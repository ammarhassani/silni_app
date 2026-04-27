import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/models/streak_event.dart';
import '../../../core/providers/ai_preload_provider.dart';
import '../../../core/providers/streak_events_provider.dart';
import '../../../shared/widgets/premium_loading_indicator.dart';
import '../../../shared/widgets/streak_milestone_modal.dart';
import '../../../shared/models/hadith_model.dart';
import '../../../core/config/supabase_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/providers/realtime_provider.dart';
import '../providers/home_providers.dart';
import '../widgets/widgets.dart';
import '../../../shared/widgets/message_widget.dart';
import '../../../shared/widgets/persistent_bottom_nav.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../family_groups/widgets/family_activity_feed.dart';
import '../../family_groups/widgets/family_celebration_card.dart';
import '../../family_tree/providers/family_graph_providers.dart';

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
  final List<StreakEvent> _pendingEvents = [];

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
    // Premium onboarding intentionally NOT triggered from home — per Phase 3
    // it shows only once, immediately after the first MAX purchase, never on
    // subsequent app opens regardless of completion state.
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

      // Process pending streak events
      if (_pendingEvents.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            for (final event in _pendingEvents) {
              _processStreakEvent(event);
            }
            _pendingEvents.clear();
          }
        });
      }
    }
  }

  Future<void> _loadDailyHadith() async {
    // Wrapped in try/catch/finally because `_isLoadingHadith` was leaving
    // the home spinner spinning forever on any throw from getDailyHadith
    // (network failure, malformed admin row, etc.). The hadithService has
    // its own hardcoded fallback list, so the worst case here is a null
    // hadith — we hide the section gracefully.
    final hadithService = ref.read(hadithServiceProvider);
    Hadith? hadith;
    try {
      hadith = await hadithService.getDailyHadith();
    } catch (_) {
      hadith = null;
    } finally {
      if (mounted) {
        setState(() {
          _dailyHadith = hadith;
          _isLoadingHadith = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _floatingController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _processStreakEvent(StreakEvent event) {
    switch (event.type) {
      case StreakEventType.streakMilestone:
        _confettiController.play();
        if (event.streak != null) {
          StreakMilestoneModal.show(context, streak: event.streak!);
        }
        break;

      case StreakEventType.streakIncreased:
        break;

      case StreakEventType.streakWarning:
        if (mounted) {
          final themeColors = ref.read(themeColorsProvider);
          UIHelpers.showSnackBar(
            context,
            '💛 تذكير: عائلتك تشتاق لك — تواصل بسيط يفرق',
            icon: Icons.favorite_rounded,
            backgroundColor: themeColors.statusWarning,
            duration: const Duration(seconds: 5),
          );
        }
        break;

      case StreakEventType.streakCritical:
        if (mounted) {
          final themeColors = ref.read(themeColorsProvider);
          UIHelpers.showSnackBar(
            context,
            '🤍 تذكير بسيط: وقت حلو تتواصل مع أهلك',
            icon: Icons.favorite_rounded,
            backgroundColor: themeColors.statusWarning,
            duration: const Duration(seconds: 8),
          );
        }
        break;

      case StreakEventType.freezeEarned:
        // Freeze earned is shown in the milestone modal
        break;

      case StreakEventType.freezeUsed:
        if (mounted) {
          final infoColor = ref.read(themeColorsProvider).statusInfo;
          UIHelpers.showSnackBar(
            context,
            '❄️ تم استخدام تجميد السلسلة! سلسلتك محمية اليوم',
            icon: Icons.ac_unit_rounded,
            backgroundColor: infoColor,
            duration: const Duration(seconds: 4),
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

    // Listen for streak events (milestones, warnings, freezes) and dispatch
    // to confetti/modal/snackbar. Was previously a GamificationListener
    // widget; now a direct ref.listen so we don't need a widget shell.
    ref.listen<AsyncValue<StreakEvent>>(streakEventsStreamProvider,
        (previous, next) {
      next.whenData((event) {
        final lifecycleState = WidgetsBinding.instance.lifecycleState;
        final isInForeground = lifecycleState == null ||
            lifecycleState == AppLifecycleState.resumed;
        if (isInForeground) {
          _processStreakEvent(event);
        } else {
          _pendingEvents.add(event);
        }
      });
    });

    // Family group info (for activity feed + celebration card)
    final groupId = ref.watch(userFamilyGroupProvider).valueOrNull?.groupId;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      floatingActionButton: null,
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
                    HomeHeaderWidget(
                      displayName: displayName,
                      userId: userId,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const MessageWidget(position: 'home_top'),
                    const SizedBox(height: AppSpacing.sm),
                    const MessageWidget(screenPath: '/home'),
                    const SizedBox(height: AppSpacing.sm),
                    IslamicReminderWidget(
                      hadith: _dailyHadith,
                      isLoading: _isLoadingHadith,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  AppColors.premiumGold.withValues(alpha: 0.35),
                                  AppColors.premiumGold.withValues(alpha: 0.6),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.premiumGold.withValues(alpha: 0.6),
                                  AppColors.premiumGold.withValues(alpha: 0.35),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const QuickActionsWidget(),
                    const SizedBox(height: AppSpacing.md),
                    OccasionCard(userId: userId),
                    const SizedBox(height: AppSpacing.md),
                    const FamilyCirclesSection(),
                    if (groupId != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      FamilyActivityFeed(groupId: groupId),
                      const SizedBox(height: AppSpacing.md),
                      FamilyCelebrationCard(groupId: groupId),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    const DueRemindersSection(),
                    const SizedBox(height: AppSpacing.lg),
                    const TodaysActivitySection(),
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
