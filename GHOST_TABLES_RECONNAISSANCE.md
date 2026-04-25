# GHOST TABLES RECONNAISSANCE — Wave 2 halt gate

**Date:** 2026-04-26 (initial recon) / 2026-04-26 (Wave 1.5 verification update — see bottom of file)
**Trigger:** Wave 2 plan reconnaissance task ("List any tables that exist on prod but have no corresponding `CREATE TABLE` in any migration").
**Result:** **HALT.** **Wave 1.5 verification against the 80-table prod inventory expanded the ghost list from 6 to 14.** Five of the eight new ghosts are critical-path or cross-feature; three are cleanup candidates. Detail at the bottom.

## TL;DR

The Wave 1 capture migration (`20260427200000_capture_chat_tables.sql`) only fixed three of the ghost tables (`chat_conversations`, `chat_messages`, `ai_memories`). The same drift exists across the rest of the core schema: `users`, `relatives`, `interactions`, `reminder_schedules`, `fcm_tokens`, plus a relic `hadith` table.

Per the Wave 2 standing order #1 — "Reconnaissance runs first. Halt if ghost tables exist beyond the three chat tables" — **all destructive Wave 2 tasks are blocked** until the CTO authorizes a Wave 1.5 capture migration for the remaining five core tables.

## How I found this

```bash
# Inventory tables defined in migrations.
grep -rh "CREATE TABLE" supabase/migrations/*.sql | grep -oP "CREATE TABLE\s+(IF NOT EXISTS\s+)?[a-zA-Z_.]+" | sed -E 's/.*\b//' | sort -u

# Tables defined in legacy/schema.sql but NOT in any migration:
#   users, relatives, interactions, reminder_schedules, fcm_tokens, hadith
```

Cross-checked against actual Dart usage to confirm whether each ghost table is live or stale:

| Table | Dart references in `lib/` | Status |
|---|---|---|
| `users` | 11 files | **CRITICAL — core table, app reads/writes constantly** |
| `relatives` | 11 files | **CRITICAL — core table** |
| `interactions` | 12 files | **CRITICAL — core table** |
| `reminder_schedules` | 1 file | **CRITICAL — used by `reminder_schedules_repository.dart`** |
| `fcm_tokens` | 0 Dart files | **CRITICAL — used by `send-push-notification` edge function (server-side)** |
| `hadith` | 0 Dart, 1 seed-file reference | Orphan — `supabase/seed_hadith.sql` references it, app uses `admin_hadith` instead |

## What this means

A `supabase db reset` against a fresh project today produces a database with **none of the core tables**. Every app feature would fail. The fact that prod works at all means `legacy/schema.sql` was applied manually to prod at some point in the past — but that script was moved to `legacy/` in Phase 2 and is no longer auto-applied.

Five of these six tables are critical-path. Dropping anything adjacent (especially anything FK'd to `users`) without first capturing the canonical schema risks data loss on prod and producing a broken fresh-deploy.

## Plan recommendation

**Wave 1.5 — capture the remaining ghost tables.** Same pattern as the Wave 1 chat-tables capture:

1. Founder runs a dump script against the linked prod project (similar to `scripts/dump_chat_tables_for_capture.sh`) for these tables: `users`, `relatives`, `interactions`, `reminder_schedules`, `fcm_tokens`. Plus all indexes, RLS policies, FKs, and CHECK constraints on each.
2. I write a `capture_core_tables.sql` migration with `CREATE TABLE IF NOT EXISTS` wrappers + idempotency guards on every constraint (same pattern as the chat-tables migration).
3. Apply to staging, verify prod is unchanged, then proceed with Wave 2 destructive tasks.

For the orphan `hadith` table: include it in **Wave 2 Task 1's drop list** (after Wave 1.5 captures the five core tables). It's a true orphan; the app uses `admin_hadith` and the only reference to plain `hadith` is a seed-file relic. Drop with the rest of the orphans.

## Ask of the CTO

1. **Authorize Wave 1.5** — running the founder dump script to capture the five core tables. Same low-risk pattern as Wave 1 Task 1; it's all `CREATE TABLE IF NOT EXISTS` so prod is untouched.
2. **Confirm `hadith` can join the Wave 2 orphan-drop list** — the app uses `admin_hadith`, the only reference to plain `hadith` is `supabase/seed_hadith.sql`, which is itself unmigrated and dead code post-Phase-2 cleanup.
3. **Confirm Wave 2 destructive tasks remain on hold** until Wave 1.5 ships and is verified on staging.

## What I did NOT do in this session

Per the halt rule, none of these:
- No `drop_orphan_tables` migration written.
- No `drop_debug_rpcs` migration written.
- No `users_subscription_status` constraint change.
- No `family_group_members` / `node_invitations` unique-constraint additions.
- No Wave 2.5 FK flips.

The non-destructive prep work (grep verification of zero references in `lib/` for orphan tables and debug RPCs) IS done — see appendix below — so the moment Wave 1.5 lands, Wave 2 is ready to execute without re-doing the recon.

## Appendix: prep work for when Wave 2 unblocks

### Orphan tables — references in `lib/` and `supabase/`

All confirmed zero or expected references:

| Table | `lib/` Dart refs | Supabase migrations refs | Verdict |
|---|---|---|---|
| `social_accounts` | 0 | only `20260130100000_create_social_media_tables.sql`, `20260131100000_social_admin_rls_policies.sql` | safe to drop |
| `social_campaigns` | 0 | same | safe to drop |
| `social_templates` | 0 | same | safe to drop |
| `social_brand_voice` | 0 | same | safe to drop |
| `social_posts` | 0 | same + `20260131110000_fix_approved_posts_to_scheduled.sql` | safe to drop |
| `social_analytics` | 0 | same | safe to drop |
| `social_click_log` | 0 | same | safe to drop |
| `admin_challenges` | 0 (Phase-0 deleted Challenges screen) | `20251230100000_admin_panel_phase1.sql` | safe to drop |
| `admin_memory_categories` | 0 (Phase-1 severed memory writes) | admin panel migrations | safe to drop |
| `admin_ai_memory_config` | 0 (same) | same | safe to drop |
| `ai_memories` | only the now-no-op `chat_history_service.dart::saveMemory` (Phase 1 stubbed it) | `20260427200000_capture_chat_tables.sql` | safe to drop after row-count check |
| `hadith` (the legacy table) | 0 | only `supabase/seed_hadith.sql` (also unmigrated) | safe to drop |

Drop order (dependents first): `social_click_log` → `social_analytics` → `social_posts` → (`social_templates`, `social_campaigns`, `social_brand_voice`, `social_accounts` in any order) → `admin_challenges` → `admin_memory_categories` → `admin_ai_memory_config` → `ai_memories` → `hadith`.

### Debug RPCs — references in `lib/`

Four `debug_*` RPCs identified:
- `debug_admin_stats` (defined in `20260103160000_debug_admin_stats.sql`)
- `debug_with_gamification_test` (defined in `20260103190000_debug_with_gamification_test.sql`)
- `debug_subscription_status` (defined in `20260103210000_debug_subscription_status.sql`)
- `debug_add_interactions` (defined in `20260103240000_debug_add_interactions.sql`)

Grep results in `lib/` (only the Dart code — no edge functions ever called these):

```bash
$ grep -rn 'debug_admin_stats\|debug_with_gamification_test\|debug_subscription_status\|debug_add_interactions' lib/
(empty)
```

All four are safe to drop.

### Wave 2.5 FK flip — already verified safe by design

The four FKs to flip:
- `family_groups.created_by`
- `family_group_members.user_id`
- `node_invitations.invited_by`
- `node_invitations.accepted_by`

All currently FK to `auth.users(id)` with no `ON DELETE` clause. The flip to `ON DELETE CASCADE` only changes deletion semantics — no data is touched. Existing rows are unaffected. The only risk is that the `delete_user_account` procedural teardown becomes redundant; per the plan, that cleanup is Wave 2.6, not this session.

## What the founder needs to do next

1. Run this query in Supabase Studio's SQL Editor against prod to confirm the recon:

```sql
-- Confirms the 6 ghost tables exist on prod
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('users', 'relatives', 'interactions',
                     'reminder_schedules', 'fcm_tokens', 'hadith')
ORDER BY table_name;

-- Bonus: confirm there's nothing else surprising
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;
```

2. Compare the second query's output against the migration-defined inventory in this file (the 68 tables I listed at the top of the recon). If any table appears on prod that's not in either the migration list or the 6-ghost list above, that's another ghost we need to deal with before any drops.

3. If the recon checks out (only the 6 known ghosts, no extras), authorize Wave 1.5 capture for the 5 core tables. I'll write the dump helper and the capture migration in a follow-up session.

---

# Wave 1.5 verification update (2026-04-26)

The CTO ran the full prod table inventory in Supabase Studio and shared the 80-table list. I diffed it against `CREATE TABLE` statements across every migration. The 6-ghost finding was **not exhaustive**.

## The full ghost list — 14 tables

### Already known (6) — from initial reconnaissance

| Table | Severity | Disposition |
|---|---|---|
| `users` | CRITICAL — 11 Dart files | Wave 1.5 capture |
| `relatives` | CRITICAL — 11 Dart files | Wave 1.5 capture |
| `interactions` | CRITICAL — 12 Dart files | Wave 1.5 capture |
| `reminder_schedules` | CRITICAL | Wave 1.5 capture |
| `fcm_tokens` | needs CTO call — see below | Wave 1.5 capture OR Wave 2 drop |
| `hadith` | true orphan — app uses `admin_hadith` | Wave 2 drop |

### Newly surfaced (8)

| Table | Evidence | Disposition |
|---|---|---|
| `notification_history` | **CRITICAL.** Used by `lib/main.dart:712,721` (writes), `data_export_service.dart:308`, `notification_history_service.dart`, `notification_history_screen.dart`. Edge functions reference it (`send-announcement`, `send-push-notification`). | Wave 1.5 capture |
| `notification_tokens` | **CRITICAL.** Used by `fcm_notification_service.dart:284,630` (FCM upserts). One migration adds an INDEX on it (`20260123000002_add_performance_indexes.sql`) but no migration creates the table. | Wave 1.5 capture |
| `admin_announcements` | **ACTIVE.** `20251231500001_fix_admin_announcements.sql` does ALTER TABLE assuming it exists, but no migration creates it. | Wave 1.5 capture |
| `challenge_streaks` | Zero references anywhere — no Dart, no migrations, no edge functions, no seeds. | Wave 2 drop candidate |
| `daily_challenges` | Same — zero references. | Wave 2 drop candidate |
| `gifts` | Zero references in app/migrations. The string "gifts" appears in `20251222_add_ai_fields_to_relatives.sql` but only as the column name `disliked_gifts` on relatives — not the table. | Wave 2 drop candidate |
| `wisdom_entries` | Zero references anywhere. | Wave 2 drop candidate |
| `occasions` | Zero references in app. The string "occasions" appears in migrations but only as `admin_message_occasions` (different table) and column comments. The `occasions` table itself is unreferenced. | Wave 2 drop candidate |

## fcm_tokens vs notification_tokens — the duplication question

The CTO call I most need clarity on. Two tables on prod with overlapping purpose:

- **`fcm_tokens`** — defined in `legacy/schema.sql`; `fcm_tokens.user_id REFERENCES users(id) ON DELETE CASCADE`. Zero references in current `lib/`. Likely populated by an older version of FCM service code, now superseded.
- **`notification_tokens`** — not defined in any migration, used by `fcm_notification_service.dart` (the current FCM code path). One migration (`20260123000002_add_performance_indexes.sql`) adds a `user_id` index on it, confirming the table is supposed to exist.

This is duplicate-table drift caused by a rename that was done in app code without a migration. **Recommendation:**
1. Capture `notification_tokens` (the live one) in Wave 1.5.
2. Drop `fcm_tokens` in Wave 2 along with the other true orphans — but only after confirming on prod that `fcm_tokens` is empty (or that any rows it contains have already been migrated to `notification_tokens`). Query: `SELECT COUNT(*) FROM fcm_tokens;` and compare with `SELECT COUNT(*) FROM notification_tokens WHERE platform IN ('ios', 'android')`.

If `fcm_tokens` has rows that aren't in `notification_tokens`, that's data-migration territory and needs CTO authorization separately.

## Reverse-drift check (admin_banners, admin_motd) — RESOLVED, false positive

The diff also surfaced two tables that ARE in migrations but NOT on prod: `admin_banners` and `admin_motd`. **This is expected, not drift:**

- Both were created in `20251230100000_admin_panel_phase1.sql`.
- Both were intentionally consolidated into `admin_in_app_messages` via `20260102000000_unified_messages.sql`.
- Both were explicitly dropped via `20260102200000_cleanup_old_messages.sql` (`DROP TABLE IF EXISTS admin_motd CASCADE` + `DROP TABLE IF EXISTS admin_banners CASCADE`). `admin_banners` is dropped a second time in `20260107000000_cleanup_deprecated.sql` — belt and suspenders.

A fresh `supabase db reset` correctly produces a database with `admin_in_app_messages` and without the two old tables. No action needed.

## Updated CTO asks

1. **Authorize Wave 1.5 capture for 7 critical tables**: `users`, `relatives`, `interactions`, `reminder_schedules`, `fcm_tokens`, `notification_history`, `notification_tokens`, `admin_announcements`. (That's 8 if `fcm_tokens` is in scope; 7 if it goes to the Wave 2 drop list.)
2. **Decide `fcm_tokens` disposition** based on whether any data needs migrating to `notification_tokens`.
3. **Authorize Wave 2 expanded drop list**: original (`hadith`, social_*, admin_challenges, admin_memory_categories, admin_ai_memory_config, ai_memories) PLUS `challenge_streaks`, `daily_challenges`, `gifts`, `wisdom_entries`, `occasions`. Verify the four "zero references anywhere" tables are truly empty on prod first via `SELECT COUNT(*) FROM challenge_streaks;` etc.
4. **Wave 2 destructive tasks remain blocked** until Wave 1.5 captures all critical tables.
