import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/ai_identity.dart';
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

/// AI Hub — a navigation grid for the three live AI features.
///
/// The screen is intentionally plain: it's the door to the AI features, not
/// the experience itself. Drama belongs inside AI Chat, not here.
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
                  subtitle: Text(
                    'مساعدك الذكي لصلة الرحم',
                    style: AppTypography.labelSmall.copyWith(
                      color: themeColors.textOnGradient.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const MessageWidget(screenPath: '/ai-hub'),
              const SizedBox(height: AppSpacing.md),
              _AIFeatureCard(
                icon: Icons.psychology_rounded,
                title: 'المستشار',
                description: 'محادثة ذكية للنصائح والمواقف الصعبة',
                featureId: FeatureIds.aiChat,
                route: AppRoutes.aiChat,
                themeColors: themeColors,
              ),
              const SizedBox(height: AppSpacing.sm),
              _AIFeatureCard(
                icon: Icons.record_voice_over_rounded,
                title: 'سيناريوهات التواصل',
                description: 'نصوص جاهزة لبدء المحادثات وإصلاح العلاقات',
                featureId: FeatureIds.communicationScripts,
                route: AppRoutes.aiScripts,
                themeColors: themeColors,
              ),
              const SizedBox(height: AppSpacing.sm),
              _AIFeatureCard(
                icon: Icons.analytics_rounded,
                title: 'التقرير الأسبوعي',
                description: 'ملخص أسبوعي لتواصلك مع أهلك',
                featureId: FeatureIds.weeklyReports,
                route: AppRoutes.aiReport,
                themeColors: themeColors,
              ),
              const SizedBox(height: AppSpacing.sm),
              _AIFeatureCard(
                icon: Icons.auto_awesome_rounded,
                title: 'ملخصك الشهري',
                description: 'قصة شهرك في صلة الرحم بأسلوب يخصك',
                featureId: FeatureIds.monthlyWrapped,
                route: AppRoutes.monthlyWrapped,
                themeColors: themeColors,
              ),
              SizedBox(height: PersistentBottomNav.totalHeight),
            ],
          ),
        ),
      ),
    );
  }
}

class _AIFeatureCard extends ConsumerWidget {
  const _AIFeatureCard({
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
    // OfflineGuard dims the card and shows a connectivity snackbar when
    // offline. The downstream AI features all require network anyway —
    // letting users tap into them while disconnected just produces opaque
    // errors a few screens deeper. Tap routing happens inside
    // OfflineGuard's onPressed when isOnline.
    return OfflineGuard(
      onPressed: () => _handleTap(context, ref),
      child: GlassCard(
        semanticsLabel: '$title، $description',
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: themeColors.primaryGradient,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: themeColors.textOnGradient,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: themeColors.textOnGradient.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_back_ios_rounded,
            size: 16,
            color: themeColors.textOnGradient.withValues(alpha: 0.6),
          ),
        ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
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
}
