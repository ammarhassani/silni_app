import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_themes.dart';
import '../../../shared/widgets/share_card_widget.dart';
import '../../../shared/widgets/shareable_card_generator.dart';
import '../../family_tree/providers/family_graph_providers.dart';
import '../models/monthly_wrapped_model.dart';
import '../providers/wrapped_providers.dart';

/// Full-screen "Spotify Wrapped" experience for monthly family connection stats.
///
/// Receives an optional [month] query parameter (ISO date string).
/// If omitted, defaults to the previous calendar month.
class MonthlyWrappedScreen extends ConsumerWidget {
  final DateTime? month;

  const MonthlyWrappedScreen({super.key, this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetMonth = month ?? _previousMonth();
    final wrappedAsync = ref.watch(monthlyWrappedProvider(targetMonth));
    final themeColors = ref.watch(themeColorsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: themeColors.backgroundGradient),
        child: wrappedAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: themeColors.primary),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'حدث خطأ أثناء تحميل الملخص',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (wrapped) => _WrappedContent(wrapped: wrapped),
        ),
      ),
    );
  }

  static DateTime _previousMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month - 1, 1);
  }
}

/// The main content body once data is loaded.
class _WrappedContent extends ConsumerWidget {
  final MonthlyWrapped wrapped;

  const _WrappedContent({required this.wrapped});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    // Check if user is in a family group
    final groupInfo = ref.watch(userFamilyGroupProvider).valueOrNull;

    // Load family stats if in a group
    final familyStatsAsync = groupInfo != null
        ? ref.watch(familyMonthlyWrappedProvider((
            month: wrapped.month,
            groupId: groupInfo.groupId,
          )))
        : null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Month title with decorative element
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                'ملخص شهر ${wrapped.arabicMonthName}',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 32),

            // Personality emoji (large) with glow
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    themeColors.primary.withValues(alpha: 0.3),
                    themeColors.accent.withValues(alpha: 0.2),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeColors.primary.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  wrapped.personalityEmoji,
                  style: const TextStyle(fontSize: 72),
                ),
              ),
            ).animate().scale(
              duration: 600.ms,
              curve: Curves.elasticOut,
            ),

            const SizedBox(height: 16),

            // Personality label
            Text(
              wrapped.personalityLabel,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

            const SizedBox(height: 8),

            // Motivational subtitle based on coverage
            Text(
              _getMotivationalMessage(),
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

            const SizedBox(height: 32),

            // Stats grid (2x2 for better visual)
            _buildStatsGrid(context, themeColors),

            const SizedBox(height: 24),

            // Interaction breakdown
            if (wrapped.interactionBreakdown.isNotEmpty) ...[
              _buildBreakdownSection(context, themeColors),
              const SizedBox(height: 24),
            ],

            // Most contacted relative
            if (wrapped.mostContactedRelativeName != null)
              _buildMostContactedCard(context, themeColors)
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 400.ms),

            const SizedBox(height: 32),

            // Family stats section (only when in a group)
            if (familyStatsAsync != null)
              familyStatsAsync.when(
                data: (familyStats) {
                  if (familyStats == null) return const SizedBox.shrink();
                  return _buildFamilyStatsCard(familyStats, themeColors);
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),

            const SizedBox(height: 32),

            // Share button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _shareWrapped(context, themeColors),
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
            ).animate().fadeIn(delay: 800.ms, duration: 400.ms),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _getMotivationalMessage() {
    final coverage = wrapped.relativesCoverage;
    if (coverage >= 0.8) return 'ما شاء الله! تواصلك مع عائلتك ممتاز';
    if (coverage >= 0.5) return 'أحسنت! استمر في التواصل مع أقاربك';
    if (coverage >= 0.2) return 'بداية طيبة، حاول تتواصل مع أقارب أكثر';
    return 'الشهر الجاي بإذن الله أفضل';
  }

  Widget _buildStatsGrid(BuildContext context, ThemeColors themeColors) {
    final stats = <_StatData>[
      _StatData('${wrapped.totalInteractions}', 'تفاعل', '📱'),
      _StatData('${wrapped.uniqueRelativesContacted}', 'قريب', '👥'),
      _StatData('${(wrapped.relativesCoverage * 100).round()}%', 'تغطية', '📊'),
      if (wrapped.longestStreak > 0)
        _StatData('${wrapped.longestStreak}', 'أيام متتالية', '🔥'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: stats.asMap().entries.map((entry) {
        final index = entry.key;
        final stat = entry.value;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(stat.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(
                stat.value,
                style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                stat.label,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(
          delay: Duration(milliseconds: 300 + (index * 100)),
          duration: 400.ms,
        );
      }).toList(),
    );
  }

  Widget _buildBreakdownSection(BuildContext context, ThemeColors themeColors) {
    final sortedEntries = wrapped.interactionBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'أنواع التواصل',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 12),
          ...sortedEntries.map((entry) {
            final fraction = wrapped.totalInteractions > 0
                ? entry.value / wrapped.totalInteractions
                : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Text(
                    entry.key.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 60,
                    child: Text(
                      entry.key.arabicName,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          themeColors.primary.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${entry.value}',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms, duration: 400.ms);
  }

  Widget _buildMostContactedCard(BuildContext context, ThemeColors themeColors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeColors.primary.withValues(alpha: 0.25),
            themeColors.accent.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            'الأكثر تواصلاً',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            wrapped.mostContactedRelativeName!,
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            '${wrapped.mostContactedRelativeCount} تفاعل',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyStatsCard(FamilyWrappedStats stats, ThemeColors themeColors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade800.withValues(alpha: 0.3),
            Colors.purple.shade800.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('👨‍👩‍👧‍👦', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 8),
              Text(
                'ملخص العائلة',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Family stats grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFamilyStatItem(
                '${stats.totalFamilyInteractions}',
                'تفاعل عائلي',
                '📱',
              ),
              _buildFamilyStatItem(
                '${stats.familyMembersActive}',
                'أعضاء نشطين',
                '👥',
              ),
            ],
          ),

          if (stats.topContributorName != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🌟', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'الأكثر نشاطاً: ${stats.topContributorName} (${stats.topContributorCount})',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (stats.mostContactedByFamily != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('💝', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'الأكثر تواصلاً معه: ${stats.mostContactedByFamily} (${stats.mostContactedByFamilyCount})',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 700.ms, duration: 400.ms);
  }

  Widget _buildFamilyStatItem(String value, String label, String emoji) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  void _shareWrapped(BuildContext context, ThemeColors themeColors) {
    final cardData = ShareableCardData(
      emoji: wrapped.personalityEmoji,
      title: wrapped.personalityLabel,
      subtitle:
          'ملخص شهر ${wrapped.arabicMonthName} - ${wrapped.totalInteractions} تفاعل',
      shareText:
          'ملخصي لشهر ${wrapped.arabicMonthName}: ${wrapped.personalityLabel} ${wrapped.personalityEmoji}\n'
          '${wrapped.totalInteractions} تفاعل مع ${wrapped.uniqueRelativesContacted} قريب\n'
          '#صِلني',
    );

    ShareCardWidget.captureAndShare(
      context,
      cardData,
      gradient: themeColors.primaryGradient,
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
