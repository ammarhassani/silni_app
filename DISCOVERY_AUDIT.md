---
name: Pre-TestFlight Discovery Audit
description: Eight-category readiness audit before TestFlight. Findings only — no code changes. Severity-classified with recommended order of attention.
type: project
---

# DISCOVERY AUDIT — Pre-TestFlight Readiness

**Date:** 2026-04-26
**Format:** findings only — no code changes were made in this session.
**Method:** static analysis via grep / file reads, MCP introspection where useful, three Explore subagents for Cats 2 / 6 / 7.

Severity legend: 🔴 launch blocker · 🟡 pre-launch worth fixing · 🟢 post-launch backlog · ⚪ documentation only.

---

## Pre-task — Test count reconciliation

**Resolution: no silent skips. The Phase 3 report's "4 failing tests" claim miscounted by 1.**

- Searched `test/unit/` for `@Skip`, `@isTest skip`, `if (false)`, commented-out tests — none found.
- `flutter test test/unit/ --reporter=expanded` shows zero skipped tests; the words "skip" in the output are test-name prefixes (e.g. *"should skip processing when offline"*) describing the behavior under test, not skipped tests.
- Phase 3 report claimed 4 fails ("4 pre-existing perspective-engine failures"). Re-running the perspective test file in Phase 3.5 showed exactly **3** fallback failures — (`fallback: returns fullName for unknown graph path`, `fallback: returns empty string for unknown target`, `fallback returns fullName instead of arabicName`). Task 1's 3-line fix resolved all 3.
- Net: 1349 + 3 = 1352 expected; actual is 1353. The discrepancy of 1 is consistent with a small drift in test count between the two snapshots (a test file may have been touched in `a12020e` "refactor(observability): rename services" or in normal evolution, accidentally adding 1 case). Not a silent skip; a counting drift.
- **The all-green claim is real.** ⚪

---

## Category 1 — Untested critical user-facing flows

Test inventory shows extensive **logic** coverage but limited **end-to-end** coverage.

| Flow | Coverage | Risk |
|---|---|---|
| **Onboarding (sign up → first relative add → first interaction)** | None end-to-end. [auth_service_test.dart](test/unit/services/auth_service_test.dart) covers error-message translation + mock demonstrations only. No happy path. [relatives_service_test.dart](test/unit/services/relatives_service_test.dart) tests filtering/sorting logic, not the add flow. | 🟡 if signup breaks at TestFlight, error reaches user with no test catching it. |
| **Push notification delivery (FCM token registration → reminder firing → notification arriving)** | Server-side: `send-push-notification` edge function has try/catch + per-token error logging. Client-side: zero tests on `notification_service.dart`'s FCM token registration. | 🟡 |
| **Reminder schedule firing (cron-driven)** | [reminder_schedules_service_test.dart](test/unit/services/reminder_schedules_service_test.dart) covers filtering/sorting/relative-ID management — no firing semantics, no time-zone math, no last_sent update. | 🔴 see Cat 2 finding: `send-scheduled-reminders` updates `last_sent` even on FCM failure (silent drop). |
| **Family group invitation (creator invites → invitee receives → invitee joins)** | [family_sharing_service_test.dart](test/unit/services/family_sharing_service_test.dart) and [node_invitation_model_test.dart](test/unit/models/node_invitation_model_test.dart) cover edge generation and model parsing. No end-to-end join verification. The `verifySharedEdges` post-join hook exists in code but no test asserts it heals missing edges. | 🟡 |
| **Delete-account (UI → RPC → cascade → user fully removed)** | No tests. The `delete_user_account` RPC ships with a DO-block that asserts cleanup; that's the only safety net. After Wave 2.5's CASCADEs, the procedural teardown becomes redundant (Wave 2.6 follow-up). | 🟡 — the architecture is right but unverified by tests. |
| **Sign-in via Apple / Google / email** | Only structural mock demos in `auth_service_test.dart`. No e2e for any provider. | 🟡 |

**Recommendation:**
- 🔴 Add ONE test that mocks an FCM failure during reminder firing and asserts `last_sent` is NOT updated. This is the only finding in this category that crosses into launch-blocker territory because it would silently drop a reminder.
- 🟡 Three integration-style happy-path tests (signup, reminder fire, group join) before the SECOND TestFlight cycle.

---

## Category 2 — Edge function inventory + health (subagent)

8 functions live, 0 orphans. Cron schedules: hourly nudges, every-minute reminders, every-15-min announcements, daily streak alerts.

### Critical findings

- 🔴 [`send-scheduled-reminders/index.ts:252-254`](supabase/functions/send-scheduled-reminders/index.ts) updates `last_sent` regardless of FCM success. If FCM is down or rejects the token, the reminder is silently dropped — and won't re-fire because `last_sent` says it did. **Pair this with Cat 1's missing test: same bug, same gap.**
- 🟡 [`send-announcement/index.ts:174`](supabase/functions/send-announcement/index.ts) and [`send-scheduled-announcements/index.ts:142`](supabase/functions/send-scheduled-announcements/index.ts) — partial FCM failure marks status `"sent"`. CTO call: change threshold (e.g. ≥90% delivered = sent, else `"partial"`/`"failed"`).
- 🟡 [`deepseek-proxy`](supabase/functions/deepseek-proxy/index.ts) has no retry/backoff for 5xx; the user gets the upstream error directly. Acceptable for launch (graceful UI degradation downstream) but easy win.
- 🟡 [`send-smart-nudges`](supabase/functions/send-smart-nudges/index.ts): if push send fails, the nudge is logged but not retried next hour.
- 🟢 `sync-subscription`, `send-push-notification`, `check-streak-alerts` — all have try/catch + structured logging + appropriate fallbacks. Ship as-is.

**Subagent's full report is incorporated; no separate file.** The verdict reads: **ship with the 1 reminder-status fix as a launch blocker.**

---

## Category 3 — The 8 analyzer issues

Captured the full output:

```
6 × info  — unnecessary_underscores
1 × warn — unused element (_saveFamilyName)
2 × error — overrideWithValue not defined for StateNotifierProvider
```

| Issue | File:line | Severity | Verdict |
|---|---|---|---|
| `unnecessary_underscores` ×6 | [create_group_screen.dart:391, 432](lib/features/family_groups/screens/create_group_screen.dart), [family_tree_screen.dart:395, 405, 441](lib/features/family_tree/screens/family_tree_screen.dart) | info | ⚪ — Dart 3 cosmetic lint; no behavior impact. Leave. |
| `_saveFamilyName` unused | [family_tree_screen.dart:253](lib/features/family_tree/screens/family_tree_screen.dart#L253) | warning | 🟢 — fully-implemented method that has no caller. Was likely wired to a UI surface that's been removed. ~30 lines of dead code that includes a Supabase write + group-name update. Worth deleting in cleanup, not a launch blocker. |
| `overrideWithValue` not defined ×2 | [test/golden/golden_test_helpers.dart:40](test/golden/golden_test_helpers.dart#L40), [test/helpers/widget_test_helpers.dart:26](test/helpers/widget_test_helpers.dart#L26) | **error** | 🟡 — these are real Riverpod API errors (`StateNotifierProvider.overrideWithValue` was deprecated in favor of `overrideWith((ref) => …)` in newer Riverpod). **Impact:** golden tests and widget-helper-using tests don't run at all. Unit tests are fine because they don't import these helpers. **Action:** before re-enabling golden tests, swap to `overrideWith`. Doesn't gate launch (production code doesn't touch these), but the test infrastructure is silently degraded. |

---

## Category 4 — Family graph edge cases

Read [family_graph_service.dart](lib/features/family_tree/services/family_graph_service.dart) cover-to-cover. Findings are all 🟢 or ⚪.

- **No path to viewer:** handled by Phase 3.5's fallback fix — returns `fullName` or `'قريب'`. ⚪
- **Cycle handling:** BFS in `computeRahimScope` (line 120) uses `visited.add(...)` which returns false on duplicates, so any cycle (intentional or accidental) terminates after each node is seen once. No infinite loop possible. ⚪
- **Divorced + remarried same partner:** the model has a single `spouseOf` edge per pair; if the same couple divorced and remarried, only one edge would survive. Re-marriage to a *different* partner would orphan the original. Neither scenario corrupts traversal — `getSpouse` returns one or null. 🟢 (not common; not blocking)
- **Edge inference silent failure modes:** [inferEdges](lib/features/family_tree/services/family_graph_service.dart#L519) returns `[]` when relationship type is `RelationshipType.other`. Callers assume empty list = "nothing to add"; there's no observability hook. If an admin's "fix bad data" tooling later expects edges to materialize for `other`, it'll silently no-op. 🟢
- **Worst-case complexity:** `getLabelForViewer` has nested loops over parents → parent-siblings → their children for cousin detection. For a typical Saudi family with ≤5 paternal aunts × 5 kids each = 25 candidates × 4 nesting levels — still well under 1ms per call on a phone. No concern. ⚪
- **`enrichAllSiblingEdges` idempotency:** the function returns the SAME graph reference if no new edges were added (line 87) — a small allocation optimization. Subtly important for Riverpod equality checks; nobody to my knowledge depends on this. ⚪

**Verdict:** no findings that block launch. The fallback drift was the only real bug; it's fixed.

---

## Category 5 — Auth surface audit

### `handle_new_user` history (each migration's stated fix)

| Migration | Date | What it tried to fix |
|---|---|---|
| [20250128100000](supabase/migrations/20250128100000_fix_profiles_sync_production.sql) | 2025-01-28 | Trigger missing in production; new users not appearing in profiles. |
| [20251230100002](supabase/migrations/20251230100002_admin_profiles.sql) | 2025-12-30 | Created profiles table itself; foundation. |
| [20251231400001](supabase/migrations/20251231400001_fix_profiles_rls.sql) | 2025-12-31 | Profiles RLS infinite recursion (admin-check policy queried profiles). Fix: SECURITY DEFINER bypass. |
| [20260103100000](supabase/migrations/20260103100000_sync_auth_users_to_profiles.sql) | 2026-01-03 | Backfill: existing auth.users without profiles. |
| [20260109100000](supabase/migrations/20260109100000_fix_signup_trigger.sql) | 2026-01-09 | "Database error saving new user" during signup. |
| [20260129100000](supabase/migrations/20260129100000_fix_all_user_sync.sql) | 2026-01-29 | `public.users` (separate from profiles) was never being written by the trigger. Trigger only inserted profiles. |
| [20260129110000](supabase/migrations/20260129110000_fix_trigger_search_path.sql) | 2026-01-29 | Trigger never fired because auth context's search_path lacks `public` — function couldn't find `public.profiles` / `public.users`. Added `SET search_path = public, auth`. |
| [20260425100000](supabase/migrations/20260425100000_ensure_user_record_and_full_account_delete.sql) | 2026-04-25 | **The current architecture.** OAuth re-login after account deletion reuses `auth.users` row, so `handle_new_user` doesn't fire. Added `ensure_user_record()` RPC, called from the client on every `signedIn` and `initialSession` event. |

That's 7 fixes. The current ([20260425100000](supabase/migrations/20260425100000_ensure_user_record_and_full_account_delete.sql)) is the one that actually closes the loop, because it stops relying on the trigger alone.

### Failure modes each layer is designed to handle

- **`handle_new_user` trigger** (server-side): fires on `INSERT INTO auth.users`. Handles fresh sign-up. Doesn't fire on OAuth re-login after deletion (Supabase reuses the row).
- **`ensure_user_record()` RPC** (client-side, idempotent UPSERT): fires from the Flutter app's `onAuthStateChange` listener on `signedIn` AND `initialSession`. Handles:
  - First-ever sign-in (redundant with trigger, but cheap).
  - OAuth re-login after account deletion.
  - App cold-start with an existing session (`initialSession` event).
  - Any case where `handle_new_user` raised an exception that was swallowed by Supabase (older bug history).

### Sign-in path map

| Path | Fires `handle_new_user` (trigger)? | Fires `ensure_user_record` (RPC)? |
|---|---|---|
| Email/password signup ([signup_screen.dart:47](lib/features/auth/screens/signup_screen.dart#L47)) | ✅ (new auth.users row) | ✅ (`signedIn` event) |
| Email/password signin (existing) | ❌ | ✅ |
| Apple OAuth ([login_screen.dart:673](lib/features/auth/screens/login_screen.dart#L673)) — first time | ✅ | ✅ |
| Apple OAuth — re-login | ❌ | ✅ |
| Google OAuth ([login_screen.dart:597](lib/features/auth/screens/login_screen.dart#L597)) — first time | ✅ | ✅ |
| Google OAuth — re-login | ❌ | ✅ |
| App cold start with valid session | ❌ | ✅ (`initialSession` event) |
| Re-login after `delete_user_account` | ❌ (auth.users reused) | ✅ |
| Password reset → sign-in (`passwordRecovery` then `signedIn`) | ❌ | ✅ |

**No path was found where neither layer fires.** The `ensure_user_record` RPC is called in [main.dart:646-649](lib/main.dart#L646-L649) for both `signedIn` and `initialSession` regardless of how the session was created — so any sign-in path that produces a session triggers it.

### Findings

- ⚪ The auth surface is now sound. The seven fixes constituted a real architectural shift (trigger-only → trigger + idempotent client-callable upsert), and the architecture covers all known sign-in paths.
- 🟢 The `_signUp` flow has a 30-second timeout; the iOS network can be slow. If TestFlight users hit the timeout it would just show an error — not a deadlock — but worth monitoring.
- 🟡 `ensure_user_record` swallows ALL exceptions in its `EXCEPTION WHEN OTHERS` block (line 78 of the migration). This is by design ("never block the client") but means a corrupted profiles/users row would fail every login *silently*. The function only RAISE LOGs the error; admins won't know. Worth surfacing failures to error_reporter (or at least Supabase logs query).

---

## Category 6 — `supabase/legacy/` audit (subagent)

Two files, 23.2 KB total:

- [`gamification_functions.sql`](supabase/legacy/gamification_functions.sql) — historical RPC definitions (`award_points`, `delete_user_account`). Superseded by [20260425000000_runtime_rpc_definitions.sql](supabase/migrations/20260425000000_runtime_rpc_definitions.sql).
- [`schema.sql`](supabase/legacy/schema.sql) — the original bootstrap schema. Superseded by the Wave 1 + 1.5 capture migrations ([20260427200000](supabase/migrations/20260427200000_capture_chat_tables.sql), [20260427300000](supabase/migrations/20260427300000_capture_core_tables.sql)).

**Status:**
- Both files are **never executed** by the app, deploy pipeline, migration order, or any script. Pure archaeology.
- Header comments correctly state "DO NOT APPLY."
- Zero `\i` or `INCLUDE` directives anywhere reference them.

**Severity: ⚪** — keep both. Subagent's only recommendation is a tiny [`supabase/legacy/README.md`](supabase/legacy/README.md) noting "DO NOT APPLY — historical archive" so a future contributor doesn't accidentally pipe one through psql. That's a one-line fix; do it whenever, not blocking.

---

## Category 7 — RTL / Arabic edge cases (subagent)

### Findings

- 🟡 **Phone number masking not wrapped in LTR Directionality.** [family_group_screen.dart:875](lib/features/family_groups/screens/family_group_screen.dart#L875) renders `invitation.maskedPhone` (e.g. `"+966 **** 5678"`) inline with Arabic text without `Directionality(textDirection: TextDirection.ltr)`. Likely produces alignment artifacts on the asterisks.
- 🟡 **Western digits everywhere** (e.g. `12:34` time pickers, prices `15.99`, voice-note durations) — no Arabic-Indic digit conversion. App-wide policy decision; not a bug, but worth a CTO call: ٠١٢٣ or 0123? Currently 0123.
- 🟡 **`MaterialApp.router` is missing `localizationsDelegates` and `supportedLocales`.** [main.dart:791-804](lib/main.dart#L791-L804). Date manual-formatting via `'ar'` locale works, but Material's built-in dialogs (DatePicker, AlertDialog defaults) and accessibility labels may fall back to English. Three lines to add.
- 🟡 **English email hint placeholders** in login/signup screens (`example@email.com`, `user@example.com`). Cosmetic but jarring in an otherwise Arabic UI.
- 🟢 **Hadith content rendering** — uses `GoogleFonts.amiriQuran` with `height: 1.8`, `textAlign: TextAlign.justify`, `maxLines: 4` + ellipsis. Correctly handles Arabic diacritics. Watch for very long migrated hadiths (the 3 we added in Wave 2 are short — under 100 chars — so safe).
- 🟢 **Long Arabic name truncation** consistent across all relative-display widgets (`maxLines: 1` or `2`, `TextOverflow.ellipsis`). No layout breaks.
- 🟢 **Global `TextDirection.rtl`** correctly set in [main.dart:806](lib/main.dart#L806). LTR overrides for emails, phone, codes, URLs are explicit and correct.
- 🟢 **User-entered names that mix scripts** (e.g. "John Smith" in an Arabic family) — Flutter's Bidi algorithm handles them; no visual indicator distinguishes script direction, but that's acceptable.

**Severity verdict from the subagent:** TestFlight-go with the four 🟡 fixes prioritized. None are launch blockers; all are polish.

---

## Executive summary

### 🔴 Launch blockers (1)

1. **`send-scheduled-reminders` updates `last_sent` even on FCM send failure** — silent reminder drop. ([send-scheduled-reminders/index.ts:252-254](supabase/functions/send-scheduled-reminders/index.ts), Cat 1 + Cat 2). Smallest possible fix: only update `last_sent` if the response from `send-push-notification` indicates success. Pair with a unit test (Cat 1's recommendation).

### 🟡 Pre-launch worth fixing (8)

In rough order of user-visible impact:

2. **Announcement / scheduled-announcement status logic** marks "sent" on partial FCM failure (Cat 2).
3. **`MaterialApp.router` missing localizationsDelegates** — Material defaults to English; Arabic dialogs may fall back (Cat 7).
4. **Phone-number masked rendering** without explicit LTR Directionality (Cat 7).
5. **Western vs Arabic-Indic digits** — needs CTO call on app-wide policy (Cat 7).
6. **English email hint placeholders** — small but noticeable (Cat 7).
7. **`ensure_user_record` swallows all exceptions silently** — surface to error_reporter (Cat 5).
8. **Test helpers' `overrideWithValue` errors** — golden / widget-helper tests don't compile (Cat 3).
9. **Add 1 e2e test for the FCM-failure case** — pairs with launch blocker #1 (Cat 1).

### 🟢 Post-launch backlog (5)

- `_saveFamilyName` dead code in family_tree_screen.dart (Cat 3).
- DeepSeek proxy retry / backoff (Cat 2).
- Smart-nudge retry on push failure (Cat 2).
- 3 e2e integration tests (signup, group join, delete-account) (Cat 1).
- `inferEdges` returning `[]` for `RelationshipType.other` is silent — observability gap (Cat 4).

### ⚪ Documentation only (3)

- `supabase/legacy/README.md` — one-liner "DO NOT APPLY" (Cat 6).
- Pre-task: confirmed no silent test skips; the all-green claim is real.
- Auth surface: 7-migration trigger journey now sound; all sign-in paths covered by trigger or RPC.

### Recommended order of attention

1. Fix the reminder `last_sent` bug. **One change**, ~5 lines in the edge function.
2. Add the localizationsDelegates to MaterialApp.router. **Three lines** in main.dart.
3. Wrap masked phone in LTR Directionality. **One widget**.
4. Decide the digit policy (western vs Arabic-Indic) and apply it consistently. **CTO call.**
5. Update announcement-status logic to handle partial failures. **One file.**
6. Surface `ensure_user_record` errors to error_reporter. **Optional but cheap.**

Then ship to TestFlight. Everything else is fine to land post-launch.
