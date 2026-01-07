-- Cleanup migration: Drop deprecated tables and functions
-- Removes: MOTD, Banners, Push Campaigns, Referral Program

-- Drop functions (IF EXISTS handles non-existent gracefully)
DROP FUNCTION IF EXISTS update_admin_motd_updated_at() CASCADE;
DROP FUNCTION IF EXISTS update_admin_banners_updated_at() CASCADE;
DROP FUNCTION IF EXISTS update_admin_push_campaigns_updated_at() CASCADE;
DROP FUNCTION IF EXISTS update_admin_referral_config_updated_at() CASCADE;
DROP FUNCTION IF EXISTS update_referral_codes_updated_at() CASCADE;
DROP FUNCTION IF EXISTS update_user_referrals_updated_at() CASCADE;
DROP FUNCTION IF EXISTS record_banner_impression(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS record_banner_click(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS get_banner_analytics(UUID) CASCADE;
DROP FUNCTION IF EXISTS apply_referral_code(UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS process_referral_reward(UUID) CASCADE;

-- Drop tables (CASCADE removes triggers, policies, indexes automatically)
DROP TABLE IF EXISTS campaign_send_log CASCADE;
DROP TABLE IF EXISTS admin_push_campaigns CASCADE;
DROP TABLE IF EXISTS user_referrals CASCADE;
DROP TABLE IF EXISTS referral_codes CASCADE;
DROP TABLE IF EXISTS admin_referral_config CASCADE;
DROP TABLE IF EXISTS admin_banners CASCADE;
DROP TABLE IF EXISTS admin_motd CASCADE;

-- Remove referral cache config entry (safe if doesn't exist)
DELETE FROM admin_cache_config WHERE service_key = 'referral_config';

-- Add comment to unified messages table if it exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'admin_in_app_messages') THEN
    COMMENT ON TABLE admin_in_app_messages IS 'Unified messaging system - replaces deprecated admin_motd and admin_banners';
  END IF;
END $$;
