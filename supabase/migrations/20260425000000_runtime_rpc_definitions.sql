-- Phase 0: Track previously-undeclared RPCs in migrations.
--
-- Both functions exist in production (defined in supabase/schema.sql and
-- supabase/gamification_functions.sql) and are called from the app, but were
-- never tracked in migrations. CREATE OR REPLACE means this is safe to run
-- against an existing database; it also ensures fresh deploys have them.

-- award_points — called from lib/core/services/gamification_service.dart
CREATE OR REPLACE FUNCTION award_points(
  p_user_id UUID,
  p_points INTEGER
)
RETURNS void AS $$
BEGIN
  UPDATE users
  SET
    points = points + p_points,
    total_interactions = total_interactions + 1,
    updated_at = now()
  WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- delete_user_account — called from lib/shared/services/auth_service.dart
-- Cascading delete fires via ON DELETE CASCADE on the users foreign keys.
CREATE OR REPLACE FUNCTION delete_user_account()
RETURNS void AS $$
BEGIN
  DELETE FROM users WHERE id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
