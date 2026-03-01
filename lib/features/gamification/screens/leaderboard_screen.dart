import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/models/subscription_tier.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/premium_loading_indicator.dart';
import '../../subscription/screens/paywall_screen.dart';

/// Family Activity screen showing collective family connection stats
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  List<Map<String, dynamic>> _memberActivity = [];
  int _totalGroupInteractions = 0;
  int _activeMembersCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFamilyActivity();
  }

  Future<void> _loadFamilyActivity() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Get group members with their recent activity (reuse leaderboard RPC but display differently)
      final response = await SupabaseConfig.client.rpc('get_leaderboard', params: {
        'order_by': 'current_streak',
        'result_limit': 50,
      });

      final data = List<Map<String, dynamic>>.from(response as List);

      // Calculate collective stats
      int totalInteractions = 0;
      int activeMembers = 0;
      for (final member in data) {
        final streak = member['current_streak'] as int? ?? 0;
        totalInteractions += member['total_interactions'] as int? ?? 0;
        if (streak > 0) activeMembers++;
      }

      if (mounted) {
        setState(() {
          _memberActivity = data;
          _totalGroupInteractions = totalInteractions;
          _activeMembersCount = activeMembers;
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
    final hasAccess = ref.watch(featureAccessProvider(FeatureIds.leaderboard));

    return Scaffold(
      body: Semantics(
        label: 'نشاط العائلة',
        child: Stack(
          children: [
            const GradientBackground(animated: true, child: SizedBox.expand()),
            SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Semantics(
                          label: 'رجوع',
                          button: true,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_ios_rounded),
                            color: themeColors.textOnGradient,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'نشاط العائلة',
                          style: AppTypography.headlineMedium.copyWith(
                            color: themeColors.textOnGradient,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (!hasAccess)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [themeColors.primary, themeColors.primaryLight],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock, size: 14, color: themeColors.textOnGradient),
                                const SizedBox(width: 4),
                                Text(
                                  'PRO',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: themeColors.textOnGradient,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (hasAccess)
                          Semantics(
                            label: 'تحديث',
                            button: true,
                            child: IconButton(
                              onPressed: _loadFamilyActivity,
                              icon: const Icon(Icons.refresh_rounded),
                              color: themeColors.textOnGradient,
                            ),
                          ),
                      ],
                    ),
                  ),

                  if (!hasAccess)
                    Expanded(child: _buildUpgradePrompt(themeColors))
                  else
                    Expanded(
                      child: _isLoading
                          ? const Center(
                              child: PremiumLoadingIndicator(
                                message: 'جاري تحميل نشاط العائلة...',
                              ),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                              child: Column(
                                children: [
                                  // Collective stats card
                                  _buildCollectiveStatsCard(themeColors),
                                  const SizedBox(height: AppSpacing.md),
                                  // Member activity list (no ranking)
                                  _buildMemberActivityList(themeColors),
                                  const SizedBox(height: AppSpacing.xxl),
                                ],
                              ),
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

  Widget _buildCollectiveStatsCard(dynamic themeColors) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const Text(
            '\u{1f90d}',
            style: TextStyle(fontSize: 40),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '\u0639\u0627\u0626\u0644\u062a\u0643\u0645 \u062a\u0648\u0627\u0635\u0644\u062a $_totalGroupInteractions \u0645\u0631\u0629',
            style: AppTypography.titleLarge.copyWith(
              color: themeColors.textOnGradient,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$_activeMembersCount \u0623\u0639\u0636\u0627\u0621 \u064a\u062a\u0648\u0627\u0635\u0644\u0648\u0646 \u062d\u0627\u0644\u064a\u064b\u0627',
            style: AppTypography.bodyMedium.copyWith(
              color: themeColors.textOnGradient.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: AppAnimations.normal)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildMemberActivityList(dynamic themeColors) {
    if (_memberActivity.isEmpty) {
      return Center(
        child: Text(
          'لا يوجد نشاط حالي',
          style: AppTypography.bodyLarge.copyWith(
            color: themeColors.textOnGradient.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'أعضاء العائلة',
          style: AppTypography.titleMedium.copyWith(
            color: themeColors.textOnGradient,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...List.generate(_memberActivity.length, (index) {
          final member = _memberActivity[index];
          final user = ref.read(currentUserProvider);
          final isCurrentUser = member['id'] == user?.id;

          return _buildMemberActivityItem(member, isCurrentUser, themeColors, index);
        }),
      ],
    );
  }

  Widget _buildMemberActivityItem(
    Map<String, dynamic> member,
    bool isCurrentUser,
    dynamic themeColors,
    int index,
  ) {
    final currentStreak = member['current_streak'] as int? ?? 0;
    final name = member['full_name'] as String? ?? 'عضو';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: isCurrentUser
              ? BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      themeColors.primary.withValues(alpha: 0.2),
                      themeColors.primaryDark.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: Row(
            children: [
              // Avatar (no rank number)
              CircleAvatar(
                radius: 20,
                backgroundColor: themeColors.primary.withValues(alpha: 0.3),
                child: Text(
                  _getInitials(name),
                  style: AppTypography.bodyMedium.copyWith(
                    color: themeColors.textOnGradient,
                    fontWeight: FontWeight.bold,
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
                      name,
                      style: AppTypography.bodyMedium.copyWith(
                        color: themeColors.textOnGradient,
                        fontWeight: FontWeight.w600,
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

              // Streak chip (no points, no ranking)
              if (currentStreak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: themeColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: themeColors.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('\u{1f525}', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        '$currentStreak يوم',
                        style: AppTypography.labelSmall.copyWith(
                          color: themeColors.textOnGradient,
                          fontWeight: FontWeight.bold,
                        ),
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
        .fadeIn(delay: Duration(milliseconds: index * 50), duration: AppAnimations.normal)
        .slideX(begin: 0.1, end: 0, delay: Duration(milliseconds: index * 50));
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '؟';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  /// Build upgrade prompt for non-pro users
  Widget _buildUpgradePrompt(dynamic themeColors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    themeColors.primary.withValues(alpha: 0.3),
                    themeColors.primaryDark.withValues(alpha: 0.2),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.family_restroom_rounded,
                size: 64,
                color: themeColors.primary,
              ),
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.05, 1.05),
                  duration: const Duration(seconds: 2),
                ),

            const SizedBox(height: AppSpacing.xl),

            Text(
              'نشاط العائلة',
              style: AppTypography.headlineMedium.copyWith(
                color: themeColors.textOnGradient,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            Text(
              'ميزة حصرية للمشتركين',
              style: AppTypography.bodyLarge.copyWith(
                color: themeColors.textOnGradient.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.md),

            Text(
              'اشترك لتشوف نشاط تواصل عائلتك',
              style: AppTypography.bodyMedium.copyWith(
                color: themeColors.textOnGradient.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.xl),

            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PaywallScreen(
                      featureToUnlock: FeatureIds.leaderboard,
                      contextHeadline: PaywallContext.headlineForFeature(FeatureIds.leaderboard),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColors.primary,
                foregroundColor: themeColors.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.workspace_premium_rounded),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'ترقية إلى PRO',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
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
}
