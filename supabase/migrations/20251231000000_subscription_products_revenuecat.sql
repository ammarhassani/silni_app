-- =====================================================
-- RevenueCat Sync Fields for Subscription Products
-- =====================================================
-- Adds columns to track RevenueCat sync status and removes
-- hardcoded placeholder prices. Prices should be set manually
-- by admin after verifying against App Store Connect.
-- =====================================================

-- Add new columns for RevenueCat integration
ALTER TABLE admin_subscription_products
  ADD COLUMN IF NOT EXISTS price_source TEXT DEFAULT 'manual'
    CHECK (price_source IN ('manual', 'app_store', 'google_play')),
  ADD COLUMN IF NOT EXISTS price_verified_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS revenuecat_package_id TEXT,
  ADD COLUMN IF NOT EXISTS notes TEXT;

-- Clear placeholder prices - admin must enter real prices after
-- verifying them in App Store Connect / Google Play Console
-- The prices (109.99 SAR, 18.99 SAR) were seed data, not real values
UPDATE admin_subscription_products
SET
  price_usd = NULL,
  price_sar = NULL,
  price_source = 'manual',
  price_verified_at = NULL,
  notes = 'Prices cleared - please enter actual prices from App Store Connect after verification'
WHERE price_source IS NULL OR price_source = 'manual';

-- Add index for price verification queries
CREATE INDEX IF NOT EXISTS idx_admin_subscription_products_verified
  ON admin_subscription_products(price_verified_at NULLS LAST);

-- Add comment explaining the pricing system
COMMENT ON COLUMN admin_subscription_products.price_usd IS
  'Reference price in USD. Source of truth is App Store/Google Play. Verify via App Store Connect.';

COMMENT ON COLUMN admin_subscription_products.price_sar IS
  'Reference price in SAR. Source of truth is App Store/Google Play. Verify via App Store Connect.';

COMMENT ON COLUMN admin_subscription_products.price_source IS
  'Where the price was verified from: manual (admin entered), app_store, or google_play';

COMMENT ON COLUMN admin_subscription_products.price_verified_at IS
  'When the price was last verified against the actual store pricing';

COMMENT ON COLUMN admin_subscription_products.revenuecat_package_id IS
  'The RevenueCat package ID this product belongs to, for sync verification';

COMMENT ON COLUMN admin_subscription_products.notes IS
  'Admin notes about pricing, verification status, or other relevant information';
