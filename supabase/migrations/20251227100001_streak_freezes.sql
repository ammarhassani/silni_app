-- Streak Freeze System
-- Allows users to protect their streaks from breaking

-- Freeze Inventory Table
CREATE TABLE IF NOT EXISTS streak_freezes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL UNIQUE,
    freeze_count INTEGER DEFAULT 0,
    freezes_used_total INTEGER DEFAULT 0,
    last_earned_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Freeze Usage History Table
CREATE TABLE IF NOT EXISTS freeze_usage_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    freeze_type TEXT NOT NULL, -- 'earned', 'purchased', 'auto_used', 'manual_used'
    streak_at_time INTEGER,
    relative_id UUID REFERENCES relatives(id) ON DELETE SET NULL,
    source TEXT, -- 'milestone_7', 'milestone_30', 'milestone_100', 'purchase'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add freeze settings to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS freeze_auto_use BOOLEAN DEFAULT TRUE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS streak_warning_sent BOOLEAN DEFAULT FALSE;

-- Enable RLS
ALTER TABLE streak_freezes ENABLE ROW LEVEL SECURITY;
ALTER TABLE freeze_usage_history ENABLE ROW LEVEL SECURITY;

-- RLS Policies for streak_freezes
CREATE POLICY "Users can view own freeze inventory"
    ON streak_freezes FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own freeze inventory"
    ON streak_freezes FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own freeze inventory"
    ON streak_freezes FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- RLS Policies for freeze_usage_history
CREATE POLICY "Users can view own freeze history"
    ON freeze_usage_history FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own freeze history"
    ON freeze_usage_history FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_streak_freezes_user ON streak_freezes(user_id);
CREATE INDEX IF NOT EXISTS idx_freeze_history_user ON freeze_usage_history(user_id);
CREATE INDEX IF NOT EXISTS idx_freeze_history_created ON freeze_usage_history(created_at DESC);

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION update_streak_freezes_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_streak_freezes_updated_at
    BEFORE UPDATE ON streak_freezes
    FOR EACH ROW
    EXECUTE FUNCTION update_streak_freezes_updated_at();
