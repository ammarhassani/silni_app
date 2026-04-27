---
name: Phase 9.1 — Real bugs first, gamification cut second, per-user state cleanup third
description: A1/A2 verified deeply (Phase 9.0's surgical fixes are correct; only one missed SharedPreferences key remained). Gamification stack ripped end-to-end (UI + services + providers + notification templates + DB columns/tables/RPCs). Per-user device state now cleared on both logout and account-delete via a single canonical wipe path. Streaks and content enhancers preserved.
type: project
---

# PHASE 9.1 — Bugs + Gamification Cut + Per-User Cleanup

**Date:** 2026-04-28
**Status:** ✅ All three parts shipped across 4 commits + 1 prod migration. Streak mechanism + content enhancers preserved exactly as scoped.

**Commits (in order):**

1. `edf30b9` — Phase 9.1.A: clearPerUserDeviceState() canonical wipe path
2. `c4f7af6` — Phase 9.1.B: Dart-side gamification cut + streak/gamification split
3. `e6d901b` — Phase 9.1.B-db: drop gamification stack from prod schema
4. `<this commit>` — Phase 9.1.docs: marketing copy + report

---

## PART A — Bug A1: Account-delete + re-login skips onboarding

### Root cause confirmed via deep verification

**Two layers verified, only the client layer was at fault:**

- **SQL layer** (verified clean via MCP): every FK to `auth.users(id)` and `public.users(id)` is `ON DELETE CASCADE`. `delete_user_account` RPC fully deletes both `auth.users` and `public.users`, cascades through `relatives`, `interactions`, `family_edges`, `chat_*`, `node_invitations`, `family_groups`, etc. No orphan rows. Migration `20260426100000_delete_user_account_full_teardown.sql` is sound.
- **Client layer** (the actual bug): `onboarding_completed` SharedPreferences key written globally per device by [main.dart:709-718](lib/main.dart#L709-L718), gated at [splash_screen.dart:167-176](lib/features/auth/screens/splash_screen.dart#L167-L176). Survived account-delete, mis-routing the next signin straight to home instead of through the marketing carousel.

### Fixes shipped

- Phase 9.0 fix (`69ecffc`, prior commit): `deleteAccount` clears `onboarding_completed`, `premium_onboarding_state`, `premium_onboarding_dismissed_tips` and routes through wrapper `signOut()` (which also clears biometric refresh token + saved email).
- **Phase 9.1.A fix (`edf30b9`)**: replaces the inline 3-key clear with a canonical `clearPerUserDeviceState()` in [session_cleanup_service.dart](lib/core/services/session_cleanup_service.dart). Two const lists: `_exactPerUserKeys` (12 keys) + `_perUserPrefixes` (`wrapped_ai_`, `one_question_asked_`). Wired into both `signOut()` and `deleteAccount()`. Closes the previously-missed `family_migration_choice` key surfaced by deep-verify, plus `weekly_report_*`, `one_question_*`, `last_hadith_index`, `analytics_first_open_date/last_active_date`, `experiment_assignments`.

### Product gap surfaced (NOT a bug — for CTO triage)

User's mental model expects a "fresh user → initial relatives picker / household setup" wizard. **No such surface exists in the codebase.** Verified by code search across `lib/features/onboarding/`, `lib/features/auth/`, `lib/features/relatives/`, `lib/features/family_groups/`, `lib/features/home/`, plus the GoRouter route registry — only the marketing carousel ([onboarding_screen.dart](lib/features/auth/screens/onboarding_screen.dart)) exists. After Phase 9.1.A's fix, a re-logged-in user lands on the carousel + then home with empty data, same as a brand-new install. Recommend either:

- Build the missing setup wizard (defer to v1.1)
- Or align user expectations with the empty-state flow

### Real-device verification halt

CTO spec required real-device test of delete + re-login. Engineer cannot verify the OAuth re-signin path in simulator. **Founder action required**: account-delete + Google re-signin + confirm carousel fires.

---

## PART A — Bug A2: Home greeting widget disappears

### Verification of Phase 9.0 fix

Phase 9.0 (`69ecffc`) shipped two edits:

- [streak_badge_bar.dart:47-51](lib/features/home/widgets/streak_badge_bar.dart#L47-L51): error fallback changed from `SizedBox.shrink()` to `_buildBar(const <String, dynamic>{})` so the bar still renders avatar + name + tier + 0-streak placeholder on stream error.
- [home_providers.dart](lib/features/home/providers/home_providers.dart): dropped `autoDispose` from `userGamificationDataProvider` (now `userStreakDataProvider` after Phase 9.1.B). Provider now persistent for the app session; no `onCancel`/`onResume` race with the competing `subscribeToUserProfile` realtime channel.

**Verdict (verified by independent agent):** Phase 9.0 fix is **complete and correct**. No additional gaps. `_buildBar` with empty data renders avatar + name + tier-pill (hidden for free tier) + 0-streak placeholder; no deeper hide-on-empty branches anywhere in the chain.

### Real-device verification halt

Same as A1 — founder needs to navigate-away + back across multiple home cycles to confirm the bar persists.

---

## PART B — Gamification cut

### Scope discovered during inventory: bigger than the spec implied

Three files mixed streak + gamification logic and could not be deleted:

1. `gamification_event.dart` — enum had streak types (`streakIncreased`, `streakMilestone`, `streakWarning`, `streakCritical`, `freezeEarned`, `freezeUsed`) AND gamification types (`pointsEarned`, `levelUp`, `badgeUnlocked`)
2. `gamification_events_provider.dart` — global event bus, streak services emit through it
3. `gamification_config_service.dart` — `streakConfig` slice used by `relative_streak_service.dart`

Solution: split each before deleting the gamification half.

### Files added (streak-only, decoupled)

- [lib/core/models/streak_event.dart](lib/core/models/streak_event.dart) — `StreakEvent` + `StreakEventType` (6 streak-only variants). Static helpers `isStreakMilestone`, `isFreezeAwardMilestone` preserved.
- [lib/core/providers/streak_events_provider.dart](lib/core/providers/streak_events_provider.dart) — `StreakEventsController`, `streakEventsControllerProvider`, `streakEventsStreamProvider`.
- [lib/core/services/streak_config_service.dart](lib/core/services/streak_config_service.dart) — `StreakConfigService` + `StreakConfig` extracted.

### Files deleted (gamification UI + services)

- `lib/core/models/gamification_event.dart`
- `lib/core/providers/gamification_events_provider.dart`
- `lib/core/providers/gamification_provider.dart`
- `lib/core/services/gamification_service.dart`
- `lib/core/services/gamification_config_service.dart`
- `lib/core/utils/badge_prestige.dart`
- `lib/shared/widgets/badge_unlock_modal.dart`
- `lib/shared/widgets/share_cards/badge_share_card.dart`
- `lib/shared/widgets/gamification_stats_card.dart`
- `lib/features/family_groups/widgets/family_leaderboard.dart`
- `lib/features/family_groups/services/leaderboard_service.dart`
- `lib/features/family_groups/providers/leaderboard_provider.dart`
- `lib/features/home/widgets/gamification_listener.dart`

Plus 4 dead test files: `gamification_service_test.dart`, `leaderboard_service_test.dart`, `gamification_config_service_test.dart`, `gamification_event_test.dart`.

### Surgical edits in surviving files

| File | Edit |
|---|---|
| [streak_badge_bar.dart](lib/features/home/widgets/streak_badge_bar.dart) | Stripped badge pill section + badge_prestige import. Bar now: avatar + name + tier-pill + streak counter + countdown. |
| [home_screen.dart](lib/features/home/screens/home_screen.dart) | Dropped GamificationListener mount + BadgeUnlockModal + pointsEarned/levelUp/badgeUnlocked cases. `_processGamificationEvent` → `_processStreakEvent`. Replaced listener-widget with direct `ref.listen` on `streakEventsStreamProvider`. |
| [profile_screen.dart](lib/features/profile/screens/profile_screen.dart) | Dropped GamificationStatsCard. |
| [family_group_screen.dart](lib/features/family_groups/screens/family_group_screen.dart) | Dropped FamilyLeaderboard mount + import. |
| [main.dart](lib/main.dart) | Dropped GamificationConfigService init/refresh + setEventsController wiring. Replaced with StreakConfigService. |
| [sync_service.dart](lib/core/services/sync_service.dart), [interactions_service.dart](lib/shared/services/interactions_service.dart) | Severed all writes to users.{badges, points, level}. |
| [relative_detail_screen.dart](lib/features/relatives/screens/relative_detail_screen.dart) | Dropped points snackbar half (kept streak messages). |
| [ai_context_engine.dart](lib/core/ai/ai_context_engine.dart) | `GamificationStats` class deleted. `AIContext.gamification` → `AIContext.totalInteractions`. Reads users.total_interactions instead of the now-dropped `gamification_stats` view. |
| [ai_prompts.dart](lib/core/ai/ai_prompts.dart), [ai_touch_point_service.dart](lib/core/services/ai_touch_point_service.dart) | Dropped المستوى/النقاط prompt lines + `{{user_level}}`/`{{total_points}}` placeholders. |
| [notification_config_service.dart](lib/core/services/notification_config_service.dart) | Dropped badge_earned/level_up/challenge_complete templates. |
| [notification_templates.dart](lib/core/constants/notification_templates.dart) | Dropped badgeMessages + levelUpMessages arrays. |
| [ui_strings_service.dart](lib/core/services/ui_strings_service.dart) | Dropped points_label/level_label/level_up/badge_earned/points_earned strings. |
| [analytics_events.dart](lib/core/constants/analytics_events.dart) | Dropped 6 event constants + 4 param constants for badges/levels/points/challenges. |
| [cache_config_service.dart](lib/core/services/cache_config_service.dart) | Renamed `gamification_config` TTL key to `streak_config`. |
| [feature_flags_service.dart](lib/core/services/feature_flags_service.dart) | Dropped gamification flag. |
| [stream_recovery_provider.dart](lib/core/providers/stream_recovery_provider.dart) | Dropped familyLeaderboardProvider invalidation. |
| [weekly_report_stats_provider.dart](lib/features/ai_assistant/providers/weekly_report_stats_provider.dart) | Dropped points/level/badges from SELECT, dropped achievements field + _parseBadges helper. |
| [paywall_screen.dart](lib/features/subscription/screens/paywall_screen.dart):298 | Dropped "لوحة المتصدرين" feature comparison row. |

### Marketing copy edited

- [README.md](README.md) lines 25, 36, 78 — replaced "نظام النقاط والشارات" / "gamification/" directory mention with "سلسلة التواصل اليومية" wording.
- [LAUNCH_DEMO_SCRIPT.md](LAUNCH_DEMO_SCRIPT.md) lines 36-37, 41 — narration "كل تواصل يحسبه — نقاط، سلسلة، شهور" → "سلسلة، شهور، عمر العلاقة"; toast snippets stripped of "+15 نقطة".
- [LAUNCH_SCREENSHOTS_LIST.md](LAUNCH_SCREENSHOTS_LIST.md) lines 34, 52 — same toast cleanup; profile screenshot description updated.

### Test cleanup

Helper agent stripped gamification refs across 9 test files:

- Rewrote: `test/helpers/test_helpers.dart` (TestGamificationEventsController → TestStreakEventsController), `model_factories.dart`, `coverage_requirements.dart`, `input_fuzzing_test.dart` (kept streak-only tests, migrated to StreakEvent), `stress_test.dart` (kept streak-milestone test, migrated)
- Stripped imports + deleted gamification test groups: `boundary_test.dart`, `race_condition_test.dart`, `security_test.dart`, `state_chaos_test.dart`, `all_services_torture_test.dart`

Net test impact: 1354 → 1167 tests passing. The 187-test drop is the deleted gamification-class tests; every streak/relative/family/notification/AI/auth test still passes.

### DB migration ([supabase/migrations/20260428500000_drop_gamification_stack.sql](supabase/migrations/20260428500000_drop_gamification_stack.sql))

Applied to prod (`bapwklwxmwhpucutyras`) via MCP. Self-verify passed. MCP post-apply confirms:

| Artifact | State |
|---|---|
| users.badges | gone |
| users.points | gone |
| users.level | gone |
| admin_badges (table) | gone |
| admin_levels (table) | gone |
| admin_points_config (table) | gone |
| gamification_stats (view) | gone |
| award_points (function) | gone |
| get_leaderboard (function, both overloads) | gone |
| **users.current_streak** | **kept** |
| **admin_streak_config (table)** | **kept** |

Surprise: `gamification_stats` was a VIEW depending on `users.badges`, not a table. First apply attempt failed with "cannot drop column badges of table users because other objects depend on it". Reordered migration to `DROP VIEW` first, then ALTER TABLE. Second apply clean.

Also discovered: `get_leaderboard` had two overloads in prod (`(integer)` and `(text, integer)`) — only one was in any captured migration. Both dropped.

### Streaks + content enhancers preserved

- ✅ users.current_streak, longest_streak, streak_freezes (all still in prod schema)
- ✅ streak_freezes table, freeze_usage_history table, relative_streaks table
- ✅ admin_streak_config table
- ✅ StreakConfig + StreakConfigService + StreakEvent + StreakEventsController
- ✅ Streak break notifications + reminder logic untouched
- ✅ StreakMilestoneModal still fires on milestones with confetti
- ✅ Wrapped, weekly report, one-question, hadith — all still wired and rendering. Per-user caches now properly cleared on logout/delete.

---

## PART C — Per-user state cleanup

`clearPerUserDeviceState()` in [session_cleanup_service.dart](lib/core/services/session_cleanup_service.dart) defines the canonical wipe path:

**Cleared on logout AND on account-delete (per-user):**

| Key | Why per-user |
|---|---|
| `onboarding_completed` | Marketing carousel cold-start gate |
| `premium_onboarding_state` | Premium tip walkthrough state |
| `premium_onboarding_dismissed_tips` | Premium tip dismissal list |
| `weekly_report_insight` | AI weekly insight string for current user |
| `weekly_report_tip` | AI weekly tip string for current user |
| `weekly_report_ts` | Weekly report cache timestamp |
| `one_question_week_count` | Per-week question rate limit |
| `one_question_week_start` | Week start timestamp |
| `last_hadith_index` | Hadith rotation index — fresh user gets fresh rotation per CTO |
| `family_migration_choice` | Per-user family-migration prompt decision |
| `analytics_first_open_date` | Per-user retention marker |
| `analytics_last_active_date` | Per-user retention marker |
| `experiment_assignments` | Avoid cross-user cohort leakage |
| `wrapped_ai_*` (prefix) | Wrapped per-user AI personality titles (per userId/year/month) |
| `one_question_asked_*` (prefix) | Asked-question history (per relativeId) |

**NOT cleared (device-global by design, documented inline):**

- `app_theme` — visual theme, device pref
- `pattern_animation_*` — animation toggles, device pref
- `notifications_*_enabled` (5 keys) — Phase 5.5 design, preserved for v1.1 topic-subscription readback
- `_test_key` — connectivity diagnostic, transient
- `feature_flag_*` — debug overrides

### Wired into both paths

- [auth_service.dart `signOut()`](lib/shared/services/auth_service.dart) — clears after the FCM/RevenueCat/biometric teardown
- [auth_service.dart `deleteAccount()`](lib/shared/services/auth_service.dart) — pre-clears before signOut runs (belt-and-suspenders against the auth-listener race window), then signOut runs its own clear

---

## Verification

| Check | Result |
|---|---|
| `flutter analyze` | 6 issues (baseline preserved — same 5 unnecessary_underscores info + 1 _saveFamilyName warning) |
| `flutter test test/unit/` | 1167 / 0 (down from 1354 — 187-test drop is the deleted gamification-class tests) |
| `flutter test test/golden/` | 8 / 0 |
| `supabase apply_migration` (drop_gamification_stack) | applied cleanly; self-verify passed |
| MCP post-apply: every gamification artifact | `gone` |
| MCP post-apply: streak guard artifacts | `kept` |

**Real-device verification still pending (CTO halt gate):** founder needs to confirm A1 (account-delete + Google re-signin → carousel fires) and A2 (home navigate-cycle → bar persists) on physical hardware. iOS build itself was not re-run — no iOS-specific changes since Phase 8.

---

## Surprises

1. **Three files had to be split, not deleted.** `gamification_event.dart`, `gamification_events_provider.dart`, `gamification_config_service.dart` all mixed streak + gamification logic. Inventory caught this before I started deleting; without it, the streak system would have broken silently.

2. **`gamification_stats` was a view, not a table.** First DB-migration attempt failed with FK-dependency error. Reordering to drop the view first cleared it. Migration file in repo matches the working second-attempt SQL exactly.

3. **`get_leaderboard` had two overloads in prod**, only one was in the captured migrations. Both dropped via the migration file's `DROP FUNCTION IF EXISTS` lines for both signatures.

4. **A1 wasn't really a bug at the SQL layer.** The CTO's working hypothesis was "users row may survive delete despite Wave 2.5's CASCADE flips." MCP introspection ruled that out completely — every FK is CASCADE, RPC drops both auth and public users rows. Phase 9.0's client-side fix was the only fix needed; Phase 9.1.A just hardened it with the canonical wipe path.

5. **The user's expected "initial relatives picker / household setup" wizard does not exist in the app.** Surfaced as a product gap, not a deletion bug. Recommend either building it for v1.1 or aligning expectations with the empty-state flow.

---

## Open questions for the CTO

1. **Real-device verification of A1 + A2.** Founder needs to run these on a physical device. The carousel-fires-on-re-signin test specifically requires an actual Google OAuth round-trip.

2. **The missing setup wizard.** Should v1.1 build "choose your initial relatives" + "household setup" surfaces, or align user expectations with the current empty-state-CTA approach?

3. **Admin-panel seed cleanup.** Skipped in 9.1.B-db because the admin schema didn't match the spec's column assumptions. Tracked in [V1_1_BACKLOG.md](V1_1_BACKLOG.md). Doesn't bite users — admin-only.

4. **TestFlight rebuild.** No iOS-specific changes in Phase 9.1, but the build cache is from Phase 8. If founder wants to TestFlight again, a fresh `flutter build ipa` will pick up all the Dart-side cuts. Version stays at `2.1.0+1`; bump to `2.1.0+2` if uploading a new build.

5. **The 6 analyze infos/warnings.** Same as Phase 8. Not addressed because they're cosmetic and pre-existing. v1.1 cleanup candidate.

---

## Closing state

App is at version `2.1.0+1`. Streak engine + content enhancers + per-relative streaks + freeze system intact. Gamification stack — UI, services, providers, notification templates, DB columns/tables/views/functions — entirely gone. Per-user device state cleaned on every logout and account-delete via a single canonical path.

Two real-device verifications and one product-gap decision (the missing setup wizard) remain for the founder. Everything else lands clean.
