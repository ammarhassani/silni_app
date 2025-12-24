import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/ai_chat_provider.dart';

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
      body: SafeArea(
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
                  childAspectRatio: 1.1,
                ),
                delegate: SliverChildListDelegate([
                  _buildFeatureCard(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'المستشار',
                    subtitle: 'نصائح عائلية',
                    gradient: LinearGradient(
                      colors: [themeColors.primary, themeColors.primaryLight],
                    ),
                    onTap: () => _navigateToFeature('counselor', themeColors),
                    delay: 0,
                  ),
                  _buildFeatureCard(
                    icon: Icons.edit_note_rounded,
                    title: 'الرسائل',
                    subtitle: 'كتابة رسائل مميزة',
                    gradient: _createGradient(themeColors.accent, themeColors.primaryLight),
                    onTap: () => _navigateToFeature('messages', themeColors),
                    delay: 100,
                  ),
                  _buildFeatureCard(
                    icon: Icons.psychology_rounded,
                    title: 'سيناريوهات',
                    subtitle: 'محادثات صعبة',
                    gradient: _createGradient(Colors.purple.shade400, Colors.purple.shade200),
                    onTap: () => _navigateToFeature('scripts', themeColors),
                    delay: 200,
                  ),
                  _buildFeatureCard(
                    icon: Icons.favorite_rounded,
                    title: 'تحليل العلاقات',
                    subtitle: 'نصائح ذكية',
                    gradient: _createGradient(Colors.pink.shade400, Colors.pink.shade200),
                    onTap: () => _navigateToFeature('analysis', themeColors),
                    delay: 300,
                  ),
                  _buildFeatureCard(
                    icon: Icons.notifications_active_rounded,
                    title: 'تذكيرات ذكية',
                    subtitle: 'اقتراحات AI',
                    gradient: _createGradient(Colors.orange.shade400, Colors.orange.shade200),
                    onTap: () => _navigateToFeature('smart_reminders', themeColors),
                    delay: 400,
                  ),
                  _buildFeatureCard(
                    icon: Icons.analytics_rounded,
                    title: 'التقرير',
                    subtitle: 'ملخص أسبوعي',
                    gradient: _createGradient(Colors.teal.shade400, Colors.teal.shade200),
                    onTap: () => _navigateToFeature('report', themeColors),
                    delay: 500,
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
              child: SizedBox(height: 100),
            ),
          ],
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
                      'واصل',
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
              .fadeIn(duration: const Duration(milliseconds: 400))
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
  }) {
    return GlassCard(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.1),
              Colors.white.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
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
                size: 28,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white60,
              ),
            ),
          ],
        ),
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
        padding: const EdgeInsets.all(AppSpacing.sm),
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
        _navigateToFeature('health', themeColors);
      },
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('وضع رمضان قريباً إن شاء الله 🌙'),
            backgroundColor: Colors.indigo.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      default:
        // Other features coming soon
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('قريباً: $feature'),
            backgroundColor: themeColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
    }
  }
}
