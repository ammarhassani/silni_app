import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/message_icons.dart';

/// Icon styles for message graphics
enum MessageIconStyle {
  /// Default - icon with subtle background
  defaultStyle,

  /// Filled - solid background circle
  filled,

  /// Outlined - border only, no fill
  outlined,

  /// Gradient - gradient background
  gradient,
}

/// A beautifully styled icon widget for messages
class MessageIconWidget extends StatelessWidget {
  final String? iconName;
  final double size;
  final Color? accentColor;
  final MessageIconStyle style;
  final bool animate;
  final Duration animationDuration;

  const MessageIconWidget({
    super.key,
    required this.iconName,
    this.size = 40,
    this.accentColor,
    this.style = MessageIconStyle.defaultStyle,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 600),
  });

  /// Create from icon style string
  factory MessageIconWidget.fromStyleString({
    Key? key,
    required String? iconName,
    double size = 40,
    Color? accentColor,
    String? styleString,
    bool animate = true,
  }) {
    return MessageIconWidget(
      key: key,
      iconName: iconName,
      size: size,
      accentColor: accentColor,
      style: _parseStyle(styleString),
      animate: animate,
    );
  }

  static MessageIconStyle _parseStyle(String? styleString) {
    switch (styleString?.toLowerCase()) {
      case 'filled':
        return MessageIconStyle.filled;
      case 'outlined':
        return MessageIconStyle.outlined;
      case 'gradient':
        return MessageIconStyle.gradient;
      default:
        return MessageIconStyle.defaultStyle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.colorScheme.primary;
    final icon = MessageIcons.getIcon(iconName);

    Widget iconWidget = _buildIconContainer(icon, color, theme);

    if (animate) {
      iconWidget = iconWidget
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.05, 1.05),
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
          );
    }

    return iconWidget;
  }

  Widget _buildIconContainer(IconData icon, Color color, ThemeData theme) {
    switch (style) {
      case MessageIconStyle.filled:
        return _buildFilledIcon(icon, color, theme);
      case MessageIconStyle.outlined:
        return _buildOutlinedIcon(icon, color, theme);
      case MessageIconStyle.gradient:
        return _buildGradientIcon(icon, color, theme);
      case MessageIconStyle.defaultStyle:
        return _buildDefaultIcon(icon, color, theme);
    }
  }

  Widget _buildDefaultIcon(IconData icon, Color color, ThemeData theme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha:0.15),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha:0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: size * 0.55,
        color: color,
      ),
    );
  }

  Widget _buildFilledIcon(IconData icon, Color color, ThemeData theme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha:0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: size * 0.55,
        color: Colors.white,
      ),
    );
  }

  Widget _buildOutlinedIcon(IconData icon, Color color, ThemeData theme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
      child: Icon(
        icon,
        size: size * 0.55,
        color: color,
      ),
    );
  }

  Widget _buildGradientIcon(IconData icon, Color color, ThemeData theme) {
    final endColor = HSLColor.fromColor(color)
        .withLightness((HSLColor.fromColor(color).lightness + 0.15).clamp(0.0, 1.0))
        .toColor();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha:0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: size * 0.55,
        color: Colors.white,
      ),
    );
  }
}

/// Small inline icon for banners and tooltips
class MessageIconBadge extends StatelessWidget {
  final String? iconName;
  final Color? accentColor;
  final double size;

  const MessageIconBadge({
    super.key,
    required this.iconName,
    this.accentColor,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.colorScheme.primary;
    final icon = MessageIcons.getIcon(iconName);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withValues(alpha:0.15),
      ),
      child: Icon(
        icon,
        size: size * 0.6,
        color: color,
      ),
    );
  }
}

/// Large hero icon for modals and full screen
class MessageHeroIcon extends StatelessWidget {
  final String? iconName;
  final Color? accentColor;
  final double size;
  final bool showGlow;

  const MessageHeroIcon({
    super.key,
    required this.iconName,
    this.accentColor,
    this.size = 88,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.colorScheme.primary;
    final icon = MessageIcons.getIcon(iconName);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow effect
        if (showGlow)
          Container(
            width: size * 1.3,
            height: size * 1.3,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha:0.3),
                  color.withValues(alpha:0.0),
                ],
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.1, 1.1),
                duration: const Duration(seconds: 2),
                curve: Curves.easeInOut,
              ),

        // Main icon container
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                color,
                HSLColor.fromColor(color)
                    .withLightness(
                        (HSLColor.fromColor(color).lightness + 0.1).clamp(0.0, 1.0))
                    .toColor(),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha:0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: size * 0.5,
            color: Colors.white,
          ),
        )
            .animate()
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.0, 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.elasticOut,
            ),
      ],
    );
  }
}
