import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:silni_app/features/widgets/home_widget_service.dart';

/// Animated counter that smoothly rolls up from 0 to [targetValue]
/// using Arabic numerals.
class AnimatedCounter extends StatefulWidget {
  final int targetValue;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final TextStyle? style;
  final String? suffix;

  const AnimatedCounter({
    super.key,
    required this.targetValue,
    this.duration = const Duration(milliseconds: 1200),
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
    this.style,
    this.suffix,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
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
        final current = (_animation.value * widget.targetValue).round();
        final text = HomeWidgetService.toArabicNumerals(current);
        final display = widget.suffix != null ? '$text${widget.suffix}' : text;

        return Text(
          display,
          textAlign: TextAlign.center,
          style: widget.style ??
              GoogleFonts.cairo(
                fontSize: 72,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.1,
              ),
        );
      },
    );
  }
}
