import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

/// Overlay widget that shows floating "+X points" animation
/// This provides instant visual feedback when points are earned
class FloatingPointsOverlay extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Trigger haptic feedback
    HapticFeedback.lightImpact();

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: IgnorePointer(
        child: Text(
          '+$points',
          style: AppTypography.numberMedium.copyWith(
            color: AppColors.premiumGold,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 8,
                color: AppColors.premiumGold.withOpacity(0.5),
              ),
            ],
          ),
        )
            .animate(
              onComplete: (_) => onComplete?.call(),
            )
            // Float upward
            .moveY(
              begin: 0,
              end: -100,
              duration: 2000.ms,
              curve: Curves.easeOut,
            )
            // Fade in quickly, then fade out
            .fadeIn(
              duration: 200.ms,
            )
            .fadeOut(
              delay: 1500.ms,
              duration: 500.ms,
            )
            // Scale animation for emphasis
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.2, 1.2),
              duration: 300.ms,
              curve: Curves.elasticOut,
            )
            .then()
            .scale(
              begin: const Offset(1.2, 1.2),
              end: const Offset(1.0, 1.0),
              duration: 200.ms,
            ),
      ),
    );
  }
}

/// Global key for the overlay state
final GlobalKey<FloatingPointsHostState> floatingPointsHostKey =
    GlobalKey<FloatingPointsHostState>();

/// Host widget that manages floating points overlays
/// Should be placed near the root of the app (above navigation)
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

  /// Show floating points at the specified position
  /// If no position is provided, shows at center of screen
  void show({
    required int points,
    Offset? position,
  }) {
    setState(() {
      final entry = _FloatingPointsEntry(
        points: points,
        position: position ??
            Offset(
              MediaQuery.of(context).size.width / 2 - 30,
              MediaQuery.of(context).size.height / 2 - 100,
            ),
        key: UniqueKey(),
      );
      _entries.add(entry);

      // Auto-remove after animation completes
      Future.delayed(const Duration(milliseconds: 2000), () {
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
        // Overlays for floating points
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
