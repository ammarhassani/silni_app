import 'package:home_widget/home_widget.dart';
import 'package:silni_app/core/config/supabase_config.dart';

/// Service for updating the home screen widget with top streak data.
///
/// Follows the project convention of private constructor + static methods.
class HomeWidgetService {
  HomeWidgetService._();

  static const _appGroupId = 'group.com.silni.app.widget';
  static const _iOSWidgetName = 'SilniStreakWidget';
  static const _androidWidgetName = 'SilniStreakWidget';

  /// Initialize home widget with app group ID.
  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  /// Update the home screen widget with the user's top streak.
  ///
  /// Uses a single joined query to fetch the top streak and relative name
  /// in one round-trip. Sends data to the native widget.
  static Future<void> updateWidget({
    required String userId,
  }) async {
    try {
      final client = SupabaseConfig.client;

      // Single query with FK join: relative_streaks -> relatives
      final streakData = await client
          .from('relative_streaks')
          .select('current_streak, relatives(full_name)')
          .eq('user_id', userId)
          .order('current_streak', ascending: false)
          .limit(1)
          .maybeSingle();

      String displayName = '\u0635\u0650\u0644\u0646\u064A'; // صِلني
      int streakCount = 0;

      if (streakData != null && streakData['current_streak'] > 0) {
        streakCount = streakData['current_streak'] as int;

        final relatives = streakData['relatives'] as Map<String, dynamic>?;
        if (relatives != null && relatives['full_name'] != null) {
          displayName = relatives['full_name'] as String;
        }
      }

      // Convert streak count to Arabic numerals
      final arabicCount = toArabicNumerals(streakCount);

      // Send data to native widget
      await HomeWidget.saveWidgetData('display_name', displayName);
      await HomeWidget.saveWidgetData('streak_count', streakCount);
      await HomeWidget.saveWidgetData(
        'streak_text',
        '$displayName \uD83D\uDD25$arabicCount',
      );

      // Trigger widget update on both platforms
      await HomeWidget.updateWidget(
        iOSName: _iOSWidgetName,
        androidName: _androidWidgetName,
      );
    } catch (_) {
      // Widget update is non-critical — silently fail
    }
  }

  /// Convert an integer to Arabic-Indic numerals (٠١٢٣٤٥٦٧٨٩).
  static String toArabicNumerals(int number) {
    if (number < 0) return toArabicNumerals(-number);
    const arabicDigits = [
      '\u0660', // ٠
      '\u0661', // ١
      '\u0662', // ٢
      '\u0663', // ٣
      '\u0664', // ٤
      '\u0665', // ٥
      '\u0666', // ٦
      '\u0667', // ٧
      '\u0668', // ٨
      '\u0669', // ٩
    ];
    return number
        .toString()
        .split('')
        .map((d) => arabicDigits[int.parse(d)])
        .join();
  }
}
