-- Dynamic App Routes for Admin Panel
-- Stores route hierarchy for dropdown selectors in CMS
-- Enables business continuity when adding new features

CREATE TABLE IF NOT EXISTS admin_app_routes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Route identification
  path TEXT NOT NULL UNIQUE,
  route_key TEXT NOT NULL UNIQUE,  -- Unique identifier like 'home', 'ai_chat'

  -- Display information
  label_ar TEXT NOT NULL,
  label_en TEXT,
  icon TEXT,  -- Emoji or icon name
  description_ar TEXT,

  -- Hierarchy
  category_key TEXT NOT NULL,  -- Groups routes: 'main', 'ai', 'reminders', etc.
  parent_route_key TEXT REFERENCES admin_app_routes(route_key),  -- For sub-routes

  -- Ordering and status
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  is_public BOOLEAN DEFAULT true,  -- Some routes may be internal only

  -- Feature gating
  requires_auth BOOLEAN DEFAULT true,
  requires_premium BOOLEAN DEFAULT false,
  feature_id TEXT,  -- Links to feature gating system

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Route categories table for organizing routes
CREATE TABLE IF NOT EXISTS admin_route_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_key TEXT NOT NULL UNIQUE,
  label_ar TEXT NOT NULL,
  label_en TEXT,
  icon TEXT,
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_app_routes_category ON admin_app_routes(category_key);
CREATE INDEX IF NOT EXISTS idx_app_routes_parent ON admin_app_routes(parent_route_key);
CREATE INDEX IF NOT EXISTS idx_app_routes_active ON admin_app_routes(is_active);
CREATE INDEX IF NOT EXISTS idx_app_routes_sort ON admin_app_routes(category_key, sort_order);

-- Trigger to update updated_at
CREATE OR REPLACE FUNCTION update_app_routes_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_app_routes_timestamp
  BEFORE UPDATE ON admin_app_routes
  FOR EACH ROW
  EXECUTE FUNCTION update_app_routes_timestamp();

-- RLS Policies (read-only for authenticated, write for admin)
ALTER TABLE admin_app_routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_route_categories ENABLE ROW LEVEL SECURITY;

-- Everyone can read routes
CREATE POLICY "Routes are viewable by all authenticated users"
  ON admin_app_routes FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Categories are viewable by all authenticated users"
  ON admin_route_categories FOR SELECT
  TO authenticated
  USING (true);

-- Only service role can modify (admin panel uses service role)
CREATE POLICY "Routes are modifiable by service role"
  ON admin_app_routes FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Categories are modifiable by service role"
  ON admin_route_categories FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Comments
COMMENT ON TABLE admin_app_routes IS 'Dynamic app routes for CMS route selectors';
COMMENT ON TABLE admin_route_categories IS 'Categories for organizing app routes';
COMMENT ON COLUMN admin_app_routes.route_key IS 'Unique key identifier for the route';
COMMENT ON COLUMN admin_app_routes.category_key IS 'Foreign key to route_categories';
COMMENT ON COLUMN admin_app_routes.parent_route_key IS 'Parent route for hierarchical sub-routes';
