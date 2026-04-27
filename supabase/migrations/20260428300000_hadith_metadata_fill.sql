-- ============================================================================
-- Phase 6.2 — Hadith metadata fill (founder-approved corrections)
-- ============================================================================
--
-- يصحّح هذا الـmigration ثلاثة صفوف في admin_hadith كانت قد التُقطت
-- خلال Wave 2 من جدول hadith القديم. كانت إشكاليّتها:
--
--   ١. الأرقام المرجعية (Ahmad 7563 و Ahmad 16033) لا تَردُ في
--      الطبعات العلميّة المعتمدة لمسند الإمام أحمد، فحُرّرت إلى
--      المراجع الأَصَحّ بعد بحثٍ خارجيّ.
--   ٢. حقل الراوي (narrator) كان فارغًا في الصفوف الثلاثة.
--
-- البحث جرى على sunnah.com و dorar.net ونسخة الرسالة لمسند أحمد،
-- بالإضافة إلى تخريج الألباني لصحيح ابن حبّان. وافق المؤسس على
-- التصحيحات في 2026-04-27 بدعم بحثيّ من الـCTO.
--
-- المرجعيّات الجديدة:
--   • صحيح البخاري ٦١٣٨ — نفس الموضع، الراوي: أبو هريرة.
--   • مسند أحمد ٨٨٦٨ (طبعة الرسالة) — تصحيح عن ٧٥٦٣، الراوي: أبو هريرة.
--   • صحيح ابن حبّان ٤٤٠ — تصحيح عن Ahmad 16033، الراوي: أبو بكرة.
--
-- البيانات الأصليّة من Wave 2 محفوظة في تاريخ git داخل
-- legacy/schema.sql والـmigration الذي التقط الجدول. لمن يرغب في
-- مراجعة لاحقة: `git show` يكشف الحالة السابقة كما كانت.
--
-- نمط التحديث دفاعيّ: المطابقة على display_priority + جزء من السلسلة
-- الإنكليزيّة في source + شرط narrator IS NULL يضمن idempotency
-- (إعادة التشغيل لا تؤثّر بعد نجاح أوّل تطبيق) ويمنع إصابة صفّ
-- مُماثل أُضيف لاحقًا.
--
-- ============================================================================

-- Row 1 — display_priority 101: Sahih Al-Bukhari 6138 → صحيح البخاري ٦١٣٨
UPDATE public.admin_hadith
SET
  narrator = 'أبو هريرة',
  source = 'صحيح البخاري ٦١٣٨'
WHERE display_priority = 101
  AND source LIKE '%Bukhari%6138%'
  AND narrator IS NULL;

-- Row 2 — display_priority 102: Musnad Ahmad 7563 → مسند أحمد ٨٨٦٨
-- Reference number corrected per al-Risala edition; original 7563 not
-- located in standard scholarly editions.
UPDATE public.admin_hadith
SET
  narrator = 'أبو هريرة',
  source = 'مسند أحمد ٨٨٦٨'
WHERE display_priority = 102
  AND source LIKE '%Ahmad%7563%'
  AND narrator IS NULL;

-- Row 3 — display_priority 103: Musnad Ahmad 16033 → صحيح ابن حبّان ٤٤٠
-- Source collection corrected: the hadith text is more reliably cited
-- from Ibn Hibban 440 (al-Albani's verification). Original Ahmad 16033
-- did not match standard editions.
UPDATE public.admin_hadith
SET
  narrator = 'أبو بكرة',
  source = 'صحيح ابن حبان ٤٤٠'
WHERE display_priority = 103
  AND source LIKE '%Ahmad%16033%'
  AND narrator IS NULL;

-- ============================================================================
-- Self-verification — assert the post-state. Aborts the transaction on
-- any mismatch so prod stays in a consistent state.
-- ============================================================================
DO $$
DECLARE
  v_count INTEGER;
  v_row RECORD;
BEGIN
  -- 1. No NULL narrators on any admin_hadith row after the fill.
  SELECT COUNT(*) INTO v_count
  FROM public.admin_hadith
  WHERE narrator IS NULL;
  IF v_count <> 0 THEN
    RAISE EXCEPTION
      'admin_hadith has % rows with NULL narrator after fill (expected 0)',
      v_count;
  END IF;

  -- 2. No English-style citations remain in source.
  SELECT COUNT(*) INTO v_count
  FROM public.admin_hadith
  WHERE source LIKE '%Bukhari%'
     OR source LIKE '%Ahmad%'
     OR source LIKE '%Sahih%'
     OR source LIKE '%Hibban%'
     OR source ~ '[A-Za-z]';
  IF v_count <> 0 THEN
    RAISE EXCEPTION
      'admin_hadith has % rows with Latin-letter source after fill (expected 0)',
      v_count;
  END IF;

  -- 3. The three target rows have the expected new values.
  SELECT narrator, source INTO v_row
  FROM public.admin_hadith
  WHERE display_priority = 101;
  IF v_row.narrator <> 'أبو هريرة'
     OR v_row.source <> 'صحيح البخاري ٦١٣٨' THEN
    RAISE EXCEPTION
      'display_priority=101 mismatch: narrator=% source=%',
      v_row.narrator, v_row.source;
  END IF;

  SELECT narrator, source INTO v_row
  FROM public.admin_hadith
  WHERE display_priority = 102;
  IF v_row.narrator <> 'أبو هريرة'
     OR v_row.source <> 'مسند أحمد ٨٨٦٨' THEN
    RAISE EXCEPTION
      'display_priority=102 mismatch: narrator=% source=%',
      v_row.narrator, v_row.source;
  END IF;

  SELECT narrator, source INTO v_row
  FROM public.admin_hadith
  WHERE display_priority = 103;
  IF v_row.narrator <> 'أبو بكرة'
     OR v_row.source <> 'صحيح ابن حبان ٤٤٠' THEN
    RAISE EXCEPTION
      'display_priority=103 mismatch: narrator=% source=%',
      v_row.narrator, v_row.source;
  END IF;
END $$;
