-- =====================================================
-- Silni App - Supabase Database Schema
-- =====================================================
-- This script creates all tables, indexes, RLS policies,
-- triggers, and seed data for the Silni application.
--
-- Run this in Supabase SQL Editor (both staging & production)
-- =====================================================

-- Enable UUID extension for generating UUIDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 1. TABLES
-- =====================================================

-- -----------------------------------------------------
-- 1.1 Users Table
-- -----------------------------------------------------
-- Stores user profile and gamification data
-- Linked to Supabase Auth via auth.uid()
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT NOT NULL,
  phone_number TEXT,
  profile_picture_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_login_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  email_verified BOOLEAN NOT NULL DEFAULT false,

  -- Subscription & Preferences
  subscription_status TEXT NOT NULL DEFAULT 'free' CHECK (subscription_status IN ('free', 'premium')),
  language TEXT NOT NULL DEFAULT 'ar' CHECK (language IN ('ar', 'en')),
  notifications_enabled BOOLEAN NOT NULL DEFAULT true,
  reminder_time TEXT NOT NULL DEFAULT '09:00',
  theme TEXT NOT NULL DEFAULT 'light' CHECK (theme IN ('light', 'dark')),

  -- Gamification
  total_interactions INTEGER NOT NULL DEFAULT 0,
  current_streak INTEGER NOT NULL DEFAULT 0,
  longest_streak INTEGER NOT NULL DEFAULT 0,
  last_interaction_at TIMESTAMPTZ, -- Timestamp of last interaction (for 24h streak logic)
  points INTEGER NOT NULL DEFAULT 0,
  level INTEGER NOT NULL DEFAULT 1,
  badges TEXT[] NOT NULL DEFAULT '{}',

  -- Account Management
  data_export_requested BOOLEAN NOT NULL DEFAULT false,
  account_deletion_requested BOOLEAN NOT NULL DEFAULT false,

  updated_at TIMESTAMPTZ DEFAULT now()
);

-- -----------------------------------------------------
-- 1.2 Relatives Table
-- -----------------------------------------------------
-- Stores family members/relatives information
CREATE TABLE IF NOT EXISTS relatives (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Basic Info
  full_name TEXT NOT NULL,
  relationship_type TEXT NOT NULL,
  gender TEXT,
  avatar_type TEXT,
  date_of_birth TIMESTAMPTZ,

  -- Contact Info
  phone_number TEXT,
  email TEXT,
  address TEXT,
  city TEXT,
  country TEXT,

  -- Media
  photo_url TEXT,

  -- Additional Info
  notes TEXT,
  tags TEXT[] NOT NULL DEFAULT '{}',
  priority INTEGER NOT NULL DEFAULT 2 CHECK (priority IN (1, 2, 3)),
  islamic_importance TEXT,
  preferred_contact_method TEXT,
  best_time_to_contact TEXT,
  health_status TEXT,

  -- Interaction Tracking
  interaction_count INTEGER NOT NULL DEFAULT 0,
  last_contact_date TIMESTAMPTZ,

  -- Status
  is_archived BOOLEAN NOT NULL DEFAULT false,
  is_favorite BOOLEAN NOT NULL DEFAULT false,
  contact_id TEXT,

  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- -----------------------------------------------------
-- 1.3 Interactions Table
-- -----------------------------------------------------
-- Stores all interactions with relatives
CREATE TABLE IF NOT EXISTS interactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  relative_id UUID NOT NULL REFERENCES relatives(id) ON DELETE CASCADE,

  -- Interaction Details
  type TEXT NOT NULL CHECK (type IN ('call', 'visit', 'message', 'gift', 'event', 'other')),
  date TIMESTAMPTZ NOT NULL DEFAULT now(),
  duration INTEGER, -- in minutes
  location TEXT,
  notes TEXT,
  mood TEXT,

  -- Media
  photo_urls TEXT[] NOT NULL DEFAULT '{}',
  audio_note_url TEXT,

  -- Metadata
  tags TEXT[] NOT NULL DEFAULT '{}',
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  is_recurring BOOLEAN NOT NULL DEFAULT false,

  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- -----------------------------------------------------
-- 1.4 Reminder Schedules Table
-- -----------------------------------------------------
-- Stores reminder schedule configurations
CREATE TABLE IF NOT EXISTS reminder_schedules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Schedule Configuration
  frequency TEXT NOT NULL CHECK (frequency IN ('daily', 'weekly', 'monthly', 'friday', 'custom')),
  relative_ids UUID[] NOT NULL DEFAULT '{}',
  time TEXT NOT NULL, -- HH:mm format
  is_active BOOLEAN NOT NULL DEFAULT true,

  -- Custom Frequency Options
  custom_days INTEGER[], -- 1=Monday, 2=Tuesday, etc.
  day_of_month INTEGER CHECK (day_of_month >= 1 AND day_of_month <= 31),

  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- -----------------------------------------------------
-- 1.5 Hadith Table
-- -----------------------------------------------------
-- Stores Islamic hadith and quotes about Silat Rahim
CREATE TABLE IF NOT EXISTS hadith (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Content
  arabic_text TEXT NOT NULL,
  english_translation TEXT NOT NULL,
  source TEXT NOT NULL,
  reference TEXT NOT NULL,

  -- Classification
  topic TEXT NOT NULL DEFAULT 'silat_rahim',
  type TEXT NOT NULL DEFAULT 'hadith' CHECK (type IN ('hadith', 'quote')),
  narrator TEXT,
  scholar TEXT,

  -- Verification & Display
  is_authentic BOOLEAN NOT NULL DEFAULT true,
  display_order INTEGER NOT NULL,

  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- -----------------------------------------------------
-- 1.6 FCM Tokens Table
-- -----------------------------------------------------
-- Stores Firebase Cloud Messaging tokens for push notifications
CREATE TABLE IF NOT EXISTS fcm_tokens (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('web', 'android', 'ios')),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================
-- 2. INDEXES FOR PERFORMANCE
-- =====================================================

-- Users indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at DESC);

-- Relatives indexes
CREATE INDEX IF NOT EXISTS idx_relatives_user_id ON relatives(user_id);
CREATE INDEX IF NOT EXISTS idx_relatives_user_archived ON relatives(user_id, is_archived);
CREATE INDEX IF NOT EXISTS idx_relatives_user_favorite ON relatives(user_id, is_favorite);
CREATE INDEX IF NOT EXISTS idx_relatives_user_priority ON relatives(user_id, priority, full_name);
CREATE INDEX IF NOT EXISTS idx_relatives_last_contact ON relatives(last_contact_date DESC);

-- Interactions indexes
CREATE INDEX IF NOT EXISTS idx_interactions_user_id ON interactions(user_id);
CREATE INDEX IF NOT EXISTS idx_interactions_relative_id ON interactions(relative_id);
CREATE INDEX IF NOT EXISTS idx_interactions_user_date ON interactions(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_interactions_relative_date ON interactions(relative_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_interactions_date ON interactions(date DESC);
CREATE INDEX IF NOT EXISTS idx_interactions_type ON interactions(type);

-- Reminder Schedules indexes
CREATE INDEX IF NOT EXISTS idx_reminder_schedules_user_id ON reminder_schedules(user_id);
CREATE INDEX IF NOT EXISTS idx_reminder_schedules_active ON reminder_schedules(is_active);
CREATE INDEX IF NOT EXISTS idx_reminder_schedules_user_active ON reminder_schedules(user_id, is_active);

-- Hadith indexes
CREATE INDEX IF NOT EXISTS idx_hadith_topic ON hadith(topic);
CREATE INDEX IF NOT EXISTS idx_hadith_topic_order ON hadith(topic, display_order);
CREATE INDEX IF NOT EXISTS idx_hadith_authentic ON hadith(is_authentic);

-- FCM Tokens indexes
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_platform ON fcm_tokens(platform);

-- =====================================================
-- 3. ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE relatives ENABLE ROW LEVEL SECURITY;
ALTER TABLE interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE reminder_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE hadith ENABLE ROW LEVEL SECURITY;
ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------
-- 3.1 Users Policies
-- -----------------------------------------------------
-- Users can only read/update their own profile
CREATE POLICY "Users can view own profile"
  ON users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON users FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can delete own profile"
  ON users FOR DELETE
  USING (auth.uid() = id);

-- -----------------------------------------------------
-- 3.2 Relatives Policies
-- -----------------------------------------------------
-- Users can only CRUD their own relatives
CREATE POLICY "Users can view own relatives"
  ON relatives FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own relatives"
  ON relatives FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own relatives"
  ON relatives FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own relatives"
  ON relatives FOR DELETE
  USING (auth.uid() = user_id);

-- -----------------------------------------------------
-- 3.3 Interactions Policies
-- -----------------------------------------------------
-- Users can only CRUD their own interactions
CREATE POLICY "Users can view own interactions"
  ON interactions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own interactions"
  ON interactions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own interactions"
  ON interactions FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own interactions"
  ON interactions FOR DELETE
  USING (auth.uid() = user_id);

-- -----------------------------------------------------
-- 3.4 Reminder Schedules Policies
-- -----------------------------------------------------
-- Users can only CRUD their own reminder schedules
CREATE POLICY "Users can view own reminder schedules"
  ON reminder_schedules FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own reminder schedules"
  ON reminder_schedules FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own reminder schedules"
  ON reminder_schedules FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own reminder schedules"
  ON reminder_schedules FOR DELETE
  USING (auth.uid() = user_id);

-- -----------------------------------------------------
-- 3.5 Hadith Policies
-- -----------------------------------------------------
-- Hadith is read-only for all authenticated users
CREATE POLICY "Authenticated users can view hadith"
  ON hadith FOR SELECT
  USING (auth.role() = 'authenticated');

-- Admins can manage hadith (service_role only)
-- No policy needed - use service_role key for admin operations

-- -----------------------------------------------------
-- 3.6 FCM Tokens Policies
-- -----------------------------------------------------
-- Users can only manage their own FCM tokens
CREATE POLICY "Users can view own FCM token"
  ON fcm_tokens FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own FCM token"
  ON fcm_tokens FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own FCM token"
  ON fcm_tokens FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own FCM token"
  ON fcm_tokens FOR DELETE
  USING (auth.uid() = user_id);

-- =====================================================
-- 4. TRIGGERS FOR AUTO-UPDATING TIMESTAMPS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to all tables with updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_relatives_updated_at BEFORE UPDATE ON relatives
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_interactions_updated_at BEFORE UPDATE ON interactions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reminder_schedules_updated_at BEFORE UPDATE ON reminder_schedules
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_hadith_updated_at BEFORE UPDATE ON hadith
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_fcm_tokens_updated_at BEFORE UPDATE ON fcm_tokens
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 5. RPC FUNCTIONS FOR COMPLEX OPERATIONS
-- =====================================================

-- -----------------------------------------------------
-- 5.1 Delete User Account (Cascading Delete)
-- -----------------------------------------------------
-- This function deletes a user and all their data
-- Called from the app when user requests account deletion
CREATE OR REPLACE FUNCTION delete_user_account()
RETURNS void AS $$
BEGIN
  -- All related data is automatically deleted via ON DELETE CASCADE
  -- This includes: relatives, interactions, reminder_schedules, fcm_tokens

  -- Delete the user record (triggers cascading deletes)
  DELETE FROM users WHERE id = auth.uid();

  -- Note: Supabase Auth user must be deleted separately via auth.admin.deleteUser()
  -- or by calling auth.signOut() then using the Admin API
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- -----------------------------------------------------
-- 5.2 Record Interaction and Update Relative
-- -----------------------------------------------------
-- This function is called when creating an interaction
-- It automatically updates the relative's interaction count and last contact date
CREATE OR REPLACE FUNCTION record_interaction_and_update_relative(
  p_relative_id UUID,
  p_user_id UUID
)
RETURNS void AS $$
BEGIN
  -- Update relative's interaction count and last contact date
  UPDATE relatives
  SET
    interaction_count = interaction_count + 1,
    last_contact_date = now(),
    updated_at = now()
  WHERE id = p_relative_id AND user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- -----------------------------------------------------
-- 5.3 Get User Statistics
-- -----------------------------------------------------
-- Returns aggregated statistics for a user
CREATE OR REPLACE FUNCTION get_user_statistics(p_user_id UUID)
RETURNS TABLE(
  total_calls BIGINT,
  total_visits BIGINT,
  total_messages BIGINT,
  total_gifts BIGINT,
  total_events BIGINT,
  interactions_this_week BIGINT,
  interactions_this_month BIGINT,
  total_relatives BIGINT,
  favorite_relatives BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    -- Count by interaction type
    COUNT(*) FILTER (WHERE i.type = 'call') AS total_calls,
    COUNT(*) FILTER (WHERE i.type = 'visit') AS total_visits,
    COUNT(*) FILTER (WHERE i.type = 'message') AS total_messages,
    COUNT(*) FILTER (WHERE i.type = 'gift') AS total_gifts,
    COUNT(*) FILTER (WHERE i.type = 'event') AS total_events,

    -- Time-based counts
    COUNT(*) FILTER (WHERE i.date >= now() - interval '7 days') AS interactions_this_week,
    COUNT(*) FILTER (WHERE i.date >= now() - interval '30 days') AS interactions_this_month,

    -- Relatives counts (using DISTINCT to avoid subquery)
    (SELECT COUNT(DISTINCT id) FROM relatives WHERE user_id = p_user_id AND is_archived = false)::BIGINT AS total_relatives,
    (SELECT COUNT(DISTINCT id) FROM relatives WHERE user_id = p_user_id AND is_favorite = true AND is_archived = false)::BIGINT AS favorite_relatives
  FROM interactions i
  WHERE i.user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 6. SEED DATA - HADITH
-- =====================================================
-- Insert default hadith about Silat Rahim
INSERT INTO hadith (arabic_text, english_translation, source, reference, topic, type, is_authentic, display_order)
VALUES
  (
    'من سره أن يبسط له في رزقه، وأن ينسأ له في أثره، فليصل رحمه',
    'Whoever would like his provision to be increased and his life to be extended, should uphold the ties of kinship',
    'Sahih Al-Bukhari',
    'Hadith 5986',
    'silat_rahim',
    'hadith',
    true,
    1
  ),
  (
    'الرحم معلقة بالعرش تقول: من وصلني وصله الله، ومن قطعني قطعه الله',
    'The womb (kinship) is suspended from the Throne, saying: "Whoever upholds me, Allah will uphold him, and whoever severs me, Allah will sever him"',
    'Sahih Al-Bukhari',
    'Hadith 5988',
    'silat_rahim',
    'hadith',
    true,
    2
  ),
  (
    'ليس الواصل بالمكافئ، ولكن الواصل الذي إذا قطعت رحمه وصلها',
    'The one who maintains ties of kinship is not the one who reciprocates. Rather, it is the one who, when his relatives cut him off, maintains ties with them',
    'Sahih Al-Bukhari',
    'Hadith 5991',
    'silat_rahim',
    'hadith',
    true,
    3
  ),
  (
    'من كان يؤمن بالله واليوم الآخر فليصل رحمه',
    'Whoever believes in Allah and the Last Day should maintain ties of kinship',
    'Sahih Al-Bukhari',
    'Hadith 6138',
    'silat_rahim',
    'hadith',
    true,
    4
  ),
  (
    'صلة الرحم محبة في الأهل، مثراة في المال، منسأة في الأثر',
    'Maintaining family ties brings love among relatives, increases wealth, and extends one''s lifespan',
    'Musnad Ahmad',
    'Hadith 7563',
    'silat_rahim',
    'hadith',
    true,
    5
  ),
  (
    'تعلموا من أنسابكم ما تصلون به أرحامكم',
    'Learn about your lineage that which will help you maintain your family ties',
    'Sunan At-Tirmidhi',
    'Hadith 1979',
    'silat_rahim',
    'hadith',
    true,
    6
  ),
  (
    'إن أعجل الطاعة ثواباً صلة الرحم',
    'The quickest act of obedience to be rewarded is maintaining family ties',
    'Musnad Ahmad',
    'Hadith 16033',
    'silat_rahim',
    'hadith',
    true,
    7
  ),
  (
    'لا يدخل الجنة قاطع رحم',
    'The one who severs family ties will not enter Paradise',
    'Sahih Al-Bukhari',
    'Hadith 5984',
    'silat_rahim',
    'hadith',
    true,
    8
  )
ON CONFLICT DO NOTHING;

-- =====================================================
-- 7. COMPLETION MESSAGE
-- =====================================================
DO $$
BEGIN
  RAISE NOTICE '✅ Silni database schema created successfully!';
  RAISE NOTICE '📊 Tables created: users, relatives, interactions, reminder_schedules, hadith, fcm_tokens';
  RAISE NOTICE '🔒 Row Level Security policies enabled';
  RAISE NOTICE '📚 Hadith seed data inserted';
  RAISE NOTICE '⚡ Indexes and triggers configured';
  RAISE NOTICE '';
  RAISE NOTICE 'Next steps:';
  RAISE NOTICE '1. Verify tables in Supabase Dashboard → Table Editor';
  RAISE NOTICE '2. Test RLS policies in Supabase Dashboard → Authentication';
  RAISE NOTICE '3. Run this same script in your PRODUCTION database';
END $$;
