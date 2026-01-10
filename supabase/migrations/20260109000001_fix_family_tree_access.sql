-- Fix family_tree to be a free feature
-- This ensures family_tree is accessible to all users (free and max)

UPDATE admin_features
SET minimum_tier = 'free', is_active = true
WHERE feature_id = 'family_tree';

-- Also ensure it's in both tier feature arrays
UPDATE admin_subscription_tiers
SET features = features || '["family_tree"]'::jsonb
WHERE tier_key = 'free'
  AND NOT (features @> '["family_tree"]'::jsonb);

UPDATE admin_subscription_tiers
SET features = features || '["family_tree"]'::jsonb
WHERE tier_key = 'max'
  AND NOT (features @> '["family_tree"]'::jsonb);
