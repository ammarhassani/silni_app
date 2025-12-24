import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/config/supabase_config.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/premium_loading_indicator.dart';

enum LeaderboardType {
  points,
  streak,
  level,
}

/// Leaderboard screen showing top users
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _leaderboardData = [];
  Map<String, dynamic>? _currentUserRank;
  bool _isLoading = true;
  LeaderboardType _selectedType = LeaderboardType.points;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedType = LeaderboardType.values[_tabController.index];
        });
        _loadLeaderboard();
      }
    });
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboard() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      String orderColumn;
      switch (_selectedType) {
        case LeaderboardType.points:
          orderColumn = 'points';
          break;
        case LeaderboardType.streak:
          orderColumn = 'current_streak';
          break;
        case LeaderboardType.level:
          orderColumn = 'level';
          break;
      }

      // Get top 50 users
      final response = await SupabaseConfig.client
          .from('users')
          .select('id, full_name, email, points, level, current_streak, avatar_url')
          .order(orderColumn, ascending: false)
          .limit(50);

      final data = List<Map<String, dynamic>>.from(response as List);

      // Find current user's rank
      final currentUserIndex = data.indexWhere((u) => u['id'] == user.id);
      Map<String, dynamic>? currentUserRank;

      if (currentUserIndex >= 0) {
        currentUserRank = {
          ...data[currentUserIndex],
          'rank': currentUserIndex + 1,
        };
      } else {
        // User not in top 50, fetch their rank separately
        final allUsers = await SupabaseConfig.client
            .from('users')
            .select('id')
            .order(orderColumn, ascending: false);

        final allUsersList = List<Map<String, dynamic>>.from(allUsers as List);
        final userRank = allUsersList.indexWhere((u) => u['id'] == user.id) + 1;

        final userData = await SupabaseConfig.client
            .from('users')
            .select('id, full_name, email, points, level, current_streak, avatar_url')
            .eq('id', user.id)
            .single();

        currentUserRank = {
          ...userData,
          'rank': userRank,
        };
      }

      if (mounted) {
        setState(() {
          _leaderboardData = data;
          _currentUserRank = currentUserRank;
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
      body: Stack(
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
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_ios_rounded),
                        color: Colors.white,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'لوحة المتصدرين',
                        style: AppTypography.headlineMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _loadLeaderboard,
                        icon: const Icon(Icons.refresh_rounded),
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),

                // Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: GlassCard(
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.premiumGold,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white60,
                      labelStyle: AppTypography.titleSmall,
                      tabs: const [
                        Tab(text: 'النقاط'),
                        Tab(text: 'السلسلة'),
                        Tab(text: 'المستوى'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Current user rank
                if (_currentUserRank != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: _buildUserRankCard(_currentUserRank!, isCurrentUser: true),
                  ),

                const SizedBox(height: AppSpacing.md),

                // Leaderboard list
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: PremiumLoadingIndicator(
                            message: 'جاري تحميل الترتيب...',
                          ),
                        )
                      : _leaderboardData.isEmpty
                          ? Center(
                              child: Text(
                                'لا توجد بيانات',
                                style: AppTypography.bodyLarge.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              itemCount: _leaderboardData.length,
                              itemBuilder: (context, index) {
                                final userData = _leaderboardData[index];
                                final user = ref.read(currentUserProvider);
                                final isCurrentUser = userData['id'] == user?.id;

                                return _buildLeaderboardItem(
                                  userData,
                                  index + 1,
                                  isCurrentUser,
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRankCard(Map<String, dynamic> userData, {required bool isCurrentUser}) {
    return GlassCard(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.premiumGold.withValues(alpha: 0.3),
              AppColors.premiumGoldDark.withValues(alpha: 0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Rank badge
            _buildRankBadge(userData['rank'] as int),
            const SizedBox(width: AppSpacing.md),

            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.islamicGreenPrimary,
              child: Text(
                _getInitials(userData['full_name'] as String? ?? userData['email'] as String),
                style: AppTypography.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userData['full_name'] as String? ?? 'مستخدم',
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'ترتيبك',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Score
            _buildScoreChip(userData),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: -0.2, end: 0, duration: 400.ms);
  }

  Widget _buildLeaderboardItem(
    Map<String, dynamic> userData,
    int rank,
    bool isCurrentUser,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: isCurrentUser
              ? BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.islamicGreenPrimary.withValues(alpha: 0.2),
                      AppColors.islamicGreenLight.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: Row(
            children: [
              // Rank badge
              _buildRankBadge(rank),
              const SizedBox(width: AppSpacing.md),

              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: _getRankColor(rank).withValues(alpha: 0.3),
                child: Text(
                  _getInitials(userData['full_name'] as String? ?? userData['email'] as String),
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userData['full_name'] as String? ?? 'مستخدم',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isCurrentUser)
                      Text(
                        'أنت',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.islamicGreenLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),

              // Score
              _buildScoreChip(userData),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (rank * 30).ms, duration: 300.ms)
        .slideX(begin: 0.1, end: 0, delay: (rank * 30).ms, duration: 400.ms);
  }

  Widget _buildRankBadge(int rank) {
    Color badgeColor;
    Widget? icon;

    if (rank == 1) {
      badgeColor = AppColors.premiumGold;
      icon = const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 20);
    } else if (rank == 2) {
      badgeColor = Colors.grey[400]!;
      icon = const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 18);
    } else if (rank == 3) {
      badgeColor = Colors.brown[400]!;
      icon = const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 16);
    } else {
      badgeColor = Colors.white.withValues(alpha: 0.2);
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
        boxShadow: rank <= 3
            ? [
                BoxShadow(
                  color: badgeColor.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Center(
        child: icon ??
            Text(
              '$rank',
              style: AppTypography.titleSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
      ),
    );
  }

  Widget _buildScoreChip(Map<String, dynamic> userData) {
    String value;
    IconData icon;
    Color color;

    switch (_selectedType) {
      case LeaderboardType.points:
        value = '${userData['points'] ?? 0}';
        icon = Icons.star_rounded;
        color = AppColors.premiumGold;
        break;
      case LeaderboardType.streak:
        value = '${userData['current_streak'] ?? 0}';
        icon = Icons.local_fire_department_rounded;
        color = AppColors.energeticRed;
        break;
      case LeaderboardType.level:
        value = '${userData['level'] ?? 1}';
        icon = Icons.workspace_premium_rounded;
        color = AppColors.islamicGreenPrimary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.titleSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return AppColors.premiumGold;
    if (rank == 2) return Colors.grey[400]!;
    if (rank == 3) return Colors.brown[400]!;
    return AppColors.islamicGreenLight;
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '؟';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }
}
