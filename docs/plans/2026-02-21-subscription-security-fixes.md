# Subscription Security Fixes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Close all 16 security vulnerabilities identified in the subscription/paywall audit, preventing free users from exploiting premium features.

**Architecture:** Defense-in-depth — server-side (Supabase RLS + DB triggers + edge functions) as the hard boundary, Flutter client as UX convenience layer. Never trust the client.

**Tech Stack:** Supabase (PostgreSQL RLS, triggers, migrations), Deno edge functions, Flutter/Riverpod

---

## Task 1: Lock down `subscription_status` writes (C1 + C2)

**Fixes:** C1 (RPC functions callable by any user), C2 (direct column update via RLS)

**Files:**
- Create: `supabase/migrations/20260221000001_lock_subscription_writes.sql`
- Modify: `lib/core/services/subscription_service.dart:717-721`

**Step 1: Write the migration**

```sql
-- Lock down subscription_status: only service_role can write subscription columns
-- Fixes: C1 (RPC exploit) and C2 (direct column update)

-- 1. Revoke EXECUTE on dangerous SECURITY DEFINER functions from authenticated users
REVOKE EXECUTE ON FUNCTION update_user_subscription FROM authenticated;
REVOKE EXECUTE ON FUNCTION start_user_trial FROM authenticated;
REVOKE EXECUTE ON FUNCTION end_user_trial FROM authenticated;
REVOKE EXECUTE ON FUNCTION log_subscription_event FROM authenticated;

-- 2. Replace the permissive users UPDATE policy with a column-restricted one
-- Drop the old wide-open policy
DROP POLICY IF EXISTS "Users can update own profile" ON users;

-- Allow users to update ONLY safe profile columns (not subscription columns)
CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Create a trigger function that prevents users from modifying subscription columns
CREATE OR REPLACE FUNCTION prevent_subscription_column_update()
RETURNS TRIGGER AS $$
BEGIN
  -- Only service_role can modify subscription columns
  IF current_setting('request.jwt.claim.role', true) != 'service_role' THEN
    -- Preserve the old subscription values — ignore whatever the client sent
    NEW.subscription_status := OLD.subscription_status;
    NEW.subscription_product_id := OLD.subscription_product_id;
    NEW.subscription_expires_at := OLD.subscription_expires_at;
    NEW.trial_started_at := OLD.trial_started_at;
    NEW.trial_used := OLD.trial_used;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach trigger BEFORE UPDATE so subscription columns are always preserved
DROP TRIGGER IF EXISTS guard_subscription_columns ON users;
CREATE TRIGGER guard_subscription_columns
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION prevent_subscription_column_update();

-- 3. Tighten subscription_events INSERT policy: service_role only
DROP POLICY IF EXISTS "Service role can insert subscription events" ON subscription_events;
CREATE POLICY "Service role can insert subscription events"
  ON subscription_events FOR INSERT
  WITH CHECK (auth.role() = 'service_role');
```

**Step 2: Update Flutter sync to use RPC via service_role edge function**

The client currently writes directly to `users.subscription_status`. After the trigger, those writes will be silently ignored. The sync is informational (RevenueCat is the source of truth), so the simplest fix is to remove the direct write and rely on RevenueCat webhooks or the existing `update_user_subscription` function called from a service-role context.

In `lib/core/services/subscription_service.dart`, replace the `_syncSubscriptionToSupabase` method (lines 701-737):

```dart
/// Sync subscription status to Supabase via secure RPC
/// Note: The trigger on users table prevents client-side subscription_status writes.
/// This calls a secure edge function that uses service_role to update.
Future<void> _syncSubscriptionToSupabase(SubscriptionState state) async {
  try {
    final supabase = SupabaseConfig.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      _logger.warning(
        'Cannot sync subscription - no user logged in',
        category: LogCategory.service,
        tag: 'SubscriptionService',
      );
      return;
    }

    final status = state.tier == SubscriptionTier.max ? 'premium' : 'free';

    await supabase.functions.invoke(
      'sync-subscription',
      body: {
        'status': status,
        'product_id': state.productId,
        'expires_at': state.expirationDate?.toIso8601String(),
        'trial_active': state.isTrialActive,
      },
    );

    _logger.info(
      'Subscription synced to Supabase via edge function',
      category: LogCategory.service,
      tag: 'SubscriptionService',
      metadata: {'userId': userId, 'status': status},
    );
  } catch (e) {
    _logger.error(
      'Failed to sync subscription to Supabase',
      category: LogCategory.service,
      tag: 'SubscriptionService',
      metadata: {'error': e.toString()},
    );
  }
}
```

**Step 3: Create the `sync-subscription` edge function**

Create `supabase/functions/sync-subscription/index.ts`:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { getCorsHeaders } from "../_shared/cors.ts";

serve(async (req: Request) => {
  const corsHeaders = getCorsHeaders(req);

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Get user from JWT
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "No auth header" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Create client with user's JWT to get their ID
    const userClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user }, error: userError } = await userClient.auth.getUser();
    if (userError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { status, product_id, expires_at, trial_active } = await req.json();

    // Validate status
    if (!["free", "premium"].includes(status)) {
      return new Response(JSON.stringify({ error: "Invalid status" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Use service_role client to update (bypasses trigger)
    const serviceClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    await serviceClient.from("users").update({
      subscription_status: status,
      subscription_product_id: product_id ?? null,
      subscription_expires_at: expires_at ?? null,
      trial_started_at: trial_active ? new Date().toISOString() : undefined,
      trial_used: trial_active ? false : undefined,
    }).eq("id", user.id);

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
```

**Step 4: Apply migration to Supabase**

Run: `supabase db push` or use the MCP `apply_migration` tool.

**Step 5: Deploy the edge function**

Run: `supabase functions deploy sync-subscription --project-ref bapwklwxmwhpucutyras`

**Step 6: Commit**

```bash
git add supabase/migrations/20260221000001_lock_subscription_writes.sql \
        supabase/functions/sync-subscription/index.ts \
        lib/core/services/subscription_service.dart
git commit -m "fix(security): lock down subscription_status writes to service_role only

Block C1 (RPC exploit) and C2 (direct column update) by:
- Revoking authenticated EXECUTE on subscription RPC functions
- Adding trigger to silently ignore client subscription column writes
- Moving sync to a service_role edge function"
```

---

## Task 2: Server-side reminder limit enforcement (C3)

**Fixes:** C3 (no DB-level reminder limit)

**Files:**
- Create: `supabase/migrations/20260221000002_enforce_reminder_limit.sql`

**Step 1: Write the migration**

```sql
-- Enforce reminder limit at DB level
-- Free users: 1 reminder, Premium users: unlimited (-1)

CREATE OR REPLACE FUNCTION enforce_reminder_limit()
RETURNS TRIGGER AS $$
DECLARE
  v_status TEXT;
  v_limit INT;
  v_count INT;
BEGIN
  -- Get user's subscription status
  SELECT subscription_status INTO v_status
  FROM users WHERE id = NEW.user_id;

  -- Premium users have no limit
  IF v_status = 'premium' THEN
    RETURN NEW;
  END IF;

  -- Get dynamic limit from admin config, fallback to 1
  SELECT COALESCE(
    (SELECT reminder_limit FROM admin_subscription_tiers
     WHERE tier_key = 'free' AND is_active = true LIMIT 1),
    1
  ) INTO v_limit;

  -- Count existing active schedules
  SELECT COUNT(*) INTO v_count
  FROM reminder_schedules
  WHERE user_id = NEW.user_id
    AND is_active = true;

  IF v_count >= v_limit THEN
    RAISE EXCEPTION 'Reminder limit reached. Free tier allows % reminders.', v_limit
      USING ERRCODE = 'P0001';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS check_reminder_limit ON reminder_schedules;
CREATE TRIGGER check_reminder_limit
  BEFORE INSERT ON reminder_schedules
  FOR EACH ROW
  EXECUTE FUNCTION enforce_reminder_limit();
```

**Step 2: Apply migration**

**Step 3: Commit**

```bash
git add supabase/migrations/20260221000002_enforce_reminder_limit.sql
git commit -m "fix(security): enforce reminder limit at DB level via trigger"
```

---

## Task 3: Fix AI proxy rate limits (H1)

**Fixes:** H1 (free users get 50 requests/day instead of 0)

**Files:**
- Modify: `supabase/functions/deepseek-proxy/index.ts:137-140`

**Step 1: Fix the rate limit logic**

Replace lines 137-140 in `supabase/functions/deepseek-proxy/index.ts`:

```typescript
    // Free users: 0 requests (blocked), Premium users: 200
    const rateLimit = isPremium ? RATE_LIMIT_PREMIUM : RATE_LIMIT_FREE;
```

Remove the `BASE_LIMIT` constant and the comment about "free users blocked at app level".

**Step 2: Deploy the edge function**

Run: `supabase functions deploy deepseek-proxy --project-ref bapwklwxmwhpucutyras`

**Step 3: Commit**

```bash
git add supabase/functions/deepseek-proxy/index.ts
git commit -m "fix(security): enforce RATE_LIMIT_FREE=0 in AI proxy, remove BASE_LIMIT=50 bypass"
```

---

## Task 4: Add subscription guard to router + AI screens (C4 + C5)

**Fixes:** C4 (AI screens have no internal checks), C5 (no router middleware)

**Files:**
- Modify: `lib/core/router/app_routes.dart` (add premiumRoutes set)
- Modify: `lib/core/router/app_router.dart` (add subscription redirect)
- Modify: `lib/features/subscription/screens/paywall_screen.dart` (add static route)

**Step 1: Define premium routes in `app_routes.dart`**

Add after the `publicRoutes` set (around line 22):

```dart
/// Routes that require MAX subscription
static const Set<String> premiumRoutes = {
  aiChat,
  aiMessages,
  aiAnalysis,
  aiScripts,
  aiReport,
  aiMemories,
  statistics,
  detailedStats,
  leaderboard,
};

/// Check if a route requires premium subscription
static bool isPremiumRoute(String path) {
  return premiumRoutes.any((route) => path == route || path.startsWith('$route/'));
}
```

**Step 2: Add subscription redirect in `app_router.dart`**

The router uses a `Provider`, not `ConsumerWidget`, so we need to read subscription state from the `ref`. Modify the `routerProvider` (line 54) to accept ref and add a redirect check.

Add this after the auth redirect logic (after line 109, before `return null;`):

```dart
// Case 4: Free user on premium route - redirect to paywall
if (isAuthenticated && AppRoutes.isPremiumRoute(currentPath)) {
  final tier = ref.read(subscriptionTierProvider);
  if (tier != SubscriptionTier.max) {
    return AppRoutes.home;
  }
}
```

Add import at top of file:
```dart
import '../providers/subscription_provider.dart';
import '../models/subscription_tier.dart';
```

Note: This redirects to home rather than the paywall because GoRouter redirect can't push a modal/dialog. The individual screen-level gates (next task) will show the paywall when needed. The router guard is a safety net to prevent direct URL access.

**Step 3: Commit**

```bash
git add lib/core/router/app_routes.dart lib/core/router/app_router.dart
git commit -m "fix(security): add router-level subscription guard for premium routes"
```

---

## Task 5: Fix Supabase fallback and cache issues (C6 + H5)

**Fixes:** C6 (fallback grants indefinite MAX), H5 (24h stale cache)

**Files:**
- Modify: `lib/core/services/subscription_service.dart:609-633` (fallback method)
- Modify: `lib/core/services/subscription_service.dart` (cache validity)

**Step 1: Fix the Supabase fallback to check expiration**

Replace `_loadFromSupabaseFallback()` (lines 609-644):

```dart
/// Fallback to Supabase subscription_status when RevenueCat fails
Future<SubscriptionState?> _loadFromSupabaseFallback() async {
  try {
    final supabase = SupabaseConfig.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await supabase
        .from('users')
        .select('subscription_status, subscription_expires_at')
        .eq('id', userId)
        .single();

    final status = response['subscription_status'] as String?;
    if (status == 'premium' || status == 'max') {
      // Verify expiration — don't grant MAX if expired or missing expiration
      final expiresAtStr = response['subscription_expires_at'] as String?;
      if (expiresAtStr == null) {
        _logger.warning(
          'Supabase fallback: premium status but no expiration date, treating as free',
          category: LogCategory.service,
          tag: 'SubscriptionService',
        );
        return SubscriptionState.free();
      }

      final expiresAt = DateTime.tryParse(expiresAtStr);
      if (expiresAt == null || expiresAt.isBefore(DateTime.now())) {
        _logger.warning(
          'Supabase fallback: premium status but expired, treating as free',
          category: LogCategory.service,
          tag: 'SubscriptionService',
        );
        return SubscriptionState.free();
      }

      _logger.info(
        'Supabase fallback returned premium status',
        category: LogCategory.service,
        tag: 'SubscriptionService',
        metadata: {'status': status},
      );
      return SubscriptionState(
        tier: SubscriptionTier.max,
        isActive: true,
        expirationDate: expiresAt,
        isLoading: false,
      );
    }
    return SubscriptionState.free();
  } catch (e) {
    _logger.warning(
      'Supabase fallback failed: $e',
      category: LogCategory.service,
      tag: 'SubscriptionService',
    );
    return null;
  }
}
```

**Step 2: Reduce cache validity from 24h to 1h**

Find the `_cacheValidity` constant and change it:

```dart
static const Duration _cacheValidity = Duration(hours: 1);
```

**Step 3: Commit**

```bash
git add lib/core/services/subscription_service.dart
git commit -m "fix(security): require expiration date in Supabase fallback, reduce cache to 1h"
```

---

## Task 6: Fix trial history erasure (M1)

**Fixes:** M1 (trial_started_at and trial_used nulled on sync)

**Files:**
- Modify: `supabase/functions/sync-subscription/index.ts` (already created in Task 1)

The fix is already partially handled in Task 1's edge function. The key is: when `trial_active` is false, we use `undefined` (not `null`) so those fields are NOT overwritten. The edge function from Task 1 already does this correctly with `trial_active ? ... : undefined`.

However, we need to make sure the edge function NEVER sets `trial_used` to `null` or `false` when the trial is over. It should only set `trial_used = true` when a trial ends.

Update the sync-subscription edge function's update block:

```typescript
const updateData: Record<string, unknown> = {
  subscription_status: status,
  subscription_product_id: product_id ?? null,
  subscription_expires_at: expires_at ?? null,
};

// Only touch trial columns when trial is active — never erase history
if (trial_active) {
  updateData.trial_started_at = new Date().toISOString();
}

await serviceClient.from("users").update(updateData).eq("id", user.id);
```

**Step 1: Update the edge function (if not already done in Task 1)**

**Step 2: Commit**

```bash
git add supabase/functions/sync-subscription/index.ts
git commit -m "fix: preserve trial history — never null out trial_started_at/trial_used on sync"
```

---

## Task 7: Add feature gates to ungated premium screens (H2 + H3)

**Fixes:** H2 (data export no check), H3 (statistics no check)

**Files:**
- Modify: `lib/features/profile/widgets/profile_dialogs.dart:152-184` (data export)
- Modify: `lib/features/statistics/screens/statistics_screen.dart` (add gate)
- Modify: `lib/features/gamification/screens/detailed_stats_screen.dart` (add gate)

**Step 1: Gate data export in `profile_dialogs.dart`**

Add subscription check at the top of `showExportDataDialogFlow` (after line 157):

```dart
// Check subscription access for data export
final hasAccess = ref.read(featureAccessProvider(FeatureIds.dataExport));
if (!hasAccess) {
  if (context.mounted) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PaywallScreen(
          featureToUnlock: FeatureIds.dataExport,
          contextHeadline: 'صدّر بياناتك مع صِلني MAX',
        ),
      ),
    );
  }
  return;
}
```

Add imports:
```dart
import '../../../core/providers/subscription_provider.dart';
import '../../../core/models/subscription_tier.dart';
import '../../../features/subscription/screens/paywall_screen.dart';
```

**Step 2: Gate statistics screen**

In `statistics_screen.dart`, wrap the screen body with a `featureAccessProvider` check at the top of the `build` method. If no access, show the paywall.

**Step 3: Gate detailed stats screen**

Same pattern in `detailed_stats_screen.dart`.

**Step 4: Commit**

```bash
git add lib/features/profile/widgets/profile_dialogs.dart \
        lib/features/statistics/screens/statistics_screen.dart \
        lib/features/gamification/screens/detailed_stats_screen.dart
git commit -m "fix(security): add subscription gates to data export, statistics, detailed stats"
```

---

## Task 8: Fix `hasFeatureAccess` returning true for unknown features (H4)

**Fixes:** H4 (unknown features get free access)

**Files:**
- Modify: `lib/core/services/feature_config_service.dart:247-249`

**Step 1: Change the fallback for unknown features**

Replace the async `hasFeatureAccess` method's null check (line 247-249):

```dart
if (feature == null) {
  // Feature not in config — use hardcoded fallback which properly gates MAX features
  return _hardcodedFeatureAccess(featureId, userTier);
}
```

Also update the sync version's null check at line 357-359:

```dart
if (feature == null) {
  // Feature not in config — use hardcoded fallback
  return _hardcodedFeatureAccess(featureId, userTier);
}
```

**Step 2: Commit**

```bash
git add lib/core/services/feature_config_service.dart
git commit -m "fix(security): use hardcoded fallback for unknown features instead of allowing access"
```

---

## Task 9: Fix reminder limit inconsistency + paywall display (M3 + L1)

**Fixes:** M3 (getReminderLimit defaults to 3), L1 (paywall shows 3)

**Files:**
- Modify: `lib/core/services/feature_config_service.dart:269` (default to 1)
- Modify: `lib/features/subscription/screens/paywall_screen.dart` (comparison table)

**Step 1: Fix `getReminderLimit` default**

In `feature_config_service.dart` line 269, change:

```dart
return tier?.reminderLimit ?? 1; // Default to 1 for free
```

**Step 2: Fix paywall comparison table**

Find the hardcoded "3" for free reminders in `paywall_screen.dart` and change to "1":

Search for `التذكيرات` or the number `3` near the comparison table and update to `١` (Arabic 1) or `1`.

**Step 3: Commit**

```bash
git add lib/core/services/feature_config_service.dart \
        lib/features/subscription/screens/paywall_screen.dart
git commit -m "fix: correct reminder limit to 1 for free tier in config fallback and paywall display"
```

---

## Task 10: Scope session counter to user (L2)

**Fixes:** L2 (session interstitial counter shared across accounts)

**Files:**
- Modify: `lib/shared/widgets/session_paywall_interstitial.dart:19-20, 23-34`

**Step 1: Scope SharedPreferences keys to user ID**

Update `maybeShow` to include user ID in keys:

```dart
static Future<void> maybeShow(BuildContext context, {String? userId}) async {
  if (userId == null) return;

  final prefs = await SharedPreferences.getInstance();

  final openCountKey = '${_openCountKey}_$userId';
  final skipCountKey = '${_skipCountKey}_$userId';

  final openCount = (prefs.getInt(openCountKey) ?? 0) + 1;
  await prefs.setInt(openCountKey, openCount);

  final skipCount = prefs.getInt(skipCountKey) ?? 0;

  final interval = skipCount >= 5 ? 5 : 3;

  if (openCount % interval != 0) return;

  if (!context.mounted) return;

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _PaywallSheet(
      onSkip: () async {
        final updatedSkipCount = (prefs.getInt(skipCountKey) ?? 0) + 1;
        await prefs.setInt(skipCountKey, updatedSkipCount);
      },
    ),
  );
}
```

Update caller in `home_screen.dart` to pass user ID.

**Step 2: Commit**

```bash
git add lib/shared/widgets/session_paywall_interstitial.dart \
        lib/features/home/screens/home_screen.dart
git commit -m "fix: scope session paywall counter to user ID"
```

---

## Summary

| Task | Severity | Issue | Key Change |
|------|----------|-------|------------|
| 1 | CRITICAL | C1+C2 | DB trigger + revoke RPCs + edge function for sync |
| 2 | CRITICAL | C3 | DB trigger for reminder limit |
| 3 | HIGH | H1 | Fix RATE_LIMIT_FREE=0 in deepseek-proxy |
| 4 | CRITICAL | C4+C5 | Router subscription guard + premiumRoutes set |
| 5 | CRITICAL | C6+H5 | Require expiration in fallback, reduce cache to 1h |
| 6 | MEDIUM | M1 | Never null out trial history on sync |
| 7 | HIGH | H2+H3 | Add feature gates to data export + statistics |
| 8 | HIGH | H4 | Use hardcoded fallback for unknown features |
| 9 | MEDIUM | M3+L1 | Fix reminder limit default + paywall display |
| 10 | LOW | L2 | Scope session counter to user ID |
