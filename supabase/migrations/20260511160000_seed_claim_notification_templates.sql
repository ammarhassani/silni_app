-- 20260511160000_seed_claim_notification_templates.sql
-- Templates used by client-side notification dispatch when claim status changes.
-- Drift reconciled: extend admin_notification_templates_category_check to include
-- 'family_sharing' (existing allowed values: reminder, streak, badge, level,
-- challenge, system, promotional, nudge). Column names match the plan/spec.

ALTER TABLE admin_notification_templates
  DROP CONSTRAINT IF EXISTS admin_notification_templates_category_check;

ALTER TABLE admin_notification_templates
  ADD CONSTRAINT admin_notification_templates_category_check
  CHECK (category = ANY (ARRAY[
    'reminder'::text,
    'streak'::text,
    'badge'::text,
    'level'::text,
    'challenge'::text,
    'system'::text,
    'promotional'::text,
    'nudge'::text,
    'family_sharing'::text
  ]));

INSERT INTO admin_notification_templates (template_key, title_ar, body_ar, category, variables, is_active)
VALUES
  ('claim_pending',
   'طلب انضمام جديد في {group_name}',
   '{claimant_name} يطلب الانضمام كـ {role_label}. اضغط للمراجعة.',
   'family_sharing',
   '["group_name","claimant_name","role_label"]'::jsonb,
   true),
  ('claim_approved',
   'تمت إضافتك إلى {group_name}',
   'وافق المدير على طلبك. مرحباً بك في العائلة!',
   'family_sharing',
   '["group_name"]'::jsonb,
   true),
  ('claim_rejected',
   'لم يتم قبول طلبك في {group_name}',
   '{reason_text} يمكنك تعديل بياناتك وإعادة المحاولة.',
   'family_sharing',
   '["group_name","reason_text"]'::jsonb,
   true)
ON CONFLICT (template_key) DO NOTHING;
