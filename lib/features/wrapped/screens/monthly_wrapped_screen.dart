import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/share_card_widget.dart';
import '../../../shared/widgets/shareable_card_generator.dart';
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
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: wrappedAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white),
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
class _WrappedContent extends StatelessWidget {
  final MonthlyWrapped wrapped;

  const _WrappedContent({required this.wrapped});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Month title
            Text(
              'ملخص شهر ${wrapped.arabicMonthName}',
              style: GoogleFonts.cairo(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 24),

            // Personality emoji (large)
            Text(
              wrapped.personalityEmoji,
              style: const TextStyle(fontSize: 80),
            ).animate().scale(
              duration: 600.ms,
              curve: Curves.elasticOut,
            ),

            const SizedBox(height: 12),

            // Personality label
            Text(
              wrapped.personalityLabel,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

            const SizedBox(height: 32),

            // Stats grid
            _buildStatsGrid(context),

            const SizedBox(height: 24),

            // Interaction breakdown
            if (wrapped.interactionBreakdown.isNotEmpty) ...[
              _buildBreakdownSection(context),
              const SizedBox(height: 24),
            ],

            // Most contacted relative
            if (wrapped.mostContactedRelativeName != null)
              _buildMostContactedCard(context)
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 400.ms),

            const SizedBox(height: 32),

            // Share button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _shareWrapped(context),
                icon: const Icon(Icons.share, color: Color(0xFF1B5E20)),
                label: Text(
                  'شارك ملخصك',
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
            ).animate().fadeIn(delay: 800.ms, duration: 400.ms),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            value: '${wrapped.totalInteractions}',
            label: 'تفاعل',
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            value: '${wrapped.uniqueRelativesContacted}',
            label: 'قريب',
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            value: '${(wrapped.relativesCoverage * 100).round()}%',
            label: 'تغطية',
          ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
        ),
        if (wrapped.longestStreak > 0) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _StatTile(
              value: '${wrapped.longestStreak}',
              label: 'أيام متتالية',
            ).animate().fadeIn(delay: 550.ms, duration: 400.ms),
          ),
        ],
      ],
    );
  }

  Widget _buildBreakdownSection(BuildContext context) {
    final sortedEntries = wrapped.interactionBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sortedEntries.map((entry) {
        final fraction = wrapped.totalInteractions > 0
            ? entry.value / wrapped.totalInteractions
            : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(
                entry.key.emoji,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                entry.key.arabicName,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
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
      }).toList(),
    ).animate().fadeIn(delay: 500.ms, duration: 400.ms);
  }

  Widget _buildMostContactedCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
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
              fontSize: 20,
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

  void _shareWrapped(BuildContext context) {
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
      gradient: AppColors.primaryGradient,
    );
  }
}

/// A small rounded tile showing a numeric value and label.
class _StatTile extends StatelessWidget {
  final String value;
  final String label;

  const _StatTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
