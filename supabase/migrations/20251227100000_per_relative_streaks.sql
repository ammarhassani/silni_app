-- Per-Relative Streaks Table
-- Tracks individual streaks for each user-relative pair
CREATE TABLE IF NOT EXISTS relative_streaks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    relative_id UUID REFERENCES relatives(id) ON DELETE CASCADE NOT NULL,
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    streak_deadline TIMESTAMPTZ,
    streak_day_start TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, relative_id)
);

-- Enable RLS
ALTER TABLE relative_streaks ENABLE ROW LEVEL SECURITY;

-- RLS Policies - users can only access their own streak data
CREATE POLICY "Users can view own relative streaks"
    ON relative_streaks FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own relative streaks"
    ON relative_streaks FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own relative streaks"
    ON relative_streaks FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own relative streaks"
    ON relative_streaks FOR DELETE
    USING (auth.uid() = user_id);

-- Index for fast lookups by user and deadline (for warning queries)
CREATE INDEX IF NOT EXISTS idx_relative_streaks_user_deadline
    ON relative_streaks(user_id, streak_deadline);

-- Index for looking up specific relative's streak
CREATE INDEX IF NOT EXISTS idx_relative_streaks_user_relative
    ON relative_streaks(user_id, relative_id);

-- Trigger to auto-update updated_at
CREATE OR REPLACE FUNCTION update_relative_streaks_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_relative_streaks_updated_at
    BEFORE UPDATE ON relative_streaks
    FOR EACH ROW
    EXECUTE FUNCTION update_relative_streaks_updated_at();
