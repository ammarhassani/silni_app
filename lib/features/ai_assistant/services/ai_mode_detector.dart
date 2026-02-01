import 'package:silni_app/core/ai/ai_models.dart';
import 'package:silni_app/shared/models/relative_model.dart';

/// آخر إجراء قام به المستخدم قبل فتح المحادثة
enum LastAction {
  /// المستخدم سجّل تفاعل مع قريب
  loggedInteraction,

  /// المستخدم شاهد ملف قريب
  viewedProfile,

  /// لا يوجد إجراء سابق
  none,
}

/// خدمة الكشف التلقائي عن نوع المحادثة المناسب
///
/// تحدد أفضل وضع استشاري بناءً على سياق القريب المحدد
/// والإجراء الأخير الذي قام به المستخدم.
class AIModeDetector {
  AIModeDetector._();

  /// عدد الأيام التي تُعتبر بعدها العلاقة بحاجة لتقوية
  static const int _reconnectionThresholdDays = 30;

  /// عدد الأيام التي تُعتبر بعدها العلاقة بحاجة لإصلاح
  static const int _repairThresholdDays = 60;

  /// الحد الأدنى لعدد التفاعلات لاعتبار التواصل كافياً
  static const int _lowInteractionThreshold = 3;

  /// Detect the best counseling mode from available context.
  ///
  /// Priority rules:
  /// 1. If [lastAction] is `loggedInteraction` -> `general` (celebration context)
  /// 2. If relative hasn't been contacted in 60+ days -> `conflict` (repair/reconciliation)
  /// 3. If relative hasn't been contacted in 30+ days -> `relationship` (reconnection advice)
  /// 4. If relative has low interaction count (<3) -> `communication` (help starting conversations)
  /// 5. Default -> `general`
  static CounselingMode detect({
    Relative? relativeContext,
    LastAction? lastAction,
  }) {
    // Rule 1: User just logged an interaction — celebration context
    if (lastAction == LastAction.loggedInteraction) {
      return CounselingMode.general;
    }

    // If no relative context, default to general
    if (relativeContext == null) {
      return CounselingMode.general;
    }

    // Calculate days since last contact
    final daysSinceContact = relativeContext.daysSinceLastContact;

    // Rule 2: 60+ days without contact — repair/reconciliation
    if (daysSinceContact != null && daysSinceContact >= _repairThresholdDays) {
      return CounselingMode.conflict;
    }

    // Rule 3: 30+ days without contact — reconnection advice
    if (daysSinceContact != null &&
        daysSinceContact >= _reconnectionThresholdDays) {
      return CounselingMode.relationship;
    }

    // Rule 4: Low interaction count — help starting conversations
    if (relativeContext.interactionCount < _lowInteractionThreshold) {
      return CounselingMode.communication;
    }

    // Rule 5: Default
    return CounselingMode.general;
  }
}
