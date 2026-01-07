-- Custom UI Strings
-- Allows admin to control app text/labels remotely

CREATE TABLE admin_ui_strings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  string_key TEXT UNIQUE NOT NULL,
  category TEXT NOT NULL DEFAULT 'general',
  value_ar TEXT NOT NULL,
  value_en TEXT,
  description TEXT,
  screen TEXT, -- optional: which screen uses this string
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),

  CONSTRAINT valid_category CHECK (category IN (
    'general', 'buttons', 'labels', 'messages', 'errors', 'titles',
    'placeholders', 'dialogs', 'notifications', 'gamification'
  ))
);

-- Create updated_at trigger
CREATE TRIGGER update_admin_ui_strings_updated_at
  BEFORE UPDATE ON admin_ui_strings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Seed with common UI strings
INSERT INTO admin_ui_strings (string_key, category, value_ar, value_en, screen, description) VALUES
-- General
('app_name', 'general', 'صِلني', 'Silni', NULL, 'اسم التطبيق'),
('loading', 'general', 'جاري التحميل...', 'Loading...', NULL, 'رسالة التحميل'),
('retry', 'general', 'إعادة المحاولة', 'Retry', NULL, 'زر إعادة المحاولة'),

-- Buttons
('save', 'buttons', 'حفظ', 'Save', NULL, 'زر الحفظ'),
('cancel', 'buttons', 'إلغاء', 'Cancel', NULL, 'زر الإلغاء'),
('confirm', 'buttons', 'تأكيد', 'Confirm', NULL, 'زر التأكيد'),
('delete', 'buttons', 'حذف', 'Delete', NULL, 'زر الحذف'),
('edit', 'buttons', 'تعديل', 'Edit', NULL, 'زر التعديل'),
('add', 'buttons', 'إضافة', 'Add', NULL, 'زر الإضافة'),
('close', 'buttons', 'إغلاق', 'Close', NULL, 'زر الإغلاق'),
('next', 'buttons', 'التالي', 'Next', NULL, 'زر التالي'),
('back', 'buttons', 'رجوع', 'Back', NULL, 'زر الرجوع'),
('done', 'buttons', 'تم', 'Done', NULL, 'زر تم'),
('skip', 'buttons', 'تخطي', 'Skip', NULL, 'زر التخطي'),

-- Titles
('home_title', 'titles', 'الرئيسية', 'Home', 'home', 'عنوان الشاشة الرئيسية'),
('profile_title', 'titles', 'الملف الشخصي', 'Profile', 'profile', 'عنوان شاشة الملف'),
('settings_title', 'titles', 'الإعدادات', 'Settings', 'settings', 'عنوان شاشة الإعدادات'),
('reminders_title', 'titles', 'التذكيرات', 'Reminders', 'reminders', 'عنوان شاشة التذكيرات'),
('relatives_title', 'titles', 'الأقارب', 'Relatives', 'relatives', 'عنوان شاشة الأقارب'),

-- Labels
('streak_label', 'labels', 'سلسلة التواصل', 'Connection Streak', 'home', 'عنوان السلسلة'),
('points_label', 'labels', 'النقاط', 'Points', NULL, 'عنوان النقاط'),
('level_label', 'labels', 'المستوى', 'Level', NULL, 'عنوان المستوى'),
('today', 'labels', 'اليوم', 'Today', NULL, 'اليوم'),
('yesterday', 'labels', 'أمس', 'Yesterday', NULL, 'أمس'),
('days_ago', 'labels', 'يوم', 'days ago', NULL, 'أيام مضت'),

-- Messages
('success_saved', 'messages', 'تم الحفظ بنجاح', 'Saved successfully', NULL, 'رسالة نجاح الحفظ'),
('success_deleted', 'messages', 'تم الحذف بنجاح', 'Deleted successfully', NULL, 'رسالة نجاح الحذف'),
('success_updated', 'messages', 'تم التحديث بنجاح', 'Updated successfully', NULL, 'رسالة نجاح التحديث'),
('confirm_delete', 'messages', 'هل أنت متأكد من الحذف؟', 'Are you sure you want to delete?', NULL, 'رسالة تأكيد الحذف'),

-- Errors
('error_network', 'errors', 'خطأ في الاتصال بالشبكة', 'Network connection error', NULL, 'خطأ الشبكة'),
('error_generic', 'errors', 'حدث خطأ ما', 'Something went wrong', NULL, 'خطأ عام'),
('error_try_again', 'errors', 'الرجاء المحاولة مرة أخرى', 'Please try again', NULL, 'رسالة إعادة المحاولة'),
('error_not_found', 'errors', 'غير موجود', 'Not found', NULL, 'خطأ عدم الوجود'),

-- Placeholders
('search_placeholder', 'placeholders', 'بحث...', 'Search...', NULL, 'نص حقل البحث'),
('name_placeholder', 'placeholders', 'الاسم', 'Name', NULL, 'نص حقل الاسم'),
('notes_placeholder', 'placeholders', 'ملاحظات...', 'Notes...', NULL, 'نص حقل الملاحظات'),

-- Gamification
('streak_congrats', 'gamification', 'أحسنت! حافظت على السلسلة', 'Great! You maintained your streak', 'home', 'رسالة تهنئة السلسلة'),
('level_up', 'gamification', 'مبروك! ارتقيت لمستوى جديد', 'Congratulations! You leveled up', NULL, 'رسالة الترقية'),
('badge_earned', 'gamification', 'حصلت على شارة جديدة!', 'You earned a new badge!', NULL, 'رسالة الشارة'),
('points_earned', 'gamification', 'نقطة', 'points', NULL, 'وحدة النقاط');

-- RLS Policies
ALTER TABLE admin_ui_strings ENABLE ROW LEVEL SECURITY;

-- Admins can manage UI strings
CREATE POLICY "Admins can manage ui strings" ON admin_ui_strings
  FOR ALL USING (is_admin());

-- Authenticated users can read active strings
CREATE POLICY "Authenticated users can read strings" ON admin_ui_strings
  FOR SELECT USING (auth.role() = 'authenticated');

-- Indexes
CREATE INDEX idx_admin_ui_strings_key ON admin_ui_strings(string_key);
CREATE INDEX idx_admin_ui_strings_category ON admin_ui_strings(category);
CREATE INDEX idx_admin_ui_strings_screen ON admin_ui_strings(screen) WHERE screen IS NOT NULL;
CREATE INDEX idx_admin_ui_strings_active ON admin_ui_strings(is_active) WHERE is_active = true;

COMMENT ON TABLE admin_ui_strings IS 'Remotely controllable UI text strings for the Flutter app';
