import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_themes.dart';
import '../../../shared/models/interaction_model.dart';
import 'animated_counter.dart';

/// Animated donut chart showing interaction type breakdown.
///
/// Segments sweep clockwise from 12 o'clock. A center counter shows
/// the total, and a legend renders below.
class InteractionRingChart extends StatefulWidget {
  final Map<InteractionType, int> breakdown;
  final ThemeColors themeColors;
  final double size;
  final double strokeWidth;
  final Duration animationDuration;
  final Duration animationDelay;

  const InteractionRingChart({
    super.key,
    required this.breakdown,
    required this.themeColors,
    this.size = 200,
    this.strokeWidth = 24,
    this.animationDuration = const Duration(milliseconds: 1200),
    this.animationDelay = const Duration(milliseconds: 300),
  });

  @override
  State<InteractionRingChart> createState() => _InteractionRingChartState();
}

class _InteractionRingChartState extends State<InteractionRingChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    Future.delayed(widget.animationDelay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _total => widget.breakdown.values.fold(0, (a, b) => a + b);

  Color _colorForType(InteractionType type) {
    final c = widget.themeColors;
    return switch (type) {
      InteractionType.call => c.primary,
      InteractionType.visit => c.accent,
      InteractionType.message => c.statusInfo,
      InteractionType.gift => c.secondary,
      InteractionType.event => c.moodExcited,
      InteractionType.other => c.textSecondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final sorted = widget.breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = _total;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ring chart with center counter
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _animation,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _RingChartPainter(
                      entries: sorted,
                      total: total,
                      progress: _animation.value,
                      colorForType: _colorForType,
                      strokeWidth: widget.strokeWidth,
                    ),
                    size: Size(widget.size, widget.size),
                  );
                },
              ),
              // Center counter
              AnimatedCounter(
                targetValue: total,
                duration: const Duration(milliseconds: 800),
                delay: widget.animationDelay + const Duration(milliseconds: 200),
                style: GoogleFonts.cairo(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Legend
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            for (var i = 0; i < sorted.length; i++)
              _LegendItem(
                type: sorted[i].key,
                count: sorted[i].value,
                color: _colorForType(sorted[i].key),
              )
                  .animate()
                  .fadeIn(
                    delay: Duration(
                      milliseconds: widget.animationDelay.inMilliseconds +
                          widget.animationDuration.inMilliseconds +
                          (i * 100),
                    ),
                    duration: 300.ms,
                  ),
          ],
        ),
      ],
    );
  }
}

class _RingChartPainter extends CustomPainter {
  final List<MapEntry<InteractionType, int>> entries;
  final int total;
  final double progress;
  final Color Function(InteractionType) colorForType;
  final double strokeWidth;

  _RingChartPainter({
    required this.entries,
    required this.total,
    required this.progress,
    required this.colorForType,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final segmentGap = 0.04; // radians gap between segments
    final totalGap = segmentGap * entries.length;
    final availableAngle = 2 * pi - totalGap;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Background track
    paint.color = Colors.white.withValues(alpha: 0.08);
    canvas.drawCircle(center, radius, paint);

    // Segments
    var startAngle = -pi / 2; // start at 12 o'clock

    for (final entry in entries) {
      final fraction = entry.value / total;
      final sweepAngle = fraction * availableAngle * progress;

      paint.color = colorForType(entry.key);
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

      startAngle += sweepAngle + segmentGap;
    }
  }

  @override
  bool shouldRepaint(_RingChartPainter old) => old.progress != progress;
}

class _LegendItem extends StatelessWidget {
  final InteractionType type;
  final int count;
  final Color color;

  const _LegendItem({
    required this.type,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          type.emoji,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(width: 4),
        Text(
          '${type.arabicName} $count',
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}
