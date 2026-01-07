import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/services/gamification_config_service.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/premium_loading_indicator.dart';
import 'badges_screen.dart';
import '../../../shared/widgets/message_widget.dart';

/// Gaming Center - Main gamification hub with exciting design
class GamingCenterScreen extends ConsumerStatefulWidget {
  const GamingCenterScreen({super.key});

  @override
  ConsumerState<GamingCenterScreen> createState() => _GamingCenterScreenState();
}

class _GamingCenterScreenState extends ConsumerState<GamingCenterScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  Map<String, dynamic>? _userStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _loadUserStats();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadUserStats() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      // Force refresh gamification config to ensure we have latest levels
      await GamificationConfigService.instance.refresh();

      final response = await SupabaseConfig.client
          .from('users')
          .select(
            'points, level, current_streak, longest_streak, badges, total_interactions',
          )
          .eq('id', user.id)
          .single();

      // Check if level needs to be synced with points
      final points = response['points'] as int? ?? 0;
      final dbLevel = response['level'] as int? ?? 1;

      debugPrint('[GamingCenterScreen] User points: $points, DB level: $dbLevel');
      debugPrint('[GamingCenterScreen] Levels loaded: ${GamificationConfigService.instance.levels.length}');
      // Show levels in ascending order for clarity
      final levelsStr = GamificationConfigService.instance.levels
          .map((l) => 'L${l.level}=${l.xpRequired}')
          .join(', ');
      debugPrint('[GamingCenterScreen] Level thresholds (ascending): $levelsStr');

      final calculatedLevel = GamificationConfigService.instance.calculateLevel(points);

      if (calculatedLevel != dbLevel) {
        // Level is out of sync - update the database
        debugPrint('[GamingCenterScreen] Level out of sync: DB=$dbLevel, calculated=$calculatedLevel. Syncing...');
        await SupabaseConfig.client.from('users').update({
          'level': calculatedLevel,
        }).eq('id', user.id);
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Semantics(
        label: 'مركز الإنجازات والألعاب',
        child: Stack(
          children: [
            // Confetti for celebrations
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.05,
                numberOfParticles: 30,
                gravity: 0.1,
                colors: [
                  AppColors.premiumGold,
                  themeColors.primary,
                  AppColors.energeticRed,
                  AppColors.joyfulOrange,
                  AppColors.emotionalPurple,
                ],
              ),
            ),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Content
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: PremiumLoadingIndicator(
                              message: 'جاري تحميل مركز الألعاب...',
                            ),
                          )
                        : CustomScrollView(
                            slivers: [
                              // Hero Header
                              SliverToBoxAdapter(child: _buildHeroHeader(themeColors)),

                              // In-App Messages
                              const SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                                  child: MessageWidget(screenPath: '/gaming-center'),
                                ),
                              ),

                              // Main Stats Display
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  child: _buildMainStatsDisplay(themeColors),
                                ),
                              ),

                              // Gaming Features Grid
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                ),
                                sliver: SliverGrid(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: 0.85,
                                        crossAxisSpacing: AppSpacing.md,
                                        mainAxisSpacing: AppSpacing.md,
                                      ),
                                  delegate: SliverChildListDelegate([
                                    _buildFeatureCard(
                                      title: 'الأوسمة',
                                      subtitle:
                                          '${(_userStats?['badges'] as List?)?.length ?? 0}/${BadgeData.allBadges.length}',
                                      icon: Icons.emoji_events_rounded,
                                      gradient: AppColors.goldenGradient,
                                      onTap: () => context.push(AppRoutes.badges),
                                      themeColors: themeColors,
                                    ),
                                    _buildFeatureCard(
                                      title: 'المتصدرين',
                                      subtitle: 'تنافس مع الجميع',
                                      icon: Icons.leaderboard_rounded,
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFF6B35),
                                          Color(0xFFFF9E00),
                                        ],
                                      ),
                                      onTap: () =>
                                          context.push(AppRoutes.leaderboard),
                                      themeColors: themeColors,
                                    ),
                                    _buildFeatureCard(
                                      title: 'الإحصائيات',
                                      subtitle: 'تفاصيل تقدمك',
                                      icon: Icons.analytics_rounded,
                                      gradient: themeColors.primaryGradient,
                                      onTap: () =>
                                          context.push(AppRoutes.detailedStats),
                                      themeColors: themeColors,
                                    ),
                                    _buildFeatureCard(
                                      title: 'التحديات',
                                      subtitle: 'تحديات يومية وأسبوعية',
                                      icon: Icons.flag_rounded,
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.emotionalPurple,
                                          AppColors.emotionalPurple.withValues(
                                            alpha: 0.7,
                                          ),
                                        ],
                                      ),
                                      onTap: () =>
                                          context.push(AppRoutes.challenges),
                                      themeColors: themeColors,
                                    ),
                                  ]),
                                ),
                              ),

                              // Progress Section
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  child: _buildProgressSection(themeColors),
                                ),
                              ),

                              // Daily Motivation
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  child: _buildMotivationCard(themeColors),
                                ),
                              ),

                              const SliverToBoxAdapter(
                                child: SizedBox(height: 100),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(dynamic themeColors) {
    final stats = _userStats ?? {};
    final points = stats['points'] ?? 0;
    // Recalculate correct level from points (in case DB is out of sync)
    final level = GamificationConfigService.instance.calculateLevel(points);

    return Container(
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: AppSpacing.md,
      ),
      child: Column(
        children: [
          // Animated Trophy Icon
          Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.goldenGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.premiumGold.withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  size: 50,
                  color: themeColors.textOnGradient,
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.1, 1.1),
                duration: AppAnimations.loop,
              )
              .shimmer(duration: AppAnimations.loop, color: themeColors.textOnGradient.withValues(alpha: 0.5)),

          const SizedBox(height: AppSpacing.lg),

          // Title
          ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.goldenGradient.createShader(bounds),
                child: Text(
                  'الإنجازات',
                  style: AppTypography.hero.copyWith(
                    color: themeColors.textOnGradient,
                    fontSize: 32,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
              .animate()
              .fadeIn(duration: AppAnimations.dramatic)
              .slideY(begin: -0.3, end: 0, duration: AppAnimations.dramatic),

          const SizedBox(height: AppSpacing.sm),

          // Level Badge
          Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  gradient: themeColors.primaryGradient,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: themeColors.primary.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      color: themeColors.textOnGradient,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'المستوى $level',
                      style: AppTypography.titleMedium.copyWith(
                        color: themeColors.textOnGradient,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(delay: AppAnimations.normal, duration: AppAnimations.dramatic)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
              ),
        ],
      ),
    );
  }

  Widget _buildMainStatsDisplay(dynamic themeColors) {
    final stats = _userStats ?? {};
    final points = stats['points'] ?? 0;
    final currentStreak = stats['current_streak'] ?? 0;
    final badgesCount = (stats['badges'] as List?)?.length ?? 0;

    return GlassCard(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.premiumGold.withValues(alpha: 0.2),
                  AppColors.premiumGoldDark.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                  child: _buildStatColumn(
                    icon: Icons.star_rounded,
                    value: points.toString(),
                    label: 'النقاط',
                    color: AppColors.premiumGold,
                    themeColors: themeColors,
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: themeColors.textOnGradient.withValues(alpha: 0.3),
                ),
                Flexible(
                  child: _buildStatColumn(
                    icon: Icons.local_fire_department_rounded,
                    value: currentStreak.toString(),
                    label: 'السلسلة',
                    color: AppColors.energeticRed,
                    themeColors: themeColors,
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: themeColors.textOnGradient.withValues(alpha: 0.3),
                ),
                Flexible(
                  child: _buildStatColumn(
                    icon: Icons.emoji_events_rounded,
                    value: badgesCount.toString(),
                    label: 'الأوسمة',
                    color: AppColors.joyfulOrange,
                    themeColors: themeColors,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: AppAnimations.dramatic, duration: AppAnimations.dramatic)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildStatColumn({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required dynamic themeColors,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.numberLarge.copyWith(
            color: themeColors.textOnGradient,
            fontSize: 24,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: themeColors.textOnGradient.withValues(alpha: 0.7),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
    required dynamic themeColors,
    bool comingSoon = false,
  }) {
    return Semantics(
      label: '$title - $subtitle',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child:
            GlassCard(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: gradient.scale(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.xs),
                                decoration: BoxDecoration(
                                  color: themeColors.textOnGradient.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, size: 28, color: themeColors.textOnGradient),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                title,
                                style: AppTypography.titleMedium.copyWith(
                                  color: themeColors.textOnGradient,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySmall.copyWith(
                                  color: themeColors.textOnGradient.withValues(alpha: 0.7),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Coming Soon Badge
                        if (comingSoon)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.joyfulOrange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'قريباً',
                                style: AppTypography.bodySmall.copyWith(
                                  color: themeColors.textOnGradient,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                )
                .animate()
                .fadeIn(delay: AppAnimations.celebration, duration: AppAnimations.dramatic)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0))
                .then()
                .shimmer(duration: AppAnimations.loop, delay: AppAnimations.celebration),
      ),
    );
  }

  Widget _buildProgressSection(dynamic themeColors) {
    final stats = _userStats ?? {};
    final points = stats['points'] ?? 0;
    // Recalculate correct level from points (in case DB is out of sync)
    final config = GamificationConfigService.instance;
    final calculatedLevel = config.calculateLevel(points);
    final currentLevelXP = config.getXpForLevel(calculatedLevel);
    final nextLevelXP = _getNextLevelXP(calculatedLevel);
    // Calculate progress within current level
    final xpInCurrentLevel = points - currentLevelXP;
    final xpNeededForNextLevel = nextLevelXP - currentLevelXP;
    final progress = xpNeededForNextLevel > 0
        ? xpInCurrentLevel / xpNeededForNextLevel
        : 1.0;

    return GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      color: themeColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'تقدمك للمستوى التالي',
                      style: AppTypography.titleMedium.copyWith(
                        color: themeColors.textOnGradient,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 20,
                    backgroundColor: themeColors.textOnGradient.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      themeColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$points نقطة',
                      style: AppTypography.bodyMedium.copyWith(
                        color: themeColors.textOnGradient.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      nextLevelXP > points
                          ? 'بقي ${nextLevelXP - points}'
                          : 'مستوى ${calculatedLevel + 1}! 🎉',
                      style: AppTypography.bodyMedium.copyWith(
                        color: themeColors.textOnGradient.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: AppAnimations.celebration, duration: AppAnimations.dramatic)
        .slideX(begin: -0.2, end: 0);
  }

  Widget _buildMotivationCard(dynamic themeColors) {
    final motivations = [
      'استمر في صلة الرحم! 💪',
      'كل تواصل يقربك من الله ❤️',
      'عائلتك تفتخر بك! 🌟',
      'لا تتوقف عن التواصل! 🔥',
    ];

    final randomMotivation =
        motivations[DateTime.now().second % motivations.length];

    return GlassCard(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.emotionalPurple.withValues(alpha: 0.3),
                  AppColors.calmBlue.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.energeticRed,
                  size: 40,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    randomMotivation,
                    style: AppTypography.titleMedium.copyWith(
                      color: themeColors.textOnGradient,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: AppAnimations.celebration, duration: AppAnimations.dramatic)
        .slideY(begin: 0.2, end: 0)
        .then()
        .shimmer(duration: AppAnimations.loop, delay: AppAnimations.loop);
  }

  /// Get XP required for next level using dynamic admin config
  int _getNextLevelXP(int level) {
    final config = GamificationConfigService.instance;
    // Get XP required for the NEXT level (level + 1)
    final nextLevelXp = config.getXpForLevel(level + 1);
    // If we're at or past max level, return a high value
    if (nextLevelXp == 0 && level >= config.maxLevel) {
      return config.getXpForLevel(config.maxLevel) + 5000;
    }
    return nextLevelXp > 0 ? nextLevelXp : 15000; // Fallback
  }
}

extension GradientExtension on Gradient {
  Gradient scale(double opacity) {
    if (this is LinearGradient) {
      final gradient = this as LinearGradient;
      return LinearGradient(
        colors: gradient.colors.map((c) => c.withValues(alpha: opacity)).toList(),
        begin: gradient.begin,
        end: gradient.end,
      );
    }
    return this;
  }
}
