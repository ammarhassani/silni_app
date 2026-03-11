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
import '../../../shared/widgets/share_bottom_sheet.dart';
import '../../../shared/widgets/share_cards/wrapped_share_card.dart';
import '../../../shared/widgets/shareable_card_generator.dart';
import '../../widgets/home_widget_service.dart';
import '../models/monthly_wrapped_model.dart';
import '../models/yearly_wrapped_model.dart';
import '../providers/wrapped_providers.dart';
import '../widgets/activity_chart.dart';
import '../widgets/animated_counter.dart';
import '../widgets/aurora_background.dart';
import '../widgets/interaction_ring_chart.dart';
import '../widgets/particle_background.dart';

// ── Arabic number-noun agreement (تمييز العدد) ──

/// يوم / أيام / يومًا
String _arabicDayWord(int count) {
  if (count >= 3 && count <= 10) return 'أيام';
  if (count % 100 == 0) return 'يوم';
  final lastTwo = count % 100;
  if (lastTwo >= 3 && lastTwo <= 10) return 'أيام';
  if (lastTwo >= 11) return 'يومًا';
  return 'يوم';
}

/// مرة / مرات / مرةً
String _arabicTimesWord(int count) {
  if (count >= 3 && count <= 10) return 'مرات';
  if (count % 100 == 0) return 'مرة';
  final lastTwo = count % 100;
  if (lastTwo >= 3 && lastTwo <= 10) return 'مرات';
  if (lastTwo >= 11) return 'مرةً';
  return 'مرة';
}

/// تفاعل / تفاعلات / تفاعلًا
String _arabicInteractionWord(int count) {
  if (count >= 3 && count <= 10) return 'تفاعلات';
  if (count % 100 == 0) return 'تفاعل';
  final lastTwo = count % 100;
  if (lastTwo >= 3 && lastTwo <= 10) return 'تفاعلات';
  if (lastTwo >= 11) return 'تفاعلًا';
  return 'تفاعل';
}

/// قريب / أقارب / قريبًا
String _arabicRelativeWord(int count) {
  if (count >= 3 && count <= 10) return 'أقارب';
  if (count % 100 == 0) return 'قريب';
  final lastTwo = count % 100;
  if (lastTwo >= 3 && lastTwo <= 10) return 'أقارب';
  if (lastTwo >= 11) return 'قريبًا';
  return 'قريب';
}

/// أيام متتالية / يوم متتالٍ / يومًا متتاليًا
String _arabicConsecutiveDaysLabel(int count) {
  if (count >= 3 && count <= 10) return 'أيام متتالية';
  if (count % 100 == 0) return 'يوم متتالٍ';
  final lastTwo = count % 100;
  if (lastTwo >= 3 && lastTwo <= 10) return 'أيام متتالية';
  if (lastTwo >= 11) return 'يومًا متتاليًا';
  return 'يوم متتالٍ';
}

/// Full-screen immersive story experience for yearly family connection stats.
///
/// Features: kinetic typography, animated counters, particle backgrounds,
/// custom charts, confetti celebrations, and tap-to-navigate story flow.
class YearlyWrappedScreen extends ConsumerStatefulWidget {
  final int year;

  const YearlyWrappedScreen({super.key, required this.year});

  @override
  ConsumerState<YearlyWrappedScreen> createState() =>
      _YearlyWrappedScreenState();
}

class _YearlyWrappedScreenState extends ConsumerState<YearlyWrappedScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wrappedAsync = ref.watch(yearlyWrappedProvider(widget.year));
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
  final YearlyWrapped wrapped;
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
    final moods = [c.moodExcited, c.statusSuccess, c.moodHappy, c.statusInfo, c.secondary];
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
    final arabicYear = HomeWidgetService.toArabicNumerals(w.year);
    final pages = <Widget>[];

    // Page 0: Year Intro — kinetic reveal
    pages.add(_withAccents(
      _buildIntroPage(arabicYear, colors),
      [
        _AccentBlob(
            top: -60, left: -40, size: 300, color: colors.primary, alpha: 0.2),
        _AccentBlob(
            top: 500,
            right: -50,
            size: 200,
            color: colors.accent,
            alpha: 0.15),
      ],
    ));

    // Page 1: Total interactions
    pages.add(_withAccents(
      _buildInteractionsPage(w, colors, arabicYear),
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

    // Page 2: Most contacted relative (conditional)
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

    // Page 3: Longest streak (conditional)
    if (w.longestStreak > 1) {
      pages.add(_withAccents(
        _buildStreakPage(w, colors),
        [
          _AccentBlob(
              top: -30, right: -40, size: 240, color: colors.moodExcited),
          _AccentBlob(
              top: 350,
              left: -60,
              size: 200,
              color: colors.moodHappy,
              alpha: 0.2),
        ],
      ));
    }

    // Page 4: Activity chart (NEW)
    if (w.monthlyTotals.isNotEmpty) {
      pages.add(_withAccents(
        _buildActivityChartPage(w, colors),
        [
          _AccentBlob(
              top: -50, right: -30, size: 220, color: colors.statusInfo, alpha: 0.2),
          _AccentBlob(
              top: 450,
              left: -60,
              size: 180,
              color: colors.primary,
              alpha: 0.15),
        ],
      ));
    }

    // Page 5: Interaction ring chart (NEW)
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

    // Page 6: Personality reveal (with confetti)
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

    // Page 7: Share
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

  // ── Page 0: Year Intro ──

  Widget _buildIntroPage(String arabicYear, ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 3),

          // Year number — kinetic reveal
          Text(
            arabicYear,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 96,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.0,
            ),
          )
              .animate()
              .scale(
                begin: const Offset(3, 3),
                end: const Offset(1, 1),
                duration: 800.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 500.ms),

          const SizedBox(height: 16),

          Text(
            'ملخص سنتك',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          )
              .animate()
              .fadeIn(delay: 500.ms, duration: 400.ms)
              .slideY(
                begin: 0.3,
                end: 0,
                delay: 500.ms,
                duration: 400.ms,
                curve: Curves.easeOut,
              ),

          const SizedBox(height: 8),

          Text(
            'مع صِلني',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ).animate().fadeIn(delay: 800.ms, duration: 300.ms),

          const Spacer(flex: 4),
        ],
      ),
    );
  }

  // ── Page 1: Total Interactions ──

  Widget _buildInteractionsPage(
      YearlyWrapped w, ThemeColors colors, String arabicYear) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 3),

          _BreathingGlowCircle(
            color: colors.primary,
            child: const Text('🔥', style: TextStyle(fontSize: 64)),
          )
              .animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 24),

          Text(
            'تواصلاتك في $arabicYear',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

          const SizedBox(height: 12),

          AnimatedCounter(
            targetValue: w.totalInteractions,
            delay: 400.ms,
            style: GoogleFonts.cairo(
              fontSize: 72,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            '${_arabicTimesWord(w.totalInteractions)} تواصلت مع أقاربك هذه السنة',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

          const Spacer(flex: 4),
        ],
      ),
    );
  }

  // ── Page 2: Most Contacted ──

  Widget _buildMostContactedPage(YearlyWrapped w, ThemeColors colors) {
    final count = w.mostContactedRelativeCount ?? 0;

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
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
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
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    AnimatedCounter(
                      targetValue: count,
                      delay: 600.ms,
                      duration: const Duration(milliseconds: 800),
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_arabicInteractionWord(count)} معه هذه السنة',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
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

  // ── Page 3: Longest Streak ──

  Widget _buildStreakPage(YearlyWrapped w, ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 3),

          _BreathingGlowCircle(
            color: colors.moodExcited,
            child: const Text('🔥', style: TextStyle(fontSize: 64)),
          )
              .animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 24),

          Text(
            'أطول سلسلة تواصل',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

          const SizedBox(height: 12),

          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AnimatedCounter(
                targetValue: w.longestStreak,
                delay: 400.ms,
                style: GoogleFonts.cairo(
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  color: colors.moodExcited,
                  height: 1.1,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _arabicDayWord(w.longestStreak),
                style: GoogleFonts.cairo(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: colors.moodExcited.withValues(alpha: 0.9),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

          const SizedBox(height: 16),

          Text(
            'متواصل بدون انقطاع',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

          const Spacer(flex: 4),
        ],
      ),
    );
  }

  // ── Page 4: Activity Chart (NEW) ──

  Widget _buildActivityChartPage(YearlyWrapped w, ThemeColors colors) {
    // Find peak month
    int peakMonth = 1;
    int peakVal = 0;
    w.monthlyTotals.forEach((month, count) {
      if (count > peakVal) {
        peakVal = count;
        peakMonth = month;
      }
    });
    final peakName = MonthlyWrapped.arabicMonthNames[peakMonth];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 3),

          const Text('📊', style: TextStyle(fontSize: 48))
              .animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 12),

          Text(
            'نشاطك الشهري',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

          const SizedBox(height: 24),

          // Bar chart
          SizedBox(
            height: 200,
            child: ActivityBarChart(
              monthlyTotals: w.monthlyTotals,
              barColor: colors.primary.withValues(alpha: 0.8),
              barHighlightColor: colors.accent,
              animationDelay: 400.ms,
            ),
          ),

          const SizedBox(height: 20),

          // Peak month callout
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
              'أكثر شهر نشاطاً: $peakName',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ).animate().fadeIn(delay: 1800.ms, duration: 400.ms),

          const Spacer(flex: 4),
        ],
      ),
    );
  }

  // ── Page 5: Interaction Ring Chart (NEW) ──

  Widget _buildRingChartPage(YearlyWrapped w, ThemeColors colors) {
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

  // ── Page 6: Personality ──

  Widget _buildPersonalityPage(YearlyWrapped w, ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 3),

          // Emoji with themed glow circle
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

              // Story pages with tap navigation
              Expanded(
                child: GestureDetector(
                  onTapUp: _onTap,
                  behavior: HitTestBehavior.translucent,
                  child: PageView(
                    controller: widget.pageController,
                    onPageChanged: _onPageChanged,
                    children: _pages,
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
  final YearlyWrapped wrapped;

  const _SharePage({required this.wrapped});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final arabicYear = HomeWidgetService.toArabicNumerals(wrapped.year);

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
                  style: const TextStyle(fontSize: 56),
                ),
                const SizedBox(height: 12),
                Text(
                  wrapped.effectivePersonalityLabel,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ملخص $arabicYear',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _MiniStat(
                      value: HomeWidgetService.toArabicNumerals(
                          wrapped.totalInteractions),
                      label:
                          _arabicInteractionWord(wrapped.totalInteractions),
                    ),
                    _MiniStat(
                      value: HomeWidgetService.toArabicNumerals(
                          wrapped.uniqueRelativesContacted),
                      label: _arabicRelativeWord(
                          wrapped.uniqueRelativesContacted),
                    ),
                    if (wrapped.longestStreak > 1)
                      _MiniStat(
                        value: HomeWidgetService.toArabicNumerals(
                            wrapped.longestStreak),
                        label: _arabicConsecutiveDaysLabel(
                            wrapped.longestStreak),
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
                    _MiniStat(
                      value: HomeWidgetService.toArabicNumerals(
                          wrapped.totalActiveDays),
                      label: 'يوم نشط',
                    ),
                    if (wrapped.mostUsedInteractionType != null)
                      _MiniStat(
                        value:
                            wrapped.mostUsedInteractionType!.arabicName,
                        label: 'أكثر نوع تواصل',
                      ),
                  ],
                ),
                if (wrapped.peakMonth != null && wrapped.peakMonth! >= 1 && wrapped.peakMonth! <= 12) ...[
                  const SizedBox(height: 8),
                  Text(
                    'شهرك الأقوى: ${MonthlyWrapped.arabicMonthNames[wrapped.peakMonth!]}',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
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

          const SizedBox(height: 32),

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

  void _shareWrapped(
      BuildContext context, ThemeColors themeColors, WidgetRef ref) {
    final isMax = ref.read(isMaxProvider);
    final periodName = wrapped.year.toString();

    ShareBottomSheet.show(
      context,
      cardBuilder: (format, {String? aiCopy}) => WrappedShareCard(
        format: format,
        personalityEmoji: wrapped.effectivePersonalityEmoji,
        personalityLabel: wrapped.effectivePersonalityLabel,
        periodName: periodName,
        totalInteractions: wrapped.totalInteractions,
        uniqueRelatives: wrapped.uniqueRelativesContacted,
        longestStreak: wrapped.longestStreak,
        coveragePercent: (wrapped.relativesCoverage * 100).round(),
        mostUsedTypeLabel: wrapped.mostUsedInteractionType?.arabicName,
        totalActiveDays: wrapped.totalActiveDays,
        copyText: aiCopy,
        gradient: themeColors.primaryGradient,
      ),
      shareText: ShareableCardData.wrapped(
        periodName: periodName,
        personalityEmoji: wrapped.effectivePersonalityEmoji,
        personalityLabel: wrapped.effectivePersonalityLabel,
        totalInteractions: wrapped.totalInteractions,
        uniqueRelatives: wrapped.uniqueRelativesContacted,
      ).shareText,
      aiCopyFuture: isMax
          ? DeepSeekAIService().generateShareCopy(
              cardType: 'wrapped',
              context: {
                'periodName': periodName,
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

/// Small stat display used in the share page summary card.
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
            fontSize: 20,
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
