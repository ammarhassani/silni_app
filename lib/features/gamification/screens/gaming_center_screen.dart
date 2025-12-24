import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/premium_loading_indicator.dart';

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
      final response = await SupabaseConfig.client
          .from('users')
          .select(
            'points, level, current_streak, longest_streak, badges, total_interactions',
          )
          .eq('id', user.id)
          .single();

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
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
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
              colors: const [
                AppColors.premiumGold,
                AppColors.islamicGreenPrimary,
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
                            SliverToBoxAdapter(child: _buildHeroHeader()),

                            // Main Stats Display
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: _buildMainStatsDisplay(),
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
                                        '${(_userStats?['badges'] as List?)?.length ?? 0}/19',
                                    icon: Icons.emoji_events_rounded,
                                    gradient: AppColors.goldenGradient,
                                    onTap: () => context.push(AppRoutes.badges),
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
                                  ),
                                  _buildFeatureCard(
                                    title: 'الإحصائيات',
                                    subtitle: 'تفاصيل تقدمك',
                                    icon: Icons.analytics_rounded,
                                    gradient: AppColors.primaryGradient,
                                    onTap: () =>
                                        context.push(AppRoutes.detailedStats),
                                  ),
                                  _buildFeatureCard(
                                    title: 'التحديات',
                                    subtitle: 'قريباً',
                                    icon: Icons.flag_rounded,
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.emotionalPurple,
                                        AppColors.emotionalPurple.withValues(
                                          alpha: 0.7,
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('قريباً!'),
                                        ),
                                      );
                                    },
                                    comingSoon: true,
                                  ),
                                ]),
                              ),
                            ),

                            // Progress Section
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: _buildProgressSection(),
                              ),
                            ),

                            // Daily Motivation
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: _buildMotivationCard(),
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
    );
  }

  Widget _buildHeroHeader() {
    final stats = _userStats ?? {};
    final level = stats['level'] ?? 1;

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
                child: const Icon(
                  Icons.emoji_events_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.1, 1.1),
                duration: 2000.ms,
              )
              .shimmer(duration: 2000.ms, color: Colors.white.withValues(alpha: 0.5)),

          const SizedBox(height: AppSpacing.lg),

          // Title
          ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.goldenGradient.createShader(bounds),
                child: Text(
                  'الإنجازات',
                  style: AppTypography.hero.copyWith(
                    color: Colors.white,
                    fontSize: 32,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
              .animate()
              .fadeIn(duration: 600.ms)
              .slideY(begin: -0.3, end: 0, duration: 600.ms),

          const SizedBox(height: AppSpacing.sm),

          // Level Badge
          Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.islamicGreenPrimary.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'المستوى $level',
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(delay: 300.ms, duration: 600.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
              ),
        ],
      ),
    );
  }

  Widget _buildMainStatsDisplay() {
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
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                Flexible(
                  child: _buildStatColumn(
                    icon: Icons.local_fire_department_rounded,
                    value: currentStreak.toString(),
                    label: 'السلسلة',
                    color: AppColors.energeticRed,
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                Flexible(
                  child: _buildStatColumn(
                    icon: Icons.emoji_events_rounded,
                    value: badgesCount.toString(),
                    label: 'الأوسمة',
                    color: AppColors.joyfulOrange,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 600.ms, duration: 600.ms)
        .slideY(begin: 0.2, end: 0);
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
        Icon(icon, color: color, size: 28),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.numberLarge.copyWith(
            color: Colors.white,
            fontSize: 24,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(color: Colors.white70),
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
    bool comingSoon = false,
  }) {
    return GestureDetector(
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
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, size: 28, color: Colors.white),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              title,
                              style: AppTypography.titleMedium.copyWith(
                                color: Colors.white,
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
                                color: Colors.white70,
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
                                color: Colors.white,
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
              .fadeIn(delay: 900.ms, duration: 600.ms)
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0))
              .then()
              .shimmer(duration: 2000.ms, delay: 1500.ms),
    );
  }

  Widget _buildProgressSection() {
    final stats = _userStats ?? {};
    final points = stats['points'] ?? 0;
    final level = stats['level'] ?? 1;
    final nextLevelXP = _getNextLevelXP(level);
    final progress = points / nextLevelXP;

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
                      color: AppColors.islamicGreenPrimary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'تقدمك للمستوى التالي',
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
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
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.islamicGreenPrimary,
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
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      'بقي ${nextLevelXP - points}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 1200.ms, duration: 600.ms)
        .slideX(begin: -0.2, end: 0);
  }

  Widget _buildMotivationCard() {
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
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 1500.ms, duration: 600.ms)
        .slideY(begin: 0.2, end: 0)
        .then()
        .shimmer(duration: 2000.ms, delay: 2000.ms);
  }

  int _getNextLevelXP(int level) {
    const xpPerLevel = [
      0,
      100,
      250,
      500,
      1000,
      2000,
      3500,
      5500,
      8000,
      11000,
      15000,
    ];
    if (level < xpPerLevel.length) {
      return xpPerLevel[level];
    }
    return xpPerLevel.last + (level - xpPerLevel.length + 1) * 5000;
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
