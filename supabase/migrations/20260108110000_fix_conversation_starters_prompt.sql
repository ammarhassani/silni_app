-- =============================================================================
-- Fix Conversation Starters Prompt - More specific instructions
-- =============================================================================

-- Update conversation_starters to be more specific and not return templates
UPDATE admin_ai_touch_points
SET prompt_template = 'أنت واصل، مساعد صلة الرحم الذكي. مهمتك تقديم اقتراحات محادثة حقيقية ومفيدة.

معلومات عن القريب:
- الاسم: {{relative_name}}
- صلة القرابة: {{relationship_type}}
- الاهتمامات: {{interests}}
- عدد أيام منذ آخر تواصل: {{last_contact}}

المطلوب:
اقترح 3 مواضيع محددة وعملية للحديث. لا تكتب قوالب أو عبارات عامة. اكتب مواضيع فعلية يمكن استخدامها مباشرة.

مثال على الصيغة المطلوبة:
1. اسأله عن صحته وكيف حاله هذه الأيام
2. تحدث معه عن الطقس والجو في منطقتكم
3. اسأله عن أخبار العائلة والأولاد

اكتب 3 اقتراحات مشابهة ومناسبة لهذا القريب:'
WHERE screen_key = 'relative_detail' AND touch_point_key = 'conversation_starters';

-- Log
DO $$
BEGIN
  RAISE NOTICE 'Migration 20260108110000_fix_conversation_starters_prompt completed';
END $$;
