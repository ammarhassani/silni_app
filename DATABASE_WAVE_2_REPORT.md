---
name: Database Wave 2 + Wave 2.5 — completed
description: Final destructive wave shipped. 5 migrations applied to prod, 17 orphan tables dropped, subscription_status CHECK fixed, FKs flipped to CASCADE, Dart fetch dead code removed.
type: project
---

# DATABASE WAVE 2 + WAVE 2.5 — Completed

**Date:** 2026-04-26
**Status:** SHIPPED. All 5 migrations applied to prod, all self-verifications passed, all expected post-conditions verified via MCP.
**Commits:** `1bb7d04` (initial 5 migrations + Dart cleanup), `<next>` (Task 3 order fix + this report).

This report supersedes the prior halt-version of the same file.

## Decisions applied

| Decision | Outcome |
|---|---|
| **T1A** — `ai_memories` removed from drop list | Excluded. Stays as captured in `20260427200000_capture_chat_tables.sql`. |
| **T1B** — drop 3 admin_* tables AND clean up Dart fetches (Option B2) | Tables dropped + 3 fetch sites + 2 cache fields + 2 method declarations removed from Dart. Fallbacks are now the only path. |
| **T1C** — migrate 3 unique hadith rows then drop `hadith` (Option H1) | Migrated and dropped. `admin_hadith` grew from 7 → 10. |

## Migrations created and outcomes

### `20260427400000_drop_orphan_tables.sql`

**Action:**
1. Inserted 3 hadith rows into `admin_hadith` with `WHERE NOT EXISTS` idempotency on `source`. Schema mapping per CTO spec — wrapped in the `قال رسول الله ﷺ:` envelope used by existing rows, English source string ('Sahih Al-Bukhari 6138', 'Musnad Ahmad 7563', 'Musnad Ahmad 16033'), grade in Arabic to match existing rows (`صحيح` for Bukhari, `حسن` for the two Ahmad rows), category `silat_rahim`, tags localized in Arabic, `display_priority` = 101/102/103 (max was 100).
2. Dropped 17 tables in dependency order via `DROP TABLE IF EXISTS … CASCADE`: 7 social_*, 3 admin_*, 2 challenge legacy (challenge_streaks, daily_challenges), 3 unshipped feature stubs (gifts, wisdom_entries, occasions), `fcm_tokens`, `hadith`.
3. Self-verified via DO block — all 17 absent from `pg_class`, all 3 migrated source values present, `admin_hadith` row count ≥ 10.

**Result:** Applied cleanly. MCP-verified post state: 17 tables `gone`, `admin_hadith` = 10 rows.

### `20260427500000_drop_debug_rpcs.sql`

**Action:** `DROP FUNCTION IF EXISTS` for the 4 debug_* RPCs.

**Surprise:** MCP introspection at apply time showed only `debug_admin_stats()` actually existed on prod. The other three were already gone (dropped previously without a migration, or never existed). `IF EXISTS` handled the absent ones cleanly with NOTICE messages.

**Result:** Applied cleanly. Self-verification confirmed zero `debug_*` functions in `public`.

### `20260427600000_fix_subscription_status_check.sql`

**Action (corrected order):**
1. DROP existing CHECK.
2. UPDATE `users` SET `subscription_status='max'` WHERE not in ('free','max'). 5 rows.
3. ADD new CHECK `('free','max')`.
4. Self-verify constraint definition + zero violators.

**Bug caught and fixed mid-push:** the originally-shipped order was UPDATE → DROP → ADD (per the CTO spec). On the first push attempt this aborted with `SQLSTATE 23514` because the legacy CHECK `('free','premium','pro')` rejects `'max'` — the UPDATE itself fired the constraint. Applied a bounded amend-in-place (the migration had aborted without applying anything, so flipping the step order is safe), then re-pushed. Append-only discipline resumes at the next migration timestamp.

**Result:** Applied cleanly on the second push.

| Distribution | Before | After |
|---|---|---|
| `free` | 22 | 22 |
| `premium` | 5 | 0 |
| `pro` | 0 | 0 |
| `max` | 0 | 5 |

CHECK definition (verified via `pg_get_constraintdef`):
```sql
CHECK ((subscription_status = ANY (ARRAY['free'::text, 'max'::text])))
```

### `20260427700000_add_unique_constraints.sql`

**Action:** ensure `family_group_members_group_id_user_id_key` UNIQUE constraint exists; ensure `idx_node_invitations_unique_pending` partial unique index exists.

**Surprise:** both already existed on prod when MCP-introspected pre-write. The audit's H1 finding was stale — they were added at some point without a migration capture (or the audit was wrong). Migration is now a no-op on prod (the partial-index DDL emitted a NOTICE: "relation already exists, skipping") but ensures fresh deploys still get them.

**Result:** Applied cleanly.

### `20260427800000_historical_fks_to_cascade.sql`

**Action:** for each of the 4 historical FKs (`family_groups.created_by`, `family_group_members.user_id`, `node_invitations.invited_by`, `node_invitations.accepted_by`), DROP existing constraint, ADD with `ON DELETE CASCADE`. All 4 reference `auth.users(id)`. Self-verify every one has `ON DELETE CASCADE` in its `pg_get_constraintdef`.

**Result:** Applied cleanly. MCP-verified post state — all 4 constraint definitions now contain `ON DELETE CASCADE`.

## Dart cleanup (Task 1.5)

Removed dead read paths since the underlying tables no longer exist.

### [lib/core/services/gamification_config_service.dart](lib/core/services/gamification_config_service.dart)
- Removed `_challengesCache` field.
- Removed `_fetchChallenges()` from the `Future.wait` in `refresh()`.
- Removed `_challengesCache = null;` from `clearCache()`.
- Deleted `_fetchChallenges()` method (was lines 325–341).
- Simplified `challenges` getter — was a 6-line cache-or-fallback; now `List<ChallengeConfig> get challenges => ChallengeConfig.fallbackChallenges();`.

### [lib/core/services/ai_config_service.dart](lib/core/services/ai_config_service.dart)
- Removed `_memoryConfigCache` and `_memoryCategoriesCache` fields.
- Removed `_fetchMemoryConfig()` and `_fetchMemoryCategories()` from the `Future.wait`.
- Removed both cache resets from `clearCache()`.
- Deleted `_fetchMemoryConfig()` and `_fetchMemoryCategories()` methods.
- Simplified `memoryConfig` and `memoryCategories` getters to return their `*.fallback*()` static methods directly.

## Verification

| Check | Result |
|---|---|
| `flutter analyze` | 8 issues (baseline preserved — pre-existing, none in files I touched). |
| `flutter test test/unit/` | 1349 pass / 4 pre-existing fail. Baseline preserved. |
| `bash scripts/check_migrations_for_missing_on_delete.sh --diff-only origin/main` | clean — none of the 5 new migrations introduce missing-`ON DELETE` debt. |
| `supabase db push` | applied all 5 migrations (after Task 3 order fix). |
| MCP post-apply verification (single round-trip query) | 17 dropped tables `gone`, `admin_hadith=10`, CHECK is `('free','max')`, distribution 22 free / 5 max / 0 premium / 0 pro, all 4 FKs `ON DELETE CASCADE`. |

The full-tree mode of the FK lint still flags the historical baseline violations (those source-file lines are unchanged — Wave 2.5's CASCADEs override them at runtime, but the script reads files line-by-line). The script is documented as expected to fail in full-tree mode and is only used in `--diff-only` mode in CI.

## MCP queries used

All read-only via `mcp__plugin_supabase_supabase__execute_sql`. No writes through MCP.

1. `hadith` vs `admin_hadith` row count + content dump (pre-task verification).
2. `users` subscription_status distribution.
3. `pg_get_constraintdef` for `users_subscription_status_check`.
4. `admin_hadith` introspection: max `display_priority`, distinct categories, distinct grades.
5. `pg_proc` lookup for the 4 debug_* RPCs (only `debug_admin_stats` existed).
6. `pg_constraint` and `pg_indexes` for `family_group_members` and `node_invitations` (both unique constraints already existed).
7. `pg_get_constraintdef` for the 4 historical FKs (all reference `auth.users(id)` with default NO ACTION).
8. `mcp__plugin_supabase_supabase__list_migrations` — confirm `20260427200000` and `20260427300000` were already applied.
9. Final post-apply verification — 17 dropped tables, admin_hadith count, CHECK def, distribution, 4 FK definitions in one round-trip.

## Surprises and what they mean

1. **Task 3 order bug.** The CTO-supplied order (UPDATE → DROP → ADD) failed because the legacy CHECK rejects `'max'`. The first push aborted; bounded amend-in-place flipped the order to DROP → UPDATE → ADD; second push clean. Lesson: when migrating values to a new tier name that the OLD CHECK forbids, drop the CHECK first.
2. **Task 2 — only 1 of 4 debug RPCs existed.** `debug_admin_stats` was the only live one. The audit's listing source must have been older / aspirational. `IF EXISTS` made this a non-issue.
3. **Task 4 — both unique constraints already existed.** Not net-new fixes; the audit's H1 was stale. Migration captures them so fresh deploys still get them.
4. **English hadith translations not migrated.** The CTO chose to leave them in git history (`hadith` table definition + seed file are still reachable). If/when an i18n pass happens for `admin_hadith`, those translations are recoverable via `git show`.

## Wave 2.6 — still tracked

The procedural per-FK teardown loop in `delete_user_account` (was needed before Task 5 because the FKs had no CASCADE). After today's CASCADE flip, that loop is redundant — deleting the auth user automatically removes the dependent rows. Wave 2.6 cleans up the loop. Hold for a separate session, after a few days of staging observation to confirm no surprise CASCADE behavior.

## Wave 2.7 — still tracked, post-TestFlight

RLS policy dedup. Per Wave 1.5 reconnaissance, several tables (notably `users` with 12 policies) have duplicate / overlapping policies. Pure cleanup, no behavior change. Hold until post-TestFlight to avoid touching the auth surface during launch.

## Wave 3 — still tracked, post-TestFlight

FK target unification — auth.users vs public.users mixed-target issue from the audit's H2. Same hold-until-post-TestFlight rationale.

## Outstanding

- ✅ All Wave 2 + Wave 2.5 tasks done.
- ✅ Migrations on prod and verified.
- ✅ Dart cleanup committed.
- ✅ Baseline preserved (analyzer, tests, lint).
- 🟡 Wave 2.6 (delete_user_account procedural teardown cleanup) — separate session, after staging observation.
- 🟡 Wave 2.7 (policy dedup) — post-TestFlight.
- 🟡 Wave 3 (FK target unification) — post-TestFlight.
