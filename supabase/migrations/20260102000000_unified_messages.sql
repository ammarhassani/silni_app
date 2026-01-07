-- =====================================================
-- Unified Messages System
-- Consolidates: admin_motd, admin_banners, admin_in_app_messages
-- Created: 2026-01-02
-- =====================================================

-- Add missing columns to admin_in_app_messages (instead of creating new table)
-- This preserves existing data and RPC functions

-- Add columns from Banners
ALTER TABLE admin_in_app_messages
ADD COLUMN IF NOT EXISTS background_gradient JSONB,
ADD COLUMN IF NOT EXISTS cta_action_type TEXT DEFAULT 'route',
ADD COLUMN IF NOT EXISTS impressions INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS clicks INTEGER DEFAULT 0;

-- Add constraint for cta_action_type
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'valid_cta_action_type'
  ) THEN
    ALTER TABLE admin_in_app_messages
    ADD CONSTRAINT valid_cta_action_type CHECK (
      cta_action_type IS NULL OR cta_action_type IN ('route', 'url', 'action', 'none')
    );
  END IF;
END $$;

-- Extend message_type to include 'motd'
ALTER TABLE admin_in_app_messages DROP CONSTRAINT IF EXISTS valid_message_type;
ALTER TABLE admin_in_app_messages
ADD CONSTRAINT valid_message_type CHECK (message_type IN (
  'banner', 'modal', 'bottom_sheet', 'tooltip', 'full_screen', 'motd'
));

-- Extend trigger_type to include 'position' (for banner positions)
ALTER TABLE admin_in_app_messages DROP CONSTRAINT IF EXISTS valid_trigger_type;
ALTER TABLE admin_in_app_messages
ADD CONSTRAINT valid_trigger_type CHECK (trigger_type IN (
  'screen_view', 'event', 'app_open', 'scheduled', 'segment', 'position'
));

-- =====================================================
-- Migrate existing MOTD data
-- =====================================================
INSERT INTO admin_in_app_messages (
  name,
  name_ar,
  message_type,
  title_ar,
  body_ar,
  icon_name,
  background_gradient,
  cta_text_ar,
  cta_action,
  cta_action_type,
  trigger_type,
  trigger_value,
  start_date,
  end_date,
  is_active,
  priority,
  display_frequency,
  is_dismissible
)
SELECT
  title,                                    -- name
  title,                                    -- name_ar
  'motd',                                   -- message_type
  title,                                    -- title_ar
  message,                                  -- body_ar
  icon,                                     -- icon_name
  background_gradient,                      -- background_gradient
  action_text,                              -- cta_text_ar
  action_route,                             -- cta_action
  'route',                                  -- cta_action_type
  'screen_view',                            -- trigger_type
  '/home',                                  -- trigger_value (MOTD always on home)
  start_date::TIMESTAMPTZ,                  -- start_date
  end_date::TIMESTAMPTZ,                    -- end_date
  is_active,                                -- is_active
  display_priority + 1000,                  -- priority (higher than regular messages)
  'daily',                                  -- display_frequency (show once per day like original)
  true                                      -- is_dismissible
FROM admin_motd
WHERE NOT EXISTS (
  SELECT 1 FROM admin_in_app_messages WHERE name = admin_motd.title AND message_type = 'motd'
);

-- =====================================================
-- Migrate existing Banners data
-- =====================================================
INSERT INTO admin_in_app_messages (
  name,
  name_ar,
  message_type,
  title_ar,
  body_ar,
  image_url,
  background_gradient,
  cta_action,
  cta_action_type,
  trigger_type,
  trigger_value,
  target_tiers,
  start_date,
  end_date,
  is_active,
  priority,
  display_frequency,
  is_dismissible,
  impressions,
  clicks
)
SELECT
  title,                                              -- name
  title,                                              -- name_ar
  'banner',                                           -- message_type
  title,                                              -- title_ar
  description,                                        -- body_ar
  image_url,                                          -- image_url
  background_gradient,                                -- background_gradient
  action_value,                                       -- cta_action
  COALESCE(action_type, 'route'),                    -- cta_action_type
  'position',                                         -- trigger_type (for banner positions)
  position,                                           -- trigger_value (home_top, home_bottom, etc.)
  CASE
    WHEN target_audience = 'all' THEN ARRAY['free', 'max']
    WHEN target_audience = 'free' THEN ARRAY['free']
    WHEN target_audience = 'max' THEN ARRAY['max']
    WHEN target_audience = 'new_users' THEN ARRAY['free', 'max']
    ELSE ARRAY['free', 'max']
  END,                                                -- target_tiers
  start_date,                                         -- start_date
  end_date,                                           -- end_date
  is_active,                                          -- is_active
  display_priority,                                   -- priority
  'always',                                           -- display_frequency (banners always show)
  true,                                               -- is_dismissible
  impressions,                                        -- impressions
  clicks                                              -- clicks
FROM admin_banners
WHERE NOT EXISTS (
  SELECT 1 FROM admin_in_app_messages
  WHERE name = admin_banners.title
    AND message_type = 'banner'
    AND trigger_value = admin_banners.position
);

-- =====================================================
-- Create/Update RPC functions for unified system
-- =====================================================

-- Drop and recreate get_applicable_messages with enhanced return type
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
    -- Normalize path comparison (remove leading slash for comparison)
    AND (
      m.trigger_value IS NULL
      OR m.trigger_value = p_trigger_value
      OR TRIM(LEADING '/' FROM m.trigger_value) = TRIM(LEADING '/' FROM p_trigger_value)
    )
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
  LIMIT 10;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to increment message impressions (for simple analytics)
CREATE OR REPLACE FUNCTION increment_message_impressions(p_message_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE admin_in_app_messages
  SET impressions = impressions + 1
  WHERE id = p_message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to increment message clicks (for simple analytics)
CREATE OR REPLACE FUNCTION increment_message_clicks(p_message_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE admin_in_app_messages
  SET clicks = clicks + 1
  WHERE id = p_message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- Comments
-- =====================================================
COMMENT ON TABLE admin_in_app_messages IS 'Unified messaging system - consolidates MOTD, Banners, and In-App Messages';
COMMENT ON COLUMN admin_in_app_messages.message_type IS 'banner, modal, bottom_sheet, tooltip, full_screen, motd';
COMMENT ON COLUMN admin_in_app_messages.trigger_type IS 'screen_view, event, app_open, scheduled, segment, position';
COMMENT ON COLUMN admin_in_app_messages.background_gradient IS 'JSONB with start/end hex colors for gradient backgrounds';
COMMENT ON COLUMN admin_in_app_messages.cta_action_type IS 'route (in-app), url (external), action (custom), none';

-- =====================================================
-- Note: Old tables (admin_motd, admin_banners) are kept for now
-- They can be dropped after confirming migration success:
-- DROP TABLE IF EXISTS admin_motd;
-- DROP TABLE IF EXISTS admin_banners;
-- =====================================================
