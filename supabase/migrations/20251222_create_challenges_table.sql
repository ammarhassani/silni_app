-- Migration: Create Daily Challenges table
-- Date: 2024-12-22
-- Description: Table for AI-generated daily connection challenges

CREATE TABLE IF NOT EXISTS daily_challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  relative_id UUID REFERENCES relatives(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  challenge_type TEXT NOT NULL DEFAULT 'call', -- 'call', 'message', 'visit', 'memory', 'gratitude', 'check_in'
  difficulty TEXT NOT NULL DEFAULT 'easy', -- 'easy', 'medium', 'meaningful'
  points INTEGER DEFAULT 10,
  status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'accepted', 'completed', 'skipped', 'expired'
  scheduled_date DATE NOT NULL DEFAULT CURRENT_DATE,
  completed_at TIMESTAMPTZ,
  interaction_id UUID REFERENCES interactions(id) ON DELETE SET NULL, -- linked interaction when completed
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Challenge history for achievements
CREATE TABLE IF NOT EXISTS challenge_streaks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  total_completed INTEGER DEFAULT 0,
  last_completed_date DATE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_daily_challenges_user_id ON daily_challenges(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_challenges_scheduled_date ON daily_challenges(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_daily_challenges_status ON daily_challenges(status);
CREATE INDEX IF NOT EXISTS idx_challenge_streaks_user_id ON challenge_streaks(user_id);

-- RLS
ALTER TABLE daily_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenge_streaks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own challenges"
  ON daily_challenges FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own challenges"
  ON daily_challenges FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own challenges"
  ON daily_challenges FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can view own challenge streaks"
  ON challenge_streaks FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own challenge streaks"
  ON challenge_streaks FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own challenge streaks"
  ON challenge_streaks FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

-- Function to update streak on challenge completion
CREATE OR REPLACE FUNCTION update_challenge_streak()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
    INSERT INTO challenge_streaks (user_id, current_streak, longest_streak, total_completed, last_completed_date)
    VALUES (NEW.user_id, 1, 1, 1, CURRENT_DATE)
    ON CONFLICT (user_id) DO UPDATE SET
      current_streak = CASE
        WHEN challenge_streaks.last_completed_date = CURRENT_DATE - 1 THEN challenge_streaks.current_streak + 1
        WHEN challenge_streaks.last_completed_date = CURRENT_DATE THEN challenge_streaks.current_streak
        ELSE 1
      END,
      longest_streak = GREATEST(
        challenge_streaks.longest_streak,
        CASE
          WHEN challenge_streaks.last_completed_date = CURRENT_DATE - 1 THEN challenge_streaks.current_streak + 1
          ELSE 1
        END
      ),
      total_completed = challenge_streaks.total_completed + 1,
      last_completed_date = CURRENT_DATE,
      updated_at = now();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_challenge_complete ON daily_challenges;
CREATE TRIGGER on_challenge_complete
  AFTER UPDATE ON daily_challenges
  FOR EACH ROW
  EXECUTE FUNCTION update_challenge_streak();

-- Comments
COMMENT ON TABLE daily_challenges IS 'AI-generated daily connection challenges for gamification';
COMMENT ON TABLE challenge_streaks IS 'User streak data for daily challenges';
COMMENT ON COLUMN daily_challenges.challenge_type IS 'Type: call, message, visit, memory, gratitude, check_in';
COMMENT ON COLUMN daily_challenges.difficulty IS 'Difficulty level: easy, medium, meaningful';
