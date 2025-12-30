-- Premium Onboarding Tracking Migration
-- Adds support for tracking premium onboarding progress and analytics

-- =====================================================
-- Add onboarding metadata column to users table
-- =====================================================

-- Add the onboarding_metadata column if it doesn't exist
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS onboarding_metadata JSONB DEFAULT '{}';

-- Add comment for documentation
COMMENT ON COLUMN users.onboarding_metadata IS
  'Stores premium onboarding progress: hasStarted, isCompleted, stepProgress, viewedScreens, etc.';

-- Create index for querying users by onboarding completion status
CREATE INDEX IF NOT EXISTS idx_users_onboarding_completed
  ON users ((onboarding_metadata->>'isCompleted'));

-- =====================================================
-- Create onboarding_events table for analytics
-- =====================================================

CREATE TABLE IF NOT EXISTS onboarding_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  step_id TEXT,
  step_index INTEGER,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Add comments for documentation
COMMENT ON TABLE onboarding_events IS
  'Tracks all premium onboarding-related events for analytics and optimization';

COMMENT ON COLUMN onboarding_events.event_type IS
  'Event types: onboarding_started, step_viewed, step_completed, step_skipped, showcase_skipped, onboarding_completed, tip_shown, tip_dismissed';

COMMENT ON COLUMN onboarding_events.step_id IS
  'Step identifier: ai_counselor, message_composer, communication_scripts, relationship_analysis, smart_reminders_ai, weekly_reports';

-- =====================================================
-- Indexes for efficient querying
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_onboarding_events_user_id
  ON onboarding_events(user_id);

CREATE INDEX IF NOT EXISTS idx_onboarding_events_event_type
  ON onboarding_events(event_type);

CREATE INDEX IF NOT EXISTS idx_onboarding_events_created_at
  ON onboarding_events(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_onboarding_events_step_id
  ON onboarding_events(step_id) WHERE step_id IS NOT NULL;

-- =====================================================
-- Row Level Security (RLS) Policies
-- =====================================================

ALTER TABLE onboarding_events ENABLE ROW LEVEL SECURITY;

-- Users can view their own onboarding events
CREATE POLICY "Users can view own onboarding events"
  ON onboarding_events FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own onboarding events
CREATE POLICY "Users can insert own onboarding events"
  ON onboarding_events FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- Analytics Function
-- =====================================================

-- Function to get onboarding analytics summary
CREATE OR REPLACE FUNCTION get_onboarding_analytics(
  p_start_date TIMESTAMPTZ DEFAULT NULL,
  p_end_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
  total_started BIGINT,
  total_completed BIGINT,
  completion_rate NUMERIC,
  avg_completion_time_seconds NUMERIC,
  showcase_skip_rate NUMERIC,
  most_completed_step TEXT,
  least_completed_step TEXT
) AS $$
BEGIN
  RETURN QUERY
  WITH date_filtered AS (
    SELECT *
    FROM onboarding_events
    WHERE (p_start_date IS NULL OR created_at >= p_start_date)
      AND (p_end_date IS NULL OR created_at <= p_end_date)
  ),
  stats AS (
    SELECT
      COUNT(DISTINCT CASE WHEN event_type = 'onboarding_started' THEN user_id END) as started,
      COUNT(DISTINCT CASE WHEN event_type = 'onboarding_completed' THEN user_id END) as completed,
      COUNT(DISTINCT CASE WHEN event_type = 'showcase_skipped' THEN user_id END) as skipped
    FROM date_filtered
  ),
  time_stats AS (
    SELECT
      AVG(EXTRACT(EPOCH FROM (completed_ev.created_at - started_ev.created_at))) as avg_time
    FROM date_filtered started_ev
    JOIN date_filtered completed_ev ON started_ev.user_id = completed_ev.user_id
    WHERE started_ev.event_type = 'onboarding_started'
      AND completed_ev.event_type = 'onboarding_completed'
  ),
  step_completion AS (
    SELECT
      step_id,
      COUNT(*) as completion_count
    FROM date_filtered
    WHERE event_type = 'step_completed' AND step_id IS NOT NULL
    GROUP BY step_id
  ),
  most_completed AS (
    SELECT step_id FROM step_completion ORDER BY completion_count DESC LIMIT 1
  ),
  least_completed AS (
    SELECT step_id FROM step_completion ORDER BY completion_count ASC LIMIT 1
  )
  SELECT
    stats.started,
    stats.completed,
    CASE WHEN stats.started > 0
      THEN ROUND((stats.completed::NUMERIC / stats.started) * 100, 2)
      ELSE 0
    END as completion_rate,
    COALESCE(ROUND(time_stats.avg_time, 0), 0) as avg_completion_time,
    CASE WHEN stats.started > 0
      THEN ROUND((stats.skipped::NUMERIC / stats.started) * 100, 2)
      ELSE 0
    END as showcase_skip_rate,
    (SELECT step_id FROM most_completed) as most_completed_step,
    (SELECT step_id FROM least_completed) as least_completed_step
  FROM stats
  CROSS JOIN time_stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_onboarding_analytics TO authenticated;

-- =====================================================
-- Function to get step-by-step analytics
-- =====================================================

CREATE OR REPLACE FUNCTION get_step_analytics(
  p_start_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
  step_id TEXT,
  times_viewed BIGINT,
  times_completed BIGINT,
  times_skipped BIGINT,
  completion_rate NUMERIC,
  avg_time_spent_seconds NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    e.step_id,
    COUNT(*) FILTER (WHERE e.event_type = 'step_viewed') as times_viewed,
    COUNT(*) FILTER (WHERE e.event_type = 'step_completed') as times_completed,
    COUNT(*) FILTER (WHERE e.event_type = 'step_skipped') as times_skipped,
    CASE
      WHEN COUNT(*) FILTER (WHERE e.event_type = 'step_viewed') > 0
      THEN ROUND(
        (COUNT(*) FILTER (WHERE e.event_type = 'step_completed')::NUMERIC /
         COUNT(*) FILTER (WHERE e.event_type = 'step_viewed')) * 100,
        2
      )
      ELSE 0
    END as completion_rate,
    COALESCE(AVG((e.metadata->>'timeSpentSeconds')::NUMERIC), 0) as avg_time_spent
  FROM onboarding_events e
  WHERE e.step_id IS NOT NULL
    AND (p_start_date IS NULL OR e.created_at >= p_start_date)
  GROUP BY e.step_id
  ORDER BY times_viewed DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_step_analytics TO authenticated;
