# Phase γ.2 — Track 1 + 2 report

**Date:** 2026-05-03
**Status:** Track 1 shipped. Track 2 verification complete. Awaiting CTO Track 3 design.

---

## Track 1 — Strict-9 partial seed

### Pre-flight test-write on `warm` tone

| Step | Result |
|---|---|
| Snapshot `warm.prompt_modifier` | `استخدم لغة دافئة ومحببة` (23 chars) |
| Test-write doc §F.1 content via MCP `apply_migration` | ✅ success |
| Verify length post-write | 380 chars |
| Revert to original 23-char value | ✅ success |
| Verify length post-revert | 23 chars |

The `DO $body$ ... UPDATE ... SET col = $content$ ... $content$ ... END $body$;` pattern works reliably with Arabic content + ASCII quotes + parentheses + Arabic punctuation. Confirmed safe for the 9-row bulk seed.

**Panel-editability:** I cannot interactively verify silni-admin → AI → Message Tones from this session (no browser context). Structural panel-editability is guaranteed by RLS policy `Admins can manage X` on the table + the fact that the γ.2-prep `admin_ai_identity` seed was confirmed panel-editable by the founder. All 6 target tables in this Track use the same RLS pattern. Risk: low.

### Pre-state snapshot of all 9 target rows

| Row | Pre-state length | Pre-state content (excerpt) |
|---|---|---|
| `admin_ai_touch_points` / `home/greeting` | 310 | `أنت واصل، مساعد صلة الرحم. اكتب تحية قصيرة وودية…` 🚩 contained legacy `أنت واصل` |
| `admin_counseling_modes` / `general` | 61 | `تحدث بشكل عام عن أي موضوع يتعلق بصلة الرحم والعلاقات الأسرية.` |
| `admin_message_occasions` / `ramadan` | 0 | `(NULL)` |
| `admin_message_occasions` / `newborn` | 0 | `(NULL)` |
| `admin_message_occasions` / `recovery` | 0 | `(NULL)` |
| `admin_message_occasions` / `graduation` | 0 | `(NULL)` |
| `admin_communication_scenarios` / `apology` | 0 | `(NULL)` |
| `admin_message_tones` / `warm` | 23 | `استخدم لغة دافئة ومحببة` |
| `admin_message_tones` / `formal` | 24 | `استخدم لغة رسمية ومحترمة` |

### Migration filename

[supabase/migrations/20260503200000_seed_gamma_2_strict_match.sql](supabase/migrations/20260503200000_seed_gamma_2_strict_match.sql) — single self-contained migration with all 9 DO-blocks + self-verify block. Local file is canonical; remote was applied per-row via MCP after the bulk apply timed out.

### Application path

**Bulk apply timed out.** First attempt: send all 9 DO-blocks + self-verify in one `mcp__plugin_supabase_supabase__apply_migration` call. Returned `The operation timed out.` Post-state query confirmed nothing landed.

Per γ.2-prep surprise #1's escalation ladder ("split into per-table migrations → split per-row"), I dropped to per-row applies. **All 9 individual applies succeeded** (each <1s). The self-verify block was applied as a 10th call after the 9 row-writes; it `RAISE NOTICE`d successfully (no exceptions raised).

| Migration name | Row updated | Result |
|---|---|---|
| `seed_gamma_2_row_1_home_greeting` | `admin_ai_touch_points / home/greeting` | ✅ |
| `seed_gamma_2_row_2_general_mode` | `admin_counseling_modes / general` | ✅ |
| `seed_gamma_2_row_3_ramadan` | `admin_message_occasions / ramadan` | ✅ |
| `seed_gamma_2_row_4_newborn` | `admin_message_occasions / newborn` | ✅ |
| `seed_gamma_2_row_5_recovery` | `admin_message_occasions / recovery` | ✅ |
| `seed_gamma_2_row_6_graduation` | `admin_message_occasions / graduation` | ✅ |
| `seed_gamma_2_row_7_apology_scenario` | `admin_communication_scenarios / apology` | ✅ |
| `seed_gamma_2_row_8_warm_tone` | `admin_message_tones / warm` | ✅ |
| `seed_gamma_2_row_9_formal_tone` | `admin_message_tones / formal` | ✅ |
| `seed_gamma_2_self_verify` | (assertions only) | ✅ all 9 length/content checks passed |

### Post-state verification

```
row_id                          post_len    legacy_pos
modes/general                   335         0
occasions/graduation            340         0
occasions/newborn               374         0
occasions/ramadan               525         0
occasions/recovery              283         0
scenarios/apology               837         0
tones/formal                    561         0
tones/warm                      380         0
touch_points/home/greeting      805         0
```

- Every row has rich content (>100 chars; lengths consistent with the source doc).
- `legacy_pos = 0` for all rows means **no row contains the legacy `أنت واصل` substring** — Phase 6.1 leak in `home/greeting` is closed.
- Self-verify block ran clean (no `RAISE EXCEPTION` thrown).

---

## Track 2 — DB-vs-code verification

Full document: [GAMMA_2_DB_CODE_VERIFICATION.md](GAMMA_2_DB_CODE_VERIFICATION.md).

### Headline findings

1. **Touch-points: only 1 of 7 production rows is actively consumed.** `relative_detail/conversation_starters` is invoked from [ai_conversation_starters_sheet.dart:63-94](lib/features/relatives/widgets/detail/ai_conversation_starters_sheet.dart#L63-L94). The other 6 (including the just-fixed `home/greeting`) are **dormant** — DB rows exist, but no Flutter widget calls `AITouchPointService.generate(screenKey:..., touchPointKey:...)` for them.
2. **The `أنت واصل` leak fix is housekeeping, not behavior change.** `home/greeting` content is read by nothing today — the leak was leaking only into the DB row, not into runtime AI prompts. Track 1's seed correctly fixes the housekeeping issue but won't surface as a user-visible improvement until/unless the home-screen UI is wired to invoke the touch-point.
3. **Doc-only touch-points (6) genuinely don't exist in code under alternative names.** Verified via grep variants for each of `ai_hub/greeting`, `interaction/post_log`, `streak/break_consolation`, `occasion/reminder`, `weekly_report/intro`, `suggested_prompts/header`. If seeded, they would all be DORMANT until Flutter UI is built to invoke them.
4. **Modes: zero user picker.** The 4 DB modes (`general`/`relationship`/`conflict`/`communication`) are auto-selected by `AIModeDetector.detect()` based on `daysSinceLastContact` + `interactionCount`. No UI surface lets the user choose a mode. The mode is *displayed* in the persona greeting block subtitle but not selectable.
5. **The CTO's modes (`general`/`scripture_grounded`/`writing_help`/`reflection`) are a different paradigm.** Doc orients on response style; DB orients on user situation. Switching to doc's modes requires either a new mode-picker UI or NLU-extension to AIModeDetector — both non-trivial code work.
6. **Personality `precision` (73 chars) and `emotional` (72 chars) are placeholder one-liners.** The doc's `interaction_patterns` and `meta_behavior` (~1500 chars each) are a substantive rewrite. CTO's call: rename + overwrite (Option A in the verification doc), insert new rows (Option B), merge (Option C), or decommission + replace (Option D).

---

## Verification — automated

| Check | Result |
|---|---|
| `flutter analyze lib/` | **0 issues** (no code touched in this session, but verified) |
| `flutter test test/unit/` | **1040/1040 passing** |

Code was not modified in this session. Track 1 was content-only (DB updates via MCP). The migration file was committed locally for source-of-truth but applied via MCP per-row after the bulk timeout.

---

## Surprises

### S1 — Bulk MCP `apply_migration` timed out at ~9 DO-blocks of Arabic content
The migration file was 322 lines (9 DO-blocks + self-verify), totaling ~9KB of SQL. The MCP `apply_migration` tool returned `The operation timed out` without a more specific error. Post-state query confirmed zero rows updated — the timeout aborted the transaction. Per-row applies (each <1KB) all succeeded in <1s. The threshold is somewhere between "single DO block with one UPDATE" and "9 DO blocks" — couldn't pinpoint without testing intermediate sizes. **For future bulk seeds, plan on per-row applies** (or per-table chunks of 2-3 rows).

### S2 — Track 1 fixes a housekeeping issue, not a user-visible behavior issue
The Phase 6.1 leak (`home/greeting` containing `أنت واصل`) was real — the row's content was wrong. But the row's content was being read by nothing in the Flutter app. So the model never saw "أنت واصل" via this row. The leak existed solely as DB-state inconsistency. Founder may have expected this fix to surface visibly on the home screen — it won't, unless someone wires a home-screen widget to invoke `AITouchPointService.generate(screenKey: 'home', touchPointKey: 'greeting')`.

### S3 — `weekly_report/intro` doc surface duplicates an existing hardcoded prompt
The doc proposes a `weekly_report/intro` touch-point. The weekly-report screen already invokes `AIPrompts.weeklyReportPrompt` (a hardcoded const at [ai_prompts.dart:916-924](lib/core/ai/ai_prompts.dart#L916-L924)). If both ship, two parallel content paths exist for the same prompt. CTO needs to pick: migrate hardcoded → DB, or drop the proposed touch-point row.

### S4 — The `relative_detail/conversation_starters` row is the production touch-point and has the strongest existing guards
Of the 7 DB rows, this one is special: it's the only one a user actually sees (when opening conversation-starters sheet for a relative), AND it already includes "لا تفترض أي معلومة غير مذكورة في البيانات" — the no-fabrication guardrail that the inventory praised. Any γ.2 rewrite of this row should preserve those guards. The doc does NOT include this row in §B (touch-points), so γ.2 currently leaves it untouched.

### S5 — Migration timestamp drift
[supabase/migrations/20260503200000_seed_gamma_2_strict_match.sql](supabase/migrations/20260503200000_seed_gamma_2_strict_match.sql) is the local canonical migration. The remote DB now has 10 individual migration entries (`seed_gamma_2_row_1_home_greeting` through `_row_9_formal_tone` plus `seed_gamma_2_self_verify`) instead of one bundled migration. This compounds the existing local-vs-remote drift noted in γ.2-prep surprise #5. The next session that runs `supabase db pull` will need to reconcile these with the local single-file canonical version.

---

## Open questions for the CTO

1. **`home/greeting` dormancy:** seeded but unread. Is the intent to wire it into the home-screen UI as part of Track 3, or to accept the row as fix-in-place housekeeping? If the former, that's UI code work; if the latter, the seeded content is decoration.

2. **The 6 dormant DB touch-points (`home/priority_contacts`, `home/insight`, `relative_detail/health_explanation`, `reminders/time_suggestion`, `reminders/frequency_recommendation` + the just-seeded `home/greeting`):** are these slated for activation via Flutter UI in Track 3 or beyond? If never, they should probably be decommissioned (`is_active = false`) so the admin panel doesn't suggest they matter.

3. **Doc-only touch-points (6):** seed when their consumer UI is built, or never? See §S3 for the `weekly_report/intro` duplication question specifically.

4. **Modes:** keep the auto-detected user-state taxonomy (current), swap to the doc's response-style taxonomy (requires picker UI), or union (4+3=7 total)? Also affects the `CounselingMode` enum in code.

5. **Personality `precision` + `emotional`:** which Option (A overwrite+rename / B insert-new / C merge / D decommission+replace) does the CTO want? The verification doc has the verbatim current content for context.

6. **Track 3 scope:** based on the verification, Track 3 is materially larger than originally framed. It needs schema decisions (modes paradigm, touch-point surfaces to add or decommission), code work (mode picker UI, touch-point invocations from home screen / AI hub / etc.), and content work (the 22 still-unseeded doc rows). Likely 3-4 distinct sessions, not one. CTO to scope.

---

## Real-device verification request

@founder — please verify on real device. Track 1 lands content into the DB but the only row that's actively-consumed by the app today is the `relative_detail/conversation_starters` row, which we did NOT touch. So the user-visible effects of Track 1 are:

1. **AI message-generation for occasions** (`ramadan`, `newborn`, `recovery`, `graduation`) should now be richer/more grounded when you use the AI to compose messages for those mukasabat. Try: open AI hub → request a Ramadan greeting → compare to what you got pre-Track-1 (was: bare "تهنئة برمضان"; now should: include "بلَّغك اللهُ صيامَه وقيامَه" pattern + briefness rules).
2. **AI message-generation in `apology` scenario** should now include the no-self-flagellation guardrail + the 4-step apology structure.
3. **Tone modifiers `warm` / `formal`** should now produce more characterized output. Try: same message, two tones, compare.
4. **Mode `general` system prompt** should now be more substantive (was: 1-line; now: 5-bullet expanded). Subtle effect — most chat conversations use general mode by default.
5. **`home/greeting` row** content is updated but **not user-visible** because no widget reads it. Don't expect to see anything different on the home screen until Track 3 wires it.

Cache TTL is 5 min — wait at least that long after Track 1 lands before testing.

If anything renders garbled/unexpected, the row content is panel-editable in silni-admin → AI → [the relevant section] for fast iteration. The seed is the floor, not the ceiling.

---

## Files

```
NEW   GAMMA_2_DB_CODE_VERIFICATION.md                                        Track 2 audit
NEW   PHASE_GAMMA_2_TRACK_1_2_REPORT.md                                      this report
NEW   supabase/migrations/20260503200000_seed_gamma_2_strict_match.sql       canonical local migration
DB    9 rows updated via 9 individual MCP migrations + 1 self-verify block   applied to bapwklwxmwhpucutyras
```
