# DATABASE WAVE 2 — Halted at reconnaissance gate

**Date:** 2026-04-26
**Status:** HALTED. The reconnaissance task surfaced **six ghost tables** beyond the three chat tables that Wave 1 captured. Per the Wave 2 plan's standing order #1, no destructive work proceeded.

Full reconnaissance is in [GHOST_TABLES_RECONNAISSANCE.md](GHOST_TABLES_RECONNAISSANCE.md). This report summarizes what's blocked, what was prepared during the halt, and the recommended path to unblock.

## What's blocked

All five Wave 2 tasks plus the Wave 2.5 FK flip:

- **Task 1** — drop orphan tables (10 of them): blocked. Some of the orphans (e.g. anything FK'd to `users` or `relatives`) need the parent tables captured in migrations first, otherwise a fresh deploy that lacks the parents would never have created the orphans either, and the drop becomes meaningless or fails.
- **Task 2** — drop debug RPCs: technically not blocked by the recon (the RPCs don't depend on ghost tables), but the standing order says HALT all destructive work, so this is held.
- **Task 3** — fix `users.subscription_status` CHECK: blocked. Modifies the `users` table, which has no migration definition. Adding a constraint to a table the migration history doesn't acknowledge would compound the drift.
- **Task 4** — add unique constraints to `family_group_members` and `node_invitations`: not blocked by the recon (both tables ARE in migrations), but held under the same standing order.
- **Task 5 / Wave 2.5** — flip the four historical FKs to `ON DELETE CASCADE`: not blocked by the recon, but held.

## What I did

1. Ran the reconnaissance: inventoried 68 tables in `supabase/migrations/*.sql`, cross-checked against what's defined in `legacy/schema.sql`, and grepped Dart usage to determine which ghost tables are critical vs. true orphans.
2. Identified the 6 ghost tables (5 critical-path, 1 orphan).
3. Verified zero `lib/` references for every Wave 2 Task 1 orphan-table drop candidate and every Wave 2 Task 2 debug RPC. Tables are evidence-clean — when Wave 2 unblocks, the destructive migrations can be written immediately. See the recon's appendix for the full reference table.
4. Did NOT write any destructive migration. Did NOT modify any constraint. Did NOT drop anything.

## The 6 ghost tables (full detail in the recon)

| Table | Severity | Disposition |
|---|---|---|
| `users` | CRITICAL | needs Wave 1.5 capture |
| `relatives` | CRITICAL | needs Wave 1.5 capture |
| `interactions` | CRITICAL | needs Wave 1.5 capture |
| `reminder_schedules` | CRITICAL | needs Wave 1.5 capture |
| `fcm_tokens` | CRITICAL | needs Wave 1.5 capture |
| `hadith` | orphan | candidate for Wave 2 Task 1 drop list (app uses `admin_hadith`) |

## Row-count and value-distribution data the founder needs to gather (now or later)

Per Wave 2's tasks, several queries were planned for the live DB. They're still relevant for when Wave 2 unblocks. Bundling them here so the founder can run them once:

```sql
-- For audit C1 follow-up confirmation:
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- For Task 1 — ai_memories row count (curiosity per the plan):
SELECT COUNT(*) AS ai_memories_rows FROM ai_memories;

-- For Task 1 — verify the orphan tables actually exist on prod
-- (in case any were silently dropped at some point):
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'social_accounts', 'social_campaigns', 'social_templates',
    'social_brand_voice', 'social_posts', 'social_analytics',
    'social_click_log',
    'admin_challenges', 'admin_memory_categories', 'admin_ai_memory_config',
    'ai_memories', 'hadith'
  )
ORDER BY table_name;

-- For Task 3 — subscription_status value distribution:
SELECT subscription_status, COUNT(*) AS count
FROM users
GROUP BY subscription_status;

-- For Task 4 — duplicate-membership check:
SELECT group_id, user_id, COUNT(*) AS count
FROM family_group_members
GROUP BY group_id, user_id
HAVING COUNT(*) > 1;

-- For Task 4 — duplicate-pending-invitation check:
SELECT group_id, relative_id, COUNT(*) AS count
FROM node_invitations
WHERE status = 'pending'
GROUP BY group_id, relative_id
HAVING COUNT(*) > 1;
```

If any of these surface anything unexpected (especially the second-to-last with values other than 'free'/'max', or either of the duplicate checks returning rows), they need explicit CTO calls before the matching migration is safe to write.

## Open asks for the CTO

1. **Read the reconnaissance.** [GHOST_TABLES_RECONNAISSANCE.md](GHOST_TABLES_RECONNAISSANCE.md) lays out what was found and the recommended path forward.

2. **Authorize Wave 1.5.** Same pattern as Wave 1 Task 1: I write a `dump_core_tables_for_capture.sh`, you run it once against the linked project, paste back the output, I write `capture_core_tables.sql` with `CREATE TABLE IF NOT EXISTS` wrappers and idempotency guards. Zero schema mutation on prod; this is the same low-risk pattern that worked for the chat tables. Once it lands and is verified, Wave 2 can proceed.

3. **Confirm `hadith` should drop.** The app uses `admin_hadith`. The only reference to plain `hadith` is in `supabase/seed_hadith.sql` which is itself unmigrated. Confirming this lets us include it in the Wave 2 Task 1 drop list.

4. **Run the queries above** when convenient. The recon halt doesn't depend on these answers, but Tasks 3 and 4 of Wave 2 are gated on `subscription_status` distribution and the two duplicate checks. Easier to gather once than to halt twice.

## Note for future planning

Wave 2.6 (the cleanup of the procedural teardown in `delete_user_account` after Wave 2.5's CASCADEs render it redundant) is **still tracked** as a follow-up. It depends on Wave 2.5 shipping and being verified on staging. Logging it here so it doesn't fall off the radar.
