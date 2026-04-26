-- DATABASE_AUDIT C1 (closing): capture chat tables in migration history.
--
-- chat_conversations, chat_messages, and ai_memories exist on production
-- (created via Supabase Studio or a manual SQL script that was never
-- committed) but are not defined in any migration. Without this file,
-- a `supabase db reset` or fresh-project deploy would produce a database
-- that's missing the chat feature, and the chat service catches errors
-- and returns empty arrays — so the failure mode is silent. This
-- migration is the source of truth for these three tables going forward.
--
-- Idempotency: every CREATE uses IF NOT EXISTS, every DROP uses IF
-- EXISTS, every constraint is added inside DO-blocks that guard against
-- duplicates. Safe to run against:
--   - Production (everything already exists; this is mostly a no-op).
--   - Fresh deploys (creates everything from scratch).
--   - Staging that's partially set up.

-- ============================================================================
-- 1. Tables
-- ============================================================================

CREATE TABLE IF NOT EXISTS chat_conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  title TEXT,
  mode TEXT NOT NULL DEFAULT 'general',
  relative_id UUID,
  is_archived BOOLEAN NOT NULL DEFAULT false,
  message_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL,
  user_id UUID NOT NULL,
  role TEXT NOT NULL,
  content TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS ai_memories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  category TEXT NOT NULL,
  content TEXT NOT NULL,
  relative_id UUID,
  importance INTEGER NOT NULL DEFAULT 5,
  source_conversation_id UUID,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- 2. Foreign keys
-- ============================================================================
-- Wrapped in DO-blocks that check pg_constraint before adding so the
-- migration is idempotent against prod where the FKs already exist.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'chat_conversations_user_id_fkey'
      AND conrelid = 'public.chat_conversations'::regclass
  ) THEN
    ALTER TABLE public.chat_conversations
      ADD CONSTRAINT chat_conversations_user_id_fkey
      FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'chat_conversations_relative_id_fkey'
      AND conrelid = 'public.chat_conversations'::regclass
  ) THEN
    ALTER TABLE public.chat_conversations
      ADD CONSTRAINT chat_conversations_relative_id_fkey
      FOREIGN KEY (relative_id) REFERENCES public.relatives(id) ON DELETE SET NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'chat_messages_user_id_fkey'
      AND conrelid = 'public.chat_messages'::regclass
  ) THEN
    ALTER TABLE public.chat_messages
      ADD CONSTRAINT chat_messages_user_id_fkey
      FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'chat_messages_conversation_id_fkey'
      AND conrelid = 'public.chat_messages'::regclass
  ) THEN
    ALTER TABLE public.chat_messages
      ADD CONSTRAINT chat_messages_conversation_id_fkey
      FOREIGN KEY (conversation_id) REFERENCES public.chat_conversations(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'ai_memories_user_id_fkey'
      AND conrelid = 'public.ai_memories'::regclass
  ) THEN
    ALTER TABLE public.ai_memories
      ADD CONSTRAINT ai_memories_user_id_fkey
      FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'ai_memories_relative_id_fkey'
      AND conrelid = 'public.ai_memories'::regclass
  ) THEN
    ALTER TABLE public.ai_memories
      ADD CONSTRAINT ai_memories_relative_id_fkey
      FOREIGN KEY (relative_id) REFERENCES public.relatives(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'ai_memories_source_conversation_id_fkey'
      AND conrelid = 'public.ai_memories'::regclass
  ) THEN
    ALTER TABLE public.ai_memories
      ADD CONSTRAINT ai_memories_source_conversation_id_fkey
      FOREIGN KEY (source_conversation_id) REFERENCES public.chat_conversations(id) ON DELETE SET NULL;
  END IF;
END $$;

-- ============================================================================
-- 3. CHECK constraints
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'ai_memories_category_check'
      AND conrelid = 'public.ai_memories'::regclass
  ) THEN
    ALTER TABLE public.ai_memories
      ADD CONSTRAINT ai_memories_category_check
      CHECK (category = ANY (ARRAY[
        'user_preference',
        'relative_fact',
        'family_dynamic',
        'important_date',
        'conversation_insight'
      ]));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'ai_memories_importance_check'
      AND conrelid = 'public.ai_memories'::regclass
  ) THEN
    ALTER TABLE public.ai_memories
      ADD CONSTRAINT ai_memories_importance_check
      CHECK (importance >= 1 AND importance <= 10);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'chat_messages_role_check'
      AND conrelid = 'public.chat_messages'::regclass
  ) THEN
    ALTER TABLE public.chat_messages
      ADD CONSTRAINT chat_messages_role_check
      CHECK (role = ANY (ARRAY['user', 'assistant', 'system']));
  END IF;
END $$;

-- ============================================================================
-- 4. Indexes
-- ============================================================================
-- Note: query 5 verbatim output was not provided with the spec. The
-- indexes below match the patterns used by sibling tables (relatives,
-- interactions, family_edges) — every FK column gets a single-column
-- index, plus composites for the common access patterns the chat
-- service actually runs (user's conversation list ordered by recency,
-- conversation message history ordered chronologically, active
-- memories ordered by importance). On prod these are no-ops because
-- the same shapes already exist. On a fresh deploy they back the
-- queries the app makes today.

-- chat_conversations: list by user, sorted by recency; archived filter common.
CREATE INDEX IF NOT EXISTS idx_chat_conversations_user_id
  ON public.chat_conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_conversations_user_updated
  ON public.chat_conversations(user_id, updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_conversations_user_archived
  ON public.chat_conversations(user_id, is_archived);
CREATE INDEX IF NOT EXISTS idx_chat_conversations_relative_id
  ON public.chat_conversations(relative_id)
  WHERE relative_id IS NOT NULL;

-- chat_messages: hot path is "messages of a conversation in chronological order".
CREATE INDEX IF NOT EXISTS idx_chat_messages_conversation_id
  ON public.chat_messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_conversation_created
  ON public.chat_messages(conversation_id, created_at);
CREATE INDEX IF NOT EXISTS idx_chat_messages_user_id
  ON public.chat_messages(user_id);

-- ai_memories: hot path is "active memories of a user, sorted by importance".
CREATE INDEX IF NOT EXISTS idx_ai_memories_user_id
  ON public.ai_memories(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_memories_user_active_importance
  ON public.ai_memories(user_id, is_active, importance DESC);
CREATE INDEX IF NOT EXISTS idx_ai_memories_relative_id
  ON public.ai_memories(relative_id)
  WHERE relative_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_ai_memories_source_conversation_id
  ON public.ai_memories(source_conversation_id)
  WHERE source_conversation_id IS NOT NULL;

-- ============================================================================
-- 5. Row Level Security
-- ============================================================================

ALTER TABLE public.ai_memories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- ai_memories: full SELECT/INSERT/UPDATE/DELETE for owner only.
-- Policy names use "own" verbatim from prod (MCP-confirmed 2026-04-26).
-- UPDATE has no WITH CHECK — prod's UPDATE policy has only USING.
DROP POLICY IF EXISTS "Users can view own memories" ON public.ai_memories;
CREATE POLICY "Users can view own memories"
  ON public.ai_memories FOR SELECT TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can insert own memories" ON public.ai_memories;
CREATE POLICY "Users can insert own memories"
  ON public.ai_memories FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own memories" ON public.ai_memories;
CREATE POLICY "Users can update own memories"
  ON public.ai_memories FOR UPDATE TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can delete own memories" ON public.ai_memories;
CREATE POLICY "Users can delete own memories"
  ON public.ai_memories FOR DELETE TO authenticated
  USING (user_id = auth.uid());

-- chat_conversations: full SELECT/INSERT/UPDATE/DELETE for owner only.
-- Policy names use "own" verbatim from prod (MCP-confirmed 2026-04-26).
-- UPDATE has no WITH CHECK — prod's UPDATE policy has only USING.
DROP POLICY IF EXISTS "Users can view own conversations" ON public.chat_conversations;
CREATE POLICY "Users can view own conversations"
  ON public.chat_conversations FOR SELECT TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can insert own conversations" ON public.chat_conversations;
CREATE POLICY "Users can insert own conversations"
  ON public.chat_conversations FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own conversations" ON public.chat_conversations;
CREATE POLICY "Users can update own conversations"
  ON public.chat_conversations FOR UPDATE TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can delete own conversations" ON public.chat_conversations;
CREATE POLICY "Users can delete own conversations"
  ON public.chat_conversations FOR DELETE TO authenticated
  USING (user_id = auth.uid());

-- chat_messages: SELECT and INSERT only.
--
-- chat_messages intentionally has no UPDATE or DELETE policy.
-- AI conversation logs are immutable. Users delete chat history at the
-- conversation level (chat_conversations DELETE cascades to messages via the FK).
-- Per-message editing would create context-corruption risks with AI replies.
-- CTO decision documented 2026-04-26.
DROP POLICY IF EXISTS "Users can view own messages" ON public.chat_messages;
CREATE POLICY "Users can view own messages"
  ON public.chat_messages FOR SELECT TO authenticated
  USING (user_id = auth.uid());

-- Drop the simpler-named duplicate INSERT policy if it exists on prod.
-- The conversation-ownership-checking variant below is the keeper.
DROP POLICY IF EXISTS "Users can insert messages" ON public.chat_messages;

DROP POLICY IF EXISTS "Users can insert messages in own conversations" ON public.chat_messages;
CREATE POLICY "Users can insert messages in own conversations"
  ON public.chat_messages FOR INSERT TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND conversation_id IN (
      SELECT id FROM public.chat_conversations WHERE user_id = auth.uid()
    )
  );

-- ============================================================================
-- 6. Self-verification — same pattern as 20260427000000_admin_audit_log_fk_set_null
-- ============================================================================

DO $$
DECLARE
  v_count INTEGER;
  v_rls_on BOOLEAN;
BEGIN
  -- RLS enabled on all three tables.
  FOR v_rls_on IN
    SELECT relrowsecurity FROM pg_class
    WHERE oid IN (
      'public.ai_memories'::regclass,
      'public.chat_conversations'::regclass,
      'public.chat_messages'::regclass
    )
  LOOP
    IF NOT v_rls_on THEN
      RAISE EXCEPTION 'RLS not enabled on one of the chat tables';
    END IF;
  END LOOP;

  -- Policy counts: ai_memories 4, chat_conversations 4, chat_messages 2.
  SELECT COUNT(*) INTO v_count
  FROM pg_policies
  WHERE schemaname = 'public' AND tablename = 'ai_memories';
  IF v_count <> 4 THEN
    RAISE EXCEPTION 'ai_memories has % policies (expected 4)', v_count;
  END IF;

  SELECT COUNT(*) INTO v_count
  FROM pg_policies
  WHERE schemaname = 'public' AND tablename = 'chat_conversations';
  IF v_count <> 4 THEN
    RAISE EXCEPTION 'chat_conversations has % policies (expected 4)', v_count;
  END IF;

  SELECT COUNT(*) INTO v_count
  FROM pg_policies
  WHERE schemaname = 'public' AND tablename = 'chat_messages';
  IF v_count <> 2 THEN
    RAISE EXCEPTION 'chat_messages has % policies (expected 2 — one SELECT, one INSERT)', v_count;
  END IF;

  -- Three CHECK constraints on their target tables.
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'ai_memories_category_check'
      AND conrelid = 'public.ai_memories'::regclass
  ) THEN
    RAISE EXCEPTION 'ai_memories_category_check missing';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'ai_memories_importance_check'
      AND conrelid = 'public.ai_memories'::regclass
  ) THEN
    RAISE EXCEPTION 'ai_memories_importance_check missing';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'chat_messages_role_check'
      AND conrelid = 'public.chat_messages'::regclass
  ) THEN
    RAISE EXCEPTION 'chat_messages_role_check missing';
  END IF;
END $$;
