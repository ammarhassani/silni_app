-- Add missing badges to admin_badges table
-- These are special achievement badges with various threshold types

-- First, drop the existing CHECK constraint and add a new one with all threshold types
ALTER TABLE admin_badges DROP CONSTRAINT IF EXISTS admin_badges_threshold_type_check;

ALTER TABLE admin_badges ADD CONSTRAINT admin_badges_threshold_type_check
  CHECK (threshold_type IN (
    'streak_days',
    'total_interactions',
    'first_interaction',
    'unique_interaction_types',
    'unique_relatives',
    'gift_count',
    'event_count',
    'call_count',
    'visit_count',
    'message_count',
    'custom'
  ));

INSERT INTO admin_badges (badge_key, display_name_ar, display_name_en, description_ar, emoji, category, threshold_type, threshold_value, xp_reward, sort_order) VALUES
  -- First interaction badge
  ('first_interaction', 'أول تفاعل', 'First Interaction', 'سجلت أول تفاعل لك', '🎯', 'milestone', 'first_interaction', 1, 25, 0),

  -- Variety badges
  ('all_interaction_types', 'متنوع', 'Versatile', 'استخدمت جميع أنواع التفاعل', '🎨', 'special', 'unique_interaction_types', 6, 300, 20),
  ('social_butterfly', 'اجتماعي', 'Social Butterfly', 'تفاعلت مع 10 أقارب مختلفين', '🦋', 'special', 'unique_relatives', 10, 200, 21),

  -- Specific type badges
  ('generous_giver', 'كريم', 'Generous Giver', 'قدمت 10+ هدايا', '🎁', 'special', 'gift_count', 10, 150, 22),
  ('family_gatherer', 'جامع العائلة', 'Family Gatherer', 'نظمت 10+ مناسبات عائلية', '👨‍👩‍👧‍👦', 'special', 'event_count', 10, 150, 23),
  ('frequent_caller', 'كثير الاتصال', 'Frequent Caller', 'أجريت 50+ مكالمة', '📞', 'special', 'call_count', 50, 200, 24),
  ('devoted_visitor', 'زائر مخلص', 'Devoted Visitor', 'قمت بـ 25+ زيارة', '🏠', 'special', 'visit_count', 25, 200, 25)
ON CONFLICT (badge_key) DO UPDATE SET
  display_name_ar = EXCLUDED.display_name_ar,
  display_name_en = EXCLUDED.display_name_en,
  description_ar = EXCLUDED.description_ar,
  emoji = EXCLUDED.emoji,
  category = EXCLUDED.category,
  threshold_type = EXCLUDED.threshold_type,
  threshold_value = EXCLUDED.threshold_value,
  xp_reward = EXCLUDED.xp_reward,
  sort_order = EXCLUDED.sort_order;
