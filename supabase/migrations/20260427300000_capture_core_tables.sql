-- DATABASE_AUDIT C1 (Wave 1.5 closing): capture 7 core ghost tables that
-- exist on production but are not defined in any migration.
--
-- Prod-introspected tables in scope:
--   users, relatives, interactions, reminder_schedules,
--   notification_history, notification_tokens, admin_announcements
--
-- Approach mirrors 20260427200000_capture_chat_tables.sql:
--   - CREATE TABLE IF NOT EXISTS — column shapes verbatim from prod.
--   - Every FK / CHECK wrapped in pg_constraint guards (idempotent).
--   - Every index via CREATE INDEX IF NOT EXISTS.
--   - RLS policies via DROP POLICY IF EXISTS + CREATE POLICY.
--   - Self-verification DO block at the end.
--
-- Per the plan, the captured shape is what's on prod TODAY, not what
-- legacy/schema.sql described from an older point in time. The current
-- prod shape incorporates all ALTER TABLE migrations that ran over the
-- past year — many columns added via migrations that are still in the
-- migration history. On prod this whole file is a no-op; on fresh
-- deploys it produces the right shape.
--
-- Drift findings documented in DATABASE_WAVE_1_5_REPORT.md.

-- ============================================================================
-- 1. Tables (column shapes verbatim from prod information_schema)
-- ============================================================================

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT NOT NULL,
  phone_number TEXT,
  profile_picture_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_login_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  email_verified BOOLEAN NOT NULL DEFAULT false,
  subscription_status TEXT NOT NULL DEFAULT 'free',
  language TEXT NOT NULL DEFAULT 'ar',
  notifications_enabled BOOLEAN NOT NULL DEFAULT true,
  reminder_time TEXT NOT NULL DEFAULT '09:00',
  theme TEXT NOT NULL DEFAULT 'light',
  total_interactions INTEGER NOT NULL DEFAULT 0,
  current_streak INTEGER NOT NULL DEFAULT 0,
  longest_streak INTEGER NOT NULL DEFAULT 0,
  points INTEGER NOT NULL DEFAULT 0,
  level INTEGER NOT NULL DEFAULT 1,
  badges TEXT[] NOT NULL DEFAULT '{}',
  data_export_requested BOOLEAN NOT NULL DEFAULT false,
  account_deletion_requested BOOLEAN NOT NULL DEFAULT false,
  updated_at TIMESTAMPTZ DEFAULT now(),
  streak_deadline TIMESTAMPTZ,
  streak_day_start TIMESTAMPTZ,
  freeze_auto_use BOOLEAN DEFAULT true,
  last_interaction_at TIMESTAMPTZ,
  onboarding_metadata JSONB,
  streak_warning_sent BOOLEAN DEFAULT false,
  subscription_product_id TEXT,
  subscription_expires_at TIMESTAMPTZ,
  trial_started_at TIMESTAMPTZ,
  trial_used BOOLEAN DEFAULT false
);

CREATE TABLE IF NOT EXISTS relatives (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL,
  full_name TEXT NOT NULL,
  relationship_type TEXT NOT NULL,
  gender TEXT,
  avatar_type TEXT,
  date_of_birth TIMESTAMPTZ,
  phone_number TEXT,
  email TEXT,
  address TEXT,
  city TEXT,
  country TEXT,
  photo_url TEXT,
  notes TEXT,
  tags TEXT[] NOT NULL DEFAULT '{}',
  priority INTEGER NOT NULL DEFAULT 2,
  islamic_importance TEXT,
  preferred_contact_method TEXT,
  best_time_to_contact TEXT,
  health_status TEXT,
  interaction_count INTEGER NOT NULL DEFAULT 0,
  last_contact_date TIMESTAMPTZ,
  is_archived BOOLEAN NOT NULL DEFAULT false,
  is_favorite BOOLEAN NOT NULL DEFAULT false,
  contact_id TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  interests TEXT[],
  favorite_colors TEXT[],
  favorite_foods TEXT[],
  clothing_size TEXT,
  gift_budget TEXT,
  disliked_gifts TEXT[],
  wishlist TEXT[],
  personality_type TEXT,
  communication_style TEXT,
  sensitive_topics TEXT[],
  relationship_challenges TEXT,
  relationship_strengths TEXT,
  ai_notes TEXT,
  emotional_closeness INTEGER,
  communication_quality INTEGER,
  conflict_history TEXT,
  support_level INTEGER,
  last_meaningful_interaction TIMESTAMPTZ,
  family_group_id UUID,
  added_by UUID,
  family_side TEXT,
  is_self BOOLEAN DEFAULT false,
  relative_category TEXT NOT NULL DEFAULT 'extended'
);

CREATE TABLE IF NOT EXISTS interactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL,
  relative_id UUID NOT NULL,
  type TEXT NOT NULL,
  date TIMESTAMPTZ NOT NULL DEFAULT now(),
  duration INTEGER,
  location TEXT,
  notes TEXT,
  mood TEXT,
  photo_urls TEXT[] NOT NULL DEFAULT '{}',
  audio_note_url TEXT,
  tags TEXT[] NOT NULL DEFAULT '{}',
  rating INTEGER,
  is_recurring BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS reminder_schedules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL,
  frequency TEXT NOT NULL,
  relative_ids UUID[] NOT NULL DEFAULT '{}',
  time TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  custom_days INTEGER[],
  day_of_month INTEGER,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  relative_id UUID,
  notification_hour INTEGER,
  days_of_week INTEGER[],
  interval_days INTEGER,
  custom_title TEXT,
  custom_message TEXT,
  last_sent TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS notification_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  notification_type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB DEFAULT '{}'::jsonb,
  sent_at TIMESTAMPTZ DEFAULT now(),
  delivered_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ,
  opened_at TIMESTAMPTZ,
  fcm_message_id TEXT,
  status TEXT DEFAULT 'sent',
  is_read BOOLEAN DEFAULT false
);

CREATE TABLE IF NOT EXISTS notification_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  fcm_token TEXT NOT NULL UNIQUE,
  platform TEXT NOT NULL,
  device_info JSONB DEFAULT '{}'::jsonb,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS admin_announcements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title_ar TEXT NOT NULL,
  body_ar TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'draft',
  scheduled_for TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  target_users TEXT NOT NULL DEFAULT 'all',
  custom_user_ids UUID[],
  notification_data JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  title_en TEXT,
  body_en TEXT,
  deep_link TEXT,
  deep_link_params JSONB DEFAULT '{}'::jsonb,
  notification_icon TEXT DEFAULT 'announcement',
  notification_sound TEXT DEFAULT 'default',
  priority TEXT DEFAULT 'high',
  total_recipients INTEGER DEFAULT 0,
  successful_sends INTEGER DEFAULT 0,
  failed_sends INTEGER DEFAULT 0,
  sent_by UUID,
  created_by UUID
);

-- ============================================================================
-- 2. Foreign keys
-- ============================================================================
-- Every FK introspected on prod via pg_constraint, with explicit ON DELETE
-- (all CASCADE — both because that's what's live and because the audit's
-- canonical pattern is "FK to user-id columns is CASCADE"). All wrapped in
-- pg_constraint existence checks so prod re-runs are no-ops.

DO $$
BEGIN
  -- users.id → auth.users.id (the chain root)
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'users_id_fkey'
      AND conrelid = 'public.users'::regclass
  ) THEN
    ALTER TABLE public.users
      ADD CONSTRAINT users_id_fkey
      FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;

  -- relatives.user_id → public.users.id
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'relatives_user_id_fkey'
      AND conrelid = 'public.relatives'::regclass
  ) THEN
    ALTER TABLE public.relatives
      ADD CONSTRAINT relatives_user_id_fkey
      FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
  END IF;

  -- relatives.family_group_id → public.family_groups.id
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'relatives_family_group_id_fkey'
      AND conrelid = 'public.relatives'::regclass
  ) THEN
    ALTER TABLE public.relatives
      ADD CONSTRAINT relatives_family_group_id_fkey
      FOREIGN KEY (family_group_id) REFERENCES public.family_groups(id) ON DELETE CASCADE;
  END IF;

  -- interactions.user_id → public.users.id
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'interactions_user_id_fkey'
      AND conrelid = 'public.interactions'::regclass
  ) THEN
    ALTER TABLE public.interactions
      ADD CONSTRAINT interactions_user_id_fkey
      FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
  END IF;

  -- interactions.relative_id → public.relatives.id
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'interactions_relative_id_fkey'
      AND conrelid = 'public.interactions'::regclass
  ) THEN
    ALTER TABLE public.interactions
      ADD CONSTRAINT interactions_relative_id_fkey
      FOREIGN KEY (relative_id) REFERENCES public.relatives(id) ON DELETE CASCADE;
  END IF;

  -- reminder_schedules.user_id → public.users.id
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'reminder_schedules_user_id_fkey'
      AND conrelid = 'public.reminder_schedules'::regclass
  ) THEN
    ALTER TABLE public.reminder_schedules
      ADD CONSTRAINT reminder_schedules_user_id_fkey
      FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
  END IF;

  -- reminder_schedules.relative_id → public.relatives.id
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'reminder_schedules_relative_id_fkey'
      AND conrelid = 'public.reminder_schedules'::regclass
  ) THEN
    ALTER TABLE public.reminder_schedules
      ADD CONSTRAINT reminder_schedules_relative_id_fkey
      FOREIGN KEY (relative_id) REFERENCES public.relatives(id) ON DELETE CASCADE;
  END IF;

  -- notification_history.user_id → public.users.id
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'notification_history_user_id_fkey'
      AND conrelid = 'public.notification_history'::regclass
  ) THEN
    ALTER TABLE public.notification_history
      ADD CONSTRAINT notification_history_user_id_fkey
      FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
  END IF;

  -- notification_tokens.user_id → public.users.id
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'notification_tokens_user_id_fkey'
      AND conrelid = 'public.notification_tokens'::regclass
  ) THEN
    ALTER TABLE public.notification_tokens
      ADD CONSTRAINT notification_tokens_user_id_fkey
      FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
  END IF;

  -- admin_announcements has no FKs on prod (sent_by, created_by are nullable
  -- UUID columns without FK constraints). Documenting the gap; not adding
  -- FKs here because the plan says capture exactly what's live.
END $$;

-- ============================================================================
-- 3. CHECK constraints
-- ============================================================================
-- All introspected verbatim from prod. NOTE: users_subscription_status_check
-- accepts ('free', 'premium', 'pro') — none of which is 'max' (the
-- post-Phase-0 app value). This is a known bug; Wave 2 Task 3 will fix it.
-- Capturing the broken state here so prod and migration history agree.

DO $$
BEGIN
  -- users
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'users_subscription_status_check' AND conrelid = 'public.users'::regclass) THEN
    ALTER TABLE public.users ADD CONSTRAINT users_subscription_status_check
      CHECK (subscription_status = ANY (ARRAY['free', 'premium', 'pro']));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'users_language_check' AND conrelid = 'public.users'::regclass) THEN
    ALTER TABLE public.users ADD CONSTRAINT users_language_check
      CHECK (language = ANY (ARRAY['ar', 'en']));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'users_theme_check' AND conrelid = 'public.users'::regclass) THEN
    ALTER TABLE public.users ADD CONSTRAINT users_theme_check
      CHECK (theme = ANY (ARRAY['light', 'dark']));
  END IF;

  -- relatives
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'relatives_priority_check' AND conrelid = 'public.relatives'::regclass) THEN
    ALTER TABLE public.relatives ADD CONSTRAINT relatives_priority_check
      CHECK (priority = ANY (ARRAY[1, 2, 3]));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'relatives_emotional_closeness_check' AND conrelid = 'public.relatives'::regclass) THEN
    ALTER TABLE public.relatives ADD CONSTRAINT relatives_emotional_closeness_check
      CHECK (emotional_closeness >= 1 AND emotional_closeness <= 5);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'relatives_communication_quality_check' AND conrelid = 'public.relatives'::regclass) THEN
    ALTER TABLE public.relatives ADD CONSTRAINT relatives_communication_quality_check
      CHECK (communication_quality >= 1 AND communication_quality <= 5);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'relatives_support_level_check' AND conrelid = 'public.relatives'::regclass) THEN
    ALTER TABLE public.relatives ADD CONSTRAINT relatives_support_level_check
      CHECK (support_level >= 1 AND support_level <= 5);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'relatives_family_side_check' AND conrelid = 'public.relatives'::regclass) THEN
    ALTER TABLE public.relatives ADD CONSTRAINT relatives_family_side_check
      CHECK (family_side = ANY (ARRAY['paternal', 'maternal']));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_relative_category' AND conrelid = 'public.relatives'::regclass) THEN
    ALTER TABLE public.relatives ADD CONSTRAINT chk_relative_category
      CHECK (relative_category = ANY (ARRAY['household', 'extended', 'distant']));
  END IF;

  -- interactions
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'interactions_type_check' AND conrelid = 'public.interactions'::regclass) THEN
    ALTER TABLE public.interactions ADD CONSTRAINT interactions_type_check
      CHECK (type = ANY (ARRAY['call', 'visit', 'message', 'gift', 'event', 'other']));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'interactions_rating_check' AND conrelid = 'public.interactions'::regclass) THEN
    ALTER TABLE public.interactions ADD CONSTRAINT interactions_rating_check
      CHECK (rating >= 1 AND rating <= 5);
  END IF;

  -- reminder_schedules
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'reminder_schedules_frequency_check' AND conrelid = 'public.reminder_schedules'::regclass) THEN
    ALTER TABLE public.reminder_schedules ADD CONSTRAINT reminder_schedules_frequency_check
      CHECK (frequency = ANY (ARRAY['daily', 'weekly', 'monthly', 'friday', 'custom']));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'reminder_schedules_day_of_month_check' AND conrelid = 'public.reminder_schedules'::regclass) THEN
    ALTER TABLE public.reminder_schedules ADD CONSTRAINT reminder_schedules_day_of_month_check
      CHECK (day_of_month >= 1 AND day_of_month <= 31);
  END IF;

  -- notification_history
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'notification_history_notification_type_check' AND conrelid = 'public.notification_history'::regclass) THEN
    ALTER TABLE public.notification_history ADD CONSTRAINT notification_history_notification_type_check
      CHECK (notification_type = ANY (ARRAY['reminder', 'streak', 'achievement', 'announcement']));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'notification_history_status_check' AND conrelid = 'public.notification_history'::regclass) THEN
    ALTER TABLE public.notification_history ADD CONSTRAINT notification_history_status_check
      CHECK (status = ANY (ARRAY['sent', 'delivered', 'read', 'failed']));
  END IF;

  -- notification_tokens
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'notification_tokens_platform_check' AND conrelid = 'public.notification_tokens'::regclass) THEN
    ALTER TABLE public.notification_tokens ADD CONSTRAINT notification_tokens_platform_check
      CHECK (platform = ANY (ARRAY['android', 'ios', 'web']));
  END IF;

  -- admin_announcements
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'admin_announcements_status_check' AND conrelid = 'public.admin_announcements'::regclass) THEN
    ALTER TABLE public.admin_announcements ADD CONSTRAINT admin_announcements_status_check
      CHECK (status = ANY (ARRAY['draft', 'scheduled', 'sent']));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'admin_announcements_target_users_check' AND conrelid = 'public.admin_announcements'::regclass) THEN
    ALTER TABLE public.admin_announcements ADD CONSTRAINT admin_announcements_target_users_check
      CHECK (target_users = ANY (ARRAY['all', 'active', 'premium', 'custom']));
  END IF;
END $$;

-- ============================================================================
-- 4. Indexes
-- ============================================================================
-- All introspected verbatim from prod via pg_indexes. Including PK/UNIQUE
-- indexes is redundant on tables that already have those constraints, but
-- harmless (CREATE INDEX IF NOT EXISTS skips them). Excluded: pkey indexes
-- which Postgres creates automatically from the PRIMARY KEY clause.

CREATE INDEX IF NOT EXISTS idx_users_email ON public.users (email);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON public.users (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_users_last_interaction ON public.users (last_interaction_at DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_users_streak_deadline ON public.users (streak_deadline);
CREATE INDEX IF NOT EXISTS idx_users_subscription_status ON public.users (subscription_status);

CREATE INDEX IF NOT EXISTS idx_relatives_user_id ON public.relatives (user_id);
CREATE INDEX IF NOT EXISTS idx_relatives_id_user ON public.relatives (id, user_id);
CREATE INDEX IF NOT EXISTS idx_relatives_user_archived ON public.relatives (user_id, is_archived);
CREATE INDEX IF NOT EXISTS idx_relatives_user_favorite ON public.relatives (user_id, is_favorite);
CREATE INDEX IF NOT EXISTS idx_relatives_user_priority ON public.relatives (user_id, priority, full_name);
CREATE INDEX IF NOT EXISTS idx_relatives_category ON public.relatives (user_id, relative_category);
CREATE INDEX IF NOT EXISTS idx_relatives_family_group ON public.relatives (family_group_id) WHERE (family_group_id IS NOT NULL);
CREATE INDEX IF NOT EXISTS idx_relatives_last_contact ON public.relatives (last_contact_date DESC);
CREATE INDEX IF NOT EXISTS idx_relatives_updated_at ON public.relatives (updated_at DESC);
CREATE UNIQUE INDEX IF NOT EXISTS idx_relatives_self_per_user_group ON public.relatives (user_id, family_group_id) WHERE ((is_self = true) AND (family_group_id IS NOT NULL));

CREATE INDEX IF NOT EXISTS idx_interactions_user_id ON public.interactions (user_id);
CREATE INDEX IF NOT EXISTS idx_interactions_id_user ON public.interactions (id, user_id);
CREATE INDEX IF NOT EXISTS idx_interactions_relative_id ON public.interactions (relative_id);
CREATE INDEX IF NOT EXISTS idx_interactions_user_relative ON public.interactions (user_id, relative_id);
CREATE INDEX IF NOT EXISTS idx_interactions_user_date ON public.interactions (user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_interactions_relative_date ON public.interactions (relative_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_interactions_date ON public.interactions (date DESC);
CREATE INDEX IF NOT EXISTS idx_interactions_created_at ON public.interactions (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_interactions_type ON public.interactions (type);

CREATE INDEX IF NOT EXISTS idx_reminder_schedules_user_id ON public.reminder_schedules (user_id);
CREATE INDEX IF NOT EXISTS idx_reminder_schedules_active ON public.reminder_schedules (is_active);
CREATE INDEX IF NOT EXISTS idx_reminder_schedules_user_active ON public.reminder_schedules (user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_reminder_schedules_active_time ON public.reminder_schedules ("time", user_id) WHERE (is_active = true);

CREATE INDEX IF NOT EXISTS idx_notification_history_user_id ON public.notification_history (user_id);
CREATE INDEX IF NOT EXISTS idx_notification_history_user_read ON public.notification_history (user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notification_history_sent_at ON public.notification_history (sent_at DESC);
CREATE INDEX IF NOT EXISTS idx_notification_history_status ON public.notification_history (status);
CREATE INDEX IF NOT EXISTS idx_notification_history_type ON public.notification_history (notification_type);

CREATE INDEX IF NOT EXISTS idx_notification_tokens_user_id ON public.notification_tokens (user_id);
CREATE INDEX IF NOT EXISTS idx_notification_tokens_fcm_token ON public.notification_tokens (fcm_token);
CREATE INDEX IF NOT EXISTS idx_notification_tokens_active ON public.notification_tokens (is_active) WHERE (is_active = true);

CREATE INDEX IF NOT EXISTS idx_admin_announcements_scheduled ON public.admin_announcements (status, scheduled_for) WHERE (status = 'scheduled');

-- ============================================================================
-- 5. Row Level Security
-- ============================================================================
-- All RLS-enabled on prod. All policies introspected via pg_policies and
-- captured here verbatim. Drop-then-create pattern is idempotent.
--
-- Notable: the users / interactions / relatives / reminder_schedules
-- tables have multiple overlapping policies (some named "X" for {public}
-- and "X" for {authenticated}). This is duplication accumulated over many
-- migrations. Captured as-is per the rule "don't improve, capture what's
-- live." A future cleanup session can dedupe.

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.relatives ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reminder_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_announcements ENABLE ROW LEVEL SECURITY;

-- users — 12 policies (3 SELECT + 3 INSERT + 3 UPDATE + 3 DELETE).
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
CREATE POLICY "Users can view own profile" ON public.users FOR SELECT TO public USING (auth.uid() = id);
DROP POLICY IF EXISTS "Users can view their own profile" ON public.users;
CREATE POLICY "Users can view their own profile" ON public.users FOR SELECT TO authenticated USING (auth.uid() = id);
DROP POLICY IF EXISTS "users_can_view_own_profile" ON public.users;
CREATE POLICY "users_can_view_own_profile" ON public.users FOR SELECT TO authenticated USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
CREATE POLICY "Users can insert own profile" ON public.users FOR INSERT TO public WITH CHECK (auth.uid() = id);
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.users;
CREATE POLICY "Users can insert their own profile" ON public.users FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);
DROP POLICY IF EXISTS "allow_trigger_insert" ON public.users;
CREATE POLICY "allow_trigger_insert" ON public.users FOR INSERT TO public WITH CHECK (true);

DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE TO public USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;
CREATE POLICY "Users can update their own profile" ON public.users FOR UPDATE TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
DROP POLICY IF EXISTS "users_can_update_own_profile" ON public.users;
CREATE POLICY "users_can_update_own_profile" ON public.users FOR UPDATE TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can delete own profile" ON public.users;
CREATE POLICY "Users can delete own profile" ON public.users FOR DELETE TO public USING (auth.uid() = id);
DROP POLICY IF EXISTS "Users can delete their own profile" ON public.users;
CREATE POLICY "Users can delete their own profile" ON public.users FOR DELETE TO authenticated USING (auth.uid() = id);
DROP POLICY IF EXISTS "users_can_delete_own_profile" ON public.users;
CREATE POLICY "users_can_delete_own_profile" ON public.users FOR DELETE TO authenticated USING (auth.uid() = id);

-- relatives — 5 policies (1 ALL + 1 SELECT + 1 INSERT + 1 UPDATE + 1 DELETE).
DROP POLICY IF EXISTS "Users can access their own relatives" ON public.relatives;
CREATE POLICY "Users can access their own relatives" ON public.relatives FOR ALL TO public USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can view own and shared relatives" ON public.relatives;
CREATE POLICY "Users can view own and shared relatives" ON public.relatives FOR SELECT TO public
USING (
  ((family_group_id IS NULL) AND (user_id = auth.uid()))
  OR ((family_group_id IS NOT NULL) AND (family_group_id IN (SELECT auth_user_group_ids())))
);
DROP POLICY IF EXISTS "Users or group members can insert relatives" ON public.relatives;
CREATE POLICY "Users or group members can insert relatives" ON public.relatives FOR INSERT TO public
WITH CHECK (
  ((family_group_id IS NULL) AND (user_id = auth.uid()))
  OR ((family_group_id IS NOT NULL) AND (user_id = auth.uid()) AND (family_group_id IN (SELECT auth_user_group_ids())))
);
DROP POLICY IF EXISTS "Owner or adder or admin can update relatives" ON public.relatives;
CREATE POLICY "Owner or adder or admin can update relatives" ON public.relatives FOR UPDATE TO public
USING (
  ((family_group_id IS NULL) AND (user_id = auth.uid()))
  OR ((family_group_id IS NOT NULL) AND (family_group_id IN (SELECT auth_user_group_ids())) AND ((user_id = auth.uid()) OR (added_by = auth.uid()) OR (EXISTS (SELECT 1 FROM family_group_members WHERE family_group_members.group_id = relatives.family_group_id AND family_group_members.user_id = auth.uid() AND family_group_members.role = 'admin'))))
)
WITH CHECK (
  ((family_group_id IS NULL) AND (user_id = auth.uid()))
  OR ((family_group_id IS NOT NULL) AND (family_group_id IN (SELECT auth_user_group_ids())) AND ((user_id = auth.uid()) OR (added_by = auth.uid()) OR (EXISTS (SELECT 1 FROM family_group_members WHERE family_group_members.group_id = relatives.family_group_id AND family_group_members.user_id = auth.uid() AND family_group_members.role = 'admin'))))
);
DROP POLICY IF EXISTS "Owner or adder or admin can delete relatives" ON public.relatives;
CREATE POLICY "Owner or adder or admin can delete relatives" ON public.relatives FOR DELETE TO public
USING (
  (user_id = auth.uid())
  OR ((family_group_id IS NOT NULL) AND (added_by = auth.uid()))
  OR ((family_group_id IS NOT NULL) AND (family_group_id IN (SELECT auth_user_admin_group_ids())))
);

-- interactions — 5 policies.
DROP POLICY IF EXISTS "Users can access their own interactions" ON public.interactions;
CREATE POLICY "Users can access their own interactions" ON public.interactions FOR ALL TO public USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can view own and shared interactions" ON public.interactions;
CREATE POLICY "Users can view own and shared interactions" ON public.interactions FOR SELECT TO public
USING (
  (user_id = auth.uid())
  OR (relative_id IN (SELECT auth_user_group_relative_ids()))
);
DROP POLICY IF EXISTS "Users can insert own interactions" ON public.interactions;
CREATE POLICY "Users can insert own interactions" ON public.interactions FOR INSERT TO public WITH CHECK (user_id = auth.uid());
DROP POLICY IF EXISTS "Users can update own interactions" ON public.interactions;
CREATE POLICY "Users can update own interactions" ON public.interactions FOR UPDATE TO public USING (user_id = auth.uid());
DROP POLICY IF EXISTS "Users can delete own interactions" ON public.interactions;
CREATE POLICY "Users can delete own interactions" ON public.interactions FOR DELETE TO public USING (user_id = auth.uid());

-- reminder_schedules — 5 policies.
DROP POLICY IF EXISTS "Users can access their own reminder schedules" ON public.reminder_schedules;
CREATE POLICY "Users can access their own reminder schedules" ON public.reminder_schedules FOR ALL TO public USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can view own reminder schedules" ON public.reminder_schedules;
CREATE POLICY "Users can view own reminder schedules" ON public.reminder_schedules FOR SELECT TO public USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can insert own reminder schedules" ON public.reminder_schedules;
CREATE POLICY "Users can insert own reminder schedules" ON public.reminder_schedules FOR INSERT TO public WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update own reminder schedules" ON public.reminder_schedules;
CREATE POLICY "Users can update own reminder schedules" ON public.reminder_schedules FOR UPDATE TO public USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can delete own reminder schedules" ON public.reminder_schedules;
CREATE POLICY "Users can delete own reminder schedules" ON public.reminder_schedules FOR DELETE TO public USING (auth.uid() = user_id);

-- notification_history — 4 policies (2 SELECT + 1 UPDATE + 1 DELETE).
DROP POLICY IF EXISTS "Users can read own notifications" ON public.notification_history;
CREATE POLICY "Users can read own notifications" ON public.notification_history FOR SELECT TO public USING (user_id = auth.uid());
DROP POLICY IF EXISTS "Users can view own notification history" ON public.notification_history;
CREATE POLICY "Users can view own notification history" ON public.notification_history FOR SELECT TO public USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notification_history;
CREATE POLICY "Users can update own notifications" ON public.notification_history FOR UPDATE TO public USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
DROP POLICY IF EXISTS "Users can delete own notifications" ON public.notification_history;
CREATE POLICY "Users can delete own notifications" ON public.notification_history FOR DELETE TO public USING (user_id = auth.uid());

-- notification_tokens — 4 policies.
DROP POLICY IF EXISTS "Users can view own tokens" ON public.notification_tokens;
CREATE POLICY "Users can view own tokens" ON public.notification_tokens FOR SELECT TO public USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can insert own tokens" ON public.notification_tokens;
CREATE POLICY "Users can insert own tokens" ON public.notification_tokens FOR INSERT TO public WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update own tokens" ON public.notification_tokens;
CREATE POLICY "Users can update own tokens" ON public.notification_tokens FOR UPDATE TO public USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can delete own tokens" ON public.notification_tokens;
CREATE POLICY "Users can delete own tokens" ON public.notification_tokens FOR DELETE TO public USING (auth.uid() = user_id);

-- admin_announcements — 5 policies (Service role full access + admin SELECT/INSERT/UPDATE/DELETE).
DROP POLICY IF EXISTS "Service role full access" ON public.admin_announcements;
CREATE POLICY "Service role full access" ON public.admin_announcements FOR ALL TO public USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Admins can view announcements" ON public.admin_announcements;
CREATE POLICY "Admins can view announcements" ON public.admin_announcements FOR SELECT TO public USING (is_admin());
DROP POLICY IF EXISTS "Admins can create announcements" ON public.admin_announcements;
CREATE POLICY "Admins can create announcements" ON public.admin_announcements FOR INSERT TO public WITH CHECK (is_admin());
DROP POLICY IF EXISTS "Admins can update announcements" ON public.admin_announcements;
CREATE POLICY "Admins can update announcements" ON public.admin_announcements FOR UPDATE TO public USING (is_admin());
DROP POLICY IF EXISTS "Admins can delete announcements" ON public.admin_announcements;
CREATE POLICY "Admins can delete announcements" ON public.admin_announcements FOR DELETE TO public USING (is_admin());

-- ============================================================================
-- 6. Self-verification — same pattern as 20260427000000 and 20260427200000
-- ============================================================================

DO $$
DECLARE
  v_count INTEGER;
  v_rls BOOLEAN;
BEGIN
  -- RLS enabled on all 7 tables.
  FOR v_rls IN
    SELECT relrowsecurity FROM pg_class
    WHERE oid IN (
      'public.users'::regclass,
      'public.relatives'::regclass,
      'public.interactions'::regclass,
      'public.reminder_schedules'::regclass,
      'public.notification_history'::regclass,
      'public.notification_tokens'::regclass,
      'public.admin_announcements'::regclass
    )
  LOOP
    IF NOT v_rls THEN
      RAISE EXCEPTION 'RLS not enabled on one of the captured core tables';
    END IF;
  END LOOP;

  -- Policy counts (matching what's on prod as of 2026-04-26).
  SELECT COUNT(*) INTO v_count FROM pg_policies WHERE schemaname = 'public' AND tablename = 'users';
  IF v_count <> 12 THEN RAISE EXCEPTION 'users has % policies (expected 12)', v_count; END IF;

  SELECT COUNT(*) INTO v_count FROM pg_policies WHERE schemaname = 'public' AND tablename = 'relatives';
  IF v_count <> 5 THEN RAISE EXCEPTION 'relatives has % policies (expected 5)', v_count; END IF;

  SELECT COUNT(*) INTO v_count FROM pg_policies WHERE schemaname = 'public' AND tablename = 'interactions';
  IF v_count <> 5 THEN RAISE EXCEPTION 'interactions has % policies (expected 5)', v_count; END IF;

  SELECT COUNT(*) INTO v_count FROM pg_policies WHERE schemaname = 'public' AND tablename = 'reminder_schedules';
  IF v_count <> 5 THEN RAISE EXCEPTION 'reminder_schedules has % policies (expected 5)', v_count; END IF;

  SELECT COUNT(*) INTO v_count FROM pg_policies WHERE schemaname = 'public' AND tablename = 'notification_history';
  IF v_count <> 4 THEN RAISE EXCEPTION 'notification_history has % policies (expected 4)', v_count; END IF;

  SELECT COUNT(*) INTO v_count FROM pg_policies WHERE schemaname = 'public' AND tablename = 'notification_tokens';
  IF v_count <> 4 THEN RAISE EXCEPTION 'notification_tokens has % policies (expected 4)', v_count; END IF;

  SELECT COUNT(*) INTO v_count FROM pg_policies WHERE schemaname = 'public' AND tablename = 'admin_announcements';
  IF v_count <> 5 THEN RAISE EXCEPTION 'admin_announcements has % policies (expected 5)', v_count; END IF;

  -- Spot-check that the most important CHECK constraints exist.
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'users_subscription_status_check' AND conrelid = 'public.users'::regclass) THEN
    RAISE EXCEPTION 'users_subscription_status_check missing';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'interactions_type_check' AND conrelid = 'public.interactions'::regclass) THEN
    RAISE EXCEPTION 'interactions_type_check missing';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'reminder_schedules_frequency_check' AND conrelid = 'public.reminder_schedules'::regclass) THEN
    RAISE EXCEPTION 'reminder_schedules_frequency_check missing';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'notification_tokens_platform_check' AND conrelid = 'public.notification_tokens'::regclass) THEN
    RAISE EXCEPTION 'notification_tokens_platform_check missing';
  END IF;
END $$;
