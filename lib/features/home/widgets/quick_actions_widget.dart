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
          _FamilyTreeHeroCard(
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

/// Full-width dramatic family tree card with horizontal layout and visual flair.
class _FamilyTreeHeroCard extends StatelessWidget {
  const _FamilyTreeHeroCard({
    required this.themeColors,
    required this.onTap,
  });

  final dynamic themeColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'شجرة العائلة - اكتشف روابط عائلتك',
      button: true,
      child: GlassCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.premiumGoldDark.withValues(alpha: 0.25),
            themeColors.primaryDark.withValues(alpha: 0.4),
            themeColors.primary.withValues(alpha: 0.2),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: Stack(
            children: [
              // Decorative tree branch lines (background pattern)
              Positioned(
                left: -20,
                top: -10,
                bottom: -10,
                width: 140,
                child: CustomPaint(
                  painter: _TreeBranchPainter(
                    color: AppColors.premiumGold.withValues(alpha: 0.08),
                  ),
                ),
              ),

              // Golden accent glow (top-right)
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.premiumGold.withValues(alpha: 0.15),
                        AppColors.premiumGold.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Main content
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    // Tree icon with golden ring
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.premiumGoldDark,
                            AppColors.premiumGold,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.premiumGold.withValues(alpha: 0.4),
                            blurRadius: 16,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.account_tree_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),

                    const SizedBox(width: AppSpacing.md),

                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'شجرة العائلة',
                            style: AppTypography.titleLarge.copyWith(
                              color: themeColors.textOnGradient,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'اكتشف روابط عائلتك',
                            style: AppTypography.bodyMedium.copyWith(
                              color: themeColors.textOnGradient
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Arrow
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: themeColors.textOnGradient.withValues(alpha: 0.9),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints decorative tree branch lines as a background pattern.
class _TreeBranchPainter extends CustomPainter {
  _TreeBranchPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = size.width * 0.6;
    final cy = size.height * 0.5;

    // Trunk
    canvas.drawLine(Offset(cx, cy + 40), Offset(cx, cy - 20), paint);

    // Branches
    canvas.drawLine(Offset(cx, cy - 20), Offset(cx - 30, cy - 50), paint);
    canvas.drawLine(Offset(cx, cy - 20), Offset(cx + 30, cy - 50), paint);
    canvas.drawLine(Offset(cx, cy + 5), Offset(cx - 40, cy - 15), paint);
    canvas.drawLine(Offset(cx, cy + 5), Offset(cx + 40, cy - 15), paint);

    // Nodes (circles at branch tips)
    final nodePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final offset in [
      Offset(cx - 30, cy - 50),
      Offset(cx + 30, cy - 50),
      Offset(cx - 40, cy - 15),
      Offset(cx + 40, cy - 15),
      Offset(cx, cy - 20),
    ]) {
      canvas.drawCircle(offset, 5, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
