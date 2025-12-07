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
import '../../../shared/widgets/gamification_stats_card.dart';
import '../../../shared/widgets/floating_points_overlay.dart';
import '../../../shared/widgets/level_up_modal.dart';
import '../../../shared/widgets/badge_unlock_modal.dart';
import '../../../shared/widgets/streak_milestone_modal.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/models/interaction_model.dart';
import '../../../shared/models/hadith_model.dart';
import '../../../shared/models/reminder_schedule_model.dart';
import '../../../shared/services/relatives_service.dart';
import '../../../shared/services/interactions_service.dart';
import '../../../shared/services/hadith_service.dart';
import '../../../shared/services/reminder_schedules_service.dart';
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

  debugPrint(
    '🔄 [HOME] Creating/Recreating relatives stream provider for user: $userId',
  );
  debugPrint(
    '🔄 [HOME] Provider creation timestamp: ${DateTime.now().toIso8601String()}',
  );

  final service = ref.watch(relativesServiceProvider);
  final stream = service.getRelativesStream(userId);

  debugPrint('📡 [HOME] Relatives stream created, listening for updates...');
  return stream.map((relatives) {
    debugPrint(
      '📊 [HOME] Relatives stream updated: ${relatives.length} relatives at ${DateTime.now().toIso8601String()}',
    );

    // Log relative names for debugging
    final relativeNames = relatives
        .map((r) => '${r.fullName} (${r.id})')
        .toList();
    debugPrint('📊 [HOME] Current relatives: $relativeNames');

    return relatives;
  });
});

final todayInteractionsStreamProvider =
    StreamProvider.family<List<Interaction>, String>((ref, userId) {
      // Keep provider alive to cache data
      ref.keepAlive();

      debugPrint(
        '📡 [HOME] Creating today interactions stream provider for user: $userId',
      );
      final service = ref.watch(interactionsServiceProvider);
      final stream = service.getTodayInteractionsStream(userId);

      debugPrint(
        '📡 [HOME] Today interactions stream created, listening for updates...',
      );
      return stream.map((interactions) {
        debugPrint(
          '📡 [HOME] Today interactions stream updated: ${interactions.length} interactions',
        );
        return interactions;
      });
    });

final reminderSchedulesStreamProvider =
    StreamProvider.family<List<ReminderSchedule>, String>((ref, userId) {
      // Keep provider alive to cache data
      ref.keepAlive();

      debugPrint(
        '📡 [HOME] Creating reminder schedules stream provider for user: $userId',
      );
      final service = ref.watch(reminderSchedulesServiceProvider);
      final stream = service.getSchedulesStream(userId);

      debugPrint(
        '📡 [HOME] Reminder schedules stream created, listening for updates...',
      );
      return stream.map((schedules) {
        debugPrint(
          '📡 [HOME] Reminder schedules stream updated: ${schedules.length} schedules',
        );
        return schedules;
      });
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

  @override
  void initState() {
    super.initState();
    debugPrint('');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🏠 [HOME SCREEN] initState() called');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('✅ [HOME SCREEN] Adding lifecycle observer');

    WidgetsBinding.instance.addObserver(this);

    debugPrint('✅ [HOME SCREEN] Initializing animation controllers');
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    debugPrint('🔄 [HOME SCREEN] Loading daily hadith...');
    _loadDailyHadith();
    debugPrint('✅ [HOME SCREEN] initState() completed');
    debugPrint('');
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
    debugPrint('');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🏠 [HOME SCREEN] build() called');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // Try to get user from stream first
    debugPrint('🔍 [HOME SCREEN] Checking currentUserProvider stream...');
    final streamUser = ref.watch(currentUserProvider);
    debugPrint(
      '📊 [HOME SCREEN] Stream user: ${streamUser != null ? 'present (${streamUser.id})' : 'NULL'}',
    );

    // Fallback to synchronous check if stream hasn't emitted yet
    // This fixes the race condition on iOS where navigation happens before stream emits
    debugPrint(
      '🔍 [HOME SCREEN] Checking SupabaseConfig.currentUser fallback...',
    );
    final fallbackUser = SupabaseConfig.currentUser;
    debugPrint(
      '📊 [HOME SCREEN] Fallback user: ${fallbackUser != null ? 'present (${fallbackUser.id})' : 'NULL'}',
    );

    final user = streamUser ?? fallbackUser;
    debugPrint(
      '📊 [HOME SCREEN] Final user: ${user != null ? 'present (${user.id})' : 'NULL'}',
    );
    debugPrint('');

    // Show loading screen if user is not yet loaded
    if (user == null) {
      debugPrint(
        '🔴 [HOME SCREEN] No user available - showing loading spinner',
      );
      debugPrint(
        '🔴 [HOME SCREEN] This should NOT happen after successful auth!',
      );
      debugPrint(
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      );
      debugPrint('');
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final displayName =
        user.userMetadata?['full_name'] as String? ?? user.email ?? 'المستخدم';
    final userId = user.id;
    debugPrint('👤 [HOME SCREEN] User loaded successfully:');
    debugPrint('   - User ID: $userId');
    debugPrint('   - Display name: $displayName');
    debugPrint('   - Email: ${user.email}');
    debugPrint('✅ [HOME SCREEN] Building home screen UI...');
    debugPrint('');

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
                    _buildIslamicHeader(displayName),
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
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Gamification Stats
                    GamificationStatsCard(userId: userId, compact: true),
                    const SizedBox(height: AppSpacing.xl),

                    // Today's connections
                    todayInteractionsAsync.when(
                      data: (interactions) =>
                          _buildTodaysActivity(interactions),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Who needs your call?
                    relativesAsync.when(
                      data: (relatives) => _buildNeedsContact(relatives),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 120), // Extra padding for bottom nav
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIslamicHeader(String displayName) {
    final themeColors = ref.watch(themeColorsProvider);
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

  Widget _buildDefaultAvatar(Relative relative) {
    return Center(
      child: Text(
        relative.fullName.isNotEmpty ? relative.fullName[0] : '؟',
        style: AppTypography.headlineMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
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

  Widget _buildTodaysActivity(List<Interaction> interactions) {
    if (interactions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تواصل اليوم',
          style: AppTypography.headlineSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: interactions.take(3).length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final interaction = interactions[index];
            return _buildInteractionCard(interaction);
          },
        ),
      ],
    );
  }

  Widget _buildInteractionCard(Interaction interaction) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: Center(
              child: Text(
                interaction.type.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  interaction.type.arabicName,
                  style: AppTypography.titleSmall.copyWith(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  interaction.relativeTime,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeedsContact(List<Relative> allRelatives) {
    final themeColors = ref.watch(themeColorsProvider);
    // Don't show anything if there are no relatives at all
    if (allRelatives.isEmpty) {
      return const SizedBox.shrink();
    }

    final needsContact = allRelatives
        .where((r) => r.needsContact)
        .take(3)
        .toList();

    if (needsContact.isEmpty) {
      return GlassCard(
        gradient: LinearGradient(
          colors: [
            themeColors.primaryLight.withOpacity(0.3),
            AppColors.premiumGold.withOpacity(0.2),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ممتاز! 🎉',
                    style: AppTypography.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'تواصلت مع جميع أقاربك مؤخراً',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'يحتاجون تواصلك ❤️',
          style: AppTypography.headlineSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: needsContact.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            return _buildNeedsContactCard(needsContact[index]);
          },
        ),
      ],
    );
  }

  Widget _buildNeedsContactCard(Relative relative) {
    final daysSince = relative.daysSinceLastContact ?? 0;

    return GestureDetector(
      onTap: () {
        context.push('${AppRoutes.relativeDetail}/${relative.id}');
      },
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.streakFire,
              ),
              child: relative.photoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        relative.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildDefaultAvatar(relative),
                      ),
                    )
                  : _buildDefaultAvatar(relative),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    relative.fullName,
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    relative.lastContactDate == null
                        ? (relative.gender == Gender.female
                              ? 'لم تتواصل معها بعد'
                              : 'لم تتواصل معه بعد')
                        : 'آخر تواصل: منذ $daysSince يوم',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.phone, color: Colors.white.withOpacity(0.7), size: 24),
          ],
        ),
      ),
    );
  }
}
