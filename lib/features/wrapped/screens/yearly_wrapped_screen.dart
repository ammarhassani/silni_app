import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/share_card_widget.dart';
import '../../../shared/widgets/shareable_card_generator.dart';
import 'package:silni_app/features/widgets/home_widget_service.dart';
import '../models/yearly_wrapped_model.dart';
import '../providers/wrapped_providers.dart';
import '../widgets/wrapped_story_page.dart';

/// Full-screen "Spotify Wrapped" story experience for yearly family
/// connection stats.
///
/// Displays 5-6 swipeable pages (like Instagram stories) with animated
/// reveals of the user's yearly highlights, ending with a shareable card.
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: wrappedAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          error: (error, _) => SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '\u{1F614}', // pensive face
                      style: const TextStyle(fontSize: 48),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '\u062D\u062F\u062B \u062E\u0637\u0623 \u0623\u062B\u0646\u0627\u0621 \u062A\u062D\u0645\u064A\u0644 \u0627\u0644\u0645\u0644\u062E\u0635', // حدث خطأ أثناء تحميل الملخص
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
                        '\u0631\u062C\u0648\u0639', // رجوع
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

/// Main story content once data is loaded.
class _WrappedStoryContent extends StatefulWidget {
  final YearlyWrapped wrapped;
  final PageController pageController;
  final int currentPage;
  final int totalPages;
  final void Function(int page, int total) onPageChanged;

  const _WrappedStoryContent({
    required this.wrapped,
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

  @override
  void initState() {
    super.initState();
    _pages = _buildPages();
    // Notify parent of total pages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onPageChanged(0, _pages.length);
    });
  }

  List<Widget> _buildPages() {
    final w = widget.wrapped;
    final arabicYear = HomeWidgetService.toArabicNumerals(w.year);
    final pages = <Widget>[];

    // Page 1: Total interactions
    pages.add(
      WrappedStoryPage(
        emoji: '\u{1F525}', // fire
        title: '\u062A\u0648\u0627\u0635\u0644\u0627\u062A\u0643 \u0641\u064A $arabicYear', // تواصلاتك في ٢٠٢٥
        mainValue: HomeWidgetService.toArabicNumerals(w.totalInteractions),
        subtitle:
            '\u0645\u0631\u0629 \u062A\u0648\u0627\u0635\u0644\u062A \u0645\u0639 \u0623\u0642\u0627\u0631\u0628\u0643 \u0647\u0627\u0644\u0633\u0646\u0629', // مرة تواصلت مع أقاربك هالسنة
      ),
    );

    // Page 2: Most contacted relative (only if exists)
    if (w.mostContactedRelativeName != null) {
      pages.add(
        WrappedStoryPage(
          emoji: '\u{1F49C}', // purple heart
          title:
              '\u0627\u0644\u0623\u0643\u062B\u0631 \u062A\u0648\u0627\u0635\u0644\u0627\u064B', // الأكثر تواصلاً
          mainValue: w.mostContactedRelativeName!,
          subtitle:
              '${HomeWidgetService.toArabicNumerals(w.mostContactedRelativeCount ?? 0)} '
              '\u062A\u0641\u0627\u0639\u0644 \u0645\u0639\u0627\u0647 \u0647\u0627\u0644\u0633\u0646\u0629', // تفاعل معاه هالسنة
        ),
      );
    }

    // Page 3: Longest streak
    if (w.longestStreak > 0) {
      pages.add(
        WrappedStoryPage(
          emoji: '\u{1F525}', // fire
          title:
              '\u0623\u0637\u0648\u0644 \u0633\u0644\u0633\u0644\u0629 \u062A\u0648\u0627\u0635\u0644', // أطول سلسلة تواصل
          mainValue:
              '${HomeWidgetService.toArabicNumerals(w.longestStreak)} \u064A\u0648\u0645', // ٥ يوم
          subtitle:
              '\u0645\u062A\u0648\u0627\u0635\u0644 \u0628\u062F\u0648\u0646 \u0627\u0646\u0642\u0637\u0627\u0639', // متواصل بدون انقطاع
          accentColor: const Color(0xFFFFD700),
        ),
      );
    }

    // Page 4: Personality type
    pages.add(
      WrappedStoryPage(
        emoji: w.personalityEmoji,
        title:
            '\u0634\u062E\u0635\u064A\u062A\u0643 \u0647\u0627\u0644\u0633\u0646\u0629', // شخصيتك هالسنة
        mainValue: w.personalityLabel,
        subtitle:
            '\u0647\u0630\u0627 \u0623\u0633\u0644\u0648\u0628\u0643 \u0641\u064A \u0635\u0644\u0629 \u0627\u0644\u0631\u062D\u0645', // هذا أسلوبك في صلة الرحم
      ),
    );

    // Page 5: Year breakdown — active days + coverage
    pages.add(
      WrappedStoryPage(
        emoji: '\u{1F4CA}', // bar chart
        title:
            '\u0645\u0644\u062E\u0635 \u0627\u0644\u0633\u0646\u0629', // ملخص السنة
        mainValue:
            '${HomeWidgetService.toArabicNumerals(w.totalActiveDays)} \u064A\u0648\u0645', // ١٢٠ يوم
        subtitle:
            '\u0643\u0646\u062A \u0641\u064A\u0647\u0627 \u0646\u0634\u064A\u0637 \u0648\u062A\u0648\u0627\u0635\u0644\u062A \u0645\u0639 '
            '${HomeWidgetService.toArabicNumerals(w.uniqueRelativesContacted)} '
            '\u0642\u0631\u064A\u0628', // كنت فيها نشيط وتواصلت مع ١٥ قريب
      ),
    );

    // Page 6: Share card
    pages.add(_SharePage(wrapped: w));

    return pages;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Top bar: close button + progress indicators
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // Progress indicator bars
                Row(
                  children: List.generate(_pages.length, (index) {
                    return Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: index <= widget.currentPage
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    );
                  }),
                ).animate().fadeIn(duration: 300.ms),

                const SizedBox(height: 8),

                // Close button
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

          // Story pages
          Expanded(
            child: PageView(
              controller: widget.pageController,
              onPageChanged: (page) {
                widget.onPageChanged(page, _pages.length);
              },
              children: _pages,
            ),
          ),

          // Navigation hints
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              widget.currentPage < _pages.length - 1
                  ? '\u0627\u0633\u062D\u0628 \u0644\u0644\u0645\u062A\u0627\u0628\u0639\u0629 \u2190' // اسحب للمتابعة ←
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
    );
  }
}

/// Final page with a share card and share button.
class _SharePage extends StatelessWidget {
  final YearlyWrapped wrapped;

  const _SharePage({required this.wrapped});

  @override
  Widget build(BuildContext context) {
    final arabicYear = HomeWidgetService.toArabicNumerals(wrapped.year);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // Mini summary card preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Text(
                  wrapped.personalityEmoji,
                  style: const TextStyle(fontSize: 56),
                ),
                const SizedBox(height: 12),
                Text(
                  wrapped.personalityLabel,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\u0645\u0644\u062E\u0635 $arabicYear', // ملخص ٢٠٢٥
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 16),
                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _MiniStat(
                      value: HomeWidgetService.toArabicNumerals(
                          wrapped.totalInteractions),
                      label:
                          '\u062A\u0641\u0627\u0639\u0644', // تفاعل
                    ),
                    _MiniStat(
                      value: HomeWidgetService.toArabicNumerals(
                          wrapped.uniqueRelativesContacted),
                      label:
                          '\u0642\u0631\u064A\u0628', // قريب
                    ),
                    _MiniStat(
                      value: HomeWidgetService.toArabicNumerals(
                          wrapped.longestStreak),
                      label:
                          '\u0623\u064A\u0627\u0645 \u0645\u062A\u062A\u0627\u0644\u064A\u0629', // أيام متتالية
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

          const SizedBox(height: 32),

          // Share button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _shareWrapped(context),
              icon: const Icon(Icons.share, color: Color(0xFF1B5E20)),
              label: Text(
                '\u0634\u0627\u0631\u0643 \u0645\u0644\u062E\u0635\u0643', // شارك ملخصك
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1B5E20),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

          const Spacer(flex: 3),
        ],
      ),
    );
  }

  void _shareWrapped(BuildContext context) {
    final arabicYear = HomeWidgetService.toArabicNumerals(wrapped.year);

    final cardData = ShareableCardData(
      emoji: wrapped.personalityEmoji,
      title: wrapped.personalityLabel,
      subtitle:
          '\u0645\u0644\u062E\u0635 $arabicYear - '
          '${wrapped.totalInteractions} '
          '\u062A\u0641\u0627\u0639\u0644', // ملخص ٢٠٢٥ - 342 تفاعل
      shareText:
          '\u0645\u0644\u062E\u0635\u064A \u0644\u0633\u0646\u0629 $arabicYear: '
          '${wrapped.personalityLabel} ${wrapped.personalityEmoji}\n'
          '${wrapped.totalInteractions} \u062A\u0641\u0627\u0639\u0644 \u0645\u0639 '
          '${wrapped.uniqueRelativesContacted} \u0642\u0631\u064A\u0628\n'
          '#\u0635\u0650\u0644\u0646\u064A', // ملخصي لسنة ٢٠٢٥: ... #صِلني
    );

    ShareCardWidget.captureAndShare(
      context,
      cardData,
      gradient: AppColors.primaryGradient,
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
