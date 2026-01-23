import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cache_config_service.dart';

/// Unified Message model - consolidates MOTD, Banners, and In-App Messages
class Message {
  final String id;
  final String messageType; // banner, modal, bottom_sheet, tooltip, full_screen, motd
  final String titleAr;
  final String? bodyAr;
  final String? ctaTextAr;
  final String? ctaAction;
  final String? ctaActionType; // route, url, action, none
  final String? imageUrl;
  final int? imageWidth;
  final int? imageHeight;
  final double imageOverlayOpacity; // 0.0 to 1.0 (0=promotional, 0.3=default, 0.6=dark bg)
  final String? iconName;

  // Enhanced graphics system
  final String graphicType; // icon, lottie, illustration, emoji
  final String? lottieName; // Name of Lottie animation file
  final String? illustrationUrl; // URL to custom illustration
  final int? illustrationWidth;
  final int? illustrationHeight;
  final String iconStyle; // default, filled, outlined, gradient

  // Color mode: theme = adapts to user theme, custom = uses configured colors
  final String colorMode;

  final String backgroundColor;
  final String textColor;
  final String? accentColor;
  final Map<String, dynamic>? backgroundGradient;
  final int delaySeconds;
  final bool isDismissible;
  final int priority;

  Message({
    required this.id,
    required this.messageType,
    required this.titleAr,
    this.bodyAr,
    this.ctaTextAr,
    this.ctaAction,
    this.ctaActionType,
    this.imageUrl,
    this.imageWidth,
    this.imageHeight,
    this.imageOverlayOpacity = 0.3,
    this.iconName,
    this.graphicType = 'icon',
    this.lottieName,
    this.illustrationUrl,
    this.illustrationWidth,
    this.illustrationHeight,
    this.iconStyle = 'default',
    this.colorMode = 'theme',
    required this.backgroundColor,
    required this.textColor,
    this.accentColor,
    this.backgroundGradient,
    required this.delaySeconds,
    required this.isDismissible,
    required this.priority,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      messageType: json['message_type'] as String,
      titleAr: json['title_ar'] as String,
      bodyAr: json['body_ar'] as String?,
      ctaTextAr: json['cta_text_ar'] as String?,
      ctaAction: json['cta_action'] as String?,
      ctaActionType: json['cta_action_type'] as String?,
      imageUrl: json['image_url'] as String?,
      imageWidth: json['image_width'] as int?,
      imageHeight: json['image_height'] as int?,
      imageOverlayOpacity: (json['image_overlay_opacity'] as num?)?.toDouble() ?? 0.3,
      iconName: json['icon_name'] as String?,
      graphicType: json['graphic_type'] as String? ?? 'icon',
      lottieName: json['lottie_name'] as String?,
      illustrationUrl: json['illustration_url'] as String?,
      illustrationWidth: json['illustration_width'] as int?,
      illustrationHeight: json['illustration_height'] as int?,
      iconStyle: json['icon_style'] as String? ?? 'default',
      colorMode: json['color_mode'] as String? ?? 'theme',
      backgroundColor: json['background_color'] as String? ?? '#FFFFFF',
      textColor: json['text_color'] as String? ?? '#1F2937',
      accentColor: json['accent_color'] as String?,
      backgroundGradient: json['background_gradient'] as Map<String, dynamic>?,
      delaySeconds: json['delay_seconds'] as int? ?? 0,
      isDismissible: json['is_dismissible'] as bool? ?? true,
      priority: json['priority'] as int? ?? 0,
    );
  }

  // Graphic type helpers
  bool get usesIcon => graphicType == 'icon';
  bool get usesLottie => graphicType == 'lottie';
  bool get usesIllustration => graphicType == 'illustration';
  bool get usesEmoji => graphicType == 'emoji';

  // Color mode helpers
  bool get usesThemeColors => colorMode == 'theme';
  bool get usesCustomColors => colorMode == 'custom';

  /// Parse hex color string to Color
  Color get backgroundColorParsed => _parseColor(backgroundColor);
  Color get textColorParsed => _parseColor(textColor);
  Color? get accentColorParsed =>
      accentColor != null ? _parseColor(accentColor!) : null;

  /// Get gradient colors if available
  LinearGradient? get gradientParsed {
    if (backgroundGradient == null) return null;
    final start = backgroundGradient!['start'] as String?;
    final end = backgroundGradient!['end'] as String?;
    if (start == null || end == null) return null;
    return LinearGradient(
      colors: [_parseColor(start), _parseColor(end)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static Color _parseColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Check message type
  bool get isBanner => messageType == 'banner';
  bool get isModal => messageType == 'modal';
  bool get isBottomSheet => messageType == 'bottom_sheet';
  bool get isTooltip => messageType == 'tooltip';
  bool get isFullScreen => messageType == 'full_screen';
  bool get isMOTD => messageType == 'motd';

  /// Check if this message has an action
  bool get hasAction => ctaAction != null && ctaAction!.isNotEmpty;
  bool get isUrlAction => ctaActionType == 'url';
  bool get isRouteAction => ctaActionType == 'route' || ctaActionType == null;
}

/// Unified Message Service - replaces InAppMessageService, MOTD, and Banner services
class MessageService {
  MessageService._();
  static final MessageService instance = MessageService._();

  final _supabase = Supabase.instance.client;
  final CacheConfigService _cacheConfig = CacheConfigService();

  // Session tracking
  final Set<String> _shownInSession = {};
  static const String _serviceKey = 'messages';

  /// Initialize the service
  Future<void> initialize() async {
    // Pre-warm cache if needed
  }

  // ==================== FETCH METHODS ====================

  /// Get messages for a specific screen
  Future<List<Message>> getMessagesForScreen(
    String screenPath, {
    String userTier = 'free',
    String platform = 'ios',
  }) {
    return _fetchMessages(
      triggerType: 'screen_view',
      triggerValue: screenPath,
      userTier: userTier,
      platform: platform,
    );
  }

  /// Get messages for a specific position (legacy banner positions)
  Future<List<Message>> getMessagesForPosition(
    String position, {
    String userTier = 'free',
    String platform = 'ios',
  }) {
    return _fetchMessages(
      triggerType: 'position',
      triggerValue: position,
      userTier: userTier,
      platform: platform,
    );
  }

  /// Get messages for app open event
  Future<List<Message>> getMessagesForAppOpen({
    String userTier = 'free',
    String platform = 'ios',
  }) {
    return _fetchMessages(
      triggerType: 'app_open',
      userTier: userTier,
      platform: platform,
    );
  }

  /// Get messages for a custom event
  Future<List<Message>> getMessagesForEvent(
    String eventName, {
    String userTier = 'free',
    String platform = 'ios',
  }) {
    return _fetchMessages(
      triggerType: 'event',
      triggerValue: eventName,
      userTier: userTier,
      platform: platform,
    );
  }

  /// Convenience: Get MOTD for home screen
  Future<Message?> getMOTD({
    String userTier = 'free',
    String platform = 'ios',
  }) async {
    final messages = await _fetchMessages(
      triggerType: 'screen_view',
      triggerValue: '/home',
      userTier: userTier,
      platform: platform,
      messageTypeFilter: 'motd',
    );
    return messages.isNotEmpty ? messages.first : null;
  }

  /// Convenience: Get banners for a position (backward compatibility)
  Future<List<Message>> getBannersForPosition(
    String position, {
    String userTier = 'free',
    String platform = 'ios',
  }) {
    return getMessagesForPosition(
      position,
      userTier: userTier,
      platform: platform,
    );
  }

  /// Core fetch method
  Future<List<Message>> _fetchMessages({
    required String triggerType,
    String? triggerValue,
    String userTier = 'free',
    String platform = 'ios',
    String? messageTypeFilter,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        return [];
      }

      final response = await _supabase.rpc('get_applicable_messages', params: {
        'p_user_id': userId,
        'p_trigger_type': triggerType,
        'p_trigger_value': triggerValue,
        'p_user_tier': userTier,
        'p_platform': platform,
      });

      if (response == null) {
        return [];
      }

      // Don't filter by session on client - backend RPC handles display_frequency
      var messages = (response as List)
          .map((json) => Message.fromJson(json))
          .toList();

      // Apply message type filter if specified
      if (messageTypeFilter != null) {
        messages = messages.where((m) => m.messageType == messageTypeFilter).toList();
      }

      return messages;
    } catch (_) {
      return [];
    }
  }

  // ==================== ANALYTICS ====================

  /// Record that a message was shown (detailed tracking)
  Future<void> recordImpression(
    String messageId, {
    String? screen,
    String? platform,
    String? appVersion,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Record detailed impression
      await _supabase.rpc('record_message_impression', params: {
        'p_user_id': userId,
        'p_message_id': messageId,
        'p_screen': screen,
        'p_platform': platform,
        'p_app_version': appVersion,
      });

      // Also increment simple counter
      await _supabase.rpc('increment_message_impressions', params: {
        'p_message_id': messageId,
      });

      _shownInSession.add(messageId);
    } catch (_) {
      // Impression recording failed silently
    }
  }

  /// Record message click
  Future<void> recordClick(String messageId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.rpc('record_message_interaction', params: {
        'p_user_id': userId,
        'p_message_id': messageId,
        'p_interaction_type': 'click',
      });

      // Also increment simple counter
      await _supabase.rpc('increment_message_clicks', params: {
        'p_message_id': messageId,
      });
    } catch (_) {
      // Click recording failed silently
    }
  }

  /// Record message dismiss
  Future<void> recordDismiss(String messageId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.rpc('record_message_interaction', params: {
        'p_user_id': userId,
        'p_message_id': messageId,
        'p_interaction_type': 'dismiss',
      });
    } catch (_) {
      // Dismiss recording failed silently
    }
  }

  // ==================== SESSION MANAGEMENT ====================

  /// Mark message as shown in this session
  void markShownInSession(String messageId) {
    _shownInSession.add(messageId);
  }

  /// Clear session shown tracking (call on logout)
  void clearSession() {
    _shownInSession.clear();
  }

  /// Check if cache needs refresh
  bool get needsRefresh {
    return _cacheConfig.isCacheExpired(_serviceKey, null);
  }
}
