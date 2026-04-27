---
name: Phase 6.0 — Bucket A (dead screen cut + English-leakage fixes)
description: Closed the 2 🔴 launch blockers from CONTENT_AUDIT_FINDINGS Cat 1 (by deleting their host screen) plus the 5 🟡 English-leakage findings (biometric service strings + Android channel display names). Founder-bottlenecked items remain for Phase 6.1.
type: project
---

# PHASE 6.0 — Bucket A

**Date:** 2026-04-27
**Status:** ✅ Both tasks shipped.
**Commit:** `<this commit>`.

## Task 1 — `phone_verification_screen.dart` cut ✅

The screen was the only host of both 🔴 English-leakage findings (`e.message` + `e.toString()` SnackBars in raw English `AuthException` text). Discovery Audit Cat 1 had already noted no flow routes to the screen. Cutting it closes both 🔴 launch blockers in one delete.

| File | Change |
|---|---|
| [lib/features/auth/screens/phone_verification_screen.dart](lib/features/auth/screens/phone_verification_screen.dart) | **Deleted.** |
| [lib/core/router/app_router.dart](lib/core/router/app_router.dart) | Removed the `import` (line 17) and the `GoRoute` block (was lines 148-159). Replaced the route block with a brief comment-block explaining the cut so a grep of "phone-verification" still surfaces the historical context. |
| [lib/core/router/app_routes.dart](lib/core/router/app_routes.dart) | Removed `static const String phoneVerification = '/phone-verification';`. Per CLAUDE.md "delete unused completely." |

### Verification

```bash
$ grep -rn "phone_verification\|PhoneVerification\|phoneVerification" lib/
lib/core/router/app_router.dart:150:      // route + AppRoutes.phoneVerification constant removed.
```

The single match is the historical comment in `app_router.dart`; no live consumers remain. Per the CTO instruction, halt-and-report would have triggered if any external caller had been found — none did.

## Task 2 — 5 🟡 English-leakage strings ✅

The 🟡 findings spanned 3 logical issues across 16 source sites (2 in biometric_service + 14 channel-name sites across 2 services). All replacements are direct string substitutions — no `error_handler_service` routing was needed because the strings live deep enough that the surrounding code already maps them through their own consumers.

### biometric_service.dart

| File:line | Before | After |
|---|---|---|
| [lib/shared/services/biometric_service.dart:103](lib/shared/services/biometric_service.dart#L103) | `BiometricAuthResult.failed('Authentication failed')` | `BiometricAuthResult.failed('فشل التحقق')` |
| [lib/shared/services/biometric_service.dart:123-126](lib/shared/services/biometric_service.dart#L123) | `BiometricAuthResult.error('Unexpected error occurred', 'unknown')` | `BiometricAuthResult.error('حدث خطأ غير متوقع في المصادقة البيومترية', 'unknown')` |

The Cat 1 finding noted the `failed` branch isn't currently rendered by any caller (login screen only surfaces `result.error`, not `result.failed`); fixing it preemptively means a future caller using `result.errorMessage` won't accidentally render English.

### Android notification channel display names + descriptions

`sed`-driven bulk replacement across both services. 14 sites total.

| String | Replacement | Sites |
|---|---|---|
| `'Silni Notifications'` | `'إشعارات صلني'` | [supabase_notification_service.dart:174](lib/shared/services/supabase_notification_service.dart#L174), `:340`, `:407` + [fcm_notification_service.dart:35](lib/shared/services/fcm_notification_service.dart#L35), `:173`, `:374` (6 sites) |
| `'Notifications for Silni app'` | `'إشعارات تطبيق صلني'` | same 6 sites (`channelDescription` parameter) — note `fcm_notification_service.dart:174` uses the `description:` named parameter shape, also caught by the substitution |
| `'Reminders'` | `'تذكيرات'` | [supabase_notification_service.dart:280](lib/shared/services/supabase_notification_service.dart#L280) (1 site) |
| `'Reminders to contact relatives'` | `'تذكيرات للتواصل مع الأقارب'` | [supabase_notification_service.dart:281](lib/shared/services/supabase_notification_service.dart#L281) (1 site) |

These strings are visible in **Android Settings → Apps → Silni → Notifications** when the user manages the Silni-specific channel UI from the system settings (i.e. the surface the new Phase 5.5 explainer screen routes them to).

Verification grep confirms zero remaining English channel names:

```bash
$ grep -nE "Silni Notifications|Reminders'|Notifications for Silni|Reminders to contact" \
    lib/shared/services/supabase_notification_service.dart \
    lib/shared/services/fcm_notification_service.dart
(no output)
```

## Verification

| Check | Phase 5.5 baseline | Phase 6.0 result | Verdict |
|---|---|---|---|
| `flutter analyze` | 6 issues | **6 issues** (same lines) | ✅ baseline preserved |
| `flutter test test/unit/` | 1354 / 0 | **1354 / 0** | ✅ |
| `flutter test test/golden/` | 8 / 0 | **8 / 0** | ✅ |
| `flutter build ios --release --no-codesign` | 70.0 MB / 39.7 s | **70.0 MB / 46.7 s** | ✅ |

## Surprises

1. **Phone verification screen was completely orphaned.** The Discovery Audit had flagged it as unused; the Content Audit then concentrated both 🔴 leakage findings on it. The cleanest fix wasn't to translate the strings — it was to delete the screen they lived on. Deleted file is 200+ lines gone with no behavior loss.
2. **The route constant in `app_routes.dart` had no consumers either** — confirmed via grep. Removed it instead of preserving for v1.1; if a future feature needs phone-verification, it'll get a fresh route.
3. **The `BiometricAuthResult.failed` branch is currently never rendered** (per Content Audit Cat 1 note). The `'فشل التحقق'` fix is a preemptive guard for any future caller that checks `result.failed`.
4. **Channel-name fix is OS-visible only**, not in-app. Users who never visit Android Settings don't see these strings. The fix is for the OS-language consistency mentioned in the audit.

## Phase 6.0 totals

- **Lines deleted:** ~210 (the entire screen file).
- **Lines changed:** 16 (bulk string replacements + 2 biometric edits + router/route_constants pruning).
- **Net commit size:** −213 / +18 ≈ **−195 lines net.**

## Items explicitly NOT touched (Phase 6.1 scope)

Per the CTO instruction, **none** of the following were touched in this session — they're founder-bottlenecked:

- Brand-name diacritic split (`صِلني` vs `صلني` vs `صِلْني`) — founder picks the canonical spelling.
- AI persona name (`واصل` collision with the gamification noun) — founder picks rename target.
- "Reminder vs notification" terminology (`تذكير` / `إشعار` / `تنبيه`) — founder picks usage policy.
- Hadith citation format (English vs Arabic) + the 3 missing-narrator and 3 missing-number rows — founder + religious advisor.
- The 963-row [COPY_REVIEW.md](COPY_REVIEW.md) — founder grades inline.
- The 16 🟡 hardcoded-copy sites in Cat 2 — founder + CTO decide which to migrate to admin tables.

## TestFlight readiness

Both 🔴 content-audit launch blockers are closed (by virtue of the screen being gone). The 5 🟡 English-leakage findings are closed. The remaining audit items are founder-bottlenecked and don't gate launch.

App still TestFlight-ready.
