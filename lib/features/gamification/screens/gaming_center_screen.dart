import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../../../core/ai/deepseek_ai_service.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/services/gamification_config_service.dart';
import '../../../shared/widgets/share_bottom_sheet.dart';
import '../../../shared/widgets/share_cards/wrapped_share_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/premium_loading_indicator.dart';
import 'badges_screen.dart';
import '../../../shared/widgets/message_widget.dart';
import '../../../shared/widgets/persistent_bottom_nav.dart';
import '../../family_tree/providers/family_graph_providers.dart';
import '../../home/providers/home_providers.dart';

/// Gaming Center - Main gamification hub with dramatic design
class GamingCenterScreen extends ConsumerStatefulWidget {
  const GamingCenterScreen({super.key});

  @override
  ConsumerState<GamingCenterScreen> createState() =>
      _GamingCenterScreenState();
}

class _GamingCenterScreenState extends ConsumerState<GamingCenterScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _glowController;
  late Animation<double> _glowIntensity;
  Map<String, dynamic>? _userStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glowIntensity = Tween<double>(begin: 0.3, end: 0.55).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _loadUserStats();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _loadUserStats() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      await GamificationConfigService.instance.refresh();

      final response = await SupabaseConfig.client
          .from('users')
          .select(
            'points, level, current_streak, longest_streak, badges, total_interactions',
          )
          .eq('id', user.id)
          .single();

      final relativesRows = await SupabaseConfig.client
          .from('relatives')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_archived', false);
      response['active_relatives_count'] = (relativesRows as List).length;

      final points = response['points'] as int? ?? 0;
      final dbLevel = response['level'] as int? ?? 1;
      final calculatedLevel =
          GamificationConfigService.instance.calculateLevel(points);

      if (calculatedLevel != dbLevel) {
        await SupabaseConfig.client
            .from('users')
            .update({'level': calculatedLevel}).eq('id', user.id);
        response['level'] = calculatedLevel;
      }

      if (mounted) {
        setState(() {
          _userStats = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);
    final groupInfo = ref.watch(userFamilyGroupProvider).valueOrNull;
    final isInGroup = groupInfo != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Semantics(
        label: 'مركز الإنجازات والألعاب',
        child: Stack(
          children: [
            // Ambient orbs
            _buildAmbientOrbs(themeColors),

            // Confetti
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.05,
                numberOfParticles: 30,
                gravity: 0.1,
                colors: [
                  themeColors.levelMax,
                  themeColors.primary,
                  themeColors.statusError,
                  themeColors.accent,
                  themeColors.secondary,
                ],
              ),
            ),

            // Main content
            SafeArea(
              bottom: false,
              child: _isLoading
                  ? const Center(
                      child: PremiumLoadingIndicator(
                        message: 'جاري تحميل مركز الألعاب...',
                      ),
                    )
                  : CustomScrollView(
                      slivers: [
                        // Compact header
                        SliverToBoxAdapter(
                          child: _buildCompactHeader(themeColors),
                        ),

                        // In-App Messages
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg),
                            child: MessageWidget(
                                screenPath: '/gaming-center'),
                          ),
                        ),

                        // Stats + XP merged card
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.sm,
                            ),
                            child: _buildStatsCard(themeColors),
                          ),
                        ),

                        // Feature grid
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1.15,
                              crossAxisSpacing: AppSpacing.md,
                              mainAxisSpacing: AppSpacing.md,
                            ),
                            delegate: SliverChildListDelegate([
                              _buildFeatureCard(
                                title: 'الأوسمة',
                                subtitle:
                                    '${(_userStats?['badges'] as List?)?.length ?? 0}/${BadgeData.allBadges.length}',
                                icon: Icons.emoji_events_rounded,
                                color: themeColors.levelMax,
                                onTap: () =>
                                    context.push(AppRoutes.badges),
                                themeColors: themeColors,
                                delay: 0,
                              ),
                              _buildFeatureCard(
                                title: 'المتصدرين',
                                subtitle: 'تنافس مع الجميع',
                                icon: Icons.leaderboard_rounded,
                                color:
                                    themeColors.streakFire.colors.first,
                                onTap: () =>
                                    context.push(AppRoutes.leaderboard),
                                themeColors: themeColors,
                                delay: 1,
                              ),
                              _buildFeatureCard(
                                title: 'الإحصائيات',
                                subtitle: 'تفاصيل تقدمك',
                                icon: Icons.analytics_rounded,
                                color: themeColors.primary,
                                onTap: () => context
                                    .push(AppRoutes.detailedStats),
                                themeColors: themeColors,
                                delay: 2,
                              ),
                              _buildFeatureCard(
                                title: 'التحديات',
                                subtitle: 'تحديات يومية وأسبوعية',
                                icon: Icons.flag_rounded,
                                color: themeColors.secondary,
                                onTap: () =>
                                    context.push(AppRoutes.challenges),
                                themeColors: themeColors,
                                delay: 3,
                              ),
                            ]),
                          ),
                        ),

                        // Family leaderboard (conditional)
                        if (isInGroup)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: _buildFamilyLeaderboardCard(
                                themeColors,
                                groupInfo.groupId,
                              ),
                            ),
                          ),

                        // Motivation card
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.sm,
                            ),
                            child: _buildMotivationCard(themeColors),
                          ),
                        ),

                        SliverToBoxAdapter(
                          child: SizedBox(
                              height: PersistentBottomNav.totalHeight),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Ambient Orbs ──────────────────────────────────────────

  Widget _buildAmbientOrbs(dynamic themeColors) {
    return AnimatedBuilder(
      animation: _glowIntensity,
      builder: (context, _) => Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    themeColors.levelMax.withValues(
                        alpha: _glowIntensity.value * 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    themeColors.primary.withValues(
                        alpha: _glowIntensity.value * 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Compact Header ────────────────────────────────────────

  Widget _buildCompactHeader(dynamic themeColors) {
    final stats = _userStats ?? {};
    final points = stats['points'] ?? 0;
    final level =
        GamificationConfigService.instance.calculateLevel(points);
    final longestStreak = stats['longest_streak'] ?? 0;
    final totalInteractions = stats['total_interactions'] ?? 0;
    final activeRelativesCount = stats['active_relatives_count'] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: AppSpacing.xs,
      ),
      child: Row(
        children: [
          // Trophy with glow halo
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: themeColors.goldenGradient,
              boxShadow: [
                BoxShadow(
                  color: themeColors.levelMax
                      .withValues(alpha: 0.3),
                  blurRadius: 10,
                ),
                BoxShadow(
                  color: themeColors.levelMax
                      .withValues(alpha: 0.12),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              size: 26,
              color: themeColors.textOnGradient,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Title + level subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الإنجازات',
                  style: AppTypography.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 10,
                      ),
                      Shadow(
                        color: themeColors.levelMax
                            .withValues(alpha: 0.4),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
                Text(
                  'المستوى $level',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Share button
          IconButton(
            icon: Icon(
              Icons.share_rounded,
              color: Colors.white.withValues(alpha: 0.87),
              size: 20,
            ),
            tooltip: 'مشاركة الإحصائيات',
            onPressed: () {
              final isMax = ref.read(isMaxProvider);
              ShareBottomSheet.show(
                context,
                cardBuilder: (format, {String? aiCopy}) =>
                    WrappedShareCard(
                  format: format,
                  personalityEmoji: '\u{1F3C6}',
                  personalityLabel:
                      '\u0645\u0633\u062A\u0648\u0649 $level',
                  periodName:
                      '\u0625\u0646\u062C\u0627\u0632\u0627\u062A\u064A \u0641\u064A \u0635\u0650\u0644\u0646\u064A',
                  totalInteractions: totalInteractions as int,
                  uniqueRelatives: activeRelativesCount as int,
                  longestStreak: longestStreak as int,
                  copyText: aiCopy,
                ),
                shareText:
                    '\u0645\u0633\u062A\u0648\u0649 $level \u2014 $totalInteractions \u062A\u0648\u0627\u0635\u0644 \u0645\u0639 \u0627\u0644\u0639\u0627\u0626\u0644\u0629 \u{1F3C6} #\u0635\u0650\u0644\u0646\u064A',
                aiCopyFuture: isMax
                    ? DeepSeekAIService().generateShareCopy(
                        cardType: 'gaming_stats',
                        context: {
                          'level': level,
                          'totalInteractions': totalInteractions,
                          'longestStreak': longestStreak,
                        },
                      )
                    : null,
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  // ─── Stats + XP Merged Card ────────────────────────────────

  Widget _buildStatsCard(dynamic themeColors) {
    final stats = _userStats ?? {};
    final points = stats['points'] ?? 0;
    final currentStreak = stats['current_streak'] ?? 0;
    final badgesCount = (stats['badges'] as List?)?.length ?? 0;

    final config = GamificationConfigService.instance;
    final level = config.calculateLevel(points);
    final currentLevelXP = config.getXpForLevel(level);
    final nextLevelXP = _getNextLevelXP(level);
    final xpInCurrentLevel = points - currentLevelXP;
    final xpNeededForNextLevel = nextLevelXP - currentLevelXP;
    final progress = xpNeededForNextLevel > 0
        ? (xpInCurrentLevel / xpNeededForNextLevel).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeColors.levelMax.withValues(alpha: 0.15),
            Colors.black.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: themeColors.levelMax.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: themeColors.levelMax.withValues(alpha: 0.2),
            blurRadius: 12,
          ),
          BoxShadow(
            color: themeColors.levelMax.withValues(alpha: 0.1),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Flexible(
                child: _buildStatColumn(
                  icon: Icons.star_rounded,
                  value: points.toString(),
                  label: 'النقاط',
                  color: themeColors.levelMax,
                ),
              ),
              Container(
                width: 1,
                height: 44,
                color: Colors.white.withValues(alpha: 0.15),
              ),
              Flexible(
                child: _buildStatColumn(
                  icon: Icons.local_fire_department_rounded,
                  value: currentStreak.toString(),
                  label: 'السلسلة',
                  color: themeColors.statusError,
                ),
              ),
              Container(
                width: 1,
                height: 44,
                color: Colors.white.withValues(alpha: 0.15),
              ),
              Flexible(
                child: _buildStatColumn(
                  icon: Icons.emoji_events_rounded,
                  value: badgesCount.toString(),
                  label: 'الأوسمة',
                  color: themeColors.accent,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // XP Progress section
          Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                color: themeColors.primary,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'تقدمك للمستوى التالي',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.87),
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Custom progress bar with glow
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FractionallySizedBox(
                  widthFactor: progress,
                  heightFactor: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          themeColors.primaryLight,
                          themeColors.primary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: [
                        BoxShadow(
                          color: themeColors.primary
                              .withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // XP labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$points نقطة',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.87),
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              Text(
                nextLevelXP > points
                    ? 'بقي ${nextLevelXP - points}'
                    : 'أقصى مستوى! 🎉',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.87),
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
            delay: AppAnimations.normal,
            duration: AppAnimations.dramatic)
        .slideY(begin: 0.15, end: 0);
  }

  Widget _buildStatColumn({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.numberLarge.copyWith(
            color: Colors.white,
            fontSize: 22,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 8,
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: Colors.white.withValues(alpha: 0.87),
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 6,
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ─── Feature Grid Cards ────────────────────────────────────

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required dynamic themeColors,
    int delay = 0,
  }) {
    return Semantics(
      label: '$title - $subtitle',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.35),
                color.withValues(alpha: 0.1),
                Colors.black.withValues(alpha: 0.8),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 12,
              ),
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with glow halo
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.5),
                        color.withValues(alpha: 0.2),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 24, color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.7),
                        blurRadius: 10,
                      ),
                      Shadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        )
            .animate(delay: Duration(milliseconds: 200 + delay * 100))
            .fadeIn(duration: AppAnimations.slow)
            .slideX(
              begin: 0.15,
              end: 0,
              duration: AppAnimations.slow,
              curve: AppAnimations.overshootCurve,
            )
            .then()
            .shimmer(
              duration: 1500.ms,
              delay: Duration(milliseconds: 3000 + delay * 500),
              color: color.withValues(alpha: 0.1),
            ),
      ),
    );
  }

  // ─── Family Leaderboard ────────────────────────────────────

  Widget _buildFamilyLeaderboardCard(
      dynamic themeColors, String groupId) {
    final familyStatsAsync =
        ref.watch(familyLeaderboardProvider(groupId));
    final currentUser = ref.watch(currentUserProvider);
    final leaderColor = themeColors.statusInfo as Color;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            leaderColor.withValues(alpha: 0.25),
            Colors.black.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: leaderColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: leaderColor.withValues(alpha: 0.2),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      leaderColor.withValues(alpha: 0.5),
                      leaderColor.withValues(alpha: 0.2),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: leaderColor.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                    BoxShadow(
                      color: leaderColor.withValues(alpha: 0.25),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.family_restroom_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'ترتيب العائلة',
                style: AppTypography.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          familyStatsAsync.when(
            data: (members) {
              if (members.isEmpty) {
                return Text(
                  'لا يوجد أعضاء في العائلة',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.87),
                  ),
                );
              }
              return Column(
                children: [
                  for (var i = 0;
                      i < members.length && i < 5;
                      i++)
                    _buildFamilyMemberRow(
                      members[i],
                      i + 1,
                      members[i].userId == currentUser?.id,
                      themeColors,
                    ),
                ],
              );
            },
            loading: () => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: CircularProgressIndicator(
                  color: themeColors.primary,
                  strokeWidth: 2,
                ),
              ),
            ),
            error: (_, _) => Text(
              'فشل في تحميل ترتيب العائلة',
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.87),
              ),
            ),
          ),
        ],
      ),
    )
        .animate(delay: AppAnimations.slow)
        .fadeIn(duration: AppAnimations.dramatic)
        .slideY(begin: 0.15, end: 0);
  }

  Widget _buildFamilyMemberRow(
    FamilyMemberStats member,
    int rank,
    bool isCurrentUser,
    dynamic themeColors,
  ) {
    final rankColor = rank == 1
        ? themeColors.levelMax as Color
        : rank == 2
            ? Colors.grey[400]!
            : rank == 3
                ? Colors.brown[400]!
                : (themeColors.textSecondary as Color);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: isCurrentUser
          ? BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  themeColors.primary.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: themeColors.primary.withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      themeColors.primary.withValues(alpha: 0.15),
                  blurRadius: 8,
                ),
              ],
            )
          : null,
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rankColor,
              shape: BoxShape.circle,
              boxShadow: rank <= 3
                  ? [
                      BoxShadow(
                        color: rankColor.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: rank <= 3
                  ? const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.white,
                      size: 16,
                    )
                  : Text(
                      '$rank',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.displayName,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: isCurrentUser
                        ? FontWeight.bold
                        : FontWeight.w500,
                    shadows: [
                      Shadow(
                        color:
                            Colors.black.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isCurrentUser)
                  Text(
                    'أنت',
                    style: AppTypography.bodySmall.copyWith(
                      color: themeColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),

          // Stats chips
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatChip(
                icon: Icons.star_rounded,
                value: '${member.points}',
                color: themeColors.levelMax,
              ),
              const SizedBox(width: AppSpacing.xs),
              _buildStatChip(
                icon: Icons.local_fire_department_rounded,
                value: '${member.currentStreak}',
                color: themeColors.statusError,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Motivation Card ───────────────────────────────────────

  Widget _buildMotivationCard(dynamic themeColors) {
    final motivations = [
      'استمر في صلة الرحم! 💪',
      'كل تواصل يقربك من الله ❤️',
      'عائلتك تفتخر بك! 🌟',
      'لا تتوقف عن التواصل! 🔥',
    ];

    final randomMotivation =
        motivations[DateTime.now().second % motivations.length];
    final heartColor = themeColors.statusError as Color;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (themeColors.secondary as Color)
                .withValues(alpha: 0.3),
            Colors.black.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: heartColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: heartColor.withValues(alpha: 0.15),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: heartColor.withValues(alpha: 0.2),
              boxShadow: [
                BoxShadow(
                  color: heartColor.withValues(alpha: 0.4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(
              Icons.favorite_rounded,
              color: heartColor,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              randomMotivation,
              style: AppTypography.titleSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate(delay: AppAnimations.slow)
        .fadeIn(duration: AppAnimations.dramatic)
        .slideY(begin: 0.15, end: 0)
        .then()
        .shimmer(
          duration: AppAnimations.loop,
          delay: AppAnimations.loop,
          color: heartColor.withValues(alpha: 0.08),
        );
  }

  // ─── Helpers ───────────────────────────────────────────────

  int _getNextLevelXP(int level) {
    final config = GamificationConfigService.instance;
    final nextLevelXp = config.getXpForLevel(level + 1);
    if (nextLevelXp == 0 && level >= config.maxLevel) {
      return config.getXpForLevel(config.maxLevel) + 5000;
    }
    return nextLevelXp > 0 ? nextLevelXp : 15000;
  }
}
