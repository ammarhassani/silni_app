-- ============================================================================
-- Phase 8 — Hadith row 103 grade correction
-- ============================================================================
--
-- يصحّح هذا الـmigration درجة (grade) الصفّ ١٠٣ في admin_hadith بحيث
-- توافق المرجع الجديد. كانت الدرجة الأصليّة من Wave 2 هي «حسن»
-- وكانت صحيحة بالنسبة لمسند أحمد. وبعد أن صحّحنا المرجع في
-- Phase 6.2 إلى «صحيح ابن حبّان ٤٤٠»، تصبح الدرجة الموافقة لتخريج
-- الألباني هي «صحيح».
--
-- وافق المؤسس والـCTO على هذا التصحيح في 2026-04-27.
--
-- نمط التحديث دفاعيّ: يطابق على display_priority + المرجع الجديد +
-- الدرجة القديمة، فلا يصيب صفًّا غيره ولا يعيد التطبيق نفسه على نفسه
-- بعد الانتهاء (idempotency).
--
-- ============================================================================

UPDATE public.admin_hadith
SET grade = 'صحيح'
WHERE display_priority = 103
  AND source = 'صحيح ابن حبان ٤٤٠'
  AND grade = 'حسن';

-- ============================================================================
-- Self-verification
-- ============================================================================
DO $$
DECLARE
  v_grade TEXT;
  v_source TEXT;
BEGIN
  SELECT grade, source INTO v_grade, v_source
  FROM public.admin_hadith
  WHERE display_priority = 103;

  IF v_source <> 'صحيح ابن حبان ٤٤٠' THEN
    RAISE EXCEPTION
      'display_priority=103 source mismatch: got % (expected صحيح ابن حبان ٤٤٠)',
      v_source;
  END IF;

  IF v_grade <> 'صحيح' THEN
    RAISE EXCEPTION
      'display_priority=103 grade mismatch: got % (expected صحيح)',
      v_grade;
  END IF;
END $$;
