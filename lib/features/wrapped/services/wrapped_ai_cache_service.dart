import 'package:shared_preferences/shared_preferences.dart';

/// Caches AI-generated wrapped personality titles in SharedPreferences.
///
/// Titles are persisted per user per period so they don't change on each open.
/// Key format: `wrapped_ai_{userId}_{year}_{month}` (monthly)
///             `wrapped_ai_{userId}_{year}`         (yearly)
class WrappedAICacheService {
  WrappedAICacheService._();

  static String _monthlyKey(String userId, int year, int month) =>
      'wrapped_ai_${userId}_${year}_$month';

  static String _yearlyKey(String userId, int year) =>
      'wrapped_ai_${userId}_$year';

  /// Get cached monthly AI title, or null if not cached.
  static Future<({String title, String emoji})?> getMonthlyTitle(
    String userId,
    int year,
    int month,
  ) async {
    return _get(_monthlyKey(userId, year, month));
  }

  /// Get cached yearly AI title, or null if not cached.
  static Future<({String title, String emoji})?> getYearlyTitle(
    String userId,
    int year,
  ) async {
    return _get(_yearlyKey(userId, year));
  }

  /// Cache a monthly AI title.
  static Future<void> putMonthlyTitle(
    String userId,
    int year,
    int month,
    String title,
    String emoji,
  ) async {
    await _put(_monthlyKey(userId, year, month), title, emoji);
  }

  /// Cache a yearly AI title.
  static Future<void> putYearlyTitle(
    String userId,
    int year,
    String title,
    String emoji,
  ) async {
    await _put(_yearlyKey(userId, year), title, emoji);
  }

  static Future<({String title, String emoji})?> _get(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final titleVal = prefs.getString('${key}_title');
    final emojiVal = prefs.getString('${key}_emoji');
    if (titleVal == null || titleVal.isEmpty) return null;
    return (title: titleVal, emoji: emojiVal ?? '');
  }

  static Future<void> _put(String key, String title, String emoji) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${key}_title', title);
    await prefs.setString('${key}_emoji', emoji);
  }
}
