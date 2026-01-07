-- In-App Messaging System
-- Allows admin to create targeted messages shown within the app

CREATE TABLE admin_in_app_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  name_ar TEXT,

  -- Message type determines UI component
  message_type TEXT NOT NULL DEFAULT 'banner',

  -- Content
  title_ar TEXT NOT NULL,
  title_en TEXT,
  body_ar TEXT,
  body_en TEXT,

  -- Call to action
  cta_text_ar TEXT,
  cta_text_en TEXT,
  cta_action TEXT, -- Deep link or action (e.g., '/upgrade', 'open_url:https://...')

  -- Visual styling
  image_url TEXT,
  icon_name TEXT,
  background_color TEXT DEFAULT '#FFFFFF',
  text_color TEXT DEFAULT '#1F2937',
  accent_color TEXT,

  -- Trigger configuration
  trigger_type TEXT NOT NULL DEFAULT 'screen_view',
  trigger_value TEXT, -- Screen name, event name, or cron expression

  -- Display rules
  display_frequency TEXT NOT NULL DEFAULT 'once',
  max_impressions INTEGER, -- null = unlimited
  delay_seconds INTEGER DEFAULT 0, -- Delay before showing

  -- Scheduling
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,

  -- Targeting
  target_tiers TEXT[] DEFAULT ARRAY['free', 'max'],
  target_platforms TEXT[] DEFAULT ARRAY['ios', 'android'],
  target_user_segment TEXT, -- 'new', 'active', 'inactive', 'churned'
  min_app_version TEXT,

  -- Priority (higher = shown first when multiple match)
  priority INTEGER DEFAULT 0,

  -- Status
  is_active BOOLEAN DEFAULT true,
  is_dismissible BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),

  CONSTRAINT valid_message_type CHECK (message_type IN (
    'banner', 'modal', 'bottom_sheet', 'tooltip', 'full_screen'
  )),
  CONSTRAINT valid_trigger_type CHECK (trigger_type IN (
    'screen_view', 'event', 'app_open', 'scheduled', 'segment'
  )),
  CONSTRAINT valid_display_frequency CHECK (display_frequency IN (
    'once', 'once_per_session', 'daily', 'weekly', 'always'
  ))
);

-- User message impressions tracking
CREATE TABLE user_message_impressions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  message_id UUID NOT NULL REFERENCES admin_in_app_messages(id) ON DELETE CASCADE,

  -- Tracking
  impression_count INTEGER DEFAULT 1,
  first_shown_at TIMESTAMPTZ DEFAULT now(),
  last_shown_at TIMESTAMPTZ DEFAULT now(),

  -- Engagement
  clicked BOOLEAN DEFAULT false,
  clicked_at TIMESTAMPTZ,
  dismissed BOOLEAN DEFAULT false,
  dismissed_at TIMESTAMPTZ,

  -- Context
  shown_on_screen TEXT,
  app_version TEXT,
  platform TEXT,

  CONSTRAINT unique_user_message UNIQUE (user_id, message_id)
);

-- Create updated_at triggers
CREATE TRIGGER update_admin_in_app_messages_updated_at
  BEFORE UPDATE ON admin_in_app_messages
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Seed with sample messages
INSERT INTO admin_in_app_messages (
  name, name_ar, message_type, title_ar, title_en, body_ar, body_en,
  cta_text_ar, cta_text_en, cta_action, trigger_type, trigger_value,
  display_frequency, target_tiers, priority, is_active
) VALUES
-- Upgrade prompt for free users on AI screen
(
  'Upgrade Prompt - AI',
  'ترقية - الذكاء الاصطناعي',
  'bottom_sheet',
  'اكتشف قوة واصل',
  'Discover Wasil Power',
  'احصل على استشارات ذكية غير محدودة مع اشتراك ماكس',
  'Get unlimited AI consultations with MAX subscription',
  'ترقية الآن',
  'Upgrade Now',
  '/upgrade',
  'screen_view',
  'ai_chat',
  'weekly',
  ARRAY['free'],
  10,
  true
),
-- Welcome message for new users
(
  'Welcome New User',
  'ترحيب بمستخدم جديد',
  'modal',
  'مرحباً بك في صِلني! 🎉',
  'Welcome to Silni! 🎉',
  'ابدأ رحلتك في صلة الرحم وأضف أول قريب لك',
  'Start your journey and add your first relative',
  'إضافة قريب',
  'Add Relative',
  '/relatives/add',
  'event',
  'first_app_open',
  'once',
  ARRAY['free', 'max'],
  100,
  true
),
-- Streak reminder banner
(
  'Streak At Risk',
  'تنبيه السلسلة',
  'banner',
  'سلسلتك في خطر! 🔥',
  'Your streak is at risk! 🔥',
  'تواصل مع قريب اليوم للحفاظ على سلسلتك',
  'Connect with a relative today to keep your streak',
  'تواصل الآن',
  'Connect Now',
  '/home',
  'segment',
  'streak_at_risk',
  'daily',
  ARRAY['free', 'max'],
  50,
  false -- Disabled by default, enable when streak logic is ready
);

-- RLS Policies
ALTER TABLE admin_in_app_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_message_impressions ENABLE ROW LEVEL SECURITY;

-- Admins can manage messages
CREATE POLICY "Admins can manage in-app messages" ON admin_in_app_messages
  FOR ALL USING (is_admin());

-- Authenticated users can read active messages
CREATE POLICY "Authenticated users can read messages" ON admin_in_app_messages
  FOR SELECT USING (auth.role() = 'authenticated' AND is_active = true);

-- Users can manage their own impressions
CREATE POLICY "Users can manage own impressions" ON user_message_impressions
  FOR ALL USING (user_id = auth.uid());

-- Indexes
CREATE INDEX idx_admin_messages_active ON admin_in_app_messages(is_active) WHERE is_active = true;
CREATE INDEX idx_admin_messages_trigger ON admin_in_app_messages(trigger_type, trigger_value);
CREATE INDEX idx_admin_messages_dates ON admin_in_app_messages(start_date, end_date);
CREATE INDEX idx_admin_messages_priority ON admin_in_app_messages(priority DESC);

CREATE INDEX idx_user_impressions_user ON user_message_impressions(user_id);
CREATE INDEX idx_user_impressions_message ON user_message_impressions(message_id);

-- Function to get applicable messages for a user
CREATE OR REPLACE FUNCTION get_applicable_messages(
  p_user_id UUID,
  p_trigger_type TEXT,
  p_trigger_value TEXT DEFAULT NULL,
  p_user_tier TEXT DEFAULT 'free',
  p_platform TEXT DEFAULT 'ios'
)
RETURNS TABLE (
  id UUID,
  message_type TEXT,
  title_ar TEXT,
  body_ar TEXT,
  cta_text_ar TEXT,
  cta_action TEXT,
  image_url TEXT,
  icon_name TEXT,
  background_color TEXT,
  text_color TEXT,
  accent_color TEXT,
  delay_seconds INTEGER,
  is_dismissible BOOLEAN,
  priority INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    m.id,
    m.message_type,
    m.title_ar,
    m.body_ar,
    m.cta_text_ar,
    m.cta_action,
    m.image_url,
    m.icon_name,
    m.background_color,
    m.text_color,
    m.accent_color,
    m.delay_seconds,
    m.is_dismissible,
    m.priority
  FROM admin_in_app_messages m
  LEFT JOIN user_message_impressions i ON i.message_id = m.id AND i.user_id = p_user_id
  WHERE m.is_active = true
    AND m.trigger_type = p_trigger_type
    AND (m.trigger_value IS NULL OR m.trigger_value = p_trigger_value)
    AND p_user_tier = ANY(m.target_tiers)
    AND p_platform = ANY(m.target_platforms)
    AND (m.start_date IS NULL OR m.start_date <= now())
    AND (m.end_date IS NULL OR m.end_date >= now())
    -- Check display frequency
    AND (
      m.display_frequency = 'always'
      OR (m.display_frequency = 'once' AND i.id IS NULL)
      OR (m.display_frequency = 'daily' AND (i.last_shown_at IS NULL OR i.last_shown_at < now() - interval '1 day'))
      OR (m.display_frequency = 'weekly' AND (i.last_shown_at IS NULL OR i.last_shown_at < now() - interval '7 days'))
      OR m.display_frequency = 'once_per_session' -- Handled client-side
    )
    -- Check max impressions
    AND (m.max_impressions IS NULL OR COALESCE(i.impression_count, 0) < m.max_impressions)
  ORDER BY m.priority DESC
  LIMIT 5;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to record message impression
CREATE OR REPLACE FUNCTION record_message_impression(
  p_user_id UUID,
  p_message_id UUID,
  p_screen TEXT DEFAULT NULL,
  p_platform TEXT DEFAULT NULL,
  p_app_version TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
  INSERT INTO user_message_impressions (
    user_id, message_id, shown_on_screen, platform, app_version
  ) VALUES (
    p_user_id, p_message_id, p_screen, p_platform, p_app_version
  )
  ON CONFLICT (user_id, message_id) DO UPDATE SET
    impression_count = user_message_impressions.impression_count + 1,
    last_shown_at = now(),
    shown_on_screen = COALESCE(p_screen, user_message_impressions.shown_on_screen);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to record message interaction
CREATE OR REPLACE FUNCTION record_message_interaction(
  p_user_id UUID,
  p_message_id UUID,
  p_interaction_type TEXT -- 'click' or 'dismiss'
)
RETURNS VOID AS $$
BEGIN
  IF p_interaction_type = 'click' THEN
    UPDATE user_message_impressions
    SET clicked = true, clicked_at = now()
    WHERE user_id = p_user_id AND message_id = p_message_id;
  ELSIF p_interaction_type = 'dismiss' THEN
    UPDATE user_message_impressions
    SET dismissed = true, dismissed_at = now()
    WHERE user_id = p_user_id AND message_id = p_message_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON TABLE admin_in_app_messages IS 'In-app messaging system for targeted user engagement';
COMMENT ON TABLE user_message_impressions IS 'Tracks when users see and interact with messages';
COMMENT ON FUNCTION get_applicable_messages IS 'Returns messages applicable for a user based on context and history';
