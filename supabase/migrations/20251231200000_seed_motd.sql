-- Seed default Message of the Day entries
-- These provide tips and motivation for users

INSERT INTO admin_motd (title, message, type, icon, is_active, display_priority) VALUES
  -- Tips
  ('نصيحة اليوم', 'تواصل مع أقاربك اليوم، رسالة بسيطة تصنع الفرق كبير في قلوبهم', 'tip', '💡', true, 10),
  ('تذكير', 'صلة الرحم من أعظم الأعمال، ابدأ بمكالمة قصيرة اليوم', 'reminder', '🔔', true, 9),
  ('تحفيز', 'كل تواصل تقوم به يُكتب في ميزان حسناتك، استمر!', 'motivation', '⭐', true, 8),
  ('نصيحة', 'جرّب المستشار الذكي واصل للحصول على نصائح شخصية لتحسين علاقاتك', 'tip', '🤖', true, 7),
  ('تذكير', 'هل راجعت تذكيراتك اليوم؟ ربما هناك قريب ينتظر تواصلك', 'reminder', '📅', true, 6)
ON CONFLICT DO NOTHING;

-- Add comment
COMMENT ON TABLE admin_motd IS 'Message of the Day entries displayed on home screen';
