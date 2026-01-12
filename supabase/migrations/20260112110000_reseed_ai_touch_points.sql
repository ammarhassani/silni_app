-- =============================================================================
-- Re-seed AI Touch Points (Production Fix)
-- The table exists but seed data was missing
-- =============================================================================

-- Clear and reseed touch points
DELETE FROM admin_ai_touch_points;

INSERT INTO admin_ai_touch_points (screen_key, touch_point_key, name_ar, name_en, description_ar, prompt_template, context_fields, display_config, temperature, max_tokens, is_enabled) VALUES

-- Home Screen Touch Points
('home', 'greeting', 'التحية الذكية', 'AI Greeting', 'تحية مخصصة بناءً على وقت اليوم وحالة العلاقات',
'أنت واصل، مساعد صلة الرحم. اكتب تحية قصيرة وودية (جملة واحدة فقط) للمستخدم بناءً على:
- الوقت الحالي: {{time_of_day}}
- عدد الشعلات النشطة: {{active_streaks}}
- الأقارب المعرضون للخطر: {{at_risk_count}}
- المناسبات القادمة: {{upcoming_occasions}}

اجعل التحية دافئة وشخصية باللهجة السعودية. لا تزيد عن 15 كلمة.',
'["time", "streaks", "health", "occasions"]'::jsonb,
'{"icon": "hand-wave", "position": "top"}'::jsonb,
0.8, 50, true),

('home', 'priority_contacts', 'من يحتاجك اليوم', 'Priority Contacts', 'قائمة الأقارب الأكثر حاجة للتواصل',
'بناءً على بيانات الأقارب التالية، رتب أهم 3 أقارب يحتاجون التواصل اليوم مع سبب قصير لكل منهم.

الأقارب:
{{relatives_data}}

الشعلات:
{{streaks_data}}

المناسبات القادمة:
{{occasions_data}}

أجب بصيغة JSON:
[{"name": "الاسم", "reason": "السبب في كلمات قليلة", "urgency": "high/medium/low"}]',
'["relatives", "streaks", "health", "occasions"]'::jsonb,
'{"icon": "users", "position": "main", "max_items": 3}'::jsonb,
0.7, 200, true),

('home', 'insight', 'رؤية اليوم', 'Daily Insight', 'ملاحظة ذكية عن أنماط التواصل',
'بناءً على بيانات التفاعلات والأنماط التالية، اكتب ملاحظة واحدة مفيدة ومشجعة للمستخدم عن صلة الرحم.

ملخص الصحة:
- علاقات صحية: {{healthy_count}}
- تحتاج اهتمام: {{needs_attention_count}}
- معرضة للخطر: {{at_risk_count}}

إحصائيات:
- إجمالي التفاعلات: {{total_interactions}}
- الشعلات النشطة: {{active_streaks}}

اجعل الملاحظة إيجابية ومحفزة. جملة أو جملتين فقط.',
'["health", "interactions", "streaks"]'::jsonb,
'{"icon": "lightbulb", "position": "bottom"}'::jsonb,
0.8, 80, true),

-- Relative Detail Touch Points
('relative_detail', 'conversation_starters', 'مواضيع للحديث', 'Conversation Starters', 'اقتراحات مواضيع بناءً على اهتمامات القريب',
'أنت مساعد عربي متخصص في تقوية صلة الرحم.

معلومات عن القريب:
- الاسم: {{relative_name}}
- صلة القرابة: {{relationship_type}}
- الجنس: {{gender}}
- الاهتمامات: {{interests}}
- نوع الشخصية: {{personality_type}}
- آخر تواصل منذ: {{days_since_contact}} يوم

اقترح 3 مواضيع محادثة مناسبة. كل موضوع يجب أن يكون:
1. جملة واحدة كاملة جاهزة للاستخدام
2. مناسب لجنس القريب ({{gender}})
3. مبني على اهتماماته إن وجدت

اكتب 3 مواضيع فقط، كل موضوع في سطر منفصل، بدون ترقيم أو نقاط:',
'["relative", "memories", "interactions"]'::jsonb,
'{"icon": "message-circle", "show_before_contact": true}'::jsonb,
0.8, 150, true),

('relative_detail', 'health_explanation', 'تفسير الصحة', 'Health Explanation', 'شرح حالة صحة العلاقة',
'اشرح باختصار لماذا صحة العلاقة مع {{relative_name}} هي {{health_status}}.

البيانات:
- آخر تواصل: {{days_since_contact}} يوم
- التقارب العاطفي: {{emotional_closeness}}/5
- جودة التواصل: {{communication_quality}}/5
- الشعلة الحالية: {{current_streak}} يوم

اكتب جملة أو جملتين تفسيرية بأسلوب ودي.',
'["relative", "health", "streaks"]'::jsonb,
'{"icon": "heart-pulse"}'::jsonb,
0.7, 80, true),

-- Reminders Screen Touch Points
('reminders', 'time_suggestion', 'أفضل وقت', 'Best Time', 'اقتراح أفضل وقت للتذكير',
'بناءً على أنماط التواصل مع {{relative_name}}:
- أوقات التواصل السابقة: {{contact_times}}
- الوقت المفضل المسجل: {{preferred_time}}

اقترح أفضل وقت للتذكير بالتواصل. جملة واحدة فقط.',
'["relative", "interactions", "patterns"]'::jsonb,
'{"icon": "clock"}'::jsonb,
0.7, 50, true),

('reminders', 'frequency_recommendation', 'تكرار مناسب', 'Frequency', 'اقتراح تكرار التذكير',
'بناءً على نوع العلاقة ({{relationship_type}}) وصحة العلاقة ({{health_status}}):

اقترح تكرار مناسب للتذكير (يومي/أسبوعي/شهري) مع تبرير قصير.',
'["relative", "health"]'::jsonb,
'{"icon": "repeat"}'::jsonb,
0.7, 60, true);

-- Log
DO $$
BEGIN
  RAISE NOTICE 'Migration 20260112100000_reseed_ai_touch_points completed - %s touch points inserted',
    (SELECT COUNT(*) FROM admin_ai_touch_points);
END $$;
