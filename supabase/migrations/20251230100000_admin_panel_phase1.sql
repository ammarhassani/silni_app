-- =====================================================
-- Silni Admin Panel - Phase 1 Database Schema
-- Created: 2025-12-30
-- =====================================================

-- =====================================================
-- 1. CONTENT MANAGEMENT TABLES
-- =====================================================

-- Hadith Collection
CREATE TABLE IF NOT EXISTS admin_hadith (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  hadith_text TEXT NOT NULL,
  source TEXT NOT NULL,
  narrator TEXT,
  grade TEXT CHECK (grade IN ('صحيح', 'حسن', 'ضعيف', 'موضوع')),
  category TEXT DEFAULT 'general',
  tags TEXT[] DEFAULT '{}',
  is_active BOOLEAN DEFAULT true,
  display_priority INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Daily Quotes
CREATE TABLE IF NOT EXISTS admin_quotes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quote_text TEXT NOT NULL,
  author TEXT,
  source TEXT,
  category TEXT DEFAULT 'general',
  tags TEXT[] DEFAULT '{}',
  is_active BOOLEAN DEFAULT true,
  display_priority INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Message of the Day
CREATE TABLE IF NOT EXISTS admin_motd (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT CHECK (type IN ('tip', 'motivation', 'reminder', 'announcement', 'celebration')),
  icon TEXT DEFAULT 'lightbulb',
  background_gradient JSONB DEFAULT '{"start": "#008080", "end": "#D4AF37"}',
  action_text TEXT,
  action_route TEXT,
  start_date DATE,
  end_date DATE,
  is_active BOOLEAN DEFAULT true,
  display_priority INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Promotional Banners
CREATE TABLE IF NOT EXISTS admin_banners (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  background_gradient JSONB,
  action_type TEXT CHECK (action_type IN ('route', 'url', 'action', 'none')),
  action_value TEXT,
  position TEXT CHECK (position IN ('home_top', 'home_bottom', 'profile', 'reminders')),
  target_audience TEXT CHECK (target_audience IN ('all', 'free', 'max', 'new_users')),
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  display_priority INTEGER DEFAULT 0,
  impressions INTEGER DEFAULT 0,
  clicks INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 2. GAMIFICATION TABLES
-- =====================================================

-- Points Configuration
CREATE TABLE IF NOT EXISTS admin_points_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  interaction_type TEXT NOT NULL UNIQUE,
  display_name_ar TEXT NOT NULL,
  display_name_en TEXT,
  base_points INTEGER NOT NULL DEFAULT 10,
  notes_bonus INTEGER DEFAULT 5,
  photo_bonus INTEGER DEFAULT 5,
  rating_bonus INTEGER DEFAULT 3,
  first_of_day_multiplier DECIMAL DEFAULT 1.5,
  daily_cap INTEGER DEFAULT 200,
  icon TEXT DEFAULT 'star',
  color_hex TEXT DEFAULT '#D4AF37',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default points configuration
INSERT INTO admin_points_config (interaction_type, display_name_ar, display_name_en, base_points, icon) VALUES
  ('call', 'مكالمة', 'Call', 10, 'phone'),
  ('visit', 'زيارة', 'Visit', 20, 'home'),
  ('message', 'رسالة', 'Message', 5, 'message-circle'),
  ('gift', 'هدية', 'Gift', 15, 'gift'),
  ('event', 'مناسبة', 'Event', 25, 'calendar'),
  ('other', 'أخرى', 'Other', 5, 'more-horizontal')
ON CONFLICT (interaction_type) DO NOTHING;

-- Badges Configuration
CREATE TABLE IF NOT EXISTS admin_badges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  badge_key TEXT NOT NULL UNIQUE,
  display_name_ar TEXT NOT NULL,
  display_name_en TEXT,
  description_ar TEXT NOT NULL,
  description_en TEXT,
  emoji TEXT NOT NULL,
  category TEXT CHECK (category IN ('streak', 'volume', 'variety', 'special', 'milestone')),
  threshold_type TEXT CHECK (threshold_type IN ('streak_days', 'total_interactions', 'unique_relatives', 'specific_action', 'custom')),
  threshold_value INTEGER NOT NULL,
  xp_reward INTEGER DEFAULT 100,
  is_secret BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default badges
INSERT INTO admin_badges (badge_key, display_name_ar, display_name_en, description_ar, emoji, category, threshold_type, threshold_value, xp_reward, sort_order) VALUES
  ('streak_7', 'أسبوع التواصل', 'Week Streak', 'حافظ على التواصل لمدة 7 أيام متتالية', '🔥', 'streak', 'streak_days', 7, 100, 1),
  ('streak_30', 'شهر التواصل', 'Month Streak', 'حافظ على التواصل لمدة 30 يوم متتالي', '💪', 'streak', 'streak_days', 30, 500, 2),
  ('streak_100', 'قرن التواصل', 'Century Streak', 'حافظ على التواصل لمدة 100 يوم متتالي', '👑', 'streak', 'streak_days', 100, 2000, 3),
  ('streak_365', 'سنة التواصل', 'Year Streak', 'حافظ على التواصل لمدة سنة كاملة', '🏆', 'streak', 'streak_days', 365, 10000, 4),
  ('interactions_10', 'بداية الطريق', 'Getting Started', 'أكمل 10 تفاعلات', '🌱', 'volume', 'total_interactions', 10, 50, 10),
  ('interactions_50', 'واصل متمكن', 'Skilled Connector', 'أكمل 50 تفاعل', '🌿', 'volume', 'total_interactions', 50, 200, 11),
  ('interactions_100', 'واصل محترف', 'Professional Connector', 'أكمل 100 تفاعل', '🌳', 'volume', 'total_interactions', 100, 500, 12),
  ('interactions_500', 'واصل خبير', 'Expert Connector', 'أكمل 500 تفاعل', '🏅', 'volume', 'total_interactions', 500, 2000, 13),
  ('interactions_1000', 'واصل أسطوري', 'Legendary Connector', 'أكمل 1000 تفاعل', '🎖️', 'volume', 'total_interactions', 1000, 5000, 14)
ON CONFLICT (badge_key) DO NOTHING;

-- Levels Configuration
CREATE TABLE IF NOT EXISTS admin_levels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  level INTEGER NOT NULL UNIQUE,
  title_ar TEXT NOT NULL,
  title_en TEXT,
  xp_required INTEGER NOT NULL,
  xp_to_next INTEGER,
  icon TEXT,
  color_hex TEXT,
  perks JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default levels
INSERT INTO admin_levels (level, title_ar, title_en, xp_required, xp_to_next) VALUES
  (1, 'مبتدئ', 'Beginner', 0, 100),
  (2, 'متعلم', 'Learner', 100, 150),
  (3, 'متقدم', 'Advanced', 250, 250),
  (4, 'ماهر', 'Skilled', 500, 500),
  (5, 'محترف', 'Professional', 1000, 1000),
  (6, 'خبير', 'Expert', 2000, 1500),
  (7, 'أستاذ', 'Master', 3500, 2000),
  (8, 'عبقري', 'Genius', 5500, 2500),
  (9, 'أسطورة', 'Legend', 8000, 4000),
  (10, 'واصل', 'Wasel', 12000, NULL)
ON CONFLICT (level) DO NOTHING;

-- Challenges Configuration
CREATE TABLE IF NOT EXISTS admin_challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_key TEXT NOT NULL UNIQUE,
  title_ar TEXT NOT NULL,
  title_en TEXT,
  description_ar TEXT NOT NULL,
  description_en TEXT,
  type TEXT CHECK (type IN ('daily', 'weekly', 'monthly', 'special', 'seasonal')),
  requirement_type TEXT CHECK (requirement_type IN ('interaction_count', 'unique_relatives', 'specific_type', 'streak', 'custom')),
  requirement_value INTEGER NOT NULL,
  requirement_metadata JSONB DEFAULT '{}',
  xp_reward INTEGER NOT NULL DEFAULT 50,
  points_reward INTEGER DEFAULT 0,
  badge_reward TEXT,
  icon TEXT DEFAULT 'target',
  color_hex TEXT DEFAULT '#008080',
  start_date DATE,
  end_date DATE,
  is_active BOOLEAN DEFAULT true,
  is_recurring BOOLEAN DEFAULT false,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Streak Configuration
CREATE TABLE IF NOT EXISTS admin_streak_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  config_key TEXT NOT NULL UNIQUE DEFAULT 'default',
  deadline_hours INTEGER NOT NULL DEFAULT 26,
  endangered_threshold_hours INTEGER NOT NULL DEFAULT 4,
  critical_threshold_minutes INTEGER NOT NULL DEFAULT 60,
  grace_period_hours INTEGER DEFAULT 2,
  freeze_award_milestones INTEGER[] DEFAULT '{7,30,100}',
  max_freezes INTEGER DEFAULT 3,
  freeze_cost_points INTEGER DEFAULT 0,
  streak_restore_enabled BOOLEAN DEFAULT false,
  streak_restore_cost_points INTEGER DEFAULT 500,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default streak config
INSERT INTO admin_streak_config (config_key) VALUES ('default')
ON CONFLICT (config_key) DO NOTHING;

-- =====================================================
-- 3. NOTIFICATION TABLES
-- =====================================================

-- Notification Templates
CREATE TABLE IF NOT EXISTS admin_notification_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_key TEXT NOT NULL UNIQUE,
  title_ar TEXT NOT NULL,
  title_en TEXT,
  body_ar TEXT NOT NULL,
  body_en TEXT,
  category TEXT CHECK (category IN ('reminder', 'streak', 'badge', 'level', 'challenge', 'system', 'promotional')),
  variables JSONB DEFAULT '[]',
  icon TEXT,
  sound TEXT DEFAULT 'default',
  channel_id TEXT DEFAULT 'default',
  priority TEXT CHECK (priority IN ('min', 'low', 'default', 'high', 'max')) DEFAULT 'default',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default notification templates
INSERT INTO admin_notification_templates (template_key, title_ar, body_ar, category, variables) VALUES
  ('reminder_due', 'حان وقت التواصل! ⏰', 'حان موعد التواصل مع {{relative_name}}', 'reminder', '["relative_name"]'),
  ('streak_endangered', 'سلسلتك في خطر! 🔥', 'تبقى {{hours}} ساعات للحفاظ على سلسلة {{streak_days}} يوم', 'streak', '["hours", "streak_days"]'),
  ('streak_broken', 'انتهت السلسلة 💔', 'للأسف انتهت سلسلتك. ابدأ من جديد!', 'streak', '[]'),
  ('badge_earned', 'وسام جديد! 🎉', 'مبروك! حصلت على وسام {{badge_name}}', 'badge', '["badge_name"]'),
  ('level_up', 'ارتقيت مستوى! 🚀', 'مبروك! وصلت للمستوى {{level}} - {{level_title}}', 'level', '["level", "level_title"]'),
  ('challenge_complete', 'تحدي مكتمل! 🏆', 'أنجزت تحدي {{challenge_name}}! +{{xp}} نقطة خبرة', 'challenge', '["challenge_name", "xp"]')
ON CONFLICT (template_key) DO NOTHING;

-- Reminder Time Slots
CREATE TABLE IF NOT EXISTS admin_reminder_time_slots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slot_key TEXT NOT NULL UNIQUE,
  display_name_ar TEXT NOT NULL,
  display_name_en TEXT,
  start_hour INTEGER NOT NULL CHECK (start_hour >= 0 AND start_hour < 24),
  end_hour INTEGER NOT NULL CHECK (end_hour >= 0 AND end_hour <= 24),
  icon TEXT,
  is_default BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default time slots
INSERT INTO admin_reminder_time_slots (slot_key, display_name_ar, display_name_en, start_hour, end_hour, icon, is_default, sort_order) VALUES
  ('morning', 'الصباح', 'Morning', 6, 12, 'sunrise', false, 1),
  ('afternoon', 'الظهيرة', 'Afternoon', 12, 17, 'sun', true, 2),
  ('evening', 'المساء', 'Evening', 17, 21, 'sunset', false, 3),
  ('night', 'الليل', 'Night', 21, 24, 'moon', false, 4)
ON CONFLICT (slot_key) DO NOTHING;

-- =====================================================
-- 4. DESIGN SYSTEM TABLES
-- =====================================================

-- Color Palette Configuration
CREATE TABLE IF NOT EXISTS admin_colors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  color_key TEXT NOT NULL UNIQUE,
  display_name_ar TEXT NOT NULL,
  display_name_en TEXT,
  hex_value TEXT NOT NULL,
  rgb_value JSONB,
  usage_context TEXT,
  is_primary BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert Silni brand colors
INSERT INTO admin_colors (color_key, display_name_ar, display_name_en, hex_value, usage_context, is_primary, sort_order) VALUES
  ('gold', 'الذهبي', 'Gold', '#D4AF37', 'accent', true, 1),
  ('gold_light', 'الذهبي الفاتح', 'Gold Light', '#E6C65C', 'accent_light', false, 2),
  ('gold_dark', 'الذهبي الداكن', 'Gold Dark', '#B8962E', 'accent_dark', false, 3),
  ('teal', 'الفيروزي', 'Teal', '#008080', 'primary', true, 4),
  ('teal_light', 'الفيروزي الفاتح', 'Teal Light', '#20B2AA', 'primary_light', false, 5),
  ('teal_dark', 'الفيروزي الداكن', 'Teal Dark', '#006666', 'primary_dark', false, 6),
  ('emerald', 'الزمردي', 'Emerald', '#50C878', 'success', false, 7),
  ('cream', 'الكريمي', 'Cream', '#FFF8DC', 'background', false, 8)
ON CONFLICT (color_key) DO NOTHING;

-- Theme Configurations
CREATE TABLE IF NOT EXISTS admin_themes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  theme_key TEXT NOT NULL UNIQUE,
  display_name_ar TEXT NOT NULL,
  display_name_en TEXT,
  is_dark BOOLEAN DEFAULT false,
  colors JSONB NOT NULL,
  gradients JSONB DEFAULT '{}',
  shadows JSONB DEFAULT '{}',
  is_premium BOOLEAN DEFAULT false,
  is_default BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  preview_image_url TEXT,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Animation Configuration
CREATE TABLE IF NOT EXISTS admin_animations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  animation_key TEXT NOT NULL UNIQUE,
  display_name_ar TEXT NOT NULL,
  display_name_en TEXT,
  duration_ms INTEGER NOT NULL,
  curve TEXT DEFAULT 'easeOut',
  description TEXT,
  usage_context TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default animation presets
INSERT INTO admin_animations (animation_key, display_name_ar, display_name_en, duration_ms, curve, usage_context) VALUES
  ('instant', 'فوري', 'Instant', 100, 'linear', 'Micro-interactions'),
  ('fast', 'سريع', 'Fast', 200, 'easeOut', 'Button feedback'),
  ('normal', 'عادي', 'Normal', 300, 'easeInOut', 'Standard transitions'),
  ('modal', 'نافذة', 'Modal', 400, 'easeOutBack', 'Dialog open/close'),
  ('slow', 'بطيء', 'Slow', 500, 'easeInOut', 'Page transitions'),
  ('dramatic', 'درامي', 'Dramatic', 800, 'easeInOutQuart', 'Celebrations'),
  ('celebration', 'احتفال', 'Celebration', 1200, 'easeOut', 'Badge/Level up'),
  ('loop', 'متكرر', 'Loop', 2000, 'linear', 'Loading indicators')
ON CONFLICT (animation_key) DO NOTHING;

-- Pattern Animation Effects
CREATE TABLE IF NOT EXISTS admin_pattern_animations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  effect_key TEXT NOT NULL UNIQUE,
  display_name_ar TEXT NOT NULL,
  display_name_en TEXT,
  description_ar TEXT,
  default_enabled BOOLEAN NOT NULL DEFAULT true,
  battery_impact TEXT CHECK (battery_impact IN ('low', 'medium', 'high')) DEFAULT 'low',
  default_intensity DECIMAL DEFAULT 0.5,
  settings_key TEXT NOT NULL,
  is_premium BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default pattern effects
INSERT INTO admin_pattern_animations (effect_key, display_name_ar, display_name_en, default_enabled, battery_impact, settings_key, sort_order) VALUES
  ('rotation', 'الدوران', 'Rotation', true, 'low', 'pattern_rotation_enabled', 1),
  ('pulse', 'النبض', 'Pulse', true, 'low', 'pattern_pulse_enabled', 2),
  ('parallax', 'التأثير الثلاثي', 'Parallax', true, 'low', 'pattern_parallax_enabled', 3),
  ('shimmer', 'اللمعان', 'Shimmer', false, 'medium', 'pattern_shimmer_enabled', 4),
  ('touch_ripple', 'تموج اللمس', 'Touch Ripple', true, 'low', 'pattern_touch_ripple_enabled', 5),
  ('gyroscope', 'الجيروسكوب', 'Gyroscope', false, 'medium', 'pattern_gyroscope_enabled', 6),
  ('follow_touch', 'متابعة اللمس', 'Follow Touch', true, 'low', 'pattern_follow_touch_enabled', 7)
ON CONFLICT (effect_key) DO NOTHING;

-- =====================================================
-- 5. HELPER FUNCTIONS
-- =====================================================

-- Updated at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at triggers to all admin tables
DO $$
DECLARE
  t text;
BEGIN
  FOR t IN
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
    AND table_name LIKE 'admin_%'
  LOOP
    EXECUTE format('
      DROP TRIGGER IF EXISTS update_%s_updated_at ON %s;
      CREATE TRIGGER update_%s_updated_at
        BEFORE UPDATE ON %s
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column();
    ', t, t, t, t);
  END LOOP;
END;
$$;

-- =====================================================
-- 6. ROW LEVEL SECURITY
-- =====================================================

-- Enable RLS on all admin tables
ALTER TABLE admin_hadith ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_motd ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_banners ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_points_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_levels ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_streak_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_notification_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_reminder_time_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_colors ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_themes ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_animations ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_pattern_animations ENABLE ROW LEVEL SECURITY;

-- Create admin role check function
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
    AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RLS Policies: Admins can do everything, users can only read active items

-- Hadith policies
CREATE POLICY "Admins can manage hadith" ON admin_hadith FOR ALL USING (is_admin());
CREATE POLICY "Users can read active hadith" ON admin_hadith FOR SELECT USING (is_active = true);

-- Quotes policies
CREATE POLICY "Admins can manage quotes" ON admin_quotes FOR ALL USING (is_admin());
CREATE POLICY "Users can read active quotes" ON admin_quotes FOR SELECT USING (is_active = true);

-- MOTD policies
CREATE POLICY "Admins can manage motd" ON admin_motd FOR ALL USING (is_admin());
CREATE POLICY "Users can read active motd" ON admin_motd FOR SELECT
  USING (is_active = true AND (start_date IS NULL OR start_date <= CURRENT_DATE) AND (end_date IS NULL OR end_date >= CURRENT_DATE));

-- Banners policies
CREATE POLICY "Admins can manage banners" ON admin_banners FOR ALL USING (is_admin());
CREATE POLICY "Users can read active banners" ON admin_banners FOR SELECT
  USING (is_active = true AND (start_date IS NULL OR start_date <= NOW()) AND (end_date IS NULL OR end_date >= NOW()));

-- Points config policies
CREATE POLICY "Admins can manage points" ON admin_points_config FOR ALL USING (is_admin());
CREATE POLICY "Users can read active points" ON admin_points_config FOR SELECT USING (is_active = true);

-- Badges policies
CREATE POLICY "Admins can manage badges" ON admin_badges FOR ALL USING (is_admin());
CREATE POLICY "Users can read active badges" ON admin_badges FOR SELECT USING (is_active = true);

-- Levels policies
CREATE POLICY "Admins can manage levels" ON admin_levels FOR ALL USING (is_admin());
CREATE POLICY "Users can read all levels" ON admin_levels FOR SELECT USING (true);

-- Challenges policies
CREATE POLICY "Admins can manage challenges" ON admin_challenges FOR ALL USING (is_admin());
CREATE POLICY "Users can read active challenges" ON admin_challenges FOR SELECT USING (is_active = true);

-- Streak config policies
CREATE POLICY "Admins can manage streak config" ON admin_streak_config FOR ALL USING (is_admin());
CREATE POLICY "Users can read active streak config" ON admin_streak_config FOR SELECT USING (is_active = true);

-- Notification templates policies
CREATE POLICY "Admins can manage notification templates" ON admin_notification_templates FOR ALL USING (is_admin());
CREATE POLICY "Users can read active notification templates" ON admin_notification_templates FOR SELECT USING (is_active = true);

-- Reminder time slots policies
CREATE POLICY "Admins can manage reminder time slots" ON admin_reminder_time_slots FOR ALL USING (is_admin());
CREATE POLICY "Users can read active reminder time slots" ON admin_reminder_time_slots FOR SELECT USING (is_active = true);

-- Colors policies
CREATE POLICY "Admins can manage colors" ON admin_colors FOR ALL USING (is_admin());
CREATE POLICY "Users can read active colors" ON admin_colors FOR SELECT USING (is_active = true);

-- Themes policies
CREATE POLICY "Admins can manage themes" ON admin_themes FOR ALL USING (is_admin());
CREATE POLICY "Users can read active themes" ON admin_themes FOR SELECT USING (is_active = true);

-- Animations policies
CREATE POLICY "Admins can manage animations" ON admin_animations FOR ALL USING (is_admin());
CREATE POLICY "Users can read active animations" ON admin_animations FOR SELECT USING (is_active = true);

-- Pattern animations policies
CREATE POLICY "Admins can manage pattern animations" ON admin_pattern_animations FOR ALL USING (is_admin());
CREATE POLICY "Users can read active pattern animations" ON admin_pattern_animations FOR SELECT USING (is_active = true);

-- =====================================================
-- 7. INDEXES FOR PERFORMANCE
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_admin_hadith_active ON admin_hadith(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_admin_hadith_category ON admin_hadith(category);
CREATE INDEX IF NOT EXISTS idx_admin_quotes_active ON admin_quotes(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_admin_motd_active ON admin_motd(is_active, start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_admin_banners_active ON admin_banners(is_active, start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_admin_badges_category ON admin_badges(category);
CREATE INDEX IF NOT EXISTS idx_admin_challenges_type ON admin_challenges(type);
CREATE INDEX IF NOT EXISTS idx_admin_notification_templates_category ON admin_notification_templates(category);
