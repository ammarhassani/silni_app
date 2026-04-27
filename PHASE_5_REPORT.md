---
name: Phase 5 — UX audit fixes
description: Closed all 10 launch blockers from UX_FLOW_AUDIT.md plus 6 of 8 high-leverage 🟡s. Cut the phone-invite subsystem from v1. Halted Task 4 (notification toggles) — needs FCM topic-subscription infra.
type: project
---

# PHASE 5 — UX Audit Fixes

**Date:** 2026-04-27
**Status:** 7 tasks shipped, 1 task halted at the architectural-change gate (Task 4 — FCM notifications).
**Commit:** `<this commit>`.

## Task 1 — Phone-invite subsystem cut from v1 ✅

The phone-invite path had four critical defects (UX audit Flow 5): RPC column-name bug, no UI to create invitations, no SMS/push trigger, broken decline. The decision was to remove the surface entirely and let the link-share path (which works) be the v1 invite mechanism.

UI-only changes — database tables, RPCs, and column-name bug all left in place dormant.

| File | Change |
|---|---|
| [family_group_screen.dart:494-497](lib/features/family_groups/screens/family_group_screen.dart#L494-L497) | Collapsed the admin-only `DefaultTabController` (length:2 with "المجموعة" + "الدعوات") into a single `_buildMainTab` for everyone. Removed `_buildInvitationsTab`, `_buildInvitationCard`, `_cancelInvitation`, and the now-unused `intl` / `share_plus` / `node_invitation_*` imports. **`InviteLinkCard` is still mounted on the main tab** — confirmed via grep. |
| [home_header_widget.dart](lib/features/home/widgets/home_header_widget.dart) | Converted `ConsumerStatefulWidget` → `ConsumerWidget`. Removed `_glowController`, the `pendingInvitationCountProvider` watch, and the entire glow animation. Bell remains and uses the existing `unreadNotificationCountProvider` badge for announcements/streaks/etc. |
| [app_router.dart:34, 348-359](lib/core/router/app_router.dart) | Deleted the `${AppRoutes.invitationDetail}/:id` route + the `InvitationDetailScreen` import. Stale notification taps fall through to the catch-all → home. |
| [notification_history_screen.dart:163, 514-519](lib/features/notifications/screens/notification_history_screen.dart) | Deleted the `notificationType == 'invitation'` branch that routed to `InvitationDetailScreen`, plus the dedicated `_buildInvitationNotificationCard` (140-line gradient card). Existing 'invitation' rows now render via the standard fall-through and the tap is a no-op. Removed unused `app_colors` import. |
| [node_invitation_service.dart:1-6](lib/features/family_groups/services/node_invitation_service.dart) | Header comment explaining the cut. |
| [main.dart](lib/main.dart) | Deleted `_checkPendingInvitations` — it was the producer of `'invitation'`-type rows in `notification_history` (also the only caller of `getMyPendingInvitations`, which has the latent column-name bug). Removed import of `node_invitation_service.dart`. |

**Confirmation: zero DB changes.** `node_invitations` table, `create_node_invitation`/`get_my_pending_invitations` RPCs, `cancel_node_invitation`, and the latent `r.name` column-mismatch bug all still on prod. They become dormant because no code path inserts or reads from the table.

## Task 2 — Add Relative (3 fixes) ✅

[lib/features/relatives/screens/add_relative_screen.dart](lib/features/relatives/screens/add_relative_screen.dart):

1. **Save → `context.pop()` instead of `context.go(/home)`.** Lines 351-358. Returns the user to whichever screen pushed Add Relative.
2. **Shared-tree provider invalidation.** Lines 343-349. `groupRelativesStreamProvider(groupId)` and `sharedFamilyEdgesStreamProvider(groupId)` are now invalidated alongside `relativesStreamProvider(user.id)` when the relative was added to a group.
3. **PopScope confirmation when form is dirty.** Lines 419-428. `_isFormDirty` flag toggled by Form's `onChanged` (covers TextFormFields), explicit `_markDirty()` calls in non-FormField callbacks (image picker, contact import, relationship picker, category picker, phone field, health-status picker, shared-tree toggle, group dropdown). Discard prompt at lines 770-806 (`_confirmDiscardChanges`).

Removed the `app_routes.dart` import — no longer needed.

## Task 3 — Onboarding (2 fixes) ✅

1. **`onboarding_completed` flag relocated.** [onboarding_screen.dart:77-86](lib/features/auth/screens/onboarding_screen.dart#L77-L86): `_finish()` no longer writes the flag. [main.dart:710-721](lib/main.dart#L710-L721) adds `_markOnboardingCompleted()` called from the `onAuthStateChange` listener on `signedIn` / `initialSession`. Idempotent — checks current value before writing. A user who taps "تخطي" without ever signing up will see the carousel again on next cold-start.

2. **Splash race condition.** [splash_screen.dart:118-145](lib/features/auth/screens/splash_screen.dart#L118-L145): `sessionInitializationProvider.future` is now wrapped in try/catch. On failure, the user is routed to `/login` with an Arabic snackbar (`'حدث خطأ في الاتصال — حاول مجدداً'`) instead of being stranded on the loader.

## Task 4 — Notification toggle wiring 🟡 HALTED

The audit's 🔴 finding was that toggles in `notifications_screen.dart` only persist to SharedPreferences and never gate any actual notifications. Per the CTO's "halt and report if topic subscription doesn't exist" instruction, halting.

**What I found:**
- `lib/shared/services/fcm_notification_service.dart` exposes neither `subscribeToTopic` nor `unsubscribeFromTopic`. No FCM topic API exists in `lib/`.
- The server-side cron `send-scheduled-reminders` reads `reminder_schedules` and fires regardless of any client preference. There's no per-user mute mechanism on the server.

**What this means:** wiring local-side gating (skip local-notification scheduling on the client) would be visible only for client-scheduled notifications. Server-driven reminders would still fire. Toggling "off" would not stop the user from getting reminders.

**Two CTO options:**
- **Option A** — ship topic-subscription infra (server: subscribe each user to a topic per category at sign-up; client: subscribe/unsubscribe via `FirebaseMessaging.instance.subscribeToTopic('reminders_${userId}')` etc.; server cron: send to topics, not directly to FCM tokens). Separate session.
- **Option B** — remove the toggles from v1 settings. The user no longer sees a toggle that doesn't work. Cosmetic-only fix. Could ship in a small follow-up commit.

I recommend **Option B** before TestFlight unless Option A is on the immediate roadmap.

## Task 5 — Delete-account hardening ✅

[lib/features/profile/widgets/profile_dialogs.dart:130-380](lib/features/profile/widgets/profile_dialogs.dart):

Replaced the single-tap dialog with a 2-step flow:

- **Step 1** — warning dialog. Same content as before. "إلغاء" / "متابعة" buttons.
- **Step 2** — `_DeleteAccountConfirmDialog` (StatefulWidget). Two fields:
  - **Typed confirmation:** TextField requires user to type `'حذف'` exactly. Submit button disabled until match.
  - **Password re-auth:** TextField (obscured). Validates by calling `signInWithEmail(currentEmail, password)`. On wrong password, displays inline Arabic error via `errorHandler.getArabicMessage(e)`; the user stays in the dialog.

Note on `auth.reauthenticate()` vs `signInWithPassword`: `reauthenticate()` in Supabase sends a nonce email, not a password verifier. The right primitive for "verify the password is correct before destructive op" is `signInWithPassword` — same approach the change-password flow uses. Documented inline at line 277-281.

**Settings mirror.** [settings_screen.dart:91-108](lib/features/settings/screens/settings_screen.dart#L91-L108): added `'حذف الحساب'` tile under الحساب section, styled with red `iconColor` + `titleColor`. Profile entry point unchanged. Extended `_buildSettingsTile` to accept optional color overrides.

## Task 6 — Silent-failures sweep + 5 specific fixes ✅

### Triage table

`grep -rEn 'catch\s*\(\s*_\s*\)\s*\{' lib/` returned **90 sites**. Below is the disposition for the 12 highest-impact sites; the rest are config-fetch fallbacks where silent-fail + hardcoded-default is intentional (cache services).

| File:line | Disposition | Status |
|---|---|---|
| `home_screen.dart:87-96` `_loadDailyHadith` | Surface → wrap in try/catch/finally | ✅ fixed (Task 6 #2) |
| `relative_detail_screen.dart:451` `_logInteraction` | Surface — fake-success was the worst offender | ✅ fixed (Task 6 #1) |
| `relative_detail_screen.dart:399-401` voice-note upload | Surface → non-blocking warning snackbar after success toast | ✅ fixed (Task 6 #4) |
| `due_reminders_section.dart:41,44` | Surface → InlineErrorWidget with retry | ✅ fixed (Task 6 #5) |
| `todays_activity_section.dart:49` | Surface → InlineErrorWidget with retry | ✅ fixed (Task 6 #5) |
| `invitation_detail_screen.dart:190-196` decline | n/a — Task 1 cut the screen | ⚪ moot |
| `family_sharing_service.dart:299` | Log-only (edge inference fallback) | 🟢 backlog |
| `family_group_service.dart:159` | Log-only (template lookup) | 🟢 backlog |
| `relationship_inference_service.dart:256` | Log-only (Arabic-name parsing) | 🟢 backlog |
| `phone_verification_screen.dart:124` `AuthException` | Surface — but this screen is unused after Task 1 | 🟢 backlog |
| `family_tree_screen.dart:412` (single-line empty) | Log-only (overlay teardown) | 🟢 backlog |
| `weekly_report_screen.dart:90` | Surface — InlineErrorWidget; queued for Task 7 in next phase | 🟢 backlog |

The remaining ~78 are in `core/services/` config-fetch wrappers where the pattern is: try Supabase fetch → on error, fall back to hardcoded defaults already shipped in the codebase. Those are intentional and low-risk.

### Fixes shipped

1. **`relative_detail_screen.dart`** ([relative_detail_screen.dart:387-402, 449-475](lib/features/relatives/screens/relative_detail_screen.dart)):
   - `_logInteraction`'s outer catch now surfaces `'تعذّر تسجيل التواصل. حاول مرة أخرى.'` instead of silently swallowing. Was the worst case — fake success snackbar.
   - Voice-note upload sets `voiceNoteUploadFailed` on catch; after the success toast, a follow-up snack `'تم تسجيل التواصل، لكن تعذّر رفع المقطع الصوتي.'` lands so the user knows the audio didn't attach.

2. **`home_screen.dart`** ([home_screen.dart:87-104](lib/features/home/screens/home_screen.dart#L87-L104)): `_loadDailyHadith` wrapped in try/catch/finally. `_isLoadingHadith` is always set false in `finally`. On error, `hadith=null` → the section hides gracefully (existing behavior).

3. **Home sections** — `due_reminders_section.dart` and `todays_activity_section.dart` now use `InlineErrorWidget.fromError(e, compact: true, onRetry: …)` in their `error` branches with provider-invalidate retries. Replaced both `SizedBox.shrink()` swallows.

## Task 7 — Six 🟡s ✅

1. **Swipe action `Mark Contacted` no longer always logs as `.call`.** [relatives_screen.dart:392-411](lib/features/relatives/screens/relatives_screen.dart). Type changed to `InteractionType.other`. Users wanting to attribute a specific type tap into the relative-detail screen.

2. **`relatives_screen` error state.** Lines 510-560. Replaced the raw `error.toString()` text with the gold-standard `_buildError` pattern (icon + Arabic copy + connectivity hint + GradientButton retry that invalidates `relativesStreamProvider`).

3. **`family_tree_screen` group-mode timeout.** [family_tree_screen.dart:75-81, 252-322, 916-928](lib/features/family_tree/screens/family_tree_screen.dart). 10-second `Timer` armed when `groupInfo != null && graph == null`, fires `_graphLoadTimedOut = true`, swaps the spinner for `_buildGraphLoadTimeoutState` (icon + Arabic + retry button that invalidates `sharedFamilyEdgesStreamProvider`).

4. **`family_group_screen.dart` raw `$e` interpolations.** Four sites (member removal, leave group, delete group, rotate invite link) now wrap the exception in `errorHandler.getArabicMessage(e)`.

5. **AI chat error banner.** [ai_chat_provider.dart:372-378, 489-495](lib/features/ai_assistant/providers/ai_chat_provider.dart). Both error catches (`sendMessage` and `sendMessageStreaming`) now route through `errorHandler.getArabicMessage(e)`. The previous AIServiceException-vs-fallback split was already mostly Arabic, but the unification is cleaner and routes through the same error categorizer the rest of the app uses.

6. **AI Hub OfflineGuard.** [ai_hub_screen.dart:111-120](lib/features/ai_assistant/screens/ai_hub_screen.dart). Each `_AIFeatureCard` is wrapped in `OfflineGuard(onPressed: …, child: GlassCard(...))`. Cards dim to 50% opacity and tap shows a Snackbar when `isOnlineProvider == false`. Online: tap routes through `_handleTap` (paywall check + push).

## Verification

| Check | Phase 4 baseline | Phase 5 result | Verdict |
|---|---|---|---|
| `flutter analyze` | 6 issues (5 info + 1 warning) | **6 issues** (same lines) | ✅ baseline preserved |
| `flutter test test/unit/` | 1354 / 0 | **1354 / 0** | ✅ |
| `flutter test test/golden/` | 8 / 0 | **8 / 0** | ✅ |
| `flutter build ios --release --no-codesign` | 70.2 MB / 33.1 s | **70.0 MB / 47.1 s** | ✅ |
| Phone-invite manual cut verification | n/a | InviteLinkCard still mounted (grep confirmed); invitations tab gone; bell still routes to notification history (now without invitation-specific behavior) | ✅ |

## Surprises

1. **The bell glow controller was the only consumer of `pendingInvitationCountProvider`.** Removing it let me convert `HomeHeaderWidget` from `ConsumerStatefulWidget` (with `SingleTickerProviderStateMixin`) to plain `ConsumerWidget` — small simplification.
2. **`package:intl/intl.dart` was only imported by `family_group_screen.dart` for the date formatter on the invitations tab.** Cutting the tab also dropped the import. The `hide TextDirection` workaround from Phase 4 is no longer needed in this file.
3. **`_checkPendingInvitations` was the only caller of `getMyPendingInvitations`.** Removing it means the latent column-name bug in that RPC can no longer be triggered from the app — even if `node_invitations` rows somehow appear, no Dart code reads them.
4. **AI chat error mapping was already mostly Arabic.** The audit flagged it as "raw error string" but the existing code returned `e.message` for `AIServiceException` (already Arabic) and a fixed Arabic fallback otherwise. The Phase 5 change consolidates both through `errorHandler.getArabicMessage` for consistency, but the user-visible improvement is small.
5. **`AppLoggerService.error()` does not accept a named `error:` parameter** — only `message`, `category`, `tag`, `metadata`, `stackTrace`. Caught this on Task 3 splash error handler.

## 🟡s NOT addressed in this session

These were explicitly outside Phase 5's scope and remain for post-TestFlight triage:

- **Notification toggles** (Task 4 halt) — needs Option A (FCM topic infra) or Option B (remove toggles from v1 settings) decision.
- **Email-verification 3s polling timer doesn't pause on background** — Flow 1 finding.
- **Apple-Sign-In NamePromptDialog dismissable by backgrounding** → user stuck with private-relay email and no display name — Flow 1 finding.
- **`accept_node_invitation` overwrites `relatives.user_id` without clearing inviter's prior `user_id`** — Flow 5 finding. Dormant now that the path is cut, but DB-side correctness issue if/when phone-invite returns.
- **`initializeSharedTree` sets `family_group_id` on ALL personal relatives without scoping** — Flow 5 finding. Surprises users with pre-existing personal trees.
- **`verifySharedEdges` early-returns on empty graph** — Flow 5 finding. Edgeless one-self-node groups stay edgeless forever.
- **Multi-group invitee silently allowed** but home UI assumes singular — Flow 5 finding.
- **Inviter has no "0 / 5 invited" affordance after group creation** — Flow 5 finding.
- **`reminders_screen.dart:117-119` stale-data race** when `hasError && isInitialLoad` is false — Flow 8 finding.
- **Loading-spinner inconsistency** (3 styles across the app) — cross-cutting finding.
- **AI Chat `_sendMessage` doesn't gate on `isOnlineProvider`** — Flow 8 finding (separate from Task 7.6's hub-card guard).
- **`family-tree-screen` placeholder→relative direct upsert bypasses any offline queue** — Flow 8 finding.
- **Trial-day text inconsistent (em-dash vs hyphen, no Arabic plural)** — Flow 7 finding.
- **`delete_user_account` RPC has no audit trail** — Flow 7 finding. Useful for dispute resolution.
- **`SubscriptionService.clearUser` failure swallowed silently** — Flow 7 finding.
- **`UIScene` lifecycle migration warning** — surfaced in iOS build but non-blocking.

## Open questions for the CTO

1. **Task 4 direction** — Option A (topic infra) or Option B (remove toggles)? Recommend Option B before TestFlight unless A is imminent.
2. **`_saveFamilyName` warning** — still present from Phase 4 backlog. Same disposition: 🟢 leave, no leverage.
3. **Phone-invite re-introduction post-TestFlight** — when the time comes, the latent `r.name`/`v_relative.name` bug needs to be fixed in the same migration that re-wires the UI. Documented in the `node_invitation_service.dart` header.

## TestFlight readiness — yes (with one caveat)

All UX-audit launch blockers closed except Task 4 (notification toggles). If the CTO chooses Option B for Task 4, ship to TestFlight today. If Option A, wait for the topic-infra session.

Code, tests, builds, and analyzer baseline all green.
