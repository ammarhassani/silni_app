import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/services/gamification_config_service.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/premium_loading_indicator.dart';
import '../../../shared/widgets/message_widget.dart';

/// Screen displaying all badges and their unlock criteria
class BadgesScreen extends ConsumerStatefulWidget {
  const BadgesScreen({super.key});

  @override
  ConsumerState<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends ConsumerState<BadgesScreen> {
  List<String> _unlockedBadges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserBadges();
  }

  Future<void> _loadUserBadges() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final response = await SupabaseConfig.client
          .from('users')
          .select('badges')
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _unlockedBadges = response['badges'] != null
              ? List<String>.from(response['badges'] as List)
              : [];
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
      body: Stack(
        children: [
          const GradientBackground(animated: true, child: SizedBox.expand()),
          SafeArea(
            child: Semantics(
              label: 'شاشة الأوسمة والإنجازات',
              child: Column(
              children: [
                // Header
                Padding(
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
                          icon: Icon(Icons.arrow_back_ios_rounded, color: themeColors.textOnGradient),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'الأوسمة والإنجازات',
                        style: AppTypography.headlineMedium.copyWith(
                          color: themeColors.textOnGradient,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // In-App Messages
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: MessageWidget(screenPath: '/badges'),
                ),

                // Stats summary
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            icon: Icons.emoji_events_rounded,
                            value: _unlockedBadges.length.toString(),
                            label: 'مفتوحة',
                            color: AppColors.premiumGold,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          _buildStatItem(
                            icon: Icons.lock_outline_rounded,
                            value: (BadgeData.allBadges.length - _unlockedBadges.length)
                                .toString(),
                            label: 'مقفلة',
                            color: Colors.white70,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          _buildStatItem(
                            icon: Icons.percent_rounded,
                            value: _unlockedBadges.isEmpty
                                ? '0%'
                                : '${(_unlockedBadges.length / BadgeData.allBadges.length * 100).toStringAsFixed(0)}%',
                            label: 'الإكمال',
                            color: AppColors.islamicGreenLight,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Badge categories
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: PremiumLoadingIndicator(
                            message: 'جاري تحميل الأوسمة...',
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          children: [
                            _buildBadgeCategory(
                              'أوسمة الإنجاز',
                              BadgeData.achievementBadges,
                              themeColors,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _buildBadgeCategory(
                              'أوسمة السلسلة',
                              BadgeData.streakBadges,
                              themeColors,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _buildBadgeCategory(
                              'أوسمة خاصة',
                              BadgeData.specialBadges,
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

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: Colors.white70,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildBadgeCategory(
    String title,
    List<BadgeInfo> badges,
    dynamic themeColors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md, right: AppSpacing.xs),
          child: Text(
            title,
            style: AppTypography.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemCount: badges.length,
          itemBuilder: (context, index) {
            final badge = badges[index];
            final isUnlocked = _unlockedBadges.contains(badge.id);
            return _buildBadgeCard(badge, isUnlocked);
          },
        ),
      ],
    );
  }

  Widget _buildBadgeCard(BadgeInfo badge, bool isUnlocked) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Badge icon
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked
                    ? badge.color.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.1),
                border: Border.all(
                  color: isUnlocked ? badge.color : Colors.white30,
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  badge.emoji,
                  style: TextStyle(
                    fontSize: 35,
                    color: isUnlocked ? null : Colors.white30,
                  ),
                ),
              ),
            )
                .animate(
                  target: isUnlocked ? 1 : 0,
                )
                .shimmer(
                  duration: 2000.ms,
                  color: badge.color.withValues(alpha: 0.5),
                ),

            const SizedBox(height: AppSpacing.xs),

            // Badge name
            Text(
              badge.name,
              textAlign: TextAlign.center,
              style: AppTypography.titleSmall.copyWith(
                color: isUnlocked ? Colors.white : Colors.white60,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // Badge description
            Text(
              badge.description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: isUnlocked ? Colors.white70 : Colors.white.withValues(alpha: 0.4),
                height: 1.2,
              ),
            ),

            const SizedBox(height: AppSpacing.xs),

            // Lock icon or checkmark
            Icon(
              isUnlocked ? Icons.check_circle : Icons.lock_outline,
              color: isUnlocked ? AppColors.premiumGold : Colors.white30,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge information model
class BadgeInfo {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final Color color;

  const BadgeInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.color,
  });
}

/// Badge data provider - uses dynamic config from admin panel
class BadgeData {
  /// Convert BadgeConfig to BadgeInfo for UI display
  static BadgeInfo _configToInfo(BadgeConfig config) {
    return BadgeInfo(
      id: config.badgeKey,
      name: config.displayNameAr,
      description: config.descriptionAr,
      emoji: config.emoji,
      color: _getCategoryColor(config.category),
    );
  }

  /// Get color based on badge category
  static Color _getCategoryColor(String category) {
    switch (category) {
      case 'streak':
        return AppColors.energeticRed;
      case 'volume':
        return AppColors.islamicGreenPrimary;
      case 'special':
        return AppColors.emotionalPurple;
      case 'milestone':
        return AppColors.premiumGold;
      default:
        return AppColors.calmBlue;
    }
  }

  /// Achievement badges (volume-based) - dynamic from admin config
  static List<BadgeInfo> get achievementBadges {
    final config = GamificationConfigService.instance;
    final volumeBadges = config.volumeBadges;

    // Add first_interaction badge if exists
    final firstInteraction = config.getBadge('first_interaction');
    final result = <BadgeInfo>[];

    if (firstInteraction != null) {
      result.add(_configToInfo(firstInteraction));
    }

    result.addAll(volumeBadges.map(_configToInfo));

    return result.isNotEmpty ? result : _fallbackAchievementBadges;
  }

  /// Streak badges - dynamic from admin config
  static List<BadgeInfo> get streakBadges {
    final config = GamificationConfigService.instance;
    final badges = config.streakBadges.map(_configToInfo).toList();
    return badges.isNotEmpty ? badges : _fallbackStreakBadges;
  }

  /// Special badges - dynamic from admin config
  static List<BadgeInfo> get specialBadges {
    final config = GamificationConfigService.instance;
    final badges = config.specialBadges.map(_configToInfo).toList();
    return badges.isNotEmpty ? badges : _fallbackSpecialBadges;
  }

  static List<BadgeInfo> get allBadges => [
        ...achievementBadges,
        ...streakBadges,
        ...specialBadges,
      ];

  // ============ Fallback badges (used when config not loaded) ============

  static const List<BadgeInfo> _fallbackAchievementBadges = [
    BadgeInfo(
      id: 'first_interaction',
      name: 'أول تفاعل',
      description: 'سجلت أول تفاعل لك',
      emoji: '🎯',
      color: AppColors.islamicGreenPrimary,
    ),
    BadgeInfo(
      id: 'interactions_10',
      name: '10 تفاعلات',
      description: 'أكملت 10 تفاعلات',
      emoji: '✨',
      color: AppColors.islamicGreenPrimary,
    ),
    BadgeInfo(
      id: 'interactions_50',
      name: '50 تفاعل',
      description: 'أكملت 50 تفاعل',
      emoji: '🌟',
      color: AppColors.islamicGreenPrimary,
    ),
    BadgeInfo(
      id: 'interactions_100',
      name: '100 تفاعل',
      description: 'أكملت 100 تفاعل',
      emoji: '💫',
      color: AppColors.islamicGreenPrimary,
    ),
    BadgeInfo(
      id: 'interactions_500',
      name: '500 تفاعل',
      description: 'أكملت 500 تفاعل',
      emoji: '🏆',
      color: AppColors.premiumGold,
    ),
    BadgeInfo(
      id: 'interactions_1000',
      name: '1000 تفاعل',
      description: 'أكملت 1000 تفاعل',
      emoji: '🎖️',
      color: AppColors.premiumGold,
    ),
  ];

  static const List<BadgeInfo> _fallbackStreakBadges = [
    BadgeInfo(
      id: 'streak_7',
      name: 'أسبوع متواصل',
      description: 'تفاعلت لمدة 7 أيام متتالية',
      emoji: '🔥',
      color: AppColors.energeticRed,
    ),
    BadgeInfo(
      id: 'streak_30',
      name: 'شهر متواصل',
      description: 'تفاعلت لمدة 30 يوم متتالي',
      emoji: '⚡',
      color: AppColors.energeticRed,
    ),
    BadgeInfo(
      id: 'streak_100',
      name: '100 يوم',
      description: 'تفاعلت لمدة 100 يوم متتالي',
      emoji: '💯',
      color: AppColors.energeticRed,
    ),
    BadgeInfo(
      id: 'streak_365',
      name: 'سنة متواصلة',
      description: 'تفاعلت لمدة سنة كاملة',
      emoji: '👑',
      color: AppColors.premiumGold,
    ),
  ];

  static const List<BadgeInfo> _fallbackSpecialBadges = [
    BadgeInfo(
      id: 'all_interaction_types',
      name: 'متنوع',
      description: 'استخدمت جميع أنواع التفاعل',
      emoji: '🎨',
      color: AppColors.emotionalPurple,
    ),
    BadgeInfo(
      id: 'social_butterfly',
      name: 'اجتماعي',
      description: 'تفاعلت مع 10 أقارب مختلفين',
      emoji: '🦋',
      color: AppColors.calmBlue,
    ),
    BadgeInfo(
      id: 'generous_giver',
      name: 'كريم',
      description: 'قدمت 10+ هدايا',
      emoji: '🎁',
      color: AppColors.joyfulOrange,
    ),
    BadgeInfo(
      id: 'family_gatherer',
      name: 'جامع العائلة',
      description: 'نظمت 10+ مناسبات عائلية',
      emoji: '👨‍👩‍👧‍👦',
      color: AppColors.islamicGreenPrimary,
    ),
    BadgeInfo(
      id: 'frequent_caller',
      name: 'كثير الاتصال',
      description: 'أجريت 50+ مكالمة',
      emoji: '📞',
      color: AppColors.calmBlue,
    ),
    BadgeInfo(
      id: 'devoted_visitor',
      name: 'زائر مخلص',
      description: 'قمت بـ 25+ زيارة',
      emoji: '🏠',
      color: AppColors.islamicGreenPrimary,
    ),
  ];
}
