import 'package:purchases_flutter/purchases_flutter.dart' as rc;

/// Helpers for formatting trial/introductory offer information
class TrialHelpers {
  TrialHelpers._();

  /// Format trial duration from RevenueCat IntroductoryPrice into Arabic text
  static String formatDuration(rc.IntroductoryPrice? introPrice) {
    if (introPrice == null) return '٧ أيام';

    final count = introPrice.periodNumberOfUnits;

    return switch (introPrice.periodUnit) {
      rc.PeriodUnit.day => count == 1 ? 'يوم واحد' : '${toArabicDigits(count)} أيام',
      rc.PeriodUnit.week => count == 1 ? 'أسبوع واحد' : '${toArabicDigits(count)} أسابيع',
      rc.PeriodUnit.month => count == 1 ? 'شهر واحد' : '${toArabicDigits(count)} أشهر',
      rc.PeriodUnit.year => count == 1 ? 'سنة واحدة' : '${toArabicDigits(count)} سنوات',
      rc.PeriodUnit.unknown => '٧ أيام',
    };
  }

  /// Convert integer to Arabic-Indic numerals
  static String toArabicDigits(int number) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((d) => digits[int.parse(d)]).join();
  }
}
