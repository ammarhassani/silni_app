-- =============================================================================
-- Optimize AI Speed - Reduce tokens and simplify prompts
-- =============================================================================

-- Reduce max_tokens for all touch points to speed up responses
UPDATE admin_ai_touch_points SET max_tokens = 80 WHERE touch_point_key = 'greeting';
UPDATE admin_ai_touch_points SET max_tokens = 100 WHERE touch_point_key = 'priority_contacts';
UPDATE admin_ai_touch_points SET max_tokens = 60 WHERE touch_point_key = 'insight';
UPDATE admin_ai_touch_points SET max_tokens = 120 WHERE touch_point_key = 'conversation_starters';
UPDATE admin_ai_touch_points SET max_tokens = 60 WHERE touch_point_key = 'health_explanation';
UPDATE admin_ai_touch_points SET max_tokens = 40 WHERE touch_point_key = 'time_suggestion';
UPDATE admin_ai_touch_points SET max_tokens = 50 WHERE touch_point_key = 'frequency_recommendation';

-- Update insight to be more concise
UPDATE admin_ai_touch_points
SET prompt_template = 'بناءً على الإحصائيات التالية، اكتب ملاحظة واحدة مختصرة ومحفزة (جملة واحدة فقط):
- علاقات صحية: {{healthy_count}}
- تحتاج اهتمام: {{needs_attention_count}}
- معرضة للخطر: {{at_risk_count}}
- شعلات نشطة: {{active_streaks}}

اكتب جملة واحدة فقط:'
WHERE screen_key = 'home' AND touch_point_key = 'insight';

-- Log
DO $$
BEGIN
  RAISE NOTICE 'Migration 20260108120000_optimize_ai_speed completed';
END $$;
