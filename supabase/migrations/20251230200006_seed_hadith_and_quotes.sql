-- Seed admin_hadith with authentic hadith about family ties (صلة الرحم)
-- These are migrated from the app's hardcoded defaults

INSERT INTO admin_hadith (hadith_text, source, narrator, grade, category, tags, display_priority, is_active) VALUES
  (
    'قال رسول الله ﷺ: "مَن أَحَبَّ أَنْ يُبْسَطَ له في رِزْقِهِ، وَيُنْسَأَ له في أَثَرِهِ، فَلْيَصِلْ رَحِمَهُ"',
    'صحيح البخاري ٥٩٨٦',
    'أنس بن مالك',
    'صحيح',
    'silat_rahim',
    ARRAY['صلة الرحم', 'الرزق', 'البركة'],
    100,
    true
  ),
  (
    'قال رسول الله ﷺ: "الرَّحِمُ مُعَلَّقَةٌ بالعَرْشِ تَقُولُ: مَن وصَلَنِي وصَلَهُ اللَّهُ، ومَن قَطَعَنِي قَطَعَهُ اللَّهُ"',
    'صحيح البخاري ٥٩٨٨',
    'عبد الرحمن بن عوف',
    'صحيح',
    'silat_rahim',
    ARRAY['صلة الرحم', 'العرش'],
    99,
    true
  ),
  (
    'قال رسول الله ﷺ: "لا يَدْخُلُ الجَنَّةَ قاطِعُ رَحِمٍ"',
    'صحيح البخاري ٥٩٨٤',
    'جبير بن مطعم',
    'صحيح',
    'silat_rahim',
    ARRAY['صلة الرحم', 'الجنة', 'تحذير'],
    98,
    true
  ),
  (
    'قال رسول الله ﷺ: "ليس الواصِلُ بالمُكافِئِ، ولكنَّ الواصِلَ الذي إذا قُطِعَتْ رَحِمُهُ وصَلَها"',
    'صحيح البخاري ٥٩٩١',
    'عبد الله بن عمرو',
    'صحيح',
    'silat_rahim',
    ARRAY['صلة الرحم', 'الصبر', 'الإحسان'],
    97,
    true
  )
ON CONFLICT DO NOTHING;

-- Seed admin_quotes with scholar quotes about family ties
INSERT INTO admin_quotes (quote_text, author, source, category, tags, display_priority, is_active) VALUES
  (
    'صلة الرحم تزيد في العمر وتوسع في الرزق وتدفع ميتة السوء',
    'الإمام أحمد بن حنبل',
    'مسند الإمام أحمد',
    'silat_rahim',
    ARRAY['صلة الرحم', 'البركة', 'العمر'],
    100,
    true
  ),
  (
    'وصلة الرحم من أعظم القربات وأجل الطاعات، وقطيعتها من أكبر الكبائر',
    'الإمام ابن قدامة المقدسي',
    'المغني - كتاب الآداب',
    'silat_rahim',
    ARRAY['صلة الرحم', 'الطاعات', 'الكبائر'],
    99,
    true
  ),
  (
    'صلة الرحم واجبة، وهي الإحسان إلى الأقارب على حسب حال الواصل والموصول',
    'الإمام البهوتي',
    'كشاف القناع',
    'silat_rahim',
    ARRAY['صلة الرحم', 'الواجبات', 'الإحسان'],
    98,
    true
  ),
  (
    'صلة الرحم من أفضل الأعمال وأحبها إلى الله تعالى، وهي سبب لزيادة العمر والبركة في الرزق',
    'الإمام المرداوي',
    'الإنصاف',
    'silat_rahim',
    ARRAY['صلة الرحم', 'فضل الأعمال', 'البركة'],
    97,
    true
  )
ON CONFLICT DO NOTHING;

-- Add more motivational content for variety

-- Additional Hadith
INSERT INTO admin_hadith (hadith_text, source, narrator, grade, category, tags, display_priority, is_active) VALUES
  (
    'قال رسول الله ﷺ: "إن الرحم شُجنة من الرحمن، فقال الله: من وصلك وصلته، ومن قطعك قطعته"',
    'صحيح البخاري',
    'أبو هريرة',
    'صحيح',
    'silat_rahim',
    ARRAY['صلة الرحم', 'الرحمن'],
    96,
    true
  ),
  (
    'قال رسول الله ﷺ: "من سره أن يُمَدَّ له في عمره، ويُوَسَّع له في رزقه، ويُدفع عنه ميتة السوء، فليتق الله وليصل رحمه"',
    'مسند الإمام أحمد',
    'علي بن أبي طالب',
    'حسن',
    'silat_rahim',
    ARRAY['صلة الرحم', 'الرزق', 'العمر', 'التقوى'],
    95,
    true
  ),
  (
    'قال رسول الله ﷺ: "تعلموا من أنسابكم ما تصلون به أرحامكم"',
    'سنن الترمذي',
    'أبو هريرة',
    'حسن',
    'silat_rahim',
    ARRAY['صلة الرحم', 'الأنساب', 'التعلم'],
    94,
    true
  )
ON CONFLICT DO NOTHING;

-- Additional Quotes
INSERT INTO admin_quotes (quote_text, author, source, category, tags, display_priority, is_active) VALUES
  (
    'صلة الرحم شجرة طيبة، أصلها ثابت وفرعها في السماء، تؤتي أكلها كل حين بإذن ربها',
    'الإمام ابن القيم',
    'زاد المعاد',
    'silat_rahim',
    ARRAY['صلة الرحم', 'البركة'],
    96,
    true
  ),
  (
    'من أراد أن يطهر قلبه فليؤثر الله على شهوته، وليصل رحمه وإن قطعوه',
    'الإمام ابن تيمية',
    'مجموع الفتاوى',
    'silat_rahim',
    ARRAY['صلة الرحم', 'تطهير القلب'],
    95,
    true
  )
ON CONFLICT DO NOTHING;

COMMENT ON TABLE admin_hadith IS 'Admin-configurable hadith collection for daily Islamic reminders. Seeded with authentic hadith about silat al-rahim (family ties).';
COMMENT ON TABLE admin_quotes IS 'Admin-configurable quotes from scholars. Seeded with wisdom about family ties and relationships.';
