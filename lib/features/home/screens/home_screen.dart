import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/models/gamification_event.dart';
import '../../../core/providers/gamification_events_provider.dart';
import '../../../core/providers/ai_preload_provider.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/premium_loading_indicator.dart';
import '../../../shared/widgets/floating_points_overlay.dart';
import '../../../shared/widgets/level_up_modal.dart';
import '../../../shared/widgets/badge_unlock_modal.dart';
import '../../../shared/widgets/streak_milestone_modal.dart';
import '../../../shared/widgets/error_widgets.dart';
import '../../../shared/models/hadith_model.dart';
import '../../../shared/providers/interactions_provider.dart';
import '../../../core/config/supabase_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/providers/realtime_provider.dart';
import '../../premium_onboarding/providers/onboarding_provider.dart';
import '../../premium_onboarding/screens/premium_onboarding_screen.dart';
import '../providers/home_providers.dart';
import '../widgets/widgets.dart';
import '../../../shared/widgets/message_widget.dart';

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
  }

  /// Check if premium onboarding should be shown for returning MAX users
  void _checkPremiumOnboarding() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Small delay to ensure providers are ready
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      final shouldShow = ref.read(shouldShowOnboardingProvider);
      if (shouldShow && mounted) {
        await PremiumOnboardingScreen.show(context);
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
              backgroundColor: AppColors.warning,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        break;

      case GamificationEventType.streakCritical:
        // Show critical streak warning with more urgency
        if (mounted) {
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
              backgroundColor: AppColors.error,
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
              backgroundColor: AppColors.info,
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

    // Listen to gamification events
    ref.listen<AsyncValue<GamificationEvent>>(
      gamificationEventsStreamProvider,
      (previous, next) {
        next.whenData((event) {
          if (event.userId != userId) return;

          final appLifecycleState = WidgetsBinding.instance.lifecycleState;
          final isInForeground =
              appLifecycleState == null ||
              appLifecycleState == AppLifecycleState.resumed;

          if (isInForeground) {
            _processGamificationEvent(event);
          } else {
            _pendingEvents.add(event);
          }
        });
      },
    );

    ref.watch(autoRealtimeSubscriptionsProvider);

    // Preload AI data in background for faster AI feature access
    ref.watch(aiAutoPreloadProvider);

    final relativesAsync = ref.watch(relativesStreamProvider(userId));
    final todayInteractionsAsync = ref.watch(todayInteractionsStreamProvider(userId));
    final schedulesAsync = ref.watch(reminderSchedulesStreamProvider(userId));
    final todayContactedAsync = ref.watch(todayContactedRelativesProvider(userId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        children: [
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
                    // Islamic greeting header
                    HomeHeaderWidget(
                      displayName: displayName,
                      userId: userId,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Top banner (promotional/announcements)
                    const MessageWidget(position: 'home_top'),
                    const SizedBox(height: AppSpacing.sm),

                    // Screen-based messages (MOTD, modals, announcements)
                    const MessageWidget(screenPath: '/home'),
                    const SizedBox(height: AppSpacing.md),

                    // Hadith/Islamic reminder
                    IslamicReminderWidget(
                      hadith: _dailyHadith,
                      isLoading: _isLoadingHadith,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Quick Actions
                    const QuickActionsWidget(),
                    const SizedBox(height: AppSpacing.lg),

                    // Family members circle avatars
                    relativesAsync.when(
                      data: (relatives) => FamilyCirclesWidget(relatives: relatives),
                      loading: () => const FamilyCirclesSkeleton(),
                      error: (error, _) => InlineErrorWidget(
                        message: 'فشل في تحميل بيانات العائلة',
                        onRetry: () => ref.invalidate(relativesStreamProvider(userId)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Frequency carousel for tomorrow/yesterday reminders
                    relativesAsync.when(
                      data: (relatives) => schedulesAsync.when(
                        data: (schedules) => FrequencyCarousel(
                          relatives: relatives,
                          schedules: schedules,
                        ),
                        loading: () => const FrequencyCarouselSkeleton(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                      loading: () => const FrequencyCarouselSkeleton(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Due Reminders Card
                    relativesAsync.when(
                      data: (relatives) => schedulesAsync.when(
                        data: (schedules) => DueRemindersCard(
                          userId: userId,
                          relatives: relatives,
                          schedules: schedules,
                          contactedSet: todayContactedAsync.valueOrNull ?? <String>{},
                        ),
                        loading: () => const DueRemindersCardSkeleton(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                      loading: () => const DueRemindersCardSkeleton(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Today's connections
                    relativesAsync.when(
                      data: (relatives) => todayInteractionsAsync.when(
                        data: (interactions) => TodaysActivityWidget(
                          interactions: interactions,
                          relatives: relatives,
                        ),
                        loading: () => const TodaysActivitySkeleton(),
                        error: (error, _) => InlineErrorWidget(
                          message: 'فشل في تحميل نشاط اليوم',
                          onRetry: () => ref.invalidate(todayInteractionsStreamProvider(userId)),
                          compact: true,
                        ),
                      ),
                      loading: () => const TodaysActivitySkeleton(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Setup reminders prompt
                    schedulesAsync.when(
                      data: (schedules) => SetupRemindersPrompt(
                        hasReminders: schedules.isNotEmpty,
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Bottom banner (tips/promotions)
                    const MessageWidget(position: 'home_bottom'),
                    const SizedBox(height: AppSpacing.lg),
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
