import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_animations.dart';
import '../../../shared/widgets/glass_card.dart';

/// Animated icon widget for feature showcase
/// Shows a pulsing gradient icon with glow effect
class AnimatedFeatureIcon extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final bool isActive;
  final double size;

  const AnimatedFeatureIcon({
    super.key,
    required this.icon,
    required this.gradient,
    this.isActive = true,
    this.size = 160,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors = (gradient as LinearGradient).colors;
    final primaryColor = gradientColors.first;

    return DramaticGlassCard(
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.4),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            size: size * 0.5,
            color: Colors.white,
          )
              .animate(
                onPlay: isActive
                    ? (controller) => controller.repeat(reverse: true)
                    : null,
              )
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.1, 1.1),
                duration: AppAnimations.loop,
                curve: Curves.easeInOut,
              ),
        ),
      ),
    );
  }
}

/// Smaller variant for quick action buttons
class SmallFeatureIcon extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final double size;
  final VoidCallback? onTap;

  const SmallFeatureIcon({
    super.key,
    required this.icon,
    required this.gradient,
    this.size = 56,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors = (gradient as LinearGradient).colors;
    final primaryColor = gradientColors.first;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: gradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            size: size * 0.5,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
