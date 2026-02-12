import '../../shared/models/interaction_model.dart';

/// Infers the most likely [InteractionType] based on context.
///
/// Rules (in priority order):
/// 1. Friday after 12pm → visit (صلاة الجمعة ثم زيارة)
/// 2. Eid / occasion days → visit
/// 3. 10pm–6am → message (late night, unlikely to call)
/// 4. 6am–9am → message (early morning)
/// 5. Default → call
class InteractionTypeInferenceService {
  InteractionTypeInferenceService._();

  /// Returns the inferred [InteractionType] for the given [now] timestamp.
  ///
  /// Pass [isOccasionDay] = true if today is Eid, Ramadan, National Day, etc.
  static InteractionType infer({
    DateTime? now,
    bool isOccasionDay = false,
  }) {
    final dateTime = now ?? DateTime.now();
    final hour = dateTime.hour;
    final weekday = dateTime.weekday; // 1=Mon, 5=Fri, 7=Sun

    // Eid / occasion day → visit
    if (isOccasionDay) {
      return InteractionType.visit;
    }

    // Friday afternoon (after Jumu'ah prayer) → visit
    if (weekday == DateTime.friday && hour >= 12) {
      return InteractionType.visit;
    }

    // Late night (10pm - midnight, midnight - 6am) → message
    if (hour >= 22 || hour < 6) {
      return InteractionType.message;
    }

    // Early morning (6am - 9am) → message
    if (hour < 9) {
      return InteractionType.message;
    }

    // Default: call
    return InteractionType.call;
  }

  /// Returns a human-readable Arabic reason for the inference.
  static String inferenceReason({
    DateTime? now,
    bool isOccasionDay = false,
  }) {
    final dateTime = now ?? DateTime.now();
    final hour = dateTime.hour;
    final weekday = dateTime.weekday;

    if (isOccasionDay) return 'يوم مناسبة - وقت زيارات 🏠';
    if (weekday == DateTime.friday && hour >= 12) return 'الجمعة بعد الصلاة - وقت زيارات 🕌';
    if (hour >= 22 || hour < 6) return 'وقت متأخر - رسالة أنسب 🌙';
    if (hour < 9) return 'الصباح الباكر - رسالة أنسب ☀️';
    return '';
  }
}
