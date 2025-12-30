import '../../../core/router/app_routes.dart';

/// Position of the tooltip relative to the target
enum TooltipPosition {
  above,
  below,
  left,
  right,
  center;
}

/// Represents a contextual tip shown on a specific screen
class ContextualTip {
  /// Unique identifier for this tip
  final String id;

  /// Route of the screen where this tip should appear
  final String screenRoute;

  /// GlobalKey identifier for the target widget
  final String targetKey;

  /// Arabic title for the tooltip
  final String titleArabic;

  /// Arabic body text
  final String bodyArabic;

  /// Position relative to the target
  final TooltipPosition position;

  /// Priority order when multiple tips on same screen (lower = first)
  final int priority;

  /// Optional action button label
  final String? actionLabel;

  /// Optional route to navigate on action
  final String? actionRoute;

  /// Whether to show spotlight overlay
  final bool showSpotlight;

  const ContextualTip({
    required this.id,
    required this.screenRoute,
    required this.targetKey,
    required this.titleArabic,
    required this.bodyArabic,
    this.position = TooltipPosition.below,
    this.priority = 0,
    this.actionLabel,
    this.actionRoute,
    this.showSpotlight = true,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContextualTip && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Predefined contextual tips for various screens
class ContextualTips {
  ContextualTips._();

  /// Tips for AI Hub screen
  static const List<ContextualTip> aiHubTips = [
    ContextualTip(
      id: 'ai_hub_counselor',
      screenRoute: AppRoutes.aiHub,
      targetKey: 'ai_counselor_card',
      titleArabic: 'المستشار الذكي',
      bodyArabic: 'احصل على نصائح مخصصة لتقوية علاقاتك العائلية',
      position: TooltipPosition.below,
      priority: 1,
      actionLabel: 'جربه الآن',
      actionRoute: AppRoutes.aiChat,
    ),
    ContextualTip(
      id: 'ai_hub_messages',
      screenRoute: AppRoutes.aiHub,
      targetKey: 'ai_messages_card',
      titleArabic: 'كاتب الرسائل',
      bodyArabic: 'دع الذكاء الاصطناعي يكتب لك رسائل جميلة للمناسبات',
      position: TooltipPosition.below,
      priority: 2,
      actionLabel: 'جربه الآن',
      actionRoute: AppRoutes.aiMessages,
    ),
    ContextualTip(
      id: 'ai_hub_scripts',
      screenRoute: AppRoutes.aiHub,
      targetKey: 'ai_scripts_card',
      titleArabic: 'سيناريوهات التواصل',
      bodyArabic: 'سيناريوهات جاهزة لبدء المحادثات مع أقاربك',
      position: TooltipPosition.below,
      priority: 3,
    ),
  ];

  /// Tips for Home screen (after onboarding)
  static const List<ContextualTip> homeTips = [
    ContextualTip(
      id: 'home_ai_hub',
      screenRoute: AppRoutes.home,
      targetKey: 'home_ai_action',
      titleArabic: 'ميزات الذكاء الاصطناعي',
      bodyArabic: 'اضغط هنا للوصول لجميع ميزات MAX الذكية',
      position: TooltipPosition.above,
      priority: 1,
      actionLabel: 'استكشف',
      actionRoute: AppRoutes.aiHub,
    ),
  ];

  /// Tips for Reminders screen
  static const List<ContextualTip> remindersTips = [
    ContextualTip(
      id: 'reminders_unlimited',
      screenRoute: AppRoutes.reminders,
      targetKey: 'add_reminder_button',
      titleArabic: 'تذكيرات غير محدودة',
      bodyArabic: 'مع MAX يمكنك إضافة عدد غير محدود من التذكيرات',
      position: TooltipPosition.above,
      priority: 1,
    ),
  ];

  /// Tips for Family Tree screen
  static const List<ContextualTip> familyTreeTips = [
    ContextualTip(
      id: 'family_tree_export',
      screenRoute: AppRoutes.familyTree,
      targetKey: 'export_tree_button',
      titleArabic: 'تصدير الشجرة',
      bodyArabic: 'يمكنك تصدير شجرة العائلة كصورة ومشاركتها',
      position: TooltipPosition.below,
      priority: 1,
    ),
  ];

  /// Tips for Leaderboard screen
  static const List<ContextualTip> leaderboardTips = [
    ContextualTip(
      id: 'leaderboard_intro',
      screenRoute: AppRoutes.leaderboard,
      targetKey: 'leaderboard_list',
      titleArabic: 'لوحة المتصدرين',
      bodyArabic: 'تنافس مع الآخرين وتصدر قائمة أكثر الواصلين',
      position: TooltipPosition.center,
      priority: 1,
      showSpotlight: false,
    ),
  ];

  /// All tips organized by screen
  static Map<String, List<ContextualTip>> get tipsByScreen => {
        AppRoutes.aiHub: aiHubTips,
        AppRoutes.home: homeTips,
        AppRoutes.reminders: remindersTips,
        AppRoutes.familyTree: familyTreeTips,
        AppRoutes.leaderboard: leaderboardTips,
      };

  /// Get tips for a specific screen
  static List<ContextualTip> getTipsForScreen(String screenRoute) {
    return tipsByScreen[screenRoute] ?? [];
  }

  /// All tips flattened
  static List<ContextualTip> get allTips => [
        ...aiHubTips,
        ...homeTips,
        ...remindersTips,
        ...familyTreeTips,
        ...leaderboardTips,
      ];

  /// Get a specific tip by ID
  static ContextualTip? getById(String id) {
    try {
      return allTips.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
