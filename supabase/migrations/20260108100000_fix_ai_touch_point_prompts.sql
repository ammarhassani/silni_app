-- =============================================================================
-- Fix AI Touch Point Prompts - Use plain text instead of JSON
-- =============================================================================

-- Update conversation_starters to return plain numbered list
UPDATE admin_ai_touch_points
SET prompt_template = 'أنت واصل، مساعد صلة الرحم. اقترح 3 مواضيع للحديث مع {{relative_name}} بناءً على:

العلاقة: {{relationship_type}}
الاهتمامات: {{interests}}
آخر تواصل: {{last_contact}} يوم
ذكريات سابقة: {{memories}}

أجب بقائمة مرقمة بسيطة، كل موضوع في سطر واحد:
1. الموضوع الأول
2. الموضوع الثاني
3. الموضوع الثالث

اجعل المواضيع طبيعية ومناسبة للعلاقة والثقافة السعودية.'
WHERE screen_key = 'relative_detail' AND touch_point_key = 'conversation_starters';

-- Update priority_contacts to return plain text insight
UPDATE admin_ai_touch_points
SET prompt_template = 'أنت واصل، مساعد صلة الرحم. بناءً على بيانات الأقارب التالية، اكتب نصيحة قصيرة (جملة أو جملتين) عن أهم شخص يحتاج التواصل اليوم.

الأقارب:
{{relatives_data}}

الشعلات:
{{streaks_data}}

المناسبات القادمة:
{{occasions_data}}

اكتب نصيحة مختصرة ومحفزة باللهجة السعودية.',
max_tokens = 100
WHERE screen_key = 'home' AND touch_point_key = 'priority_contacts';

-- Log the migration
DO $$
BEGIN
  RAISE NOTICE 'Migration 20260108100000_fix_ai_touch_point_prompts completed';
END $$;
