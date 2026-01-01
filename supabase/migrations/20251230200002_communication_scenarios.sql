-- Admin table for communication scenarios (used in AI scripts feature)
-- These define the predefined conversation scenarios users can select

CREATE TABLE IF NOT EXISTS admin_communication_scenarios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scenario_key TEXT NOT NULL UNIQUE,
  title_ar TEXT NOT NULL,
  title_en TEXT,
  description_ar TEXT NOT NULL,
  description_en TEXT,
  emoji TEXT NOT NULL DEFAULT '💬',
  color_hex TEXT NOT NULL DEFAULT '#2196F3',
  prompt_context TEXT, -- Additional context for AI prompt
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add RLS
ALTER TABLE admin_communication_scenarios ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read scenarios
CREATE POLICY "Allow authenticated read on admin_communication_scenarios"
ON admin_communication_scenarios FOR SELECT
TO authenticated
USING (true);

-- Insert default scenarios
INSERT INTO admin_communication_scenarios (scenario_key, title_ar, title_en, description_ar, description_en, emoji, color_hex, sort_order) VALUES
  ('apology', 'طلب مسامحة', 'Seeking Forgiveness', 'بعد خلاف أو سوء تفاهم', 'After a disagreement or misunderstanding', '🤝', '#FF9800', 1),
  ('congratulation', 'تهنئة', 'Congratulation', 'بمناسبة سعيدة', 'For a happy occasion', '🎉', '#4CAF50', 2),
  ('condolence', 'مواساة', 'Condolence', 'في مصيبة أو حزن', 'During grief or hardship', '💐', '#9C27B0', 3),
  ('reconnect', 'إعادة تواصل', 'Reconnecting', 'بعد انقطاع طويل', 'After a long absence', '🔄', '#2196F3', 4),
  ('gratitude', 'شكر وامتنان', 'Gratitude', 'على معروف أو مساعدة', 'For a favor or help', '🙏', '#009688', 5),
  ('sensitive', 'موضوع حساس', 'Sensitive Topic', 'مناقشة أمر صعب', 'Discussing a difficult matter', '💬', '#FFC107', 6)
ON CONFLICT (scenario_key) DO UPDATE SET
  title_ar = EXCLUDED.title_ar,
  title_en = EXCLUDED.title_en,
  description_ar = EXCLUDED.description_ar,
  description_en = EXCLUDED.description_en,
  emoji = EXCLUDED.emoji,
  color_hex = EXCLUDED.color_hex,
  sort_order = EXCLUDED.sort_order;

-- Add updated_at trigger
CREATE OR REPLACE FUNCTION update_admin_communication_scenarios_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER admin_communication_scenarios_updated_at
BEFORE UPDATE ON admin_communication_scenarios
FOR EACH ROW EXECUTE FUNCTION update_admin_communication_scenarios_updated_at();

COMMENT ON TABLE admin_communication_scenarios IS 'Configurable communication scenarios for AI-assisted conversation scripts';
