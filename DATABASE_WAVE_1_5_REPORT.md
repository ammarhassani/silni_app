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
