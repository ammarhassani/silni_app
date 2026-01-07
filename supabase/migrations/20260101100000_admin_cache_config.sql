-- Remote Cache Configuration
-- Allows admin to control cache durations for all Flutter config services

CREATE TABLE admin_cache_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_key TEXT UNIQUE NOT NULL,
  cache_duration_seconds INTEGER NOT NULL DEFAULT 300,
  description TEXT,
  description_ar TEXT,
  min_duration_seconds INTEGER DEFAULT 30,
  max_duration_seconds INTEGER DEFAULT 1800,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create updated_at trigger
CREATE TRIGGER update_admin_cache_config_updated_at
  BEFORE UPDATE ON admin_cache_config
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Seed with current hardcoded values from Flutter services
INSERT INTO admin_cache_config (service_key, cache_duration_seconds, description, description_ar) VALUES
('feature_config', 300, 'Feature configuration and subscription tiers', 'إعدادات الميزات والاشتراكات'),
('ai_config', 300, 'AI identity, personality, modes, and parameters', 'إعدادات الذكاء الاصطناعي'),
('gamification_config', 300, 'Points, badges, levels, streaks, and challenges', 'إعدادات نظام النقاط والشارات'),
('notification_config', 600, 'Notification templates and time slots', 'قوالب الإشعارات وأوقاتها'),
('design_config', 600, 'Colors, themes, and animations', 'الألوان والثيمات والحركات'),
('content_config', 600, 'Hadith, quotes, MOTD, and banners', 'المحتوى: أحاديث، اقتباسات، بانرات'),
('app_routes_config', 600, 'App navigation routes and categories', 'مسارات التنقل في التطبيق');

-- RLS Policies
ALTER TABLE admin_cache_config ENABLE ROW LEVEL SECURITY;

-- Admins can manage cache config
CREATE POLICY "Admins can manage cache config" ON admin_cache_config
  FOR ALL USING (is_admin());

-- Authenticated users can read cache config (needed by Flutter app)
CREATE POLICY "Authenticated users can read cache config" ON admin_cache_config
  FOR SELECT USING (auth.role() = 'authenticated');

-- Index for fast lookups
CREATE INDEX idx_admin_cache_config_service_key ON admin_cache_config(service_key);
CREATE INDEX idx_admin_cache_config_active ON admin_cache_config(is_active) WHERE is_active = true;

COMMENT ON TABLE admin_cache_config IS 'Controls cache durations for Flutter config services';
