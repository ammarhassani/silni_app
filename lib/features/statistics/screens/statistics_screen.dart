import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/services/relatives_service.dart';
import '../../../shared/models/relative_model.dart';
import '../../auth/providers/auth_provider.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  int _calculateCurrentStreak(List<Relative> relatives) {
    if (relatives.isEmpty) return 0;

    // Get all contact dates and sort them
    final contactDates =
        relatives
            .where((r) => r.lastContactDate != null)
            .map((r) => r.lastContactDate!)
            .toList()
          ..sort((a, b) => b.compareTo(a)); // Most recent first

    if (contactDates.isEmpty) return 0;

    // Calculate streak: count consecutive days with at least one contact
    int streak = 0;
    DateTime checkDate = DateTime.now();
    final Set<String> contactedDays = contactDates
        .map((date) => '${date.year}-${date.month}-${date.day}')
        .toSet();

    while (true) {
      final dayKey = '${checkDate.year}-${checkDate.month}-${checkDate.day}';
      if (contactedDays.contains(dayKey)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final relativesService = RelativesService();

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User not authenticated')),
      );
    }

    return Scaffold(
      body: GradientBackground(
        animated: true,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'الإحصائيات',
                      style: AppTypography.headlineMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Stats with real data
              Expanded(
                child: StreamBuilder<List<Relative>>(
                  stream: relativesService.getRelativesStream(user.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'خطأ: ${snapshot.error}',
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      );
                    }

                    final relatives = snapshot.data ?? [];
                    final totalContacts = relatives.fold<int>(
                      0,
                      (sum, r) => sum + r.interactionCount,
                    );
                    final currentStreak = _calculateCurrentStreak(relatives);

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          GlassCard(
                            child: Column(
                              children: [
                                Text(
                                  'إجمالي التواصل',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  totalContacts.toString(),
                                  style: AppTypography.numberLarge.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn().slideY(begin: 0.3, end: 0),
                          const SizedBox(height: AppSpacing.md),
                          GlassCard(
                                child: Column(
                                  children: [
                                    Text(
                                      'سلسلة التواصل الحالية',
                                      style: AppTypography.titleMedium.copyWith(
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      currentStreak.toString(),
                                      style: AppTypography.numberLarge.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      currentStreak == 1 ? 'يوم' : 'أيام',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .animate(delay: const Duration(milliseconds: 100))
                              .fadeIn()
                              .slideY(begin: 0.3, end: 0),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
