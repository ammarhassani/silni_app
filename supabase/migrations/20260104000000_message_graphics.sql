-- =====================================================
-- Message Graphics Enhancement
-- Adds support for SVG icons, Lottie animations, and illustrations
-- Created: 2026-01-04
-- =====================================================

-- Add new columns for enhanced graphics
ALTER TABLE admin_in_app_messages
ADD COLUMN IF NOT EXISTS graphic_type TEXT DEFAULT 'icon',
ADD COLUMN IF NOT EXISTS lottie_name TEXT,
ADD COLUMN IF NOT EXISTS illustration_url TEXT,
ADD COLUMN IF NOT EXISTS icon_style TEXT DEFAULT 'default';

-- Add constraints for new columns
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'valid_graphic_type'
  ) THEN
    ALTER TABLE admin_in_app_messages
    ADD CONSTRAINT valid_graphic_type CHECK (
      graphic_type IS NULL OR graphic_type IN ('icon', 'lottie', 'illustration', 'emoji')
    );
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'valid_icon_style'
  ) THEN
    ALTER TABLE admin_in_app_messages
    ADD CONSTRAINT valid_icon_style CHECK (
      icon_style IS NULL OR icon_style IN ('default', 'filled', 'outlined', 'gradient')
    );
  END IF;
END $$;

-- =====================================================
-- Update RPC function to include new columns
-- =====================================================

DROP FUNCTION IF EXISTS get_applicable_messages(UUID, TEXT, TEXT, TEXT, TEXT);

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
  cta_action_type TEXT,
  image_url TEXT,
  icon_name TEXT,
  graphic_type TEXT,
  lottie_name TEXT,
  illustration_url TEXT,
  icon_style TEXT,
  background_color TEXT,
  text_color TEXT,
  accent_color TEXT,
  background_gradient JSONB,
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
    m.cta_action_type,
    m.image_url,
    m.icon_name,
    m.graphic_type,
    m.lottie_name,
    m.illustration_url,
    m.icon_style,
    m.background_color,
    m.text_color,
    m.accent_color,
    m.background_gradient,
    m.delay_seconds,
    m.is_dismissible,
    m.priority
  FROM admin_in_app_messages m
  LEFT JOIN user_message_impressions i ON i.message_id = m.id AND i.user_id = p_user_id
  WHERE m.is_active = true
    AND m.trigger_type = p_trigger_type
    AND (
      m.trigger_value IS NULL
      OR m.trigger_value = p_trigger_value
      OR TRIM(LEADING '/' FROM m.trigger_value) = TRIM(LEADING '/' FROM p_trigger_value)
    )
    AND p_user_tier = ANY(m.target_tiers)
    AND p_platform = ANY(m.target_platforms)
    AND (m.start_date IS NULL OR m.start_date <= now())
    AND (m.end_date IS NULL OR m.end_date >= now())
    AND (
      m.display_frequency = 'always'
      OR (m.display_frequency = 'once' AND i.id IS NULL)
      OR (m.display_frequency = 'daily' AND (i.last_shown_at IS NULL OR i.last_shown_at < now() - interval '1 day'))
      OR (m.display_frequency = 'weekly' AND (i.last_shown_at IS NULL OR i.last_shown_at < now() - interval '7 days'))
      OR m.display_frequency = 'once_per_session'
    )
    AND (m.max_impressions IS NULL OR COALESCE(i.impression_count, 0) < m.max_impressions)
  ORDER BY m.priority DESC
  LIMIT 10;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- Update existing messages to use 'emoji' graphic type
-- (preserves backward compatibility)
-- =====================================================

UPDATE admin_in_app_messages
SET graphic_type = 'emoji'
WHERE icon_name IS NOT NULL AND graphic_type = 'icon';

-- =====================================================
-- Comments
-- =====================================================

COMMENT ON COLUMN admin_in_app_messages.graphic_type IS 'Type of graphic: icon (Lucide SVG), lottie (animation), illustration (image), emoji (legacy)';
COMMENT ON COLUMN admin_in_app_messages.lottie_name IS 'Name of Lottie animation file (e.g., celebration_confetti, success_checkmark)';
COMMENT ON COLUMN admin_in_app_messages.illustration_url IS 'URL to custom illustration in Supabase Storage';
COMMENT ON COLUMN admin_in_app_messages.icon_style IS 'Style variant for SVG icons: default, filled, outlined, gradient';
