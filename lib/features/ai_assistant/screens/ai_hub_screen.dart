import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/ai_identity.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/subscription_tier.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../../shared/widgets/message_widget.dart';
import '../../../shared/widgets/persistent_bottom_nav.dart';
import '../../subscription/screens/paywall_screen.dart';

/// AI Hub Screen — Dramatic bento grid with signature-branded feature cards.
///
/// Each card gets its own deep gradient, neon glow shadows, bold pattern,
/// gradient text, and icon halo. The hero card has a rotating SweepGradient
/// border. Ambient color orbs float behind the grid for depth.
class AIHubScreen extends ConsumerStatefulWidget {
  const AIHubScreen({super.key});

  @override
  ConsumerState<AIHubScreen> createState() => _AIHubScreenState();
}

class _AIHubScreenState extends ConsumerState<AIHubScreen>
    with TickerProviderStateMixin {
  late AnimationController _ringController;
  late AnimationController _glowController;
  late Animation<double> _glowIntensity;
  late Animation<double> _glowSize;

  @override
  void initState() {
    super.initState();

    // Spinning ring for header + hero card rotating border
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Breathing glow for ambient orbs + hero card
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    final curve = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );
    _glowIntensity = Tween<double>(begin: 0.3, end: 0.55).animate(curve);
    _glowSize = Tween<double>(begin: 15.0, end: 30.0).animate(curve);
  }

  @override
  void dispose() {
    _ringController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Semantics(
        label: 'مركز ${AIIdentity.name} الذكي',
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Ambient glow orbs (fixed behind scroll content)
              _buildAmbientOrbs(themeColors),

              // Scrollable content
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildHeader(themeColors),
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: MessageWidget(screenPath: '/ai-hub'),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: _buildBentoGrid(themeColors),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child:
                        SizedBox(height: PersistentBottomNav.totalHeight),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Ambient Glow Orbs ──────────────────────────────────────────────

  Widget _buildAmbientOrbs(ThemeColors themeColors) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        final intensity = _glowIntensity.value;
        return Stack(
          children: [
            // Top-right: primary orb
            Positioned(
              top: -60,
              right: -80,
              child: _buildOrb(
                size: 250,
                color: themeColors.primary,
                opacity: intensity * 0.3,
              ),
            ),
            // Center-left: accent orb
            Positioned(
              top: 280,
              left: -100,
              child: _buildOrb(
                size: 300,
                color: themeColors.accent,
                opacity: intensity * 0.2,
              ),
            ),
            // Bottom-right: primaryLight orb
            Positioned(
              bottom: 100,
              right: -60,
              child: _buildOrb(
                size: 220,
                color: themeColors.primaryLight,
                opacity: intensity * 0.25,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrb({
    required double size,
    required Color color,
    required double opacity,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: opacity * 0.3),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  // ── Animated Hero Header ─────────────────────────────────────────

  Widget _buildHeader(ThemeColors themeColors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        children: [
          // Spinning ring avatar — bigger with glow
          AnimatedBuilder(
            animation: Listenable.merge([_ringController, _glowController]),
            builder: (context, child) {
              return Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      themeColors.primary,
                      themeColors.accent,
                      themeColors.primaryLight,
                      themeColors.primary,
                    ],
                    transform: GradientRotation(
                      _ringController.value * 2 * pi,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: themeColors.primary
                          .withValues(alpha: _glowIntensity.value * 0.5),
                      blurRadius: _glowSize.value,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: themeColors.accent
                          .withValues(alpha: _glowIntensity.value * 0.2),
                      blurRadius: _glowSize.value * 2,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: themeColors.primaryGradient,
                    ),
                    child: const Icon(
                      Icons.smart_toy_rounded,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),

          // Solid white title with shadow for WCAG2 contrast
          Text(
            AIIdentity.name,
            style: AppTypography.headlineSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 12,
                ),
                Shadow(
                  color: themeColors.primary.withValues(alpha: 0.4),
                  blurRadius: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'مساعدك الذكي في صلة الرحم',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: AppAnimations.slow)
        .scale(
          begin: const Offset(0.85, 0.85),
          end: const Offset(1, 1),
          duration: AppAnimations.dramatic,
          curve: AppAnimations.overshootCurve,
        );
  }

  // ── Bento Grid ───────────────────────────────────────────────────

  Widget _buildBentoGrid(ThemeColors themeColors) {
    return Column(
      children: [
        // Row 1: Hero المستشار (full width)
        SizedBox(
          height: 180,
          child: _buildHeroCard(themeColors: themeColors),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Row 2: الرسائل + سيناريوهات
        SizedBox(
          height: 100,
          child: Row(
            children: [
              Expanded(
                child: _buildFeatureCard(
                  icon: Icons.edit_note_rounded,
                  title: 'الرسائل',
                  subtitle: 'كتابة رسائل مميزة',
                  color1: const Color(0xFF1565C0),
                  color2: const Color(0xFF42A5F5),
                  patternType: _PatternType.diagonalLines,
                  featureId: FeatureIds.messageComposer,
                  route: 'messages',
                  delay: 100,
                  themeColors: themeColors,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildFeatureCard(
                  icon: Icons.psychology_rounded,
                  title: 'سيناريوهات',
                  subtitle: 'محادثات صعبة',
                  color1: const Color(0xFF7B1FA2),
                  color2: const Color(0xFFCE93D8),
                  patternType: _PatternType.overlappingFrames,
                  featureId: FeatureIds.communicationScripts,
                  route: 'scripts',
                  delay: 200,
                  themeColors: themeColors,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Row 3: تحليل العلاقات + التقرير
        SizedBox(
          height: 100,
          child: Row(
            children: [
              Expanded(
                child: _buildFeatureCard(
                  icon: Icons.favorite_rounded,
                  title: 'تحليل العلاقات',
                  subtitle: 'نصائح ذكية',
                  color1: const Color(0xFFC2185B),
                  color2: const Color(0xFFF48FB1),
                  patternType: _PatternType.connectedDots,
                  featureId: FeatureIds.relationshipAnalysis,
                  route: 'analysis',
                  delay: 300,
                  themeColors: themeColors,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildFeatureCard(
                  icon: Icons.analytics_rounded,
                  title: 'التقرير',
                  subtitle: 'ملخص أسبوعي',
                  color1: const Color(0xFF00695C),
                  color2: const Color(0xFF4DB6AC),
                  patternType: _PatternType.ascendingBars,
                  featureId: FeatureIds.weeklyReports,
                  route: 'report',
                  delay: 400,
                  themeColors: themeColors,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Hero Card (المستشار) — Rotating Border + Neon Glow ──────────

  Widget _buildHeroCard({required ThemeColors themeColors}) {
    final hasAccess = ref.watch(featureAccessProvider(FeatureIds.aiChat));
    final color1 = themeColors.primary;
    final color2 = themeColors.primaryLight;

    Widget card = AnimatedBuilder(
      animation: Listenable.merge([_ringController, _glowController]),
      builder: (context, _) {
        return GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            _navigateWithGate(
                'counselor', FeatureIds.aiChat, themeColors);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              // Rotating SweepGradient = animated border
              gradient: SweepGradient(
                colors: [
                  color1,
                  themeColors.accent,
                  color2,
                  color1,
                ],
                transform: GradientRotation(
                  _ringController.value * 2 * pi,
                ),
              ),
              // 3-layer neon glow
              boxShadow: [
                BoxShadow(
                  color: color1
                      .withValues(alpha: _glowIntensity.value * 0.6),
                  blurRadius: 10,
                ),
                BoxShadow(
                  color: color1
                      .withValues(alpha: _glowIntensity.value * 0.3),
                  blurRadius: _glowSize.value,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: color1
                      .withValues(alpha: _glowIntensity.value * 0.15),
                  blurRadius: _glowSize.value * 2,
                  spreadRadius: 8,
                ),
              ],
            ),
            // Inner container — the "border width" is the margin
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color1.withValues(alpha: 0.4),
                    color1.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  children: [
                    // Bold pattern + shimmer (effects layer only)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _DramaticPatternPainter(
                          type: _PatternType.concentricCircles,
                          color: color2,
                        ),
                      ),
                    ),

                    // Content (on top — untouched by effects)
                    Center(
                      child: Padding(
                        padding:
                            const EdgeInsets.all(AppSpacing.md),
                        child: Opacity(
                          opacity: hasAccess ? 1.0 : 0.6,
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              // Icon with 3-layer glow halo
                              Container(
                                padding:
                                    const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [color1, color2],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color1.withValues(
                                          alpha: 0.6),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                    BoxShadow(
                                      color: color1.withValues(
                                          alpha: 0.3),
                                      blurRadius: 25,
                                      spreadRadius: 5,
                                    ),
                                    BoxShadow(
                                      color: color1.withValues(
                                          alpha: 0.15),
                                      blurRadius: 40,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons
                                      .chat_bubble_outline_rounded,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                              const SizedBox(
                                  height: AppSpacing.md),

                              // Title with text shadow
                              Text(
                                'المستشار',
                                style: AppTypography
                                    .titleLarge
                                    .copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.6),
                                      blurRadius: 12,
                                    ),
                                    Shadow(
                                      color: color1
                                          .withValues(alpha: 0.5),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'نصائح عائلية',
                                style: AppTypography.bodySmall
                                    .copyWith(
                                  color: Colors.white
                                      .withValues(alpha: 0.85),
                                  shadows: [
                                    Shadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.5),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    if (!hasAccess)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _buildPremiumBadge(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    // Entry animation (no shimmer on whole card — text stays on top)
    return card
        .animate()
        .fadeIn(duration: AppAnimations.slow)
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          duration: AppAnimations.dramatic,
          curve: AppAnimations.overshootCurve,
        );
  }

  // ── Feature Card — Deep Gradient + Neon Glow + Bold Pattern ─────

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color1,
    required Color color2,
    required _PatternType patternType,
    required String featureId,
    required String route,
    required int delay,
    required ThemeColors themeColors,
  }) {
    final hasAccess = ref.watch(featureAccessProvider(featureId));

    Widget card = GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _navigateWithGate(route, featureId, themeColors);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color1.withValues(alpha: 0.35),
              color1.withValues(alpha: 0.1),
              Colors.black.withValues(alpha: 0.8),
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
          border: Border.all(
            color: color1.withValues(alpha: 0.35),
            width: 1.5,
          ),
          // 2-layer neon glow shadow
          boxShadow: [
            BoxShadow(
              color: color1.withValues(alpha: 0.25),
              blurRadius: 12,
            ),
            BoxShadow(
              color: color1.withValues(alpha: 0.1),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Pattern + shimmer (effects layer only — text stays above)
              Positioned.fill(
                child: CustomPaint(
                  painter: _DramaticPatternPainter(
                    type: patternType,
                    color: color2,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(
                      delay: Duration(milliseconds: 3000 + delay * 4),
                      duration: 1500.ms,
                      color: color1.withValues(alpha: 0.12),
                    ),
              ),

              // Dark scrim for text readability
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.centerStart,
                      end: AlignmentDirectional.centerEnd,
                      colors: [
                        Colors.black.withValues(alpha: 0.45),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Content (on top of everything)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 4,
                  vertical: AppSpacing.sm,
                ),
                child: Opacity(
                  opacity: hasAccess ? 1.0 : 0.6,
                  child: Row(
                    children: [
                      // Icon with glow halo
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [color1, color2],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color1.withValues(alpha: 0.5),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                            BoxShadow(
                              color: color1.withValues(alpha: 0.2),
                              blurRadius: 20,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),

                      // Title with text shadow (no gradient mask)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style:
                                  AppTypography.titleSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                shadows: [
                                  Shadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.7),
                                    blurRadius: 10,
                                  ),
                                  Shadow(
                                    color: color1
                                        .withValues(alpha: 0.4),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              subtitle,
                              style:
                                  AppTypography.labelSmall.copyWith(
                                color: Colors.white
                                    .withValues(alpha: 0.8),
                                shadows: [
                                  Shadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.6),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (!hasAccess)
                Positioned(
                  top: 4,
                  left: 4,
                  child: _buildPremiumBadge(),
                ),
            ],
          ),
        ),
      ),
    );

    // Entry animation
    return card
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: AppAnimations.normal)
        .slideX(
          begin: 0.15,
          end: 0,
          duration: AppAnimations.slow,
          curve: AppAnimations.overshootCurve,
        );
  }

  // ── Premium Badge ─────────────────────────────────────────────────

  Widget _buildPremiumBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.premiumGold, AppColors.premiumGoldDark],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.premiumGold.withValues(alpha: 0.5),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock, size: 10, color: Colors.black87),
          const SizedBox(width: 3),
          Text(
            'MAX',
            style: AppTypography.labelSmall.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  // ── Navigation Helpers ────────────────────────────────────────────

  void _navigateWithGate(
    String feature,
    String featureId,
    ThemeColors themeColors,
  ) {
    final hasAccess = ref.read(featureAccessProvider(featureId));

    if (hasAccess) {
      _navigateToFeature(feature, themeColors);
    } else {
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
      case 'messages':
        context.push(AppRoutes.aiMessages);
      case 'scripts':
        context.push(AppRoutes.aiScripts);
      case 'analysis':
        context.push(AppRoutes.aiAnalysis);
      case 'report':
        context.push(AppRoutes.aiReport);
      default:
        UIHelpers.showSnackBar(
          context,
          'قريباً: $feature',
          backgroundColor: themeColors.primary,
        );
    }
  }
}

// ── Pattern Types ──────────────────────────────────────────────────

enum _PatternType {
  concentricCircles,
  diagonalLines,
  overlappingFrames,
  connectedDots,
  ascendingBars,
}

// ── Dramatic Pattern Painter ───────────────────────────────────────
//
// Bold, visible patterns with filled shapes, glow effects, and
// higher alpha values (0.10-0.30) than the original subtle strokes.

class _DramaticPatternPainter extends CustomPainter {
  final _PatternType type;
  final Color color;

  const _DramaticPatternPainter({
    required this.type,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case _PatternType.concentricCircles:
        _paintConcentricCircles(canvas, size);
      case _PatternType.diagonalLines:
        _paintDiagonalLines(canvas, size);
      case _PatternType.overlappingFrames:
        _paintOverlappingFrames(canvas, size);
      case _PatternType.connectedDots:
        _paintConnectedDots(canvas, size);
      case _PatternType.ascendingBars:
        _paintAscendingBars(canvas, size);
    }
  }

  void _paintConcentricCircles(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.8, size.height * 0.2);

    // Filled concentric circles with decreasing opacity
    for (var i = 6; i >= 1; i--) {
      canvas.drawCircle(
        center,
        i * 22.0,
        Paint()
          ..color = color.withValues(alpha: 0.04 + (6 - i) * 0.015)
          ..style = PaintingStyle.fill,
      );
    }

    // Stroke rings on top
    final strokePaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var i = 1; i <= 6; i++) {
      canvas.drawCircle(center, i * 22.0, strokePaint);
    }

    // Glowing center dot
    canvas.drawCircle(
      center,
      6,
      Paint()
        ..color = color.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  void _paintDiagonalLines(Canvas canvas, Size size) {
    for (var i = 0; i < 8; i++) {
      final offset = i * 18.0;
      final paint = Paint()
        ..color = color.withValues(alpha: 0.08 + i * 0.012)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      // Add blur to alternating lines
      if (i.isEven) {
        paint.maskFilter =
            const MaskFilter.blur(BlurStyle.normal, 2);
      }

      canvas.drawLine(
        Offset(-offset, size.height + offset),
        Offset(size.width - offset, offset),
        paint,
      );
    }
  }

  void _paintOverlappingFrames(Canvas canvas, Size size) {
    for (var i = 0; i < 4; i++) {
      final shift = i * 10.0;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.5 + shift,
          size.height * 0.3 + shift,
          size.width * 0.4,
          size.height * 0.5,
        ),
        const Radius.circular(8),
      );

      // Fill
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = color.withValues(alpha: 0.03 + i * 0.012)
          ..style = PaintingStyle.fill,
      );

      // Stroke
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = color.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  void _paintConnectedDots(Canvas canvas, Size size) {
    final points = [
      Offset(size.width * 0.65, size.height * 0.15),
      Offset(size.width * 0.9, size.height * 0.1),
      Offset(size.width * 0.85, size.height * 0.4),
      Offset(size.width * 0.6, size.height * 0.5),
      Offset(size.width * 0.75, size.height * 0.7),
      Offset(size.width * 0.95, size.height * 0.65),
    ];

    // Connection lines
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], linePaint);
    }
    // Cross-links
    canvas.drawLine(points[0], points[3], linePaint);
    canvas.drawLine(points[1], points[4], linePaint);

    // Glowing dots
    for (final p in points) {
      // Outer glow
      canvas.drawCircle(
        p,
        5,
        Paint()
          ..color = color.withValues(alpha: 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      // Core dot
      canvas.drawCircle(
        p,
        3,
        Paint()
          ..color = color.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _paintAscendingBars(Canvas canvas, Size size) {
    for (var i = 0; i < 7; i++) {
      final barHeight = (i + 1) * size.height * 0.1;
      final x = size.width * 0.5 + i * 16.0;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - barHeight - 4, 10, barHeight),
        const Radius.circular(4),
      );

      // Fill
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = color.withValues(alpha: 0.06 + i * 0.015)
          ..style = PaintingStyle.fill,
      );

      // Stroke
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = color.withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DramaticPatternPainter old) =>
      old.type != type || old.color != color;
}
