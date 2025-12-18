import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/models/reminder_schedule_model.dart';
import '../../../shared/widgets/glass_card.dart';

/// Carousel showing tomorrow/yesterday reminders by frequency
class FrequencyCarousel extends StatefulWidget {
  const FrequencyCarousel({
    super.key,
    required this.relatives,
    required this.schedules,
  });

  final List<Relative> relatives;
  final List<ReminderSchedule> schedules;

  @override
  State<FrequencyCarousel> createState() => _FrequencyCarouselState();
}

class _FrequencyCarouselState extends State<FrequencyCarousel> {
  final PageController _pageController = PageController();
  Timer? _autoSlideTimer;
  int _currentPage = 0;

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide(int totalPages) {
    _autoSlideTimer?.cancel();
    if (totalPages <= 1) return;

    _autoSlideTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        final nextPage = (_currentPage + 1) % totalPages;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  bool _shouldFireOnDate(ReminderSchedule schedule, DateTime date) {
    switch (schedule.frequency) {
      case ReminderFrequency.daily:
        return true;
      case ReminderFrequency.weekly:
        if (schedule.customDays != null && schedule.customDays!.isNotEmpty) {
          return schedule.customDays!.contains(date.weekday);
        }
        return true;
      case ReminderFrequency.monthly:
        if (schedule.dayOfMonth != null) {
          return date.day == schedule.dayOfMonth;
        }
        return false;
      case ReminderFrequency.friday:
        return date.weekday == 5;
      case ReminderFrequency.custom:
        return false;
    }
  }

  List<ReminderFrequency> _getFrequenciesOnDate(DateTime date) {
    final activeSchedules = widget.schedules.where((s) =>
      s.isActive && _shouldFireOnDate(s, date)
    ).toList();

    if (activeSchedules.isEmpty) return [];

    final frequencies = activeSchedules.map((s) => s.frequency).toSet().toList();
    frequencies.sort((a, b) {
      if (a == ReminderFrequency.friday) return -1;
      if (b == ReminderFrequency.friday) return 1;
      return a.arabicName.compareTo(b.arabicName);
    });

    return frequencies;
  }

  List<Relative> _getRelativesByFrequencyOnDate(
    DateTime date,
    ReminderFrequency frequency,
  ) {
    final dueRelativeIds = <String>{};
    for (final schedule in widget.schedules) {
      if (schedule.isActive &&
          schedule.frequency == frequency &&
          _shouldFireOnDate(schedule, date)) {
        dueRelativeIds.addAll(schedule.relativeIds);
      }
    }
    return widget.relatives.where((r) => dueRelativeIds.contains(r.id)).toList();
  }

  String _buildRelativesHint(List<Relative> relatives) {
    if (relatives.isEmpty) return '';
    if (relatives.length <= 3) {
      return relatives.map((r) => r.fullName.split(' ').first).join('، ');
    }
    final firstThree = relatives.take(3).map((r) => r.fullName.split(' ').first).join('، ');
    return '$firstThree +${relatives.length - 3}';
  }

  Color _getFrequencyColor(ReminderFrequency frequency) {
    switch (frequency) {
      case ReminderFrequency.friday:
        return const Color(0xFF1B5E20);
      case ReminderFrequency.daily:
        return const Color(0xFF1976D2);
      case ReminderFrequency.weekly:
        return const Color(0xFF7B1FA2);
      case ReminderFrequency.monthly:
        return const Color(0xFFE64A19);
      case ReminderFrequency.custom:
        return const Color(0xFF455A64);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    final tomorrowFreqs = _getFrequenciesOnDate(tomorrow);
    final yesterdayFreqs = _getFrequenciesOnDate(yesterday);
    final allFrequencies = {...tomorrowFreqs, ...yesterdayFreqs}.toList();

    allFrequencies.sort((a, b) {
      if (a == ReminderFrequency.friday) return -1;
      if (b == ReminderFrequency.friday) return 1;
      return a.arabicName.compareTo(b.arabicName);
    });

    if (allFrequencies.isEmpty) return const SizedBox.shrink();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoSlide(allFrequencies.length);
    });

    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _pageController,
            itemCount: allFrequencies.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final frequency = allFrequencies[index];
              return _buildFrequencySlide(frequency, tomorrow, yesterday);
            },
          ),
        ),
        if (allFrequencies.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                allFrequencies.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentPage == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentPage == index
                        ? _getFrequencyColor(allFrequencies[index])
                        : Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
      ],
    ).animate().fadeIn(delay: const Duration(milliseconds: 100));
  }

  Widget _buildFrequencySlide(
    ReminderFrequency frequency,
    DateTime tomorrow,
    DateTime yesterday,
  ) {
    final tomorrowRelatives = _getRelativesByFrequencyOnDate(tomorrow, frequency);
    final yesterdayRelatives = _getRelativesByFrequencyOnDate(yesterday, frequency);

    final color = _getFrequencyColor(frequency);
    final isFriday = frequency == ReminderFrequency.friday;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.3),
                  ),
                  child: Center(
                    child: Text(
                      isFriday ? '🕌' : frequency.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  frequency.arabicName,
                  style: AppTypography.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (tomorrowRelatives.isNotEmpty)
              _buildFrequencyRow(
                label: 'غداً',
                relatives: tomorrowRelatives,
                color: color,
                isPast: false,
              ),
            if (yesterdayRelatives.isNotEmpty)
              _buildFrequencyRow(
                label: 'أمس',
                relatives: yesterdayRelatives,
                color: color,
                isPast: true,
              ),
            if (tomorrowRelatives.isEmpty && yesterdayRelatives.isEmpty)
              Center(
                child: Text(
                  'لا يوجد تذكيرات',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyRow({
    required String label,
    required List<Relative> relatives,
    required Color color,
    required bool isPast,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            isPast ? Icons.history : Icons.schedule,
            color: color.withValues(alpha: isPast ? 0.5 : 0.8),
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white.withValues(alpha: isPast ? 0.5 : 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _buildRelativesHint(relatives),
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white.withValues(alpha: isPast ? 0.4 : 0.7),
                decoration: isPast ? TextDecoration.lineThrough : null,
                decorationColor: Colors.white.withValues(alpha: 0.3),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isPast ? 0.2 : 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${relatives.length}',
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white.withValues(alpha: isPast ? 0.6 : 1.0),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
