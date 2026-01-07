-- =====================================================
-- Hotfix: Normalize path matching in get_applicable_messages
-- Fixes issue where /ai-hub doesn't match ai-hub
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
      OR TRIM(LEADING '/' FROM COALESCE(m.trigger_value, '')) = TRIM(LEADING '/' FROM COALESCE(p_trigger_value, ''))
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
