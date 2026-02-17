import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:silni_app/features/widgets/home_widget_service.dart';

/// Animated bar chart showing monthly interaction totals across a year.
///
/// Bars animate in a staggered left-to-right wave. The peak month is
/// highlighted with [barHighlightColor].
class ActivityBarChart extends StatefulWidget {
  final Map<int, int> monthlyTotals;
  final Color barColor;
  final Color barHighlightColor;
  final Duration animationDuration;
  final Duration animationDelay;

  const ActivityBarChart({
    super.key,
    required this.monthlyTotals,
    required this.barColor,
    required this.barHighlightColor,
    this.animationDuration = const Duration(milliseconds: 1500),
    this.animationDelay = const Duration(milliseconds: 300),
  });

  @override
  State<ActivityBarChart> createState() => _ActivityBarChartState();
}

class _ActivityBarChartState extends State<ActivityBarChart>
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return CustomPaint(
          painter: _ActivityChartPainter(
            monthlyTotals: widget.monthlyTotals,
            barColor: widget.barColor,
            barHighlightColor: widget.barHighlightColor,
            progress: _animation.value,
          ),
          size: const Size(double.infinity, 200),
        );
      },
    );
  }
}

class _ActivityChartPainter extends CustomPainter {
  final Map<int, int> monthlyTotals;
  final Color barColor;
  final Color barHighlightColor;
  final double progress;

  static const _monthLabels = ['ي', 'ف', 'م', 'أ', 'م', 'ي', 'ي', 'أ', 'س', 'أ', 'ن', 'د'];

  _ActivityChartPainter({
    required this.monthlyTotals,
    required this.barColor,
    required this.barHighlightColor,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final labelHeight = 24.0;
    final valueHeight = 18.0;
    final topPadding = valueHeight + 4;
    final maxBarHeight = size.height - labelHeight - topPadding;
    final gap = 6.0;
    final barWidth = (size.width - 13 * gap) / 12;

    // Find max value for scaling
    int maxVal = 0;
    int peakMonth = 1;
    for (var m = 1; m <= 12; m++) {
      final v = monthlyTotals[m] ?? 0;
      if (v > maxVal) {
        maxVal = v;
        peakMonth = m;
      }
    }
    if (maxVal == 0) maxVal = 1;

    final barPaint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < 12; i++) {
      final month = i + 1;
      final value = monthlyTotals[month] ?? 0;
      final fraction = value / maxVal;

      // Staggered wave: bar i starts at progress * 1.5 - i / 12, clamped 0..1
      final barProgress = ((progress * 1.8 - i / 12)).clamp(0.0, 1.0);
      final barHeight = fraction * maxBarHeight * barProgress;

      final x = gap + i * (barWidth + gap);
      final barTop = topPadding + maxBarHeight - barHeight;

      final isPeak = month == peakMonth && value > 0;
      barPaint.color = isPeak ? barHighlightColor : barColor;

      // Draw rounded-top bar
      final barRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, barTop, barWidth, barHeight),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      canvas.drawRRect(barRect, barPaint);

      // Value label above bar (only when bar is mostly visible)
      if (barProgress > 0.5 && value > 0) {
        final valueText = HomeWidgetService.toArabicNumerals(value);
        final valueParagraph = _buildParagraph(
          valueText,
          10,
          (isPeak ? barHighlightColor : Colors.white).withValues(alpha: barProgress * 0.9),
          barWidth + gap * 2,
          FontWeight.w700,
        );
        canvas.drawParagraph(
          valueParagraph,
          Offset(x - gap, barTop - valueHeight),
        );
      }

      // Month label below
      final labelParagraph = _buildParagraph(
        _monthLabels[i],
        11,
        Colors.white.withValues(alpha: 0.6),
        barWidth + gap * 2,
        FontWeight.w600,
      );
      canvas.drawParagraph(
        labelParagraph,
        Offset(x - gap, size.height - labelHeight + 4),
      );
    }
  }

  ui.Paragraph _buildParagraph(
    String text,
    double fontSize,
    Color color,
    double width,
    FontWeight weight,
  ) {
    final style = ui.TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: weight,
      fontFamily: GoogleFonts.cairo().fontFamily,
    );
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(textAlign: TextAlign.center, maxLines: 1),
    )
      ..pushStyle(style)
      ..addText(text);
    final paragraph = builder.build();
    paragraph.layout(ui.ParagraphConstraints(width: width));
    return paragraph;
  }

  @override
  bool shouldRepaint(_ActivityChartPainter old) => old.progress != progress;
}
