# DATABASE WAVE 1.5 — Halted at expanded ghost-table verification

**Date:** 2026-04-26
**Status:** **HALTED.** Wave 1.5's Task 1 verification gate against the 80-table prod inventory expanded the ghost list from 6 to 14. Per the plan's standing order #1, the capture migration was not written. The plan explicitly required this halt: "If the diff contains anything else — STOP. Update GHOST_TABLES_RECONNAISSANCE.md with a 'Wave 1.5 verification update' section listing the additional ghosts."

GHOST_TABLES_RECONNAISSANCE.md has been updated with the verification section at the bottom. This report focuses on what's blocked, what's prepared, and the asks.

## What changed

The previous (6-ghost) reconnaissance scoped its check to `legacy/schema.sql` vs migrations. The 80-table prod list surfaced 8 more tables that exist on prod but have no migration:

| Table | Verdict | Why it's a ghost |
|---|---|---|
| `notification_history` | **CRITICAL** — needs capture | Used by `lib/main.dart` (notification-history writes), `data_export_service`, `notification_history_screen`, edge functions. The existing migrations reference it (e.g. seed_app_routes.sql links to `/notification-history`) but no migration creates the table. |
| `notification_tokens` | **CRITICAL** — needs capture | Used by `fcm_notification_service.dart` (FCM push). One migration creates an INDEX on it (`20260123000002_add_performance_indexes.sql:50`) but no migration creates the table. Confirms the table was supposed to exist but the CREATE was lost. |
| `admin_announcements` | **ACTIVE** — needs capture | `20251231500001_fix_admin_announcements.sql` does `ALTER TABLE` against it (renaming `title`/`body` to `_ar` and adding `_en` versions), assuming the table exists. No migration creates it. |
| `challenge_streaks` | drop candidate | Zero references anywhere in `lib/`, `supabase/migrations/`, `supabase/functions/`, or `supabase/legacy/schema.sql`. |
| `daily_challenges` | drop candidate | Same — zero references. |
| `gifts` | drop candidate | Zero references. (Note: the string "gifts" appears in `20251222_add_ai_fields_to_relatives.sql` but only as the column name `disliked_gifts` on the `relatives` table — not the `gifts` table.) |
| `wisdom_entries` | drop candidate | Zero references. |
| `occasions` | drop candidate | Zero references. (Note: "occasions" appears in migrations but only as `admin_message_occasions` — a different, migration-defined table.) |

## fcm_tokens vs notification_tokens — the duplication question

The most important finding from this verification: the FCM token storage exists in **two tables** on prod, both ghosts:

- **`fcm_tokens`** — defined only in `legacy/schema.sql`. Zero references in current `lib/`. Likely a relic from an older FCM service implementation that was renamed.
- **`notification_tokens`** — defined nowhere. Used by `fcm_notification_service.dart:284,630` (current FCM code path) and the `send-push-notification` edge function.

This is an FCM-token rename that was done in app code without a migration, leaving both tables alive on prod. Recommendation:

1. **Capture `notification_tokens`** in Wave 1.5 — it's the one the live app uses.
2. **Drop `fcm_tokens`** in Wave 2 along with the other true orphans, **but only after** confirming on prod that any rows still in `fcm_tokens` have been migrated to `notification_tokens` or are stale enough to discard.

Founder query for the data check, before any drop:

```sql
SELECT 'fcm_tokens' AS source, COUNT(*) AS rows FROM fcm_tokens
UNION ALL
SELECT 'notification_tokens', COUNT(*) FROM notification_tokens;

-- And to find rows in old but not new:
SELECT user_id, token, platform
FROM fcm_tokens f
WHERE NOT EXISTS (
  SELECT 1 FROM notification_tokens n WHERE n.token = f.token
);
```

If the second query returns rows, those are device tokens that would lose push delivery if `fcm_tokens` is dropped — needs a data-migration step before the drop.

## Reverse drift (admin_banners, admin_motd) — false positive, no action needed

The diff also surfaced two tables that are in migrations but not on prod: `admin_banners` and `admin_motd`. **This is intentional, not drift:** they were consolidated into `admin_in_app_messages` in `20260102000000_unified_messages.sql` and dropped in `20260102200000_cleanup_old_messages.sql`. A fresh `supabase db reset` correctly produces a database without them. No action needed.

## What's prepared during the halt

### Generalized dump helper

`scripts/dump_tables_for_capture.sh` is a generalization of the Wave 1 chat-tables helper. Takes one or more table names as arguments:

```bash
bash scripts/dump_tables_for_capture.sh users relatives interactions \
  reminder_schedules notification_history notification_tokens \
  admin_announcements > /tmp/wave_1_5_dump.sql
```

When the founder runs it (after Wave 1.5 scope is authorized), the output is paste-able straight into a capture migration the way the chat-tables flow worked.

### Updated reconnaissance doc

`GHOST_TABLES_RECONNAISSANCE.md` has a "Wave 1.5 verification update" section at the bottom with the full 14-ghost breakdown, the fcm_tokens/notification_tokens duplication explanation, and the reverse-drift resolution.

## Open asks for the CTO

1. **Authorize the expanded Wave 1.5 capture scope.** Originally 5 tables; now 7 critical (`users`, `relatives`, `interactions`, `reminder_schedules`, `notification_history`, `notification_tokens`, `admin_announcements`). `fcm_tokens` is conditional on the duplication-question answer below.

2. **Decide `fcm_tokens` disposition.** Run the duplication-check queries above. If `fcm_tokens` is empty or its rows are already in `notification_tokens`, drop it in Wave 2. Otherwise migrate rows first.

3. **Authorize the expanded Wave 2 drop list.** The original drop list (`hadith`, social_*, admin_challenges, admin_memory_categories, admin_ai_memory_config, ai_memories) plus `challenge_streaks`, `daily_challenges`, `gifts`, `wisdom_entries`, `occasions`. Verify the four "zero references anywhere" tables are truly empty on prod first:

   ```sql
   SELECT 'challenge_streaks' AS t, COUNT(*) FROM challenge_streaks UNION ALL
   SELECT 'daily_challenges',    COUNT(*) FROM daily_challenges    UNION ALL
   SELECT 'gifts',                COUNT(*) FROM gifts              UNION ALL
   SELECT 'wisdom_entries',       COUNT(*) FROM wisdom_entries     UNION ALL
   SELECT 'occasions',            COUNT(*) FROM occasions;
   ```
   If any of them have rows, that's data that's currently invisible to the app and needs a CTO call about whether the data matters before the table's dropped.

4. **Run the founder dump script** for the 7 (or 8) capture targets once authorization is granted. Same single-command flow as Wave 1 Task 1.

## What was NOT done

Per the halt rule, none of these:
- No `capture_core_tables.sql` migration written. Doing so without the prod introspection would be inferring schema, which the plan explicitly forbids.
- No FK lint run against a non-existent migration.
- No flutter analyze / test runs (the codebase didn't change in this session).

## Files added or changed

```
GHOST_TABLES_RECONNAISSANCE.md       [+verification update section, ~80 lines]
DATABASE_WAVE_1_5_REPORT.md          [new — this file]
scripts/dump_tables_for_capture.sh   [new — generalized helper]
```

Wave 1.5 is paused at this gate. Wave 2 destructive tasks remain blocked. Tag back when the expanded scope is authorized.

---

# Wave 1.5 closing update (2026-04-26)

After CTO authorization for expanded scope and the addition of read-only Supabase MCP access to this Claude Code instance, Wave 1.5 closed end-to-end. Migration `supabase/migrations/20260427300000_capture_core_tables.sql` captures all 7 critical ghost tables at their live prod shape.

## FCM duplication — RESOLVED

**Disposition: drop `fcm_tokens` in Wave 2; capture `notification_tokens` here.**

MCP queries that decided this:

```sql
SELECT 'fcm_tokens' AS source, COUNT(*) AS rows FROM fcm_tokens
UNION ALL
SELECT 'notification_tokens', COUNT(*) FROM notification_tokens;
```

Result: `fcm_tokens` has **0 rows**, `notification_tokens` has **23 rows**. The FCM service code in `fcm_notification_service.dart:284` uses an upsert pattern (`onConflict: 'fcm_token'`) — every device-token write goes to `notification_tokens`. The legacy `fcm_tokens` table is unused dead schema.

No data migration needed. Wave 2 can drop `fcm_tokens` clean.

## Drift findings (legacy/schema.sql vs prod)

I compared legacy/schema.sql shapes against prod for the 5 tables that exist in legacy. All drift below is **expected** — it comes from ALTER TABLE migrations that ran over the past year evolving the schema. Per the plan's "capture exactly what's live" rule, the new migration reflects prod, not legacy.

### `users` — drift: known + benign + one critical bug

- **9 columns added by various ALTER migrations** beyond legacy: `streak_deadline`, `streak_day_start`, `freeze_auto_use`, `last_interaction_at` (already in legacy), `onboarding_metadata`, `streak_warning_sent`, `subscription_product_id`, `subscription_expires_at`, `trial_started_at`, `trial_used`. All from migrations like `20251227200000_subscription_tracking.sql`, `20251229_premium_onboarding.sql`, etc. Captured as-is.
- **1 column dropped**: `last_streak_date` was removed by `20260111000001_remove_unused_last_streak_date.sql`. Visible in prod as a gap at `ordinal_position=23`. Captured shape doesn't include it.
- **CRITICAL: `users_subscription_status_check` allows `('free', 'premium', 'pro')`** — three values, *none* of which is `'max'` (the post-Phase-0 app value). The audit M4 said the CHECK was `('free', 'premium')`; reality is even worse. The app would silently fail to write `'max'` if anything ever bypassed RLS. **Wave 2 Task 3 must fix this.** Captured as-is here so prod and migration history agree on what the broken state is.

### `relatives` — drift: large but expected

- ~22 columns added by ALTER migrations: AI fields (interests, favorite_colors, etc.) from `20251222_add_ai_fields_to_relatives.sql`, family-sharing fields (family_group_id, added_by, family_side, is_self) from various 20260201/20260202 migrations, and `relative_category` from `20260302100000`.
- Captured at the latest shape.

### `interactions` — minimal drift

- Schema essentially matches legacy. A few new indexes added via `20260123000002_add_performance_indexes.sql`. Captured.

### `reminder_schedules` — drift: many added columns

- Legacy had 10 columns. Prod has 17. Added: `relative_id`, `notification_hour`, `days_of_week`, `interval_days`, `custom_title`, `custom_message`, `last_sent`. Captured.

### `fcm_tokens` — NOT CAPTURED

Per the FCM duplication resolution above, this table is being deferred to Wave 2 drop list. Not in the capture migration.

### `notification_history`, `notification_tokens`, `admin_announcements` — no legacy comparison

Not in `legacy/schema.sql`. Captured exactly as introspected on prod.

## Other notable findings

### Policy duplication on prod

`users` table has **12 RLS policies** — three copies each of SELECT / INSERT / UPDATE / DELETE under different names (e.g. `"Users can view own profile"` for `{public}` AND `"Users can view their own profile"` for `{authenticated}` AND `"users_can_view_own_profile"` for `{authenticated}`). Same triplication for the other three commands.

`reminder_schedules` has 5 policies — one `FOR ALL` overlapping with separate SELECT/INSERT/UPDATE/DELETE policies that have identical gating. Same redundancy on `interactions`.

Captured all of them verbatim per "don't improve" rule. Recommend a future cleanup session to dedupe — but not in scope here.

### `admin_announcements` has unfk'd UUID columns

`sent_by` and `created_by` are `UUID` columns with no FK constraint on prod. They look like they should reference `auth.users(id)` but don't. Captured as-is. **Adding the FKs later would require backfilling/validating the existing data first.** Tracking as a separate finding.

### Index parity confirmed via MCP

All 47 indexes across the 7 tables are introspected and captured. Including the partial unique index `idx_relatives_self_per_user_group` (prevents two `is_self=true` rows in the same family group) and several `WHERE` clauses on partial indexes — captured verbatim.

## FK cascades written and reasoning

All 9 FKs in the new migration use `ON DELETE CASCADE`. Reasoning per FK:

| FK | Reason for CASCADE |
|---|---|
| `users.id → auth.users.id` | Deleting an auth user wipes their entire data footprint. This is the chain root — every other CASCADE eventually fans out from here. |
| `relatives.user_id → users.id` | Relatives are owned by a user. No user, no relative. |
| `relatives.family_group_id → family_groups.id` | If the group is deleted, its relatives don't belong anywhere. |
| `interactions.user_id → users.id` | Interactions are per-user activity logs. |
| `interactions.relative_id → relatives.id` | An interaction without its relative is orphan data. |
| `reminder_schedules.user_id → users.id` | Reminders are per-user. |
| `reminder_schedules.relative_id → relatives.id` | Reminders without relatives can't fire correctly. |
| `notification_history.user_id → users.id` | Notification logs are per-user. |
| `notification_tokens.user_id → users.id` | A device token without an owning user can't be addressed. |

All of these match what's already on prod — no semantic change. The capture just makes the constraints reproducible from migration history.

## Wave 2 drop-candidate row counts (Task 5)

MCP query:

```sql
SELECT 'challenge_streaks' AS t, COUNT(*) FROM challenge_streaks UNION ALL
SELECT 'daily_challenges',    COUNT(*) FROM daily_challenges    UNION ALL
SELECT 'gifts',                COUNT(*) FROM gifts              UNION ALL
SELECT 'wisdom_entries',       COUNT(*) FROM wisdom_entries     UNION ALL
SELECT 'occasions',            COUNT(*) FROM occasions          UNION ALL
SELECT 'ai_memories',          COUNT(*) FROM ai_memories        UNION ALL
SELECT 'admin_challenges',     COUNT(*) FROM admin_challenges   UNION ALL
SELECT 'admin_memory_categories', COUNT(*) FROM admin_memory_categories UNION ALL
SELECT 'admin_ai_memory_config',  COUNT(*) FROM admin_ai_memory_config  UNION ALL
SELECT 'hadith',               COUNT(*) FROM hadith;
```

Results:

| Table | Rows | Disposition |
|---|---|---|
| `challenge_streaks` | 0 | safe to drop |
| `daily_challenges` | 0 | safe to drop |
| `gifts` | 0 | safe to drop |
| `wisdom_entries` | 0 | safe to drop |
| `occasions` | 0 | safe to drop |
| `ai_memories` | 0 | safe to drop (Phase-1 stopped writes; existing rows must have been cleaned) |
| `admin_challenges` | 0 | safe to drop |
| `admin_memory_categories` | **5** | **needs CTO call** — 5 admin-config rows. Likely the `user_preference / relative_fact / family_dynamic / important_date / conversation_insight` category list. Was tied to memory-extraction admin panel. Memory feature is dead, so the data is stranded. Recommend drop, but document the row count in the Wave 2 plan. |
| `admin_ai_memory_config` | **1** | **needs CTO call** — 1 row of admin config. Same reasoning as above. |
| `hadith` | **8** | **mild concern** — 8 rows of hadith content. App reads from `admin_hadith` (which has its own seed data), so this is unused. The 8 rows are likely from `supabase/seed_hadith.sql` (which is itself unmigrated and dead). Recommend drop, but the founder may want to verify the hadith content matches what's in `admin_hadith` before dropping in case there's any unique content here. |

The 7 truly-empty tables can drop without further checks. The 3 with rows need a CTO sanity-check on whether the data matters.

## MCP queries used (audit trail)

For audit-trail purposes per the plan's standing order #7, these are the MCP queries I ran during this session:

1. `mcp__plugin_supabase_supabase__list_projects` — discover the project ID.
2. `mcp__plugin_supabase_supabase__execute_sql` — FCM-token row counts (fcm_tokens vs notification_tokens).
3. `mcp__plugin_supabase_supabase__list_tables` (verbose) — initial full inventory; output too large, abandoned for targeted queries.
4. `mcp__plugin_supabase_supabase__execute_sql` — `information_schema.columns` for 7 tables.
5. `mcp__plugin_supabase_supabase__execute_sql` — `information_schema.referential_constraints` join for FKs on 7 tables.
6. `mcp__plugin_supabase_supabase__execute_sql` — `pg_constraint` CHECK constraints on 7 tables.
7. `mcp__plugin_supabase_supabase__execute_sql` — `pg_constraint` (cross-schema) for users.id FK to auth.users.
8. `mcp__plugin_supabase_supabase__execute_sql` — `pg_indexes` for 7 tables.
9. `mcp__plugin_supabase_supabase__execute_sql` — `pg_policies` for 7 tables.
10. `mcp__plugin_supabase_supabase__execute_sql` — `pg_class.relrowsecurity` for 7 tables.
11. `mcp__plugin_supabase_supabase__execute_sql` — Wave 2 drop-candidate row counts (10 tables).

All queries were SELECT-only. No writes via MCP at any point.

## Self-verification block confirmation

The migration ends with a DO block that raises if any of the following don't match prod:
- RLS not enabled on any of the 7 tables
- Policy counts: users=12, relatives=5, interactions=5, reminder_schedules=5, notification_history=4, notification_tokens=4, admin_announcements=5
- Spot-checks for the 4 most-important CHECK constraints (`users_subscription_status_check`, `interactions_type_check`, `reminder_schedules_frequency_check`, `notification_tokens_platform_check`)

The migration aborts cleanly on staging if any expectation is wrong.

## CI lint result

`bash scripts/check_migrations_for_missing_on_delete.sh supabase/migrations/20260427300000_capture_core_tables.sql` → **passes** (every FK in the new migration has an explicit `ON DELETE`).

`flutter analyze` → 8 baseline issues unchanged. No Dart code touched.

## Open questions for the CTO

1. **Apply to staging first.** The capture migration is idempotent against prod (no-op) and creates the right shape on fresh deploys. The self-verification block is the safety net. Recommended: apply to staging, run the self-verification implicitly, then push to prod.
2. **`users_subscription_status_check` is broken** (audit said `('free','premium')`, reality is `('free','premium','pro')`, neither matches the app's `'max'`). Wave 2 Task 3 must fix. This is the most important finding from this session.
3. **Policy duplication on `users`, `interactions`, `relatives`, `reminder_schedules`, `notification_history`** is captured verbatim. Recommend a future cleanup session to dedupe. Tracking as a separate finding, not in current scope.
4. **`admin_announcements.sent_by` and `.created_by` lack FK constraints** to `auth.users`. Captured as-is; consider adding FKs in a follow-up after backfilling/validating existing data.
5. **Wave 2 drop list expansion**: `admin_memory_categories` (5 rows), `admin_ai_memory_config` (1 row), and `hadith` (8 rows) need explicit yes/no before drop.
6. **Wave 2 destructive tasks unblock** after this migration applies cleanly to staging.

## Files added or changed

```
supabase/migrations/20260427300000_capture_core_tables.sql   [new — 7 tables, 9 FKs, 18 CHECKs, 47 indexes, 39 policies]
DATABASE_WAVE_1_5_REPORT.md                                  [+closing update — this section]
```

Wave 1.5 is complete. Wave 2 is unblocked once the capture lands on staging.
