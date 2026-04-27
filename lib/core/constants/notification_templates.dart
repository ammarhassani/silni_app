import 'dart:math';

/// Saudi dialect notification templates with escalating tone based on
/// days since last contact. Templates use {name} and {days} placeholders.
class NotificationTemplates {
  NotificationTemplates._();

  static final _random = Random();

  // 1-3 day gap: gentle, casual
  static const _gentleTemplates = [
    '{name} يسلم عليك',
    '{name} وش أخبارهم؟',
    'سلّم على {name} اليوم',
    'شكلك ناسي {name}',
    '{name} لهم {days} أيام ما سمعوا صوتك',
  ];

  // 4-13 day gap: moderate nudge
  static const _moderateTemplates = [
    '{name} لهم أسبوع ما حد كلمهم',
    'وش أخبار {name}؟ لهم {days} أيام',
    '{name} يمكن يحتاجون يسمعون صوتك',
    'ما كلمت {name} من {days} يوم',
    '{name} وش سالفتهم؟ طولت عليهم',
  ];

  // 14-29 day gap: direct, mentions أسبوعين
  static const _directTemplates = [
    '{name} لهم أسبوعين ما سمعوا صوتك',
    'لهم أسبوعين ما كلمت {name}، وش رايك تطمن عليهم؟',
    '{name} من أسبوعين ما سمعوا منك',
    'طولت على {name}، لهم أسبوعين',
    '{name} ينتظرون اتصالك، لهم أكثر من أسبوعين',
  ];

  // 30+ day gap: heavy, mentions شهر
  static const _heavyTemplates = [
    'آخر مرة كلمت {name} كان قبل شهر',
    '{name} لهم أكثر من شهر ما سمعوا منك',
    'شهر كامل ما تواصلت مع {name}',
    '{name} لهم شهر، الوقت يمر بسرعة',
    'صلة الرحم مع {name} محتاجة اهتمام، لهم شهر',
  ];

  /// Returns a randomly selected notification reminder in Saudi dialect.
  ///
  /// The tone escalates based on [daysSinceContact]:
  /// - 1-3 days: gentle, casual
  /// - 4-13 days: moderate nudge
  /// - 14-29 days: direct
  /// - 30+ days: heavy
  static String getReminder({
    required String relativeName,
    required int daysSinceContact,
  }) {
    final List<String> templates;
    if (daysSinceContact <= 3) {
      templates = _gentleTemplates;
    } else if (daysSinceContact <= 13) {
      templates = _moderateTemplates;
    } else if (daysSinceContact <= 29) {
      templates = _directTemplates;
    } else {
      templates = _heavyTemplates;
    }

    final template = templates[_random.nextInt(templates.length)];
    return template
        .replaceAll('{name}', relativeName)
        .replaceAll('{days}', daysSinceContact.toString());
  }

  /// Streak celebration messages (Saudi dialect).
  /// Use {streak} placeholder for streak count.
  static const streakMessages = [
    'يا وصّال العيلة! {streak} يوم ما وقفت 🔥',
    'سلسلة {streak} يوم! أنت قدها 🔥',
    '{streak} يوم متواصل! الله يبارك فيك',
    'ما شاء الله، {streak} يوم! كمّل',
  ];

}
