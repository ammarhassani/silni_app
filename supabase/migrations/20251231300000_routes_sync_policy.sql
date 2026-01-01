-- RLS policies for admin_app_routes
-- This policy enables the admin panel to manage app routes

-- Drop existing policies if they exist to avoid conflicts
DROP POLICY IF EXISTS "Allow upsert for sync" ON admin_app_routes;
DROP POLICY IF EXISTS "Allow public read" ON admin_app_routes;
DROP POLICY IF EXISTS "Admins can manage routes" ON admin_app_routes;
DROP POLICY IF EXISTS "Users can read active routes" ON admin_app_routes;

-- Allow admins to manage routes (using the existing is_admin() function from phase1)
CREATE POLICY "Admins can manage routes" ON admin_app_routes
FOR ALL USING (is_admin());

-- Allow all users to read active routes (Flutter app needs this)
CREATE POLICY "Users can read active routes" ON admin_app_routes
FOR SELECT USING (is_active = true);
