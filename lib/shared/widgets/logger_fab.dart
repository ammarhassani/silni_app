import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/logger_provider.dart';

/// Floating Action Button to toggle logger visibility
class LoggerFAB extends ConsumerWidget {
  const LoggerFAB({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVisible = ref.watch(loggerVisibilityProvider);

    return Positioned(
      bottom: 100, // Above bottom nav
      left: 16,
      child: FloatingActionButton.small(
        heroTag: 'loggerFAB',
        backgroundColor: isVisible
            ? AppColors.error
            : AppColors.islamicGreenPrimary,
        onPressed: () {
          ref.read(loggerVisibilityProvider.notifier).state = !isVisible;
        },
        child: Icon(
          isVisible ? Icons.close : Icons.bug_report,
          color: Colors.white,
        ),
      ).animate(
        effects: [
          // Subtle pulse animation to draw attention when closed
          if (!isVisible)
            ScaleEffect(
              duration: 2000.ms,
              curve: Curves.easeInOut,
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.1, 1.1),
            ),
        ],
      ).animate(onPlay: (controller) {
        if (!isVisible) {
          controller.repeat(reverse: true);
        }
      }),
    );
  }
}
