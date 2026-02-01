-- Add Saudi dialect notification templates to admin_ui_strings
-- These mirror the hardcoded templates in notification_templates.dart
-- and can be updated remotely via the admin panel.

INSERT INTO admin_ui_strings (string_key, category, value_ar, value_en, description, screen, is_active) VALUES
-- Gentle reminders (1-3 days)
('reminder_gentle_1', 'notifications', '{name} يسلم عليك', '{name} says hi', 'Gentle reminder 1-3 days', 'notification', true),
('reminder_gentle_2', 'notifications', '{name} وش أخبارهم؟', 'How is {name}?', 'Gentle reminder 1-3 days', 'notification', true),
('reminder_gentle_3', 'notifications', 'سلّم على {name} اليوم', 'Say hi to {name} today', 'Gentle reminder 1-3 days', 'notification', true),
('reminder_gentle_4', 'notifications', 'شكلك ناسي {name}', 'Looks like you forgot {name}', 'Gentle reminder 1-3 days', 'notification', true),
('reminder_gentle_5', 'notifications', '{name} لهم {days} أيام ما سمعوا صوتك', '{name} hasn''t heard your voice in {days} days', 'Gentle reminder 1-3 days', 'notification', true),
-- Moderate reminders (4-13 days)
('reminder_moderate_1', 'notifications', '{name} لهم أسبوع ما حد كلمهم', '{name} hasn''t heard from anyone in a week', 'Moderate reminder 4-13 days', 'notification', true),
('reminder_moderate_2', 'notifications', 'وش أخبار {name}؟ لهم {days} أيام', 'How is {name}? It''s been {days} days', 'Moderate reminder 4-13 days', 'notification', true),
('reminder_moderate_3', 'notifications', '{name} يمكن يحتاجون يسمعون صوتك', '{name} might need to hear your voice', 'Moderate reminder 4-13 days', 'notification', true),
('reminder_moderate_4', 'notifications', 'ما كلمت {name} من {days} يوم', 'You haven''t talked to {name} in {days} days', 'Moderate reminder 4-13 days', 'notification', true),
('reminder_moderate_5', 'notifications', '{name} وش سالفتهم؟ طولت عليهم', 'What''s up with {name}? It''s been a while', 'Moderate reminder 4-13 days', 'notification', true),
-- Direct reminders (14-29 days)
('reminder_direct_1', 'notifications', '{name} لهم أسبوعين ما سمعوا صوتك', '{name} hasn''t heard your voice in 2 weeks', 'Direct reminder 14-29 days', 'notification', true),
('reminder_direct_2', 'notifications', 'لهم أسبوعين ما كلمت {name}، وش رايك تطمن عليهم؟', 'It''s been 2 weeks since you talked to {name}, check on them?', 'Direct reminder 14-29 days', 'notification', true),
('reminder_direct_3', 'notifications', '{name} من أسبوعين ما سمعوا منك', '{name} hasn''t heard from you in 2 weeks', 'Direct reminder 14-29 days', 'notification', true),
('reminder_direct_4', 'notifications', 'طولت على {name}، لهم أسبوعين', 'It''s been too long with {name}, 2 weeks', 'Direct reminder 14-29 days', 'notification', true),
('reminder_direct_5', 'notifications', '{name} ينتظرون اتصالك، لهم أكثر من أسبوعين', '{name} is waiting for your call, over 2 weeks', 'Direct reminder 14-29 days', 'notification', true),
-- Heavy reminders (30+ days)
('reminder_heavy_1', 'notifications', 'آخر مرة كلمت {name} كان قبل شهر', 'Last time you talked to {name} was a month ago', 'Heavy reminder 30+ days', 'notification', true),
('reminder_heavy_2', 'notifications', '{name} لهم أكثر من شهر ما سمعوا منك', '{name} hasn''t heard from you in over a month', 'Heavy reminder 30+ days', 'notification', true),
('reminder_heavy_3', 'notifications', 'شهر كامل ما تواصلت مع {name}', 'A whole month without contacting {name}', 'Heavy reminder 30+ days', 'notification', true),
('reminder_heavy_4', 'notifications', '{name} لهم شهر، الوقت يمر بسرعة', '{name}, it''s been a month, time flies', 'Heavy reminder 30+ days', 'notification', true),
('reminder_heavy_5', 'notifications', 'صلة الرحم مع {name} محتاجة اهتمام، لهم شهر', 'Your bond with {name} needs attention, it''s been a month', 'Heavy reminder 30+ days', 'notification', true),
-- Streak celebration messages
('streak_celebration_1', 'notifications', 'يا وصّال العيلة! {streak} يوم ما وقفت 🔥', 'Family connector! {streak} days going strong 🔥', 'Streak celebration', 'notification', true),
('streak_celebration_2', 'notifications', 'سلسلة {streak} يوم! أنت قدها 🔥', '{streak} day streak! You got this 🔥', 'Streak celebration', 'notification', true),
('streak_celebration_3', 'notifications', '{streak} يوم متواصل! الله يبارك فيك', '{streak} days straight! May God bless you', 'Streak celebration', 'notification', true),
('streak_celebration_4', 'notifications', 'ما شاء الله، {streak} يوم! كمّل', 'MashaAllah, {streak} days! Keep it up', 'Streak celebration', 'notification', true),
-- Badge unlock messages
('badge_unlock_1', 'notifications', 'يا بطل، شارة جديدة تستاهلها!', 'Champ, you earned a new badge!', 'Badge unlock', 'notification', true),
('badge_unlock_2', 'notifications', 'وسام جديد! أنت تستاهل', 'New medal! You deserve it', 'Badge unlock', 'notification', true),
('badge_unlock_3', 'notifications', 'حصلت على شارة جديدة، يا وصّال!', 'You got a new badge, connector!', 'Badge unlock', 'notification', true),
-- Level up messages
('level_up_1', 'notifications', 'مستوى جديد! كل ما تتواصل كل ما ترتقي', 'New level! The more you connect the higher you rise', 'Level up', 'notification', true),
('level_up_2', 'notifications', 'ارتقيت لمستوى {level}! الله يوفقك', 'You reached level {level}! May God guide you', 'Level up', 'notification', true),
('level_up_3', 'notifications', 'مستوى {level}! أنت من أفضل الوصّالين', 'Level {level}! You are among the best connectors', 'Level up', 'notification', true)
ON CONFLICT (string_key) DO NOTHING;
