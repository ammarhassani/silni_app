# DATABASE WAVE 1 + WAVE 4 — REPORT

**Date:** 2026-04-26
**Scope:** Wave 1 (additive fixes for C1, C2, C3, H4) + Wave 4 (CI discipline). All non-destructive.

## TL;DR

- **Tasks 2, 3, 4, 5, 6 shipped.** New migrations for the admin_audit_log FK fix and the load-bearing function documentation. New CI script + workflow job for FK discipline. CONTRIBUTING.md gained a "Database migration rules" section.
- **Task 1 HALTED at the audit's own STOP gate.** The audit assumed `chat_conversations`, `chat_messages`, and `ai_memories` were defined in `legacy/schema.sql`. They're not. The schema only exists on the live database, presumably created via Supabase Studio or a manual SQL script. Without the live definitions, capturing them in a migration would mean inventing the schema, which the plan explicitly forbids ("Don't infer or 'improve' anything — capture exactly what's live").
- A helper script for the founder to dump the live shape is committed; once you run it and paste the result back, Task 1 finishes in a five-minute follow-up.
- `flutter analyze`: 8 baseline issues, no new errors. Tests not re-run because no Dart code was touched.

## What shipped

### New migrations (3)

| Migration | Purpose |
|---|---|
| `20260427000000_admin_audit_log_fk_set_null.sql` | Fixes C2 final FK gap. Drops the existing `admin_audit_log_user_id_fkey` and re-adds it with `ON DELETE SET NULL` so admin-account deletes never get blocked by audit history. Self-verifying — the migration ends with a `pg_get_constraintdef` check that raises if the new constraint isn't `SET NULL`. |
| `20260427100000_document_load_bearing_functions.sql` | Re-creates four functions with prepended architecture comment blocks and `COMMENT ON FUNCTION` metadata: `handle_new_user`, `ensure_user_record`, `auth_user_group_ids`, `auth_user_admin_group_ids`. Bodies are byte-identical to the latest authoritative versions; only documentation is added. Done as a new migration (not edits to the historical ones) per the append-only rule. |

### New scripts (2)

| Script | Purpose |
|---|---|
| `scripts/check_migrations_for_missing_on_delete.sh` | Lints `supabase/migrations/*.sql` for FKs to `auth.users` or `public.users` that lack an explicit `ON DELETE` clause. Two modes: full-scan (occasional manual audit) and `--diff-only BASE_REF` (CI mode — only checks files added/changed against the base ref, so historical debt doesn't fail every PR). |
| `scripts/dump_chat_tables_for_capture.sh` | Founder helper for the halted Task 1. Runs `supabase db dump` against the linked project and extracts the DDL for the three chat tables to a temp file you can paste back. |

### CI changes

`.github/workflows/ci.yml` got a new `migrations-fk-discipline` job that runs the lint script in `--diff-only` mode against the PR base. Job is bounded to one bug class — won't grow into a general SQL linter without scope work.

### Documentation

`CONTRIBUTING.md` gained a "Database migration rules" section right at the top covering the four bullet points the plan specified plus the destructive-change protocol (write the migration in two halves: add new shape, ship + verify, then drop old shape).

## Halted: Task 1 (capture chat tables)

**STOP rule:** the plan said "If you find drift between `legacy/schema.sql` and live DB shape, STOP and write it down."

The drift turned out to be more severe than expected. There IS no `legacy/schema.sql` definition for the three tables. Exhaustive grep:

```bash
$ grep -in "chat_conversations\|chat_messages\|ai_memories" supabase/legacy/schema.sql
(empty)

$ grep -rln "CREATE TABLE.*chat_conversations\|CREATE TABLE.*chat_messages\|CREATE TABLE.*ai_memories" \
    supabase/migrations supabase/legacy
(empty)
```

The audit's framing — "they came from `legacy/schema.sql`" — was wrong. They came from somewhere else: most likely Supabase Studio's table editor, or a SQL script that was run via the SQL editor and never committed.

The chat feature works on production today, so the tables exist there. To capture them faithfully in a migration:

1. Founder runs `bash scripts/dump_chat_tables_for_capture.sh > /tmp/chat_tables_schema.sql`.
2. Founder pastes the output back.
3. I write the capture migration with `CREATE TABLE IF NOT EXISTS` wrapping each statement, plus indexes / RLS / grants from the dump.
4. Apply and verify.

The script is committed in this PR; one command on the founder's side closes Task 1.

## Findings the script surfaced beyond the audit

The plan asked: "If [the script] surfaces any FK that *also* lacks `ON DELETE` clauses (beyond the four already fixed and the admin_audit_log fix from Task 2), STOP and write them into the phase report."

Running the full scan against current state surfaces **exactly the 5 violations the audit identified**, no more:

```
supabase/migrations/20260101000000_security_fixes.sql:120:   user_id UUID REFERENCES auth.users(id),
supabase/migrations/20260201150000_family_groups.sql:5:    created_by UUID REFERENCES auth.users(id) NOT NULL,
supabase/migrations/20260201150000_family_groups.sql:14:   user_id UUID REFERENCES auth.users(id) NOT NULL,
supabase/migrations/20260308100000_node_invitations.sql:19:  invited_by UUID NOT NULL REFERENCES auth.users(id),
supabase/migrations/20260308100000_node_invitations.sql:21:  accepted_by UUID REFERENCES auth.users(id),
```

Status of each:
- **`admin_audit_log.user_id`** (line 120 of `20260101000000`) — fixed by today's `20260427000000_admin_audit_log_fk_set_null.sql`.
- **`family_groups.created_by`** — addressed procedurally by `delete_user_account`'s teardown (Phase-3 hot-fix). Wave 3 will address at the constraint level.
- **`family_group_members.user_id`** — same.
- **`node_invitations.invited_by`** — same.
- **`node_invitations.accepted_by`** — same.

**No new violations beyond the audit.** The historical 5 stay as-is until Wave 3; the CI lint runs in `--diff-only` mode so they don't block ongoing work.

## Verification

- `flutter analyze`: 8 baseline issues (5 underscore-lints, 1 `_saveFamilyName` warning, 2 `overrideWithValue` errors in test helpers). Identical to pre-Wave-1 baseline.
- `bash scripts/check_migrations_for_missing_on_delete.sh --diff-only HEAD~1` against this commit: passes (only checks the 3 new migrations, none of which add new FKs to user-id columns).
- `bash scripts/check_migrations_for_missing_on_delete.sh` (full scan): correctly surfaces the 5 historical violations described above. Expected — that's the documented baseline.
- The two new migrations are SQL that I have not applied locally. Per the plan ("If you can't easily verify against a live DB, note that in the report"): I haven't run them against a live DB. Reviewer should `supabase db diff` or apply to staging before pushing to prod.

## Open questions / asks for the CTO

1. **Run the chat-table dump.** One command (`bash scripts/dump_chat_tables_for_capture.sh > /tmp/chat_tables.sql`), paste back, and Task 1 closes. The longer this stays open the longer fresh-deploy parity stays broken.
2. **Apply the two new migrations to staging first.** `20260427000000_admin_audit_log_fk_set_null.sql` does FK surgery (drops + re-adds the constraint) and `20260427100000_document_load_bearing_functions.sql` re-defines four functions. Both are designed to be idempotent and side-effect-free for behavior, but the constraint-drop is the only real schema change in this batch and deserves a staging dry-run.
3. **Wave 2 readiness.** This wave didn't touch any of the destructive items (orphan tables, debug RPCs, the `users.subscription_status` CHECK). Those need an explicit "yes drop them" call. The audit lays out the full list under H1 / M1 / M4.
4. **The 5 historical FKs that still lack `ON DELETE`.** Wave 3 (FK unification) is the planned home for these. They're tracked, the procedural teardown handles them safely, and the CI lint won't add new instances. If you want a faster path, a single Wave 2.5 migration can `ALTER CONSTRAINT` all four to `ON DELETE CASCADE` — that's bounded surgery, not the full unification.

## Files added or changed

```
supabase/migrations/20260427000000_admin_audit_log_fk_set_null.sql      [new]
supabase/migrations/20260427100000_document_load_bearing_functions.sql  [new]
scripts/check_migrations_for_missing_on_delete.sh                       [new]
scripts/dump_chat_tables_for_capture.sh                                 [new]
.github/workflows/ci.yml                                                [+job: migrations-fk-discipline]
CONTRIBUTING.md                                                         [+section: Database migration rules]
DATABASE_WAVE_1_REPORT.md                                               [new — this file]
```

Wave 1 is done as far as can be done without your input. Tag back when the chat-table dump is ready or when you want to proceed to Wave 2.
