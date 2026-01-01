-- Add action routes to MOTD entries so they link to featured sections
-- This makes the MOTD cards clickable and navigates to relevant features

-- Update existing MOTD entries with action_route
UPDATE admin_motd SET action_route = '/reminders'
WHERE title = 'تذكير' AND message LIKE '%راجعت تذكيراتك%';

UPDATE admin_motd SET action_route = '/ai-hub'
WHERE title = 'نصيحة' AND message LIKE '%المستشار الذكي%';

UPDATE admin_motd SET action_route = '/reminders'
WHERE title = 'تذكير' AND message LIKE '%صلة الرحم من أعظم%';

-- Insert additional MOTD entries with action routes to different features
INSERT INTO admin_motd (title, message, type, icon, action_route, is_active, display_priority) VALUES
  -- AI Features
  ('جرّب المستشار الذكي', 'واصل جاهز لمساعدتك في تحسين علاقاتك الأسرية وحل المشاكل', 'tip', '🤖', '/ai-chat', true, 5),
  ('أنشئ رسائل مميزة', 'استخدم منشئ الرسائل الذكي لكتابة تهاني ورسائل مؤثرة لأقاربك', 'tip', '✍️', '/ai-messages', true, 4),

  -- Reminders
  ('نظّم تواصلك', 'أضف تذكيرات للتواصل مع أقاربك ولا تنسَ أحداً', 'reminder', '📅', '/reminders', true, 3),

  -- Gamification
  ('اكتشف إنجازاتك', 'راجع الأوسمة التي حصلت عليها واستمر في جمع المزيد!', 'motivation', '🏆', '/badges', true, 2),

  -- Family Tree
  ('شجرة العائلة', 'ارسم شجرة عائلتك وتعرف على علاقاتك بشكل أوضح', 'tip', '🌳', '/family-tree', true, 1)
ON CONFLICT DO NOTHING;
