import 'package:flutter/material.dart';
import '../../../core/services/message_service.dart';
import '../../../core/constants/message_icons.dart';
import 'message_icon_widget.dart';
import 'message_lottie_widget.dart';
import 'message_illustration.dart';

/// Factory for creating the appropriate graphic widget based on message type
class MessageGraphicFactory {
  MessageGraphicFactory._();

  /// Create a small badge-style graphic (for banners, tooltips)
  static Widget buildBadge({
    required Message message,
    double size = 32,
  }) {
    final color = message.accentColorParsed;

    switch (message.graphicType) {
      case 'lottie':
        return MessageLottieWidget(
          lottieName: message.lottieName,
          size: size,
          accentColor: color,
          repeat: true,
        );

      case 'emoji':
        return _buildEmojiBadge(message.iconName, size, color);

      case 'icon':
      default:
        return MessageIconBadge(
          iconName: message.iconName,
          accentColor: color,
          size: size,
        );
    }
  }

  /// Create a medium-sized graphic (for bottom sheets)
  static Widget buildMedium({
    required Message message,
    double size = 56,
  }) {
    final color = message.accentColorParsed;

    switch (message.graphicType) {
      case 'lottie':
        return MessageLottieWidget(
          lottieName: message.lottieName,
          size: size,
          accentColor: color,
          repeat: false,
        );

      case 'illustration':
        return MessageIllustration(
          illustrationUrl: message.illustrationUrl,
          width: size,
          height: size,
        );

      case 'emoji':
        return _buildEmojiCircle(message.iconName, size, color);

      case 'icon':
      default:
        return MessageIconWidget.fromStyleString(
          iconName: message.iconName,
          size: size,
          accentColor: color,
          styleString: message.iconStyle,
        );
    }
  }

  /// Create a large hero graphic (for modals, full-screen)
  static Widget buildHero({
    required Message message,
    double size = 88,
    bool showGlow = true,
  }) {
    final color = message.accentColorParsed;

    switch (message.graphicType) {
      case 'lottie':
        return MessageHeroLottie(
          lottieName: message.lottieName,
          size: size,
          accentColor: color,
          showGlow: showGlow,
        );

      case 'illustration':
        return MessageHeroIllustration(
          illustrationUrl: message.illustrationUrl,
          maxHeight: size * 1.5,
        );

      case 'emoji':
        return _buildHeroEmoji(message.iconName, size, color);

      case 'icon':
      default:
        return MessageHeroIcon(
          iconName: message.iconName,
          size: size,
          accentColor: color,
          showGlow: showGlow,
        );
    }
  }

  /// Create a full-screen background graphic
  static Widget? buildBackground({
    required Message message,
    Color? overlayColor,
  }) {
    switch (message.graphicType) {
      case 'lottie':
        if (message.lottieName != null) {
          return MessageBackgroundLottie(
            lottieName: message.lottieName,
            repeat: true,
          );
        }
        return null;

      case 'illustration':
        if (message.illustrationUrl != null) {
          return MessageBackgroundIllustration(
            illustrationUrl: message.illustrationUrl,
            overlayColor: overlayColor,
          );
        }
        return null;

      default:
        return null;
    }
  }

  // === Emoji Fallback Widgets ===

  static Widget _buildEmojiBadge(String? iconName, double size, Color? color) {
    final emoji = MessageIcons.getEmoji(iconName);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.2),
        color: (color ?? Colors.blue).withValues(alpha: 0.15),
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(fontSize: size * 0.6),
        ),
      ),
    );
  }

  static Widget _buildEmojiCircle(String? iconName, double size, Color? color) {
    final emoji = MessageIcons.getEmoji(iconName);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (color ?? Colors.blue).withValues(alpha: 0.15),
        boxShadow: [
          BoxShadow(
            color: (color ?? Colors.blue).withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(fontSize: size * 0.5),
        ),
      ),
    );
  }

  static Widget _buildHeroEmoji(String? iconName, double size, Color? color) {
    final emoji = MessageIcons.getEmoji(iconName);
    final effectiveColor = color ?? Colors.blue;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            effectiveColor,
            effectiveColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: effectiveColor.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(fontSize: size * 0.45),
        ),
      ),
    );
  }
}

/// Extension to get the appropriate graphic size for each message type
extension MessageGraphicSize on Message {
  /// Get recommended badge size
  double get badgeSize {
    switch (messageType) {
      case 'banner':
        return 36;
      case 'tooltip':
        return 24;
      default:
        return 32;
    }
  }

  /// Get recommended medium size
  double get mediumSize {
    switch (messageType) {
      case 'bottom_sheet':
        return 56;
      default:
        return 48;
    }
  }

  /// Get recommended hero size
  double get heroSize {
    switch (messageType) {
      case 'full_screen':
        return 120;
      case 'modal':
        return 88;
      default:
        return 80;
    }
  }
}
