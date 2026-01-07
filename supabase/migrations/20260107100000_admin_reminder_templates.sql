-- Admin table for reminder templates
-- These define predefined reminder frequency options shown to users

CREATE TABLE IF NOT EXISTS admin_reminder_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_key TEXT NOT NULL UNIQUE,
  frequency TEXT NOT NULL CHECK (frequency IN ('daily', 'weekly', 'monthly', 'friday', 'custom')),
  title_ar TEXT NOT NULL,
  title_en TEXT,
  description_ar TEXT NOT NULL,
  description_en TEXT,
  suggested_relationships_ar TEXT NOT NULL,
  suggested_relationships_en TEXT,
  default_time TEXT NOT NULL DEFAULT '09:00',
  emoji TEXT NOT NULL DEFAULT '📅',
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add RLS
ALTER TABLE admin_reminder_templates ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read templates
CREATE POLICY "Allow authenticated read on admin_reminder_templates"
ON admin_reminder_templates FOR SELECT
TO authenticated
USING (true);

-- Insert default templates matching the hardcoded ones
INSERT INTO admin_reminder_templates (template_key, frequency, title_ar, title_en, description_ar, description_en, suggested_relationships_ar, suggested_relationships_en, default_time, emoji, sort_order) VALUES
  ('daily', 'daily', 'تذكير يومي', 'Daily Reminder', 'للأقارب الأقرب (الوالدين، الزوج/الزوجة)', 'For closest relatives (parents, spouse)', 'أب، أم، زوج، زوجة', 'Father, Mother, Husband, Wife', '09:00', '📅', 1),
  ('weekly', 'weekly', 'تذكير أسبوعي', 'Weekly Reminder', 'للإخوة والأجداد', 'For siblings and grandparents', 'أخ، أخت، جد، جدة', 'Brother, Sister, Grandfather, Grandmother', '10:00', '📆', 2),
  ('monthly', 'monthly', 'تذكير شهري', 'Monthly Reminder', 'للأعمام والأخوال وأبناء العم', 'For uncles, aunts, and cousins', 'عم، خال، ابن العم، بنت الخالة', 'Uncle, Aunt, Cousin', '11:00', '📋', 3),
  ('friday', 'friday', 'تذكير يوم الجمعة', 'Friday Reminder', 'تواصل خاص يوم الجمعة المبارك', 'Special connection on blessed Friday', 'جميع الأقارب', 'All relatives', '16:00', '🕌', 4)
ON CONFLICT (template_key) DO UPDATE SET
  frequency = EXCLUDED.frequency,
  title_ar = EXCLUDED.title_ar,
  title_en = EXCLUDED.title_en,
  description_ar = EXCLUDED.description_ar,
  description_en = EXCLUDED.description_en,
  suggested_relationships_ar = EXCLUDED.suggested_relationships_ar,
  suggested_relationships_en = EXCLUDED.suggested_relationships_en,
  default_time = EXCLUDED.default_time,
  emoji = EXCLUDED.emoji,
  sort_order = EXCLUDED.sort_order;

-- Add updated_at trigger
CREATE OR REPLACE FUNCTION update_admin_reminder_templates_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER admin_reminder_templates_updated_at
BEFORE UPDATE ON admin_reminder_templates
FOR EACH ROW EXECUTE FUNCTION update_admin_reminder_templates_updated_at();

-- Add cache config entry
INSERT INTO admin_cache_config (service_key, cache_duration_seconds, description, description_ar) VALUES
('reminder_templates', 1800, 'Reminder template configuration', 'إعدادات قوالب التذكيرات')
ON CONFLICT (service_key) DO NOTHING;

COMMENT ON TABLE admin_reminder_templates IS 'Configurable reminder frequency templates shown when users create reminders';
