import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/theme_provider.dart';

// ---------------------------------------------------------------------------
// Sparkle particle burst system
// ---------------------------------------------------------------------------

class _SparkleParticle {
  final double angle;
  final double speed;
  final double radius;
  final Color color;
  final double lifetime;

  _SparkleParticle({
    required this.angle,
    required this.speed,
    required this.radius,
    required this.color,
    required this.lifetime,
  });
}

class _SparklePainter extends CustomPainter {
  final List<_SparkleParticle> particles;
  final double progress;

  _SparklePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final p in particles) {
      if (progress > p.lifetime) continue;

      final t = progress / p.lifetime;
      // Ease-out fade: fast at start, slow at end
      final opacity = (1.0 - t * t).clamp(0.0, 1.0);
      final currentRadius = p.radius * (1.0 - t * 0.6);
      final dx = cos(p.angle) * p.speed * t;
      final dy = sin(p.angle) * p.speed * t;

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

      canvas.drawCircle(center + Offset(dx, dy), currentRadius, paint);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _SparkleOverlay extends StatefulWidget {
  final List<Color> sparkleColors;

  const _SparkleOverlay({required this.sparkleColors});

  @override
  State<_SparkleOverlay> createState() => _SparkleOverlayState();
}

class _SparkleOverlayState extends State<_SparkleOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_SparkleParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    final rng = Random();
    _particles = List.generate(12, (_) {
      return _SparkleParticle(
        angle: rng.nextDouble() * 2 * pi,
        speed: 40 + rng.nextDouble() * 60,
        radius: 1.5 + rng.nextDouble() * 2.5,
        color: widget.sparkleColors[rng.nextInt(widget.sparkleColors.length)],
        lifetime: 0.5 + rng.nextDouble() * 0.5,
      );
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
      animation: _controller,
      builder: (_, _) => CustomPaint(
        size: const Size(160, 160),
        painter: _SparklePainter(_particles, _controller.value),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Floating points overlay — theme-aware pill with sparkle burst
// ---------------------------------------------------------------------------

/// Overlay widget that shows a floating "+X" pill with sparkle burst.
/// Provides instant visual & haptic feedback when points are earned.
class FloatingPointsOverlay extends ConsumerWidget {
  final int points;
  final Offset position;
  final VoidCallback? onComplete;

  const FloatingPointsOverlay({
    super.key,
    required this.points,
    required this.position,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeColorsProvider);
    final gradient = colors.primaryGradient;
    final accentColor = gradient.colors[1];

    HapticFeedback.mediumImpact();

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: IgnorePointer(
          child: Stack(
            alignment: Alignment.center,
            children: [
              _SparkleOverlay(
                sparkleColors: [...gradient.colors, Colors.white],
              ),
              _buildGlowBloom(accentColor),
              _buildPointsPill(gradient, accentColor),
            ],
          )
              .animate(onComplete: (_) => onComplete?.call())
              // --- Scale punch: appear big, settle to 1x ---
              .scale(
                begin: const Offset(1.5, 1.5),
                end: const Offset(1.0, 1.0),
                duration: 350.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 100.ms, curve: Curves.easeOut)
              // --- Float upward with deceleration (starts immediately) ---
              .moveY(
                begin: 0,
                end: -60,
                duration: 1800.ms,
                curve: Curves.decelerate,
              )
              // --- Fade out in the last stretch ---
              .fadeOut(
                delay: 1300.ms,
                duration: 500.ms,
                curve: Curves.easeIn,
              ),
        ),
      ),
    );
  }

  Widget _buildGlowBloom(Color accentColor) {
    return Container(
      width: 100,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildPointsPill(LinearGradient gradient, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient.colors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.5),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        '+$points',
        textAlign: TextAlign.center,
        style: AppTypography.numberMedium.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 0.5,
          decoration: TextDecoration.none,
          shadows: [
            Shadow(
              blurRadius: 4,
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Host & infrastructure (public API unchanged)
// ---------------------------------------------------------------------------

/// Global key for the overlay state
final GlobalKey<FloatingPointsHostState> floatingPointsHostKey =
    GlobalKey<FloatingPointsHostState>();

/// Host widget that manages floating points overlays.
/// Should be placed near the root of the app (above navigation).
class FloatingPointsHost extends StatefulWidget {
  final Widget child;

  const FloatingPointsHost({
    super.key,
    required this.child,
  });

  @override
  State<FloatingPointsHost> createState() => FloatingPointsHostState();
}

class FloatingPointsHostState extends State<FloatingPointsHost> {
  final List<_FloatingPointsEntry> _entries = [];

  /// Show floating points at the specified position.
  /// If no position is provided, shows at center of screen.
  void show({
    required int points,
    Offset? position,
  }) {
    setState(() {
      final entry = _FloatingPointsEntry(
        points: points,
        position: position ??
            Offset(
              MediaQuery.of(context).size.width / 2,
              MediaQuery.of(context).size.height / 2 - 100,
            ),
        key: UniqueKey(),
      );
      _entries.add(entry);

      // Auto-remove after animation completes
      Future.delayed(const Duration(milliseconds: 1900), () {
        if (mounted) {
          setState(() {
            _entries.remove(entry);
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        ..._entries.map((entry) => FloatingPointsOverlay(
              key: entry.key,
              points: entry.points,
              position: entry.position,
              onComplete: () {
                if (mounted) {
                  setState(() {
                    _entries.remove(entry);
                  });
                }
              },
            )),
      ],
    );
  }
}

/// Internal class to track overlay entries
class _FloatingPointsEntry {
  final int points;
  final Offset position;
  final Key key;

  _FloatingPointsEntry({
    required this.points,
    required this.position,
    required this.key,
  });
}

/// Helper extension to show floating points from anywhere
extension FloatingPointsHelper on BuildContext {
  void showFloatingPoints({
    required int points,
    Offset? position,
  }) {
    floatingPointsHostKey.currentState?.show(
      points: points,
      position: position,
    );
  }
}
