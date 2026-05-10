-- Phase γ.2-prep — Task 1: seed admin_ai_identity with one editable row.
--
-- بذرة افتراضية لجدول admin_ai_identity. النص هنا مطابق للـ fallback في
-- lib/core/ai/ai_identity.dart. سيتم تحرير المحتوى لاحقاً عبر لوحة الإدارة.
--
-- Why this migration exists:
--
-- The Phase 6.1 rename migration (20260428100000) deliberately left
-- admin_ai_identity empty, reasoning that AIIdentityConfig.fallback() in
-- lib/core/services/ai_config_service.dart was the source of truth for v1.
-- Phase γ.1's ADMIN_PANEL_ARCHITECTURE_VERIFICATION found that this leaves
-- the founder unable to edit identity from silni-admin (the panel page
-- exists but is edit-only — no row, nothing to edit).
--
-- Decision (CTO, 2026-05-03): seed exactly one row matching the fallback
-- so that production behavior is unchanged at apply-time, but the founder
-- can now open silni-admin → AI → Identity, see the row, and edit it.
-- Phase γ.2 content (the new persona, role, greeting) will be pasted in
-- via that UI — not via SQL.
--
-- Defensive:
--   - Wrapped in IF NOT EXISTS guard so re-running the migration is a no-op.
--   - Self-verification block at the end asserts >= 1 active row exists.

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.admin_ai_identity WHERE is_active = true) THEN
    INSERT INTO public.admin_ai_identity (
      ai_name,
      ai_name_en,
      ai_role_ar,
      ai_role_en,
      greeting_message_ar,
      greeting_message_en,
      dialect,
      personality_summary_ar,
      ai_avatar_url,
      is_active
    ) VALUES (
      'أنيس',
      'Wasel',
      'مساعد ذكي متخصص في صلة الرحم والعلاقات الأسرية',
      'Smart assistant for family connections',
      'السلام عليكم! أنا أنيس، مساعدك الشخصي لصلة الرحم. كيف يمكنني مساعدتك اليوم؟',
      NULL,
      'saudi_arabic',
      NULL,
      NULL,
      true
    );
  END IF;
END $$;

-- Self-verification — at least one active row must exist after this runs.
DO $$
DECLARE
  active_count int;
BEGIN
  SELECT count(*) INTO active_count
  FROM public.admin_ai_identity
  WHERE is_active = true;

  IF active_count < 1 THEN
    RAISE EXCEPTION 'admin_ai_identity seed failed — no active row exists';
  END IF;
END $$;
