-- Fix product IDs to match App Store Connect identifiers
-- The reseed migration (20260111120000) incorrectly used 'max_monthly'/'max_annual'
-- and the live DB has 'premium_monthly'/'premium_annual' from manual edits.
-- App Store Connect uses 'silni_max_monthly'/'silni_max_annual'.

-- Step 1: Update product IDs to match App Store Connect
UPDATE admin_subscription_products
SET product_id = 'silni_max_monthly'
WHERE product_id IN ('max_monthly', 'premium_monthly');

UPDATE admin_subscription_products
SET product_id = 'silni_max_annual'
WHERE product_id IN ('max_annual', 'premium_annual');

-- Step 2: Clear hardcoded prices — App Store is the source of truth
-- The app fetches localized prices dynamically via RevenueCat
UPDATE admin_subscription_products
SET
  price_usd = NULL,
  price_sar = NULL,
  price_source = 'manual',
  price_verified_at = NULL,
  notes = 'Prices managed by App Store Connect. Use RevenueCat for dynamic pricing.'
WHERE product_id IN ('silni_max_monthly', 'silni_max_annual');

-- Step 3: Set revenuecat_package_id for cross-reference
UPDATE admin_subscription_products
SET revenuecat_package_id = 'max_monthly'
WHERE product_id = 'silni_max_monthly';

UPDATE admin_subscription_products
SET revenuecat_package_id = 'max_annual'
WHERE product_id = 'silni_max_annual';
