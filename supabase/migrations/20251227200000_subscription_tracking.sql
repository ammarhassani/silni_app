-- Migration: Add subscription tracking for RevenueCat integration
-- Date: 2025-12-26
-- Description: Adds subscription tier tracking, trial management, and analytics

-- =====================================================
-- 1. UPDATE USERS TABLE FOR SUBSCRIPTION TRACKING
-- =====================================================

-- Update subscription_status constraint to support new tiers
-- First, drop the existing constraint if it exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'users_subscription_status_check'
    AND table_name = 'users'
  ) THEN
    ALTER TABLE users DROP CONSTRAINT users_subscription_status_check;
  END IF;
END $$;

-- Add new constraint with updated tiers (only free and premium/max)
ALTER TABLE users ADD CONSTRAINT users_subscription_status_check
  CHECK (subscription_status IN ('free', 'premium'));

-- Add subscription tracking columns
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS subscription_product_id TEXT,
  ADD COLUMN IF NOT EXISTS subscription_expires_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS trial_started_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS trial_used BOOLEAN DEFAULT false;

-- Add comments for documentation
COMMENT ON COLUMN users.subscription_status IS 'Current subscription tier: free or premium (MAX)';
COMMENT ON COLUMN users.subscription_product_id IS 'RevenueCat product ID for the active subscription';
COMMENT ON COLUMN users.subscription_expires_at IS 'Subscription expiration date from RevenueCat';
COMMENT ON COLUMN users.trial_started_at IS 'When the user started their free trial';
COMMENT ON COLUMN users.trial_used IS 'Whether the user has already used their free trial';

-- Create index for subscription queries
CREATE INDEX IF NOT EXISTS idx_users_subscription_status ON users(subscription_status);
CREATE INDEX IF NOT EXISTS idx_users_subscription_expires_at ON users(subscription_expires_at);

-- =====================================================
-- 2. CREATE SUBSCRIPTION EVENTS TABLE FOR ANALYTICS
-- =====================================================

CREATE TABLE IF NOT EXISTS subscription_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  from_tier TEXT,
  to_tier TEXT,
  product_id TEXT,
  revenue_amount DECIMAL(10,2),
  currency TEXT DEFAULT 'USD',
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Add comments for documentation
COMMENT ON TABLE subscription_events IS 'Tracks all subscription-related events for analytics';
COMMENT ON COLUMN subscription_events.event_type IS 'Type of event: purchase, renewal, upgrade, downgrade, cancellation, trial_start, trial_end';
COMMENT ON COLUMN subscription_events.from_tier IS 'Previous subscription tier';
COMMENT ON COLUMN subscription_events.to_tier IS 'New subscription tier';
COMMENT ON COLUMN subscription_events.product_id IS 'RevenueCat product ID involved in the event';
COMMENT ON COLUMN subscription_events.revenue_amount IS 'Revenue from this event (if applicable)';
COMMENT ON COLUMN subscription_events.metadata IS 'Additional event-specific data in JSON format';

-- Create indexes for analytics queries
CREATE INDEX IF NOT EXISTS idx_subscription_events_user_id ON subscription_events(user_id);
CREATE INDEX IF NOT EXISTS idx_subscription_events_event_type ON subscription_events(event_type);
CREATE INDEX IF NOT EXISTS idx_subscription_events_created_at ON subscription_events(created_at DESC);

-- =====================================================
-- 3. ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on subscription_events
ALTER TABLE subscription_events ENABLE ROW LEVEL SECURITY;

-- Users can only view their own subscription events
CREATE POLICY "Users can view own subscription events"
  ON subscription_events FOR SELECT
  USING (auth.uid() = user_id);

-- Only service role can insert subscription events (via webhook or backend)
CREATE POLICY "Service role can insert subscription events"
  ON subscription_events FOR INSERT
  WITH CHECK (auth.role() = 'service_role' OR auth.uid() = user_id);

-- =====================================================
-- 4. HELPER FUNCTIONS
-- =====================================================

-- Function to log subscription events
CREATE OR REPLACE FUNCTION log_subscription_event(
  p_user_id UUID,
  p_event_type TEXT,
  p_from_tier TEXT DEFAULT NULL,
  p_to_tier TEXT DEFAULT NULL,
  p_product_id TEXT DEFAULT NULL,
  p_revenue_amount DECIMAL DEFAULT NULL,
  p_currency TEXT DEFAULT 'USD',
  p_metadata JSONB DEFAULT '{}'
) RETURNS UUID AS $$
DECLARE
  event_id UUID;
BEGIN
  INSERT INTO subscription_events (
    user_id, event_type, from_tier, to_tier,
    product_id, revenue_amount, currency, metadata
  ) VALUES (
    p_user_id, p_event_type, p_from_tier, p_to_tier,
    p_product_id, p_revenue_amount, p_currency, p_metadata
  ) RETURNING id INTO event_id;

  RETURN event_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update user subscription status
CREATE OR REPLACE FUNCTION update_user_subscription(
  p_user_id UUID,
  p_status TEXT,
  p_product_id TEXT DEFAULT NULL,
  p_expires_at TIMESTAMPTZ DEFAULT NULL
) RETURNS VOID AS $$
DECLARE
  v_old_status TEXT;
BEGIN
  -- Get current status for event logging
  SELECT subscription_status INTO v_old_status
  FROM users WHERE id = p_user_id;

  -- Update user subscription
  UPDATE users SET
    subscription_status = p_status,
    subscription_product_id = COALESCE(p_product_id, subscription_product_id),
    subscription_expires_at = p_expires_at,
    updated_at = now()
  WHERE id = p_user_id;

  -- Log the event if status changed
  IF v_old_status IS DISTINCT FROM p_status THEN
    PERFORM log_subscription_event(
      p_user_id,
      CASE
        WHEN v_old_status = 'free' AND p_status = 'premium' THEN 'purchase'
        WHEN p_status = 'free' THEN 'cancellation'
        ELSE 'status_change'
      END,
      v_old_status,
      p_status,
      p_product_id
    );
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to start trial
CREATE OR REPLACE FUNCTION start_user_trial(p_user_id UUID) RETURNS BOOLEAN AS $$
DECLARE
  v_trial_used BOOLEAN;
BEGIN
  -- Check if trial already used
  SELECT trial_used INTO v_trial_used
  FROM users WHERE id = p_user_id;

  IF v_trial_used = true THEN
    RETURN false;
  END IF;

  -- Start trial
  UPDATE users SET
    subscription_status = 'premium',
    trial_started_at = now(),
    updated_at = now()
  WHERE id = p_user_id;

  -- Log trial start event
  PERFORM log_subscription_event(p_user_id, 'trial_start', 'free', 'premium');

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to end trial
CREATE OR REPLACE FUNCTION end_user_trial(p_user_id UUID) RETURNS VOID AS $$
BEGIN
  UPDATE users SET
    subscription_status = 'free',
    trial_used = true,
    updated_at = now()
  WHERE id = p_user_id
  AND trial_started_at IS NOT NULL
  AND subscription_product_id IS NULL;

  -- Log trial end event
  PERFORM log_subscription_event(p_user_id, 'trial_end', 'premium', 'free');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 5. GRANT PERMISSIONS
-- =====================================================

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION log_subscription_event TO authenticated;
GRANT EXECUTE ON FUNCTION update_user_subscription TO authenticated;
GRANT EXECUTE ON FUNCTION start_user_trial TO authenticated;
GRANT EXECUTE ON FUNCTION end_user_trial TO authenticated;
