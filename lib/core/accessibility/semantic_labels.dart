import 'package:flutter/material.dart';

/// Semantic labels for accessibility (Arabic/English)
/// Use these labels for screen readers (VoiceOver/TalkBack)
class SemanticLabels {
  SemanticLabels._();

  // ============ NAVIGATION ============

  static const String homeTab = 'الرئيسية';
  static const String homeTabEn = 'Home';

  static const String relativesTab = 'الأقارب';
  static const String relativesTabEn = 'Relatives';

  static const String statisticsTab = 'الإحصائيات';
  static const String statisticsTabEn = 'Statistics';

  static const String settingsTab = 'الإعدادات';
  static const String settingsTabEn = 'Settings';

  static const String profileTab = 'الملف الشخصي';
  static const String profileTabEn = 'Profile';

  static const String backButton = 'رجوع';
  static const String backButtonEn = 'Go back';

  static const String closeButton = 'إغلاق';
  static const String closeButtonEn = 'Close';

  // ============ ACTIONS ============

  static const String addRelative = 'إضافة قريب';
  static const String addRelativeEn = 'Add relative';

  static const String editRelative = 'تعديل القريب';
  static const String editRelativeEn = 'Edit relative';

  static const String deleteRelative = 'حذف القريب';
  static const String deleteRelativeEn = 'Delete relative';

  static const String callRelative = 'اتصل بالقريب';
  static const String callRelativeEn = 'Call relative';

  static const String messageRelative = 'أرسل رسالة للقريب';
  static const String messageRelativeEn = 'Message relative';

  static const String markContacted = 'تحديد كمتواصل';
  static const String markContactedEn = 'Mark as contacted';

  static const String toggleFavorite = 'تبديل المفضل';
  static const String toggleFavoriteEn = 'Toggle favorite';

  static const String save = 'حفظ';
  static const String saveEn = 'Save';

  static const String cancel = 'إلغاء';
  static const String cancelEn = 'Cancel';

  static const String confirm = 'تأكيد';
  static const String confirmEn = 'Confirm';

  static const String retry = 'إعادة المحاولة';
  static const String retryEn = 'Retry';

  static const String refresh = 'تحديث';
  static const String refreshEn = 'Refresh';

  // ============ STATUS & STATES ============

  static const String loading = 'جاري التحميل';
  static const String loadingEn = 'Loading';

  static const String error = 'حدث خطأ';
  static const String errorEn = 'Error occurred';

  static const String empty = 'لا توجد بيانات';
  static const String emptyEn = 'No data available';

  static const String online = 'متصل';
  static const String onlineEn = 'Online';

  static const String offline = 'غير متصل';
  static const String offlineEn = 'Offline';

  static const String syncing = 'جاري المزامنة';
  static const String syncingEn = 'Syncing';

  // ============ GAMIFICATION ============

  static const String levelUp = 'ارتفاع المستوى';
  static const String levelUpEn = 'Level up';

  static const String badgeUnlocked = 'تم فتح شارة جديدة';
  static const String badgeUnlockedEn = 'Badge unlocked';

  static const String streakMilestone = 'إنجاز سلسلة التواصل';
  static const String streakMilestoneEn = 'Streak milestone reached';

  static const String pointsEarned = 'نقاط مكتسبة';
  static const String pointsEarnedEn = 'Points earned';

  // ============ FORM FIELDS ============

  static const String nameField = 'الاسم';
  static const String nameFieldEn = 'Name';

  static const String phoneField = 'رقم الهاتف';
  static const String phoneFieldEn = 'Phone number';

  static const String emailField = 'البريد الإلكتروني';
  static const String emailFieldEn = 'Email';

  static const String notesField = 'ملاحظات';
  static const String notesFieldEn = 'Notes';

  static const String searchField = 'بحث';
  static const String searchFieldEn = 'Search';

  static const String required = 'مطلوب';
  static const String requiredEn = 'Required';

  // ============ RELATIVE CARD ============

  static String relativeCard(String name) => 'بطاقة القريب $name';
  static String relativeCardEn(String name) => 'Relative card for $name';

  static String needsAttention(String name) => '$name يحتاج تواصل';
  static String needsAttentionEn(String name) => '$name needs contact';

  static String lastContacted(String date) => 'آخر تواصل: $date';
  static String lastContactedEn(String date) => 'Last contacted: $date';

  // ============ HELPER METHODS ============

  /// Get localized label based on locale
  static String localized(String arabic, String english, {Locale? locale}) {
    if (locale == null) return arabic; // Default to Arabic for RTL app
    return locale.languageCode == 'ar' ? arabic : english;
  }
}

/// Extension for easy semantics wrapping
extension SemanticsExtension on Widget {
  /// Wrap widget with semantics for accessibility
  Widget withSemantics({
    required String label,
    String? hint,
    bool? button,
    bool? link,
    bool? image,
    bool? header,
    bool? enabled,
    bool? focused,
    bool? selected,
    bool? toggled,
    bool? liveRegion,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: button,
      link: link,
      image: image,
      header: header,
      enabled: enabled,
      focused: focused,
      selected: selected,
      toggled: toggled,
      liveRegion: liveRegion,
      onTap: onTap,
      onLongPress: onLongPress,
      child: this,
    );
  }

  /// Wrap widget as a semantic button
  Widget asSemanticButton(String label, {String? hint, bool enabled = true}) {
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      enabled: enabled,
      child: this,
    );
  }

  /// Wrap widget as a semantic header
  Widget asSemanticHeader(String label) {
    return Semantics(
      label: label,
      header: true,
      child: this,
    );
  }

  /// Wrap widget as a semantic image
  Widget asSemanticImage(String label) {
    return Semantics(
      label: label,
      image: true,
      child: this,
    );
  }

  /// Wrap as live region for dynamic updates
  Widget asLiveRegion(String label) {
    return Semantics(
      label: label,
      liveRegion: true,
      child: this,
    );
  }

  /// Exclude from semantics tree (decorative elements)
  Widget excludeFromSemantics() {
    return ExcludeSemantics(child: this);
  }
}

/// Focus utilities for keyboard navigation
class FocusHelpers {
  FocusHelpers._();

  /// Request focus on a node
  static void requestFocus(FocusNode node) {
    if (!node.hasFocus) {
      node.requestFocus();
    }
  }

  /// Move focus to next node
  static void nextFocus(BuildContext context) {
    FocusScope.of(context).nextFocus();
  }

  /// Move focus to previous node
  static void previousFocus(BuildContext context) {
    FocusScope.of(context).previousFocus();
  }

  /// Unfocus current node
  static void unfocus(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  /// Create a focus traversal group for logical focus order
  static Widget traversalGroup({
    required Widget child,
    FocusTraversalPolicy? policy,
  }) {
    return FocusTraversalGroup(
      policy: policy ?? ReadingOrderTraversalPolicy(),
      child: child,
    );
  }

  /// Trap focus within a modal/dialog
  static Widget trapFocus({
    required Widget child,
    required FocusScopeNode node,
  }) {
    return FocusScope(
      node: node,
      autofocus: true,
      child: child,
    );
  }
}

/// Contrast checking utilities for WCAG compliance
class ContrastHelpers {
  ContrastHelpers._();

  /// Calculate relative luminance of a color
  static double relativeLuminance(Color color) {
    double r = _linearize(color.r);
    double g = _linearize(color.g);
    double b = _linearize(color.b);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double _linearize(double value) {
    return value <= 0.03928
        ? value / 12.92
        : ((value + 0.055) / 1.055) * ((value + 0.055) / 1.055) * ((value + 0.055) / 1.055);
  }

  /// Calculate contrast ratio between two colors
  static double contrastRatio(Color foreground, Color background) {
    double l1 = relativeLuminance(foreground);
    double l2 = relativeLuminance(background);
    double lighter = l1 > l2 ? l1 : l2;
    double darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Check if contrast meets WCAG AA for normal text (4.5:1)
  static bool meetsAANormalText(Color foreground, Color background) {
    return contrastRatio(foreground, background) >= 4.5;
  }

  /// Check if contrast meets WCAG AA for large text (3:1)
  static bool meetsAALargeText(Color foreground, Color background) {
    return contrastRatio(foreground, background) >= 3.0;
  }

  /// Check if contrast meets WCAG AAA for normal text (7:1)
  static bool meetsAAANormalText(Color foreground, Color background) {
    return contrastRatio(foreground, background) >= 7.0;
  }

  /// Get suggested text color (black or white) for background
  static Color suggestedTextColor(Color background) {
    return relativeLuminance(background) > 0.179
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);
  }
}

/// Minimum touch target size for accessibility (44x44)
class TouchTargetHelpers {
  TouchTargetHelpers._();

  /// Minimum touch target size per WCAG guidelines
  static const double minTouchTarget = 44.0;

  /// Wrap widget to ensure minimum touch target size
  static Widget ensureMinTouchTarget({
    required Widget child,
    double minSize = minTouchTarget,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minSize,
        minHeight: minSize,
      ),
      child: child,
    );
  }
}
