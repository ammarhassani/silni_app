import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/ai/ai_identity.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/glass_card.dart';

/// Quick action buttons grid
class QuickActionsWidget extends ConsumerWidget {
  const QuickActionsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    return Semantics(
      label: 'إجراءات سريعة',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إجراءات سريعة',
            style: AppTypography.headlineSmall.copyWith(
              color: themeColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.notifications_active_rounded,
                  title: 'التذكيرات',
                  subtitle: 'نظّم تذكيراتك',
                  gradient: themeColors.primaryGradient,
                  themeColors: themeColors,
                  onTap: () => context.push(AppRoutes.reminders),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.auto_awesome_rounded,
                  title: AIIdentity.name,
                  subtitle: 'مساعدك الذكي',
                  gradient: LinearGradient(
                    colors: [
                      AppColors.emotionalPurple.withValues(alpha: 0.7),
                      AppColors.calmBlue.withValues(alpha: 0.5),
                    ],
                  ),
                  themeColors: themeColors,
                  onTap: () => context.push(AppRoutes.aiHub),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _QuickActionCard(
            icon: Icons.account_tree_rounded,
            title: 'شجرة العائلة',
            subtitle: 'تصور جميل لعائلتك',
            gradient: LinearGradient(
              colors: [
                themeColors.primaryDark,
                themeColors.primary.withValues(alpha: 0.8),
              ],
            ),
            themeColors: themeColors,
            onTap: () => context.push(AppRoutes.familyTree),
          ),
        ],
      ),
    )
        .animate(delay: const Duration(milliseconds: 300))
        .fadeIn()
        .slideY(begin: 0.1, end: 0);
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.themeColors,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final dynamic themeColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gradientColors = (gradient as LinearGradient).colors;

    return Semantics(
      label: '$title - $subtitle',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              gradientColors.first.withValues(alpha: 0.35),
              gradientColors.last.withValues(alpha: 0.2),
            ],
          ),
          semanticsLabel: title,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero icon container with full gradient + glow
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: gradient,
                  boxShadow: [
                    // Primary shadow
                    BoxShadow(
                      color: gradientColors.first.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                    // Outer glow
                    BoxShadow(
                      color: gradientColors.first.withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(icon, color: Colors.white, size: 40),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: AppTypography.titleLarge.copyWith(
                  color: themeColors.textOnGradient,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: AppTypography.bodyMedium.copyWith(
                  color: themeColors.textOnGradient.withValues(alpha: 0.85),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
