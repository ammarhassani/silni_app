-- Fix RLS policies for admin_app_routes and admin_route_categories
-- Allow anon and authenticated users to read routes (it's just configuration data)
-- Admins can manage both tables

-- Drop existing read policies
DROP POLICY IF EXISTS "Routes are viewable by all authenticated users" ON admin_app_routes;
DROP POLICY IF EXISTS "Categories are viewable by all authenticated users" ON admin_route_categories;
DROP POLICY IF EXISTS "Routes are readable by everyone" ON admin_app_routes;
DROP POLICY IF EXISTS "Categories are readable by everyone" ON admin_route_categories;
DROP POLICY IF EXISTS "Admins can manage categories" ON admin_route_categories;

-- Create new read policies that allow both anon and authenticated
CREATE POLICY "Routes are readable by everyone"
  ON admin_app_routes FOR SELECT
  USING (is_active = true);

CREATE POLICY "Categories are readable by everyone"
  ON admin_route_categories FOR SELECT
  USING (is_active = true);

-- Admin write policies for route categories
CREATE POLICY "Admins can manage categories"
  ON admin_route_categories FOR ALL
  USING (is_admin());
