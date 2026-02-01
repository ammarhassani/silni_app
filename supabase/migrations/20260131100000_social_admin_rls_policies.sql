-- =====================================================
-- Add admin RLS policies for social media tables
-- The original migration only granted access to service_role.
-- The admin panel uses client-side Supabase (authenticated role),
-- so admin users need explicit policies.
-- =====================================================

-- social_accounts: admin full access
CREATE POLICY social_accounts_admin_all
  ON social_accounts FOR ALL
  TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- social_campaigns: admin full access
CREATE POLICY social_campaigns_admin_all
  ON social_campaigns FOR ALL
  TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- social_templates: admin full access
CREATE POLICY social_templates_admin_all
  ON social_templates FOR ALL
  TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- social_brand_voice: admin full access
CREATE POLICY social_brand_voice_admin_all
  ON social_brand_voice FOR ALL
  TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- social_posts: admin full access
CREATE POLICY social_posts_admin_all
  ON social_posts FOR ALL
  TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- social_analytics: admin full access
CREATE POLICY social_analytics_admin_all
  ON social_analytics FOR ALL
  TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- social_click_log: admin full access
CREATE POLICY social_click_log_admin_all
  ON social_click_log FOR ALL
  TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
