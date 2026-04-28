import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ai/deepseek_ai_service.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/ai_generated_badge.dart';
import '../../../shared/widgets/share_bottom_sheet.dart';
import '../../../shared/widgets/share_cards/wrapped_share_card.dart';
import '../../../shared/widgets/shareable_card_generator.dart';
import '../../family_tree/providers/family_graph_providers.dart';
import '../models/monthly_wrapped_model.dart';
import '../providers/wrapped_providers.dart';
import '../widgets/animated_counter.dart';
import '../widgets/aurora_background.dart';
import '../widgets/interaction_ring_chart.dart';
import '../widgets/particle_background.dart';

/// Full-screen immersive story experience for monthly family connection stats.
///
/// Features: animated counters, particle backgrounds, ring charts,
/// confetti celebrations, and tap-to-navigate story flow.
class MonthlyWrappedScreen extends ConsumerStatefulWidget {
  final DateTime? month;

  const MonthlyWrappedScreen({super.key, this.month});

  @override
  ConsumerState<MonthlyWrappedScreen> createState() =>
      _MonthlyWrappedScreenState();
}

class _MonthlyWrappedScreenState extends ConsumerState<MonthlyWrappedScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    // initialPage: 0 explicit. Without this, PageController defaults to 0
    // anyway, but being explicit guards against subclassing or future Flutter
    // changes. The Directionality.ltr wrapper around the PageView itself
    // (further down the tree) ensures page index 0 always renders first
    // regardless of the surrounding Arabic RTL UI.
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  static DateTime _previousMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month - 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    final targetMonth = widget.month ?? _previousMonth();
    final wrappedAsync = ref.watch(monthlyWrappedProvider(targetMonth));
    final themeColors = ref.watch(themeColorsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(gradient: themeColors.backgroundGradient),
        child: wrappedAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: themeColors.primary),
          ),
          error: (error, _) => SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('😔', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    Text(
                      'حدث خطأ أثناء تحميل الملخص',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'رجوع',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          data: (wrapped) => _WrappedStoryContent(
            wrapped: wrapped,
            themeColors: themeColors,
            pageController: _pageController,
            currentPage: _currentPage,
            totalPages: _totalPages,
            onPageChanged: (page, total) {
              setState(() {
                _currentPage = page;
                _totalPages = total;
              });
            },
          ),
        ),
      ),
    );
  }
}

/// Main story content with immersive page layouts.
class _WrappedStoryContent extends StatefulWidget {
  final MonthlyWrapped wrapped;
  final ThemeColors themeColors;
  final PageController pageController;
  final int currentPage;
  final int totalPages;
  final void Function(int page, int total) onPageChanged;

  const _WrappedStoryContent({
    required this.wrapped,
    required this.themeColors,
    required this.pageController,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  State<_WrappedStoryContent> createState() => _WrappedStoryContentState();
}

class _WrappedStoryContentState extends State<_WrappedStoryContent> {
  late final List<Widget> _pages;
  late final ConfettiController _confettiController;
  bool _confettiFired = false;
  int _personalityPageIndex = -1;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _pages = _buildPages();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onPageChanged(0, _pages.length);
      HapticFeedback.mediumImpact();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (page < 0 || page >= _pages.length) return;
    widget.pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    HapticFeedback.selectionClick();
  }

  void _onTap(TapUpDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tapX = details.globalPosition.dx;
    // RTL: tap left side = next, tap right side = previous
    if (tapX < screenWidth * 0.3) {
      _goToPage(widget.currentPage + 1);
    } else if (tapX > screenWidth * 0.7) {
      _goToPage(widget.currentPage - 1);
    }
  }

  void _onPageChanged(int page) {
    widget.onPageChanged(page, _pages.length);
    HapticFeedback.lightImpact();

    // Fire confetti on personality page (once)
    if (page == _personalityPageIndex && !_confettiFired) {
      _confettiFired = true;
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _confettiController.play();
          HapticFeedback.heavyImpact();
        }
      });
    }
  }

  /// Per-page accent color — fully theme-aware.
  Color _pageMoodColor(int page) {
    final c = widget.themeColors;
    if (page == 0) return c.primary;
    if (page == _personalityPageIndex) return c.accent;
    if (page == _pages.length - 1) return c.secondary;
    final moods = [c.moodExcited, c.statusSuccess, c.moodHappy, c.statusInfo];
    return moods[(page - 1) % moods.length];
  }

  /// 4 rich, saturated mesh gradient colors derived from theme for the current page.
  /// Uses hue shifts to create visible contrast between vertices so the fluid
  /// motion is actually perceptible.
  List<Color> _meshColorsForPage(int page) {
    final c = widget.themeColors;
    final mood = _pageMoodColor(page);
    return [
      _toMeshColor(mood, 0.0, 0.38),
      _toMeshColor(c.primary, 35.0, 0.28),
      _toMeshColor(c.accent, -25.0, 0.22),
      _toMeshColor(c.secondary, 55.0, 0.32),
    ];
  }

  /// Converts a color to a rich mesh gradient variant with optional hue shift.
  static Color _toMeshColor(Color c, double hueShift, double lightness) {
    final hsl = HSLColor.fromColor(c);
    return HSLColor.fromAHSL(
      1.0,
      (hsl.hue + hueShift) % 360,
      (hsl.saturation * 1.3).clamp(0.4, 1.0),
      lightness,
    ).toColor();
  }

  String _getMotivationalMessage() {
    final coverage = widget.wrapped.relativesCoverage;
    if (coverage >= 0.8) return 'ما شاء الله! تواصلك مع عائلتك ممتاز';
    if (coverage >= 0.5) return 'أحسنت! استمر في التواصل مع أقاربك';
    if (coverage >= 0.2) return 'بداية طيبة، حاول تتواصل مع أقارب أكثر';
    return 'الشهر الجاي بإذن الله أفضل';
  }

  /// Wraps a page widget in a Stack with decorative accent blobs.
  Widget _withAccents(Widget page, List<_AccentBlob> blobs) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        ...blobs,
        Positioned.fill(child: page),
      ],
    );
  }

  List<Widget> _buildPages() {
    final w = widget.wrapped;
    final colors = widget.themeColors;
    final pages = <Widget>[];

    // Page 0: Month intro
    pages.add(_withAccents(
      _buildIntroPage(w, colors),
      [
        _AccentBlob(
            top: -60, left: -40, size: 280, color: colors.primary, alpha: 0.2),
        _AccentBlob(
            top: 500,
            right: -50,
            size: 200,
            color: colors.accent,
            alpha: 0.15),
      ],
    ));

    // Page 1: Stats overview
    pages.add(_withAccents(
      _buildStatsPage(w, colors),
      [
        _AccentBlob(top: -40, right: -60, size: 260, color: colors.moodExcited),
        _AccentBlob(
            top: 400,
            left: -80,
            size: 180,
            color: colors.primary,
            alpha: 0.15),
      ],
    ));

    // Page 2: Most contacted (conditional)
    if (w.mostContactedRelativeName != null) {
      pages.add(_withAccents(
        _buildMostContactedPage(w, colors),
        [
          _AccentBlob(top: -60, left: -40, size: 220, color: colors.statusSuccess),
          _AccentBlob(
              top: 500,
              right: -50,
              size: 200,
              color: colors.moodHappy,
              alpha: 0.15),
        ],
      ));
    }

    // Page 3: Interaction ring chart (conditional)
    if (w.interactionBreakdown.isNotEmpty) {
      pages.add(_withAccents(
        _buildRingChartPage(w, colors),
        [
          _AccentBlob(
              top: -40,
              left: -50,
              size: 240,
              color: colors.accent,
              alpha: 0.2),
          _AccentBlob(
              top: 500,
              right: -40,
              size: 200,
              color: colors.primary,
              alpha: 0.15),
        ],
      ));
    }

    // Page 4: Personality reveal (with confetti)
    _personalityPageIndex = pages.length;
    pages.add(_withAccents(
      _buildPersonalityPage(w, colors),
      [
        _AccentBlob(
            top: -50,
            left: -50,
            size: 280,
            color: colors.accent,
            alpha: 0.3),
        _AccentBlob(
            top: 450,
            right: -70,
            size: 220,
            color: colors.primary,
            alpha: 0.2),
      ],
    ));

    // Page 5: Family stats + Share
    pages.add(_withAccents(
      _SharePage(wrapped: w),
      [
        _AccentBlob(
            top: -40,
            left: -60,
            size: 240,
            color: colors.secondary,
            alpha: 0.2),
        _AccentBlob(
            top: 400,
            right: -50,
            size: 200,
            color: colors.primary,
            alpha: 0.15),
      ],
    ));

    return pages;
  }

  // ── Page 0: Month Intro ──

  Widget _buildIntroPage(MonthlyWrapped w, ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 3),

          // Month name pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              'شهر ${w.arabicMonthName}',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          )
              .animate()
              .scale(
                begin: const Offset(2, 2),
                end: const Offset(1, 1),
                duration: 700.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 24),

          Text(
            'ملخص تواصلك',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          )
              .animate()
              .fadeIn(delay: 400.ms, duration: 400.ms)
              .slideY(
                begin: 0.3,
                end: 0,
                delay: 400.ms,
                duration: 400.ms,
                curve: Curves.easeOut,
              ),

          const SizedBox(height: 12),

          Text(
            _getMotivationalMessage(),
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ).animate().fadeIn(delay: 700.ms, duration: 400.ms),

          const Spacer(flex: 4),
        ],
      ),
    );
  }

  // ── Page 1: Stats Overview ──

  Widget _buildStatsPage(MonthlyWrapped w, ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 3),

          // Large animated total
          _BreathingGlowCircle(
            color: colors.primary,
            child: const Text('📱', style: TextStyle(fontSize: 56)),
          )
              .animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 20),

          AnimatedCounter(
            targetValue: w.totalInteractions,
            delay: 300.ms,
            style: GoogleFonts.cairo(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
            ),
          ),

          Text(
            'تفاعل هذا الشهر',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

          const SizedBox(height: 32),

          // 2x2 stats grid
          _buildStatsGrid(w, colors),

          const Spacer(flex: 4),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(MonthlyWrapped w, ThemeColors colors) {
    final stats = <_StatData>[
      _StatData('${w.uniqueRelativesContacted}', 'قريب', '👥'),
      _StatData(
          '${(w.relativesCoverage * 100).round()}%', 'تغطية', '📊'),
      if (w.longestStreak > 0)
        _StatData('${w.longestStreak}', 'أيام متتالية', '🔥'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                children: [
                  Text(stats[i].emoji,
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 2),
                  Text(
                    stats[i].value,
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    stats[i].label,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(
                  delay: Duration(milliseconds: 500 + (i * 100)),
                  duration: 400.ms,
                ),
          ),
        ],
      ],
    );
  }

  // ── Page 2: Most Contacted ──

  Widget _buildMostContactedPage(MonthlyWrapped w, ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 3),

          const Text('🏆', style: TextStyle(fontSize: 56))
              .animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 16),

          Text(
            'الأكثر تواصلاً',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

          const SizedBox(height: 20),

          // Glass card with name
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primary.withValues(alpha: 0.25),
                  colors.accent.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                const Text('❤️', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                Text(
                  w.mostContactedRelativeName!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedCounter(
                  targetValue: w.mostContactedRelativeCount ?? 0,
                  delay: 600.ms,
                  duration: const Duration(milliseconds: 800),
                  suffix: ' تفاعل',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: 400.ms, duration: 500.ms)
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.0, 1.0),
                delay: 400.ms,
                duration: 500.ms,
                curve: Curves.easeOut,
              ),

          const Spacer(flex: 4),
        ],
      ),
    );
  }

  // ── Page 3: Interaction Ring Chart ──

  Widget _buildRingChartPage(MonthlyWrapped w, ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          Text(
            'أنواع تواصلك',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 24),

          InteractionRingChart(
            breakdown: w.interactionBreakdown,
            themeColors: colors,
            animationDelay: 300.ms,
          ),

          const Spacer(flex: 3),
        ],
      ),
    );
  }

  // ── Page 4: Personality Reveal ──

  Widget _buildPersonalityPage(MonthlyWrapped w, ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 3),

          _BreathingGlowCircle(
            color: colors.primary,
            size: 140,
            child: Text(
              w.effectivePersonalityEmoji,
              style: const TextStyle(fontSize: 80),
            ),
          )
              .animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 24),

          Text(
            w.effectivePersonalityLabel,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
            ),
          )
              .animate()
              .fadeIn(delay: 400.ms, duration: 500.ms)
              .slideY(
                begin: 0.15,
                end: 0,
                delay: 400.ms,
                duration: 500.ms,
                curve: Curves.easeOut,
              ),

          const SizedBox(height: 6),
          const AIGeneratedBadge(color: Colors.white)
              .animate()
              .fadeIn(delay: 600.ms, duration: 400.ms),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Text(
              'هذا أسلوبك في صلة الرحم',
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

          const Spacer(flex: 4),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final moodColor = _pageMoodColor(widget.currentPage);
    final meshColors = _meshColorsForPage(widget.currentPage);

    return Stack(
      children: [
        // Layer 1: Fluid mesh gradient background (shader-based, per-page colors)
        AuroraBackground(colors: meshColors),

        // Layer 2: Particle sparkle (per-page color)
        ParticleBackground(
          particleColor: moodColor,
        ),

        // Layer 3: Content
        SafeArea(
          child: Column(
            children: [
              // Progress bar with glow
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    Row(
                      children: List.generate(_pages.length, (index) {
                        final isActive = index <= widget.currentPage;
                        final isCurrent = index == widget.currentPage;
                        return Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            height: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.3),
                              boxShadow: isCurrent
                                  ? [
                                      BoxShadow(
                                        color:
                                            Colors.white.withValues(alpha: 0.6),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      }),
                    ).animate().fadeIn(duration: 300.ms),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Story pages with tap navigation. Wrapped in Directionality.ltr
              // so page index 0 always renders first regardless of the
              // surrounding Arabic RTL UI. Each page's CONTENT remains RTL
              // because individual page widgets use the app's global
              // Directionality (rtl) by default — only the PageView's
              // index→pixel-direction mapping is forced LTR here.
              Expanded(
                child: GestureDetector(
                  onTapUp: _onTap,
                  behavior: HitTestBehavior.translucent,
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: PageView(
                      controller: widget.pageController,
                      onPageChanged: _onPageChanged,
                      children: _pages,
                    ),
                  ),
                ),
              ),

              // Swipe hint
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  widget.currentPage < _pages.length - 1
                      ? 'اسحب للمتابعة ←'
                      : '',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms, duration: 400.ms),
            ],
          ),
        ),

        // Layer 4: Confetti overlay
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 30,
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            gravity: 0.2,
            colors: [
              widget.themeColors.primary,
              widget.themeColors.accent,
              widget.themeColors.secondary,
              widget.themeColors.moodExcited,
              widget.themeColors.moodHappy,
            ],
          ),
        ),
      ],
    );
  }
}

// ── Share Page (ConsumerWidget for ref access) ──

class _SharePage extends ConsumerWidget {
  final MonthlyWrapped wrapped;

  const _SharePage({required this.wrapped});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    // Check if user is in a family group
    final groupInfo = ref.watch(userFamilyGroupProvider).valueOrNull;
    final familyStatsAsync = groupInfo != null
        ? ref.watch(familyMonthlyWrappedProvider((
            month: wrapped.month,
            groupId: groupInfo.groupId,
          )))
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // Summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Text(
                  wrapped.effectivePersonalityEmoji,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 8),
                Text(
                  wrapped.effectivePersonalityLabel,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ملخص شهر ${wrapped.arabicMonthName}',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _MiniStat(
                      value: '${wrapped.totalInteractions}',
                      label: 'تفاعل',
                    ),
                    _MiniStat(
                      value: '${wrapped.uniqueRelativesContacted}',
                      label: 'قريب',
                    ),
                    if (wrapped.longestStreak > 0)
                      _MiniStat(
                        value: '${wrapped.longestStreak}',
                        label: 'أيام متتالية',
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Second stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _MiniStat(
                      value:
                          '${(wrapped.relativesCoverage * 100).round()}٪',
                      label: 'تغطية',
                    ),
                    if (wrapped.mostUsedInteractionType != null)
                      _MiniStat(
                        value: wrapped.mostUsedInteractionType!.arabicName,
                        label: 'أكثر نوع تواصل',
                      ),
                    if (wrapped.mostContactedRelativeName != null)
                      _MiniStat(
                        value: wrapped.mostContactedRelativeName!,
                        label: 'الأكثر تواصلاً',
                      ),
                  ],
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1, 1),
                duration: 500.ms,
                curve: Curves.easeOut,
              ),

          // Family stats (compact, if available)
          if (familyStatsAsync != null)
            familyStatsAsync.when(
              data: (familyStats) {
                if (familyStats == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _buildFamilyStatsCard(familyStats, themeColors),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),

          const SizedBox(height: 24),

          // Share button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _shareWrapped(context, themeColors, ref),
              icon: Icon(Icons.share, color: themeColors.primary),
              label: Text(
                'شارك ملخصك',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: themeColors.primary,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: themeColors.primary.withValues(alpha: 0.3),
              ),
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildFamilyStatsCard(
      FamilyWrappedStats stats, ThemeColors themeColors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeColors.primaryDark.withValues(alpha: 0.3),
            themeColors.accent.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeColors.primaryDark.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('👨‍👩‍👧‍👦', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'ملخص العائلة',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MiniStat(
                value: '${stats.totalFamilyInteractions}',
                label: 'تفاعل عائلي',
              ),
              _MiniStat(
                value: '${stats.familyMembersActive}',
                label: 'أعضاء نشطين',
              ),
            ],
          ),
          if (stats.topContributorName != null) ...[
            const SizedBox(height: 8),
            Text(
              '🌟 الأكثر نشاطاً: ${stats.topContributorName}',
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }

  void _shareWrapped(
      BuildContext context, ThemeColors themeColors, WidgetRef ref) {
    final isMax = ref.read(isMaxProvider);
    ShareBottomSheet.show(
      context,
      cardBuilder: (format, {String? aiCopy}) => WrappedShareCard(
        format: format,
        personalityEmoji: wrapped.effectivePersonalityEmoji,
        personalityLabel: wrapped.effectivePersonalityLabel,
        periodName: wrapped.arabicMonthName,
        totalInteractions: wrapped.totalInteractions,
        uniqueRelatives: wrapped.uniqueRelativesContacted,
        longestStreak: wrapped.longestStreak,
        coveragePercent: (wrapped.relativesCoverage * 100).round(),
        mostUsedTypeLabel: wrapped.mostUsedInteractionType?.arabicName,
        copyText: aiCopy,
      ),
      shareText: ShareableCardData.wrapped(
        periodName: wrapped.arabicMonthName,
        personalityEmoji: wrapped.effectivePersonalityEmoji,
        personalityLabel: wrapped.effectivePersonalityLabel,
        totalInteractions: wrapped.totalInteractions,
        uniqueRelatives: wrapped.uniqueRelativesContacted,
      ).shareText,
      aiCopyFuture: isMax
          ? DeepSeekAIService().generateShareCopy(
              cardType: 'wrapped',
              context: {
                'periodName': wrapped.arabicMonthName,
                'personalityLabel': wrapped.personalityLabel,
                'totalInteractions': wrapped.totalInteractions,
              },
            )
          : null,
    );
  }
}

// ── Shared widgets ──

/// Glowing circle that breathes infinitely (scale + shadow pulse).
class _BreathingGlowCircle extends StatefulWidget {
  final Color color;
  final Widget child;
  final double size;

  const _BreathingGlowCircle({
    required this.color,
    required this.child,
    this.size = 120,
  });

  @override
  State<_BreathingGlowCircle> createState() => _BreathingGlowCircleState();
}

class _BreathingGlowCircleState extends State<_BreathingGlowCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 0.25, end: 0.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.color.withValues(alpha: 0.3),
                  widget.color.withValues(alpha: 0.1),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: _glowAnimation.value),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Center(child: widget.child),
          ),
        );
      },
    );
  }
}

/// Small stat display for summary cards.
class _MiniStat extends StatelessWidget {
  final String value;
  final String label;

  const _MiniStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

/// Positioned radial gradient blob for per-page visual drama.
class _AccentBlob extends StatelessWidget {
  final double top;
  final double? left;
  final double? right;
  final double size;
  final Color color;
  final double alpha;

  const _AccentBlob({
    required this.top,
    this.left,
    this.right,
    required this.size,
    required this.color,
    this.alpha = 0.25,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(
            end: 1.2,
            duration: Duration(milliseconds: 3000 + (size * 8).toInt()),
            curve: Curves.easeInOut,
          ),
    );
  }
}

/// Internal data for a stat tile.
class _StatData {
  final String value;
  final String label;
  final String emoji;

  const _StatData(this.value, this.label, this.emoji);
}
