-- Remote Feature Flags
-- Migrates feature flags from local SharedPreferences to remote control

CREATE TABLE admin_feature_flags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  flag_key TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  name_ar TEXT NOT NULL,
  description TEXT,
  description_ar TEXT,

  -- Flag type and values
  flag_type TEXT NOT NULL DEFAULT 'boolean', -- 'boolean', 'string', 'number', 'json'
  default_value JSONB NOT NULL DEFAULT 'false',
  enabled_value JSONB NOT NULL DEFAULT 'true',

  -- Rollout configuration
  rollout_percentage INTEGER DEFAULT 100, -- 0-100, percentage of users to enable for
  target_tiers TEXT[] DEFAULT ARRAY['free', 'basic', 'pro', 'max'],
  target_platforms TEXT[] DEFAULT ARRAY['ios', 'android', 'web'],

  -- Categorization
  category TEXT DEFAULT 'feature', -- 'feature', 'ui', 'experiment', 'performance'

  -- Status
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),

  -- Constraints
  CONSTRAINT valid_rollout CHECK (rollout_percentage >= 0 AND rollout_percentage <= 100),
  CONSTRAINT valid_flag_type CHECK (flag_type IN ('boolean', 'string', 'number', 'json'))
);

-- Create updated_at trigger
CREATE TRIGGER update_admin_feature_flags_updated_at
  BEFORE UPDATE ON admin_feature_flags
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Seed with existing Flutter flags (from FeatureFlags class)
INSERT INTO admin_feature_flags (flag_key, name, name_ar, description_ar, flag_type, default_value, enabled_value, category) VALUES
-- UI Experiments
('premium_loading_indicators', 'Premium Loading', 'مؤشرات تحميل مميزة', 'مؤشرات تحميل متميزة بتصميم احترافي', 'boolean', 'true', 'true', 'ui'),
('glassmorphism_cards', 'Glass Cards', 'بطاقات زجاجية', 'تأثير الزجاج الشفاف على البطاقات', 'boolean', 'true', 'true', 'ui'),
('animated_transitions', 'Animations', 'الانتقالات المتحركة', 'تحريك الانتقالات بين الشاشات', 'boolean', 'true', 'true', 'ui'),
('haptic_feedback', 'Haptic', 'الاهتزاز التفاعلي', 'اهتزاز عند التفاعل مع العناصر', 'boolean', 'true', 'true', 'ui'),

-- Feature Rollouts
('ai_assistant_enabled', 'AI Assistant', 'المساعد الذكي', 'تفعيل مساعد واصل الذكي', 'boolean', 'true', 'true', 'feature'),
('family_tree_enabled', 'Family Tree', 'شجرة العائلة', 'عرض شجرة العائلة', 'boolean', 'true', 'true', 'feature'),
('gamification_enabled', 'Gamification', 'نظام النقاط', 'تفعيل نظام النقاط والشارات', 'boolean', 'true', 'true', 'feature'),
('smart_reminders_enabled', 'Smart Reminders', 'تذكيرات ذكية', 'تذكيرات مدعومة بالذكاء الاصطناعي', 'boolean', 'true', 'true', 'feature'),

-- A/B Test Variants
('onboarding_variant', 'Onboarding', 'شاشة الترحيب', 'نوع شاشة الترحيب للمستخدمين الجدد', 'string', '"control"', '"control"', 'experiment'),
('home_screen_layout', 'Home Layout', 'تصميم الرئيسية', 'تصميم الشاشة الرئيسية', 'string', '"default"', '"default"', 'experiment'),
('reminder_frequency_options', 'Reminder Options', 'خيارات التذكير', 'خيارات تكرار التذكيرات', 'string', '"standard"', '"standard"', 'experiment'),

-- Performance Tuning
('pagination_page_size', 'Page Size', 'حجم الصفحة', 'عدد العناصر في كل صفحة', 'number', '20', '20', 'performance'),
('cache_timeout_minutes', 'Cache Timeout', 'مدة التخزين', 'مدة تخزين البيانات بالدقائق', 'number', '5', '5', 'performance'),
('ai_preload_enabled', 'AI Preload', 'تحميل مسبق', 'تحميل بيانات الذكاء مسبقاً', 'boolean', 'true', 'true', 'performance');

-- RLS Policies
ALTER TABLE admin_feature_flags ENABLE ROW LEVEL SECURITY;

-- Admins can manage feature flags
CREATE POLICY "Admins can manage feature flags" ON admin_feature_flags
  FOR ALL USING (is_admin());

-- Authenticated users can read flags
CREATE POLICY "Authenticated users can read flags" ON admin_feature_flags
  FOR SELECT USING (auth.role() = 'authenticated');

-- Indexes
CREATE INDEX idx_admin_feature_flags_key ON admin_feature_flags(flag_key);
CREATE INDEX idx_admin_feature_flags_active ON admin_feature_flags(is_active) WHERE is_active = true;
CREATE INDEX idx_admin_feature_flags_category ON admin_feature_flags(category);

-- Function to evaluate a flag for a specific user
CREATE OR REPLACE FUNCTION evaluate_feature_flag(
  p_flag_key TEXT,
  p_user_id UUID DEFAULT NULL,
  p_tier TEXT DEFAULT 'free',
  p_platform TEXT DEFAULT 'ios'
)
RETURNS JSONB AS $$
DECLARE
  v_flag RECORD;
  v_hash INTEGER;
BEGIN
  -- Get the flag
  SELECT * INTO v_flag
  FROM admin_feature_flags
  WHERE flag_key = p_flag_key
    AND is_active = true;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  -- Check tier targeting
  IF NOT (p_tier = ANY(v_flag.target_tiers)) THEN
    RETURN v_flag.default_value;
  END IF;

  -- Check platform targeting
  IF NOT (p_platform = ANY(v_flag.target_platforms)) THEN
    RETURN v_flag.default_value;
  END IF;

  -- Check rollout percentage
  IF v_flag.rollout_percentage < 100 THEN
    -- Use user ID hash for consistent assignment
    IF p_user_id IS NOT NULL THEN
      v_hash := abs(hashtext(p_user_id::TEXT)) % 100;
    ELSE
      v_hash := floor(random() * 100);
    END IF;

    IF v_hash >= v_flag.rollout_percentage THEN
      RETURN v_flag.default_value;
    END IF;
  END IF;

  RETURN v_flag.enabled_value;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON TABLE admin_feature_flags IS 'Remote feature flags with rollout and targeting support';
COMMENT ON FUNCTION evaluate_feature_flag IS 'Evaluates a feature flag for a user with tier/platform targeting';
