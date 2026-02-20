-- Lock down subscription_status: only service_role can write subscription columns
-- Fixes: C1 (RPC exploit) and C2 (direct column update)

-- 1. Revoke EXECUTE on dangerous SECURITY DEFINER functions from authenticated users
REVOKE EXECUTE ON FUNCTION update_user_subscription FROM authenticated;
REVOKE EXECUTE ON FUNCTION start_user_trial FROM authenticated;
REVOKE EXECUTE ON FUNCTION end_user_trial FROM authenticated;
REVOKE EXECUTE ON FUNCTION log_subscription_event FROM authenticated;

-- 2. Create a trigger function that prevents users from modifying subscription columns
CREATE OR REPLACE FUNCTION prevent_subscription_column_update()
RETURNS TRIGGER AS $$
BEGIN
  -- Only service_role can modify subscription columns
  IF current_setting('request.jwt.claim.role', true) != 'service_role' THEN
    -- Preserve the old subscription values — ignore whatever the client sent
    NEW.subscription_status := OLD.subscription_status;
    NEW.subscription_product_id := OLD.subscription_product_id;
    NEW.subscription_expires_at := OLD.subscription_expires_at;
    NEW.trial_started_at := OLD.trial_started_at;
    NEW.trial_used := OLD.trial_used;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach trigger BEFORE UPDATE so subscription columns are always preserved
DROP TRIGGER IF EXISTS guard_subscription_columns ON users;
CREATE TRIGGER guard_subscription_columns
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION prevent_subscription_column_update();

-- 3. Tighten subscription_events INSERT policy: service_role only
DROP POLICY IF EXISTS "Service role can insert subscription events" ON subscription_events;
CREATE POLICY "Service role can insert subscription events"
  ON subscription_events FOR INSERT
  WITH CHECK (auth.role() = 'service_role');
