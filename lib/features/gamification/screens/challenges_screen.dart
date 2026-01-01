import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/services/gamification_config_service.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/premium_loading_indicator.dart';

/// Screen displaying daily, weekly, and monthly challenges
class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<ChallengeConfig> _dailyChallenges = [];
  List<ChallengeConfig> _weeklyChallenges = [];
  List<ChallengeConfig> _monthlyChallenges = [];
  List<ChallengeConfig> _specialChallenges = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadChallenges();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChallenges() async {
    try {
      await GamificationConfigService.instance.refresh();
      final config = GamificationConfigService.instance;

      if (mounted) {
        setState(() {
          _dailyChallenges = config.dailyChallenges;
          _weeklyChallenges = config.weeklyChallenges;
          _monthlyChallenges = config.monthlyChallenges;
          _specialChallenges = config.specialChallenges;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[ChallengesScreen] Error loading challenges: $e');
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
      body: Stack(
        children: [
          const GradientBackground(animated: true, child: SizedBox.expand()),
          SafeArea(
            child: Semantics(
              label: 'شاشة التحديات',
              child: Column(
                children: [
                  // Header
                  _buildHeader(themeColors),

                  // Tab Bar
                  _buildTabBar(themeColors),

                  // Content
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: PremiumLoadingIndicator(
                              message: 'جاري تحميل التحديات...',
                            ),
                          )
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildChallengesList(
                                _dailyChallenges,
                                'يومية',
                                themeColors,
                              ),
                              _buildChallengesList(
                                _weeklyChallenges,
                                'أسبوعية',
                                themeColors,
                              ),
                              _buildChallengesList(
                                _monthlyChallenges,
                                'شهرية',
                                themeColors,
                              ),
                              _buildChallengesList(
                                _specialChallenges,
                                'خاصة',
                                themeColors,
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(dynamic themeColors) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Semantics(
            label: 'رجوع',
            button: true,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: themeColors.textOnGradient,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            Icons.flag_rounded,
            color: AppColors.premiumGold,
            size: 28,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'التحديات',
            style: AppTypography.headlineMedium.copyWith(
              color: themeColors.textOnGradient,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(dynamic themeColors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: themeColors.textOnGradient.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: themeColors.textOnGradient,
        unselectedLabelColor: themeColors.textOnGradient.withValues(alpha: 0.5),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: themeColors.primary.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        labelStyle: AppTypography.labelLarge.copyWith(
          fontWeight: FontWeight.bold,
        ),
        tabs: const [
          Tab(text: 'يومية'),
          Tab(text: 'أسبوعية'),
          Tab(text: 'شهرية'),
          Tab(text: 'خاصة'),
        ],
      ),
    );
  }

  Widget _buildChallengesList(
    List<ChallengeConfig> challenges,
    String type,
    dynamic themeColors,
  ) {
    if (challenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 64,
              color: themeColors.textOnGradient.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'لا توجد تحديات $type حالياً',
              style: AppTypography.titleMedium.copyWith(
                color: themeColors.textOnGradient.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        return _buildChallengeCard(challenge, index, themeColors);
      },
    );
  }

  Widget _buildChallengeCard(
    ChallengeConfig challenge,
    int index,
    dynamic themeColors,
  ) {
    final color = _parseColor(challenge.colorHex);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.3),
                color.withValues(alpha: 0.1),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconForChallenge(challenge.icon),
                  color: themeColors.textOnGradient,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.titleAr,
                      style: AppTypography.titleMedium.copyWith(
                        color: themeColors.textOnGradient,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      challenge.descriptionAr,
                      style: AppTypography.bodySmall.copyWith(
                        color: themeColors.textOnGradient.withValues(alpha: 0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Rewards
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        _buildRewardChip(
                          '${challenge.xpReward} XP',
                          AppColors.premiumGold,
                          themeColors,
                        ),
                        if (challenge.pointsReward > 0)
                          _buildRewardChip(
                            '${challenge.pointsReward} نقطة',
                            themeColors.primary,
                            themeColors,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 100 * index),
          duration: const Duration(milliseconds: 400),
        )
        .slideX(begin: 0.2, end: 0);
  }

  Widget _buildRewardChip(String label, Color color, dynamic themeColors) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: themeColors.textOnGradient,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return AppColors.islamicGreenPrimary;
    }
  }

  IconData _getIconForChallenge(String iconName) {
    switch (iconName) {
      case 'target':
        return Icons.flag_rounded;
      case 'check-circle':
        return Icons.check_circle_rounded;
      case 'phone':
        return Icons.phone_rounded;
      case 'shuffle':
        return Icons.shuffle_rounded;
      case 'flame':
        return Icons.local_fire_department_rounded;
      case 'trophy':
        return Icons.emoji_events_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'heart':
        return Icons.favorite_rounded;
      case 'users':
        return Icons.people_rounded;
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'calendar':
        return Icons.event_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'message':
        return Icons.message_rounded;
      default:
        return Icons.flag_rounded;
    }
  }
}
