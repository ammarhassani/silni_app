-- Point Multiplier Events
-- Time-limited events that boost points earned for specific actions

CREATE TABLE admin_point_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  name_ar TEXT NOT NULL,
  description TEXT,
  description_ar TEXT,

  -- Multiplier and bonus
  multiplier DECIMAL(4,2) NOT NULL DEFAULT 1.5,
  bonus_points INTEGER DEFAULT 0,

  -- Timing
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ NOT NULL,

  -- Targeting: which point actions this applies to
  -- 'all', 'streak', 'connection', 'reminder', 'first_connection', 'badge_earned', etc.
  applies_to TEXT[] DEFAULT ARRAY['all'],

  -- Display
  icon TEXT DEFAULT 'gift',
  color TEXT DEFAULT '#FFD700',
  banner_image_url TEXT,
  show_banner BOOLEAN DEFAULT true,

  -- Status
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),

  -- Constraints
  CONSTRAINT valid_multiplier CHECK (multiplier >= 1.0 AND multiplier <= 10.0),
  CONSTRAINT valid_dates CHECK (end_date > start_date),
  CONSTRAINT valid_bonus CHECK (bonus_points >= 0)
);

-- Create updated_at trigger
CREATE TRIGGER update_admin_point_events_updated_at
  BEFORE UPDATE ON admin_point_events
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Seed with example events (inactive by default)
INSERT INTO admin_point_events (name, name_ar, description_ar, multiplier, bonus_points, start_date, end_date, applies_to, icon, color, is_active) VALUES
('Ramadan Boost', 'مضاعفة رمضان', 'نقاط مضاعفة خلال شهر رمضان المبارك', 2.0, 50, '2026-02-28 00:00:00+00', '2026-03-30 23:59:59+00', ARRAY['all'], 'moon', '#C9A227', false),
('Eid Celebration', 'احتفال العيد', 'نقاط إضافية بمناسبة العيد', 1.5, 100, '2026-03-30 00:00:00+00', '2026-04-02 23:59:59+00', ARRAY['connection', 'first_connection'], 'gift', '#4CAF50', false),
('Weekend Warriors', 'محاربو نهاية الأسبوع', 'نقاط إضافية للتواصل في نهاية الأسبوع', 1.25, 25, '2026-01-03 00:00:00+00', '2026-01-05 23:59:59+00', ARRAY['connection', 'streak'], 'zap', '#FF9800', false);

-- RLS Policies
ALTER TABLE admin_point_events ENABLE ROW LEVEL SECURITY;

-- Admins can manage point events
CREATE POLICY "Admins can manage point events" ON admin_point_events
  FOR ALL USING (is_admin());

-- Authenticated users can read active events
CREATE POLICY "Authenticated users can read active events" ON admin_point_events
  FOR SELECT USING (
    auth.role() = 'authenticated'
    AND is_active = true
  );

-- Indexes for efficient querying
CREATE INDEX idx_admin_point_events_active ON admin_point_events(is_active) WHERE is_active = true;
CREATE INDEX idx_admin_point_events_dates ON admin_point_events(start_date, end_date);
CREATE INDEX idx_admin_point_events_current ON admin_point_events(start_date, end_date)
  WHERE is_active = true;

-- Function to get currently active event with highest multiplier
CREATE OR REPLACE FUNCTION get_active_point_event()
RETURNS TABLE (
  id UUID,
  name TEXT,
  name_ar TEXT,
  multiplier DECIMAL,
  bonus_points INTEGER,
  applies_to TEXT[],
  icon TEXT,
  color TEXT,
  banner_image_url TEXT,
  end_date TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    e.id,
    e.name,
    e.name_ar,
    e.multiplier,
    e.bonus_points,
    e.applies_to,
    e.icon,
    e.color,
    e.banner_image_url,
    e.end_date
  FROM admin_point_events e
  WHERE e.is_active = true
    AND e.start_date <= now()
    AND e.end_date >= now()
  ORDER BY e.multiplier DESC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON TABLE admin_point_events IS 'Time-limited point multiplier events for gamification';
COMMENT ON FUNCTION get_active_point_event IS 'Returns the currently active event with highest multiplier';
