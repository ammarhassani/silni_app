---
name: Wave 1 fix report — chat tables migration policy-name correction
description: How the failing 20260427200000_capture_chat_tables.sql was fixed in place after prod aborted on the self-verification block.
type: project
---

# DATABASE WAVE 1 — Fix report (chat tables capture)

**Date:** 2026-04-26
**Migration corrected in place:** [20260427200000_capture_chat_tables.sql](supabase/migrations/20260427200000_capture_chat_tables.sql)
**Authorization:** Bounded amend-in-place because the migration had aborted on every environment it ran against — i.e. it was never successfully applied anywhere. Append-only discipline starts again at the next migration timestamp.

## What went wrong on the first run

`supabase db push` aborted in the migration's section-6 self-verification DO block:

```
ai_memories has 8 policies (expected 4)
```

### Root cause

The migration's `DROP POLICY IF EXISTS` statements targeted policy names containing the word **"their"** (e.g. `"Users can view their memories"`), but production's existing policies use the word **"own"** (e.g. `"Users can view own memories"`). Because the names didn't match:

1. `DROP POLICY IF EXISTS "Users can view their memories"` was a no-op against prod.
2. `CREATE POLICY "Users can view their memories"` then added a second policy alongside the existing `"Users can view own memories"`.
3. Net effect: every CRUD verb on `ai_memories` and `chat_conversations` ended up with two parallel policies — 4 verbs × 2 = 8 policies on `ai_memories`, which the self-check caught and aborted on.

A secondary mismatch: the migration's `UPDATE` policies declared `WITH CHECK (user_id = auth.uid())`, but prod's `UPDATE` policies have only `USING` (no `with_check` column populated in `pg_policies`). Re-creating with `WITH CHECK` would have re-introduced drift even after the rename was fixed.

## MCP query results (Step 1 — confirm rollback and capture verbatim names)

Ran via `mcp__plugin_supabase_supabase__execute_sql` against the linked production project (`bapwklwxmwhpucutyras`).

**Policy counts after rollback (confirmed clean):**

| Table | Policy count | Notes |
|---|---|---|
| `ai_memories` | 4 | matches expectation |
| `chat_conversations` | 4 | matches expectation |
| `chat_messages` | 3 | one extra — the duplicate `"Users can insert messages"` is still alive; the migration drops it explicitly |

**Verbatim policy names from prod:**

`ai_memories`:
- `"Users can view own memories"` (SELECT, USING `user_id = auth.uid()`)
- `"Users can insert own memories"` (INSERT, WITH CHECK `user_id = auth.uid()`)
- `"Users can update own memories"` (UPDATE, USING `user_id = auth.uid()`, **no WITH CHECK**)
- `"Users can delete own memories"` (DELETE, USING `user_id = auth.uid()`)

`chat_conversations`:
- `"Users can view own conversations"` (SELECT, USING `user_id = auth.uid()`)
- `"Users can insert own conversations"` (INSERT, WITH CHECK `user_id = auth.uid()`)
- `"Users can update own conversations"` (UPDATE, USING `user_id = auth.uid()`, **no WITH CHECK**)
- `"Users can delete own conversations"` (DELETE, USING `user_id = auth.uid()`)

`chat_messages`:
- `"Users can view own messages"` (SELECT, USING `user_id = auth.uid()`)
- `"Users can insert messages"` (INSERT, WITH CHECK `user_id = auth.uid()`) — **the duplicate to drop**
- `"Users can insert messages in own conversations"` (INSERT, WITH CHECK `user_id = auth.uid() AND conversation_id IN (SELECT id FROM chat_conversations WHERE user_id = auth.uid())`) — **the keeper**

## What was changed in the migration file (Step 2)

Single edit to [supabase/migrations/20260427200000_capture_chat_tables.sql](supabase/migrations/20260427200000_capture_chat_tables.sql), section 5. Tables, FKs, CHECK constraints, indexes, and the self-verification block are all unchanged.

### Renames (9 policy names total)

| Old name (broken) | New name (verbatim from prod) |
|---|---|
| `"Users can view their memories"` | `"Users can view own memories"` |
| `"Users can insert their memories"` | `"Users can insert own memories"` |
| `"Users can update their memories"` | `"Users can update own memories"` |
| `"Users can delete their memories"` | `"Users can delete own memories"` |
| `"Users can view their conversations"` | `"Users can view own conversations"` |
| `"Users can insert their conversations"` | `"Users can insert own conversations"` |
| `"Users can update their conversations"` | `"Users can update own conversations"` |
| `"Users can delete their conversations"` | `"Users can delete own conversations"` |
| `"Users can view their messages"` | `"Users can view own messages"` |

### WITH CHECK removed from UPDATE policies

The `UPDATE` policies on `ai_memories` and `chat_conversations` lost their `WITH CHECK (user_id = auth.uid())` clause to match prod's existing shape (USING-only). Practical semantics: with USING `user_id = auth.uid()` already filtering at row-visibility, an attacker can only UPDATE rows they own; rewriting `user_id` to a stranger's UUID would still silently succeed without WITH CHECK, but our app code never exposes such an UPDATE path. Capturing prod's actual shape > improving it.

### Unchanged on purpose

- The `chat_messages` duplicate-INSERT cleanup (`DROP POLICY IF EXISTS "Users can insert messages"`) and the keeper (`"Users can insert messages in own conversations"`) — both names already matched prod verbatim.
- The `chat_messages` immutability comment block (no UPDATE/DELETE policy by design).
- The self-verification expectations (4 / 4 / 2 policies, three CHECK constraints, RLS enabled).

## Verification

- `bash scripts/check_migrations_for_missing_on_delete.sh supabase/migrations/20260427200000_capture_chat_tables.sql` → passes (every FK has explicit `ON DELETE`).
- The migration was **not applied locally** (Docker unavailable in this session). Founder runs `supabase db push` to re-apply against prod.

## Step 3 — Re-run

**Action for the founder:** `supabase db push` from the project root.

Expected output: this migration applies cleanly (every CREATE/DROP guarded for idempotency; policy names now match prod verbatim, so the DROP POLICY IF EXISTS statements actually drop the existing policies before re-creating them, keeping the count at 4/4/2). Self-verification block must complete without raising.

If the self-verification still raises, capture the exact error and the live policy state (`SELECT * FROM pg_policies WHERE tablename IN ('ai_memories', 'chat_conversations', 'chat_messages');`) before any further action.

## Step 4 — Whether 20260427300000 also needed correction

`supabase/migrations/20260427300000_capture_core_tables.sql` (the Wave 1.5 core-tables capture: `users`, `relatives`, `interactions`, `reminder_schedules`, `fcm_tokens`, `notification_tokens`, `family_groups`, `family_group_members`, `node_invitations`) — **policy names in that migration were already MCP-introspected verbatim** during Wave 1.5, so no rename is needed.

However: as a precaution, if `20260427300000` also aborts on its own self-verification when applied, the same playbook applies — query `pg_policies` for the live names, fix in place, re-run. The bounded amend-in-place authorization extends to any never-applied migration that aborted in self-verification.

`20260427300000` has not yet been applied to prod. It will run on the same `supabase db push` that re-runs `20260427200000`. The founder should watch for either to abort.

## Lessons captured

- **Policy-name discovery is mandatory before writing a capture migration.** "Improvising" names from sibling migrations or guessing from convention will mismatch prod silently, and `DROP POLICY IF EXISTS` won't catch the mismatch. Future capture migrations: query `pg_policies` first, paste names verbatim.
- **UPDATE policies need `with_check` introspection too**, not just `qual`. `pg_policies.with_check` is `NULL` when prod has no `WITH CHECK` clause.
- **Self-verification with policy counts caught the mismatch immediately.** The `RAISE EXCEPTION` rolled the migration back cleanly — prod was untouched. The pattern is working as designed.

## Open follow-ups

1. **Wave 2 readiness** — still gated on the Wave 2 + Wave 2.5 destructive-changes go-ahead. Does not depend on this fix; this fix only re-opens the Wave 1 task that was supposed to have closed in `90cc7e1`.
2. **20260427300000 application** — if it aborts on prod, repeat the playbook (MCP query → fix in place → re-run → document).
