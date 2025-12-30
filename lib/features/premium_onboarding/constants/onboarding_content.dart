/// Arabic content strings for premium onboarding
class OnboardingContent {
  OnboardingContent._();

  // =====================================================
  // SHOWCASE SCREEN
  // =====================================================

  /// Header title
  static const String headerTitle = 'مرحباً بك في MAX';

  /// Skip button text
  static const String skipButton = 'تخطي';

  /// Next button text
  static const String nextButton = 'التالي';

  /// Try now button text
  static const String tryNowButton = 'جرب الآن';

  /// Start journey button (last screen)
  static const String startJourneyButton = 'ابدأ رحلتك';

  /// Step counter format (e.g., "1/6")
  static String stepCounter(int current, int total) => '$current/$total';

  // =====================================================
  // COMPLETION MODAL
  // =====================================================

  /// Completion title
  static const String completionTitle = 'أنت جاهز!';

  /// Completion subtitle
  static const String completionSubtitle =
      'استكشفت جميع ميزات صلني MAX\nابدأ رحلتك في تقوية صلة الرحم';

  /// Completion CTA
  static const String completionCta = 'ابدأ الآن';

  /// Quick actions section title
  static const String quickActionsTitle = 'ابدأ مع';

  // =====================================================
  // CONTEXTUAL TIPS
  // =====================================================

  /// Got it button text
  static const String gotItButton = 'فهمت';

  /// Don't show again text
  static const String dontShowAgain = 'لا تظهر مرة أخرى';

  // =====================================================
  // ANALYTICS EVENT NAMES
  // =====================================================

  static const String eventOnboardingStarted = 'premium_onboarding_started';
  static const String eventStepViewed = 'premium_onboarding_step_viewed';
  static const String eventStepCompleted = 'premium_onboarding_step_completed';
  static const String eventStepSkipped = 'premium_onboarding_step_skipped';
  static const String eventShowcaseSkipped = 'premium_onboarding_showcase_skipped';
  static const String eventOnboardingCompleted = 'premium_onboarding_completed';
  static const String eventTipShown = 'premium_onboarding_tip_shown';
  static const String eventTipDismissed = 'premium_onboarding_tip_dismissed';

  // =====================================================
  // STORAGE KEYS
  // =====================================================

  /// SharedPreferences key for onboarding state
  static const String localStorageKey = 'premium_onboarding_state';

  /// Supabase column name for onboarding metadata
  static const String supabaseColumn = 'onboarding_metadata';
}
