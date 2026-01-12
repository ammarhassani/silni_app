-- Sync app routes between staging and production
-- This migration ensures both environments have the same complete set of routes

-- First, ensure all route categories exist
INSERT INTO admin_route_categories (category_key, label_ar, label_en, icon, sort_order, is_active) VALUES
  ('main', 'الصفحات الرئيسية', 'Main Pages', '🏠', 1, true),
  ('relatives', 'الأقارب', 'Relatives', '👥', 2, true),
  ('reminders', 'التذكيرات', 'Reminders', '🔔', 3, true),
  ('ai', 'الذكاء الاصطناعي', 'AI Assistant', '🤖', 4, true),
  ('gamification', 'التحفيز والإنجازات', 'Gamification', '🏆', 5, true),
  ('settings', 'الإعدادات', 'Settings', '⚙️', 6, true),
  ('family', 'العائلة', 'Family', '👨‍👩‍👧‍👦', 7, true),
  ('notifications', 'الإشعارات', 'Notifications', '🔔', 8, true),
  ('auth', 'تسجيل الدخول', 'Authentication', '🔐', 9, true),
  ('subscription', 'الاشتراك', 'Subscription', '💎', 10, true)
ON CONFLICT (category_key) DO UPDATE SET
  label_ar = EXCLUDED.label_ar,
  label_en = EXCLUDED.label_en,
  icon = EXCLUDED.icon,
  sort_order = EXCLUDED.sort_order;

-- Insert all routes (using ON CONFLICT to avoid duplicates)
-- Main routes
INSERT INTO admin_app_routes (path, route_key, label_ar, label_en, icon, category_key, sort_order, is_active, is_public, requires_auth, requires_premium) VALUES
  ('/', 'splash', 'البداية', 'Splash', '🚀', 'main', 0, true, true, false, false),
  ('/onboarding', 'onboarding', 'التعريف', 'Onboarding', '👋', 'main', 1, true, true, false, false),
  ('/home', 'home', 'الرئيسية', 'Home', '🏠', 'main', 2, true, false, true, false),
  ('/achievements', 'achievements', 'الإنجازات', 'Achievements', '🏆', 'main', 3, true, false, true, false),
  ('/statistics', 'statistics', 'الإحصائيات', 'Statistics', '📊', 'main', 4, true, false, true, false)
ON CONFLICT (path) DO UPDATE SET
  label_ar = EXCLUDED.label_ar,
  label_en = EXCLUDED.label_en,
  icon = EXCLUDED.icon,
  category_key = EXCLUDED.category_key,
  sort_order = EXCLUDED.sort_order;

-- Auth routes
INSERT INTO admin_app_routes (path, route_key, label_ar, label_en, icon, category_key, sort_order, is_active, is_public, requires_auth, requires_premium) VALUES
  ('/login', 'login', 'تسجيل الدخول', 'Login', '🔑', 'auth', 1, true, true, false, false),
  ('/signup', 'signup', 'إنشاء حساب', 'Sign Up', '📝', 'auth', 2, true, true, false, false),
  ('/email-verification', 'email_verification', 'تأكيد البريد', 'Email Verification', '✉️', 'auth', 3, true, true, false, false),
  ('/reset-password', 'reset_password', 'استعادة كلمة المرور', 'Reset Password', '🔒', 'auth', 4, true, true, false, false)
ON CONFLICT (path) DO UPDATE SET
  label_ar = EXCLUDED.label_ar,
  label_en = EXCLUDED.label_en,
  icon = EXCLUDED.icon,
  category_key = EXCLUDED.category_key,
  sort_order = EXCLUDED.sort_order;

-- Relatives routes
INSERT INTO admin_app_routes (path, route_key, label_ar, label_en, icon, category_key, sort_order, is_active, is_public, requires_auth, requires_premium, description_ar) VALUES
  ('/relatives', 'relatives', 'الأقارب', 'Relatives', '👥', 'relatives', 1, true, false, true, false, 'قائمة الأقارب'),
  ('/add-relative', 'add_relative', 'إضافة قريب', 'Add Relative', '➕', 'relatives', 2, true, false, true, false, 'إضافة قريب جديد'),
  ('/relative/:id', 'relative_detail', 'تفاصيل القريب', 'Relative Detail', '👤', 'relatives', 3, true, false, true, false, 'صفحة تفاصيل القريب'),
  ('/edit-relative/:id', 'edit_relative', 'تعديل قريب', 'Edit Relative', '✏️', 'relatives', 4, true, false, true, false, 'تعديل بيانات القريب'),
  ('/import-contacts', 'import_contacts', 'استيراد جهات الاتصال', 'Import Contacts', '📱', 'relatives', 5, true, false, true, false, 'استيراد الأقارب من جهات الاتصال'),
  ('/family-tree', 'family_tree', 'شجرة العائلة', 'Family Tree', '🌳', 'relatives', 6, true, false, true, false, 'عرض شجرة العائلة التفاعلية')
ON CONFLICT (path) DO UPDATE SET
  label_ar = EXCLUDED.label_ar,
  label_en = EXCLUDED.label_en,
  icon = EXCLUDED.icon,
  category_key = EXCLUDED.category_key,
  sort_order = EXCLUDED.sort_order,
  description_ar = EXCLUDED.description_ar;

-- Reminders routes
INSERT INTO admin_app_routes (path, route_key, label_ar, label_en, icon, category_key, sort_order, is_active, is_public, requires_auth, requires_premium, description_ar) VALUES
  ('/reminders', 'reminders', 'التذكيرات', 'Reminders', '📅', 'reminders', 1, true, false, true, false, 'إدارة جداول التذكير'),
  ('/reminders-due', 'reminders_due', 'التذكيرات المستحقة', 'Due Reminders', '⏰', 'reminders', 2, true, false, true, false, 'التذكيرات التي حان موعدها')
ON CONFLICT (path) DO UPDATE SET
  label_ar = EXCLUDED.label_ar,
  label_en = EXCLUDED.label_en,
  icon = EXCLUDED.icon,
  category_key = EXCLUDED.category_key,
  sort_order = EXCLUDED.sort_order,
  description_ar = EXCLUDED.description_ar;

-- AI routes
INSERT INTO admin_app_routes (path, route_key, label_ar, label_en, icon, category_key, sort_order, is_active, is_public, requires_auth, requires_premium, feature_id, description_ar) VALUES
  ('/ai-hub', 'ai_hub', 'واصل', 'AI Hub', '🧠', 'ai', 1, true, false, true, false, NULL, 'مركز خدمات الذكاء الاصطناعي'),
  ('/ai-chat', 'ai_chat', 'المستشار الذكي', 'AI Counselor', '💬', 'ai', 2, true, false, true, true, 'ai_chat', 'محادثة مع المستشار واصل'),
  ('/ai-messages', 'ai_messages', 'منشئ الرسائل', 'Message Composer', '✍️', 'ai', 3, true, false, true, true, 'message_composer', 'إنشاء رسائل مخصصة'),
  ('/ai-scripts', 'ai_scripts', 'سيناريوهات التواصل', 'Communication Scripts', '📝', 'ai', 4, true, false, true, true, 'communication_scripts', 'نصوص جاهزة للمواقف'),
  ('/ai-analysis', 'ai_analysis', 'تحليل العلاقات', 'Relationship Analysis', '📈', 'ai', 5, true, false, true, true, 'relationship_analysis', 'تحليل شامل للعلاقات'),
  ('/ai-memories', 'ai_memories', 'الذكريات', 'AI Memories', '🧠', 'ai', 6, true, false, true, true, 'ai_chat', 'ذكريات المحادثات'),
  ('/ai-report', 'ai_report', 'التقرير الأسبوعي', 'Weekly Report', '📋', 'ai', 7, true, false, true, true, 'weekly_reports', 'تقرير أسبوعي عن التواصل')
ON CONFLICT (path) DO UPDATE SET
  label_ar = EXCLUDED.label_ar,
  label_en = EXCLUDED.label_en,
  icon = EXCLUDED.icon,
  category_key = EXCLUDED.category_key,
  sort_order = EXCLUDED.sort_order,
  requires_premium = EXCLUDED.requires_premium,
  feature_id = EXCLUDED.feature_id,
  description_ar = EXCLUDED.description_ar;

-- Gamification routes
INSERT INTO admin_app_routes (path, route_key, label_ar, label_en, icon, category_key, sort_order, is_active, is_public, requires_auth, requires_premium, description_ar) VALUES
  ('/badges', 'badges', 'الأوسمة', 'Badges', '🎖️', 'gamification', 1, true, false, true, false, 'الأوسمة المحققة والمتاحة'),
  ('/detailed-stats', 'detailed_stats', 'إحصائيات تفصيلية', 'Detailed Statistics', '📉', 'gamification', 2, true, false, true, false, 'إحصائيات مفصلة عن التواصل'),
  ('/leaderboard', 'leaderboard', 'لوحة المتصدرين', 'Leaderboard', '🏅', 'gamification', 3, true, false, true, false, 'ترتيب المستخدمين'),
  ('/challenges', 'challenges', 'التحديات', 'Challenges', '🎯', 'gamification', 4, true, false, true, false, 'تحديات التواصل')
ON CONFLICT (path) DO UPDATE SET
  label_ar = EXCLUDED.label_ar,
  label_en = EXCLUDED.label_en,
  icon = EXCLUDED.icon,
  category_key = EXCLUDED.category_key,
  sort_order = EXCLUDED.sort_order,
  description_ar = EXCLUDED.description_ar;

-- Settings routes
INSERT INTO admin_app_routes (path, route_key, label_ar, label_en, icon, category_key, sort_order, is_active, is_public, requires_auth, requires_premium, description_ar) VALUES
  ('/settings', 'settings', 'الإعدادات', 'Settings', '⚙️', 'settings', 1, true, false, true, false, 'إعدادات التطبيق'),
  ('/profile', 'profile', 'الملف الشخصي', 'Profile', '👤', 'settings', 2, true, false, true, false, 'الملف الشخصي')
ON CONFLICT (path) DO UPDATE SET
  label_ar = EXCLUDED.label_ar,
  label_en = EXCLUDED.label_en,
  icon = EXCLUDED.icon,
  category_key = EXCLUDED.category_key,
  sort_order = EXCLUDED.sort_order,
  description_ar = EXCLUDED.description_ar;

-- Notifications routes
INSERT INTO admin_app_routes (path, route_key, label_ar, label_en, icon, category_key, sort_order, is_active, is_public, requires_auth, requires_premium, description_ar) VALUES
  ('/notifications', 'notifications', 'الإشعارات', 'Notifications', '🔔', 'notifications', 1, true, false, true, false, 'إشعارات التطبيق'),
  ('/notification-history', 'notification_history', 'سجل الإشعارات', 'Notification History', '📜', 'notifications', 2, true, false, true, false, 'سجل الإشعارات السابقة')
ON CONFLICT (path) DO UPDATE SET
  label_ar = EXCLUDED.label_ar,
  label_en = EXCLUDED.label_en,
  icon = EXCLUDED.icon,
  category_key = EXCLUDED.category_key,
  sort_order = EXCLUDED.sort_order,
  description_ar = EXCLUDED.description_ar;

-- Subscription routes (both /subscription and /paywall point to paywall screen)
INSERT INTO admin_app_routes (path, route_key, label_ar, label_en, icon, category_key, sort_order, is_active, is_public, requires_auth, requires_premium, description_ar) VALUES
  ('/subscription', 'subscription', 'الاشتراك', 'Subscription', '💎', 'subscription', 1, true, false, true, false, 'شاشة الاشتراك وباقات MAX'),
  ('/paywall', 'paywall', 'الاشتراك', 'Paywall', '💎', 'subscription', 2, true, false, true, false, 'شاشة الاشتراك وباقات MAX')
ON CONFLICT (path) DO UPDATE SET
  label_ar = EXCLUDED.label_ar,
  label_en = EXCLUDED.label_en,
  icon = EXCLUDED.icon,
  category_key = EXCLUDED.category_key,
  sort_order = EXCLUDED.sort_order,
  description_ar = EXCLUDED.description_ar;

-- Clean up any duplicate routes with :id patterns that might have been entered differently
-- Keep the canonical versions
DELETE FROM admin_app_routes WHERE path = '/relatives/:id' AND route_key != 'relative_detail';
DELETE FROM admin_app_routes WHERE path = '/relatives/add' AND route_key != 'add_relative';
