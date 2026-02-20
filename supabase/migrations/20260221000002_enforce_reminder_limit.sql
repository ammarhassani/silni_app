-- Enforce reminder limit at DB level
-- Free users: limited reminders, Premium users: unlimited

CREATE OR REPLACE FUNCTION enforce_reminder_limit()
RETURNS TRIGGER AS $$
DECLARE
  v_status TEXT;
  v_limit INT;
  v_count INT;
BEGIN
  -- Get user's subscription status
  SELECT subscription_status INTO v_status
  FROM users WHERE id = NEW.user_id;

  -- Premium users have no limit
  IF v_status = 'premium' THEN
    RETURN NEW;
  END IF;

  -- Get dynamic limit from admin config, fallback to 1
  SELECT COALESCE(
    (SELECT reminder_limit FROM admin_subscription_tiers
     WHERE tier_key = 'free' AND is_active = true LIMIT 1),
    1
  ) INTO v_limit;

  -- Count existing active schedules
  SELECT COUNT(*) INTO v_count
  FROM reminder_schedules
  WHERE user_id = NEW.user_id
    AND is_active = true;

  IF v_count >= v_limit THEN
    RAISE EXCEPTION 'Reminder limit reached. Free tier allows % reminders.', v_limit
      USING ERRCODE = 'P0001';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS check_reminder_limit ON reminder_schedules;
CREATE TRIGGER check_reminder_limit
  BEFORE INSERT ON reminder_schedules
  FOR EACH ROW
  EXECUTE FUNCTION enforce_reminder_limit();
