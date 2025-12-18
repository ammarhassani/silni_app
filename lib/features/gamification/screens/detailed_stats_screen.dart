import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../providers/stats_provider.dart';
import '../widgets/stats/widgets.dart';

/// Detailed statistics screen showing comprehensive gamification data
class DetailedStatsScreen extends ConsumerWidget {
  const DetailedStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(detailedStatsProvider);

    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(animated: true, child: SizedBox.expand()),
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(context),

                // Content
                Expanded(
                  child: statsAsync.when(
                    data: (stats) => _buildContent(stats),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, _) => _buildErrorState(context, ref),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
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
            'الإحصائيات التفصيلية',
            style: AppTypography.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(DetailedStats stats) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Overall stats
        OverallStatsWidget(userStats: stats.userStats),
        const SizedBox(height: AppSpacing.lg),

        // Interaction type breakdown
        InteractionTypeChart(interactionCounts: stats.interactionCounts),
        const SizedBox(height: AppSpacing.lg),

        // Weekly activity
        WeeklyActivityChart(recentActivity: stats.recentActivity),
        const SizedBox(height: AppSpacing.lg),

        // Monthly trend analysis
        MonthlyTrendChart(monthlyData: stats.monthlyData),
        const SizedBox(height: AppSpacing.lg),

        // Top relatives breakdown
        TopRelativesWidget(topRelatives: stats.topRelatives),
        const SizedBox(height: AppSpacing.lg),

        // Time-based patterns
        TimePatternsChart(timePatterns: stats.timePatterns),
        const SizedBox(height: AppSpacing.lg),

        // Achievement badges showcase
        AchievementsShowcase(achievements: stats.achievements),
        const SizedBox(height: AppSpacing.lg),

        // Milestones progress
        MilestonesProgress(userStats: stats.userStats),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.white54,
            size: 64,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'حدث خطأ في تحميل البيانات',
            style: AppTypography.bodyLarge.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton.icon(
            onPressed: () => ref.invalidate(detailedStatsProvider),
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            label: Text(
              'إعادة المحاولة',
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
