-- =============================================================================
-- Gender-Aware Conversation Starters
-- =============================================================================

-- Update conversation starters prompt to be gender-aware and use proper context
UPDATE admin_ai_touch_points
SET prompt_template = 'أنت مساعد عربي متخصص في تقوية صلة الرحم.

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
    max_tokens = 150,
    temperature = 0.8
WHERE screen_key = 'relative_detail' AND touch_point_key = 'conversation_starters';

-- Log
DO $$
BEGIN
  RAISE NOTICE 'Migration 20260108130000_gender_aware_conversation_starters completed';
END $$;
