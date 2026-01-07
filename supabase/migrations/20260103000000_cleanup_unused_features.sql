-- Migration: Cleanup unused features
-- Removes: Referral Program, Push Campaigns, Subscription Gifts
-- Date: 2026-01-03

-- =====================================================
-- DROP REFERRAL PROGRAM TABLES AND FUNCTIONS
-- =====================================================

-- Drop triggers first
DROP TRIGGER IF EXISTS update_admin_referral_config_updated_at ON admin_referral_config;

-- Drop functions
DROP FUNCTION IF EXISTS get_referral_stats(UUID);
DROP FUNCTION IF EXISTS track_referee_action(UUID);
DROP FUNCTION IF EXISTS apply_referral_code(UUID, TEXT);
DROP FUNCTION IF EXISTS get_or_create_referral_code(UUID);
DROP FUNCTION IF EXISTS generate_referral_code();

-- Drop tables (order matters due to foreign keys)
DROP TABLE IF EXISTS user_referrals;
DROP TABLE IF EXISTS referral_codes;
DROP TABLE IF EXISTS admin_referral_config;

-- =====================================================
-- DROP PUSH CAMPAIGNS TABLES
-- =====================================================

-- Drop dependent table first
DROP TABLE IF EXISTS campaign_send_log;
DROP TABLE IF EXISTS admin_push_campaigns;

-- =====================================================
-- DROP SUBSCRIPTION GIFTS TABLE
-- =====================================================

DROP TABLE IF EXISTS subscription_gifts;

-- =====================================================
-- CLEANUP CACHE CONFIG
-- =====================================================

-- Remove referral_config from cache config if it exists
DELETE FROM admin_cache_config WHERE service_key = 'referral_config';

-- =====================================================
-- VERIFICATION
-- =====================================================

-- This will fail if any tables still exist (good for verification)
DO $$
BEGIN
  -- Check that all tables are dropped
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_referrals') THEN
    RAISE EXCEPTION 'user_referrals table still exists';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'referral_codes') THEN
    RAISE EXCEPTION 'referral_codes table still exists';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'admin_referral_config') THEN
    RAISE EXCEPTION 'admin_referral_config table still exists';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'admin_push_campaigns') THEN
    RAISE EXCEPTION 'admin_push_campaigns table still exists';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'subscription_gifts') THEN
    RAISE EXCEPTION 'subscription_gifts table still exists';
  END IF;

  RAISE NOTICE 'All unused feature tables successfully dropped';
END $$;
