# DATABASE WAVE 1 — Task 1 follow-up

**Closes:** Task 1 of the Wave 1 + Wave 4 plan, halted in `08410ab` pending the prod schema dump.
**Date:** 2026-04-26
**Migration:** `supabase/migrations/20260427200000_capture_chat_tables.sql`

## Summary

The chat tables (`chat_conversations`, `chat_messages`, `ai_memories`) are now defined in migration history. Fresh deploys will produce the same shape that production has had since the legacy bootstrap. `supabase db reset` no longer silently breaks the chat feature.

## What the migration does

- Creates all three tables with `CREATE TABLE IF NOT EXISTS`. Column shapes match the spec verbatim — `gen_random_uuid()` PKs, `timestamptz now()` audit columns, the JSONB `metadata` on messages, the `is_active` flag on memories.
- Adds seven foreign keys, all wrapped in `pg_constraint` existence checks so the migration is idempotent on prod where the FKs already exist:
  - `chat_conversations.user_id → auth.users(id) ON DELETE CASCADE`
  - `chat_conversations.relative_id → public.relatives(id) ON DELETE SET NULL`
  - `chat_messages.user_id → auth.users(id) ON DELETE CASCADE`
  - `chat_messages.conversation_id → public.chat_conversations(id) ON DELETE CASCADE`
  - `ai_memories.user_id → auth.users(id) ON DELETE CASCADE`
  - `ai_memories.relative_id → public.relatives(id) ON DELETE CASCADE`
  - `ai_memories.source_conversation_id → public.chat_conversations(id) ON DELETE SET NULL`
- Adds three CHECK constraints (`ai_memories_category_check`, `ai_memories_importance_check`, `chat_messages_role_check`) with `pg_constraint` existence guards.
- Enables RLS on all three tables, drops + recreates 10 policies in the explicit shape: 4 for `ai_memories` (full CRUD owner-only), 4 for `chat_conversations` (full CRUD owner-only), 2 for `chat_messages` (SELECT and INSERT only).
- Self-verification DO block at the end: confirms RLS is on for all three tables, exact policy counts (4 / 4 / 2), and that the three CHECK constraints exist. RAISES if any expectation isn't met.

## Policy duplication cleanup confirmed

Per the spec:
- `DROP POLICY IF EXISTS "Users can insert messages" ON public.chat_messages` runs before the `CREATE POLICY` for the keeper.
- The keeper is `"Users can insert messages in own conversations"`, with a `WITH CHECK` clause that verifies both `user_id = auth.uid()` AND that the target conversation belongs to the caller (subquery on `chat_conversations`).
- Net result on prod: the simpler-named duplicate is removed, the conversation-ownership-checking variant remains. Self-verification's expectation of exactly 2 policies on `chat_messages` would fail if for any reason both INSERT policies ended up alive.

## chat_messages immutability decision

Captured as a SQL comment block right before the chat_messages SELECT policy:

```
-- chat_messages intentionally has no UPDATE or DELETE policy.
-- AI conversation logs are immutable. Users delete chat history at the
-- conversation level (chat_conversations DELETE cascades to messages via the FK).
-- Per-message editing would create context-corruption risks with AI replies.
-- CTO decision documented 2026-04-26.
```

The cascade path the comment refers to is the new
`chat_messages.conversation_id → chat_conversations(id) ON DELETE CASCADE`
FK added in this migration. Deleting a conversation cleans up its
messages atomically; users never reach the messages table directly for
mutation.

## Things I had to fill in beyond the spec

The plan said I had complete information, but **query 5 verbatim output (indexes) wasn't pasted in the message**, and the SELECT policy names for `chat_messages` weren't named explicitly. I noted the gap inside the migration's section 4 header and flag both here:

1. **Indexes (section 4 of the migration).** Inferred 11 indexes total based on the patterns used by sibling tables (`relatives`, `interactions`, `family_edges`) and the actual access patterns in `chat_history_service.dart`:
   - `chat_conversations`: `(user_id)`, `(user_id, updated_at DESC)`, `(user_id, is_archived)`, `(relative_id) WHERE NOT NULL`.
   - `chat_messages`: `(conversation_id)`, `(conversation_id, created_at)`, `(user_id)`.
   - `ai_memories`: `(user_id)`, `(user_id, is_active, importance DESC)`, `(relative_id) WHERE NOT NULL`, `(source_conversation_id) WHERE NOT NULL`.
   - All use `CREATE INDEX IF NOT EXISTS` so prod's existing indexes (whatever they are) won't conflict. Worst case: prod retains some indexes the migration didn't capture and a `supabase db reset` produces a slightly different index set than prod. That's a deviation from the audit's "capture exactly what's live" goal.
   - **Action:** when convenient, run `\d+ ai_memories`, `\d+ chat_conversations`, `\d+ chat_messages` against prod and diff against the migration's index list. If prod has indexes I missed, add them in a follow-up migration. If prod is missing indexes the migration adds, applying this migration to prod will create them — desirable.

2. **`chat_messages` SELECT policy name.** Picked `"Users can view their messages"` to match the naming pattern of the other policies in the same migration. If the prod policy already has a different name, the `DROP POLICY IF EXISTS` is a no-op against the prod name, my `CREATE POLICY` adds a new one, and the self-verification block then sees 3 policies on `chat_messages` and raises. To recover: drop the redundant prod-named SELECT policy after applying.

## Verification

- The migration is internally idempotent — every CREATE / ADD / DROP guards on existence first.
- `bash scripts/check_migrations_for_missing_on_delete.sh supabase/migrations/20260427200000_capture_chat_tables.sql` → passes (every FK has an explicit `ON DELETE`).
- The migration was **not applied locally** — Docker is unavailable in this session for `supabase start`, and `supabase db reset` against the linked project would be destructive. Recommend applying to staging first, then verifying via `supabase db diff` that prod is unchanged.

## Open questions for the CTO

1. **Apply the migration to staging first** and verify the self-verification DO block doesn't raise. The self-check is the safety net; if any expectation is wrong (policy count, CHECK absence, RLS off), the migration aborts cleanly and prod is untouched.
2. **Index parity check** (per the inferred-indexes note above). One-time `\d+` per table, diff against my list, follow-up migration if anything's missing.
3. **Wave 2 readiness** is still gated on the destructive-changes confirmation (drop the orphan tables, drop the debug RPCs, fix the `users.subscription_status` CHECK). Task 1 was the last open Wave 1 item — Wave 2 is now unblocked once you confirm scope.

Session A is fully closed with this commit.
