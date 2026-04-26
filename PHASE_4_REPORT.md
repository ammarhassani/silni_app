---
name: Phase 4 — Pre-TestFlight fixes from the discovery audit
description: 9 tasks shipped — reminder silent-drop blocker fixed, announcement 3-status logic with migration, localizations + digit policy, RTL polish, ensure_user_record runbook, golden tests unblocked, legacy README. Baseline preserved/improved.
type: project
---

# PHASE 4 — Pre-TestFlight Cleanup

**Date:** 2026-04-26
**Status:** ✅ All 9 tasks shipped. Migration applied to prod. App builds clean for iOS release.
**Commits:** `<this commit>`.

## Task 1 — Reminder last_sent silent-drop fix 🔴 (launch blocker)

**File:** [supabase/functions/send-scheduled-reminders/index.ts:206-262](supabase/functions/send-scheduled-reminders/index.ts#L206-L262)

Added a per-schedule `let sentSuccessfully = false;` flag. The flag flips to `true` ONLY when `notificationResponse.ok && responseData.sent > 0`. The `last_sent` UPDATE is now wrapped in `if (sentSuccessfully)`. All three failure paths (HTTP error, `sent === 0`/no FCM tokens, network exception in `catch`) leave `last_sent` unchanged, and each logs an explicit `last_sent unchanged` line for log-readers.

The cron's WHERE clause (`is_active=true AND time=HH:mm`) doesn't depend on `last_sent`, so a failure today doesn't block tomorrow's same-time fire. `last_sent` is now an honest "last successful delivery" timestamp.

## Task 2 — Reminder regression test ✅

**File:** [test/unit/functions/send_scheduled_reminders_test.dart](test/unit/functions/send_scheduled_reminders_test.dart) (new file).

The Deno/TypeScript edge function can't be exercised by the Flutter test runner. The pragmatic alternative: a Dart-level **invariant test** that reads the source file and asserts three regression-prevention conditions:

1. `let sentSuccessfully = false` is declared.
2. `sentSuccessfully = true` only appears within 200 chars of a `sent > 0` check.
3. `last_sent: new Date().toISOString()` is preceded (within 300 chars) by `if (sentSuccessfully)`.

Any future edit that strips the guard fails this test. **+1 test, exactly matches the spec target of 1354/0.**

## Task 3 — Announcement partial-failure (3 statuses)

### Migration

**File:** [supabase/migrations/20260427900000_announcement_status_check_expansion.sql](supabase/migrations/20260427900000_announcement_status_check_expansion.sql)

Drops the existing CHECK `('draft', 'scheduled', 'sent')` and replaces with `('draft', 'scheduled', 'sent', 'partial', 'failed')`. Self-verifies that the new definition contains `'partial'` and `'failed'`. **Applied to prod cleanly via `supabase db push`.**

**Surprise:** `total_recipients`, `successful_sends`, `failed_sends` columns *already existed* on `admin_announcements` (introspected via MCP). The audit's claim that columns might be needed turned out to be a false alarm — only the CHECK needed expanding. **Latent bug caught on the way through:** the existing `send-announcement` function was already trying to write `'failed'` on full FCM rejection — that write would have hit the old CHECK. Migration closes the latent bug as a side effect.

### send-announcement function

**File:** [supabase/functions/send-announcement/index.ts:170-194](supabase/functions/send-announcement/index.ts#L170-L194)

Replaces the binary `failCount === tokens.length ? "failed" : "sent"` with the 3-status mapping:

```
successCount === 0           → "failed"
successCount === tokens.length → "sent"
otherwise                    → "partial"
```

### send-scheduled-announcements function

**File:** [supabase/functions/send-scheduled-announcements/index.ts:130-167](supabase/functions/send-scheduled-announcements/index.ts#L130-L167)

The bigger of the two function changes. Previously this function:
- Always wrote `status: "sent"` regardless of delivery counts
- Did NOT update `total_recipients`, `successful_sends`, or `failed_sends`

Now writes the 3-status terminal value AND the three count columns alongside `sent_at`.

### silni-admin TypeScript types + UI

**Files:**
- [silni-admin/src/hooks/use-announcements.ts:7-12, 213-220, 229-236](silni-admin/src/hooks/use-announcements.ts) — `AnnouncementStatus` union now includes `"partial"`; `STATUS_LABELS["partial"] = "إرسال جزئي"`; `STATUS_COLORS["partial"] = "bg-amber-100 text-amber-700"`.
- [silni-admin/src/app/(dashboard)/notifications/announcements/page.tsx:290-303](silni-admin/src/app/(dashboard)/notifications/announcements/page.tsx) — table row now renders the badge plus a sub-line `{successful_sends}/{total_recipients} وصلت` for any terminal status (sent/partial/failed) with `total_recipients > 0`.

## Task 4 — `MaterialApp.router` localizations + digit policy comment

**File:** [lib/main.dart:9, 116-122, 802-810](lib/main.dart)

Added:
- `import 'package:flutter_localizations/flutter_localizations.dart'`.
- The 3 standard delegates (`GlobalMaterialLocalizations`, `GlobalWidgetsLocalizations`, `GlobalCupertinoLocalizations`) on `MaterialApp.router`.
- `supportedLocales: const [Locale('ar', 'SA'), Locale('en')]`.
- The CTO digit-policy comment immediately after `initializeDateFormatting('ar')`. Locks in Western digits as the app-wide policy with rationale.

## Task 5 — Phone LTR Directionality wrap

**File:** [lib/features/family_groups/screens/family_group_screen.dart:874-885](lib/features/family_groups/screens/family_group_screen.dart#L874-L885)

Wrapped `Text(invitation.maskedPhone, …)` in `Directionality(textDirection: TextDirection.ltr, child: …)`. **Side gotcha:** `package:intl/intl.dart` exports its own `TextDirection` (with uppercase `LTR`/`RTL`), shadowing Flutter's lowercase `ltr` enum value. Fixed by changing the intl import to `import 'package:intl/intl.dart' hide TextDirection;` so Flutter's wins. The other LTR sites in the codebase don't import intl, so they were never affected.

## Task 6 — Arabic email hint placeholders

Three sites replaced with `'بريدك الإلكتروني'`:

- [lib/features/auth/screens/signup_screen.dart:347](lib/features/auth/screens/signup_screen.dart#L347)
- [lib/features/auth/screens/login_screen.dart:520](lib/features/auth/screens/login_screen.dart#L520)
- [lib/features/auth/screens/login_screen.dart:873](lib/features/auth/screens/login_screen.dart#L873)

Re-grepping confirms zero remaining `example@`, `user@`, or `@example` occurrences in `lib/`.

## Task 7 — `ensure_user_record` failure runbook

**File:** [docs/MAINTENANCE_OPERATIONS.md](docs/MAINTENANCE_OPERATIONS.md) — appended new "Appendix A — `ensure_user_record` failure surveillance" section.

Documents the weekly Postgres-logs query that surfaces swallowed `RAISE LOG` lines from the function's `EXCEPTION WHEN OTHERS` block, plus triage paths (empty / single user / cross-user-cross-state). Also documents the delete+recreate manual recovery for a corrupted single-user row, and explicitly notes WHY a persisted failures table (Option B from the audit) was rejected: it would add a write to the sign-in path and break the function's "never block the client" contract.

## Task 8 — `overrideWithValue` → `overrideWith`

`StateNotifierProvider.overrideWithValue` was deprecated in current Riverpod. The new API requires `overrideWith((ref) => MyNotifier(value))`.

**Files updated:**
- [test/golden/golden_test_helpers.dart:38-43](test/golden/golden_test_helpers.dart#L38-L43)
- [test/helpers/widget_test_helpers.dart:24-30](test/helpers/widget_test_helpers.dart#L24-L30)

Only `themeColorsProvider` is a `StateNotifierProvider` — the other 4 providers (`themeKeyProvider`, `themeProvider`, `dynamicThemesProvider`, `currentDynamicThemeProvider`) are plain `Provider` and still take `overrideWithValue`. Used `AnimatedThemeColorsNotifier(themeColors)` as the override factory.

**Bonus:** golden tests now compile AND pass — `flutter test test/golden/` shows 8/8 GlassCard golden tests green. The infrastructure that was silently degraded since pre-Phase-3 is now functional.

## Task 9 — `supabase/legacy/README.md`

**File:** [supabase/legacy/README.md](supabase/legacy/README.md). One-paragraph "DO NOT APPLY" notice with pointers to the wave reports.

## Verification

| Check | Phase 3.5 baseline | Phase 4 result | Verdict |
|---|---|---|---|
| `flutter analyze` | 8 issues (2 errors + 1 warn + 5 info) | **6 issues** (0 errors + 1 warn + 5 info) | ✅ down 2 |
| `flutter test test/unit/` | 1353 / 0 | **1354 / 0** | ✅ exactly the spec target |
| `flutter test test/golden/` | did not compile | **8 / 0** | ✅ unblocked |
| `bash scripts/check_migrations_for_missing_on_delete.sh --diff-only origin/main` | clean | clean | ✅ |
| `flutter build ios --release --no-codesign` | 69.7 MB / 112.2 s | **70.2 MB / 33.1 s** | ✅ (faster because incremental) |
| `supabase db push` (announcement status CHECK) | n/a | applied cleanly | ✅ |

## Surprises

1. **`admin_announcements` already had the count columns.** `total_recipients`, `successful_sends`, `failed_sends` existed pre-Phase-4. The audit didn't introspect deeply enough to spot this. Migration scope was therefore much smaller — just a CHECK expansion.
2. **Latent CHECK-constraint bug closed as a side effect.** `send-announcement` was writing `'failed'` against a CHECK that only allowed `('draft','scheduled','sent')`. Any actual full FCM rejection would have raised SQLSTATE 23514. The Phase 4 migration fixes that latent bug while doing the partial-failure expansion.
3. **`package:intl/intl.dart` exports a `TextDirection` class** that shadows Flutter's enum. The Task 5 LTR wrap wouldn't compile until I added `hide TextDirection` to the intl import. Worth knowing for any future LTR-wrap site that also uses intl date formatting.
4. **Golden tests passed on first compile.** I expected a visual regression or two given how much UI has churned recently — instead, all 8 GlassCard goldens are green. Either the goldens are stable or they're checked in for a recent enough state. Either way, no fire to fight.

## Open questions for the CTO

1. **Apply the announcement-status CHECK migration to staging?** It's already on prod (the only environment we deploy to currently). If a separate staging DB exists, run `supabase db push --linked-project staging` against it before the next release cycle. Otherwise n/a.
2. **The `_saveFamilyName` dead method warning.** Still present. Cat 3 of the audit classified it 🟢 post-launch backlog — leave or delete? Five-minute decision; not gating launch either way.
3. **Verify the digit policy comment is accurate.** The comment claims iOS Arabic locale uses Western digits and that WhatsApp/banking/ride-share apps use the same. If founder wants to push back, comment is one edit away from saying the opposite.

## TestFlight readiness — yes

All Phase 4 tasks shipped:
- 🔴 launch blocker fixed (reminder silent-drop) and pinned with a regression test.
- 🟡 announcement partial-failure surfaces in the admin panel as `إرسال جزئي` with `X/Y وصلت` sublabel.
- 🟡 Material/Cupertino/Widgets locales properly delegated; future DatePicker dialogs render in Arabic.
- 🟡 phone-mask renders LTR within RTL parent.
- 🟡 email placeholders are Arabic.
- 🟡 ensure_user_record observability documented (weekly query + triage runbook).
- 🟡 test helper infrastructure unblocked; golden tests compile and pass.
- ⚪ legacy README seals the archaeology folder against accidental application.

Code, infra, and tests are all in launch-ready shape. Next session is TestFlight prep proper: signing, archive, upload, internal release notes.
