import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
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

              // Stats
              Expanded(
                child: SingleChildScrollView(
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
                              '45',
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
                              'أطول سلسلة',
                              style: AppTypography.titleMedium.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              '12',
                              style: AppTypography.numberLarge.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'يوم',
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
