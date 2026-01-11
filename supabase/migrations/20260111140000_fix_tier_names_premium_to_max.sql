-- URGENT FIX: Change 'premium' tier to 'max' to match Flutter app
-- The app's FeatureConfigService only recognizes 'free' and 'max' tiers
-- The reseed migration incorrectly used 'premium' which breaks ALL premium features

-- Step 1: Create new 'max' tier first
INSERT INTO admin_subscription_tiers (tier_key, display_name_ar, display_name_en, reminder_limit, features, is_default, sort_order)
SELECT 'max', 'ماكس', 'MAX', reminder_limit, features, false, sort_order
FROM admin_subscription_tiers
WHERE tier_key = 'premium'
ON CONFLICT (tier_key) DO NOTHING;

-- Step 2: Update products to reference new 'max' tier
UPDATE admin_subscription_products
SET tier_key = 'max'
WHERE tier_key = 'premium';

-- Step 3: Remove old 'premium' tier
DELETE FROM admin_subscription_tiers WHERE tier_key = 'premium';

-- Step 4: Fix admin_features minimum_tier
UPDATE admin_features
SET minimum_tier = 'max'
WHERE minimum_tier = 'premium';
