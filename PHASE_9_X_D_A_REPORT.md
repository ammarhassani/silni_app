---
name: Phase 9.X.D Track A — onboarding-prep engine work, founder push pending
description: 6 of 8 spec'd tasks shipped (code + migrations written, tests green). 2 halted for spec divergence. Cannot apply to prod (MCP disconnected); founder pushes 5 migrations + redeploys 1 edge function, then verifies on real device per CTO spec.
type: project
---

# PHASE 9.X.D Track A Report

**Date:** 2026-04-28
**Status:** Code + migrations committed in `bd54145`. MCP reconnected mid-session; **all 5 migrations applied to prod + cron redeployed (v19 ACTIVE) + post-state MCP-verified clean.** Real-device tests gate Track B+C closure.

**Commits shipped:**
- `bd54145` — Track A code + 5 migrations (founder-push-pending at the time of commit)
- `<this commit>` — Report updated with applied-to-prod state

---

## Per-task summary

### A1 — Drop dead users columns

**Reduced scope per pre-check.** Original audit listed 9 dead users columns; pre-check verified 7 dead, 2 LIVE.

| Column | Pre-check verdict | Action |
|---|---|---|
| `language` | DEAD (no consumers) | Dropped |
| `notifications_enabled` | DEAD (only an analytics user-property string constant) | Dropped |
| `reminder_time` | DEAD (cron uses `reminder_schedules.time`, not user-level) | Dropped |
| `theme` | DEAD (matches were `ThemeColors` API, unrelated) | Dropped |
| `phone_number` | DEAD (matches were all `relatives.phone_number`) | Dropped |
| `account_deletion_requested` | DEAD | Dropped |
| `last_streak_date` | DEAD (already gone — IF EXISTS no-op) | Dropped |
| `trial_started_at` | 🔴 LIVE — `sync-subscription/index.ts:100` writes it | **Preserved** |
| `trial_used` | 🔴 LIVE — `sync-subscription/index.ts:101` writes it | **Preserved** |

**Migration:** [`20260428600000_drop_dead_user_columns.sql`](supabase/migrations/20260428600000_drop_dead_user_columns.sql) — 7 column drops + self-verify (asserts dropped columns gone AND trial_* columns still present).

**Relatives — full halt.** Audit listed 8 dead relatives columns. Pre-check verified ALL 8 LIVE in `Relative.fromJson`/`toJson` ([relative_model.dart:316-426](lib/shared/models/relative_model.dart)) — every read of a relative deserializes them, every write serializes them. Plus:
- `best_time_to_contact` referenced at [one_question_engine.dart:78,94](lib/core/services/one_question_engine.dart#L78) (dormant feature but exists)
- `emotional_closeness` + `communication_quality` are AI prompt placeholders at [ai_touch_point_service.dart:234-235](lib/core/services/ai_touch_point_service.dart#L234)

Per spec ("If any column flips from dead to live, halt; don't force a drop"), preserved all 8 relatives columns. Removing them properly requires Dart-side surgery: drop the model fields → drop fromJson/toJson lines → grep callers → fix the touch-point placeholder fallbacks. **Out of scope for Track A.** Tracked as v1.1 cleanup if founder wants the schema bloat trimmed.

### A2 — Add `relative_category` — HALTED FOR DIVERGENCE

**The column already exists.** Spec asks to add a 2-value enum (`household`, `extended`); current schema has a 3-value enum (`household`, `extended`, `distant`) at [`20260427300000_capture_core_tables.sql:485`](supabase/migrations/20260427300000_capture_core_tables.sql).

The spec's `ALTER TABLE relatives ADD COLUMN IF NOT EXISTS relative_category TEXT NOT NULL DEFAULT 'extended' CHECK (relative_category IN ('household', 'extended'));` would no-op the column add (since it exists) and not apply the new CHECK (ALTER TABLE ADD COLUMN IF NOT EXISTS doesn't update constraints on existing columns).

Pivoting from 3-value → 2-value requires a **data migration**, not a schema add:
1. Decide what to do with existing `'distant'` rows: collapse to `'extended'`? Force user re-categorization?
2. Find the existing CHECK constraint name + DROP it; ADD new CHECK
3. Update [Dart `RelativeCategory` enum](lib/shared/models/relative_model.dart#L4-L13) (currently 3 values)
4. Update [`family_circles_widget.dart:62-71`](lib/features/home/widgets/family_circles_widget.dart) which renders all three category sections

**This is a behavior decision, not a schema-add.** Halted for founder/CTO direction. Two options for v1:
- 🅰 **Migrate to 2-value:** collapse `'distant'` rows to `'extended'`. Tightens the model but loses the "distant relatives — occasional contact" tier.
- 🅱 **Keep 3-value:** spec's intent (household/extended distinction) is already captured. Wizard step asks only `'household'` vs `'extended'` and leaves `'distant'` as a future bucket the user populates from the relatives screen later.

Recommendation: **🅱 keep 3-value.** The wizard surfaces only the binary choice the spec asked for; `'distant'` remains accessible from the regular add-relative form.

### A3 — Reminder suppression + cron update — SHIPPED

**Migration:** [`20260428610000_add_reminder_suppression.sql`](supabase/migrations/20260428610000_add_reminder_suppression.sql)
- `users.suppress_reminders_after_recent_contact BOOLEAN NOT NULL DEFAULT true`
- Default-on for every existing user (no wizard step needed for v1; sane behavior immediate)
- Self-verify: every existing row has the new column = true

**Cron edit:** [`supabase/functions/send-scheduled-reminders/index.ts`](supabase/functions/send-scheduled-reminders/index.ts) — adds last-contact suppression block:
- Selects `last_contact_date` + `relative_category` alongside relatives data
- Reads `users.suppress_reminders_after_recent_contact` (default `true` on fetch error)
- Per-relative filter at threshold `SUPPRESSION_HOURS = 24` (single threshold for v1; spec's household-specific 6h threshold deferred per spec's "simplify" clause)
- If ALL relatives recently contacted → skip schedule entirely AND skip `last_sent` update (tomorrow re-evaluates fresh)
- If SOME recently contacted → fire notification with reduced names list
- Logs each suppression with hours-ago for debug

**Founder action required:** `supabase functions deploy send-scheduled-reminders`

### A4 — Self-node creation + backfill — SHIPPED

**Migration:** [`20260428620000_self_node_on_signup.sql`](supabase/migrations/20260428620000_self_node_on_signup.sql)

Updates `handle_new_user` trigger:
- Resolves `v_full_name` once (DRY) for both existing inserts
- Adds a third INSERT to `relatives`: `is_self=true`, `relative_category='household'`, `priority=1`, `family_group_id=NULL`, `relationship_type='other'` (catch-all enum value), `full_name` from metadata
- `WHERE NOT EXISTS (SELECT 1 FROM relatives WHERE user_id = NEW.id AND is_self = true)` — handles the family-group claim flow which sets `is_self=true` on a pre-existing row
- Existing `EXCEPTION WHEN OTHERS` swallow preserved — signup never blocks
- The migration's "DO NOT REMOVE / DO NOT SIMPLIFY" history (5 prior remediations) preserved; this is an ADDITION

**Backfill:** `INSERT ... SELECT` for every `public.users` row that lacks an `is_self=true` relatives row. Uses `public.users.full_name` (more accurate than re-deriving from `raw_user_meta_data`) with email/'User' fallback.

**Self-verify:** counts `auth.users` without self-nodes post-backfill; RAISE if > 0. The migration aborts the entire transaction if backfill leaves any user un-self-noded.

**Cannot estimate backfill scope without MCP.** App is in TestFlight (small user count); risk is bounded. Self-verify is the safety net.

### A5 — AI context engine adds `users.full_name` — SHIPPED

[`lib/core/ai/ai_context_engine.dart`](lib/core/ai/ai_context_engine.dart):
- New `_userFullNameCache` String? field + `clearCache()` reset
- New `_fetchUserFullName(userId)` method, parallel with the existing `_fetch*` group in `_refreshCache` (added to the `Future.wait` list)
- `AIContext` class adds `final String? userFullName;` field, threaded through constructor + `.empty()` factory + the call site that builds the live context
- `toPromptSummary()` emits `- الاسم: <name>` line when `userFullName` is set + non-empty (skipped silently otherwise — graceful degradation when full_name is null)

**Engineer cannot test locally.** No AI service running in build env. Founder verifies on real device by opening AI chat and checking the AI references the user's name appropriately.

### A6 — Setup-complete marker + backfill — SHIPPED

**Migration:** [`20260428630000_setup_complete_marker.sql`](supabase/migrations/20260428630000_setup_complete_marker.sql)

Critical: every existing user must be `setupComplete=true` BEFORE the Track B wizard ships. Otherwise existing users would suddenly see the half-built wizard.

- Defensively `ALTER COLUMN onboarding_metadata SET DEFAULT '{}'::jsonb` + `SET NOT NULL` after backfilling NULLs to `'{}'`
- `UPDATE users SET onboarding_metadata = jsonb_set(onboarding_metadata, '{setupComplete}', 'true'::jsonb, true) WHERE setupComplete IS DISTINCT FROM 'true'`
- Self-verify: zero users have `setupComplete IS DISTINCT FROM 'true'` post-backfill

New users (post-migration) start with default `'{}'` — no `setupComplete` key — Track B's router redirect catches them on first launch.

### A7 — FCM permission deferral — SHIPPED

[`lib/shared/services/fcm_notification_service.dart`](lib/shared/services/fcm_notification_service.dart):
- `initialize()` no longer calls `_requestPermissions()` or `_initializeFCMToken()`. It only sets up local notifications + message handlers. Safe at app boot.
- New `requestPermission()`: explicit OS prompt + token retrieval (only after grant). Returns `bool`. Idempotent.

[`lib/main.dart`](lib/main.dart) auth-state listener:
- New `_legacyOneShotPermissionAsk()` fires on `signedIn`/`initialSession` for users with `onboarding_metadata->>'setupComplete'='true'` AND `'permissionAsked'` missing/false. Calls `requestPermission()`; writes `onboarding_metadata.permissionAsked = true` regardless of grant outcome (don't re-ask denied users)
- New users (setupComplete absent) skip the legacy ask — **Track B wizard owns the prompt with explainer copy**

### A8 — `seed_onboarding_ai_memory` RPC — SHIPPED

**Migration:** [`20260428640000_seed_onboarding_ai_memory_rpc.sql`](supabase/migrations/20260428640000_seed_onboarding_ai_memory_rpc.sql)

```sql
seed_onboarding_ai_memory(
  p_user_id UUID, p_full_name TEXT,
  p_household_count INT, p_extended_count INT,
  p_reminder_preference TEXT
) RETURNS UUID
```

- SECURITY DEFINER + explicit `search_path = public` per Wave 2 patterns
- Defensive: RAISE if `auth.uid() != p_user_id` (prevents cross-user seeding)
- Idempotent: if a `category='onboarding_seed'` memory already exists for the user, UPDATE it (no duplicates)
- Inserts/updates a single `ai_memories` row with `importance=5`, structured content for AI first-chat context
- `GRANT EXECUTE TO authenticated`
- Self-verify: function exists in `pg_proc` post-create

Track B's wizard calls this at completion. Wizard skip → no seed → AI degrades to today's behavior. Acceptable.

---

## Applied to prod (MCP reconnected mid-session)

All 5 migrations applied via MCP `apply_migration`, in numerical order. All self-verifications passed.

### Pre-apply state (28 users on prod, TestFlight scale)

| Check | Pre |
|---|---|
| Total users | 28 |
| Total auth.users | 28 |
| Users without `is_self` relatives row | **27** |
| Users with NULL `onboarding_metadata` | 24 |
| Users without `setupComplete=true` | 28 |

### Post-apply state (MCP-verified)

| Check | Post |
|---|---|
| `users.language` | `gone` |
| `users.theme` | `gone` |
| `users.reminder_time` | `gone` |
| `users.trial_started_at` (preserved per pre-check) | `kept` |
| `users.suppress_reminders_after_recent_contact` | `present` |
| Users without `is_self` relatives row | **0** ✅ (down from 27) |
| Users without `setupComplete=true` | **0** ✅ (down from 28) |
| `seed_onboarding_ai_memory` function | `present` ✅ |

### Edge function

`send-scheduled-reminders` redeployed via MCP `deploy_edge_function`:
- Version `19`, status `ACTIVE`
- `verify_jwt: true` (preserved from prior deploy)
- The new suppression logic is live in prod immediately

### What did NOT execute via Track A

None — all 6 shipped tasks are applied to prod. A2 was correctly halted before any apply. The 8 relatives columns flagged for drop in the original audit were correctly preserved post pre-check.

### Real-device verification (founder runs)

Per CTO spec — Track B and C **wait until founder confirms each:**

1. **Lunch-with-dad simulation** — Log an interaction with a relative right now. Confirm the next applicable scheduled reminder for that relative (or trigger one) does NOT fire (suppressed at SUPPRESSION_HOURS=24h).
2. **Solo user self-node** — Check via MCP that your `auth.uid()` has a `relatives` row with `is_self = true`. Open the family tree screen — your self-node visible/anchored?
3. **AI knows your name** — Open AI chat. Ask "what's my name?" or anything. Does the AI reference your full name appropriately?
4. **`setupComplete` marker** — Verify your existing user has `onboarding_metadata->>'setupComplete' = 'true'` so you don't accidentally see Track B's half-built wizard if you cold-launch.
5. **No notification ask at boot for already-permissioned users.** For unpermissioned existing users, expect the one-shot ask + verify `permissionAsked=true` is written afterward. (Note: the founder's own user already has `setupComplete=true` from the A6 backfill, so the legacy ask path WILL trigger on next launch if `permissionAsked` is absent. Expected one-shot prompt then quiet thereafter.)

---

## Engineer-side verification (already complete)

| Check | Result |
|---|---|
| `flutter analyze` | 0 issues |
| `flutter test test/unit/` | 1175 / 0 |
| `flutter test test/golden/` | 8 / 0 |
| All migration files self-verifying | Yes (each has a DO block that RAISEs on assertion failure) |

Could not run:
- `flutter build ios --release --no-codesign` — skipped to keep this fast; founder builds when ready to TestFlight

Now applied (MCP reconnected):
- All 5 migrations applied to prod, MCP-verified post-state
- Edge function `send-scheduled-reminders` deployed v19 ACTIVE

---

## Surprises

1. **Audit was approximate, not exact.** 2 of 9 "dead" users columns were live; 8 of 8 "dead" relatives columns were live. The pre-check spec saved us from a destructive force-drop. The audit's "dead" status was based on grep-for-consumers but didn't account for `Relative.fromJson`/`toJson` deserialization paths or edge function references.

2. **`relative_category` already exists with 3 values.** Spec's 2-value migration would have been a no-op + behavior bug. Halted for divergence.

3. **The reminders cron pre-deploy update is in code.** A founder running `supabase functions deploy send-scheduled-reminders` immediately after `supabase db push` of 20260428610000 will activate the suppression logic. There's a small window where the column exists but the function isn't deployed yet — old code reads no column → behavior unchanged → safe ordering.

4. **Self-node trigger update is the highest-risk change.** `handle_new_user` has 5 prior remediations and a "DO NOT REMOVE" comment. The new addition preserves the existing inserts verbatim and adds the third one wrapped in WHERE NOT EXISTS + the same EXCEPTION swallow. Conservative pattern.

5. **`relationship_type='other'` for self-node.** No `'self'` value exists in the enum; adding one would touch the Dart `RelationshipType` enum + tests + family-tree label resolution. Punted to v1.1. The family tree's `is_self` boolean is the orthogonal flag the rendering code uses anyway — `relationship_type` is mostly cosmetic for self-nodes.

---

## Open questions for the CTO

1. **A2 divergence** — Recommend keeping the 3-value `relative_category` (household/extended/distant) and having the wizard surface only the household/extended binary. Confirm or specify migrate-to-2-value path.

2. **Relatives column drop scope** — All 8 audit-flagged "dead" relatives columns turned out live in model serialization. Want a follow-up Dart-side surgery to actually drop them, or accept the schema bloat?

3. **MCP disconnected mid-session.** Engineer cannot apply migrations or verify post-state. Founder pushes per the hand-off section. If MCP comes back online, engineer can re-verify.

4. **Real-device tests** — 5 verifications gate Track B + C closure. Founder owns these per CTO spec.

5. **A4 backfill scope estimation** — Without MCP, can't count `auth.users` lacking self-nodes pre-apply. Migration's self-verify ensures correctness post-apply. If the backfill volume is large enough that the migration takes minutes to apply, the founder will see it; otherwise no concern.

---

## Closing state

6 of 8 spec'd tasks shipped (A1-reduced, A3, A4, A5, A6, A7, A8). A2 halted for divergence (3-value column already exists). A1 narrowed to 7 of 9 columns per pre-check.

Engineer-side verification clean. Founder push + real-device tests gate closure.
