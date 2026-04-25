# DATABASE AUDIT — Silni

**Date:** 2026-04-26
**Reviewer:** CTO sweep (post Phase 0–3 + delete-account hot-fix)
**Scope:** all 134 applied migrations + the legacy `schema.sql` bootstrap + 63 RPCs

## TL;DR

- **38% of migrations are remediation** (51 of 134 are `fix_*`, `debug_*`, `cleanup_*`, `reseed_*`, `sync_*`). That ratio alone explains the founder's intuition that the schema accumulated debt as features were stacked.
- The bug we just hit (delete fails on FK to `auth.users`) is an instance of a wider pattern: **inconsistent FK targets** (some tables FK to `auth.users(id)`, others to `public.users(id)`) **and inconsistent `ON DELETE` clauses** (some CASCADE, some SET NULL, some no clause = NO ACTION).
- **Critical schema drift**: `chat_conversations`, `chat_messages`, `ai_memories` exist on production (created via the legacy `schema.sql` bootstrap) but are **not defined in any migration**. A fresh deploy would not have them, and the chat feature would break.
- **Orphaned tables from deleted features** still occupy schema space: 7 `social_*` tables (Phase 0 deleted the social-publisher edge functions), `admin_challenges` (Phase 0 deleted Challenges), `admin_memory_categories` and `admin_ai_memory_config` (Phase 1 severed memory writes).
- **`handle_new_user` trigger has been re-fixed 5+ times.** It now does the right thing (inserts into both `profiles` and `users`) but it only fires on `INSERT` to `auth.users`. After Phase-0 account deletion, re-login reuses the same `auth.users` row → trigger doesn't fire → orphan state. The new `ensure_user_record()` RPC + the client call on every sign-in is the durable fix; document it so it doesn't get reverted.

Below: severity-ranked findings, each with the evidence trail, the impact, and the concrete fix. At the end: a proposed remediation migration ordered by risk.

---

## CRITICAL — already breaking or guaranteed to break a real flow

### C1. Schema drift: chat tables missing from migration history
**Evidence**
- `lib/shared/services/chat_history_service.dart` reads/writes `ai_memories`, `chat_conversations`, `chat_messages`.
- `grep "CREATE TABLE.*ai_memories\|chat_conversations\|chat_messages" supabase/migrations/*.sql` → **zero hits**.
- These tables exist on production because `supabase/legacy/schema.sql` was applied manually before the migration discipline started.
- A `supabase db reset` or fresh-project deploy would NOT have these tables. The chat feature would fail silently — the service catches errors and returns `[]`/`null`.

**Impact**
- New developer joining the project, or a staging refresh, gets a half-broken AI Chat feature with no error surfaced.
- Anyone investigating the schema by reading `supabase/migrations/` reaches incorrect conclusions about what tables exist.

**Fix**
Write a migration `20260426110000_capture_chat_tables.sql` that does `CREATE TABLE IF NOT EXISTS` for `chat_conversations`, `chat_messages`, and `ai_memories` exactly as they exist on prod. Use `pg_dump --schema-only --table=...` against prod to get the canonical DDL, paste it in the migration. After this migration, prod is unchanged (the IF NOT EXISTS guards), but fresh deploys finally produce the right schema.

---

### C2. Five FKs to `auth.users(id)` without `ON DELETE` clauses (= NO ACTION = blocks deletes)
**Evidence**
| Table.column | File |
|---|---|
| `family_groups.created_by` (NOT NULL) | `20260201150000_family_groups.sql:5` |
| `family_group_members.user_id` (NOT NULL) | `20260201150000_family_groups.sql:14` |
| `node_invitations.invited_by` (NOT NULL) | `20260308100000_node_invitations.sql:19` |
| `node_invitations.accepted_by` (nullable) | `20260308100000_node_invitations.sql:21` |
| `admin_audit_log.user_id` (nullable) | `20260101000000_security_fixes.sql` |

**Impact**
- This is exactly what bit you on delete-account: any user who created a group, joined a group, or sent/accepted an invitation could not be deleted. The whole `delete_user_account` transaction rolled back.
- `admin_audit_log.user_id` is the **last unfixed instance**. The admin user (you) accumulates audit-log entries on every role change; deleting your admin account would still raise 23503.
- Migration `20260426100000_delete_user_account_full_teardown.sql` (today's fix) handles the four group/invitation FKs by leaving groups + cleaning invitations *before* the auth.users delete. It does **not** touch `admin_audit_log`.

**Fix**
Two options, do both:
1. **Migration to add `ON DELETE SET NULL` to `admin_audit_log.user_id`** so admin-deletion stops being blocked by audit history. The audit row stays for compliance, just loses the user FK.
2. **Migration to add `ON DELETE CASCADE` to the four user/group FKs** — safer than relying on the procedural cleanup in `delete_user_account`. The procedural cleanup stays as the user-facing entry point but the constraint level becomes a safety net.

---

### C3. `handle_new_user` trigger is fragile and has been re-fixed 5+ times
**Evidence**
Migrations that redefine or fix this trigger, in order:
- `20250128100000_fix_profiles_sync_production.sql`
- `20251230100002_admin_profiles.sql`
- `20260103100000_sync_auth_users_to_profiles.sql`
- `20260109100000_fix_signup_trigger.sql`
- `20260129100000_fix_all_user_sync.sql` ← current authoritative definition
- `20260129110000_fix_trigger_search_path.sql`
- `20260208140003_trigger_and_policy_fixes.sql`

The current version (in `20260129100000`) inserts into both `profiles` and `users` with `ON CONFLICT DO NOTHING/UPDATE` and an `EXCEPTION WHEN OTHERS` swallow. That last clause is the danger: a failed insert is logged and ignored, leaving the user without a `public.users` row.

**Impact**
- Trigger silently fails → user can sign in but every operation that needs `public.users` (relatives, interactions, reminders, family groups) fails with FK violations later.
- The Phase-0 hot-fix RPC `ensure_user_record()` exists exactly because this trigger is unreliable. The client now calls the RPC on every sign-in, which papers over trigger failures by self-healing the `public.users` row.

**Fix**
Don't bother reworking the trigger. The `ensure_user_record()` RPC + the client-side call on `signedIn`/`initialSession` is **already the right architecture** — sign-in becomes idempotent, trigger failures are recovered automatically. What the schema needs is **documentation in the trigger's comment** explaining the `ensure_user_record` belt-and-braces, so the next developer doesn't try to "simplify" by removing the RPC.

---

## HIGH — bugs waiting to happen

### H1. Orphaned tables from deleted features
**Evidence**
| Table | Defined in | Status |
|---|---|---|
| `social_accounts` | `20260130100000_create_social_media_tables.sql` | ORPHANED — Phase 0 deleted the social-publisher edge function |
| `social_campaigns` | same | ORPHANED |
| `social_templates` | same | ORPHANED |
| `social_brand_voice` | same | ORPHANED |
| `social_posts` | same | ORPHANED |
| `social_analytics` | same | ORPHANED |
| `social_click_log` | same | ORPHANED |
| `admin_challenges` | `20251230100000_admin_panel_phase1.sql:174` | ORPHANED — Phase 0 deleted `ChallengesScreen` |
| `admin_memory_categories` | admin panel migrations | ORPHANED — Phase 1 severed memory writes |
| `admin_ai_memory_config` | admin panel migrations | ORPHANED — Phase 1 severed memory writes |
| `ai_memories` (the data table) | legacy schema only | ORPHANED — same |

**Impact**
- Carries data weight (storage, backups), schema scan time, and confuses anyone reading the migrations to understand the feature set.
- Some of these have `INSERT INTO ... ON CONFLICT` seeds in newer reseed migrations; the seeds will keep refreshing dead data.

**Fix**
Single migration `20260427000000_drop_deleted_feature_tables.sql` that does `DROP TABLE IF EXISTS` on all 11 tables in dependency order (FKs first). Provide a one-line rollback note in the migration header in case anything depends on these silently.

**Caveat to ask the founder before running**: if the founder has any plans to revive social posting in Phase 4+, these tables and their RLS policies would need to be re-created from scratch. Confirm intent before dropping.

---

### H2. Mixed FK targets: some tables FK to `auth.users`, others to `public.users`
**Evidence**
- `relatives.user_id` → `users(id)` ON DELETE CASCADE (public.users)
- `interactions.user_id` → `users(id)` ON DELETE CASCADE (public.users)
- `family_groups.created_by` → `auth.users(id)` (no clause)
- `family_group_members.user_id` → `auth.users(id)` (no clause)
- `family_edges.user_id` → `auth.users(id)` ON DELETE CASCADE
- `relatives.added_by` → `auth.users(id)` ON DELETE SET NULL
- `node_invitations.invited_by` → `auth.users(id)` (no clause)

**Impact**
- The mental model "delete cascades from public.users" is half-true. Tables FK'd to `auth.users` directly aren't reached by `DELETE FROM users`. This is the structural cause of the Phase-3 delete-account bug.
- New tables in future migrations will likely pick the wrong FK target by copy-paste from a neighboring file.

**Fix**
Pick **one canonical target** and document it. My recommendation: **always FK to `auth.users(id)` ON DELETE CASCADE**. Reasons:
1. `public.users.id` is itself an FK to `auth.users.id` ON DELETE CASCADE, so cascading from auth.users still reaches everything.
2. `auth.users` is the source of truth for identity. `public.users` is a mirror.
3. This is what Supabase's own examples and docs recommend.

A migration to alter the existing `public.users`-targeted FKs is risky (requires drop-and-recreate). Defer that to Phase 4. For now, **add a CONTRIBUTING note** that all NEW FK columns to user-id should target `auth.users(id) ON DELETE CASCADE`.

---

### H3. 38% of migrations are remediation
**Evidence**
- 51 of 134 migrations have names containing `fix_`, `debug_`, `cleanup_`, `reseed_`, or `sync_`.
- `20260103xxx` cluster: 11 fix-fix-fix migrations in a single day, mostly debugging admin gamification stats functions.
- Four `debug_*` files were merged into prod (`20260103160000_debug_admin_stats.sql` etc.).

**Impact**
- The migration log reads like a bug-fix journal, not a schema specification.
- For a new contributor running `supabase db reset` to set up a dev environment, they'd run all 134 in order — including the four debug_* migrations. The `debug_admin_stats` RPC ends up in production, callable.

**Fix**
Two parts:
1. **Squash the debug_* and debug-and-fix-each-other clusters** into a single migration per logical change. This is a meaningful effort (maybe a Phase 4 task on its own) but pays dividends — fewer files, clearer history. Caveat: only safe to do *once* per environment, with everyone aware.
2. **Drop the `debug_*` RPCs** from production. They were development-time helpers that got committed.

---

### H4. RLS recursion incident already happened — and the helper functions are now load-bearing
**Evidence**
- `20260204100000_fix_family_group_members_rls_recursion.sql` documents a `42P17 infinite recursion` incident on `family_group_members` RLS.
- The fix introduced `auth_user_group_ids()` and `auth_user_admin_group_ids()` SECURITY DEFINER helpers that bypass RLS to break the cycle.
- These helpers are now referenced by **at least 6 RLS policies** across `family_group_members`, `family_groups`, `relatives`, `family_edges`, etc.

**Impact**
- The helpers are CRITICAL infrastructure now. Any future change to `family_group_members` RLS that re-introduces a self-reference instead of using the helper will recurse again.
- The next contributor adding a new RLS policy on group-related tables may not know about this pattern.

**Fix**
- Add a SQL comment block to `auth_user_group_ids()` definition explaining the recursion-breaker role.
- Establish a code-review rule: any new RLS policy touching `family_group_members` MUST go through one of the helper functions, not a direct subquery.

---

## MEDIUM — code smells, latent issues

### M1. Four `debug_*` RPCs shipped to production
**Evidence**
```
debug_admin_stats           — 20260103160000_debug_admin_stats.sql
debug_with_gamification_test — 20260103190000_debug_with_gamification_test.sql
debug_subscription_status   — 20260103210000_debug_subscription_status.sql
debug_add_interactions      — 20260103240000_debug_add_interactions.sql
```

**Impact**
- These are callable by `authenticated` users (the GRANT EXECUTE is broad in the migrations). At minimum, they run plpgsql that touches admin tables.
- Several of them seed test data. `debug_add_interactions` actively creates rows.

**Fix**
Migration `20260427100000_drop_debug_rpcs.sql` that does `DROP FUNCTION IF EXISTS` for each of the four. Verify no production code calls them first (`grep -rn 'debug_admin_stats\|debug_with_gamification\|debug_subscription_status\|debug_add_interactions' lib/`).

### M2. No uniqueness constraint on `family_group_members(user_id, group_id)`
**Evidence**
- `20260201150000_family_groups.sql` defines `family_group_members` without a UNIQUE constraint on `(group_id, user_id)`.
- Atomic group RPCs (`create_group_atomic`, `join_group_by_invite_code`, `accept_node_invitation`) all check existence before insert, but a race between two concurrent calls could insert duplicate membership rows.

**Impact**
- Duplicate member rows would cause `getGroupMembers` to return the user twice, double-count in the leaderboard, and confuse the admin-transfer logic in `leave_group_atomic`.

**Fix**
Migration that adds `ALTER TABLE family_group_members ADD CONSTRAINT family_group_members_user_group_unique UNIQUE (group_id, user_id)`. Run a `SELECT group_id, user_id, COUNT(*) FROM family_group_members GROUP BY group_id, user_id HAVING COUNT(*) > 1` first to verify no existing duplicates would block the constraint.

### M3. `node_invitations` allows multiple pending invitations per (group, relative_id) only by application-layer check
**Evidence**
- `20260308100000_node_invitations.sql` does NOT define a partial-unique index on `(group_id, relative_id) WHERE status = 'pending'`.
- `create_node_invitation` RPC checks for existing pending invitations before insert, but again, a race could slip past.

**Fix**
Add a partial unique index:
```sql
CREATE UNIQUE INDEX node_invitations_one_pending_per_node
  ON node_invitations(group_id, relative_id)
  WHERE status = 'pending';
```

### M4. `users.subscription_status` enum is `('free', 'premium')` but the app uses `('free', 'max')`
**Evidence**
- `supabase/legacy/schema.sql:35`: `subscription_status TEXT NOT NULL DEFAULT 'free' CHECK (subscription_status IN ('free', 'premium'))`
- `lib/core/models/subscription_tier.dart:9-10`: `enum SubscriptionTier { free, max }` — value persisted as `'max'`.
- `20260111140000_fix_tier_names_premium_to_max.sql` renamed the tier app-side but the CHECK constraint on the column may not have been updated.

**Impact**
- If the app writes `subscription_status = 'max'` to `public.users`, the CHECK constraint may reject it. Subscription state is now usually held in `subscription_events` table not directly on `users`, which masks this.

**Fix**
Verify on prod: `SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conname = 'users_subscription_status_check'`. If the constraint still reads `('free', 'premium')`, replace it with `('free', 'max')` or drop the constraint entirely (the app no longer relies on this column).

### M5. `subscription_events` table FK pattern is inconsistent with the rest
**Evidence**
- `20251227200000_subscription_tracking.sql:50`: `user_id UUID REFERENCES users(id) ON DELETE CASCADE`
- This FKs to `public.users` (correct given existing pattern), not `auth.users`. So when the new `delete_user_account` deletes from `public.users`, this cascades correctly. ✅

**Status:** Actually fine — flagging as "verified" rather than as an issue. Listed here because it's worth noting the right pattern for future reference.

---

## LOW — cleanliness

### L1. `supabase/legacy/schema.sql` and `supabase/legacy/gamification_functions.sql` exist as historical snapshots but new contributors might mistakenly think they are authoritative
**Evidence**
- Phase 2 moved them to `legacy/` with a "Historical bootstrap" header.
- A fresh git clone could still see `legacy/schema.sql` and assume it's the seed.

**Fix**
- Add a `supabase/legacy/README.md` that says "DO NOT APPLY. These are historical snapshots from before migration discipline. The migrations folder is authoritative."

### L2. The `profiles` table is largely a shadow of `public.users`
**Evidence**
- `profiles(id, email, display_name, role, created_at, updated_at)`.
- `public.users(id, email, full_name, …, level, points, badges, …)`.
- `handle_new_user` populates BOTH tables with overlapping data.
- `profiles.display_name` is what the admin panel reads; `users.full_name` is what the mobile app reads. They drift.

**Impact**
- Two sources of truth for "what's this user's name" — admin panel can show stale names if `users.full_name` was updated post-signup.

**Fix (Phase 4 territory, not urgent):**
- Decide on canonical name: probably `users.full_name`.
- Make `profiles.display_name` a generated column or a view over `users.full_name`.
- Or merge the two tables entirely. Risky — defer.

### L3. `relatives.subscription_status`-style enum fields scattered with their own CHECK constraints
**Evidence**
- The pattern of `text + CHECK (column IN (...))` appears on `relatives.gender`, `relatives.relationship_type`, `node_invitations.status`, `family_group_members.role`, etc.
- Each rename or addition requires a CHECK migration.

**Fix (low priority):**
- Convert the most-stable ones to Postgres enums: `CREATE TYPE invitation_status AS ENUM ('pending', 'accepted', 'cancelled')`. Adds type safety, cuts CHECK constraint maintenance.

### L4. Many `INSERT INTO admin_*` seed migrations
**Evidence**
- `20260111120000_reseed_all_admin_tables.sql`, `20260111110000_reseed_hadith_quotes.sql`, etc.
- These re-insert reference data on every migration run, which is fine for `ON CONFLICT DO NOTHING` but couples migration history to content updates.

**Fix (Phase 4 territory):**
- Move admin-table seeds out of migrations into the admin panel itself. Migrations should define structure; the admin panel populates content.

---

## Proposed remediation roadmap

I've ordered these by **risk vs. value**. The first two are essentially zero-risk and high-value; the rest get progressively bolder.

### Wave 1 — ship now (zero schema mutation, just defining what's already there)
1. **C1 fix**: capture chat tables in a migration. `pg_dump` the existing tables, paste into `20260426110000_capture_chat_tables.sql`, ship. Prod unchanged, fresh deploys finally work.
2. **C2 partial fix**: add `ON DELETE SET NULL` to `admin_audit_log.user_id`. Last loose end of the delete-account bug.

### Wave 2 — clean up (minor mutation, well-defined)
3. **H1**: drop the 11 orphaned tables (after founder confirms no Phase 4+ revival).
4. **M1**: drop the 4 `debug_*` RPCs.
5. **M2**: add unique constraint to `family_group_members(group_id, user_id)`.
6. **M3**: partial-unique index on `node_invitations(group_id, relative_id) WHERE pending`.
7. **M4**: verify and fix the `users.subscription_status` CHECK constraint.
8. **L1**: README in `supabase/legacy/`.

### Wave 3 — restructural (Phase 4 territory, dedicated session)
9. **H2**: migrate the four `family_groups`/`family_group_members`/`node_invitations` FKs from `auth.users` to consistent CASCADE behavior. Touch with care.
10. **H3**: squash the 51 fix/debug/cleanup migrations into a smaller number of meaningful ones. Big effort, only safe to do once per environment.
11. **L2**: decide between merging `profiles` into `users` or making `profiles` a view.

### Wave 4 — preventative
12. Add a check in CI that any new migration adding `REFERENCES auth.users` or `REFERENCES users` includes an explicit `ON DELETE` clause. Bash one-liner against `git diff` would do.
13. Add a CONTRIBUTING.md section: "All FKs pointing at user-id columns target `auth.users(id) ON DELETE CASCADE`. Never `public.users(id)`."

---

## What this audit did NOT cover

- **Performance**: index coverage looked decent (125 indexes total) but I didn't run `EXPLAIN ANALYZE` on the actual hot-path queries. Worth doing once load grows.
- **RLS correctness for admin tables**: 30 policies in `admin_panel_phase1` + 30 in `admin_panel_phase2`. Spot-checked a few, didn't audit every one.
- **Storage RLS** (voice notes bucket, message images bucket): touched once in `20260123000001_fix_storage_rls.sql`. Not re-verified.
- **Edge function security**: out of scope — this audit is schema only.

The wave-1 fixes alone close the immediate pain points (the FK gap on admin_audit_log, and the schema-drift footgun on chat tables). I'd recommend shipping those next.
