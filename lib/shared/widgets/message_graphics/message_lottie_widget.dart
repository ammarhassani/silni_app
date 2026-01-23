import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../core/constants/message_icons.dart';

/// A Lottie animation widget for message graphics
class MessageLottieWidget extends StatefulWidget {
  final String? lottieName;
  final double size;
  final Color? accentColor;
  final bool repeat;
  final bool autoPlay;
  final VoidCallback? onComplete;

  const MessageLottieWidget({
    super.key,
    required this.lottieName,
    this.size = 100,
    this.accentColor,
    this.repeat = false,
    this.autoPlay = true,
    this.onComplete,
  });

  @override
  State<MessageLottieWidget> createState() => _MessageLottieWidgetState();
}

class _MessageLottieWidgetState extends State<MessageLottieWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    if (!widget.repeat) {
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete?.call();
        }
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
    final lottiePath = MessageIcons.getLottiePath(widget.lottieName);

    if (lottiePath == null) {
      // Fallback to icon if Lottie not found
      return _buildFallbackIcon();
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Lottie.asset(
        lottiePath,
        controller: _controller,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        onLoaded: (composition) {
          _controller.duration = composition.duration;
          if (widget.autoPlay) {
            if (widget.repeat) {
              _controller.repeat();
            } else {
              _controller.forward();
            }
          }
        },
        errorBuilder: (context, error, stackTrace) {
          // Lottie load error - showing fallback icon
          return _buildFallbackIcon();
        },
      ),
    );
  }

  Widget _buildFallbackIcon() {
    final color = widget.accentColor ?? Theme.of(context).colorScheme.primary;
    final icon = MessageIcons.getIcon(widget.lottieName);

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            color,
            color.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        icon,
        size: widget.size * 0.5,
        color: Colors.white,
      ),
    );
  }

  /// Play the animation from the beginning
  void play() {
    _controller.reset();
    if (widget.repeat) {
      _controller.repeat();
    } else {
      _controller.forward();
    }
  }

  /// Stop the animation
  void stop() {
    _controller.stop();
  }

  /// Reset the animation
  void reset() {
    _controller.reset();
  }
}

/// Hero Lottie animation for modals and celebrations
class MessageHeroLottie extends StatelessWidget {
  final String? lottieName;
  final double size;
  final Color? accentColor;
  final bool repeat;
  final bool showGlow;

  const MessageHeroLottie({
    super.key,
    required this.lottieName,
    this.size = 120,
    this.accentColor,
    this.repeat = false,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? Theme.of(context).colorScheme.primary;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow effect behind animation
        if (showGlow)
          Container(
            width: size * 1.4,
            height: size * 1.4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: 0.3),
                  color.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),

        // Lottie animation
        MessageLottieWidget(
          lottieName: lottieName,
          size: size,
          accentColor: accentColor,
          repeat: repeat,
        ),
      ],
    );
  }
}

/// Background Lottie animation (for confetti, particles, etc.)
class MessageBackgroundLottie extends StatelessWidget {
  final String? lottieName;
  final bool repeat;

  const MessageBackgroundLottie({
    super.key,
    required this.lottieName,
    this.repeat = true,
  });

  @override
  Widget build(BuildContext context) {
    final lottiePath = MessageIcons.getLottiePath(lottieName);

    if (lottiePath == null) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: Lottie.asset(
          lottiePath,
          fit: BoxFit.cover,
          repeat: repeat,
        ),
      ),
    );
  }
}
