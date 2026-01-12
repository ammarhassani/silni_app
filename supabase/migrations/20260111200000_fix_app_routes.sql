-- Fix app routes to match Flutter app_routes.dart
-- Clear existing routes and reseed with correct values

-- Delete all existing routes
DELETE FROM admin_app_routes;

-- Reseed Route Categories (ensure they exist)
INSERT INTO admin_route_categories (category_key, label_ar, label_en, icon, sort_order) VALUES
  ('main', 'الصفحات الرئيسية', 'Main Pages', '🏠', 1),
  ('relatives', 'الأقارب', 'Relatives', '👥', 2),
  ('reminders', 'التذكيرات', 'Reminders', '🔔', 3),
  ('ai', 'الذكاء الاصطناعي', 'AI Assistant', '🤖', 4),
  ('gamification', 'التحفيز والإنجازات', 'Gamification', '🏆', 5),
  ('family', 'العائلة', 'Family', '👨‍👩‍👧‍👦', 6),
  ('notifications', 'الإشعارات', 'Notifications', '🔔', 7),
  ('subscription', 'الاشتراك', 'Subscription', '💎', 8)
ON CONFLICT (category_key) DO UPDATE SET
  label_ar = EXCLUDED.label_ar,
  icon = EXCLUDED.icon,
  sort_order = EXCLUDED.sort_order;

-- Main routes (matching Flutter app_routes.dart exactly)
INSERT INTO admin_app_routes (path, route_key, label_ar, label_en, icon, category_key, sort_order, is_active, is_public, requires_auth) VALUES
  ('/home', 'home', 'الرئيسية', 'Home', '🏠', 'main', 1, true, false, true),
  ('/relatives', 'relatives', 'صلة الرحم', 'Relatives', '👥', 'main', 2, true, false, true),
  ('/achievements', 'achievements', 'الإنجازات', 'Achievements', '🏆', 'main', 3, true, false, true),
  ('/statistics', 'statistics', 'الإحصائيات', 'Statistics', '📊', 'main', 4, true, false, true),
  ('/settings', 'settings', 'الإعدادات', 'Settings', '⚙️', 'main', 5, true, false, true),
  ('/profile', 'profile', 'الملف الشخصي', 'Profile', '👤', 'main', 6, true, false, true);

-- Relatives sub-routes
INSERT INTO admin_app_routes (path, route_key, label_ar, label_en, icon, category_key, sort_order, is_active, requires_auth, description_ar) VALUES
  ('/add-relative', 'add_relative', 'إضافة قريب', 'Add Relative', '➕', 'relatives', 1, true, true, 'إضافة قريب جديد'),
  ('/import-contacts', 'import_contacts', 'استيراد جهات الاتصال', 'Import Contacts', '📱', 'relatives', 2, true, true, 'استيراد الأقارب من جهات الاتصال');

-- Reminders routes
INSERT INTO admin_app_routes (path, route_key, label_ar, label_en, icon, category_key, sort_order, is_active, requires_auth, description_ar) VALUES
  ('/reminders', 'reminders', 'التذكيرات', 'Reminders', '📅', 'reminders', 1, true, true, 'إدارة جداول التذكير'),
  ('/reminders-due', 'reminders_due', 'التذكيرات المستحقة', 'Due Reminders', '⏰', 'reminders', 2, true, true, 'التذكيرات التي حان موعدها');

-- AI routes
INSERT INTO admin_app_routes (path, route_key, label_ar, label_en, icon, category_key, sort_order, is_active, requires_auth, requires_premium, feature_id, description_ar) VALUES
  ('/ai-hub', 'ai_hub', 'واصل', 'AI Hub', '🧠', 'ai', 1, true, true, false, NULL, 'مركز خدمات الذكاء الاصطناعي'),
  ('/ai-chat', 'ai_chat', 'المستشار الذكي', 'AI Counselor', '💬', 'ai', 2, true, true, true, 'ai_chat', 'محادثة مع المستشار واصل'),
  ('/ai-messages', 'ai_messages', 'منشئ الرسائل', 'Message Composer', '✍️', 'ai', 3, true, true, true, 'message_composer', 'إنشاء رسائل مخصصة'),
  ('/ai-scripts', 'ai_scripts', 'سيناريوهات التواصل', 'Communication Scripts', '📝', 'ai', 4, true, true, true, 'communication_scripts', 'نصوص جاهزة للمواقف'),
  ('/ai-analysis', 'ai_analysis', 'تحليل العلاقات', 'Relationship Analysis', '📈', 'ai', 5, true, true, true, 'relationship_analysis', 'تحليل شامل للعلاقات'),
  ('/ai-memories', 'ai_memories', 'الذكريات', 'AI Memories', '🧠', 'ai', 6, true, true, true, 'ai_chat', 'ذكريات المحادثات'),
  ('/ai-report', 'ai_report', 'التقرير الأسبوعي', 'Weekly Report', '📋', 'ai', 7, true, true, true, 'weekly_reports', 'تقرير أسبوعي عن التواصل');

-- Gamification routes
INSERT INTO admin_app_routes (path, route_key, label_ar, label_en, icon, category_key, sort_order, is_active, requires_auth, description_ar) VALUES
  ('/badges', 'badges', 'الأوسمة', 'Badges', '🎖️', 'gamification', 1, true, true, 'الأوسمة المحققة والمتاحة'),
  ('/detailed-stats', 'detailed_stats', 'إحصائيات تفصيلية', 'Detailed Statistics', '📉', 'gamification', 2, true, true, 'إحصائيات مفصلة عن التواصل'),
  ('/leaderboard', 'leaderboard', 'لوحة المتصدرين', 'Leaderboard', '🏅', 'gamification', 3, true, true, 'ترتيب المستخدمين'),
  ('/challenges', 'challenges', 'التحديات', 'Challenges', '🎯', 'gamification', 4, true, true, 'تحديات التواصل');

-- Family routes
INSERT INTO admin_app_routes (path, route_key, label_ar, label_en, icon, category_key, sort_order, is_active, requires_auth, description_ar) VALUES
  ('/family-tree', 'family_tree', 'شجرة العائلة', 'Family Tree', '🌳', 'family', 1, true, true, 'عرض شجرة العائلة التفاعلية');

-- Notifications routes
INSERT INTO admin_app_routes (path, route_key, label_ar, label_en, icon, category_key, sort_order, is_active, requires_auth, description_ar) VALUES
  ('/notifications', 'notifications', 'الإشعارات', 'Notifications', '🔔', 'notifications', 1, true, true, 'إشعارات التطبيق'),
  ('/notification-history', 'notification_history', 'سجل الإشعارات', 'Notification History', '📜', 'notifications', 2, true, true, 'سجل الإشعارات السابقة');

-- Subscription routes
INSERT INTO admin_app_routes (path, route_key, label_ar, label_en, icon, category_key, sort_order, is_active, requires_auth, description_ar) VALUES
  ('/paywall', 'paywall', 'الاشتراك', 'Subscription', '💎', 'subscription', 1, true, true, 'شاشة الاشتراك وباقات MAX');
