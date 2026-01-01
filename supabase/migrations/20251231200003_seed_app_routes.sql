-- Seed Route Categories
INSERT INTO admin_route_categories (category_key, label_ar, label_en, icon, sort_order) VALUES
  ('main', 'الصفحات الرئيسية', 'Main Pages', '🏠', 1),
  ('relatives', 'الأقارب', 'Relatives', '👥', 2),
  ('reminders', 'التذكيرات', 'Reminders', '🔔', 3),
  ('ai', 'الذكاء الاصطناعي', 'AI Assistant', '🤖', 4),
  ('gamification', 'التحفيز والإنجازات', 'Gamification', '🏆', 5),
  ('family', 'العائلة', 'Family', '👨‍👩‍👧‍👦', 6),
  ('notifications', 'الإشعارات', 'Notifications', '🔔', 7),
  ('auth', 'تسجيل الدخول', 'Authentication', '🔐', 8)
ON CONFLICT (category_key) DO UPDATE SET
  label_ar = EXCLUDED.label_ar,
  icon = EXCLUDED.icon,
  sort_order = EXCLUDED.sort_order;

-- Seed App Routes
-- Main routes
INSERT INTO admin_app_routes (path, route_key, label_ar, label_en, icon, category_key, sort_order, is_public, requires_auth) VALUES
  ('/home', 'home', 'الرئيسية', 'Home', '🏠', 'main', 1, false, true),
  ('/relatives', 'relatives', 'الأقارب', 'Relatives', '👥', 'main', 2, false, true),
  ('/achievements', 'achievements', 'الإنجازات', 'Achievements', '🏆', 'main', 3, false, true),
  ('/statistics', 'statistics', 'الإحصائيات', 'Statistics', '📊', 'main', 4, false, true),
  ('/settings', 'settings', 'الإعدادات', 'Settings', '⚙️', 'main', 5, false, true),
  ('/profile', 'profile', 'الملف الشخصي', 'Profile', '👤', 'main', 6, false, true)
ON CONFLICT (route_key) DO UPDATE SET
  label_ar = EXCLUDED.label_ar,
  icon = EXCLUDED.icon,
  sort_order = EXCLUDED.sort_order;

-- Relatives routes
INSERT INTO admin_app_routes (path, route_key, label_ar, label_en, icon, category_key, sort_order, requires_auth, description_ar) VALUES
  ('/relative', 'relative_detail', 'تفاصيل القريب', 'Relative Detail', '👤', 'relatives', 1, true, 'صفحة تفاصيل القريب'),
  ('/add-relative', 'add_relative', 'إضافة قريب', 'Add Relative', '➕', 'relatives', 2, true, 'إضافة قريب جديد'),
  ('/edit-relative', 'edit_relative', 'تعديل قريب', 'Edit Relative', '✏️', 'relatives', 3, true, 'تعديل بيانات القريب'),
  ('/import-contacts', 'import_contacts', 'استيراد جهات الاتصال', 'Import Contacts', '📱', 'relatives', 4, true, 'استيراد الأقارب من جهات الاتصال')
ON CONFLICT (route_key) DO UPDATE SET
  label_ar = EXCLUDED.label_ar,
  icon = EXCLUDED.icon,
  sort_order = EXCLUDED.sort_order;

-- Reminders routes
INSERT INTO admin_app_routes (path, route_key, label_ar, label_en, icon, category_key, sort_order, requires_auth, description_ar) VALUES
  ('/reminders', 'reminders', 'التذكيرات', 'Reminders', '📅', 'reminders', 1, true, 'إدارة جداول التذكير'),
  ('/reminders-due', 'reminders_due', 'التذكيرات المستحقة', 'Due Reminders', '⏰', 'reminders', 2, true, 'التذكيرات التي حان موعدها')
ON CONFLICT (route_key) DO UPDATE SET
  label_ar = EXCLUDED.label_ar,
  icon = EXCLUDED.icon,
  sort_order = EXCLUDED.sort_order;

-- AI routes
INSERT INTO admin_app_routes (path, route_key, label_ar, label_en, icon, category_key, sort_order, requires_auth, requires_premium, feature_id, description_ar) VALUES
  ('/ai-hub', 'ai_hub', 'مركز الذكاء', 'AI Hub', '🧠', 'ai', 1, true, false, NULL, 'مركز خدمات الذكاء الاصطناعي'),
  ('/ai-chat', 'ai_chat', 'المستشار الذكي', 'AI Counselor', '💬', 'ai', 2, true, true, 'ai_chat', 'محادثة مع المستشار واصل'),
  ('/ai-messages', 'ai_messages', 'منشئ الرسائل', 'Message Composer', '✍️', 'ai', 3, true, true, 'message_composer', 'إنشاء رسائل مخصصة'),
  ('/ai-scripts', 'ai_scripts', 'سيناريوهات التواصل', 'Communication Scripts', '📝', 'ai', 4, true, true, 'communication_scripts', 'نصوص جاهزة للمواقف'),
  ('/ai-analysis', 'ai_analysis', 'تحليل العلاقات', 'Relationship Analysis', '📈', 'ai', 5, true, true, 'relationship_analysis', 'تحليل شامل للعلاقات'),
  ('/ai-memories', 'ai_memories', 'الذكريات', 'AI Memories', '🧠', 'ai', 6, true, true, 'ai_chat', 'ذكريات المحادثات'),
  ('/ai-report', 'ai_report', 'التقرير الأسبوعي', 'Weekly Report', '📋', 'ai', 7, true, true, 'weekly_reports', 'تقرير أسبوعي عن التواصل')
ON CONFLICT (route_key) DO UPDATE SET
  label_ar = EXCLUDED.label_ar,
  icon = EXCLUDED.icon,
  sort_order = EXCLUDED.sort_order,
  requires_premium = EXCLUDED.requires_premium,
  feature_id = EXCLUDED.feature_id;

-- Gamification routes
INSERT INTO admin_app_routes (path, route_key, label_ar, label_en, icon, category_key, sort_order, requires_auth, description_ar) VALUES
  ('/badges', 'badges', 'الأوسمة', 'Badges', '🎖️', 'gamification', 1, true, 'الأوسمة المحققة والمتاحة'),
  ('/detailed-stats', 'detailed_stats', 'إحصائيات تفصيلية', 'Detailed Statistics', '📉', 'gamification', 2, true, 'إحصائيات مفصلة عن التواصل'),
  ('/leaderboard', 'leaderboard', 'لوحة المتصدرين', 'Leaderboard', '🏅', 'gamification', 3, true, 'ترتيب المستخدمين')
ON CONFLICT (route_key) DO UPDATE SET
  label_ar = EXCLUDED.label_ar,
  icon = EXCLUDED.icon,
  sort_order = EXCLUDED.sort_order;

-- Family routes
INSERT INTO admin_app_routes (path, route_key, label_ar, label_en, icon, category_key, sort_order, requires_auth, description_ar) VALUES
  ('/family-tree', 'family_tree', 'شجرة العائلة', 'Family Tree', '🌳', 'family', 1, true, 'عرض شجرة العائلة التفاعلية')
ON CONFLICT (route_key) DO UPDATE SET
  label_ar = EXCLUDED.label_ar,
  icon = EXCLUDED.icon,
  sort_order = EXCLUDED.sort_order;

-- Notifications routes
INSERT INTO admin_app_routes (path, route_key, label_ar, label_en, icon, category_key, sort_order, requires_auth, description_ar) VALUES
  ('/notifications', 'notifications', 'الإشعارات', 'Notifications', '🔔', 'notifications', 1, true, 'إشعارات التطبيق'),
  ('/notification-history', 'notification_history', 'سجل الإشعارات', 'Notification History', '📜', 'notifications', 2, true, 'سجل الإشعارات السابقة')
ON CONFLICT (route_key) DO UPDATE SET
  label_ar = EXCLUDED.label_ar,
  icon = EXCLUDED.icon,
  sort_order = EXCLUDED.sort_order;

-- Auth routes (public, for reference)
INSERT INTO admin_app_routes (path, route_key, label_ar, label_en, icon, category_key, sort_order, is_public, requires_auth, is_active) VALUES
  ('/', 'splash', 'شاشة البداية', 'Splash', '✨', 'auth', 1, true, false, false),
  ('/onboarding', 'onboarding', 'التعريف', 'Onboarding', '👋', 'auth', 2, true, false, false),
  ('/login', 'login', 'تسجيل الدخول', 'Login', '🔑', 'auth', 3, true, false, false),
  ('/signup', 'signup', 'إنشاء حساب', 'Sign Up', '📝', 'auth', 4, true, false, false),
  ('/email-verification', 'email_verification', 'تأكيد البريد', 'Email Verification', '📧', 'auth', 5, true, false, false)
ON CONFLICT (route_key) DO UPDATE SET
  label_ar = EXCLUDED.label_ar,
  icon = EXCLUDED.icon,
  sort_order = EXCLUDED.sort_order,
  is_active = EXCLUDED.is_active;
