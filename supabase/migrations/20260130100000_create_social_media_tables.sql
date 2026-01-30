-- =====================================================
-- Social Media Suite - Database Schema
-- Created: 2026-01-30
-- Description: Tables for managing social media posts,
--   analytics, campaigns, templates, and brand voice
--   for the Silni admin panel.
-- =====================================================

-- Enable pgcrypto for token encryption support
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =====================================================
-- 1. SOCIAL ACCOUNTS
-- Connected Twitter/Instagram credentials
-- =====================================================

CREATE TABLE IF NOT EXISTS social_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  platform TEXT NOT NULL CHECK (platform IN ('twitter', 'instagram')),
  account_name TEXT NOT NULL,
  account_handle TEXT NOT NULL,
  access_token_encrypted TEXT NOT NULL,
  refresh_token_encrypted TEXT,
  token_expires_at TIMESTAMPTZ,
  scopes TEXT[],
  platform_user_id TEXT,
  status TEXT NOT NULL DEFAULT 'connected' CHECK (status IN ('connected', 'expired', 'disconnected')),
  last_post_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 2. SOCIAL CAMPAIGNS
-- Group posts for tracking
-- =====================================================

CREATE TABLE IF NOT EXISTS social_campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  utm_campaign TEXT NOT NULL UNIQUE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 3. SOCIAL TEMPLATES
-- Reusable post structures
-- =====================================================

CREATE TABLE IF NOT EXISTS social_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  content_type TEXT NOT NULL CHECK (content_type IN ('hadith', 'quran', 'family_tip', 'feature', 'update', 'cta', 'occasion')),
  platform TEXT NOT NULL CHECK (platform IN ('twitter', 'instagram', 'both')),
  text_template TEXT NOT NULL,
  default_hashtags TEXT[],
  default_tone TEXT CHECK (default_tone IN ('inspirational', 'educational', 'conversational', 'promotional')),
  is_recurring BOOLEAN DEFAULT false,
  recurring_schedule JSONB,
  tags TEXT[],
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 4. SOCIAL BRAND VOICE
-- Brand voice configuration (singleton)
-- =====================================================

CREATE TABLE IF NOT EXISTS social_brand_voice (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tone_guidelines TEXT NOT NULL DEFAULT '',
  arabic_dialect TEXT NOT NULL DEFAULT 'msa' CHECK (arabic_dialect IN ('msa', 'colloquial', 'mix')),
  hashtag_sets JSONB DEFAULT '{}',
  banned_words TEXT[],
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 5. SOCIAL POSTS
-- Core posts table
-- =====================================================

CREATE TABLE IF NOT EXISTS social_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  platform TEXT NOT NULL CHECK (platform IN ('twitter', 'instagram')),
  content_type TEXT NOT NULL CHECK (content_type IN ('hadith', 'quran', 'family_tip', 'feature', 'update', 'cta', 'occasion')),
  text_ar TEXT NOT NULL,
  text_en TEXT,
  hashtags TEXT[],
  image_prompt TEXT,
  image_url TEXT,
  utm_link TEXT,
  tone TEXT CHECK (tone IN ('inspirational', 'educational', 'conversational', 'promotional')),
  status TEXT NOT NULL DEFAULT 'queued' CHECK (status IN ('draft', 'queued', 'approved', 'scheduled', 'published', 'failed', 'rejected')),
  scheduled_at TIMESTAMPTZ,
  published_at TIMESTAMPTZ,
  platform_post_id TEXT,
  platform_post_url TEXT,
  error_message TEXT,
  campaign_id UUID REFERENCES social_campaigns(id),
  template_id UUID REFERENCES social_templates(id),
  account_id UUID REFERENCES social_accounts(id),
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 6. SOCIAL ANALYTICS
-- Per-post engagement snapshots
-- =====================================================

CREATE TABLE IF NOT EXISTS social_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES social_posts(id) ON DELETE CASCADE,
  likes INTEGER DEFAULT 0,
  comments INTEGER DEFAULT 0,
  shares INTEGER DEFAULT 0,
  impressions INTEGER DEFAULT 0,
  link_clicks INTEGER DEFAULT 0,
  snapshot_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 7. SOCIAL CLICK LOG
-- UTM click tracking
-- =====================================================

CREATE TABLE IF NOT EXISTS social_click_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID REFERENCES social_posts(id) ON DELETE SET NULL,
  utm_source TEXT,
  utm_medium TEXT,
  utm_campaign TEXT,
  utm_content TEXT,
  user_agent TEXT,
  ip_hash TEXT,
  clicked_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 8. INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_social_posts_status ON social_posts(status);
CREATE INDEX IF NOT EXISTS idx_social_posts_scheduled ON social_posts(scheduled_at) WHERE status = 'scheduled';
CREATE INDEX IF NOT EXISTS idx_social_posts_platform ON social_posts(platform);
CREATE INDEX IF NOT EXISTS idx_social_posts_campaign_id ON social_posts(campaign_id);
CREATE INDEX IF NOT EXISTS idx_social_analytics_post_id ON social_analytics(post_id);
CREATE INDEX IF NOT EXISTS idx_social_analytics_snapshot_at ON social_analytics(snapshot_at);
CREATE INDEX IF NOT EXISTS idx_social_click_log_post_id ON social_click_log(post_id);
CREATE INDEX IF NOT EXISTS idx_social_click_log_utm_campaign ON social_click_log(utm_campaign);
CREATE INDEX IF NOT EXISTS idx_social_accounts_platform ON social_accounts(platform);

-- =====================================================
-- 9. UPDATED_AT TRIGGERS
-- =====================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_social_accounts_updated_at
  BEFORE UPDATE ON social_accounts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_social_campaigns_updated_at
  BEFORE UPDATE ON social_campaigns
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_social_templates_updated_at
  BEFORE UPDATE ON social_templates
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_social_brand_voice_updated_at
  BEFORE UPDATE ON social_brand_voice
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_social_posts_updated_at
  BEFORE UPDATE ON social_posts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 10. ROW LEVEL SECURITY
-- =====================================================

ALTER TABLE social_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_brand_voice ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_click_log ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 11. SERVICE ROLE POLICIES
-- Full access for service role (admin backend)
-- =====================================================

CREATE POLICY social_accounts_service_role_all
  ON social_accounts FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

CREATE POLICY social_campaigns_service_role_all
  ON social_campaigns FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

CREATE POLICY social_templates_service_role_all
  ON social_templates FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

CREATE POLICY social_brand_voice_service_role_all
  ON social_brand_voice FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

CREATE POLICY social_posts_service_role_all
  ON social_posts FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

CREATE POLICY social_analytics_service_role_all
  ON social_analytics FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

CREATE POLICY social_click_log_service_role_all
  ON social_click_log FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- =====================================================
-- 12. SEED DATA
-- Default brand voice configuration
-- =====================================================

INSERT INTO social_brand_voice (tone_guidelines, arabic_dialect, hashtag_sets, banned_words)
VALUES (
  'دافئ، عائلي، متجذر في القيم الإسلامية، غير وعظي. نتحدث كصديق ناصح لا كواعظ.',
  'msa',
  '{"islamic": ["#صلة_الرحم", "#عائلة", "#اسلام", "#حديث", "#قرآن"], "app": ["#صلني", "#silni", "#family_app", "#تطبيق_عائلي"], "occasion": ["#رمضان", "#عيد", "#جمعة_مباركة"]}',
  ARRAY['سياسة', 'طائفي', 'مذهبي']
);
