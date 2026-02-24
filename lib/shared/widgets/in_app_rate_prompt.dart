import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Prompts the user to rate the app after a certain number of app opens.
///
/// Uses the native in-app review dialog (App Store / Play Store).
/// Shows on the 5th, 15th, and 40th app open — then never again.
class InAppRatePrompt {
  InAppRatePrompt._();

  static const _openCountKey = 'silni_rate_open_count';
  static const _hasRatedKey = 'silni_has_rated';

  /// Trigger points (app open numbers) at which the review dialog appears.
  static const _triggerPoints = {5, 15, 40};

  /// Call on each app open. Shows the native review dialog if threshold is met.
  static Future<void> maybeShow(BuildContext context, {String? userId}) async {
    if (userId == null) return;

    final prefs = await SharedPreferences.getInstance();

    final ratedKey = '${_hasRatedKey}_$userId';
    if (prefs.getBool(ratedKey) == true) return;

    final openKey = '${_openCountKey}_$userId';
    final openCount = (prefs.getInt(openKey) ?? 0) + 1;
    await prefs.setInt(openKey, openCount);

    if (!_triggerPoints.contains(openCount)) return;

    if (!context.mounted) return;

    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
      // Mark as rated after showing — the OS may or may not show the dialog,
      // but we stop prompting after the last trigger point regardless.
      if (openCount == _triggerPoints.last) {
        await prefs.setBool(ratedKey, true);
      }
    }
  }
}
