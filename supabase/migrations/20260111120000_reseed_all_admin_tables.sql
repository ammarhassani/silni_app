-- Comprehensive reseed for production
-- Re-applies all seed data that was missing from production

-- =====================================================
-- 1. GAMIFICATION TABLES
-- =====================================================

-- Points Config
DELETE FROM admin_points_config WHERE true;
INSERT INTO admin_points_config (interaction_type, display_name_ar, display_name_en, base_points, icon) VALUES
  ('call', 'مكالمة', 'Call', 10, 'phone'),
  ('visit', 'زيارة', 'Visit', 20, 'home'),
  ('message', 'رسالة', 'Message', 5, 'message-circle'),
  ('gift', 'هدية', 'Gift', 15, 'gift'),
  ('event', 'مناسبة', 'Event', 25, 'calendar'),
  ('other', 'أخرى', 'Other', 5, 'more-horizontal');

-- Badges (core badges only - matching production schema)
DELETE FROM admin_badges WHERE true;
INSERT INTO admin_badges (badge_key, display_name_ar, display_name_en, description_ar, emoji, category, threshold_type, threshold_value, xp_reward, sort_order) VALUES
  ('streak_7', 'أسبوع التواصل', 'Week Streak', 'حافظ على التواصل لمدة 7 أيام متتالية', '🔥', 'streak', 'streak_days', 7, 100, 1),
  ('streak_30', 'شهر التواصل', 'Month Streak', 'حافظ على التواصل لمدة 30 يوم متتالي', '💪', 'streak', 'streak_days', 30, 500, 2),
  ('streak_100', 'قرن التواصل', 'Century Streak', 'حافظ على التواصل لمدة 100 يوم متتالي', '👑', 'streak', 'streak_days', 100, 2000, 3),
  ('streak_365', 'سنة التواصل', 'Year Streak', 'حافظ على التواصل لمدة سنة كاملة', '🏆', 'streak', 'streak_days', 365, 10000, 4),
  ('interactions_10', 'بداية الطريق', 'Getting Started', 'أكمل 10 تفاعلات', '🌱', 'volume', 'total_interactions', 10, 50, 10),
  ('interactions_50', 'واصل متمكن', 'Skilled Connector', 'أكمل 50 تفاعل', '🌿', 'volume', 'total_interactions', 50, 200, 11),
  ('interactions_100', 'واصل محترف', 'Professional Connector', 'أكمل 100 تفاعل', '🌳', 'volume', 'total_interactions', 100, 500, 12),
  ('interactions_500', 'واصل خبير', 'Expert Connector', 'أكمل 500 تفاعل', '🏅', 'volume', 'total_interactions', 500, 2000, 13),
  ('interactions_1000', 'واصل أسطوري', 'Legendary Connector', 'أكمل 1000 تفاعل', '🎖️', 'volume', 'total_interactions', 1000, 5000, 14),
  ('first_interaction', 'الخطوة الأولى', 'First Step', 'سجل أول تفاعل', '🎯', 'milestone', 'custom', 1, 50, 20),
  ('variety_3', 'منوع', 'Variety', 'تواصل مع 3 أقارب مختلفين', '🎨', 'variety', 'unique_relatives', 3, 100, 30),
  ('variety_10', 'شبكة علاقات', 'Network Builder', 'تواصل مع 10 أقارب مختلفين', '🌐', 'variety', 'unique_relatives', 10, 300, 31),
  ('early_bird', 'الباكر', 'Early Bird', 'سجل تفاعل قبل الساعة 8 صباحاً', '🌅', 'special', 'custom', 1, 50, 40),
  ('night_owl', 'البوم الليلي', 'Night Owl', 'سجل تفاعل بعد الساعة 10 مساءً', '🦉', 'special', 'custom', 1, 50, 41),
  ('weekend_warrior', 'محارب نهاية الأسبوع', 'Weekend Warrior', 'سجل 5 تفاعلات في عطلة نهاية الأسبوع', '💪', 'special', 'custom', 5, 150, 42),
  ('ramadan_spirit', 'روح رمضان', 'Ramadan Spirit', 'تواصل يومياً خلال رمضان', '🌙', 'special', 'streak_days', 30, 1000, 50);

-- Levels
DELETE FROM admin_levels WHERE true;
INSERT INTO admin_levels (level, title_ar, title_en, xp_required, xp_to_next) VALUES
  (1, 'مبتدئ', 'Beginner', 0, 100),
  (2, 'متعلم', 'Learner', 100, 150),
  (3, 'متقدم', 'Advanced', 250, 250),
  (4, 'ماهر', 'Skilled', 500, 500),
  (5, 'محترف', 'Professional', 1000, 1000),
  (6, 'خبير', 'Expert', 2000, 1500),
  (7, 'أستاذ', 'Master', 3500, 2000),
  (8, 'عبقري', 'Genius', 5500, 2500),
  (9, 'أسطورة', 'Legend', 8000, 4000),
  (10, 'واصل', 'Wasel', 12000, NULL);

-- Streak Config
DELETE FROM admin_streak_config WHERE true;
INSERT INTO admin_streak_config (config_key) VALUES ('default');

-- =====================================================
-- 2. NOTIFICATION TABLES
-- =====================================================

DELETE FROM admin_notification_templates WHERE true;
INSERT INTO admin_notification_templates (template_key, title_ar, body_ar, category, variables) VALUES
  ('reminder_due', 'حان وقت التواصل! ⏰', 'حان موعد التواصل مع {{relative_name}}', 'reminder', '["relative_name"]'),
  ('streak_endangered', 'سلسلتك في خطر! 🔥', 'تبقى {{hours}} ساعات للحفاظ على سلسلة {{streak_days}} يوم', 'streak', '["hours", "streak_days"]'),
  ('streak_broken', 'انتهت السلسلة 💔', 'للأسف انتهت سلسلتك. ابدأ من جديد!', 'streak', '[]'),
  ('badge_earned', 'وسام جديد! 🎉', 'مبروك! حصلت على وسام {{badge_name}}', 'badge', '["badge_name"]'),
  ('level_up', 'ارتقيت مستوى! 🚀', 'مبروك! وصلت للمستوى {{level}} - {{level_title}}', 'level', '["level", "level_title"]'),
  ('challenge_complete', 'تحدي مكتمل! 🏆', 'أنجزت تحدي {{challenge_name}}! +{{xp}} نقطة خبرة', 'challenge', '["challenge_name", "xp"]');

DELETE FROM admin_reminder_time_slots WHERE true;
INSERT INTO admin_reminder_time_slots (slot_key, display_name_ar, display_name_en, start_hour, end_hour, icon, is_default, sort_order) VALUES
  ('morning', 'الصباح', 'Morning', 6, 12, 'sunrise', false, 1),
  ('afternoon', 'الظهيرة', 'Afternoon', 12, 17, 'sun', true, 2),
  ('evening', 'المساء', 'Evening', 17, 21, 'sunset', false, 3),
  ('night', 'الليل', 'Night', 21, 24, 'moon', false, 4);

-- =====================================================
-- 3. DESIGN SYSTEM TABLES
-- =====================================================

DELETE FROM admin_colors WHERE true;
INSERT INTO admin_colors (color_key, display_name_ar, display_name_en, hex_value, usage_context, is_primary, sort_order) VALUES
  ('gold', 'الذهبي', 'Gold', '#D4AF37', 'accent', true, 1),
  ('gold_light', 'الذهبي الفاتح', 'Gold Light', '#E6C65C', 'accent_light', false, 2),
  ('gold_dark', 'الذهبي الداكن', 'Gold Dark', '#B8962E', 'accent_dark', false, 3),
  ('teal', 'الفيروزي', 'Teal', '#008080', 'primary', true, 4),
  ('teal_light', 'الفيروزي الفاتح', 'Teal Light', '#20B2AA', 'primary_light', false, 5),
  ('teal_dark', 'الفيروزي الداكن', 'Teal Dark', '#006666', 'primary_dark', false, 6),
  ('emerald', 'الزمردي', 'Emerald', '#50C878', 'success', false, 7),
  ('cream', 'الكريمي', 'Cream', '#FFF8DC', 'background', false, 8);

DELETE FROM admin_animations WHERE true;
INSERT INTO admin_animations (animation_key, display_name_ar, display_name_en, duration_ms, curve, usage_context) VALUES
  ('instant', 'فوري', 'Instant', 100, 'linear', 'Micro-interactions'),
  ('fast', 'سريع', 'Fast', 200, 'easeOut', 'Button feedback'),
  ('normal', 'عادي', 'Normal', 300, 'easeInOut', 'Standard transitions'),
  ('modal', 'نافذة', 'Modal', 400, 'easeOutBack', 'Dialog open/close'),
  ('slow', 'بطيء', 'Slow', 500, 'easeInOut', 'Page transitions'),
  ('dramatic', 'درامي', 'Dramatic', 800, 'easeInOutQuart', 'Celebrations'),
  ('celebration', 'احتفال', 'Celebration', 1200, 'easeOut', 'Badge/Level up'),
  ('loop', 'متكرر', 'Loop', 2000, 'linear', 'Loading indicators');

DELETE FROM admin_pattern_animations WHERE true;
INSERT INTO admin_pattern_animations (effect_key, display_name_ar, display_name_en, default_enabled, battery_impact, settings_key, sort_order) VALUES
  ('rotation', 'الدوران', 'Rotation', true, 'low', 'pattern_rotation_enabled', 1),
  ('pulse', 'النبض', 'Pulse', true, 'low', 'pattern_pulse_enabled', 2),
  ('parallax', 'التأثير الثلاثي', 'Parallax', true, 'low', 'pattern_parallax_enabled', 3),
  ('shimmer', 'اللمعان', 'Shimmer', false, 'medium', 'pattern_shimmer_enabled', 4),
  ('touch_ripple', 'تموج اللمس', 'Touch Ripple', true, 'low', 'pattern_touch_ripple_enabled', 5),
  ('gyroscope', 'الجيروسكوب', 'Gyroscope', false, 'medium', 'pattern_gyroscope_enabled', 6),
  ('follow_touch', 'متابعة اللمس', 'Follow Touch', true, 'low', 'pattern_follow_touch_enabled', 7);

-- Themes - PROPER THEMES with full color/gradient data (see 20251231300001_seed_admin_themes.sql)
DELETE FROM admin_themes WHERE true;
INSERT INTO admin_themes (theme_key, display_name_ar, display_name_en, is_dark, colors, gradients, is_premium, is_default, sort_order) VALUES
('default', 'صِلني', 'Silni Green', false,
  '{"primary": "#2E7D32", "primary_light": "#60AD5E", "primary_dark": "#005005", "secondary": "#FFD700", "accent": "#FF6F00", "background_1": "#1B5E20", "background_2": "#2E7D32", "background_3": "#388E3C", "on_primary": "#FFFFFF", "on_secondary": "#1B5E20", "surface": "#1B5E20", "on_surface": "#FFFFFF", "surface_variant": "#2E7D32", "on_surface_variant": "#E8F5E9", "glass_background": "#26FFFFFF", "glass_border": "#33FFFFFF", "glass_highlight": "#4DFFFFFF", "text_primary": "#FFFFFF", "text_secondary": "#B3FFFFFF", "text_hint": "#80FFFFFF", "text_on_gradient": "#FFFFFF", "shimmer_base": "#2E7D32", "shimmer_highlight": "#81C784", "card_background": "#26FFFFFF", "card_border": "#33FFFFFF", "divider": "#33FFFFFF", "disabled": "#80FFFFFF"}',
  '{"primary": {"colors": ["#2E7D32", "#60AD5E", "#81C784"]}, "background": {"colors": ["#1B5E20", "#2E7D32", "#388E3C"]}, "golden": {"colors": ["#FFD700", "#FFA000", "#FF6F00"]}, "streak_fire": {"colors": ["#FF6F00", "#FF8F00", "#FFA726"]}}',
  false, true, 0),
('lavender', 'خزامى', 'Lavender Purple', false,
  '{"primary": "#7B1FA2", "primary_light": "#BA68C8", "primary_dark": "#4A0072", "secondary": "#FFD700", "accent": "#E040FB", "background_1": "#4A148C", "background_2": "#6A1B9A", "background_3": "#7B1FA2", "on_primary": "#FFFFFF", "on_secondary": "#4A148C", "surface": "#4A148C", "on_surface": "#FFFFFF", "surface_variant": "#6A1B9A", "on_surface_variant": "#F3E5F5", "glass_background": "#26FFFFFF", "glass_border": "#33FFFFFF", "glass_highlight": "#4DFFFFFF", "text_primary": "#FFFFFF", "text_secondary": "#B3FFFFFF", "text_hint": "#80FFFFFF", "text_on_gradient": "#FFFFFF", "shimmer_base": "#7B1FA2", "shimmer_highlight": "#BA68C8", "card_background": "#26FFFFFF", "card_border": "#33FFFFFF", "divider": "#33FFFFFF", "disabled": "#80FFFFFF"}',
  '{"primary": {"colors": ["#7B1FA2", "#9C27B0", "#BA68C8"]}, "background": {"colors": ["#4A148C", "#6A1B9A", "#7B1FA2"]}, "golden": {"colors": ["#FFD700", "#FFA000", "#FF6F00"]}, "streak_fire": {"colors": ["#E040FB", "#CE93D8", "#BA68C8"]}}',
  true, false, 1),
('royal', 'الأزرق الملكي', 'Royal Blue', false,
  '{"primary": "#1565C0", "primary_light": "#5E92F3", "primary_dark": "#003C8F", "secondary": "#FFD700", "accent": "#00B0FF", "background_1": "#0D47A1", "background_2": "#1565C0", "background_3": "#1976D2", "on_primary": "#FFFFFF", "on_secondary": "#0D47A1", "surface": "#0D47A1", "on_surface": "#FFFFFF", "surface_variant": "#1565C0", "on_surface_variant": "#E3F2FD", "glass_background": "#26FFFFFF", "glass_border": "#33FFFFFF", "glass_highlight": "#4DFFFFFF", "text_primary": "#FFFFFF", "text_secondary": "#B3FFFFFF", "text_hint": "#80FFFFFF", "text_on_gradient": "#FFFFFF", "shimmer_base": "#1565C0", "shimmer_highlight": "#42A5F5", "card_background": "#26FFFFFF", "card_border": "#33FFFFFF", "divider": "#33FFFFFF", "disabled": "#80FFFFFF"}',
  '{"primary": {"colors": ["#1565C0", "#1976D2", "#42A5F5"]}, "background": {"colors": ["#0D47A1", "#1565C0", "#1976D2"]}, "golden": {"colors": ["#FFD700", "#FFA000", "#FF6F00"]}, "streak_fire": {"colors": ["#00B0FF", "#40C4FF", "#80D8FF"]}}',
  true, false, 2),
('sunset', 'غروب الشمس', 'Sunset Orange', false,
  '{"primary": "#E65100", "primary_light": "#FF8A50", "primary_dark": "#AC1900", "secondary": "#FFD700", "accent": "#FF6F00", "background_1": "#BF360C", "background_2": "#D84315", "background_3": "#E64A19", "on_primary": "#FFFFFF", "on_secondary": "#BF360C", "surface": "#BF360C", "on_surface": "#FFFFFF", "surface_variant": "#D84315", "on_surface_variant": "#FBE9E7", "glass_background": "#26FFFFFF", "glass_border": "#33FFFFFF", "glass_highlight": "#4DFFFFFF", "text_primary": "#FFFFFF", "text_secondary": "#B3FFFFFF", "text_hint": "#80FFFFFF", "text_on_gradient": "#FFFFFF", "shimmer_base": "#E65100", "shimmer_highlight": "#FF9800", "card_background": "#26FFFFFF", "card_border": "#33FFFFFF", "divider": "#33FFFFFF", "disabled": "#80FFFFFF"}',
  '{"primary": {"colors": ["#E65100", "#FF6F00", "#FF9800"]}, "background": {"colors": ["#BF360C", "#D84315", "#E64A19"]}, "golden": {"colors": ["#FFD700", "#FFA000", "#FF6F00"]}, "streak_fire": {"colors": ["#FF6F00", "#FF8F00", "#FFA726"]}}',
  true, false, 3),
('rose', 'ذهبي وردي', 'Rose Gold', false,
  '{"primary": "#C2185B", "primary_light": "#F06292", "primary_dark": "#880E4F", "secondary": "#FFD700", "accent": "#FF4081", "background_1": "#880E4F", "background_2": "#AD1457", "background_3": "#C2185B", "on_primary": "#FFFFFF", "on_secondary": "#880E4F", "surface": "#880E4F", "on_surface": "#FFFFFF", "surface_variant": "#AD1457", "on_surface_variant": "#FCE4EC", "glass_background": "#26FFFFFF", "glass_border": "#33FFFFFF", "glass_highlight": "#4DFFFFFF", "text_primary": "#FFFFFF", "text_secondary": "#B3FFFFFF", "text_hint": "#80FFFFFF", "text_on_gradient": "#FFFFFF", "shimmer_base": "#C2185B", "shimmer_highlight": "#F06292", "card_background": "#26FFFFFF", "card_border": "#33FFFFFF", "divider": "#33FFFFFF", "disabled": "#80FFFFFF"}',
  '{"primary": {"colors": ["#C2185B", "#E91E63", "#F06292"]}, "background": {"colors": ["#880E4F", "#AD1457", "#C2185B"]}, "golden": {"colors": ["#FFD700", "#FFA000", "#FF6F00"]}, "streak_fire": {"colors": ["#FF4081", "#FF80AB", "#F48FB1"]}}',
  true, false, 4),
('midnight', 'ليل', 'Midnight Dark', true,
  '{"primary": "#1A237E", "primary_light": "#534BAE", "primary_dark": "#000051", "secondary": "#FFD700", "accent": "#536DFE", "background_1": "#0A0E27", "background_2": "#1A237E", "background_3": "#283593", "on_primary": "#FFFFFF", "on_secondary": "#0A0E27", "surface": "#0A0E27", "on_surface": "#FFFFFF", "surface_variant": "#1A237E", "on_surface_variant": "#E8EAF6", "glass_background": "#26FFFFFF", "glass_border": "#33FFFFFF", "glass_highlight": "#4DFFFFFF", "text_primary": "#FFFFFF", "text_secondary": "#B3FFFFFF", "text_hint": "#80FFFFFF", "text_on_gradient": "#FFFFFF", "shimmer_base": "#1A237E", "shimmer_highlight": "#3949AB", "card_background": "#26FFFFFF", "card_border": "#33FFFFFF", "divider": "#33FFFFFF", "disabled": "#80FFFFFF"}',
  '{"primary": {"colors": ["#1A237E", "#283593", "#3949AB"]}, "background": {"colors": ["#0A0E27", "#1A237E", "#283593"]}, "golden": {"colors": ["#FFD700", "#FFA000", "#FF6F00"]}, "streak_fire": {"colors": ["#536DFE", "#7C4DFF", "#B388FF"]}}',
  true, false, 5);

-- =====================================================
-- 4. AI TABLES
-- =====================================================

DELETE FROM admin_ai_personality WHERE true;
INSERT INTO admin_ai_personality (section_key, section_name_ar, content_ar, priority) VALUES
  ('base', 'الهوية الأساسية', 'أنت واصل، مساعد ذكي متخصص في تعزيز صلة الرحم والعلاقات الأسرية. تتحدث بالعامية السعودية البيضاء وتهتم بالقيم الإسلامية.', 1),
  ('values', 'القيم الإسلامية', 'تستند في نصائحك إلى تعاليم الإسلام حول صلة الرحم وبر الوالدين والإحسان للأقارب.', 2),
  ('style', 'أسلوب التواصل', 'تتحدث بأسلوب ودي ومحترم، تستخدم التشجيع والتحفيز، وتتجنب الأحكام السلبية.', 3),
  ('precision', 'الدقة والاختصار', 'تجيب بإيجاز ووضوح، وتتجنب الإطالة غير الضرورية. تركز على الفائدة العملية.', 4),
  ('emotional', 'الذكاء العاطفي', 'تفهم مشاعر المستخدم وتتعامل معها بحساسية، وتقدم الدعم النفسي عند الحاجة.', 5);

DELETE FROM admin_counseling_modes WHERE true;
INSERT INTO admin_counseling_modes (mode_key, display_name_ar, display_name_en, description_ar, icon_name, mode_instructions, is_default, sort_order) VALUES
  ('general', 'محادثة عامة', 'General Chat', 'محادثة عامة حول صلة الرحم', 'message-circle', 'تحدث بشكل عام عن أي موضوع يتعلق بصلة الرحم والعلاقات الأسرية.', true, 1),
  ('relationship', 'تحسين العلاقات', 'Improve Relationships', 'نصائح لتحسين العلاقات مع الأقارب', 'heart', 'ركز على تقديم نصائح عملية لتحسين وتعزيز العلاقات مع الأقارب.', false, 2),
  ('conflict', 'حل النزاعات', 'Conflict Resolution', 'مساعدة في حل المشاكل العائلية', 'scale', 'ساعد في تحليل المشاكل العائلية واقترح حلولاً عملية وحكيمة.', false, 3),
  ('communication', 'فن التواصل', 'Communication Skills', 'تطوير مهارات التواصل العائلي', 'users', 'قدم نصائح لتحسين مهارات التواصل والحوار مع الأقارب.', false, 4);

DELETE FROM admin_ai_parameters WHERE true;
INSERT INTO admin_ai_parameters (feature_key, display_name_ar, temperature, max_tokens, description) VALUES
  ('chat', 'المحادثة', 0.7, 2048, 'محادثة المستشار الذكي'),
  ('message_generation', 'توليد الرسائل', 0.9, 2048, 'إبداعية أعلى لتوليد رسائل متنوعة'),
  ('relationship_analysis', 'تحليل العلاقات', 0.7, 2048, 'تحليل دقيق للعلاقات الأسرية'),
  ('smart_reminders', 'التذكيرات الذكية', 0.7, 1024, 'اقتراحات التذكيرات'),
  ('memory_extraction', 'استخراج الذاكرة', 0.3, 500, 'دقة عالية لاستخراج JSON'),
  ('weekly_report', 'التقرير الأسبوعي', 0.7, 1500, 'ملخص وتشجيع');

DELETE FROM admin_ai_memory_config WHERE true;
INSERT INTO admin_ai_memory_config (config_key) VALUES ('default');

DELETE FROM admin_memory_categories WHERE true;
INSERT INTO admin_memory_categories (category_key, display_name_ar, display_name_en, icon_name, sort_order) VALUES
  ('user_preference', 'تفضيلات المستخدم', 'User Preference', 'settings', 1),
  ('relative_fact', 'معلومة عن قريب', 'Relative Fact', 'user', 2),
  ('family_dynamic', 'ديناميكية عائلية', 'Family Dynamic', 'users', 3),
  ('important_date', 'تاريخ مهم', 'Important Date', 'calendar', 4),
  ('conversation_insight', 'ملاحظة من محادثة', 'Conversation Insight', 'message-circle', 5);

DELETE FROM admin_message_occasions WHERE true;
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
  ('thanks', 'شكر', 'Thanks', '❤️', 12);

DELETE FROM admin_message_tones WHERE true;
INSERT INTO admin_message_tones (tone_key, display_name_ar, display_name_en, emoji, prompt_modifier, sort_order) VALUES
  ('formal', 'رسمي', 'Formal', '👔', 'استخدم لغة رسمية ومحترمة', 1),
  ('warm', 'دافئ', 'Warm', '🤗', 'استخدم لغة دافئة ومحببة', 2),
  ('humorous', 'مرح', 'Humorous', '😄', 'أضف لمسة خفيفة ومرحة', 3),
  ('religious', 'ديني', 'Religious', '🤲', 'أضف آيات أو أدعية مناسبة', 4);

DELETE FROM admin_suggested_prompts WHERE true;
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

DELETE FROM admin_ai_streaming_config WHERE true;
INSERT INTO admin_ai_streaming_config (config_key) VALUES ('default');

DELETE FROM admin_ai_error_messages WHERE true;
INSERT INTO admin_ai_error_messages (error_code, message_ar, show_retry_button) VALUES
  (400, 'طلب غير صالح. يرجى المحاولة مرة أخرى.', true),
  (401, 'انتهت جلستك. يرجى تسجيل الدخول مرة أخرى.', false),
  (402, 'هذه الميزة متاحة فقط لمشتركي MAX.', false),
  (403, 'ليس لديك صلاحية لهذا الإجراء.', false),
  (404, 'لم يتم العثور على المورد المطلوب.', true),
  (408, 'انتهت مهلة الطلب. حاول مرة أخرى.', true),
  (429, 'تم تجاوز الحد المسموح. انتظر قليلاً ثم حاول.', true),
  (500, 'حدث خطأ في الخادم. نعتذر عن الإزعاج.', true),
  (502, 'خطأ في بوابة الخادم. حاول بعد قليل.', true),
  (503, 'الخدمة غير متوفرة حالياً. نعتذر عن الإزعاج.', true);

-- =====================================================
-- 5. SUBSCRIPTION TABLES
-- =====================================================

-- NOTE: Flutter app only recognizes 'free' and 'max' tiers - DO NOT use 'premium'!
DELETE FROM admin_subscription_tiers WHERE true;
INSERT INTO admin_subscription_tiers (tier_key, display_name_ar, display_name_en, reminder_limit, features, is_default, sort_order) VALUES
  ('free', 'مجاني', 'Free', 3, '["basic_reminders", "streak_tracking", "basic_stats"]', true, 1),
  ('max', 'ماكس', 'MAX', -1, '["unlimited_reminders", "ai_counselor", "advanced_stats", "custom_themes", "family_tree", "export_data"]', false, 2);

DELETE FROM admin_subscription_products WHERE true;
-- Product IDs must match App Store Connect identifiers exactly
-- Prices are NULL because App Store is the source of truth (dynamic via RevenueCat)
INSERT INTO admin_subscription_products (product_id, tier_key, display_name_ar, display_name_en, billing_period, price_usd, price_sar, savings_percentage, is_featured, sort_order, revenuecat_package_id, notes) VALUES
  ('silni_max_monthly', 'max', 'اشتراك شهري', 'Monthly', 'monthly', NULL, NULL, 0, false, 1, 'max_monthly', 'Prices managed by App Store Connect. Use RevenueCat for dynamic pricing.'),
  ('silni_max_annual', 'max', 'اشتراك سنوي', 'Annual', 'annual', NULL, NULL, 33, true, 2, 'max_annual', 'Prices managed by App Store Connect. Use RevenueCat for dynamic pricing.');

DELETE FROM admin_trial_config WHERE true;
INSERT INTO admin_trial_config (config_key) VALUES ('default');

-- NOTE: minimum_tier must be 'free' or 'max' - Flutter app doesn't recognize 'premium'!
DELETE FROM admin_features WHERE true;
INSERT INTO admin_features (feature_id, display_name_ar, display_name_en, category, minimum_tier, icon_name, sort_order) VALUES
  ('ai_chat', 'المستشار الذكي', 'AI Counselor', 'ai', 'max', 'brain', 1),
  ('ai_message_generator', 'مولد الرسائل', 'Message Generator', 'ai', 'max', 'message-square-plus', 2),
  ('ai_weekly_report', 'التقرير الأسبوعي', 'Weekly Report', 'ai', 'max', 'file-text', 3),
  ('ai_suggestions', 'اقتراحات ذكية', 'Smart Suggestions', 'ai', 'max', 'lightbulb', 4),
  ('advanced_stats', 'إحصائيات متقدمة', 'Advanced Stats', 'analytics', 'max', 'trending-up', 10),
  ('export_data', 'تصدير البيانات', 'Export Data', 'analytics', 'max', 'download', 11),
  ('family_tree', 'شجرة العائلة', 'Family Tree', 'social', 'max', 'git-branch', 20),
  ('unlimited_reminders', 'تذكيرات غير محدودة', 'Unlimited Reminders', 'utility', 'max', 'bell-plus', 30),
  ('custom_themes', 'سمات مخصصة', 'Custom Themes', 'customization', 'max', 'palette', 40),
  ('pattern_effects', 'تأثيرات الخلفية', 'Background Effects', 'customization', 'max', 'sparkles', 41),
  ('ad_free', 'بدون إعلانات', 'Ad Free', 'utility', 'max', 'shield', 50),
  ('priority_support', 'دعم أولوي', 'Priority Support', 'utility', 'max', 'headphones', 51);

-- =====================================================
-- 6. COMMUNICATION SCENARIOS
-- =====================================================

DELETE FROM admin_communication_scenarios WHERE true;
INSERT INTO admin_communication_scenarios (scenario_key, title_ar, title_en, description_ar, description_en, emoji, color_hex, sort_order, is_active) VALUES
  ('reconnect', 'إعادة التواصل', 'Reconnecting', 'التواصل بعد فترة انقطاع', 'Reaching out after a period of silence', '🔄', '#4CAF50', 1, true),
  ('congratulate', 'تهنئة', 'Congratulations', 'تهنئة بمناسبة سعيدة', 'Congratulating on a happy occasion', '🎉', '#FF9800', 2, true),
  ('condolence', 'تعزية', 'Condolence', 'تقديم العزاء والمواساة', 'Offering condolences', '🤲', '#607D8B', 3, true),
  ('checkin', 'اطمئنان', 'Check-in', 'الاطمئنان على الحال', 'Checking in on someone', '👋', '#2196F3', 4, true),
  ('apology', 'اعتذار', 'Apology', 'الاعتذار وطلب المسامحة', 'Apologizing and asking for forgiveness', '🙏', '#9C27B0', 5, true),
  ('thanks', 'شكر', 'Thanks', 'شكر وتقدير', 'Expressing gratitude', '❤️', '#E91E63', 6, true);

-- =====================================================
-- 7. ONBOARDING SCREENS
-- =====================================================

DELETE FROM admin_onboarding_screens WHERE true;
INSERT INTO admin_onboarding_screens (screen_order, title_ar, title_en, subtitle_ar, subtitle_en, animation_name, is_active) VALUES
  (1, 'مرحباً بك في واصل', 'Welcome to Wasel', 'تطبيق يساعدك على تعزيز صلة الرحم والتواصل مع أقاربك', 'An app that helps you strengthen family ties and stay connected', 'welcome', true),
  (2, 'أضف أقاربك', 'Add Your Relatives', 'أضف أسماء أقاربك وحدد درجة القرابة', 'Add your relatives and specify the relationship', 'relatives', true),
  (3, 'ضع تذكيرات', 'Set Reminders', 'حدد مواعيد للتواصل مع كل قريب', 'Schedule times to connect with each relative', 'reminders', true),
  (4, 'تابع سلسلتك', 'Track Your Streak', 'حافظ على سلسلة التواصل اليومية', 'Maintain your daily connection streak', 'streak', true),
  (5, 'استشر واصل', 'Ask Wasel', 'استفد من المستشار الذكي لتحسين علاقاتك', 'Use the AI counselor to improve your relationships', 'ai', true);

-- =====================================================
-- 8. APP ROUTES
-- =====================================================

DELETE FROM admin_route_categories WHERE true;
INSERT INTO admin_route_categories (category_key, label_ar, label_en, icon, sort_order) VALUES
  ('main', 'الرئيسية', 'Main', 'home', 1),
  ('relatives', 'الأقارب', 'Relatives', 'users', 2),
  ('reminders', 'التذكيرات', 'Reminders', 'bell', 3),
  ('ai', 'المستشار', 'Counselor', 'bot', 4),
  ('gamification', 'الإنجازات', 'Achievements', 'trophy', 5),
  ('settings', 'الإعدادات', 'Settings', 'settings', 6),
  ('auth', 'المصادقة', 'Auth', 'lock', 7),
  ('subscription', 'الاشتراك', 'Subscription', 'credit-card', 8);

DELETE FROM admin_app_routes WHERE true;
INSERT INTO admin_app_routes (path, route_key, label_ar, label_en, icon, category_key, sort_order, is_public, requires_auth) VALUES
  ('/', 'splash', 'البداية', 'Splash', 'loader', 'main', 0, true, false),
  ('/onboarding', 'onboarding', 'التعريف', 'Onboarding', 'book-open', 'main', 1, true, false),
  ('/home', 'home', 'الرئيسية', 'Home', 'home', 'main', 2, false, true),
  ('/relatives', 'relatives', 'الأقارب', 'Relatives', 'users', 'relatives', 1, false, true),
  ('/relatives/add', 'add_relative', 'إضافة قريب', 'Add Relative', 'user-plus', 'relatives', 2, false, true),
  ('/relatives/:id', 'relative_detail', 'تفاصيل القريب', 'Relative Detail', 'user', 'relatives', 3, false, true),
  ('/reminders', 'reminders', 'التذكيرات', 'Reminders', 'bell', 'reminders', 1, false, true),
  ('/ai', 'ai_counselor', 'المستشار', 'Counselor', 'bot', 'ai', 1, false, true),
  ('/badges', 'badges', 'الأوسمة', 'Badges', 'award', 'gamification', 1, false, true),
  ('/settings', 'settings', 'الإعدادات', 'Settings', 'settings', 'settings', 1, false, true),
  ('/profile', 'profile', 'الملف الشخصي', 'Profile', 'user', 'settings', 2, false, true),
  ('/login', 'login', 'تسجيل الدخول', 'Login', 'log-in', 'auth', 1, true, false),
  ('/signup', 'signup', 'إنشاء حساب', 'Sign Up', 'user-plus', 'auth', 2, true, false),
  ('/subscription', 'subscription', 'الاشتراك', 'Subscription', 'credit-card', 'subscription', 1, false, true),
  ('/family-tree', 'family_tree', 'شجرة العائلة', 'Family Tree', 'git-branch', 'relatives', 4, false, true);
