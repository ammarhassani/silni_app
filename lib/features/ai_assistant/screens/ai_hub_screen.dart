import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/ai_identity.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/subscription_tier.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glass_pill_title.dart';
import '../../../shared/widgets/message_widget.dart';
import '../../../shared/widgets/offline_guard.dart';
import '../../../shared/widgets/persistent_bottom_nav.dart';
import '../../subscription/screens/paywall_screen.dart';

/// AI Hub — hero feature on top + a tight grid of distinct-color tiles
/// below. Hero gets the dramatic full-width treatment (Counselor — the
/// primary AI surface); the secondary features each get their own fixed
/// accent color (purple / blue / gold) so the column reads as a curated
/// palette, not four template clones.
class AIHubScreen extends ConsumerWidget {
  const AIHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Semantics(
        label: 'مركز ${AIIdentity.name} الذكي',
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            children: [
              Center(
                child: GlassPillTitle(
                  text: AIIdentity.name,
                  centered: true,
                  subtitle: Text(
                    'مساعدك الذكي لصلة الرحم',
                    textAlign: TextAlign.center,
                    style: AppTypography.labelSmall.copyWith(
                      color:
                          themeColors.textOnGradient.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const MessageWidget(screenPath: '/ai-hub'),
              const SizedBox(height: AppSpacing.md),
              // HERO — Counselor. Big card, dramatic gradient, centered
              // glowing icon + title + subtitle. The primary AI surface.
              _HeroAIFeatureCard(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'المستشار',
                description: 'نصائح عائلية ومحادثة ذكية',
                featureId: FeatureIds.aiChat,
                route: AppRoutes.aiChat,
                themeColors: themeColors,
              ),
              const SizedBox(height: AppSpacing.md),
              // 2-up row of compact tiles, each in its own accent color.
              Row(
                children: [
                  Expanded(
                    child: _CompactAIFeatureCard(
                      icon: Icons.record_voice_over_rounded,
                      title: 'سيناريوهات',
                      description: 'محادثات صعبة',
                      featureId: FeatureIds.communicationScripts,
                      route: AppRoutes.aiScripts,
                      themeColors: themeColors,
                      accent: AppColors.emotionalPurple,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _CompactAIFeatureCard(
                      icon: Icons.bar_chart_rounded,
                      title: 'التقرير',
                      description: 'ملخص أسبوعي',
                      featureId: FeatureIds.weeklyReports,
                      route: AppRoutes.aiReport,
                      themeColors: themeColors,
                      accent: AppColors.calmBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // Full-width premium tile for the monthly wrapped — gold
              // treatment matches its "premium summary" character.
              _CompactAIFeatureCard(
                icon: Icons.auto_awesome_rounded,
                title: 'ملخصك الشهري',
                description: 'قصة شهرك في صلة الرحم',
                featureId: FeatureIds.monthlyWrapped,
                route: AppRoutes.monthlyWrapped,
                themeColors: themeColors,
                accent: AppColors.premiumGold,
              ),
              SizedBox(height: PersistentBottomNav.totalHeight),
            ],
          ),
        ),
      ),
    );
  }
}

/// Big hero card — full-width, dramatic gradient, glowing icon halo.
/// Reserved for the single primary AI feature (Counselor).
class _HeroAIFeatureCard extends ConsumerWidget {
  const _HeroAIFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.featureId,
    required this.route,
    required this.themeColors,
  });

  final IconData icon;
  final String title;
  final String description;
  final String featureId;
  final String route;
  final ThemeColors themeColors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OfflineGuard(
      onPressed: () => _handleTap(context, ref, featureId, route),
      child: GlassCard(
        semanticsLabel: '$title، $description',
        padding: EdgeInsets.zero,
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.joyfulOrange.withValues(alpha: 0.45),
            themeColors.primary.withValues(alpha: 0.55),
            themeColors.primaryDark.withValues(alpha: 0.4),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Big radial glow (top-right) — orange-tinted dramatic light
              Positioned(
                top: -60,
                right: -60,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.joyfulOrange.withValues(alpha: 0.55),
                        AppColors.joyfulOrange.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Soft secondary glow (bottom-left)
              Positioned(
                left: -40,
                bottom: -40,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        themeColors.primary.withValues(alpha: 0.4),
                        themeColors.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Concentric ripple ring around the icon — subtle "broadcasting"
              // motif appropriate for an advice/dialogue surface.
              Positioned.fill(
                child: Center(
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
              // Content — unpositioned so it sizes the Stack's height.
              // Stack alignment is set on the parent so this child centers
              // horizontally within the card's bounds.
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xl,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glowing icon halo
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: themeColors.primary.withValues(alpha: 0.55),
                        border: Border.all(
                          color: AppColors.joyfulOrange.withValues(alpha: 0.7),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.joyfulOrange
                                .withValues(alpha: 0.4),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: themeColors.primary.withValues(alpha: 0.45),
                            blurRadius: 36,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      title,
                      style: AppTypography.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
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

/// Compact tile — used in the grid below the hero. Each tile gets a
/// fixed accent color (passed in) so the row reads as a multicolor
/// curated set rather than theme-uniform.
class _CompactAIFeatureCard extends ConsumerWidget {
  const _CompactAIFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.featureId,
    required this.route,
    required this.themeColors,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String description;
  final String featureId;
  final String route;
  final ThemeColors themeColors;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OfflineGuard(
      onPressed: () => _handleTap(context, ref, featureId, route),
      child: GlassCard(
        semanticsLabel: '$title، $description',
        padding: EdgeInsets.zero,
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            accent.withValues(alpha: 0.32),
            accent.withValues(alpha: 0.18),
            themeColors.primaryDark.withValues(alpha: 0.25),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: Stack(
            children: [
              // Soft glow blob top-right
              Positioned(
                top: -24,
                right: -24,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accent.withValues(alpha: 0.35),
                        accent.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: AppTypography.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            description,
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accent,
                            accent.withValues(alpha: 0.75),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.45),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
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

void _handleTap(
  BuildContext context,
  WidgetRef ref,
  String featureId,
  String route,
) {
  final hasAccess = ref.read(featureAccessProvider(featureId));
  if (hasAccess) {
    context.push(route);
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => PaywallScreen(
        featureToUnlock: featureId,
        contextHeadline: PaywallContext.headlineForFeature(featureId),
      ),
    ),
  );
}
