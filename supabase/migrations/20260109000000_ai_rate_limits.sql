-- Track AI API usage per user per day for rate limiting
CREATE TABLE IF NOT EXISTS ai_rate_limits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  request_count INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, date)
);

-- Index for fast lookups
CREATE INDEX idx_ai_rate_limits_user_date ON ai_rate_limits(user_id, date);

-- RLS
ALTER TABLE ai_rate_limits ENABLE ROW LEVEL SECURITY;

-- Users can only see their own rate limit data
CREATE POLICY "Users can view own rate limits"
  ON ai_rate_limits FOR SELECT
  USING (auth.uid() = user_id);

-- Service role can manage all rate limits (for edge functions)
CREATE POLICY "Service role can manage rate limits"
  ON ai_rate_limits FOR ALL
  USING (auth.role() = 'service_role');
