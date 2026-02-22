# Sprint 1: Ramadan Emergency — Headache Paywall Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Ship the 5 highest-impact paywall changes within 48 hours of Ramadan Day 1.

**Architecture:** Modify existing paywall, subscription tier, and home screen to add premium pressure. No new services or providers — just UI changes and config tweaks on existing infrastructure.

**Tech Stack:** Flutter, Riverpod, RevenueCat, existing GlassCard/AppColors/AppTypography system

---

## Task 1: Change Reminder Limit from 3 to 1

**Files:**
- Modify: `lib/core/models/subscription_tier.dart:86-88`
- Modify: `supabase/migrations/` (new migration for admin_subscription_tiers)

**Step 1: Update hardcoded fallback**

In `lib/core/models/subscription_tier.dart`, change line 87:
```dart
int get reminderLimit => switch (this) {
  SubscriptionTier.free => 1,  // Changed from 3 to 1
  SubscriptionTier.max => -1, // Unlimited
};
```

**Step 2: Create Supabase migration to update admin config**

Create migration file `supabase/migrations/20260218000000_reduce_free_reminder_limit.sql`:
```sql
-- Reduce free tier reminder limit from 3 to 1
UPDATE admin_subscription_tiers
SET reminder_limit = 1
WHERE tier_key = 'free';
```

**Step 3: Push migration**

Run: `supabase db push --project-ref bapwklwxmwhpucutyras` (or use the MCP apply_migration tool)

**Step 4: Verify**

Check that `dynamicReminderLimitProvider` returns 1 for free users. The provider in `lib/core/providers/feature_config_provider.dart:199-206` will pick up the DB change automatically.

**Step 5: Commit**

```bash
git add lib/core/models/subscription_tier.dart supabase/migrations/20260218000000_reduce_free_reminder_limit.sql
git commit -m "feat: reduce free tier reminder limit from 3 to 1"
```

---

## Task 2: Add Contextual Paywall Copy

**Files:**
- Modify: `lib/features/subscription/screens/paywall_screen.dart:37-44` (constructor)
- Modify: `lib/features/subscription/screens/paywall_screen.dart:129-130` (headline)

**Step 1: Add contextual headline parameter to PaywallScreen**

In `paywall_screen.dart`, update the constructor (lines 37-44):
```dart
class PaywallScreen extends ConsumerStatefulWidget {
  /// Feature that triggered the paywall (for analytics)
  final String? featureToUnlock;

  /// Custom headline based on trigger context
  final String? contextHeadline;

  const PaywallScreen({
    super.key,
    this.featureToUnlock,
    this.contextHeadline,
  });
```

**Step 2: Use contextual headline in the app bar**

In `paywall_screen.dart`, update the headline (around line 129-130):
```dart
Text(
  widget.contextHeadline ?? 'الاشتراك المميز',
  style: AppTypography.headlineMedium.copyWith(
    color: themeColors.textOnGradient,
    fontWeight: FontWeight.bold,
  ),
  textAlign: TextAlign.center,
),
```

**Step 3: Add a static helper for contextual headlines**

Add at the top of `paywall_screen.dart` (after FeatureIds import):
```dart
/// Contextual headlines for paywall based on trigger source
class PaywallContext {
  PaywallContext._();

  static String? headlineForFeature(String? featureId) {
    return switch (featureId) {
      FeatureIds.aiChat => 'احصل على مساعد ذكي لعلاقاتك',
      FeatureIds.unlimitedReminders => 'لا تنسَ أحداً — تذكيرات بلا حدود',
      FeatureIds.advancedAnalytics => 'اعرف من تواصلت معه ومن نسيته',
      FeatureIds.leaderboard => 'تنافس مع عائلتك في صلة الرحم',
      FeatureIds.familyTree => 'شاهد شجرة عائلتك التفاعلية',
      FeatureIds.messageComposer => 'رسائل ذكية لكل مناسبة',
      FeatureIds.relationshipAnalysis => 'تحليل شامل لعلاقاتك العائلية',
      FeatureIds.weeklyReports => 'تقارير أسبوعية عن تواصلك',
      FeatureIds.occasionMessages => 'رسائل مناسبات بالذكاء الاصطناعي',
      FeatureIds.communicationScripts => 'نصوص جاهزة للتواصل مع أقاربك',
      _ => null,
    };
  }
}
```

**Step 4: Update all existing paywall triggers to pass contextual headline**

Update each trigger site. Example for AI Hub (`lib/features/ai_assistant/screens/ai_hub_screen.dart:847-854`):
```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => PaywallScreen(
      featureToUnlock: featureId,
      contextHeadline: PaywallContext.headlineForFeature(featureId),
    ),
  ),
);
```

Do the same for:
- `lib/features/gamification/screens/leaderboard_screen.dart` (FeatureIds.leaderboard)
- `lib/features/settings/widgets/theme_carousel.dart` (FeatureIds.customThemes)
- `lib/features/family_tree/screens/family_tree_screen.dart` (FeatureIds.familyTree)
- `lib/features/ai_assistant/screens/occasion_messages_screen.dart` (FeatureIds.occasionMessages)

**Step 5: Commit**

```bash
git add lib/features/subscription/screens/paywall_screen.dart lib/features/ai_assistant/ lib/features/gamification/ lib/features/settings/ lib/features/family_tree/
git commit -m "feat: contextual paywall headlines based on trigger source"
```

---

## Task 3: Change CTA to "٠ ريال" Copy

**Files:**
- Modify: `lib/features/subscription/screens/paywall_screen.dart:597` (purchase button text)
- Modify: `lib/features/subscription/screens/paywall_screen.dart:167` (trial banner text)

**Step 1: Update purchase button CTA**

In `paywall_screen.dart` line 597, change:
```dart
// FROM:
'ابدأ التجربة المجانية',
// TO:
'جرّب مجاناً بـ ٠ ريال',
```

**Step 2: Update trial banner text**

In `paywall_screen.dart` line 167, change:
```dart
// FROM:
'جرب مجاناً لمدة 7 أيام',
// TO:
'جرّب MAX مجاناً — ٠ ريال لمدة ٧ أيام',
```

**Step 3: Commit**

```bash
git add lib/features/subscription/screens/paywall_screen.dart
git commit -m "feat: change paywall CTA to zero-price copy for higher conversion"
```

---

## Task 4: Home Screen Premium Banner for Free Users

**Files:**
- Create: `lib/features/home/widgets/premium_upgrade_banner.dart`
- Modify: `lib/features/home/screens/home_screen.dart` (insert banner after header)
- Modify: `lib/features/home/widgets/widgets.dart` (export barrel)

**Step 1: Create the premium banner widget**

Create `lib/features/home/widgets/premium_upgrade_banner.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../subscription/screens/paywall_screen.dart';

/// Rotating premium upgrade banner shown to free users on home screen.
/// Not dismissable — visible every session.
class PremiumUpgradeBanner extends ConsumerStatefulWidget {
  const PremiumUpgradeBanner({super.key});

  @override
  ConsumerState<PremiumUpgradeBanner> createState() =>
      _PremiumUpgradeBannerState();
}

class _PremiumUpgradeBannerState extends ConsumerState<PremiumUpgradeBanner> {
  static const _teasers = [
    'ذكاء اصطناعي يحلل علاقاتك ويقترح متى تتواصل',
    'تذكيرات ذكية بلا حدود لكل أفراد عائلتك',
    'تحليلات متقدمة لتواصلك مع عائلتك',
    'تقارير أسبوعية وتنافس عائلي في صلة الرحم',
  ];

  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(() => _currentIndex = (_currentIndex + 1) % _teasers.length);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMax = ref.watch(isMaxProvider);
    if (isMax) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PaywallScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.premiumGold.withValues(alpha: 0.2),
              AppColors.premiumGoldDark.withValues(alpha: 0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: AppColors.premiumGold.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.premiumGold, AppColors.premiumGoldDark],
                ),
              ),
              child:
                  const Icon(Icons.star_rounded, color: Colors.black87, size: 22),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'صِلني MAX',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.premiumGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      _teasers[_currentIndex],
                      key: ValueKey(_currentIndex),
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.premiumGold.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}
```

**Step 2: Export from widgets barrel**

Check `lib/features/home/widgets/widgets.dart` and add the export.

**Step 3: Insert into home screen**

In `lib/features/home/screens/home_screen.dart`, add after `HomeHeaderWidget` (after line 390):

```dart
// Premium upgrade banner (free users only)
const PremiumUpgradeBanner(),
const SizedBox(height: AppSpacing.sm),
```

**Step 4: Commit**

```bash
git add lib/features/home/widgets/premium_upgrade_banner.dart lib/features/home/widgets/widgets.dart lib/features/home/screens/home_screen.dart
git commit -m "feat: add persistent premium upgrade banner on home screen for free users"
```

---

## Task 5: Blurred AI Teasers (Replace Lock Boxes)

**Files:**
- Modify: `lib/features/home/widgets/ai_insight_card.dart` (show blurred teaser instead of hiding)
- Modify: `lib/features/home/widgets/ai_priority_contacts_widget.dart` (show blurred teaser instead of hiding)

**Step 1: Update AI Insight Card to show blurred teaser for free users**

In `lib/features/home/widgets/ai_insight_card.dart`, instead of returning `SizedBox.shrink()` for non-MAX users, show a blurred teaser card. Replace the early return with a fake blurred insight card that opens the paywall on tap.

The card should:
- Show a GlassCard with the same styling as the real insight
- Contain 2-3 lines of Arabic placeholder text (e.g., "بناءً على تحليل تواصلك الأخير مع عائلتك، ننصحك بالتواصل مع...")
- Apply `ImageFilter.blur(sigmaX: 5, sigmaY: 5)` to the text
- Overlay: "اشترك لقراءة التحليل" with a lock icon
- `onTap` → Navigate to `PaywallScreen(featureToUnlock: FeatureIds.relationshipAnalysis, contextHeadline: PaywallContext.headlineForFeature(FeatureIds.relationshipAnalysis))`

**Step 2: Update AI Priority Contacts to show blurred teaser for free users**

In `lib/features/home/widgets/ai_priority_contacts_widget.dart`, same approach:
- Instead of `SizedBox.shrink()`, show a blurred card with fake priority names
- Overlay: "MAX يخبرك من يجب أن تتواصل معه أولاً"
- `onTap` → Navigate to PaywallScreen with appropriate context

**Step 3: Commit**

```bash
git add lib/features/home/widgets/ai_insight_card.dart lib/features/home/widgets/ai_priority_contacts_widget.dart
git commit -m "feat: show blurred AI teasers for free users instead of hiding cards"
```

---

## Task 6: Session-Based Paywall Interstitial (Every 3rd App Open)

**Files:**
- Create: `lib/shared/widgets/session_paywall_interstitial.dart`
- Modify: `lib/features/home/screens/home_screen.dart` (trigger on init)

**Step 1: Create the interstitial widget**

Create `lib/shared/widgets/session_paywall_interstitial.dart`:

A static method `maybeShow(BuildContext context)` that:
- Uses `SharedPreferences` to track app open count (`silni_app_open_count`) and skip count (`silni_paywall_skip_count`)
- Increments open count on each call
- Shows every 3rd open (or every 5th after 5 skips)
- Displays a modal bottom sheet (not full screen — less intrusive but still visible):
  - Gold gradient header: "جرّب صِلني MAX"
  - "مجاناً بـ ٠ ريال لمدة ٧ أيام"
  - 3 feature bullets with icons
  - Gold "ابدأ التجربة" button → opens PaywallScreen
  - Grey "تخطي" text button at bottom → increments skip count and dismisses

**Step 2: Trigger from home screen**

In `lib/features/home/screens/home_screen.dart`, in `initState()` (after `_checkPremiumOnboarding()`), add:

```dart
_checkSessionPaywall();
```

Add the method:
```dart
void _checkSessionPaywall() {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    final isMax = ref.read(isMaxProvider);
    if (!isMax) {
      SessionPaywallInterstitial.maybeShow(context);
    }
  });
}
```

**Step 3: Commit**

```bash
git add lib/shared/widgets/session_paywall_interstitial.dart lib/features/home/screens/home_screen.dart
git commit -m "feat: add session-based paywall interstitial every 3rd app open"
```

---

## Verification

After all tasks, run:
```bash
flutter analyze
flutter build ios --no-codesign  # Quick build check
```

Then push an update to TestFlight and verify:
1. Free user sees only 1 reminder slot
2. Premium banner shows on home screen with rotating text
3. Paywall headline changes based on which feature triggered it
4. CTA says "٠ ريال"
5. AI cards show blurred teasers instead of being hidden
6. Every 3rd app open shows interstitial

---

## Final Push

```bash
# After all tasks verified
flutter build ios
# Upload to TestFlight / App Store
```
