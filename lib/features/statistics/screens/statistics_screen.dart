import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';

/// Coming Soon screen for واصل (Wasil) - AI chat assistant feature
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'واصل',
                    style: AppTypography.headlineMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Coming Soon Content
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // AI Icon with glow effect
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.islamicGreenPrimary.withValues(alpha: 0.3),
                              AppColors.calmBlue.withValues(alpha: 0.3),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.islamicGreenPrimary.withValues(alpha: 0.4),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.smart_toy_rounded,
                          size: 80,
                          color: Colors.white,
                        ),
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .shimmer(
                            duration: const Duration(seconds: 3),
                            color: Colors.white24,
                          ),
                      const SizedBox(height: AppSpacing.xl),

                      // Title
                      Text(
                        'مساعدك الذكي',
                        style: AppTypography.headlineLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fadeIn().slideY(begin: 0.3, end: 0),
                      const SizedBox(height: AppSpacing.sm),

                      // Subtitle
                      Text(
                        'Your AI Assistant',
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white70,
                        ),
                      )
                          .animate(delay: const Duration(milliseconds: 100))
                          .fadeIn()
                          .slideY(begin: 0.3, end: 0),
                      const SizedBox(height: AppSpacing.xl),

                      // Coming Soon Badge
                      GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.md,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.premiumGold,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.premiumGold.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              )
                                  .animate(onPlay: (controller) => controller.repeat())
                                  .fadeIn()
                                  .then()
                                  .fadeOut()
                                  .then()
                                  .fadeIn(),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'قريباً...',
                                style: AppTypography.titleLarge.copyWith(
                                  color: AppColors.premiumGold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                          .animate(delay: const Duration(milliseconds: 200))
                          .fadeIn()
                          .scale(begin: const Offset(0.8, 0.8)),
                      const SizedBox(height: AppSpacing.xl),

                      // Description
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: Text(
                          'تواصل مع أقاربك بسهولة عبر مساعدك الذكي واصل.\n'
                          'سيساعدك على كتابة رسائل مميزة، واقتراح أوقات التواصل المثالية، وتذكيرك بالمناسبات الهامة.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyLarge.copyWith(
                            color: Colors.white70,
                            height: 1.6,
                          ),
                        ),
                      )
                          .animate(delay: const Duration(milliseconds: 300))
                          .fadeIn()
                          .slideY(begin: 0.2, end: 0),
                      const SizedBox(height: AppSpacing.xl * 2),

                      // Feature preview cards
                      _buildFeaturePreview(
                        icon: Icons.edit_note_rounded,
                        title: 'كتابة الرسائل',
                        description: 'اقتراحات ذكية لرسائل مؤثرة',
                        delay: 400,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildFeaturePreview(
                        icon: Icons.schedule_rounded,
                        title: 'أوقات التواصل',
                        description: 'معرفة أفضل أوقات التواصل',
                        delay: 500,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildFeaturePreview(
                        icon: Icons.celebration_rounded,
                        title: 'المناسبات',
                        description: 'تذكير بالمناسبات الخاصة',
                        delay: 600,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturePreview({
    required IconData icon,
    required String title,
    required String description,
    required int delay,
  }) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.islamicGreenPrimary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppColors.islamicGreenPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white30,
              size: 16,
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn()
        .slideX(begin: 0.2, end: 0);
  }
}
