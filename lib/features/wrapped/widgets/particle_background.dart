import 'dart:math';

import 'package:flutter/material.dart';

/// Floating particle background effect for immersive wrapped screens.
///
/// Renders [particleCount] semi-transparent circles that drift upward
/// with sinusoidal horizontal wobble, creating a subtle sparkle effect.
class ParticleBackground extends StatefulWidget {
  final Color particleColor;
  final int particleCount;
  final double opacity;

  const ParticleBackground({
    super.key,
    required this.particleColor,
    this.particleCount = 30,
    this.opacity = 0.3,
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _particles = List.generate(widget.particleCount, (_) => _randomParticle());
  }

  _Particle _randomParticle({double? startY}) {
    return _Particle(
      x: _random.nextDouble(),
      y: startY ?? _random.nextDouble(),
      size: 1.0 + _random.nextDouble() * 2.5,
      speedY: 0.02 + _random.nextDouble() * 0.04,
      wobblePhase: _random.nextDouble() * 2 * pi,
      wobbleSpeed: 0.5 + _random.nextDouble() * 1.5,
      wobbleAmplitude: 0.005 + _random.nextDouble() * 0.015,
      baseOpacity: 0.2 + _random.nextDouble() * 0.6,
      pulsePhase: _random.nextDouble() * 2 * pi,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _ParticlePainter(
              particles: _particles,
              color: widget.particleColor,
              opacity: widget.opacity,
              tick: _controller.value,
              onUpdate: _updateParticles,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  void _updateParticles(double dt) {
    for (var i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      var newY = p.y - p.speedY * dt;
      var newX =
          p.x + sin(p.wobblePhase + _controller.value * p.wobbleSpeed * 2 * pi) * p.wobbleAmplitude;

      // Wrap around
      if (newY < -0.05) {
        _particles[i] = _randomParticle(startY: 1.05);
        continue;
      }
      if (newX < 0) newX += 1.0;
      if (newX > 1) newX -= 1.0;

      _particles[i] = p.copyWith(x: newX, y: newY);
    }
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Color color;
  final double opacity;
  final double tick;
  final void Function(double dt) onUpdate;

  double _lastTick = -1;

  _ParticlePainter({
    required this.particles,
    required this.color,
    required this.opacity,
    required this.tick,
    required this.onUpdate,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (_lastTick >= 0) {
      var dt = tick - _lastTick;
      if (dt < 0) dt += 1.0; // handle wrap-around
      onUpdate(dt);
    }
    _lastTick = tick;

    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final pulseOpacity =
          (sin(p.pulsePhase + tick * 2 * pi * 0.5) * 0.3 + 0.7).clamp(0.0, 1.0);
      final alpha = p.baseOpacity * pulseOpacity * opacity;

      paint.color = color.withValues(alpha: alpha);

      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final double speedY;
  final double wobblePhase;
  final double wobbleSpeed;
  final double wobbleAmplitude;
  final double baseOpacity;
  final double pulsePhase;

  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedY,
    required this.wobblePhase,
    required this.wobbleSpeed,
    required this.wobbleAmplitude,
    required this.baseOpacity,
    required this.pulsePhase,
  });

  _Particle copyWith({double? x, double? y}) {
    return _Particle(
      x: x ?? this.x,
      y: y ?? this.y,
      size: size,
      speedY: speedY,
      wobblePhase: wobblePhase,
      wobbleSpeed: wobbleSpeed,
      wobbleAmplitude: wobbleAmplitude,
      baseOpacity: baseOpacity,
      pulsePhase: pulsePhase,
    );
  }
}
