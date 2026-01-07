import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Icon mappings for message graphics system
class MessageIcons {
  MessageIcons._();

  /// Map icon names to Lucide icons
  static IconData getIcon(String? iconName) {
    if (iconName == null) return LucideIcons.info;
    return _iconMap[iconName.toLowerCase()] ?? LucideIcons.info;
  }

  /// Check if icon name is valid
  static bool hasIcon(String? iconName) {
    if (iconName == null) return false;
    return _iconMap.containsKey(iconName.toLowerCase());
  }

  /// Get Lottie animation path
  static String? getLottiePath(String? lottieName) {
    if (lottieName == null) return null;
    return _lottieMap[lottieName.toLowerCase()];
  }

  /// Check if Lottie animation exists
  static bool hasLottie(String? lottieName) {
    if (lottieName == null) return false;
    return _lottieMap.containsKey(lottieName.toLowerCase());
  }

  /// Fallback emoji for legacy support
  static String getEmoji(String? iconName) {
    if (iconName == null) return 'ℹ️';
    return _emojiMap[iconName.toLowerCase()] ?? 'ℹ️';
  }

  /// Icon name to Lucide icon mapping
  static const Map<String, IconData> _iconMap = {
    // Notification icons
    'bell': LucideIcons.bell,
    'megaphone': LucideIcons.megaphone,
    'alert': LucideIcons.alertCircle,
    'info': LucideIcons.info,
    'announcement': LucideIcons.megaphone,

    // Celebration icons
    'star': LucideIcons.star,
    'sparkles': LucideIcons.sparkles,
    'party': LucideIcons.partyPopper,
    'gift': LucideIcons.gift,
    'celebration': LucideIcons.partyPopper,
    'trophy': LucideIcons.trophy,

    // Action icons
    'crown': LucideIcons.crown,
    'rocket': LucideIcons.rocket,
    'zap': LucideIcons.zap,
    'fire': LucideIcons.flame,
    'upgrade': LucideIcons.arrowUpCircle,

    // Engagement icons
    'heart': LucideIcons.heart,
    'users': LucideIcons.users,
    'tree': LucideIcons.treePine,
    'link': LucideIcons.link,
    'family': LucideIcons.users,

    // System icons
    'check': LucideIcons.checkCircle,
    'warning': LucideIcons.alertTriangle,
    'tip': LucideIcons.lightbulb,
    'lightbulb': LucideIcons.lightbulb,
    'help': LucideIcons.helpCircle,

    // Time & Islamic themed
    'moon': LucideIcons.moon,
    'sun': LucideIcons.sun,
    'calendar': LucideIcons.calendar,
    'clock': LucideIcons.clock,

    // Misc
    'message': LucideIcons.messageCircle,
    'mail': LucideIcons.mail,
    'bookmark': LucideIcons.bookmark,
    'settings': LucideIcons.settings,
    'home': LucideIcons.home,
    'quote': LucideIcons.quote,
  };

  /// Lottie animation paths
  static const Map<String, String> _lottieMap = {
    'celebration': 'assets/animations/messages/celebration_confetti.json',
    'celebration_confetti': 'assets/animations/messages/celebration_confetti.json',
    'confetti': 'assets/animations/messages/celebration_confetti.json',
    'success': 'assets/animations/messages/success_checkmark.json',
    'success_checkmark': 'assets/animations/messages/success_checkmark.json',
    'checkmark': 'assets/animations/messages/success_checkmark.json',
    'gift': 'assets/animations/messages/gift_unwrap.json',
    'gift_unwrap': 'assets/animations/messages/gift_unwrap.json',
    'levelup': 'assets/animations/messages/level_up_burst.json',
    'level_up': 'assets/animations/messages/level_up_burst.json',
    'level_up_burst': 'assets/animations/messages/level_up_burst.json',
    'moon': 'assets/animations/messages/moon_glow.json',
    'moon_glow': 'assets/animations/messages/moon_glow.json',
    'ramadan': 'assets/animations/messages/moon_glow.json',
    'sparkle': 'assets/animations/messages/sparkle_shimmer.json',
    'sparkle_shimmer': 'assets/animations/messages/sparkle_shimmer.json',
    'shimmer': 'assets/animations/messages/sparkle_shimmer.json',
  };

  /// Legacy emoji fallback map
  static const Map<String, String> _emojiMap = {
    'gift': '🎁',
    'star': '⭐',
    'fire': '🔥',
    'heart': '❤️',
    'bell': '🔔',
    'crown': '👑',
    'rocket': '🚀',
    'trophy': '🏆',
    'sparkles': '✨',
    'party': '🎉',
    'moon': '🌙',
    'sun': '☀️',
    'info': 'ℹ️',
    'warning': '⚠️',
    'check': '✅',
    'zap': '⚡',
    'lightbulb': '💡',
    'tip': '💡',
    'motivation': '💪',
    'reminder': '🔔',
    'announcement': '📢',
    'celebration': '🎉',
    'family': '👨‍👩‍👧‍👦',
    'users': '👥',
    'message': '💬',
    'quote': '💭',
  };
}
