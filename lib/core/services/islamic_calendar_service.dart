/// Service for Islamic calendar awareness.
/// Provides approximate dates for major Islamic occasions.
///
/// Note: Uses approximate Gregorian dates for 2026. Islamic (Hijri) dates
/// shift ~10-11 days earlier each Gregorian year. For production accuracy,
/// consider integrating the hijri_calendar package.
class IslamicCalendarService {
  IslamicCalendarService._();

  /// Check if today is Friday (Jumu'ah)
  static bool get isJumuah => DateTime.now().weekday == DateTime.friday;

  /// Get a seasonal/Islamic briefing message for today, or null if none applicable.
  ///
  /// Approximate 2026 Gregorian dates:
  /// - Ramadan: ~Feb 18 – Mar 19
  /// - Eid al-Fitr: ~Mar 20 – 22
  /// - Eid al-Adha: ~May 27 – 29
  static String? getTodayBriefing() {
    final now = DateTime.now();

    // Friday — works every year
    if (now.weekday == DateTime.friday) {
      return 'الجمعة يوم مبارك للتواصل مع الأهل 🤍';
    }

    // Hardcoded dates only valid for 2026
    if (now.year != 2026) return null;

    final month = now.month;
    final day = now.day;

    // Pre-Ramadan (~Feb 4-17)
    if (month == 2 && day >= 4 && day <= 17) {
      return 'رمضان قرب — وش رايك تجهز رسائل لأقاربك؟ 🌙';
    }

    // During Ramadan (~Feb 18 – Mar 19)
    if ((month == 2 && day >= 18) || (month == 3 && day <= 19)) {
      return 'بعد الإفطار وقت حلو تتصل على عائلتك 🌙';
    }

    // Eid al-Fitr (~Mar 20-22)
    if (month == 3 && day >= 20 && day <= 22) {
      return 'كل عام وأنت بخير! عيد سعيد — واصل يقدر يكتب لك رسائل عيد 🎉';
    }

    // Pre-Eid al-Adha (~May 20-26)
    if (month == 5 && day >= 20 && day <= 26) {
      return 'عيد الأضحى قرب — وقت حلو تحضّر تهاني لعائلتك 🌟';
    }

    // Eid al-Adha (~May 27-29)
    if (month == 5 && day >= 27 && day <= 29) {
      return 'عيد أضحى مبارك! تواصل مع أهلك وهنّيهم 🐑';
    }

    return null;
  }

  /// Get the current Islamic season context for AI prompts, or null if none.
  static String? getSeasonContext() {
    final now = DateTime.now();
    // Hardcoded dates only valid for 2026
    if (now.year != 2026) return null;
    final month = now.month;
    final day = now.day;

    // During Ramadan (~Feb 18 – Mar 19)
    if ((month == 2 && day >= 18) || (month == 3 && day <= 19)) {
      return 'الآن شهر رمضان المبارك — وقت مثالي لصلة الرحم وتعزيز الروابط';
    }

    // Eid al-Fitr (~Mar 20-22)
    if (month == 3 && day >= 20 && day <= 22) {
      return 'الآن أيام عيد الفطر — مناسبة مهمة للتواصل والتهنئة';
    }

    // Eid al-Adha (~May 27-29)
    if (month == 5 && day >= 27 && day <= 29) {
      return 'الآن أيام عيد الأضحى — مناسبة مهمة للتواصل والتهنئة';
    }

    return null;
  }
}
