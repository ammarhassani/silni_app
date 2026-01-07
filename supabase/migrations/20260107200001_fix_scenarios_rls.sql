-- Fix communication scenarios RLS to allow public read (like other admin config tables)
-- And re-seed data since it was missing

-- Drop the overly restrictive policy
DROP POLICY IF EXISTS "Allow authenticated read on admin_communication_scenarios" ON admin_communication_scenarios;

-- Add public read policy (for anon and authenticated users)
CREATE POLICY "Users can read active communication scenarios"
ON admin_communication_scenarios FOR SELECT
USING (is_active = true);

-- Re-seed data (in case it's still missing)
INSERT INTO admin_communication_scenarios (scenario_key, title_ar, title_en, description_ar, description_en, emoji, color_hex, sort_order, is_active) VALUES
  ('apology', 'طلب مسامحة', 'Seeking Forgiveness', 'بعد خلاف أو سوء تفاهم', 'After a disagreement or misunderstanding', '🤝', '#FF9800', 1, true),
  ('congratulation', 'تهنئة', 'Congratulation', 'بمناسبة سعيدة', 'For a happy occasion', '🎉', '#4CAF50', 2, true),
  ('condolence', 'مواساة', 'Condolence', 'في مصيبة أو حزن', 'During grief or hardship', '💐', '#9C27B0', 3, true),
  ('reconnect', 'إعادة تواصل', 'Reconnecting', 'بعد انقطاع طويل', 'After a long absence', '🔄', '#2196F3', 4, true),
  ('gratitude', 'شكر وامتنان', 'Gratitude', 'على معروف أو مساعدة', 'For a favor or help', '🙏', '#009688', 5, true),
  ('sensitive', 'موضوع حساس', 'Sensitive Topic', 'مناقشة أمر صعب', 'Discussing a difficult matter', '💬', '#FFC107', 6, true)
ON CONFLICT (scenario_key) DO UPDATE SET
  title_ar = EXCLUDED.title_ar,
  title_en = EXCLUDED.title_en,
  description_ar = EXCLUDED.description_ar,
  description_en = EXCLUDED.description_en,
  emoji = EXCLUDED.emoji,
  color_hex = EXCLUDED.color_hex,
  sort_order = EXCLUDED.sort_order,
  is_active = EXCLUDED.is_active;
