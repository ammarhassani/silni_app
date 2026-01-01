-- =====================================================
-- Silni Admin Panel - Phase 2 Database Schema
-- AI Management, Subscriptions, Feature Gating
-- Created: 2025-12-30
-- =====================================================

-- =====================================================
-- 1. AI MANAGEMENT TABLES
-- =====================================================

-- AI Identity Configuration
CREATE TABLE IF NOT EXISTS admin_ai_identity (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ai_name TEXT NOT NULL DEFAULT 'واصل',
  ai_name_en TEXT DEFAULT 'Wasel',
  ai_role_ar TEXT NOT NULL DEFAULT 'مساعد ذكي متخصص في صلة الرحم والعلاقات الأسرية',
  ai_role_en TEXT DEFAULT 'Smart assistant specialized in family connections',
  ai_avatar_url TEXT,
  greeting_message_ar TEXT NOT NULL DEFAULT 'السلام عليكم! أنا واصل، مساعدك الشخصي لصلة الرحم. كيف يمكنني مساعدتك اليوم؟',
  greeting_message_en TEXT,
  dialect TEXT DEFAULT 'saudi_arabic',
  personality_summary_ar TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default AI identity
INSERT INTO admin_ai_identity (id) VALUES (gen_random_uuid())
ON CONFLICT DO NOTHING;

-- AI Personality Sections
CREATE TABLE IF NOT EXISTS admin_ai_personality (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  section_key TEXT NOT NULL UNIQUE,
  section_name_ar TEXT NOT NULL,
  content_ar TEXT NOT NULL,
  content_en TEXT,
  priority INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default personality sections
INSERT INTO admin_ai_personality (section_key, section_name_ar, content_ar, priority) VALUES
  ('base', 'الهوية الأساسية', 'أنت واصل، مساعد ذكي متخصص في تعزيز صلة الرحم والعلاقات الأسرية. تتحدث بالعامية السعودية البيضاء وتهتم بالقيم الإسلامية.', 1),
  ('values', 'القيم الإسلامية', 'تستند في نصائحك إلى تعاليم الإسلام حول صلة الرحم وبر الوالدين والإحسان للأقارب.', 2),
  ('style', 'أسلوب التواصل', 'تتحدث بأسلوب ودي ومحترم، تستخدم التشجيع والتحفيز، وتتجنب الأحكام السلبية.', 3),
  ('precision', 'الدقة والاختصار', 'تجيب بإيجاز ووضوح، وتتجنب الإطالة غير الضرورية. تركز على الفائدة العملية.', 4),
  ('emotional', 'الذكاء العاطفي', 'تفهم مشاعر المستخدم وتتعامل معها بحساسية، وتقدم الدعم النفسي عند الحاجة.', 5)
ON CONFLICT (section_key) DO NOTHING;

-- Counseling Modes
CREATE TABLE IF NOT EXISTS admin_counseling_modes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mode_key TEXT NOT NULL UNIQUE,
  display_name_ar TEXT NOT NULL,
  display_name_en TEXT,
  description_ar TEXT,
  icon_name TEXT DEFAULT 'message-circle',
  color_hex TEXT DEFAULT '#008080',
  mode_instructions TEXT NOT NULL,
  is_default BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default counseling modes
INSERT INTO admin_counseling_modes (mode_key, display_name_ar, display_name_en, description_ar, icon_name, mode_instructions, is_default, sort_order) VALUES
  ('general', 'محادثة عامة', 'General Chat', 'محادثة عامة حول صلة الرحم', 'message-circle', 'تحدث بشكل عام عن أي موضوع يتعلق بصلة الرحم والعلاقات الأسرية.', true, 1),
  ('relationship', 'تحسين العلاقات', 'Improve Relationships', 'نصائح لتحسين العلاقات مع الأقارب', 'heart', 'ركز على تقديم نصائح عملية لتحسين وتعزيز العلاقات مع الأقارب.', false, 2),
  ('conflict', 'حل النزاعات', 'Conflict Resolution', 'مساعدة في حل المشاكل العائلية', 'scale', 'ساعد في تحليل المشاكل العائلية واقترح حلولاً عملية وحكيمة.', false, 3),
  ('communication', 'فن التواصل', 'Communication Skills', 'تطوير مهارات التواصل العائلي', 'users', 'قدم نصائح لتحسين مهارات التواصل والحوار مع الأقارب.', false, 4)
ON CONFLICT (mode_key) DO NOTHING;

-- AI Model Parameters
CREATE TABLE IF NOT EXISTS admin_ai_parameters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  feature_key TEXT NOT NULL UNIQUE,
  display_name_ar TEXT NOT NULL,
  model_name TEXT DEFAULT 'deepseek',
  temperature DECIMAL NOT NULL DEFAULT 0.7,
  max_tokens INTEGER NOT NULL DEFAULT 2048,
  timeout_seconds INTEGER DEFAULT 30,
  stream_enabled BOOLEAN DEFAULT true,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default AI parameters
INSERT INTO admin_ai_parameters (feature_key, display_name_ar, temperature, max_tokens, description) VALUES
  ('chat', 'المحادثة', 0.7, 2048, 'محادثة المستشار الذكي'),
  ('message_generation', 'توليد الرسائل', 0.9, 2048, 'إبداعية أعلى لتوليد رسائل متنوعة'),
  ('relationship_analysis', 'تحليل العلاقات', 0.7, 2048, 'تحليل دقيق للعلاقات الأسرية'),
  ('smart_reminders', 'التذكيرات الذكية', 0.7, 1024, 'اقتراحات التذكيرات'),
  ('memory_extraction', 'استخراج الذاكرة', 0.3, 500, 'دقة عالية لاستخراج JSON'),
  ('weekly_report', 'التقرير الأسبوعي', 0.7, 1500, 'ملخص وتشجيع')
ON CONFLICT (feature_key) DO NOTHING;

-- AI Memory Configuration
CREATE TABLE IF NOT EXISTS admin_ai_memory_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  config_key TEXT NOT NULL UNIQUE DEFAULT 'default',
  max_memories_per_context INTEGER DEFAULT 30,
  max_memories_for_relative INTEGER DEFAULT 10,
  max_insights_displayed INTEGER DEFAULT 5,
  importance_default INTEGER DEFAULT 5,
  importance_min INTEGER DEFAULT 1,
  importance_max INTEGER DEFAULT 10,
  duplicate_match_threshold DECIMAL DEFAULT 0.8,
  cache_duration_minutes INTEGER DEFAULT 30,
  auto_cleanup_days INTEGER DEFAULT 365,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default memory config
INSERT INTO admin_ai_memory_config (config_key) VALUES ('default')
ON CONFLICT (config_key) DO NOTHING;

-- Memory Categories
CREATE TABLE IF NOT EXISTS admin_memory_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_key TEXT NOT NULL UNIQUE,
  display_name_ar TEXT NOT NULL,
  display_name_en TEXT,
  icon_name TEXT DEFAULT 'brain',
  default_importance INTEGER DEFAULT 5,
  auto_extract BOOLEAN DEFAULT true,
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default memory categories
INSERT INTO admin_memory_categories (category_key, display_name_ar, display_name_en, icon_name, sort_order) VALUES
  ('user_preference', 'تفضيلات المستخدم', 'User Preference', 'settings', 1),
  ('relative_fact', 'معلومة عن قريب', 'Relative Fact', 'user', 2),
  ('family_dynamic', 'ديناميكية عائلية', 'Family Dynamic', 'users', 3),
  ('important_date', 'تاريخ مهم', 'Important Date', 'calendar', 4),
  ('conversation_insight', 'ملاحظة من محادثة', 'Conversation Insight', 'message-circle', 5)
ON CONFLICT (category_key) DO NOTHING;

-- Message Occasions
CREATE TABLE IF NOT EXISTS admin_message_occasions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  occasion_key TEXT NOT NULL UNIQUE,
  display_name_ar TEXT NOT NULL,
  display_name_en TEXT,
  emoji TEXT NOT NULL,
  prompt_addition TEXT,
  seasonal BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default occasions
INSERT INTO admin_message_occasions (occasion_key, display_name_ar, display_name_en, emoji, sort_order) VALUES
  ('eid', 'عيد', 'Eid', '🎉', 1),
  ('ramadan', 'رمضان', 'Ramadan', '🌙', 2),
  ('birthday', 'عيد ميلاد', 'Birthday', '🎂', 3),
  ('wedding', 'زواج', 'Wedding', '💍', 4),
  ('graduation', 'تخرج', 'Graduation', '🎓', 5),
  ('newborn', 'مولود جديد', 'Newborn', '👶', 6),
  ('condolence', 'تعزية', 'Condolence', '🤲', 7),
  ('recovery', 'شفاء', 'Recovery', '💚', 8),
  ('missing', 'اشتياق', 'Missing', '💭', 9),
  ('checkin', 'اطمئنان', 'Check-in', '👋', 10),
  ('apology', 'اعتذار', 'Apology', '🙏', 11),
  ('thanks', 'شكر', 'Thanks', '❤️', 12)
ON CONFLICT (occasion_key) DO NOTHING;

-- Message Tones
CREATE TABLE IF NOT EXISTS admin_message_tones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tone_key TEXT NOT NULL UNIQUE,
  display_name_ar TEXT NOT NULL,
  display_name_en TEXT,
  emoji TEXT NOT NULL,
  prompt_modifier TEXT,
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default tones
INSERT INTO admin_message_tones (tone_key, display_name_ar, display_name_en, emoji, prompt_modifier, sort_order) VALUES
  ('formal', 'رسمي', 'Formal', '👔', 'استخدم لغة رسمية ومحترمة', 1),
  ('warm', 'دافئ', 'Warm', '🤗', 'استخدم لغة دافئة ومحببة', 2),
  ('humorous', 'مرح', 'Humorous', '😄', 'أضف لمسة خفيفة ومرحة', 3),
  ('religious', 'ديني', 'Religious', '🤲', 'أضف آيات أو أدعية مناسبة', 4)
ON CONFLICT (tone_key) DO NOTHING;

-- Suggested Prompts per Mode
CREATE TABLE IF NOT EXISTS admin_suggested_prompts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mode_key TEXT NOT NULL REFERENCES admin_counseling_modes(mode_key) ON DELETE CASCADE,
  prompt_ar TEXT NOT NULL,
  prompt_en TEXT,
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default suggested prompts
INSERT INTO admin_suggested_prompts (mode_key, prompt_ar, sort_order) VALUES
  ('general', 'كيف أحافظ على صلة الرحم؟', 1),
  ('general', 'ما أهمية صلة الرحم في الإسلام؟', 2),
  ('general', 'كيف أتواصل مع قريب بعيد؟', 3),
  ('general', 'اقترح لي طرق للتواصل', 4),
  ('relationship', 'كيف أحسن علاقتي بوالديّ؟', 1),
  ('relationship', 'كيف أتقرب من أقاربي؟', 2),
  ('relationship', 'علاقتي بأخي متوترة، ماذا أفعل؟', 3),
  ('relationship', 'كيف أصبح أكثر قرباً من عائلتي؟', 4),
  ('conflict', 'هناك خلاف عائلي، كيف أتصرف؟', 1),
  ('conflict', 'كيف أتعامل مع قريب صعب المراس؟', 2),
  ('conflict', 'كيف أصلح بين أقاربي المتخاصمين؟', 3),
  ('conflict', 'قريبي غاضب مني، ماذا أفعل؟', 4),
  ('communication', 'كيف أبدأ محادثة مع قريب؟', 1),
  ('communication', 'ماذا أقول في أول اتصال بعد انقطاع؟', 2),
  ('communication', 'كيف أعبر عن مشاعري لعائلتي؟', 3),
  ('communication', 'ما المواضيع المناسبة للحديث؟', 4);

-- AI Streaming Configuration
CREATE TABLE IF NOT EXISTS admin_ai_streaming_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  config_key TEXT NOT NULL UNIQUE DEFAULT 'default',
  sentence_end_delay_ms INTEGER DEFAULT 10,
  comma_delay_ms INTEGER DEFAULT 6,
  newline_delay_ms INTEGER DEFAULT 12,
  space_delay_ms INTEGER DEFAULT 2,
  word_min_delay_ms INTEGER DEFAULT 3,
  word_max_delay_ms INTEGER DEFAULT 5,
  is_streaming_enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default streaming config
INSERT INTO admin_ai_streaming_config (config_key) VALUES ('default')
ON CONFLICT (config_key) DO NOTHING;

-- AI Error Messages
CREATE TABLE IF NOT EXISTS admin_ai_error_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  error_code INTEGER NOT NULL UNIQUE,
  message_ar TEXT NOT NULL,
  message_en TEXT,
  show_retry_button BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default error messages
INSERT INTO admin_ai_error_messages (error_code, message_ar, show_retry_button) VALUES
  (400, 'طلب غير صالح. يرجى المحاولة مرة أخرى.', true),
  (401, 'انتهت جلستك. يرجى تسجيل الدخول مرة أخرى.', false),
  (402, 'هذه الميزة متاحة فقط لمشتركي MAX.', false),
  (403, 'ليس لديك صلاحية لهذا الإجراء.', false),
  (404, 'لم يتم العثور على المورد المطلوب.', true),
  (429, 'تجاوزت الحد المسموح. انتظر قليلاً ثم حاول مرة أخرى.', true),
  (500, 'حدث خطأ في الخادم. نعمل على إصلاحه.', true),
  (502, 'خطأ في الاتصال بالخادم. جاري المحاولة...', true),
  (503, 'الخدمة غير متاحة حالياً. جاري الصيانة.', true),
  (504, 'انتهت مهلة الطلب. يرجى المحاولة مرة أخرى.', true)
ON CONFLICT (error_code) DO NOTHING;

-- =====================================================
-- 2. SUBSCRIPTION MANAGEMENT TABLES
-- =====================================================

-- Subscription Tiers
CREATE TABLE IF NOT EXISTS admin_subscription_tiers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tier_key TEXT NOT NULL UNIQUE,
  display_name_ar TEXT NOT NULL,
  display_name_en TEXT,
  description_ar TEXT,
  description_en TEXT,
  reminder_limit INTEGER NOT NULL DEFAULT 3,
  features JSONB NOT NULL DEFAULT '[]',
  icon_name TEXT DEFAULT 'star',
  color_hex TEXT DEFAULT '#D4AF37',
  is_default BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default tiers
INSERT INTO admin_subscription_tiers (tier_key, display_name_ar, display_name_en, reminder_limit, features, is_default, sort_order) VALUES
  ('free', 'المجاني', 'Free', 3, '["custom_themes", "family_tree", "basic_reminders"]', true, 1),
  ('max', 'ماكس', 'MAX', -1, '["ai_chat", "message_composer", "communication_scripts", "relationship_analysis", "smart_reminders_ai", "weekly_reports", "advanced_analytics", "leaderboard", "data_export", "unlimited_reminders", "custom_themes", "family_tree"]', false, 2)
ON CONFLICT (tier_key) DO NOTHING;

-- Subscription Products
CREATE TABLE IF NOT EXISTS admin_subscription_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id TEXT NOT NULL UNIQUE,
  tier_key TEXT NOT NULL REFERENCES admin_subscription_tiers(tier_key) ON DELETE CASCADE,
  display_name_ar TEXT NOT NULL,
  display_name_en TEXT,
  billing_period TEXT NOT NULL CHECK (billing_period IN ('monthly', 'annual', 'lifetime')),
  price_usd DECIMAL(10,2),
  price_sar DECIMAL(10,2),
  savings_percentage INTEGER,
  is_featured BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default products
INSERT INTO admin_subscription_products (product_id, tier_key, display_name_ar, display_name_en, billing_period, price_usd, price_sar, savings_percentage, is_featured, sort_order) VALUES
  ('silni_max_monthly', 'max', 'ماكس الشهري', 'MAX Monthly', 'monthly', 4.99, 18.99, NULL, false, 1),
  ('silni_max_annual', 'max', 'ماكس السنوي', 'MAX Annual', 'annual', 29.99, 109.99, 50, true, 2)
ON CONFLICT (product_id) DO NOTHING;

-- Trial Configuration
CREATE TABLE IF NOT EXISTS admin_trial_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  config_key TEXT NOT NULL UNIQUE DEFAULT 'default',
  trial_duration_days INTEGER NOT NULL DEFAULT 7,
  trial_tier TEXT NOT NULL DEFAULT 'max',
  features_during_trial JSONB,
  show_trial_prompt_after_days INTEGER DEFAULT 3,
  show_trial_prompt_on_screens TEXT[] DEFAULT '{}',
  is_trial_enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default trial config
INSERT INTO admin_trial_config (config_key) VALUES ('default')
ON CONFLICT (config_key) DO NOTHING;

-- =====================================================
-- 3. FEATURE GATING TABLES
-- =====================================================

-- Feature Definitions
CREATE TABLE IF NOT EXISTS admin_features (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  feature_id TEXT NOT NULL UNIQUE,
  display_name_ar TEXT NOT NULL,
  display_name_en TEXT,
  description_ar TEXT,
  description_en TEXT,
  icon_name TEXT DEFAULT 'lock',
  category TEXT CHECK (category IN ('ai', 'analytics', 'social', 'customization', 'utility')),
  minimum_tier TEXT NOT NULL DEFAULT 'free',
  locked_message_ar TEXT,
  locked_message_en TEXT,
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default features
INSERT INTO admin_features (feature_id, display_name_ar, display_name_en, category, minimum_tier, icon_name, sort_order) VALUES
  ('ai_chat', 'المستشار الذكي', 'AI Counselor', 'ai', 'max', 'brain', 1),
  ('message_composer', 'منشئ الرسائل', 'Message Composer', 'ai', 'max', 'message-square', 2),
  ('communication_scripts', 'سيناريوهات التواصل', 'Communication Scripts', 'ai', 'max', 'file-text', 3),
  ('relationship_analysis', 'تحليل العلاقات', 'Relationship Analysis', 'ai', 'max', 'pie-chart', 4),
  ('smart_reminders_ai', 'التذكيرات الذكية', 'Smart Reminders AI', 'ai', 'max', 'zap', 5),
  ('weekly_reports', 'التقارير الأسبوعية', 'Weekly Reports', 'ai', 'max', 'bar-chart', 6),
  ('advanced_analytics', 'التحليلات المتقدمة', 'Advanced Analytics', 'analytics', 'max', 'activity', 7),
  ('leaderboard', 'لوحة المتصدرين', 'Leaderboard', 'social', 'max', 'award', 8),
  ('data_export', 'تصدير البيانات', 'Data Export', 'utility', 'max', 'download', 9),
  ('unlimited_reminders', 'تذكيرات غير محدودة', 'Unlimited Reminders', 'utility', 'max', 'bell', 10),
  ('custom_themes', 'السمات المخصصة', 'Custom Themes', 'customization', 'free', 'palette', 11),
  ('family_tree', 'شجرة العائلة', 'Family Tree', 'utility', 'free', 'git-branch', 12)
ON CONFLICT (feature_id) DO NOTHING;

-- =====================================================
-- 4. ENABLE RLS AND POLICIES
-- =====================================================

-- Enable RLS on all new tables
ALTER TABLE admin_ai_identity ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_ai_personality ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_counseling_modes ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_ai_parameters ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_ai_memory_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_memory_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_message_occasions ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_message_tones ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_suggested_prompts ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_ai_streaming_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_ai_error_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_subscription_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_subscription_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_trial_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_features ENABLE ROW LEVEL SECURITY;

-- AI Identity policies
CREATE POLICY "Admins can manage ai identity" ON admin_ai_identity FOR ALL USING (is_admin());
CREATE POLICY "Users can read active ai identity" ON admin_ai_identity FOR SELECT USING (is_active = true);

-- AI Personality policies
CREATE POLICY "Admins can manage ai personality" ON admin_ai_personality FOR ALL USING (is_admin());
CREATE POLICY "Users can read active ai personality" ON admin_ai_personality FOR SELECT USING (is_active = true);

-- Counseling Modes policies
CREATE POLICY "Admins can manage counseling modes" ON admin_counseling_modes FOR ALL USING (is_admin());
CREATE POLICY "Users can read active counseling modes" ON admin_counseling_modes FOR SELECT USING (is_active = true);

-- AI Parameters policies
CREATE POLICY "Admins can manage ai parameters" ON admin_ai_parameters FOR ALL USING (is_admin());
CREATE POLICY "Users can read active ai parameters" ON admin_ai_parameters FOR SELECT USING (is_active = true);

-- AI Memory Config policies
CREATE POLICY "Admins can manage ai memory config" ON admin_ai_memory_config FOR ALL USING (is_admin());
CREATE POLICY "Users can read active ai memory config" ON admin_ai_memory_config FOR SELECT USING (is_active = true);

-- Memory Categories policies
CREATE POLICY "Admins can manage memory categories" ON admin_memory_categories FOR ALL USING (is_admin());
CREATE POLICY "Users can read active memory categories" ON admin_memory_categories FOR SELECT USING (is_active = true);

-- Message Occasions policies
CREATE POLICY "Admins can manage message occasions" ON admin_message_occasions FOR ALL USING (is_admin());
CREATE POLICY "Users can read active message occasions" ON admin_message_occasions FOR SELECT USING (is_active = true);

-- Message Tones policies
CREATE POLICY "Admins can manage message tones" ON admin_message_tones FOR ALL USING (is_admin());
CREATE POLICY "Users can read active message tones" ON admin_message_tones FOR SELECT USING (is_active = true);

-- Suggested Prompts policies
CREATE POLICY "Admins can manage suggested prompts" ON admin_suggested_prompts FOR ALL USING (is_admin());
CREATE POLICY "Users can read active suggested prompts" ON admin_suggested_prompts FOR SELECT USING (is_active = true);

-- AI Streaming Config policies
CREATE POLICY "Admins can manage ai streaming config" ON admin_ai_streaming_config FOR ALL USING (is_admin());
CREATE POLICY "Users can read ai streaming config" ON admin_ai_streaming_config FOR SELECT USING (true);

-- AI Error Messages policies
CREATE POLICY "Admins can manage ai error messages" ON admin_ai_error_messages FOR ALL USING (is_admin());
CREATE POLICY "Users can read ai error messages" ON admin_ai_error_messages FOR SELECT USING (true);

-- Subscription Tiers policies
CREATE POLICY "Admins can manage subscription tiers" ON admin_subscription_tiers FOR ALL USING (is_admin());
CREATE POLICY "Users can read active subscription tiers" ON admin_subscription_tiers FOR SELECT USING (is_active = true);

-- Subscription Products policies
CREATE POLICY "Admins can manage subscription products" ON admin_subscription_products FOR ALL USING (is_admin());
CREATE POLICY "Users can read active subscription products" ON admin_subscription_products FOR SELECT USING (is_active = true);

-- Trial Config policies
CREATE POLICY "Admins can manage trial config" ON admin_trial_config FOR ALL USING (is_admin());
CREATE POLICY "Users can read trial config" ON admin_trial_config FOR SELECT USING (is_trial_enabled = true);

-- Features policies
CREATE POLICY "Admins can manage features" ON admin_features FOR ALL USING (is_admin());
CREATE POLICY "Users can read active features" ON admin_features FOR SELECT USING (is_active = true);

-- =====================================================
-- 5. ADD UPDATED_AT TRIGGERS
-- =====================================================

DO $$
DECLARE
  t text;
BEGIN
  FOR t IN
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
    AND table_name LIKE 'admin_%'
    AND table_name NOT IN (
      SELECT event_object_table
      FROM information_schema.triggers
      WHERE trigger_name LIKE 'update_%_updated_at'
    )
  LOOP
    EXECUTE format('
      DROP TRIGGER IF EXISTS update_%s_updated_at ON %s;
      CREATE TRIGGER update_%s_updated_at
        BEFORE UPDATE ON %s
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column();
    ', t, t, t, t);
  END LOOP;
END;
$$;

-- =====================================================
-- 6. INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_admin_counseling_modes_active ON admin_counseling_modes(is_active, sort_order);
CREATE INDEX IF NOT EXISTS idx_admin_message_occasions_active ON admin_message_occasions(is_active, sort_order);
CREATE INDEX IF NOT EXISTS idx_admin_message_tones_active ON admin_message_tones(is_active, sort_order);
CREATE INDEX IF NOT EXISTS idx_admin_suggested_prompts_mode ON admin_suggested_prompts(mode_key, is_active);
CREATE INDEX IF NOT EXISTS idx_admin_subscription_tiers_active ON admin_subscription_tiers(is_active, sort_order);
CREATE INDEX IF NOT EXISTS idx_admin_subscription_products_active ON admin_subscription_products(is_active, tier_key);
CREATE INDEX IF NOT EXISTS idx_admin_features_active ON admin_features(is_active, minimum_tier);
