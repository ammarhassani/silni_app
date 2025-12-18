import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import 'package:intl/intl.dart' as intl;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/models/gamification_event.dart';
import '../../../core/providers/gamification_events_provider.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/avatar_carousel.dart';
import '../../../shared/widgets/floating_points_overlay.dart';
import '../../../shared/widgets/level_up_modal.dart';
import '../../../shared/widgets/badge_unlock_modal.dart';
import '../../../shared/widgets/streak_milestone_modal.dart';
import '../../../shared/widgets/error_widgets.dart';
import '../../../core/providers/stream_recovery_provider.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/models/interaction_model.dart';
import '../../../shared/models/hadith_model.dart';
import '../../../shared/models/reminder_schedule_model.dart';
import '../../../shared/services/relatives_service.dart';
import '../../../shared/services/interactions_service.dart';
import '../../../shared/services/hadith_service.dart';
import '../../../shared/services/reminder_schedules_service.dart';
import '../../../shared/services/notification_history_service.dart';
import '../../../shared/providers/interactions_provider.dart';
import '../../../core/config/supabase_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/providers/realtime_provider.dart';

// Note: relativesServiceProvider is now imported from shared/services/relatives_service.dart
// Note: interactionsServiceProvider is now imported from shared/providers/interactions_provider.dart

final hadithServiceProvider = Provider((ref) {
  return HadithService();
});

final relativesStreamProvider = StreamProvider.family<List<Relative>, String>((
  ref,
  userId,
) {
  // Keep provider alive to cache data
  ref.keepAlive();

  final service = ref.watch(relativesServiceProvider);
  return service.getRelativesStream(userId);
});

final todayInteractionsStreamProvider =
    StreamProvider.family<List<Interaction>, String>((ref, userId) {
      // Keep provider alive to cache data
      ref.keepAlive();

      final service = ref.watch(interactionsServiceProvider);
      return service.getTodayInteractionsStream(userId);
    });

final reminderSchedulesStreamProvider =
    StreamProvider.family<List<ReminderSchedule>, String>((ref, userId) {
      // Keep provider alive to cache data
      ref.keepAlive();

      final service = ref.watch(reminderSchedulesServiceProvider);
      return service.getSchedulesStream(userId);
    });

/// Provider for today's due relatives based on reminder schedules
/// Returns relatives with ALL their applicable frequencies (e.g., daily + friday)
final todayDueRelativesProvider = Provider.family<List<DueRelativeWithFrequencies>, ({
  List<ReminderSchedule> schedules,
  List<Relative> relatives,
})>((ref, data) {
  final schedules = data.schedules;
  final relatives = data.relatives;

  // Map: relativeId -> Set<ReminderFrequency>
  // This tracks ALL frequencies that apply to each relative
  final relativeFrequencies = <String, Set<ReminderFrequency>>{};

  for (final schedule in schedules) {
    if (schedule.isActive && schedule.shouldFireToday()) {
      for (final relativeId in schedule.relativeIds) {
        relativeFrequencies.putIfAbsent(relativeId, () => <ReminderFrequency>{});
        relativeFrequencies[relativeId]!.add(schedule.frequency);
      }
    }
  }

  // Build the result list with frequency info
  return relatives
      .where((r) => relativeFrequencies.containsKey(r.id))
      .map((r) => DueRelativeWithFrequencies(
            relative: r,
            frequencies: relativeFrequencies[r.id]!,
          ))
      .toList();
});

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

  // Carousel state for frequency slides
  final PageController _frequencyPageController = PageController();
  Timer? _frequencyAutoSlideTimer;
  int _currentFrequencyPage = 0;

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
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When app resumes, process pending events
    if (state == AppLifecycleState.resumed && _pendingEvents.isNotEmpty) {
      // Delay slightly to ensure UI is ready
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
    _frequencyAutoSlideTimer?.cancel();
    _frequencyPageController.dispose();
    super.dispose();
  }

  /// Process a single gamification event
  void _processGamificationEvent(GamificationEvent event) {
    switch (event.type) {
      case GamificationEventType.pointsEarned:
        // Show floating points animation
        context.showFloatingPoints(points: event.points ?? 0);
        break;

      case GamificationEventType.levelUp:
        // Trigger confetti for level up
        _confettiController.play();
        // Show level up celebration modal
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
        // Trigger confetti for streak milestones
        _confettiController.play();
        // Show streak milestone celebration modal
        if (event.streak != null) {
          StreakMilestoneModal.show(context, streak: event.streak!);
        }
        break;

      case GamificationEventType.badgeUnlocked:
        // Trigger confetti for badge unlocks
        _confettiController.play();
        // Show badge unlock celebration modal
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
        // No special UI for regular streak increases
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Try to get user from stream first
    final streamUser = ref.watch(currentUserProvider);

    // Fallback to synchronous check if stream hasn't emitted yet
    // This fixes the race condition on iOS where navigation happens before stream emits
    final fallbackUser = SupabaseConfig.currentUser;

    final user = streamUser ?? fallbackUser;

    // Show loading screen if user is not yet loaded
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final displayName =
        user.userMetadata?['full_name'] as String? ?? user.email ?? 'المستخدم';
    final userId = user.id;

    final themeColors = ref.watch(themeColorsProvider);

    // Listen to gamification events for visual feedback
    ref.listen<AsyncValue<GamificationEvent>>(
      gamificationEventsStreamProvider,
      (previous, next) {
        next.whenData((event) {
          // Only process events for this user
          if (event.userId != userId) return;

          // Check if app is in foreground
          final appLifecycleState = WidgetsBinding.instance.lifecycleState;
          final isInForeground =
              appLifecycleState == null ||
              appLifecycleState == AppLifecycleState.resumed;

          if (isInForeground) {
            // Process immediately if app is visible
            _processGamificationEvent(event);
          } else {
            // Store for later if app is in background
            _pendingEvents.add(event);
          }
        });
      },
    );

    // Initialize real-time subscriptions for this user
    ref.watch(autoRealtimeSubscriptionsProvider);

    final relativesAsync = ref.watch(relativesStreamProvider(userId));
    final todayInteractionsAsync = ref.watch(
      todayInteractionsStreamProvider(userId),
    );
    final schedulesAsync = ref.watch(reminderSchedulesStreamProvider(userId));
    final todayContactedAsync = ref.watch(todayContactedRelativesProvider(userId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody:
          true, // Extend body behind bottom nav for glassmorphism effect
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
            bottom:
                false, // Don't apply safe area to bottom so content flows under nav
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Islamic greeting header
                    _buildIslamicHeader(displayName, userId),
                    const SizedBox(height: AppSpacing.xl),

                    // Hadith/Islamic reminder of the day
                    _buildIslamicReminder(),
                    const SizedBox(height: AppSpacing.xl),

                    // Quick Actions
                    _buildQuickActions(),
                    const SizedBox(height: AppSpacing.xl),

                    // Family members circle avatars
                    relativesAsync.when(
                      data: (relatives) => _buildFamilyCircles(relatives),
                      loading: () => const FamilyCirclesSkeleton(),
                      error: (error, _) => InlineErrorWidget(
                        message: 'فشل في تحميل بيانات العائلة',
                        onRetry: () => ref.invalidate(relativesStreamProvider(userId)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // REMINDERS SECTION
                    // Frequency carousel for tomorrow/yesterday reminders
                    _buildFrequencyCarousel(
                      relativesAsync,
                      schedulesAsync,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Due Reminders Card - today's reminders as tasks
                    _buildDueRemindersCard(
                      userId,
                      relativesAsync,
                      schedulesAsync,
                      todayContactedAsync,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Today's connections (with relative names)
                    relativesAsync.when(
                      data: (relatives) => todayInteractionsAsync.when(
                        data: (interactions) =>
                            _buildTodaysActivity(interactions, relatives),
                        loading: () => const SizedBox.shrink(),
                        error: (error, _) => InlineErrorWidget(
                          message: 'فشل في تحميل نشاط اليوم',
                          onRetry: () => ref.invalidate(todayInteractionsStreamProvider(userId)),
                          compact: true,
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (error, _) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Setup reminders prompt (only for new users without reminders)
                    schedulesAsync.when(
                      data: (schedules) => _buildSetupRemindersPrompt(schedules),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: AppSpacing.xl), // Padding for bottom nav
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDueRemindersCard(
    String userId,
    AsyncValue<List<Relative>> relativesAsync,
    AsyncValue<List<ReminderSchedule>> schedulesAsync,
    AsyncValue<Set<String>> todayContactedAsync,
  ) {
    final themeColors = ref.watch(themeColorsProvider);

    // Wait for all data to load
    return relativesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (relatives) => schedulesAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (schedules) {
          // Get today's due relatives
          final dueRelatives = ref.watch(todayDueRelativesProvider((
            schedules: schedules,
            relatives: relatives,
          )));

          // Get contacted relatives set
          final contactedSet = todayContactedAsync.valueOrNull ?? <String>{};

          // If no reminders exist at all, show "add reminders" prompt
          if (schedules.isEmpty) {
            return GlassCard(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.withOpacity(0.3),
                  Colors.grey.withOpacity(0.1),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 48,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'لا توجد تذكيرات',
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'أضف تذكيرات لتبقى على تواصل مع أقاربك',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.reminders),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: themeColors.primary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Text(
                        'إضافة تذكير',
                        style: AppTypography.labelMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn();
          }

          // If no due reminders today
          if (dueRelatives.isEmpty) {
            return GlassCard(
              gradient: LinearGradient(
                colors: [
                  themeColors.primaryLight.withOpacity(0.3),
                  AppColors.premiumGold.withOpacity(0.2),
                ],
              ),
              child: Row(
                children: [
                  const Text('✅', style: TextStyle(fontSize: 40)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'أنت على تواصل جيد!',
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'لا توجد تذكيرات لليوم',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn();
          }

          // Count contacted vs total
          final contactedCount = dueRelatives.where(
            (r) => contactedSet.contains(r.relative.id)
          ).length;
          final totalCount = dueRelatives.length;
          final allContacted = contactedCount == totalCount;

          // All relatives contacted - show celebration
          if (allContacted) {
            return GlassCard(
              gradient: LinearGradient(
                colors: [
                  AppColors.premiumGold.withOpacity(0.4),
                  themeColors.primaryLight.withOpacity(0.3),
                ],
              ),
              child: Row(
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 40)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'أحسنت! أكملت مهامك',
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'تواصلت مع جميع الأقارب في تذكيراتك اليوم',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
          }

          // Show due reminders as tasks
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'تذكيرات اليوم',
                    style: AppTypography.headlineSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: themeColors.primary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      '$contactedCount / $totalCount',
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: totalCount > 0 ? contactedCount / totalCount : 0,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.premiumGold,
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Due relatives list
              ...dueRelatives.take(5).map((dueRelative) {
                final isContacted = contactedSet.contains(dueRelative.relative.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _buildDueRelativeCard(dueRelative, isContacted, userId),
                );
              }),

              // Show more button if more than 5
              if (dueRelatives.length > 5)
                GestureDetector(
                  onTap: () => context.push(AppRoutes.remindersDue),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Text(
                      'عرض ${dueRelatives.length - 5} المزيد...',
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ).animate().fadeIn().slideY(begin: 0.1, end: 0);
        },
      ),
    );
  }

  /// Helper to check if a schedule fires on a specific date
  bool _shouldFireOnDate(ReminderSchedule schedule, DateTime date) {
    switch (schedule.frequency) {
      case ReminderFrequency.daily:
        return true;
      case ReminderFrequency.weekly:
        if (schedule.customDays != null && schedule.customDays!.isNotEmpty) {
          return schedule.customDays!.contains(date.weekday);
        }
        return true;
      case ReminderFrequency.monthly:
        if (schedule.dayOfMonth != null) {
          return date.day == schedule.dayOfMonth;
        }
        return false;
      case ReminderFrequency.friday:
        return date.weekday == 5;
      case ReminderFrequency.custom:
        return false;
    }
  }

  /// Build hint text showing first 3 relatives + count
  String _buildRelativesHint(List<Relative> relatives) {
    if (relatives.isEmpty) return '';
    if (relatives.length <= 3) {
      return relatives.map((r) => r.fullName.split(' ').first).join('، ');
    }
    final firstThree = relatives.take(3).map((r) => r.fullName.split(' ').first).join('، ');
    return '$firstThree +${relatives.length - 3}';
  }

  /// Get unique frequencies for schedules firing on a date (Friday first)
  List<ReminderFrequency> _getFrequenciesOnDate(List<ReminderSchedule> schedules, DateTime date) {
    final activeSchedules = schedules.where((s) =>
      s.isActive && _shouldFireOnDate(s, date)
    ).toList();

    if (activeSchedules.isEmpty) return [];

    // Get unique frequencies and sort (Friday first)
    final frequencies = activeSchedules.map((s) => s.frequency).toSet().toList();
    frequencies.sort((a, b) {
      if (a == ReminderFrequency.friday) return -1;
      if (b == ReminderFrequency.friday) return 1;
      return a.arabicName.compareTo(b.arabicName);
    });

    return frequencies;
  }

  /// Get relatives due on a specific date for a specific frequency
  List<Relative> _getRelativesByFrequencyOnDate(
    List<ReminderSchedule> schedules,
    List<Relative> relatives,
    DateTime date,
    ReminderFrequency frequency,
  ) {
    final dueRelativeIds = <String>{};
    for (final schedule in schedules) {
      if (schedule.isActive &&
          schedule.frequency == frequency &&
          _shouldFireOnDate(schedule, date)) {
        dueRelativeIds.addAll(schedule.relativeIds);
      }
    }
    return relatives.where((r) => dueRelativeIds.contains(r.id)).toList();
  }

  /// Start auto-slide timer for frequency carousel
  void _startFrequencyAutoSlide(int totalPages) {
    _frequencyAutoSlideTimer?.cancel();
    if (totalPages <= 1) return;

    _frequencyAutoSlideTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        final nextPage = (_currentFrequencyPage + 1) % totalPages;
        _frequencyPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  /// Build the frequency carousel for tomorrow/yesterday reminders
  Widget _buildFrequencyCarousel(
    AsyncValue<List<Relative>> relativesAsync,
    AsyncValue<List<ReminderSchedule>> schedulesAsync,
  ) {
    return relativesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (relatives) => schedulesAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (schedules) {
          final tomorrow = DateTime.now().add(const Duration(days: 1));
          final yesterday = DateTime.now().subtract(const Duration(days: 1));

          // Get all unique frequencies that have reminders on tomorrow or yesterday
          final tomorrowFreqs = _getFrequenciesOnDate(schedules, tomorrow);
          final yesterdayFreqs = _getFrequenciesOnDate(schedules, yesterday);
          final allFrequencies = {...tomorrowFreqs, ...yesterdayFreqs}.toList();

          // Sort frequencies (Friday first)
          allFrequencies.sort((a, b) {
            if (a == ReminderFrequency.friday) return -1;
            if (b == ReminderFrequency.friday) return 1;
            return a.arabicName.compareTo(b.arabicName);
          });

          if (allFrequencies.isEmpty) return const SizedBox.shrink();

          // Start auto-slide timer
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _startFrequencyAutoSlide(allFrequencies.length);
          });

          return Column(
            children: [
              SizedBox(
                height: 140,
                child: PageView.builder(
                  controller: _frequencyPageController,
                  itemCount: allFrequencies.length,
                  onPageChanged: (index) {
                    setState(() => _currentFrequencyPage = index);
                  },
                  itemBuilder: (context, index) {
                    final frequency = allFrequencies[index];
                    return _buildFrequencySlide(
                      frequency,
                      schedules,
                      relatives,
                      tomorrow,
                      yesterday,
                    );
                  },
                ),
              ),
              // Dot indicators
              if (allFrequencies.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      allFrequencies.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentFrequencyPage == index ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentFrequencyPage == index
                              ? _getFrequencyColor(allFrequencies[index])
                              : Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ).animate().fadeIn(delay: const Duration(milliseconds: 100));
        },
      ),
    );
  }

  /// Get color for a frequency type
  Color _getFrequencyColor(ReminderFrequency frequency) {
    switch (frequency) {
      case ReminderFrequency.friday:
        return const Color(0xFF1B5E20); // Islamic green
      case ReminderFrequency.daily:
        return const Color(0xFF1976D2); // Blue
      case ReminderFrequency.weekly:
        return const Color(0xFF7B1FA2); // Purple
      case ReminderFrequency.monthly:
        return const Color(0xFFE64A19); // Deep orange
      case ReminderFrequency.custom:
        return const Color(0xFF455A64); // Blue grey
    }
  }

  /// Build a single frequency slide showing tomorrow and yesterday
  Widget _buildFrequencySlide(
    ReminderFrequency frequency,
    List<ReminderSchedule> schedules,
    List<Relative> relatives,
    DateTime tomorrow,
    DateTime yesterday,
  ) {
    final tomorrowRelatives = _getRelativesByFrequencyOnDate(
      schedules,
      relatives,
      tomorrow,
      frequency,
    );
    final yesterdayRelatives = _getRelativesByFrequencyOnDate(
      schedules,
      relatives,
      yesterday,
      frequency,
    );

    final color = _getFrequencyColor(frequency);
    final isFriday = frequency == ReminderFrequency.friday;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.25),
            color.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with frequency name and emoji
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.3),
                  ),
                  child: Center(
                    child: Text(
                      isFriday ? '🕌' : frequency.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  frequency.arabicName,
                  style: AppTypography.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Tomorrow row
            if (tomorrowRelatives.isNotEmpty)
              _buildFrequencyRow(
                label: 'غداً',
                relatives: tomorrowRelatives,
                color: color,
                isPast: false,
              ),
            // Yesterday row
            if (yesterdayRelatives.isNotEmpty)
              _buildFrequencyRow(
                label: 'أمس',
                relatives: yesterdayRelatives,
                color: color,
                isPast: true,
              ),
            // Empty state if no relatives in either
            if (tomorrowRelatives.isEmpty && yesterdayRelatives.isEmpty)
              Center(
                child: Text(
                  'لا يوجد تذكيرات',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build a row for tomorrow or yesterday in frequency slide
  Widget _buildFrequencyRow({
    required String label,
    required List<Relative> relatives,
    required Color color,
    required bool isPast,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            isPast ? Icons.history : Icons.schedule,
            color: color.withOpacity(isPast ? 0.5 : 0.8),
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white.withOpacity(isPast ? 0.5 : 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _buildRelativesHint(relatives),
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white.withOpacity(isPast ? 0.4 : 0.7),
                decoration: isPast ? TextDecoration.lineThrough : null,
                decorationColor: Colors.white.withOpacity(0.3),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(isPast ? 0.2 : 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${relatives.length}',
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white.withOpacity(isPast ? 0.6 : 1.0),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDueRelativeCard(DueRelativeWithFrequencies dueRelative, bool isContacted, String userId) {
    final relative = dueRelative.relative;
    final hasFriday = dueRelative.hasFridayReminder;

    // Friday special green color
    const fridayGreen = Color(0xFF1B5E20);
    const fridayGreenLight = Color(0xFF4CAF50);

    return GestureDetector(
      onTap: () => context.push('${AppRoutes.relativeDetail}/${relative.id}'),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        gradient: isContacted
            ? LinearGradient(
                colors: [
                  Colors.green.withValues(alpha: 0.3),
                  Colors.green.withValues(alpha: 0.1),
                ],
              )
            : hasFriday
                ? LinearGradient(
                    colors: [
                      fridayGreen.withValues(alpha: 0.3),
                      fridayGreenLight.withValues(alpha: 0.15),
                    ],
                  )
                : null,
        child: Row(
          children: [
            // Checkbox/status indicator
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isContacted
                    ? Colors.green
                    : Colors.white.withValues(alpha: 0.2),
                border: isContacted
                    ? null
                    : Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
              ),
              child: isContacted
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),

            // Relative info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    relative.fullName,
                    style: AppTypography.titleSmall.copyWith(
                      color: Colors.white,
                      decoration: isContacted ? TextDecoration.lineThrough : null,
                      decorationColor: Colors.white.withValues(alpha: 0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        relative.relationshipType.arabicName,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Frequency badges
                      ..._buildFrequencyBadges(dueRelative.sortedFrequencies),
                    ],
                  ),
                ],
              ),
            ),

            // Show contacted badge or arrow
            if (isContacted)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  'تم',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.5),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  /// Build frequency badges for a relative (e.g., [🕌 جمعة] [يومي])
  List<Widget> _buildFrequencyBadges(List<ReminderFrequency> frequencies) {
    return frequencies.map((freq) => Padding(
      padding: const EdgeInsets.only(left: 4),
      child: _buildFrequencyBadge(freq),
    )).toList();
  }

  /// Build a single frequency badge with special styling for Friday
  Widget _buildFrequencyBadge(ReminderFrequency frequency) {
    final isFriday = frequency == ReminderFrequency.friday;

    // Friday special green styling
    const fridayGreen = Color(0xFF1B5E20);
    const fridayGreenLight = Color(0xFF4CAF50);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isFriday
            ? fridayGreen.withOpacity(0.6)
            : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: isFriday
            ? Border.all(color: fridayGreenLight.withOpacity(0.5), width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isFriday) ...[
            const Text('🕌', style: TextStyle(fontSize: 10)),
            const SizedBox(width: 2),
          ],
          Text(
            frequency.arabicName,
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white,
              fontSize: 9,
              fontWeight: isFriday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIslamicHeader(String displayName, String userId) {
    final themeColors = ref.watch(themeColorsProvider);
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider(userId));
    final hour = DateTime.now().hour;
    String greeting = 'السلام عليكم';
    if (hour < 12) {
      greeting = 'صباح الخير';
    } else if (hour < 18) {
      greeting = 'مساء الخير';
    }

    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: AppTypography.bodyLarge.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayName,
                        style: AppTypography.headlineMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Notification bell icon with unread badge
                GestureDetector(
                  onTap: () => context.push(AppRoutes.notificationHistory),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        // Unread badge
                        unreadCountAsync.when(
                          data: (count) => count > 0
                              ? Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Center(
                                      child: Text(
                                        count > 99 ? '99+' : count.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '"ومن أحب أن يُبسَط له في رزقه، وأن يُنسَأ له في أثره، فليصل رحمه"',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.8),
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 600))
        .slideY(begin: -0.1, end: 0);
  }

  Widget _buildIslamicReminder() {
    final themeColors = ref.watch(themeColorsProvider);
    if (_isLoadingHadith) {
      return GlassCard(
        gradient: LinearGradient(
          colors: [
            themeColors.primary.withOpacity(0.2),
            AppColors.premiumGold.withOpacity(0.1),
          ],
        ),
        child: const HadithSkeletonLoader(),
      );
    }

    if (_dailyHadith == null) {
      return const SizedBox.shrink();
    }

    final hadith = _dailyHadith!;

    return GlassCard(
          gradient: LinearGradient(
            colors: [
              themeColors.primary.withOpacity(0.3),
              AppColors.premiumGold.withOpacity(0.2),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: themeColors.goldenGradient,
                    ),
                    child: const Center(
                      child: Text('📿', style: TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hadith.type == HadithType.hadith
                              ? 'حديث اليوم'
                              : 'قول العلماء',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.premiumGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (hadith.formattedSource.isNotEmpty)
                          Text(
                            hadith.formattedSource,
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Hadith text
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: AppColors.premiumGold.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  hadith.arabicText,
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    height: 1.8,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),

              // Reference
              if (hadith.reference.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.book,
                      size: 14,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      hadith.reference,
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        )
        .animate(delay: const Duration(milliseconds: 200))
        .fadeIn()
        .slideX(begin: 0.2, end: 0);
  }

  Widget _buildQuickActions() {
    final themeColors = ref.watch(themeColorsProvider);
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إجراءات سريعة',
              style: AppTypography.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.notifications_active_rounded,
                    title: 'التذكيرات',
                    subtitle: 'نظّم تذكيراتك',
                    gradient: themeColors.primaryGradient,
                    onTap: () => context.push(AppRoutes.reminders),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.assessment_rounded,
                    title: 'الإحصائيات',
                    subtitle: 'تقدمك اليومي',
                    gradient: LinearGradient(
                      colors: [
                        AppColors.emotionalPurple.withOpacity(0.6),
                        AppColors.calmBlue.withOpacity(0.4),
                      ],
                    ),
                    onTap: () => context.push(AppRoutes.statistics),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.account_tree_rounded,
                    title: 'شجرة العائلة',
                    subtitle: 'تصور جميل لعائلتك',
                    gradient: LinearGradient(
                      colors: [
                        themeColors.primaryDark,
                        themeColors.primary.withOpacity(0.8),
                      ],
                    ),
                    onTap: () => context.push(AppRoutes.familyTree),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: const SizedBox()),
              ],
            ),
          ],
        )
        .animate(delay: const Duration(milliseconds: 300))
        .fadeIn()
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        gradient: gradient,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyCircles(List<Relative> relatives) {
    if (relatives.isEmpty) {
      return _buildEmptyState();
    }

    // Sort by creation date (oldest first) so newest appears on LEFT in RTL
    final sortedByDate = List<Relative>.from(relatives)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Show first 8 relatives in carousel
    final displayRelatives = sortedByDate.take(8).toList();

    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'عائلتك',
                  style: AppTypography.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(AppRoutes.relatives),
                  child: Row(
                    children: [
                      Text(
                        'عرض الكل',
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AvatarCarousel(
              relatives: displayRelatives,
              onAddRelative: () => context.push(AppRoutes.addRelative),
            ),
          ],
        )
        .animate(delay: const Duration(milliseconds: 400))
        .fadeIn()
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildEmptyState() {
    return GlassCard(
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'ابدأ بإضافة أفراد عائلتك',
            style: AppTypography.titleMedium.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'أضف والديك، إخوتك، أجدادك وباقي أقاربك',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          GradientButton(
            text: 'إضافة أول قريب',
            onPressed: () {
              context.push(AppRoutes.addRelative);
            },
            icon: Icons.person_add,
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysActivity(List<Interaction> interactions, List<Relative> relatives) {
    if (interactions.isEmpty) return const SizedBox.shrink();

    // Create a map for quick relative lookup
    final relativeMap = {for (var r in relatives) r.id: r};

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with icon
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: Colors.white70,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'سجل التواصل',
                style: AppTypography.titleSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: AppSpacing.sm),
          // Compact list
          ...interactions.take(4).map((interaction) {
            final relative = relativeMap[interaction.relativeId];
            return _buildCompactInteractionItem(interaction, relative);
          }),
        ],
      ),
    );
  }

  Widget _buildCompactInteractionItem(Interaction interaction, Relative? relative) {
    final relativeName = relative?.fullName ?? 'قريب';

    return GestureDetector(
      onTap: relative != null
          ? () => context.push('${AppRoutes.relativeDetail}/${relative.id}')
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            // Interaction emoji in colored circle
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getInteractionColor(interaction.type).withValues(alpha: 0.15),
              ),
              child: Center(
                child: Text(
                  interaction.type.emoji,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Name
            Expanded(
              child: Text(
                relativeName,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Time
            Text(
              interaction.relativeTime,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getInteractionColor(InteractionType type) {
    switch (type) {
      case InteractionType.call:
        return Colors.green;
      case InteractionType.message:
        return Colors.blue;
      case InteractionType.visit:
        return Colors.orange;
      case InteractionType.gift:
        return Colors.pink;
      case InteractionType.event:
        return Colors.teal;
      case InteractionType.other:
        return Colors.purple;
    }
  }

  /// Build setup reminders prompt for new users without reminders
  Widget _buildSetupRemindersPrompt(List<ReminderSchedule> schedules) {
    // If user has reminders, don't show anything
    if (schedules.isNotEmpty) {
      return const SizedBox.shrink();
    }

    final themeColors = ref.watch(themeColorsProvider);

    // Show prompt for new users to set up reminders
    return GestureDetector(
      onTap: () => context.push(AppRoutes.reminders),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        gradient: LinearGradient(
          colors: [
            themeColors.primary.withValues(alpha: 0.3),
            AppColors.premiumGold.withValues(alpha: 0.2),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.premiumGold.withValues(alpha: 0.3),
              ),
              child: const Center(
                child: Text('🔔', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'اضبط تذكيراتك لتبدأ رحلة الصلة',
                style: AppTypography.titleSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withValues(alpha: 0.7),
              size: 16,
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }
}
