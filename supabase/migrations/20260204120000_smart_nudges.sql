-- =====================================================
-- Smart Nudges: Intelligent, Admin-Driven Push Notifications
-- =====================================================
-- Extends admin_notification_templates with gap-aware nudge support
-- Creates nudge_history for cooldown enforcement and template rotation

-- 1. Add 'nudge' to category CHECK constraint
ALTER TABLE admin_notification_templates
  DROP CONSTRAINT IF EXISTS admin_notification_templates_category_check;

ALTER TABLE admin_notification_templates
  ADD CONSTRAINT admin_notification_templates_category_check
  CHECK (category IN ('reminder', 'streak', 'badge', 'level', 'challenge', 'system', 'promotional', 'nudge'));

-- 2. Add nudge-specific columns to admin_notification_templates
ALTER TABLE admin_notification_templates
  ADD COLUMN IF NOT EXISTS gap_min_days INTEGER,
  ADD COLUMN IF NOT EXISTS gap_max_days INTEGER,
  ADD COLUMN IF NOT EXISTS gender TEXT CHECK (gender IN ('male', 'female')),
  ADD COLUMN IF NOT EXISTS nudge_cooldown_hours INTEGER DEFAULT 72;

-- Index for nudge template lookups
CREATE INDEX IF NOT EXISTS idx_admin_notification_templates_nudge
  ON admin_notification_templates(category, gap_min_days, gap_max_days, gender)
  WHERE category = 'nudge' AND is_active = true;

-- 3. Create nudge_history table
CREATE TABLE IF NOT EXISTS nudge_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  relative_id UUID NOT NULL REFERENCES relatives(id) ON DELETE CASCADE,
  template_key TEXT NOT NULL,
  gap_days INTEGER NOT NULL,
  sent_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes for cooldown checks and daily cap
CREATE INDEX IF NOT EXISTS idx_nudge_history_user_relative
  ON nudge_history(user_id, relative_id, sent_at DESC);

CREATE INDEX IF NOT EXISTS idx_nudge_history_user_sent
  ON nudge_history(user_id, sent_at DESC);

-- RLS
ALTER TABLE nudge_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own nudge history"
  ON nudge_history FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Service role can manage nudge history"
  ON nudge_history FOR ALL
  USING (true)
  WITH CHECK (true);

-- 4. Seed initial nudge templates
-- Gentle tier: 3-6 days
INSERT INTO admin_notification_templates (template_key, title_ar, body_ar, category, variables, gap_min_days, gap_max_days, gender, nudge_cooldown_hours) VALUES
  ('nudge_gentle_m_1', 'صِلني 💚', '{{relative_label}} له {{days}} أيام ما سمع صوتك', 'nudge', '["relative_label", "days"]', 3, 6, 'male', 72),
  ('nudge_gentle_f_1', 'صِلني 💚', '{{relative_label}} لها {{days}} أيام ما سمعت صوتك', 'nudge', '["relative_label", "days"]', 3, 6, 'female', 72),
  ('nudge_gentle_m_2', 'صِلني 💚', 'وش أخبار {{relative_label}}؟ له {{days}} أيام', 'nudge', '["relative_label", "days"]', 3, 6, 'male', 72),
  ('nudge_gentle_f_2', 'صِلني 💚', 'وش أخبار {{relative_label}}؟ لها {{days}} أيام', 'nudge', '["relative_label", "days"]', 3, 6, 'female', 72),
  ('nudge_gentle_m_3', 'صِلني 💚', '{{relative_label}} يسلم عليك', 'nudge', '["relative_label"]', 3, 6, 'male', 72),
  ('nudge_gentle_f_3', 'صِلني 💚', '{{relative_label}} تسلم عليك', 'nudge', '["relative_label"]', 3, 6, 'female', 72),

-- Moderate tier: 7-13 days
  ('nudge_moderate_m_1', 'صِلني 💛', '{{relative_label}} له أسبوع ما حد كلمه', 'nudge', '["relative_label"]', 7, 13, 'male', 72),
  ('nudge_moderate_f_1', 'صِلني 💛', '{{relative_label}} لها أسبوع ما حد كلمها', 'nudge', '["relative_label"]', 7, 13, 'female', 72),
  ('nudge_moderate_m_2', 'صِلني 💛', '{{relative_label}} يمكن يحتاج يسمع صوتك، له {{days}} يوم', 'nudge', '["relative_label", "days"]', 7, 13, 'male', 72),
  ('nudge_moderate_f_2', 'صِلني 💛', '{{relative_label}} يمكن تحتاج تسمع صوتك، لها {{days}} يوم', 'nudge', '["relative_label", "days"]', 7, 13, 'female', 72),
  ('nudge_moderate_m_3', 'صِلني 💛', 'ما كلمت {{relative_label}} من {{days}} يوم', 'nudge', '["relative_label", "days"]', 7, 13, 'male', 72),
  ('nudge_moderate_f_3', 'صِلني 💛', 'ما كلمت {{relative_label}} من {{days}} يوم', 'nudge', '["relative_label", "days"]', 7, 13, 'female', 72),

-- Direct tier: 14-29 days
  ('nudge_direct_m_1', 'صِلني 🧡', '{{relative_label}} له أسبوعين ما سمع صوتك', 'nudge', '["relative_label"]', 14, 29, 'male', 48),
  ('nudge_direct_f_1', 'صِلني 🧡', '{{relative_label}} لها أسبوعين ما سمعت صوتك', 'nudge', '["relative_label"]', 14, 29, 'female', 48),
  ('nudge_direct_m_2', 'صِلني 🧡', '{{relative_label}} ينتظر اتصالك، له {{days}} يوم', 'nudge', '["relative_label", "days"]', 14, 29, 'male', 48),
  ('nudge_direct_f_2', 'صِلني 🧡', '{{relative_label}} تنتظر اتصالك، لها {{days}} يوم', 'nudge', '["relative_label", "days"]', 14, 29, 'female', 48),
  ('nudge_direct_m_3', 'صِلني 🧡', 'طولت على {{relative_label}}، له {{days}} يوم', 'nudge', '["relative_label", "days"]', 14, 29, 'male', 48),
  ('nudge_direct_f_3', 'صِلني 🧡', 'طولت على {{relative_label}}، لها {{days}} يوم', 'nudge', '["relative_label", "days"]', 14, 29, 'female', 48),

-- Heavy tier: 30+ days
  ('nudge_heavy_m_1', 'صِلني ❤️', 'آخر مرة كلمت {{relative_label}} كان قبل شهر', 'nudge', '["relative_label"]', 30, 999, 'male', 24),
  ('nudge_heavy_f_1', 'صِلني ❤️', 'آخر مرة كلمت {{relative_label}} كان قبل شهر', 'nudge', '["relative_label"]', 30, 999, 'female', 24),
  ('nudge_heavy_m_2', 'صِلني ❤️', '{{relative_label}} له أكثر من شهر ما سمع منك', 'nudge', '["relative_label"]', 30, 999, 'male', 24),
  ('nudge_heavy_f_2', 'صِلني ❤️', '{{relative_label}} لها أكثر من شهر ما سمعت منك', 'nudge', '["relative_label"]', 30, 999, 'female', 24),
  ('nudge_heavy_m_3', 'صِلني ❤️', 'صلة الرحم مع {{relative_label}} محتاجة اهتمام، له {{days}} يوم', 'nudge', '["relative_label", "days"]', 30, 999, 'male', 24),
  ('nudge_heavy_f_3', 'صِلني ❤️', 'صلة الرحم مع {{relative_label}} محتاجة اهتمام، لها {{days}} يوم', 'nudge', '["relative_label", "days"]', 30, 999, 'female', 24)
ON CONFLICT (template_key) DO NOTHING;
