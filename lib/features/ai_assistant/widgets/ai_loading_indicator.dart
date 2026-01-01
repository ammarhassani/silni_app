import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/ai/ai_identity.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';

/// AI-themed loading indicator with animated dots and message
/// Used across all AI feature screens for consistent loading UX
class AILoadingIndicator extends StatelessWidget {
  final String? message;
  final bool showIcon;

  const AILoadingIndicator({
    super.key,
    this.message,
    this.showIcon = true,
  });

  String get _displayMessage => message ?? '${AIIdentity.name} يفكر...';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showIcon) ...[
            // AI avatar with pulse animation
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.islamicGreenPrimary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 32,
                color: Colors.white,
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.1, 1.1),
                  duration: 800.ms,
                )
                .then()
                .scale(
                  begin: const Offset(1.1, 1.1),
                  end: const Offset(1.0, 1.0),
                  duration: 800.ms,
                ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Message with animated dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _displayMessage,
                style: AppTypography.bodyLarge.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 4),
              _AnimatedDots(),
            ],
          ),
        ],
      ),
    );
  }
}

/// Enhanced engaging loading widget with rotating messages, progress bar, and animations
class AIEngagingLoader extends StatefulWidget {
  final List<String> messages;
  final String? emoji;
  final Color? accentColor;

  AIEngagingLoader({
    super.key,
    List<String>? messages,
    this.emoji,
    this.accentColor,
  }) : messages = messages ?? _defaultMessages;

  static List<String> get _defaultMessages => [
    '${AIIdentity.name} يستكشف الأفكار...',
    'يبحث عن أفضل الخيارات...',
    'يحلل البيانات...',
    'جاري التفكير بعمق...',
    'لحظات ونكون جاهزين...',
  ];

  @override
  State<AIEngagingLoader> createState() => _AIEngagingLoaderState();
}

class _AIEngagingLoaderState extends State<AIEngagingLoader>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _glowController;
  int _currentMessageIndex = 0;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..forward();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Rotate messages every 2.5 seconds
    _messageTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (mounted) {
        setState(() {
          _currentMessageIndex =
              (_currentMessageIndex + 1) % widget.messages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _glowController.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.accentColor ?? AppColors.islamicGreenPrimary;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated AI avatar with glow
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor,
                      accentColor.withValues(alpha: 0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(
                        alpha: 0.3 + (_glowController.value * 0.3),
                      ),
                      blurRadius: 20 + (_glowController.value * 15),
                      spreadRadius: 2 + (_glowController.value * 5),
                    ),
                  ],
                ),
                child: Center(
                  child: widget.emoji != null
                      ? Text(
                          widget.emoji!,
                          style: const TextStyle(fontSize: 36),
                        )
                      : const Icon(
                          Icons.smart_toy_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                ),
              );
            },
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .rotate(begin: -0.02, end: 0.02, duration: 2000.ms),

          const SizedBox(height: AppSpacing.xl),

          // Rotating message with fade animation
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              widget.messages[_currentMessageIndex],
              key: ValueKey(_currentMessageIndex),
              style: AppTypography.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Progress bar
          Container(
            width: 200,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                return Stack(
                  children: [
                    // Background shimmer
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.05),
                              Colors.white.withValues(alpha: 0.1),
                              Colors.white.withValues(alpha: 0.05),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Progress fill
                    FractionallySizedBox(
                      widthFactor: _progressController.value.clamp(0.0, 0.95),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: LinearGradient(
                            colors: [
                              accentColor,
                              accentColor.withValues(alpha: 0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Sparkle dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                child: Icon(
                  Icons.auto_awesome,
                  size: 12,
                  color: accentColor.withValues(alpha: 0.6),
                ),
              )
                  .animate(
                    delay: Duration(milliseconds: index * 200),
                    onPlay: (c) => c.repeat(),
                  )
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1.2, 1.2),
                    duration: 600.ms,
                  )
                  .then()
                  .scale(
                    begin: const Offset(1.2, 1.2),
                    end: const Offset(0.5, 0.5),
                    duration: 600.ms,
                  );
            }),
          ),
        ],
      ),
    );
  }
}

/// Animated three dots indicator
class _AnimatedDots extends StatefulWidget {
  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
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
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.25;
            final value = ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);
            final opacity = (value < 0.5 ? value * 2 : 2 - value * 2).clamp(0.3, 1.0);

            return Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.islamicGreenLight.withValues(alpha: opacity),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Compact inline loading indicator for buttons
class AILoadingButton extends StatelessWidget {
  final String loadingText;
  final bool isLoading;
  final VoidCallback? onPressed;
  final String buttonText;
  final IconData? icon;

  const AILoadingButton({
    super.key,
    this.loadingText = 'جاري التحميل...',
    required this.isLoading,
    this.onPressed,
    required this.buttonText,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: isLoading ? null : AppColors.primaryGradient,
        color: isLoading ? Colors.white.withValues(alpha: 0.1) : null,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Center(
            child: isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        loadingText,
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Text(
                        buttonText,
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
