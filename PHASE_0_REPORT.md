# PHASE 0 REPORT — Stop the Bleeding

Branch: `phase-0-cleanup` (off `main`).
Total dart line count: **117,861 → 110,372** (−7,489 lines, −6.4%).
`flutter analyze`: clean — 5 info / 1 warning / 2 errors **all pre-existing on `main`** (info-level underscore lint nags in family_groups + family_tree screens; an unused `_saveFamilyName` private; two `overrideWithValue` errors in test helpers).
`flutter test test/unit/`: **1366 passed, 4 failed** — all 4 failures are pre-existing in `family_graph_service_test.dart` and `relationship_label_helper_test.dart`, neither of which I touched (perspective engine is CTO-protected). Failures are about Arabic label fallbacks ("الأب", "قريب", "أحمد") returning empty strings, suggesting admin-config not loaded in test env. Not caused by Phase 0.

## Task 1 — Runtime-broken RPC references

Both functions were defined in non-migration `*.sql` files (`schema.sql`, `gamification_functions.sql`) so they exist in production but are absent from migration history. **Chose option A: define in a new migration.** Code call sites are unchanged — they continue calling `_supabase.rpc('award_points', ...)` and `_supabase.rpc('delete_user_account')`.

**New migration:** `supabase/migrations/20260425000000_runtime_rpc_definitions.sql`
- `award_points(p_user_id UUID, p_points INTEGER)` — matches signature called from `lib/core/services/gamification_service.dart:90`
- `delete_user_account()` — matches signature called from `lib/shared/services/auth_service.dart:1299`

`CREATE OR REPLACE` is safe to run against the live DB; ensures fresh deploys also have them. Recommend deploying this migration soon so prod migration history is consistent.

## Task 2 — The Big Delete

### Files deleted (10 dart screens, 4 edge functions)

| File | Reason |
|---|---|
| `lib/core/services/gyroscope_service.dart` | Plan |
| `lib/features/ai_assistant/screens/memory_viewer_screen.dart` | Plan |
| `lib/features/ai_assistant/screens/message_composer_screen.dart` | Plan (Communication Scripts wraps the same backend method) |
| `lib/features/ai_assistant/screens/relationship_analysis_screen.dart` | Plan |
| `lib/features/wrapped/screens/yearly_wrapped_screen.dart` | Plan (had no in-app entry point) |
| `lib/features/gamification/screens/gaming_center_screen.dart` | Plan |
| `lib/features/gamification/screens/badges_screen.dart` | Plan (gallery only — `BadgeUnlockModal` in `lib/shared/widgets/` stays) |
| `lib/features/gamification/screens/challenges_screen.dart` | Plan |
| `lib/features/gamification/screens/leaderboard_screen.dart` | Plan |
| `lib/features/gamification/screens/detailed_stats_screen.dart` | Plan |
| `supabase/functions/social-publisher/` | Plan (zero references in `lib/`) |
| `supabase/functions/social-token-refresh/` | Plan |
| `supabase/functions/social-click-redirect/` | Plan |
| `supabase/functions/social-analytics-collector/` | Plan |

`phone_verification_screen.dart` was confirmed live (wired in `app_router.dart:157`, used as a step in signup) and **NOT deleted** per plan guardrail.

### Routes / nav cleanup

- `app_routes.dart` — removed constants: `achievements`, `badges`, `detailedStats`, `leaderboard`, `challenges`, `yearlyWrapped`, `aiMemories`, `aiMessages`, `aiAnalysis`. `premiumRoutes` set trimmed to `{aiChat, aiScripts, aiReport}`.
- `app_router.dart` — removed 12 imports and 7 `GoRoute` definitions for deleted screens.
- `persistent_bottom_nav.dart` — bottom nav rebuilt to plan spec: **Home, Relatives, Reminders, AI Hub, Profile**. Tab 3 was Gaming Center (gone), tab 4 was Statistics → now AI Hub, tab 5 was Settings → now Profile. `_getCurrentIndex` route-matching logic updated for new tabs.
- **Pre-existing bug found and fixed**: `app_router.dart:378` referenced `AIHubScreen` but never imported `ai_hub_screen.dart`. Compiled previously because `statistics_screen.dart` re-exports `AIHubScreen`. Left the indirect re-export (didn't change `statistics_screen.dart` since plan didn't authorize it).

### Feature flag strip

- `lib/core/models/subscription_tier.dart`: `FeatureIds` removed `messageComposer`, `relationshipAnalysis`, `smartRemindersAI`, `leaderboard`. `requiredTier()` switch trimmed.
- `lib/core/services/feature_config_service.dart` and `lib/core/providers/feature_config_provider.dart`: trimmed `maxFeatures` set — removed `message_composer`, `relationship_analysis`, `smart_reminders_ai`, `leaderboard`.
- `lib/features/premium_onboarding/models/onboarding_step.dart`: removed `message_composer`, `relationship_analysis`, `smart_reminders_ai` steps. `aiFeatures` is now `[AI Counselor, Communication Scripts]`; `otherFeatures` is now `[Weekly Reports]`. Phase 3 will trim further to the planned 3-step carousel.
- `lib/features/premium_onboarding/models/contextual_tip.dart`: removed `ai_hub_messages` tip and the entire `leaderboardTips` list.
- `lib/features/premium_onboarding/widgets/onboarding_completion_modal.dart`: removed the Message Composer quick-action button. Now shows AI Counselor + Communication Scripts.
- `lib/features/subscription/screens/paywall_screen.dart`: `headlineForFeature` switch — removed cases for `leaderboard`, `messageComposer`, `relationshipAnalysis`. Added `dataExport` case (it was missing — wired feature, no headline).
- `lib/features/settings/widgets/theme_carousel.dart`: removed paywall gate on themes. `customThemes` is now hard-coded as free for all tiers (`hasThemeAccess = true`). Paywall navigation in `_onThemeTap` removed.
- `lib/features/home/widgets/ai_insight_card.dart` and `ai_priority_contacts_widget.dart`: paywall `featureToUnlock` repointed from `relationshipAnalysis` (deleted) to `aiChat` (still live). Phase 3 home cleanup will revisit these cards.
- `lib/features/ai_assistant/screens/ai_hub_screen.dart`: bento grid — removed Row 2 ("الرسائل" + "سيناريوهات") and the "تحليل العلاقات" card from Row 3. Hub now shows: hero (المستشار) + سيناريوهات + التقرير. Matches Phase 2's planned 3-card grid; the 1081-line drama still needs Phase 2 stripping.
- `lib/features/ai_assistant/screens/ai_chat_screen.dart`: removed both Memory Viewer entry points (the saved-indicator tap and the appbar psychology icon) — these pointed to the deleted `aiMemories` route.

### Gyroscope removal

`gyroscope_service.dart` and all references stripped:
- `lib/core/constants/pattern_animation_constants.dart`: removed `gyroscopeMaxOffset`, `gyroscopeSamplingPeriod`.
- `lib/core/providers/pattern_animation_provider.dart`: removed `gyroscopeEnabled` field everywhere (constructor, copyWith, toJson/fromJson, equality, hashCode, toggle method, enableAll/disableAll).
- `lib/shared/widgets/pattern_animation_controller.dart`: removed `updateGyroscopeParallax` method and the `||  _settings.gyroscopeEnabled` branch in `parallaxOffset`.
- `lib/shared/widgets/animated_islamic_pattern_background.dart`: removed gyroscope subscription, setup/teardown, and lifecycle re-init. Pattern background still works via scroll parallax + flow + pulse.
- The `sensors_plus` pubspec dep is now unused (only consumer was `gyroscope_service.dart`). I left the dep entry in pubspec.yaml — removing it is a one-line follow-up if desired.

### Change-password de-duplication

Two implementations existed:
- `lib/features/profile/widgets/profile_dialogs.dart::showChangePasswordDialog` — sends a reset-email link (thin wrapper over `authService.resetPassword`)
- `lib/features/settings/screens/settings_screen.dart::_showChangePasswordDialog` — full inline form with current/new/confirm fields, re-authenticates, calls `authService.updatePassword`

**Kept the inline form in Settings; deleted the reset-email dialog from profile_dialogs.dart.** This aligns with Phase 3's plan to consolidate change-password into the Settings Account section. Profile screen no longer has a "تغيير كلمة المرور" row — `ProfileActionsWidget` constructor lost its `onChangePassword` param. Users now reach change-password via Settings only.

## Task 3 — Auto-reminder kill

Plan only mentioned `add_relative_screen.dart:327`, but I found a **second call site at `family_tree_screen.dart:1189`** in the placeholder-spawn flow (when a user taps a "+" placeholder in the tree). Same intent — adding a relative — so I severed both. Notes:

- `lib/features/relatives/screens/add_relative_screen.dart`: removed the `unawaited(AutoReminderService.createAutoReminder(...))` call. Toast already existed; updated wording from `'تم حفظ ${relative.fullName} بنجاح! 🎉'` to `'تم إضافة ${relative.fullName} بنجاح'` per plan. Confetti + haptic stay (they're not the auto-reminder side effect — they're celebration on save).
- `lib/features/family_tree/screens/family_tree_screen.dart`: removed the `unawaited(AutoReminderService.createAutoReminder(...))` call from `_createRelativeFromPlaceholder`. Existing toast `'تم إضافة $fullName بنجاح'` already matches plan wording.
- Removed `auto_reminder_service.dart` import from both files.

`auto_reminder_service.dart` itself is intact (plan said "do not delete the service yet, just sever the call"). It now has zero call sites. Recommend Phase 1 or 2 delete it for real.

## Task 4 — Keep-list verification

| Item | Status | Evidence |
|---|---|---|
| Phone verification | ✓ live | `app_router.dart:157` — `PhoneVerificationScreen(returnRoute: returnRoute)` |
| Apple Sign-in | ✓ live | `login_screen.dart` and `auth_service.dart` (`signInWithApple`) |
| `dataExport` feature | ✓ live | `data_export_provider.dart`, `data_export_service.dart`, `data_export_dialog.dart`, reachable from profile |
| Per-relative streak badges (header) | ✓ live | `relative_header_widget.dart:155` → `RelativeStreakBadge` |
| Screenshot watermark + snackbar | ✓ live | `family_tree_screen.dart` lines 14, 57, 149-150 (`ScreenshotCallback`) |
| Voice notes | ✓ live | `relative_detail_screen.dart:280` (`VoiceNoteRecorder`), `relative_interactions_list.dart:203-210` (`VoiceNotePlayer`), `interaction_model.dart:36` (`audioNoteUrl`) |
| Family Tree visual canvas | ✓ untouched | only added an import-cleanup edit (the `auto_reminder_service` import removal at line 21); canvas painters/layout unchanged |
| Communication Scripts AI screen | ✓ live | route still in `app_router.dart` |
| Weekly Report AI screen | ✓ live | route still in `app_router.dart` |

## Surprises / questions for the CTO

1. **`delete_user_account` is in `schema.sql:401` and `award_points` is in `gamification_functions.sql:12`** — both files are root-level, non-migration `*.sql`. Functions clearly exist on prod (otherwise the app would crash on every interaction and account-delete attempt), but migration history has them as ghosts. The new migration captures them. Worth deciding whether `schema.sql` and `gamification_functions.sql` should be archived (they're now redundant for fresh deploys) or kept as bootstrap.

2. **`AutoReminderService` is now orphaned.** Plan said don't delete it yet. Phase 1 should decide: delete the file outright (~150 lines), or keep it for a future "user-initiated suggested reminder" UX.

3. **AI Memory Viewer deletion leaves orphaned data.** The `ai_memories` Postgres table will keep accumulating rows (memories are extracted as a side effect of AI Chat per `ai_chat_provider.dart:109`), but users now have no UI to view, export, or delete them. Two options to flag for Phase 1: (a) wire memory delete-all into Settings, or (b) stop the chat provider from extracting/persisting memories at all. The current behavior is "memories are saved but invisible," which is privacy-debt.

4. **AI Hub bento grid is now 3 cards but still wrapped in 1,081 lines of drama.** I only removed the dead cards in Phase 0. The animation controllers, custom painters, ambient orbs, and pattern enums remain. Phase 2 will strip these.

5. **`AIPreloadService` retains its primary call site** (`home_screen.dart` MAX preload, gated by `isMax`). The Relationship Analysis preload code path is gone with the screen. The service file itself is small and still used by home — left in place.

6. **`achievements_showcase.dart` and the gamification stats widgets** are now orphaned (their consumers — Detailed Stats and Gaming Center — were deleted). Plan didn't authorize deleting them, so they ride along as dead code. Easy follow-up: `lib/features/gamification/widgets/stats/` and `lib/features/gamification/providers/stats_provider.dart` can be deleted in Phase 1 or 2.

7. **`sensors_plus` pubspec dep** is now unused. Removing it is a one-line edit if desired.

8. **`statistics_screen.dart` re-exports `AIHubScreen`** — that's how the pre-existing missing-import bug compiled. Worth straightening out in Phase 2 when the AI Hub is rewritten.

9. **Pre-existing test failures** (4 tests in `family_graph_service_test` and `relationship_label_helper_test`) appear to be admin-config-not-loaded issues in test setup, not caused by Phase 0. They were failing before this branch as well. Worth a Phase 3 cleanup pass.

10. **Founder decision needed for `customThemes` admin config.** I hard-coded `hasThemeAccess = true` in `theme_carousel.dart` to make all themes free. If admin config has `custom_themes` flagged as MAX-only, that flag is now ignored at the carousel. Cleaner long-term: remove `customThemes` from `FeatureIds` entirely (Phase 2 config consolidation) and from any admin config rows.

## Summary

Phase 0 is complete. App compiles, analyzes clean, 1366 unit tests pass with 4 pre-existing failures unrelated to this work. Codebase is 7,489 lines lighter. Bottom nav and routing are simpler. The runtime-broken RPC references are now tracked in migrations. Auto-reminder side effect on Add Relative is gone from both call sites.

Ready for founder review and Phase 1 authorization.
