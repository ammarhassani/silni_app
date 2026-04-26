---
name: UX Flow Audit — pre-TestFlight
description: 8 user-flow maps with severity-classified findings. No code changes. Method: 5 parallel general-purpose subagents + 3 in-context flows + cross-cutting synthesis.
type: project
---

# UX FLOW AUDIT — Pre-TestFlight Discovery

**Date:** 2026-04-26
**Format:** findings only — no code changes. Eight user-flow traces + cross-cutting synthesis. Severity tags: 🔴 launch blocker · 🟡 pre-launch worth fixing · 🟢 post-launch backlog · ⚪ documentation only.

## Executive summary

### 🔴 Launch blockers (10)

| # | Flow | Finding | Recommendation (one-liner) |
|---|---|---|---|
| 1 | 1 onboarding | `onboarding_completed=true` is set when user taps "تخطي"; signed-out users never see the carousel again, no Settings entry | gate the flag on signup-success only, or expose "Replay tour" |
| 2 | 1 onboarding | Splash race: if Supabase init throws, `sessionInitializationProvider` errors and user is stranded on the loader | handle the FutureProvider error, route to login with banner |
| 3 | 2 add relative | Save always navigates to Home, regardless of entry point — user loses context | `context.pop()` instead of `context.go(home)` |
| 4 | 2 add relative | Shared-tree provider not invalidated on save — new shared relative may not appear until manual refresh | invalidate `groupRelativesStreamProvider` + `sharedFamilyEdgesStreamProvider` |
| 5 | 2 add relative | Form data silently lost on back-press / swipe-back, no "discard?" guard | add `PopScope` confirmation when form is dirty |
| 6 | 5 invite | `create_node_invitation` and `get_my_pending_invitations` RPCs reference `r.name`/`v_relative.name` — column is `full_name` (MCP-confirmed) | rename column reference to `full_name` in both RPCs |
| 7 | 5 invite | No UI to create phone-based node invitations; `createInvitation` has zero callers — entire phone-invite system dead-on-arrival | add an "Invite by phone" entry point on relative-node / group screen |
| 8 | 5 invite | No SMS or push triggered on `node_invitations` insert — invitee never knows they were invited | trigger SMS or push on insert |
| 9 | 7 settings | Notification toggles only persist to SharedPreferences; never read by FCM/local-notif gating — toggles are cosmetic | wire each toggle into the service (subscribe/unsubscribe topic + skip local schedule) |
| 10 | 7 settings | Delete-account warning is a single dialog, single tap; no typed confirmation, no re-auth | add typed-string confirm OR password re-prompt |

### Top 5 highest-leverage friction fixes

(regardless of severity — these will be felt by the most users)

1. **Add Relative always lands on Home** (#3 above). Every Add-Relative flow ends with disorientation.
2. **Notification toggles are cosmetic** (#9). Users will mute and still get pings.
3. **`_logInteraction` swallows failures silently** (Flow 3). User sees a success snackbar even when the create failed and triggers a retry that may not happen.
4. **Decline invitation does nothing server-side** (Flow 5). Bell glows forever.
5. **`_loadDailyHadith` has no try/catch — leaves home spinner forever on error** (Flow 8 hang).

### Cross-cutting issues (affect ≥2 flows)

- **Loading spinner inconsistency:** `PremiumLoadingIndicator` (most), `CircularProgressIndicator(Colors.white)` (family tree, group buttons), skeleton loaders (home sections). Three distinct styles. (Flows 4, 5, 7, 8.)
- **Error-state inconsistency:** some screens render retry buttons; others swallow errors into `SizedBox.shrink()`; others interpolate raw exception strings into Arabic copy. (Flows 1, 2, 5, 7, 8.)
- **No screen consumes `isOnlineProvider`** despite a global `AnimatedOfflineBanner` and an unused `OfflineGuard` widget existing. AI calls, mutations, share actions all proceed regardless. (Flows 6, 8.)
- **Silent-fail patterns recur:** onboarding flag never resets; notification toggles cosmetic; `_logInteraction` swallows; decline → no-op; ensure_user_record swallows. (Flows 1, 3, 5, 7.)
- **Navigation contracts uneven:** Add Relative uses `context.go(home)` post-save; notification taps use navigateTo + 100ms delay + push; decline uses `pop()`. Three different "where am I after this action" patterns. (Flows 2, 4, 5.)

---

## Flow 1 — First-run onboarding

### Flow map (condensed)

1. App launches → `main()` initializes Supabase / Hive / Firebase / Sentry [main.dart:56-454].
2. ProviderScope mounts, MaterialApp.router shows full-screen "جاري التحميل" loader while `sessionInitializationProvider` resolves [main.dart:822-847].
3. GoRouter `initialLocation = '/splash'`; redirect short-circuits for splash so SplashScreen owns navigation [app_router.dart:51, 81-84].
4. SplashScreen plays glow/shimmer for ~1.5s while preloading fonts [splash_screen.dart:38-53].
5. SplashScreen calls `sessionInitializationProvider` → `AuthService.checkPersistentSession` [splash_screen.dart:118; auth_provider.dart:40-46].
6. If no session → reads SharedPreferences `onboarding_completed` [splash_screen.dart:128-138].
7. First run (key absent) → `context.go('/onboarding')` [splash_screen.dart:136].
8. OnboardingScreen — 4-page PageView; "تخطي" / "ابدأ الآن" buttons [onboarding_screen.dart:27-130].
9. `_finish()` writes `onboarding_completed=true` and `context.go('/login')` [onboarding_screen.dart:77-85].
10. LoginScreen renders gradient + glass form, "إنشاء حساب جديد", Google + Apple (iOS only) [login_screen.dart:1001-1138].
11. SignUpScreen Form: name (≥2), email (regex), password (≥8 + upper + lower + digit) [signup_screen.dart:330-444].
12. `_signUp()` calls `signUpWithEmail` with 30s timeout [signup_screen.dart:77-93].
13. Email-not-verified → `EmailVerificationScreen` polls every 3s via `refreshSession` [email_verification_screen.dart:53-107].
14. Post-verification → `context.go('/home')` [email_verification_screen.dart:84-97].
15. `main.dart` auth listener fires `ensure_user_record` + `getMyPendingInvitations` on signedIn [main.dart:654-668].
16. HomeScreen mounts, zero relatives → `FamilyCirclesWidget` shows "إضافة أول قريب" CTA [family_circles_widget.dart:393-427].
17. AddRelativeScreen → save → confetti + snack → `context.go('/home')` [add_relative_screen.dart:171-349].

### Findings

- 🔴 **`onboarding_completed=true` is permanent.** Set on "تخطي"; signed-out users never see the carousel again, no "Replay tour" in Settings. — Recommendation: gate flag on signup-success only.
- 🔴 **Splash race when Supabase init fails.** Init exception swallowed but `sessionInitializationProvider` still throws → loader hangs. [main.dart:173-182; splash_screen.dart:118] — Handle the future-error.
- 🟡 **No first-run "log your first interaction" prompt.** Add-relative success → home with confetti, no targeted CTA. — Add a one-shot tooltip after the first relative is added.
- 🟡 **Email verification polls every 3s indefinitely.** Backgrounding doesn't pause the timer. [email_verification_screen.dart:53-107] — Pause in `didChangeAppLifecycleState`.
- 🟡 **Forgot-password dialog shows generic success on missing-account.** [login_screen.dart:570-591] — Surface distinct feedback.
- 🟡 **Login `_isLoading` never reset on success.** If `context.go(/home)` is intercepted, screen stuck on spinner. [login_screen.dart:374-383] — Reset in `finally`.
- 🟡 **Apple-Sign-In NamePromptDialog dismissable by backgrounding** → user stuck with private-relay email and no display name. [login_screen.dart:719-736] — Make name a blocking step.
- 🟡 **AddRelative defaults to `RelationshipType.brother`.** First-ever add for "mother" requires picker change. [add_relative_screen.dart:58] — Leave un-prefilled.
- 🟢 **Splash hard-coded 1.5s delay** + font preload adds cold-start latency. — Race delay against session restoration.
- 🟢 **Signup → verification has no "we sent a code to {email}" toast** [signup_screen.dart:126-140]. — Add transient snackbar on transition.
- ⚪ **App-resume refreshes 7 config services but doesn't re-validate session freshness** [main.dart:766-780]. — Note for QA.
- ⚪ **Phone-verification screen reachable via router but unused in email signup** [app_router.dart:149-160].

---

## Flow 2 — Add Relative

### Flow map (5 entry points)

1. Home → Family Circles "+" tile [family_circles_widget.dart:57]
2. Home → empty-state "إضافة أول قريب" CTA [family_circles_widget.dart:421]
3. Relatives tab → empty-state CTA [relatives_screen.dart:456]
4. Relatives tab → floating "+" FAB [relatives_screen.dart:555]
5. Avatar carousel "+" tile [avatar_carousel.dart:342]

User steps:
6. Header with back arrow → "إضافة قريب" title [add_relative_screen.dart:657-678].
7. CTA "اختر من جهات الاتصال" opens `ContactImportScreen(singleSelect: true)` [add_relative_screen.dart:128-138].
8. OR "إضافة يدوياً" expands form (`_manualExpanded = true`) [add_relative_screen.dart:418-479].
9. Form: photo / name (req) / `FlatRelationshipPicker` / shared-tree toggle (if user has a group) / category / phone (optional, no validator) / health status / notes [add_relative_screen.dart:483-624].
10. Save → photo upload → `inferEdges` → `family_edges` upsert → confetti + haptic + snackbar [add_relative_screen.dart:171-349].
11. `ref.invalidate(relativesStreamProvider(user.id))` — only personal stream [add_relative_screen.dart:341].
12. 400ms delay → `context.go('/home')` [add_relative_screen.dart:349].

### Findings

- 🔴 **Save always navigates to Home, regardless of entry point.** — Use `context.pop()`.
- 🔴 **Shared-tree provider not invalidated on save.** Group views may not show new relative until manual refresh. — Invalidate `groupRelativesStreamProvider` + `sharedFamilyEdgesStreamProvider`.
- 🔴 **Form data lost on back-press, no "discard?" guard.** [add_relative_screen.dart:667] — Add `PopScope`.
- 🟡 **Phone has no validation despite using `IntlPhoneField`** [add_relative_screen.dart:549-590]. — Use the field's built-in validator.
- 🟡 **Validation only fires on Save** — set `autovalidateMode: AutovalidateMode.onUserInteraction`.
- 🟡 **Default relationship = "brother"** [add_relative_screen.dart:58]. — Start un-prefilled or with the most-likely missing singleton.
- 🟡 **Field ordering scrambles identity vs metadata.** Photo → name → relationship → shared-tree → category → phone → health → notes. — Group identity (photo/name/phone) before metadata.
- 🟡 **No DOB / email / address fields.** `Relative.email` is passed `null` [line 213]. — Confirm product intent.
- 🟡 **Multi-group dropdown has no group-context affordance.** — Replace with cards showing group name + member preview.
- 🟢 **Photo picker on web uses identical branches** [line 700-708]. — Collapse the `kIsWeb` ternary.
- 🟢 **`_isFavorite` always false; `_priority` auto-set silently.** — Remove or expose.
- 🟢 **Manual-toggle row is one-way** [line 437-478]. — Add collapse handle.
- 🟢 **Confetti + 400ms delay before navigation overlays the snackbar.** — Run animation in parallel.
- ⚪ **5 entry points all `context.push`; save uses `context.go(home)` — inconsistent stack.**
- ⚪ **`persistent_bottom_nav.dart:284` treats addRelative as Relatives tab** but Home reaches it too.

---

## Flow 3 — Log Interaction

### Flow map

Entry points (all live):
1. **Relative card swipe** → `onMarkContacted`: silently creates `InteractionType.call` with notes `'تواصل سريع'` [relatives_screen.dart:392-405]. ⚠️ type misattribution — could've been a message.
2. **Relative detail → call/whatsapp/sms one-tap** via `ContactLauncher`; on success → `_logInteraction(type, …)` [relative_detail_screen.dart:336-355].
3. **Relative detail → Visit / Gift / Event tile** → `_showInteractionDialog` AlertDialog with notes TextField (3 lines, RTL) + `VoiceNoteRecorder` [relative_detail_screen.dart:217-310].

Path 3 detail:
4. User types notes (optional), optionally records voice note.
5. On confirm → `_logInteraction` creates `Interaction`, calls `interactionsRepository.createInteraction`.
6. If voice path is non-null → `SupabaseStorageService.uploadVoiceNote` then `repository.updateInteraction({audio_note_url})` [lines 386-402].
7. Compute points via `gamificationService.calculateInteractionPoints`.
8. Read `relativeStreakService.getRelativeStreak` for the streak count.
9. **Three success-snackbar variants:** milestone (7/14/30/50/100), non-zero streak, zero streak [lines 426-449].
10. Failure path — bare `catch (_)` [line 451] — silent, no user feedback.
11. `_isLoggingInteraction` 2s guard window prevents accidental double-logs [lines 364, 454].

### Findings

- 🔴 **`_logInteraction` failure is silently swallowed** [relative_detail_screen.dart:451] — user sees no success and no error; thinks it logged. — Add an inline error snackbar; don't let the user think it succeeded silently.
- 🟡 **Swipe-action "Mark Contacted" always logs as `InteractionType.call`** [relatives_screen.dart:399]. User may have just sent a WhatsApp; the type is wrong. — Either rename the action to "تواصل" + `InteractionType.other`, or prompt for type.
- 🟡 **Three near-identical success snackbar variants** [lines 426-449] — could collapse to one with conditional suffixes; cleaner code, identical UX.
- 🟢 **2s guard window is timer-based, not state-based** [line 454] — racy if `mounted` flips during the await. — Replace with `_isLoggingInteraction = false` set inside the success path.
- 🟢 **Voice-note upload failure is `debugPrint`** [line 400] — user thinks the audio was attached. — Either retry or surface a snack.
- ⚪ **The interaction-log "screen" doesn't exist as a screen** — it's an AlertDialog plus implicit logging from contact actions. Friction is low (1-3 taps), but discoverability of "what counts as an interaction" is opaque to a new user.

---

## Flow 4 — Reminder firing + receiving

### Server side (already audited in DISCOVERY_AUDIT Cat 2)

- Cron `* * * * *` checks `reminder_schedules.time = HH:mm` (Riyadh UTC+3) [send-scheduled-reminders/index.ts].
- Builds consolidated push: title = `schedule.custom_title` or `'تذكير يومي/أسبوعي/...'`; body = `schedule.custom_message` or `'حان وقت التواصل مع {names}'`.
- Phase 4 fix: `last_sent` only updates on confirmed FCM delivery.
- Offline user: notification queues at FCM, delivered when device reconnects (FCM behavior, not app).

### Client side

1. `FirebaseMessaging.onMessageOpenedApp.listen` → `_handleNotificationTap` [fcm_notification_service.dart:334].
2. Local-notif tap (foreground) → `onDidReceiveNotificationResponse` → same handler [line 159].
3. For `type == 'reminder'`:
   - `NavigationService.navigateTo(home)` [line 438]
   - 100ms delay
   - `pushTo('/reminders-due?ids=…')` [line 440]
4. For `type == 'streak'` → home → 100ms → push to `/statistics` [lines 456-459].
5. For `type == 'achievement'` → home → 100ms → push to `/profile` [lines 462-466].
6. For `type == 'announcement'` → home only, **no deep_link handling** despite the announcement model carrying a `deep_link` field [line 470].
7. Home-screen ambient state: `DueRemindersCard` derives from `todayDueRelativesProvider((schedules, relatives))` [home_screen.dart consumed in widgets/due_reminders_card.dart].

### Findings

- 🟡 **Notification body lists relative names but no deep-link to a specific relative** — the body says `"حان وقت التواصل مع {names}"`, tap → consolidated `RemindersDueScreen`. User can't tap "أمي" specifically and land on Mom's detail. — Send a per-relative deep link OR add tappable chips on `RemindersDueScreen`.
- 🟡 **`announcement` type ignores `deep_link`** [line 470]. The admin can author a deep-link in `admin_announcements` but it has no effect. — Implement deep-link routing for announcements OR remove the field.
- 🟢 **100ms delay between `navigateTo(home)` and `pushTo(remindersDue)`** [lines 438-440] is fragile — racy on slow first-render. — Guard with a future that completes after home renders, OR navigate to `remindersDue` directly with home in the back stack.
- 🟢 **No special handling for "user is already on remindersDue when notification arrives"** — they get bounced to home then back to a fresh `RemindersDueScreen`.
- ⚪ **iOS / Android channel config is in `fcm_notification_service.dart:170-182`** with a custom raw sound `silni_default` — confirm the asset is shipped in `android/app/src/main/res/raw/`.

---

## Flow 5 — Family group invite + join

### Flow map — Inviter

1. `/create-family-group` → 3-step wizard (name → review → done) [create_group_screen.dart].
2. Step 2 review shows all personal non-archived relatives that will become shared — no opt-out per relative [lines 324-459].
3. `_createGroup` → `FamilySharingService.initializeSharedTree` → `create_group_atomic` RPC + self-node insert + `family_group_id` set on every personal non-archived relative [family_sharing_service.dart:21-96].
4. Step 3 "دعوة أفراد العائلة" → `FamilyGroupScreen` [create_group_screen.dart:529-536].
5. `InviteLinkCard` exposes copy / WhatsApp share / generic share / rotate-code [invite_link_card.dart:29-209]. Format: `https://silniapp.com/join/<code>`.
6. "الدعوات" tab lists `node_invitations` with status, masked phone, resend (generic share), cancel [family_group_screen.dart:495-520, 739-790].
7. **No UI anywhere creates `node_invitations`** — `NodeInvitationService.createInvitation` has zero callers.

### Flow map — Invitee (Path A — public link, the only working channel)

8. Tap link → router strips scheme → `JoinGroupScreen` [app_router.dart:336-345].
9. `lookup_group_by_invite_code` RPC, 15s timeout [join_group_screen.dart:52-112].
10. If unauthenticated → "سجّل دخولك أولاً" → login with `?redirect=/join/<code>` [lines 345-363].
11. If already a member → "أنت عضو بالفعل" + "عرض المجموعة" [lines 315-344].
12. Tap "انضم للمجموعة" → `FamilyGroupService.joinGroup` → `join_group_by_invite_code` RPC + `verifySharedEdges` + fire-and-forget `_sendJoinNotification` [family_group_service.dart:77-162].
13. Post-join: `getMyPendingInvitations` → if matching node-invitation found → `InvitationDetailScreen`; else → `/family-tree` [join_group_screen.dart:144-161].

### Flow map — Invitee (Path B — phone node-invitation, broken)

14. Discovery only via the bell-glow on `home_header_widget` [lines 59-72, 113-138]. No banner, no SMS.
15. Tap bell → `notification_history_screen` [line 109]. Only `notificationType == 'invitation'` rows route to `InvitationDetailScreen` — and **no code path inserts those rows**.
16. `InvitationDetailScreen.initState` calls `getMyPendingInvitations` (filtered by verified phone), accept → `accept_node_invitation` RPC [lines 83-142].
17. "رفض" only `pop()`s — does NOT call `cancel_node_invitation`; the row stays pending forever [lines 144-197].

### Findings

- 🔴 **`create_node_invitation` and `get_my_pending_invitations` RPCs reference `r.name` / `v_relative.name`; the column is `full_name`** (MCP-confirmed on prod). Latent bug today (no rows exist), instant launch blocker the moment the table gets a row. — Rename column references to `full_name`.
- 🔴 **No UI calls `createInvitation`** — phone-invite system is dead-on-arrival from the inviter side. — Add an "Invite by phone" entry point on the relative-node / group screen.
- 🔴 **No SMS or push triggered on `node_invitations` insert** — even if the inviter manually called the RPC, the invitee would only discover via the bell on next sign-in. — Trigger SMS or push on insert.
- 🟡 **"رفض" does nothing server-side** [invitation_detail_screen.dart:190-196] — bell glows forever. — Wire decline to `cancel_node_invitation` (or a new "decline" RPC).
- 🟡 **"إعادة إرسال" on admin's invitations tab is just `Share.share` of a generic link** [family_group_screen.dart:903-920] — does not reference the invitation, the relative, or include `?rid=`. — Either send the actual deep link OR remove the button.
- 🟡 **Inviter cannot see when invitee joined via the link.** `_sendJoinNotification` pings members, but the "الدعوات" tab tracks only `node_invitations`. — Add realtime stream on `family_group_members`.
- 🟡 **`initializeSharedTree` sets `family_group_id` on ALL the user's personal relatives** (no scoping) — silently merges any pre-existing personal tree into the new group [family_sharing_service.dart:71-77]. — Confirm intent or scope the migration.
- 🟡 **`verifySharedEdges` early-returns if `existingEdges.isEmpty`** — a one-self-node group stays edgeless forever [family_sharing_service.dart:253]. — Generate baseline edges for empty graphs.
- 🟡 **`_sendJoinNotification` template lookup may fail silently** if `family_join_1` row not seeded in env [family_group_service.dart:135-142]. — Surface a debug log.
- 🟡 **`accept_node_invitation` overwrites `relatives.user_id`** without clearing inviter's prior `user_id` [20260308100001_invitation_rpcs.sql:180-183]. — Audit user_id semantics on claim.
- 🟡 **Multi-group is silently allowed** — invitee can be in N groups, but home UI uses singular `userFamilyGroupProvider`. — Decide: support multi-group or block.
- 🟢 **No "0 / 5 invited" affordance for inviter post-create** — the new admin lands on an empty member list with no progress signal.
- 🟢 **`getInvitationForRelative` exists but is unused** [node_invitation_service.dart:71-85].
- 🟢 **Invite-link rotation invalidates old links without warning the admin** about already-shared copies.
- 🟢 **Invitation list lacks empty/error retry** — only a centered icon.
- ⚪ **`nodeInvitationServiceProvider` defined twice; `_prefillGroupName` empty** [create_group_screen.dart:47-49].
- ⚪ **"ستنضم كـ" copy assumes the relative's name is frozen at invite time**, but the join screen joins live `relatives` row — stale if admin renames.

---

## Flow 6 — AI Hub (post-Phase-2 trimmed)

### Flow map

1. AI Hub reachable via persistent bottom nav [ai_hub_screen.dart].
2. `GlassPillTitle` with name "هلال" (or AIIdentity.name) + Arabic subtitle.
3. `MessageWidget(screenPath: '/ai-hub')` — slot for admin-driven banner messages.
4. **Three GlassCards (the only content):**
   - **المستشار** — Icons.psychology_rounded — `AppRoutes.aiChat` — featureId `aiChat` [lines 60-68].
   - **سيناريوهات التواصل** — Icons.record_voice_over_rounded — `AppRoutes.aiScripts` — featureId `communicationScripts` [lines 70-77].
   - **التقرير الأسبوعي** — Icons.analytics_rounded — `AppRoutes.aiReport` — featureId `weeklyReports` [lines 79-84].
5. Each card's `_handleTap` checks `featureAccessProvider(featureId)`; if no access, `MaterialPageRoute → PaywallScreen(featureToUnlock)` [lines 160-174].
6. AI Chat: streaming with `chatState.isStreaming` flag; per-message typing indicator [ai_chat_screen.dart:498-524].
7. AI Chat error state: inline `_buildErrorBanner` above input, dismissable with X [ai_chat_screen.dart:524-554].
8. AI Chat empty state: suggested-prompts list (good UX).

### Findings

- 🟡 **AI Hub has no offline awareness** — feature cards stay tappable; paywall resolves; deep screens fail downstream. The unused `OfflineGuard` widget exists. — Wrap cards in `OfflineGuard` to dim/disable.
- 🟡 **AI chat error banner shows raw error string from `chatState.error`** — likely "Failed to fetch" or HTTP body — not user-friendly Arabic. — Map errors to Arabic messages via the existing `error_handler_service`.
- 🟢 **AI Hub itself has no loading state** because it's static — but if `featureAccessProvider` is async (it's not currently), loading could matter. — Note for future.
- 🟢 **`AIIdentity.name` is "هلال" hardcoded** — confirm branding intent. — Document in product copy guide.
- ⚪ **"AI-Generated Content" badge from Phase 1 lives in `chat_message_bubble.dart`** — unverified in this audit, but visually present on AI replies per Phase 2 deliverables.

---

## Flow 7 — Settings + account management

### Flow map

**الحساب (Account)** [settings_screen.dart]:
1. Profile tile → `/profile` [line 62].
2. Change password tile → in-screen `AlertDialog` `_showChangePasswordDialog` [line 69 → :261].
3. Sign-out tile → `signOut` + `clearUserSessionFromWidget` + `context.go(/login)` [lines 72-90].

**التطبيق (App)**:
4. Theme picker (`ThemePickerButton`) [line 95].
5. Notifications tile → `/notifications` [line 101].
6. Invite friend → `Share.share(...)` [lines 104-122].
7. Rate app → `InAppReview.requestReview` / fallback [lines 124-138].

**الاشتراك (Subscription)**:
8. `SubscriptionCard` [lines 143-148]:
   - Free → "ترقية الآن" → `PaywallScreen`.
   - MAX → "إدارة" → App Store / Play Store deep-link.
   - "استعادة المشتريات" → `SubscriptionService.restorePurchases`.

**Change-password** (single dialog):
9. New pwd validates ≥8 + upper + lower + digit [lines 351-364].
10. Re-auth via `signInWithEmail` [line 414].
11. `updatePassword(newPassword)` → `_supabase.auth.updateUser` [auth_service.dart:795].

**Notification preferences** [notifications_screen.dart]:
12. `_loadSavedPreferences` reads SharedPreferences keys [lines 53-72].
13. Each toggle → `setState` + `_savePreference` to SharedPreferences [lines 75-82].
14. **Toggle values are never sent to the FCM service.**

**Subscription**: cancel/downgrade only via App Store / Play Store [subscription_card.dart:533].

**Delete-account** (lives on Profile, not Settings):
15. `profile_screen.dart:229` → `showDeleteAccountDialog` [profile_dialogs.dart:131].
16. Single warning dialog: amber note about unaffected subscription. **No re-auth, no typed confirmation, no double-confirm** [lines 152-165].
17. Tap "حذف" → spinner → `authService.deleteAccount` → `delete_user_account` RPC [lines 191; auth_service.dart:1272-1328].
18. RPC: `DELETE FROM users` + `DELETE FROM auth.users`. SubscriptionService.clearUser (best-effort). `auth.signOut`. Navigate to /login + "تم حذف حسابك بنجاح".

### Findings

- 🔴 **Notification toggles are cosmetic** — only persist to SharedPreferences; never read by FCM/local-notif gating. — Wire into the service.
- 🔴 **Delete-account warning is too weak.** Single dialog, single tap, no typed confirmation, no re-auth. App Store 5.1.1(v) + panicked-user risk. — Add typed-string OR password re-prompt.
- 🟡 **Delete-account is unreachable from Settings** — only in Profile. Discoverability gap during App Store review. — Mirror the link in الحساب section.
- 🟡 **Change-password dialog never disposes its controllers** [settings_screen.dart:473-475] — admitted in code comment. — Use a StatefulWidget.
- 🟡 **Re-auth uses `signInWithEmail`** — Supabase has dedicated `auth.reauthenticate()`. — Switch.
- 🟡 **No language/locale picker exists.** App is Arabic-only; no toggle. — Decide explicitly.
- 🟡 **"Manage subscription" silently fails on web/desktop** — `Platform.isIOS/Android` checks fall through. — Add fallback URL.
- 🟢 **Restore-purchases UX split** — two buttons (`SubscriptionCard`, `PaywallScreen`) with different feedback (snack vs congrats dialog). — Unify.
- 🟢 **Trial-day text inconsistent** — em-dash vs hyphen across two cards; no Arabic plural for `أيام`/`يوم`/`يومان`. — Add helper.
- 🟢 **`delete_user_account` RPC has no audit trail** — no `deleted_users` table. — Add audit row before DELETEs.
- 🟢 **`SubscriptionService.clearUser` failure swallowed** [auth_service.dart:1315-1322] — RevenueCat may retain the alias. — Surface a non-blocking warning.
- 🟢 **Sign-out tile uses `showChevron: false`**; profile-side logout uses chevron — inconsistent.
- ⚪ **Admin env badge gated on hard-coded email `azahrani337@gmail.com`** [settings_screen.dart:216-258].

---

## Flow 8 — Empty / loading / error / offline states

### Per-screen state matrix

| Screen | Empty | Loading | Error | Offline |
|---|---|---|---|---|
| Home (composite) | per-section | `PremiumLoadingIndicator` + skeletons | mixed: some `InlineErrorWidget` w/ retry, some swallow as `SizedBox.shrink()` | global banner only |
| Hadith card | `SizedBox.shrink()` if null | skeleton | **no try/catch — leaves `_isLoadingHadith=true` forever** | banner only |
| Relatives list | "لا يوجد أقارب بعد" + animation + CTA | `PremiumLoadingIndicator` | "حدث خطأ" + raw `error.toString()`; no retry | banner only |
| Family tree | placeholder layout | `CircularProgressIndicator(white)` | generic "حدث خطأ في تحميل شجرة العائلة"; no retry | banner only |
| AI Hub | static (no async) | none | none | banner only — taps fail downstream |
| AI Chat | suggested prompts (good) | per-message streaming indicator | inline `_buildErrorBanner` w/ dismiss | no gate |
| Weekly Report | n/a | `_buildLoadingCard` | swallowed `SizedBox.shrink()` for both stats + relatives | banner only |
| Settings | n/a | none | none | banner only |
| Family group | "لا يوجد أعضاء بعد" / "لا توجد دعوات" | `PremiumLoadingIndicator` | mixed: members has retry; group-level shows raw text; invitations no retry | banner only; mutations dump raw `e` into snack |
| Reminders | "لا يوجد أقارب بعد" + CTA, then "لا توجد جداول تذكير" + CTA | `PremiumLoadingIndicator` | `_buildError` w/ retry button (gold standard) | banner only |
| Reminders due | n/a | `PremiumLoadingIndicator` | `_buildError` | banner only |

### Findings

- 🔴 **`_loadDailyHadith` no try/catch — home spinner forever on error** [home_screen.dart:87-96]. — Wrap in try/catch/finally.
- 🔴 **`family_group_screen.dart:55-72` — error path indistinguishable from 404** ("لم يتم العثور على المجموعة"), no retry. — Distinguish + retry.
- 🔴 **`family_tree_screen.dart:393-396` — group-fetch error silently renders personal-mode header**; user in a group sees wrong screen affordances. — Distinguish loading/error.
- 🔴 **`family_tree_screen.dart:884-888` — group mode + `graph == null` spins forever** [no timeout]. — Add timeout / error state.
- 🟡 **`relatives_screen.dart:496-522` raw `error.toString()`, no retry.** — Match `reminders_screen.dart` pattern.
- 🟡 **`family_tree_screen.dart:1412-1435` `_buildError` no retry.** — Add `ref.invalidate` retry button.
- 🟡 **Home's `due_reminders_section.dart:41,44` and `todays_activity_section.dart:49` swallow errors to `SizedBox.shrink()`.** — Replace with `InlineErrorWidget`.
- 🟡 **Weekly report swallows errors at `:248,257`.** — Add retry/notice.
- 🟡 **Family group mutations interpolate raw `$e` into Arabic copy** (`'حدث خطأ أثناء إزالة العضو: $e'`) [multiple lines]. — Map errors via `error_handler_service`.
- 🟡 **No screen consumes `isOnlineProvider`** despite `connectivity_service` + `OfflineGuard` existing. The global banner is purely cosmetic. — Wire AI / mutations to gate on online state.
- 🟡 **AI Chat send offline dumps raw error** instead of "أنت غير متصل". — Gate `_sendMessage` on `isOnlineProvider`; show queueing UI.
- 🟡 **Family-tree placeholder→relative creation does direct `family_edges` upsert** — bypasses any offline queue [line 1257]. — Route through repository.
- 🟡 **`relatives_screen.dart:122-134` may briefly show empty state during loading transitions** (filtered provider race). — Document or guard.
- 🟢 **Loading-spinner inconsistency** — `PremiumLoadingIndicator`, `CircularProgressIndicator(Colors.white)`, skeletons. — Pick one per role.
- 🟢 **Family-tree empty state has no first-time illustration.** — Match `relatives_screen` empty pattern.
- 🟢 **Family group invitations error has no retry** [line 743-748], inconsistent with members-error in same screen.
- ⚪ **`reminders_screen.dart:353-396` is the gold-standard error-state pattern** — clear copy, connectivity hint, retry. Use as template.
- ⚪ **`AnimatedOfflineBanner` is mounted globally at `app_router.dart:553`.**
- ⚪ **`OfflineGuard`, `OfflineAwareButton`, `ConnectivityAwareWidget` exist in `lib/shared/widgets/offline_guard.dart` but are unused.**

---

## Cross-cutting findings

(numbered for triage)

1. **Loading-spinner inconsistency.** Three styles. — Pick one (recommend `PremiumLoadingIndicator` for full-screen, skeletons for inline) and remove the rest. (Cat: Cat 8 + flows 4, 5, 7.)
2. **Error-state inconsistency.** Mix of retry / no-retry / swallow / raw exception. — Establish a single error-widget contract; map all errors via `error_handler_service`. (Flows 1, 2, 5, 7, 8.)
3. **Silent failures across the app.** Onboarding flag never resets; notification toggles cosmetic; `_logInteraction` swallows; decline → no-op; `ensure_user_record` swallows. — Audit every `catch (_)` in the app and decide: surface, queue, or log. Many of these are 🟡 by themselves but in aggregate hurt trust. (Flows 1, 3, 5, 7.)
4. **No screen consumes `isOnlineProvider`.** The banner is cosmetic. — Wire AI calls and write-mutations through `OfflineGuard`. (Flows 6, 8.)
5. **Navigation contracts are uneven.** Add Relative `context.go(home)` post-save; notification taps `navigateTo(home)` + 100ms + push; decline `pop()`. — Pick `pop()` as the default "after action" pattern; reserve `go()` for explicit cross-flow jumps; remove the 100ms delay. (Flows 2, 4, 5.)
6. **Terminology consistent.** قريب / الأقارب used uniformly; no "فرد العائلة" / "علاقة" leakage. — ⚪ no fix needed.
7. **Glass / dialog styling consistent.** AlertDialogs use `themeColors.background1` + 16px radius across log-interaction, delete-relative, change-password. — ⚪ no fix needed.

## Top-of-mind for the CTO

If you ship as-is, the *most likely* TestFlight beta-tester complaints are, in order:

1. **"I muted notifications and still got pinged."** (Flow 7 #9.)
2. **"I tapped Add Relative from the Relatives list and it dropped me on Home."** (Flow 2 #3.)
3. **"I declined an invitation but the bell keeps glowing."** (Flow 5 decline.)
4. **"I tapped 'Sign up' and got stuck on a loader."** (Flow 1 splash race / login `_isLoading`.)
5. **"The home screen has a spinner that never goes away."** (Flow 8 hadith hang.)

If you only fix five things this cycle, fix those five. The remaining 🔴/🟡 issues are real but lower-frequency.
