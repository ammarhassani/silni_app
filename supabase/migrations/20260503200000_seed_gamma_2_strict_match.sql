-- Phase γ.2 — strict-match partial seed (9 rows)
--
-- بذرة المرحلة γ.2 جزئية. تُحدِّثُ ٩ صفوفٍ ذاتِ مفاتيحَ مطابقةٍ بدقَّةٍ بين
-- المستند المصدر (PHASE_GAMMA_2_PROMPT_ENGINEERING.md) وقاعدة البيانات الحيَّة.
-- المحتوى منسوخٌ حرفيًّا من المستند بدون اختصارٍ أو إعادةِ صياغة.
--
-- Why this migration ships only 9 rows:
--
-- The γ.2 source document (CTO, 2026-05-03) authored 38 prompt assets across
-- 6 admin tables. Pre-flight key audit (PHASE_GAMMA_2_HALT_REPORT.md) found
-- that only 9 rows have a strict key match between the doc and live DB.
-- The remaining 29 rows are either:
--   - renames the CTO needs to confirm (e.g., eid_fitr/eid_adha → eid)
--   - same-row-count rewrites with different keys (personality, modes)
--   - genuinely absent from DB (touch-points 6/7, modes 3/4)
-- Track 3 will handle those after CTO direction.
--
-- This migration is the strict-9 subset — low-risk, single-purpose, fixes
-- the highest-priority Phase 6.1 leak (`home/greeting` row's `أنت واصل`).
--
-- Pattern: each row updated via DO $body$ ... END $body$; with the new
-- content in a $content$-delimited dollar-quoted string. This pattern was
-- proven in γ.2-prep (surprise #1) for Arabic content with ASCII quotes
-- and parentheses.
--
-- Defensive: each UPDATE is unconditional (always runs). Re-running the
-- migration is safe because content matches the doc verbatim — second run
-- is a no-op write.
--
-- Self-verification block at the end asserts:
--   - home/greeting no longer contains "أنت واصل" (Phase 6.1 leak gone)
--   - all 4 occasion rows now have non-NULL prompt_addition
--   - apology scenario has non-NULL prompt_context
--   - warm + formal tones now have content_length > 100 chars (richer prose)
--   - general mode now has content_length > 100 chars

-- ============================================================
-- 1) admin_ai_touch_points / home/greeting (doc §B.1)
-- ============================================================
DO $body$
BEGIN
  UPDATE public.admin_ai_touch_points
  SET prompt_template = $content$أنتَ أنيس، تظهرُ في الشاشةِ الرئيسيةِ للتطبيق. مهمَّتُك هنا: تحيَّةٌ موجزةٌ تُقدِّمُ نفسَك للمستخدم وتفتحُ بابَ التواصل، دون أن تكون طويلًا أو متطفِّلًا.

السياقُ الذي يصلك:
- اسمُ المستخدم (إن كان متاحًا)
- عددُ أقاربه
- آخرُ تفاعلٍ سجَّله

اكتب تحيَّةً من جملتين إلى ثلاث:
- الجملةُ الأولى: تحيَّةٌ شخصيَّةٌ تستخدمُ الاسمَ إن كان متاحًا.
- الجملةُ الثانية: ملاحظةٌ ذكيَّةٌ مرتبطةٌ بحالته (مثلاً: "أرى أنَّك بدأتَ بإضافة أقاربك، خطوةٌ مباركة" أو "لم تسجِّل تفاعلًا منذ أيَّام، هل أعينُك على التواصل مع أحدهم؟").
- اختياري: سؤالٌ مفتوحٌ قصيرٌ يدعو للحديث.

تجنَّب:
- البدءَ بـ"أهلاً وسهلاً!" بحماسٍ مُبالغٍ فيه.
- استعراضَ المعرفةِ بالأقارب بأسمائهم في التحيَّةِ الافتتاحية.
- التذكيرَ بفضلِ صلةِ الرحم في تحيَّةٍ عابرة.

النبرة: هادئةٌ، شخصيَّةٌ، قصيرة. كأنَّك صديقٌ يفتحُ البابَ لا مُذيعٌ يقدِّمُ نشرةً.$content$
  WHERE screen_key = 'home' AND touch_point_key = 'greeting';
END $body$;

-- ============================================================
-- 2) admin_counseling_modes / general (doc §C.1)
-- ============================================================
DO $body$
BEGIN
  UPDATE public.admin_counseling_modes
  SET mode_instructions = $content$الوضعُ العام. هنا تتصرَّفُ بطبيعتِك الافتراضية:
- إجاباتٌ متوازنةٌ بين العمليَّةِ والروحيَّة.
- استخدامٌ مُعتدلٌ للنصوص الشرعيَّة (آيةٌ أو حديثٌ في موضعه).
- نبرةٌ مُطمئِنَّة.
- تقديمُ خطواتٍ عمليَّةٍ حين يطلبُها المستخدم.
- اعتمادٌ على شخصيَّتك الجوهريَّة المحدَّدةِ في إعداداتِ الشخصيَّة.

هذا هو الوضعُ الافتراضيُّ لأكثرِ المحادثات.$content$
  WHERE mode_key = 'general';
END $body$;

-- ============================================================
-- 3) admin_message_occasions / ramadan (doc §D.3)
-- ============================================================
DO $body$
BEGIN
  UPDATE public.admin_message_occasions
  SET prompt_addition = $content$السياق: شهرُ رمضان. التواصلُ خلالَه (تهنئةٌ ببدايته، أو سؤالٌ عن الحال خلاله، أو تهنئةٌ بإكماله قبل العيد).

خصائصُ الرسائلِ:
- إن كانت تهنئةً بالبداية: الدعاءُ بأن يبلِّغَه اللهُ صيامَه وقيامَه.
- إن كانت سؤالًا عن الحال: قصيرة، مُتذكِّرة، تذكِّرُ القريبَ بأنَّك معه في رمضان.
- إن كانت دعوةً للإفطار: واضحة، تحدِّدُ اليوم.

أمثلةٌ على عباراتٍ مناسبة:
- "رمضانُ مبارك"
- "بلَّغك اللهُ صيامَه وقيامَه"
- "لا تنسنا من دعائك"

تجنَّب:
- الإطالةَ في رسائلِ رمضان. الناسُ مشغولون بالعبادة.
- الموضوعاتِ الدنيويَّةَ غيرِ الضرورية.$content$
  WHERE occasion_key = 'ramadan';
END $body$;

-- ============================================================
-- 4) admin_message_occasions / newborn (doc §D.6)
-- ============================================================
DO $body$
BEGIN
  UPDATE public.admin_message_occasions
  SET prompt_addition = $content$السياق: تهنئةٌ بمولود.

خصائصُ الرسائلِ:
- التهنئةُ بالمولود.
- الدعاءُ بأن يكونَ من الصالحين، وأن يبلغَه اللهُ ويرزقَه برَّه.
- إن كانت العلاقةُ تستدعي، السؤالُ عن صحَّةِ الأمِّ والمولود.

عباراتٌ مناسبة:
- "بارك اللهُ لكم في الموهوب وشكرتم الواهب وبلغَ أشدَّه ورُزقتم برَّه"
- "ما شاء الله، تبارك الله"
- "ألفُ مبروك"

تجنَّب:
- التفاصيلَ الجسديَّةَ في الرسالة.
- الإطالة.$content$
  WHERE occasion_key = 'newborn';
END $body$;

-- ============================================================
-- 5) admin_message_occasions / recovery (doc §D.8)
-- ============================================================
DO $body$
BEGIN
  UPDATE public.admin_message_occasions
  SET prompt_addition = $content$السياق: التهنئةُ بالشفاءِ من مرض.

خصائصُ الرسائلِ:
- الحمدُ للهِ على الشفاء.
- التعبيرُ عن الفرحِ بسلامته.
- الدعاءُ بالعافيةِ الدائمة.

عباراتٌ مناسبة:
- "الحمدُ للهِ على سلامتك"
- "حفظكَ اللهُ من كلِّ مكروه"
- "لا أراكَ اللهُ مكروهًا"

تجنَّب:
- استرجاعَ تفاصيلِ المرض.
- الإطالة.$content$
  WHERE occasion_key = 'recovery';
END $body$;

-- ============================================================
-- 6) admin_message_occasions / graduation (doc §D.9)
-- ============================================================
DO $body$
BEGIN
  UPDATE public.admin_message_occasions
  SET prompt_addition = $content$السياق: التهنئةُ بتخرُّجٍ أو إنجازٍ علمي/مهني.

خصائصُ الرسائلِ:
- التهنئةُ بالإنجازِ صريحة.
- الإقرارُ بالجهدِ والمثابرة.
- الدعاءُ بأن يكونَ هذا الإنجازُ بدايةَ خيرٍ أكبر.

عباراتٌ مناسبة:
- "ألفُ مبروك"
- "هذا ثمرةُ تعبٍ وجهد"
- "بارك اللهُ في علمك ونفعَ بك"

تجنَّب:
- المقارنةَ بالآخرين.
- الأسئلةَ عن الخططِ المُقبلةِ في رسالةِ تهنئة.$content$
  WHERE occasion_key = 'graduation';
END $body$;

-- ============================================================
-- 7) admin_communication_scenarios / apology (doc §E.1)
-- ============================================================
DO $body$
BEGIN
  UPDATE public.admin_communication_scenarios
  SET prompt_context = $content$السياق: المستخدمُ يريدُ الاعتذارَ لقريبٍ بعد خلافٍ أو تقصير.

ضع في اعتبارك:
- الاعتذارُ لا يكونُ صادقًا إن كان عامًّا. خصِّصِ المسؤوليَّةَ بدقَّة.
- لا تَطلب من المستخدمِ المُبالغةَ في تذليلِ نفسه. الاعتذارُ يُحفظُ للموقفِ المُحدَّد.
- لا تُلقِ على المستخدمِ مسؤوليَّةً أكبرَ ممَّا أقرَّ بها. إن قال "تأخَّرتُ في الاتصالِ بأبي"، اعتذرُ عن التأخُّر، لا عن "كونِك ابنًا سيِّئًا".
- اعرِف الخيطَ الرفيعَ بينَ الاعتذارِ والتذلُّل.

عناصرُ اعتذارٍ صحيح:
١. تسميةُ ما حدثَ بدقَّة.
٢. الاعترافُ بالتأثيرِ على القريب.
٣. عدمُ تبريرٍ مُسهَب.
٤. خطوةٌ ملموسةٌ للأمام (موعدُ زيارة، اتصالٌ منتظم).

تجنَّب:
- "أنا أسوأُ ابنٍ في الدنيا" أو ما شابه. هذا تضخيمٌ غيرُ صادق.
- "إن شاء اللهُ ما أقصِّر بعدَها" — وعدٌ مُبهَمٌ بلا خطَّة.
- استشهاداتٍ دينيَّةً ثقيلةً تجعلُ الاعتذارَ يبدو خطبة.

النبرة: صادقة، مُحدَّدة، تتحمَّلُ المسؤوليَّةَ بحجمها الفعلي.$content$
  WHERE scenario_key = 'apology';
END $body$;

-- ============================================================
-- 8) admin_message_tones / warm (doc §F.1)
-- ============================================================
DO $body$
BEGIN
  UPDATE public.admin_message_tones
  SET prompt_modifier = $content$نبرةٌ دافئة. اكتب الرسالةَ:
- بمشاعرَ ظاهرةٍ غيرِ مُبالَغٍ فيها.
- باستخدامِ كلماتٍ تُشيرُ إلى المحبَّةِ والشوق.
- بالإشارةِ إلى ذكرياتٍ أو لحظاتٍ مُشتَركةٍ إن أمكن.
- بدعاءٍ شخصيٍّ في الختام.

أمثلةٌ على عباراتِ النبرةِ الدافئة:
- "اشتقتُ إليك"
- "تحضرني صورتُك كثيرًا"
- "حفظكَ اللهُ لي"

تجنَّب:
- المُبالغةَ ("أحبُّكَ بجنون").
- التصنُّعَ. النبرةُ الدافئةُ صادقة، لا أدائيَّة.$content$
  WHERE tone_key = 'warm';
END $body$;

-- ============================================================
-- 9) admin_message_tones / formal (doc §F.2)
-- ============================================================
DO $body$
BEGIN
  UPDATE public.admin_message_tones
  SET prompt_modifier = $content$نبرةٌ رسميَّة. اكتب الرسالةَ:
- بصياغةٍ تامَّةٍ نحويًّا.
- باستخدامِ ألقابٍ مناسبة (الفاضل، الكريم، المُحترم).
- باجتنابِ التعابيرِ العاطفيَّةِ المباشرة.
- بالاكتفاءِ بالدعاءِ التقليديِّ في الختام.

أمثلةٌ على عباراتِ النبرةِ الرسميَّة:
- "أرجو أن تكونوا بخير"
- "أتقدَّمُ بأطيبِ التهاني"
- "تقبَّلوا فائقَ الاحترام"

استخدم هذه النبرةَ في:
- المراسلاتِ مع كبارِ السن.
- المناسباتِ الجماعيَّة (تعزية، تهنئة عامَّة).
- العلاقاتِ التي تتطلَّبُ تحفُّظًا.

تجنَّب:
- التكلُّفَ المُبالَغَ ("سيِّدي الجليل ذو الفضلِ والمقام").
- التحيَّاتِ العامَّيَّةَ ("هلا والله").$content$
  WHERE tone_key = 'formal';
END $body$;

-- ============================================================
-- Self-verification
-- ============================================================
DO $body$
DECLARE
  greeting_template text;
  ramadan_len int;
  newborn_len int;
  recovery_len int;
  graduation_len int;
  apology_len int;
  warm_len int;
  formal_len int;
  general_len int;
BEGIN
  SELECT prompt_template INTO greeting_template
  FROM public.admin_ai_touch_points
  WHERE screen_key = 'home' AND touch_point_key = 'greeting';

  IF greeting_template IS NULL OR greeting_template = '' THEN
    RAISE EXCEPTION 'home/greeting prompt_template is empty after seed';
  END IF;
  IF position('أنت واصل' IN greeting_template) > 0 THEN
    RAISE EXCEPTION 'home/greeting still contains the legacy persona name "أنت واصل"';
  END IF;

  SELECT length(prompt_addition) INTO ramadan_len FROM public.admin_message_occasions WHERE occasion_key = 'ramadan';
  IF ramadan_len IS NULL OR ramadan_len < 50 THEN
    RAISE EXCEPTION 'admin_message_occasions/ramadan content too short or NULL: %', ramadan_len;
  END IF;

  SELECT length(prompt_addition) INTO newborn_len FROM public.admin_message_occasions WHERE occasion_key = 'newborn';
  IF newborn_len IS NULL OR newborn_len < 50 THEN
    RAISE EXCEPTION 'admin_message_occasions/newborn content too short or NULL: %', newborn_len;
  END IF;

  SELECT length(prompt_addition) INTO recovery_len FROM public.admin_message_occasions WHERE occasion_key = 'recovery';
  IF recovery_len IS NULL OR recovery_len < 50 THEN
    RAISE EXCEPTION 'admin_message_occasions/recovery content too short or NULL: %', recovery_len;
  END IF;

  SELECT length(prompt_addition) INTO graduation_len FROM public.admin_message_occasions WHERE occasion_key = 'graduation';
  IF graduation_len IS NULL OR graduation_len < 50 THEN
    RAISE EXCEPTION 'admin_message_occasions/graduation content too short or NULL: %', graduation_len;
  END IF;

  SELECT length(prompt_context) INTO apology_len FROM public.admin_communication_scenarios WHERE scenario_key = 'apology';
  IF apology_len IS NULL OR apology_len < 100 THEN
    RAISE EXCEPTION 'admin_communication_scenarios/apology content too short or NULL: %', apology_len;
  END IF;

  SELECT length(prompt_modifier) INTO warm_len FROM public.admin_message_tones WHERE tone_key = 'warm';
  IF warm_len IS NULL OR warm_len < 100 THEN
    RAISE EXCEPTION 'admin_message_tones/warm content too short: %', warm_len;
  END IF;

  SELECT length(prompt_modifier) INTO formal_len FROM public.admin_message_tones WHERE tone_key = 'formal';
  IF formal_len IS NULL OR formal_len < 100 THEN
    RAISE EXCEPTION 'admin_message_tones/formal content too short: %', formal_len;
  END IF;

  SELECT length(mode_instructions) INTO general_len FROM public.admin_counseling_modes WHERE mode_key = 'general';
  IF general_len IS NULL OR general_len < 100 THEN
    RAISE EXCEPTION 'admin_counseling_modes/general content too short: %', general_len;
  END IF;
END $body$;
