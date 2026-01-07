-- Onboarding Configuration
-- Allows admin to customize onboarding screens remotely

CREATE TABLE admin_onboarding_screens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  screen_order INTEGER NOT NULL,
  title_ar TEXT NOT NULL,
  title_en TEXT,
  subtitle_ar TEXT,
  subtitle_en TEXT,

  -- Visual content (either image URL or Lottie animation name)
  image_url TEXT,
  animation_name TEXT, -- Lottie animation asset name

  -- Styling
  background_color TEXT DEFAULT '#FFFFFF',
  background_gradient_start TEXT,
  background_gradient_end TEXT,
  text_color TEXT DEFAULT '#1F2937',
  accent_color TEXT,

  -- Button configuration
  button_text_ar TEXT DEFAULT 'التالي',
  button_text_en TEXT DEFAULT 'Next',
  button_color TEXT,

  -- Options
  skip_enabled BOOLEAN DEFAULT true,
  auto_advance_seconds INTEGER, -- auto advance after X seconds (null = manual only)

  -- Targeting (optional)
  show_for_tiers TEXT[] DEFAULT ARRAY['free', 'max'],

  -- Status
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),

  CONSTRAINT unique_screen_order UNIQUE (screen_order),
  CONSTRAINT valid_order CHECK (screen_order > 0)
);

-- Create updated_at trigger
CREATE TRIGGER update_admin_onboarding_screens_updated_at
  BEFORE UPDATE ON admin_onboarding_screens
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Seed with default onboarding screens
INSERT INTO admin_onboarding_screens (
  screen_order, title_ar, title_en, subtitle_ar, subtitle_en,
  animation_name, background_color, text_color, button_text_ar
) VALUES
(1,
  'مرحباً بك في صِلني',
  'Welcome to Silni',
  'تطبيق يساعدك على التواصل مع أقاربك والحفاظ على صلة الرحم',
  'An app that helps you stay connected with your relatives',
  'onboarding_welcome',
  '#FFFFFF', '#1F2937', 'التالي'
),
(2,
  'تذكيرات ذكية',
  'Smart Reminders',
  'لا تنسَ صلة أرحامك مع تذكيرات مخصصة لكل قريب',
  'Never forget to connect with personalized reminders',
  'onboarding_reminders',
  '#FFFFFF', '#1F2937', 'التالي'
),
(3,
  'مستشار واصل',
  'Wasil Assistant',
  'مستشارك الذكي يساعدك في كل موقف تواصلي',
  'Your AI assistant for all communication situations',
  'onboarding_ai',
  '#FFFFFF', '#1F2937', 'التالي'
),
(4,
  'نظام المكافآت',
  'Rewards System',
  'اكسب النقاط والشارات وارتقِ بمستواك',
  'Earn points, badges, and level up',
  'onboarding_gamification',
  '#FFFFFF', '#1F2937', 'التالي'
),
(5,
  'ابدأ رحلتك',
  'Start Your Journey',
  'سجّل الآن وابدأ صلة أرحامك',
  'Sign up now and start connecting',
  'onboarding_start',
  '#10B981', '#FFFFFF', 'ابدأ الآن'
);

-- RLS Policies
ALTER TABLE admin_onboarding_screens ENABLE ROW LEVEL SECURITY;

-- Admins can manage onboarding screens
CREATE POLICY "Admins can manage onboarding" ON admin_onboarding_screens
  FOR ALL USING (is_admin());

-- Anyone can read active onboarding screens (needed before auth)
CREATE POLICY "Anyone can read onboarding" ON admin_onboarding_screens
  FOR SELECT USING (is_active = true);

-- Indexes
CREATE INDEX idx_admin_onboarding_order ON admin_onboarding_screens(screen_order);
CREATE INDEX idx_admin_onboarding_active ON admin_onboarding_screens(is_active) WHERE is_active = true;

-- Function to reorder screens
CREATE OR REPLACE FUNCTION reorder_onboarding_screens(
  p_screen_id UUID,
  p_new_order INTEGER
)
RETURNS VOID AS $$
DECLARE
  v_current_order INTEGER;
BEGIN
  -- Get current order
  SELECT screen_order INTO v_current_order
  FROM admin_onboarding_screens
  WHERE id = p_screen_id;

  IF v_current_order IS NULL THEN
    RAISE EXCEPTION 'Screen not found';
  END IF;

  IF p_new_order = v_current_order THEN
    RETURN;
  END IF;

  -- Shift other screens
  IF p_new_order > v_current_order THEN
    -- Moving down: shift screens up
    UPDATE admin_onboarding_screens
    SET screen_order = screen_order - 1
    WHERE screen_order > v_current_order
      AND screen_order <= p_new_order;
  ELSE
    -- Moving up: shift screens down
    UPDATE admin_onboarding_screens
    SET screen_order = screen_order + 1
    WHERE screen_order >= p_new_order
      AND screen_order < v_current_order;
  END IF;

  -- Set new order
  UPDATE admin_onboarding_screens
  SET screen_order = p_new_order
  WHERE id = p_screen_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON TABLE admin_onboarding_screens IS 'Configurable onboarding screens for the Flutter app';
COMMENT ON FUNCTION reorder_onboarding_screens IS 'Reorders onboarding screens and shifts others accordingly';
