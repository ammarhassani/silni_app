import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/ai_identity.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/subscription_tier.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../subscription/screens/paywall_screen.dart';
import '../providers/ai_chat_provider.dart';
import '../../../shared/utils/ui_helpers.dart';

/// AI Hub Screen - Main dashboard for all AI features
/// Replaces the old statistics "Coming Soon" screen
class AIHubScreen extends ConsumerStatefulWidget {
  const AIHubScreen({super.key});

  @override
  ConsumerState<AIHubScreen> createState() => _AIHubScreenState();
}

class _AIHubScreenState extends ConsumerState<AIHubScreen> {
  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Semantics(
        label: 'مركز ${AIIdentity.name} الذكي',
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: _buildHeader(themeColors),
              ),

            // AI Features Grid
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.md),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 0.95, // More height for badges
                ),
                delegate: SliverChildListDelegate([
                  _buildFeatureCard(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'المستشار',
                    subtitle: 'نصائح عائلية',
                    gradient: LinearGradient(
                      colors: [themeColors.primary, themeColors.primaryLight],
                    ),
                    onTap: () => _navigateWithGate('counselor', FeatureIds.aiChat, themeColors),
                    delay: 0,
                    featureId: FeatureIds.aiChat,
                    requiredTier: SubscriptionTier.max,
                  ),
                  _buildFeatureCard(
                    icon: Icons.edit_note_rounded,
                    title: 'الرسائل',
                    subtitle: 'كتابة رسائل مميزة',
                    gradient: _createGradient(themeColors.accent, themeColors.primaryLight),
                    onTap: () => _navigateWithGate('messages', FeatureIds.messageComposer, themeColors),
                    delay: 100,
                    featureId: FeatureIds.messageComposer,
                    requiredTier: SubscriptionTier.max,
                  ),
                  _buildFeatureCard(
                    icon: Icons.psychology_rounded,
                    title: 'سيناريوهات',
                    subtitle: 'محادثات صعبة',
                    gradient: _createGradient(Colors.purple.shade400, Colors.purple.shade200),
                    onTap: () => _navigateWithGate('scripts', FeatureIds.communicationScripts, themeColors),
                    delay: 200,
                    featureId: FeatureIds.communicationScripts,
                    requiredTier: SubscriptionTier.max,
                  ),
                  _buildFeatureCard(
                    icon: Icons.favorite_rounded,
                    title: 'تحليل العلاقات',
                    subtitle: 'نصائح ذكية',
                    gradient: _createGradient(Colors.pink.shade400, Colors.pink.shade200),
                    onTap: () => _navigateWithGate('analysis', FeatureIds.relationshipAnalysis, themeColors),
                    delay: 300,
                    featureId: FeatureIds.relationshipAnalysis,
                    requiredTier: SubscriptionTier.max,
                  ),
                  _buildFeatureCard(
                    icon: Icons.notifications_active_rounded,
                    title: 'تذكيرات ذكية',
                    subtitle: 'اقتراحات AI',
                    gradient: _createGradient(Colors.orange.shade400, Colors.orange.shade200),
                    onTap: () => _navigateWithGate('smart_reminders', FeatureIds.smartRemindersAI, themeColors),
                    delay: 400,
                    featureId: FeatureIds.smartRemindersAI,
                    requiredTier: SubscriptionTier.max,
                  ),
                  _buildFeatureCard(
                    icon: Icons.analytics_rounded,
                    title: 'التقرير',
                    subtitle: 'ملخص أسبوعي',
                    gradient: _createGradient(Colors.teal.shade400, Colors.teal.shade200),
                    onTap: () => _navigateWithGate('report', FeatureIds.weeklyReports, themeColors),
                    delay: 500,
                    featureId: FeatureIds.weeklyReports,
                    requiredTier: SubscriptionTier.max,
                  ),
                ]),
              ),
            ),

            // Ramadan Mode Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _buildRamadanCard(themeColors),
              ),
            ),

            // Health Overview
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: _buildHealthOverview(themeColors),
              ),
            ),

            // Bottom spacing for nav bar
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.bottomNavPadding),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors themeColors) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              // AI Avatar with glow
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [themeColors.primary, themeColors.primaryLight],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: themeColors.primary.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(
                    duration: const Duration(seconds: 3),
                    color: Colors.white24,
                  ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AIIdentity.name,
                      style: AppTypography.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'مساعدك الذكي في صلة الرحم',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: AppAnimations.modal)
              .slideX(begin: -0.1, end: 0),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
    required int delay,
    String? featureId,
    SubscriptionTier requiredTier = SubscriptionTier.free,
  }) {
    // Check if feature is locked
    final hasAccess = featureId == null || ref.watch(featureAccessProvider(featureId));
    final isPremiumFeature = requiredTier != SubscriptionTier.free;

    return GlassCard(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Stack(
        children: [
          // Main content
          Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: hasAccess ? 0.1 : 0.05),
                  Colors.white.withValues(alpha: hasAccess ? 0.05 : 0.02),
                ],
              ),
            ),
            child: Opacity(
              opacity: hasAccess ? 1.0 : 0.6,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: gradient,
                      boxShadow: [
                        BoxShadow(
                          color: (gradient as LinearGradient).colors.first.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white60,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          // Premium badge
          if (isPremiumFeature && !hasAccess)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.premiumGold, AppColors.premiumGoldDark],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.premiumGold.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock, size: 10, color: Colors.black87),
                    const SizedBox(width: 3),
                    Text(
                      requiredTier.englishName.toUpperCase(),
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn()
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
  }

  Widget _buildRamadanCard(ThemeColors themeColors) {
    // Check if it's Ramadan season (this is simplified, use proper Hijri calendar)
    final now = DateTime.now();
    final isRamadanSeason = now.month >= 2 && now.month <= 4; // Approximate

    return GlassCard(
      onTap: () {
        HapticFeedback.lightImpact();
        _navigateToFeature('ramadan', themeColors);
      },
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.indigo.shade800.withValues(alpha: 0.3),
          Colors.purple.shade900.withValues(alpha: 0.2),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.indigo.shade400,
                    Colors.purple.shade400,
                  ],
                ),
              ),
              child: const Text(
                '🌙',
                style: TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'وضع رمضان',
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isRamadanSeason ? 'مميزات خاصة للشهر الفضيل' : 'قريباً في رمضان',
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
        .animate(delay: const Duration(milliseconds: 800))
        .fadeIn()
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildHealthOverview(ThemeColors themeColors) {
    final relativesAsync = ref.watch(aiRelativesProvider);

    // Calculate health counts from relatives
    final relatives = relativesAsync.valueOrNull ?? [];
    int healthyCount = 0;
    int needsAttentionCount = 0;
    int atRiskCount = 0;

    for (final relative in relatives) {
      switch (relative.healthStatus2) {
        case RelationshipHealthStatus.healthy:
          healthyCount++;
        case RelationshipHealthStatus.needsAttention:
          needsAttentionCount++;
        case RelationshipHealthStatus.atRisk:
          atRiskCount++;
        case RelationshipHealthStatus.unknown:
          // Count unknown as needs attention
          needsAttentionCount++;
      }
    }

    return GlassCard(
      onTap: () {
        HapticFeedback.lightImpact();
        // Use gated navigation for health overview (same as relationship analysis)
        _navigateWithGate('health', FeatureIds.relationshipAnalysis, themeColors);
      },
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'صحة العلاقات',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white30,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHealthStat('🟢', healthyCount, 'صحية'),
                _buildHealthStat('🟡', needsAttentionCount, 'تحتاج اهتمام'),
                _buildHealthStat('🔴', atRiskCount, 'معرضة للخطر'),
              ],
            ),
          ],
        ),
      ),
    )
        .animate(delay: const Duration(milliseconds: 900))
        .fadeIn()
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildHealthStat(String emoji, int count, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: AppTypography.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  LinearGradient _createGradient(Color start, Color end) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [start, end],
    );
  }

  /// Navigate to feature with subscription gate check
  void _navigateWithGate(String feature, String featureId, ThemeColors themeColors) {
    final hasAccess = ref.read(featureAccessProvider(featureId));

    if (hasAccess) {
      _navigateToFeature(feature, themeColors);
    } else {
      // Show paywall
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaywallScreen(
            featureToUnlock: featureId,
          ),
        ),
      );
    }
  }

  void _navigateToFeature(String feature, ThemeColors themeColors) {
    switch (feature) {
      case 'counselor':
        context.push(AppRoutes.aiChat);
        return;
      case 'messages':
        context.push(AppRoutes.aiMessages);
        return;
      case 'scripts':
        context.push(AppRoutes.aiScripts);
        return;
      case 'analysis':
        context.push(AppRoutes.aiAnalysis);
        return;
      case 'smart_reminders':
        // Smart reminders are now integrated into the main reminders screen
        context.push(AppRoutes.reminders);
        return;
      case 'report':
        context.push(AppRoutes.aiReport);
        return;
      case 'health':
        // Navigate to relationship analysis for health overview
        context.push(AppRoutes.aiAnalysis);
        return;
      case 'ramadan':
        // Ramadan mode - coming soon
        // Ramadan mode - coming soon
        UIHelpers.showSnackBar(
          context,
          'وضع رمضان قريباً إن شاء الله 🌙',
          backgroundColor: Colors.indigo.shade600,
        );
        return;
      default:
        // Other features coming soon
        // Other features coming soon
        UIHelpers.showSnackBar(
          context,
          'قريباً: $feature',
          backgroundColor: themeColors.primary,
        );
    }
  }
}
