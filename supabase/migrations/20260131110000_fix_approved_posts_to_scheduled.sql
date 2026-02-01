-- =====================================================
-- One-time fix: move approved posts to scheduled
-- and assign the connected Twitter account.
-- Previously the approve action only set status='approved'
-- without an account_id, so these posts were stuck.
-- =====================================================

-- Assign the connected Twitter account and schedule all approved twitter posts
UPDATE social_posts
SET status = 'scheduled',
    account_id = (
      SELECT id FROM social_accounts
      WHERE platform = 'twitter' AND status = 'connected'
      LIMIT 1
    )
WHERE status = 'approved'
  AND platform = 'twitter'
  AND account_id IS NULL;

-- Assign the connected Instagram account and schedule all approved instagram posts
UPDATE social_posts
SET status = 'scheduled',
    account_id = (
      SELECT id FROM social_accounts
      WHERE platform = 'instagram' AND status = 'connected'
      LIMIT 1
    )
WHERE status = 'approved'
  AND platform = 'instagram'
  AND account_id IS NULL;
