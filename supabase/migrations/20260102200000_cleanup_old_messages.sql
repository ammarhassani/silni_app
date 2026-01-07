-- =====================================================
-- Cleanup Old Messages
-- Remove all old/migrated messages to start fresh with unified system
-- =====================================================

-- Clear all impression tracking
TRUNCATE TABLE user_message_impressions;

-- Clear all messages to start fresh
TRUNCATE TABLE admin_in_app_messages CASCADE;

-- Drop old tables that are no longer needed
DROP TABLE IF EXISTS admin_motd CASCADE;
DROP TABLE IF EXISTS admin_banners CASCADE;

-- Log cleanup
DO $$
BEGIN
  RAISE NOTICE 'Cleanup complete. All old messages removed. Old tables dropped.';
END $$;
