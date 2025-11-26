-- =====================================================
-- SEED HADITH DATA
-- Run this in Supabase Dashboard → SQL Editor → STAGING
-- =====================================================

-- Insert authentic hadith about Silat Rahim (family ties)
INSERT INTO hadith (arabic_text, english_translation, source, reference, topic, type, is_authentic, display_order)
VALUES
  (
    'من سره أن يبسط له في رزقه، وأن ينسأ له في أثره، فليصل رحمه',
    'Whoever would like his provision to be increased and his life to be extended, should uphold the ties of kinship',
    'Sahih Al-Bukhari',
    'Hadith 5986',
    'silat_rahim',
    'hadith',
    true,
    1
  ),
  (
    'الرحم معلقة بالعرش تقول: من وصلني وصله الله، ومن قطعني قطعه الله',
    'The womb (kinship) is suspended from the Throne, saying: "Whoever upholds me, Allah will uphold him, and whoever severs me, Allah will sever him"',
    'Sahih Al-Bukhari',
    'Hadith 5988',
    'silat_rahim',
    'hadith',
    true,
    2
  ),
  (
    'ليس الواصل بالمكافئ، ولكن الواصل الذي إذا قطعت رحمه وصلها',
    'The one who maintains ties of kinship is not the one who reciprocates. Rather, it is the one who, when his relatives cut him off, maintains ties with them',
    'Sahih Al-Bukhari',
    'Hadith 5991',
    'silat_rahim',
    'hadith',
    true,
    3
  ),
  (
    'من كان يؤمن بالله واليوم الآخر فليصل رحمه',
    'Whoever believes in Allah and the Last Day should maintain ties of kinship',
    'Sahih Al-Bukhari',
    'Hadith 6138',
    'silat_rahim',
    'hadith',
    true,
    4
  ),
  (
    'صلة الرحم محبة في الأهل، مثراة في المال، منسأة في الأثر',
    'Maintaining family ties brings love among relatives, increases wealth, and extends one''s lifespan',
    'Musnad Ahmad',
    'Hadith 7563',
    'silat_rahim',
    'hadith',
    true,
    5
  ),
  (
    'تعلموا من أنسابكم ما تصلون به أرحامكم',
    'Learn about your lineage that which will help you maintain your family ties',
    'Sunan At-Tirmidhi',
    'Hadith 1979',
    'silat_rahim',
    'hadith',
    true,
    6
  ),
  (
    'إن أعجل الطاعة ثواباً صلة الرحم',
    'The quickest act of obedience to be rewarded is maintaining family ties',
    'Musnad Ahmad',
    'Hadith 16033',
    'silat_rahim',
    'hadith',
    true,
    7
  ),
  (
    'لا يدخل الجنة قاطع رحم',
    'The one who severs family ties will not enter Paradise',
    'Sahih Al-Bukhari',
    'Hadith 5984',
    'silat_rahim',
    'hadith',
    true,
    8
  )
ON CONFLICT DO NOTHING;

-- Verify the data was inserted
SELECT 'Hadith seeded successfully!' as status;
SELECT COUNT(*) as total_hadith FROM hadith WHERE topic = 'silat_rahim';
SELECT arabic_text, display_order FROM hadith WHERE topic = 'silat_rahim' ORDER BY display_order;
