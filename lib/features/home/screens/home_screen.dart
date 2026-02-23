import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/models/gamification_event.dart';
import '../../../core/providers/ai_preload_provider.dart';
import '../../../shared/widgets/premium_loading_indicator.dart';
import '../../../shared/widgets/floating_points_overlay.dart';
import '../../../shared/widgets/level_up_modal.dart';
import '../../../shared/widgets/badge_unlock_modal.dart';
import '../../../shared/widgets/streak_milestone_modal.dart';
import '../../../shared/models/hadith_model.dart';
import '../../../core/config/supabase_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/providers/realtime_provider.dart';
import '../../premium_onboarding/providers/onboarding_provider.dart';
import '../../premium_onboarding/screens/premium_onboarding_screen.dart';
import '../providers/home_providers.dart';
import '../widgets/widgets.dart';
import '../../../shared/widgets/message_widget.dart';
import '../../../shared/widgets/persistent_bottom_nav.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../shared/widgets/session_paywall_interstitial.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _floatingController;
  late ConfettiController _confettiController;
  Hadith? _dailyHadith;
  bool _isLoadingHadith = true;
  final List<GamificationEvent> _pendingEvents = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    _loadDailyHadith();
    _checkPremiumOnboarding();
    _checkSessionPaywall();
  }

  /// Check if premium onboarding should be shown for returning MAX users
  void _checkPremiumOnboarding() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final shouldShow = ref.read(shouldShowOnboardingProvider);
      if (shouldShow) {
        PremiumOnboardingScreen.show(context);
      }
    });
  }

  /// Show session-based paywall interstitial for free users every few app opens
  void _checkSessionPaywall() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isMax = ref.read(isMaxProvider);
      if (!isMax) {
        SessionPaywallInterstitial.maybeShow(context, userId: SupabaseConfig.currentUserId);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Stop animation when app is paused to prevent "disposed controller" errors
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _floatingController.stop();
    } else if (state == AppLifecycleState.resumed) {
      // Resume animation when app is back in foreground
      if (!_floatingController.isAnimating) {
        _floatingController.repeat(reverse: true);
      }

      // Process pending gamification events
      if (_pendingEvents.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            for (final event in _pendingEvents) {
              _processGamificationEvent(event);
            }
            _pendingEvents.clear();
          }
        });
      }
    }
  }

  Future<void> _loadDailyHadith() async {
    final hadithService = ref.read(hadithServiceProvider);
    final hadith = await hadithService.getDailyHadith();
    if (mounted) {
      setState(() {
        _dailyHadith = hadith;
        _isLoadingHadith = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _floatingController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _processGamificationEvent(GamificationEvent event) {
    switch (event.type) {
      case GamificationEventType.pointsEarned:
        context.showFloatingPoints(points: event.points ?? 0);
        break;

      case GamificationEventType.levelUp:
        _confettiController.play();
        if (event.newLevel != null) {
          LevelUpModal.show(
            context,
            oldLevel: event.oldLevel ?? event.newLevel! - 1,
            newLevel: event.newLevel!,
            currentXP: event.currentXP ?? 0,
            xpToNextLevel: event.xpToNextLevel ?? 0,
          );
        }
        break;

      case GamificationEventType.streakMilestone:
        _confettiController.play();
        if (event.streak != null) {
          StreakMilestoneModal.show(context, streak: event.streak!);
        }
        break;

      case GamificationEventType.badgeUnlocked:
        _confettiController.play();
        if (event.badgeId != null) {
          BadgeUnlockModal.show(
            context,
            badgeId: event.badgeId!,
            badgeName: event.badgeName ?? 'وسام جديد',
            badgeDescription: event.badgeDescription ?? 'أحسنت!',
          );
        }
        break;

      case GamificationEventType.streakIncreased:
        break;

      case GamificationEventType.streakWarning:
        // Show streak warning notification
        if (mounted) {
          final warningColor = ref.read(themeColorsProvider).statusWarning;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '⚠️ تنبيه: سلسلة التواصل على وشك الانقطاع! تواصل مع أحد أقاربك اليوم',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: warningColor,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        break;

      case GamificationEventType.streakCritical:
        // Show critical streak warning with more urgency
        if (mounted) {
          final criticalColor = ref.read(themeColorsProvider).statusError;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_rounded, color: Colors.white),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '🔥 عاجل: ستفقد سلسلة التواصل خلال ساعات! تواصل الآن',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: criticalColor,
              duration: const Duration(seconds: 8),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        break;

      case GamificationEventType.freezeEarned:
        // Freeze earned is shown in the milestone modal
        break;

      case GamificationEventType.freezeUsed:
        // Show freeze used notification
        if (mounted) {
          final infoColor = ref.read(themeColorsProvider).statusInfo;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.ac_unit_rounded, color: Colors.white),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '❄️ تم استخدام تجميد السلسلة! سلسلتك محمية اليوم',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: infoColor,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        break;
    }
  }


  @override
  Widget build(BuildContext context) {
    final streamUser = ref.watch(currentUserProvider);
    final fallbackUser = SupabaseConfig.currentUser;
    final user = streamUser ?? fallbackUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: PremiumLoadingIndicator(
            message: 'جاري تحميل الصفحة الرئيسية...',
          ),
        ),
      );
    }

    final displayName = user.userMetadata?['full_name'] as String? ??
        user.userMetadata?['display_name'] as String? ??
        user.userMetadata?['name'] as String? ??
        user.email ??
        'المستخدم';
    final userId = user.id;

    final themeColors = ref.watch(themeColorsProvider);

    // Side-effect providers — no widget output, but must stay in HomeScreen
    ref.watch(autoRealtimeSubscriptionsProvider);
    ref.watch(aiAutoPreloadProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      floatingActionButton: null,
      body: Stack(
        children: [
          // Gamification event listener (invisible)
          GamificationListener(
            onEvent: (event) {
              final appLifecycleState =
                  WidgetsBinding.instance.lifecycleState;
              final isInForeground = appLifecycleState == null ||
                  appLifecycleState == AppLifecycleState.resumed;
              if (isInForeground) {
                _processGamificationEvent(event);
              } else {
                _pendingEvents.add(event);
              }
            },
          ),

          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              shouldLoop: false,
              colors: [
                themeColors.primary,
                AppColors.premiumGold,
                AppColors.emotionalPurple,
                AppColors.joyfulOrange,
              ],
            ),
          ),

          // Main content
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.sm,
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HomeHeaderWidget(
                      displayName: displayName,
                      userId: userId,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const PremiumUpgradeBanner(),
                    const SizedBox(height: AppSpacing.sm),
                    const MessageWidget(position: 'home_top'),
                    const SizedBox(height: AppSpacing.sm),
                    const MessageWidget(screenPath: '/home'),
                    const SizedBox(height: AppSpacing.md),
                    IslamicReminderWidget(
                      hadith: _dailyHadith,
                      isLoading: _isLoadingHadith,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OccasionCard(userId: userId),
                    const SizedBox(height: AppSpacing.md),
                    ProactiveInsightCard(userId: userId),
                    const SizedBox(height: AppSpacing.md),
                    const QuickActionsWidget(),
                    const SizedBox(height: AppSpacing.lg),
                    const FamilyCirclesSection(),
                    const SizedBox(height: AppSpacing.md),
                    AIPriorityContactsWidget(userId: userId),
                    const SizedBox(height: AppSpacing.md),
                    const DueRemindersSection(),
                    const SizedBox(height: AppSpacing.lg),
                    const TodaysActivitySection(),
                    const SizedBox(height: AppSpacing.md),
                    const AIInsightCard(),
                    const SizedBox(height: AppSpacing.md),
                    const SetupRemindersSection(),
                    const SizedBox(height: AppSpacing.md),
                    const MessageWidget(position: 'home_bottom'),
                    SizedBox(height: PersistentBottomNav.totalHeight),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
