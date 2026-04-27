---
name: Phase 5.5 — Cosmetic notification toggles cut
description: Replaced the SharedPreferences-only notification toggle screen with an explainer + OS-settings launcher. Phase 5 Task 4 closed.
type: project
---

# PHASE 5.5 — Cosmetic Notification Toggles Cut

**Date:** 2026-04-27
**Status:** ✅ Shipped. Closes the Phase 5 Task 4 halt.
**Commit:** `<this commit>`.

## Decision: Option A

Replaced the entire body of `notifications_screen.dart` with a single explainer card + an "افتح إعدادات النظام" button. **Reasoning:**

- Option B (toggles → explainer card with button) leaves the ghost of toggles around. Option A wipes them entirely; the screen becomes a 1-purpose deep-link.
- The widget tree shrinks from ~330 lines (StatefulWidget + 5 toggle tiles + cache-load logic + service-init) to ~190 lines of `ConsumerWidget`. No `_isLoading`, no `setState`, no service initialization on this screen.
- The user mental model maps 1:1: "I want to control notifications" → tap → OS settings.

Settings tile in [settings_screen.dart:114-121](lib/features/settings/screens/settings_screen.dart#L114-L121) is **unchanged** — it routes to `/notifications` which is now the new explainer/launcher screen. Same destination from the user's perspective; nothing further to wire.

## File:line evidence

### [notifications_screen.dart](lib/features/notifications/screens/notifications_screen.dart) — full rewrite

- **Lines 1-7:** v1-cut documentation comment exactly as the CTO spec asked.
- **Lines 9-20:** trimmed imports — dropped `flutter/services` (HapticFeedback no longer used), `shared_preferences`, `supabase_notification_service`. Added `dart:io` (Platform), `url_launcher`, `gradient_button`.
- **Lines 28-44:** `_NotificationPrefsKeys` class preserved verbatim. The 5 keys (`notifications_reminders_enabled`, `notifications_daily_enabled`, `notifications_weekly_enabled`, `notifications_sound_enabled`, `notifications_vibration_enabled`) are exactly the same strings the previous toggles wrote to. `// ignore_for_file: unused_field, unused_element` suppresses the analyzer warnings about the class + fields being unreferenced (they're scaffolding for v1.1 readback, not v1 consumers).
- **Lines 46-130:** new `NotificationsScreen` — `ConsumerWidget` (was `ConsumerStatefulWidget`). Renders the message-widget slot, then a single GlassCard with icon + title + explainer paragraph + GradientButton.
- **Lines 132-156:** `_openSystemNotificationSettings`. iOS path: `Uri.parse('app-settings:')` + `canLaunchUrl` + `launchUrl`. Android path: surfaces the manual navigation path via SnackBar (`'افتح إعدادات الجهاز > التطبيقات > صلني > الإشعارات.'`). Inline comments document why Android doesn't get a one-tap deep-link and what v1.1 would change.
- **Lines 158-189:** simplified `_buildHeader` — title only, removed the subtitle "تخصيص التذكيرات والإشعارات" since toggles are gone.

### Removed (replaced by the rewrite, not preserved as dead code)

The previous file had:
- `_NotificationsScreenState` with 6 mutable fields (`_remindersEnabled` through `_isLoading` + service ref).
- `_loadSavedPreferences`, `_savePreference`, `_initializeNotificationService`.
- `_buildSwitchTile` helper.
- 5 in-page Switch tiles + 2 section headers.

All gone. ~330 → ~190 lines.

### `app_router.dart`, settings tile

Untouched. The route `/notifications` and the Settings tile both still work exactly as before from the user's perspective; the destination's content is what changed.

## SharedPreferences key preservation — confirmed

```bash
$ grep -E "notifications_(reminders|daily|weekly|sound|vibration)_enabled" lib/features/notifications/screens/notifications_screen.dart
                                ^ before: 5 reads + 5 writes via setBool
                                ^ after:  5 string-constant declarations only
```

The strings live as `_NotificationPrefsKeys` static const fields. They are **not read or written by any code in v1** — the previous Phase-5 audit confirmed they never gated anything. v1.1 will:

1. Read `prefs.getBool(_NotificationPrefsKeys.remindersEnabled)` etc. at first launch after the upgrade.
2. Use those values to seed initial FCM topic membership (`subscribeToTopic('reminders_<userId>')` etc.).
3. Then re-expose the toggles, this time backed by topic state.

If the migration grows ambitious, a small Dart utility could expose `_NotificationPrefsKeys` publicly and copy them to a more stable namespace. For now, file-private is fine.

## Verification

| Check | Phase 5 baseline | Phase 5.5 result | Verdict |
|---|---|---|---|
| `flutter analyze` | 6 issues (5 info + 1 warn) | **6 issues** (same lines) | ✅ baseline preserved |
| `flutter test test/unit/` | 1354 / 0 | **1354 / 0** | ✅ |
| `flutter test test/golden/` | 8 / 0 | **8 / 0** | ✅ |
| `flutter build ios --release --no-codesign` | 70.0 MB / 47.1 s | **70.0 MB / 39.7 s** | ✅ |

Manual verification path: Settings → الإشعارات → "افتح إعدادات النظام" button → on iOS, lands on Silni's iOS Settings page with the Notifications row.

## Surprises

1. **The previous screen called `_initializeNotificationService()` in `initState`** — every visit re-initialized the FCM service. That was wasted work since `main.dart` already initializes it at startup. Cutting the screen also cuts that redundant init.
2. **`HapticFeedback.selectionClick()` was fired on every toggle tap** — gone with the toggles. No haptics are missed because nothing actually toggles anymore.
3. **`// ignore_for_file: unused_field` doesn't cover `unused_element`** — they're separate lints. Needed both directives to suppress the warning on the preserved-keys class. (Caught while iterating.)
4. **Android deep-link to notification settings would need a native intent.** `url_launcher` doesn't handle `android.settings.APP_NOTIFICATION_SETTINGS`. The honest fallback is a SnackBar with the manual path. v1.1 should pull in `app_settings` (~5 KB) for one-tap on both platforms.

## Open questions for the CTO

1. **`_saveFamilyName` analyzer warning** still present — same disposition as Phases 4/5: 🟢 leave for post-TestFlight backlog.
2. **Android one-tap launcher** — add `app_settings` package in v1.1 alongside the topic infra? Or sooner if Android is non-trivial portion of v1 audience?

## TestFlight readiness

The codebase has zero known cosmetic-state bugs. Every UX-audit launch blocker is closed. Tests pass, builds clean, analyzer at baseline.
