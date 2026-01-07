import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_animations.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/services/message_service.dart';
import '../../core/router/navigation_service.dart';
import 'message_graphics/message_graphics.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/models/subscription_tier.dart';

// ==================== HELPER WIDGETS ====================

/// Glassmorphic Container - Premium frosted glass effect
/// Used for banners and premium overlays
class _GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color? tintColor;
  final double borderRadius;
  final EdgeInsets? padding;
  final BoxBorder? border;

  const _GlassmorphicContainer({
    required this.child,
    this.blur = 12,
    this.opacity = 0.15,
    this.tintColor,
    this.borderRadius = 16,
    this.padding,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = tintColor ?? (isDark ? Colors.white : Colors.black);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ?? Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.2 : 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: tint.withValues(alpha: 0.1),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Floating Sparkles Background - For full screen celebrations
class _FloatingSparkles extends StatelessWidget {
  final int count;
  final Color color;

  const _FloatingSparkles({
    this.count = 15,
    this.color = Colors.white30,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final random = Random();
        return Stack(
          children: List.generate(count, (i) {
            final left = random.nextDouble() * constraints.maxWidth;
            final top = random.nextDouble() * constraints.maxHeight;
            final size = 4.0 + random.nextDouble() * 6;
            final delay = Duration(milliseconds: i * 150);

            return Positioned(
              left: left,
              top: top,
              child: Icon(
                Icons.star,
                size: size,
                color: color,
              )
                  .animate(onPlay: (c) => c.repeat())
                  .fadeIn(duration: 400.ms, delay: delay)
                  .then()
                  .moveY(begin: 0, end: -40, duration: 3000.ms, curve: Curves.easeInOut)
                  .fadeOut(delay: 2500.ms)
                  .then()
                  .moveY(begin: 40, end: 0, duration: 0.ms),
            );
          }),
        );
      },
    );
  }
}

/// Unified Message Widget - replaces BannerWidget, MOTDWidget, InAppMessageWidget
/// Renders different message types with appropriate UI
///
/// Dismissal behavior (all message types):
/// - Dismissed messages are tracked in memory only (_dismissedIds)
/// - On hot restart or app kill/relaunch, dismissed messages will reappear
/// - This is intentional - permanent dismissal is controlled by backend display_frequency
class MessageWidget extends ConsumerStatefulWidget {
  /// Screen path for screen_view trigger (e.g., '/home', '/profile')
  final String? screenPath;

  /// Position for position-based messages (e.g., 'home_top', 'profile')
  final String? position;

  /// Trigger type (defaults to screen_view if screenPath provided, position if position provided)
  final String? triggerType;

  /// Filter by message type (null = all types)
  final String? messageType;

  const MessageWidget({
    super.key,
    this.screenPath,
    this.position,
    this.triggerType,
    this.messageType,
  });

  @override
  ConsumerState<MessageWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends ConsumerState<MessageWidget> {
  final _service = MessageService.instance;
  List<Message> _messages = [];
  final Set<String> _dismissedIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // On widget init, dismissedIds is empty - all messages can appear
    debugPrint('[MessageWidget] initState - dismissedIds cleared, messages will load fresh');
    // Load messages on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
    });
  }

  @override
  void didUpdateWidget(MessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if trigger changed
    if (oldWidget.screenPath != widget.screenPath ||
        oldWidget.position != widget.position ||
        oldWidget.triggerType != widget.triggerType) {
      _loadMessages();
    }
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final platform = Theme.of(context).platform == TargetPlatform.iOS
          ? 'ios'
          : 'android';

      // Get user tier from subscription provider
      final tier = ref.read(subscriptionTierProvider);
      final userTier = tier.id; // 'free' or 'max'

      List<Message> messages;

      debugPrint('[MessageWidget] Loading messages...');
      debugPrint('  - screenPath: ${widget.screenPath}');
      debugPrint('  - position: ${widget.position}');
      debugPrint('  - userTier: $userTier');
      debugPrint('  - platform: $platform');

      if (widget.position != null) {
        // Position-based (legacy banner positions)
        debugPrint('[MessageWidget] Fetching for position: ${widget.position}');
        messages = await _service.getMessagesForPosition(
          widget.position!,
          userTier: userTier,
          platform: platform,
        );
      } else if (widget.screenPath != null) {
        // Screen-based
        final routePath = widget.screenPath!.startsWith('/')
            ? widget.screenPath!
            : '/${widget.screenPath!}';

        debugPrint('[MessageWidget] Fetching for screen: $routePath');
        messages = await _service.getMessagesForScreen(
          routePath,
          userTier: userTier,
          platform: platform,
        );
      } else if (widget.triggerType == 'app_open') {
        debugPrint('[MessageWidget] Fetching for app_open');
        messages = await _service.getMessagesForAppOpen(
          userTier: userTier,
          platform: platform,
        );
      } else {
        debugPrint('[MessageWidget] No valid trigger - returning empty');
        messages = [];
      }

      debugPrint('[MessageWidget] Received ${messages.length} messages');
      for (final m in messages) {
        debugPrint('  - ${m.id}: ${m.titleAr} (type: ${m.messageType})');
      }

      // Filter by message type if specified
      if (widget.messageType != null) {
        messages = messages
            .where((m) => m.messageType == widget.messageType)
            .toList();
        debugPrint('[MessageWidget] After type filter: ${messages.length} messages');
      }

      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      debugPrint('[MessageWidget] Error loading messages: $e');
      debugPrint('[MessageWidget] Stack: $stack');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Dismiss message for current session only
  /// Message will reappear after hot restart or app kill/relaunch
  void _dismissMessage(Message message) {
    debugPrint('[MessageWidget] Dismissing message: ${message.id} (${message.messageType})');
    debugPrint('[MessageWidget] Session-only dismissal - will reappear on app restart');
    _service.recordDismiss(message.id); // Analytics only
    if (mounted) {
      setState(() {
        _dismissedIds.add(message.id);
      });
    }
  }

  void _handleMessageTap(Message message) {
    _service.recordClick(message.id);

    if (message.hasAction) {
      if (message.isUrlAction) {
        _launchUrl(message.ctaAction!);
      } else {
        NavigationService.pushTo(message.ctaAction!);
      }
    }

    // Dismiss after action
    if (mounted) {
      setState(() {
        _dismissedIds.add(message.id);
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _recordImpression(Message message) {
    final routePath = widget.screenPath ?? widget.position ?? '';
    _service.recordImpression(
      message.id,
      screen: routePath,
      platform: Theme.of(context).platform == TargetPlatform.iOS
          ? 'ios'
          : 'android',
    );
  }

  // Track shown overlays to avoid duplicates within same session
  // Clears on hot restart/app kill - overlays will show again
  final Set<String> _shownOverlays = {};

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    // Filter out dismissed messages
    final visibleMessages = _messages
        .where((m) => !_dismissedIds.contains(m.id))
        .toList();

    if (visibleMessages.isEmpty) return const SizedBox.shrink();

    // Separate overlay messages from inline messages
    final overlayMessages = visibleMessages.where((m) =>
        m.messageType == 'modal' ||
        m.messageType == 'bottom_sheet' ||
        m.messageType == 'full_screen').toList();

    final inlineMessages = visibleMessages.where((m) =>
        m.messageType != 'modal' &&
        m.messageType != 'bottom_sheet' &&
        m.messageType != 'full_screen').toList();

    // Show overlay messages after build
    if (overlayMessages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final message in overlayMessages) {
          if (!_shownOverlays.contains(message.id)) {
            debugPrint('[MessageWidget] Showing overlay: ${message.id} (${message.messageType})');
            _shownOverlays.add(message.id);
            _showOverlayMessage(message);
          } else {
            debugPrint('[MessageWidget] Overlay already shown this session: ${message.id}');
          }
        }
      });
    }

    // Show inline messages normally
    if (inlineMessages.isEmpty) return const SizedBox.shrink();

    // Show only the highest priority inline message
    final message = inlineMessages.first;
    debugPrint('[MessageWidget] Rendering inline message: ${message.id} (${message.messageType})');

    // Record impression when message is displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordImpression(message);
    });

    // Render based on message type
    return _buildMessageWidget(message);
  }

  /// Show overlay-based messages (modal, bottom_sheet, full_screen)
  void _showOverlayMessage(Message message) {
    if (!mounted) return;

    _recordImpression(message);

    // Apply delay if specified
    final delay = Duration(seconds: message.delaySeconds);
    Future.delayed(delay, () {
      if (!mounted) return;

      switch (message.messageType) {
        case 'modal':
          _showModalMessage(message);
          break;
        case 'bottom_sheet':
          _showBottomSheetMessage(message);
          break;
        case 'full_screen':
          _showFullScreenMessage(message);
          break;
      }
    });
  }

  /// MODAL - Celebration Dialog with Confetti
  /// Premium dialog with glow border and celebration animations
  /// For achievements, level-ups, and important announcements
  void _showModalMessage(Message message) {
    debugPrint('[MessageWidget] _showModalMessage called for: ${message.id}');
    final themeColors = ref.read(themeColorsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = message.accentColorParsed ?? themeColors.primary;

    // Create confetti controller
    final confettiController = ConfettiController(duration: const Duration(seconds: 2));

    showGeneralDialog(
      context: context,
      barrierDismissible: message.isDismissible,
      barrierLabel: 'Modal Message',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        // Fire confetti after dialog opens
        WidgetsBinding.instance.addPostFrameCallback((_) {
          confettiController.play();
        });

        return PopScope(
          canPop: message.isDismissible,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) confettiController.dispose();
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Dialog content
              Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 320),
                  decoration: BoxDecoration(
                    color: themeColors.surface,
                    borderRadius: BorderRadius.circular(28),
                    // Glow border effect
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.25),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dismiss button (top-left)
                      if (message.isDismissible)
                        Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: GestureDetector(
                              onTap: () {
                                confettiController.dispose();
                                Navigator.of(dialogContext).pop();
                                _dismissMessage(message);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: themeColors.divider.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: themeColors.textHint,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Content
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          24,
                          message.isDismissible ? 0 : 28,
                          24,
                          24,
                        ),
                        child: Column(
                          children: [
                            // Hero icon/animation using new graphics system
                            if (message.iconName != null || message.usesLottie || message.usesIllustration)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: MessageGraphicFactory.buildHero(
                                  message: message,
                                  size: 88,
                                  showGlow: true,
                                ),
                              ),

                            // Title
                            Text(
                              message.titleAr,
                              style: AppTypography.headlineSmall.copyWith(
                                color: themeColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                              textAlign: TextAlign.center,
                            )
                                .animate()
                                .fadeIn(delay: 200.ms, duration: 300.ms)
                                .slideY(begin: 0.3, end: 0, delay: 200.ms),

                            // Body
                            if (message.bodyAr != null && message.bodyAr!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                message.bodyAr!,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: themeColors.textSecondary,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              )
                                  .animate()
                                  .fadeIn(delay: 350.ms, duration: 300.ms)
                                  .slideY(begin: 0.3, end: 0, delay: 350.ms),
                            ],

                            // CTA Button with gradient
                            if (message.hasAction) ...[
                              const SizedBox(height: 24),
                              GestureDetector(
                                onTap: () {
                                  confettiController.dispose();
                                  Navigator.of(dialogContext).pop();
                                  _handleMessageTap(message);
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        accentColor,
                                        accentColor.withValues(alpha: 0.85),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accentColor.withValues(alpha: 0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    message.ctaTextAr ?? 'رائع!',
                                    style: AppTypography.labelLarge.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                                  .animate()
                                  .fadeIn(delay: 500.ms, duration: 200.ms)
                                  .scale(
                                    begin: const Offset(0.9, 0.9),
                                    end: const Offset(1.0, 1.0),
                                    delay: 500.ms,
                                    duration: 200.ms,
                                  )
                                  .then(delay: 400.ms)
                                  .animate(onPlay: (c) => c.repeat(reverse: true, count: 2))
                                  .scale(
                                    begin: const Offset(1.0, 1.0),
                                    end: const Offset(1.02, 1.02),
                                    duration: 400.ms,
                                  ),
                            ],

                            // Skip text link
                            if (message.isDismissible && message.hasAction) ...[
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () {
                                  confettiController.dispose();
                                  Navigator.of(dialogContext).pop();
                                  _dismissMessage(message);
                                },
                                child: Text(
                                  'تخطي',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: themeColors.textHint,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Confetti overlay
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  particleDrag: 0.05,
                  emissionFrequency: 0.05,
                  numberOfParticles: 25,
                  gravity: 0.15,
                  colors: [
                    accentColor,
                    accentColor.withValues(alpha: 0.7),
                    Colors.amber,
                    Colors.orange,
                    Colors.pink,
                    Colors.purple,
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// BOTTOM SHEET - Action Panel with Spring Physics
  /// Solid surface with drag handle and horizontal layout
  /// For feature announcements and contextual actions
  void _showBottomSheetMessage(Message message) {
    debugPrint('[MessageWidget] _showBottomSheetMessage called for: ${message.id}');
    final themeColors = ref.read(themeColorsProvider);
    final accentColor = message.accentColorParsed ?? themeColors.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: message.isDismissible,
      enableDrag: message.isDismissible,
      isScrollControlled: true,
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 350),
      ),
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: themeColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle with hint animation
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: themeColors.textHint.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              )
                  .animate(delay: 800.ms, onPlay: (c) => c.repeat(count: 2, reverse: true))
                  .moveY(begin: 0, end: 3, duration: 300.ms),

              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row: Icon badge + Title + Close
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon badge - using new graphics system
                        if (message.iconName != null || message.usesLottie) ...[
                          MessageGraphicFactory.buildMedium(
                            message: message,
                            size: 56,
                          ),
                          const SizedBox(width: 16),
                        ],

                        // Title & Description
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.titleAr,
                                style: AppTypography.titleMedium.copyWith(
                                  color: themeColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              )
                                  .animate()
                                  .fadeIn(delay: 150.ms, duration: 200.ms),

                              if (message.bodyAr != null && message.bodyAr!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  message.bodyAr!,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: themeColors.textSecondary,
                                    height: 1.5,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                )
                                    .animate()
                                    .fadeIn(delay: 250.ms, duration: 200.ms),
                              ],
                            ],
                          ),
                        ),

                        // Close button
                        if (message.isDismissible && !message.hasAction) ...[
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              _dismissMessage(message);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: themeColors.divider.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: themeColors.textHint,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    // CTA Button - full width with gradient
                    if (message.hasAction) ...[
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          _handleMessageTap(message);
                        },
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accentColor,
                                accentColor.withValues(alpha: 0.85),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              message.ctaTextAr ?? 'جرب الآن',
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 350.ms, duration: 200.ms)
                          .slideY(begin: 0.2, end: 0, delay: 350.ms),
                    ],

                    // Secondary dismiss link
                    if (message.isDismissible && message.hasAction) ...[
                      const SizedBox(height: 14),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            _dismissMessage(message);
                          },
                          child: Text(
                            'ربما لاحقاً',
                            style: AppTypography.labelSmall.copyWith(
                              color: themeColors.textHint,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// FULL SCREEN - Immersive Celebration with Particles
  /// Rich gradient background with floating sparkles
  /// For major milestones, onboarding completion, special events
  void _showFullScreenMessage(Message message) {
    debugPrint('[MessageWidget] _showFullScreenMessage called for: ${message.id}');
    final accentColor = message.accentColorParsed ?? Theme.of(context).primaryColor;

    // Darker shade for gradient
    final accentDark = HSLColor.fromColor(accentColor)
        .withLightness((HSLColor.fromColor(accentColor).lightness - 0.15).clamp(0.0, 1.0))
        .toColor();

    showGeneralDialog(
      context: context,
      barrierDismissible: message.isDismissible,
      barrierLabel: 'Full Screen Message',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 500),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return PopScope(
          canPop: message.isDismissible,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                // Rich gradient background
                Container(
                  decoration: BoxDecoration(
                    gradient: message.gradientParsed ??
                        LinearGradient(
                          colors: [accentColor, accentDark],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                  ),
                ),

                // Radial glow overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                        radius: 0.8,
                        center: const Alignment(0, -0.3),
                      ),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1.0, 1.0),
                        end: const Offset(1.2, 1.2),
                        duration: 3000.ms,
                        curve: Curves.easeInOut,
                      ),
                ),

                // Floating sparkles background
                const Positioned.fill(
                  child: _FloatingSparkles(count: 20, color: Colors.white24),
                ),

                // Main content
                SafeArea(
                  child: Column(
                    children: [
                      // Close button - glassmorphic circle
                      Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                              _dismissMessage(message);
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 22,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Hero content centered
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Hero graphic using new graphics system
                                if (message.iconName != null || message.usesLottie || message.usesIllustration)
                                  MessageGraphicFactory.buildHero(
                                    message: message,
                                    size: 120,
                                    showGlow: true,
                                  ),

                                const SizedBox(height: 40),

                                // Hero title
                                Text(
                                  message.titleAr,
                                  style: AppTypography.headlineMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 28,
                                  ),
                                  textAlign: TextAlign.center,
                                )
                                    .animate()
                                    .fadeIn(delay: 300.ms, duration: 400.ms)
                                    .slideY(begin: 0.5, end: 0, delay: 300.ms, curve: Curves.easeOutCubic),

                                // Body text
                                if (message.bodyAr != null && message.bodyAr!.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    message.bodyAr!,
                                    style: AppTypography.bodyLarge.copyWith(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      height: 1.6,
                                      fontSize: 17,
                                    ),
                                    textAlign: TextAlign.center,
                                  )
                                      .animate()
                                      .fadeIn(delay: 500.ms, duration: 400.ms)
                                      .slideY(begin: 0.3, end: 0, delay: 500.ms),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),

                      // CTA Button - glassmorphic style
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(dialogContext).pop();
                            if (message.hasAction) {
                              _handleMessageTap(message);
                            } else {
                              _dismissMessage(message);
                            }
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    message.ctaTextAr ?? (message.hasAction ? 'شارك إنجازك' : 'رائع!'),
                                    style: AppTypography.titleMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 800.ms, duration: 300.ms)
                          .slideY(begin: 0.5, end: 0, delay: 800.ms, curve: Curves.easeOutBack)
                          .then(delay: 400.ms)
                          .shimmer(duration: 1500.ms, color: Colors.white.withValues(alpha: 0.2)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageWidget(Message message) {
    switch (message.messageType) {
      case 'motd':
        return _buildMOTDMessage(message);
      case 'banner':
        return _buildBannerMessage(message);
      case 'tooltip':
        return _buildTooltipMessage(message);
      default:
        // Fallback for unknown types
        return _buildBannerMessage(message);
    }
  }

  /// BANNER - Glassmorphic Notification Bar
  /// Premium frosted glass effect with subtle shimmer
  /// Compact, non-intrusive notification style
  Widget _buildBannerMessage(Message message) {
    final themeColors = ref.watch(themeColorsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = message.accentColorParsed ?? themeColors.primary;

    // Check if has image - use image banner variant
    if (message.imageUrl != null && message.imageUrl!.isNotEmpty) {
      return _buildImageBanner(message, themeColors);
    }

    // Determine tint color based on accent (for visual context)
    final tintColor = accentColor.withValues(alpha: 0.2);

    return Semantics(
      label: 'رسالة: ${message.titleAr}',
      button: message.hasAction,
      child: GestureDetector(
        onTap: message.hasAction ? () => _handleMessageTap(message) : null,
        child: _GlassmorphicContainer(
          blur: 12,
          opacity: isDark ? 0.25 : 0.2,
          tintColor: tintColor,
          borderRadius: 12,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Icon - using new graphics system
              if (message.iconName != null || message.usesLottie) ...[
                MessageGraphicFactory.buildBadge(
                  message: message,
                  size: 36,
                ),
                const SizedBox(width: 12),
              ],

              // Content - single line title + optional subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.titleAr,
                      style: AppTypography.labelMedium.copyWith(
                        color: isDark ? Colors.white : themeColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (message.bodyAr != null && message.bodyAr!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        message.bodyAr!,
                        style: AppTypography.bodySmall.copyWith(
                          color: (isDark ? Colors.white : themeColors.textSecondary)
                              .withValues(alpha: 0.85),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // CTA arrow or dismiss
              if (message.hasAction) ...[
                const SizedBox(width: 8),
                Icon(
                  message.isUrlAction ? Icons.open_in_new_rounded : Icons.arrow_back_ios_rounded,
                  size: 16,
                  color: accentColor,
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveX(begin: 0, end: -3, duration: 800.ms),
              ],
              if (message.isDismissible) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _dismissMessage(message),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: isDark ? Colors.white70 : themeColors.textHint,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 200.ms)
        .slideY(begin: -1, end: 0, curve: Curves.easeOutCubic, duration: 300.ms)
        .then()
        .shimmer(
          duration: 1500.ms,
          color: Colors.white.withValues(alpha: 0.15),
          delay: 400.ms,
        );
  }

  Widget _buildImageBanner(Message message, dynamic themeColors) {
    return Semantics(
      label: 'رسالة: ${message.titleAr}',
      button: message.hasAction,
      child: GestureDetector(
        onTap: message.hasAction ? () => _handleMessageTap(message) : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Stack(
            children: [
              // Background image
              Image.network(
                message.imageUrl!,
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to gradient
                  return Container(
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          themeColors.primary.withValues(alpha: 0.9),
                          themeColors.primary.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.black.withValues(alpha: 0.2),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ),

              // Content
              Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.titleAr,
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (message.bodyAr != null && message.bodyAr!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        message.bodyAr!,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (message.hasAction) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            message.ctaTextAr ?? 'اضغط للمزيد',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            message.isUrlAction ? Icons.open_in_new : Icons.arrow_back_ios,
                            size: 12,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Dismiss button
              if (message.isDismissible)
                Positioned(
                  top: AppSpacing.xs,
                  left: AppSpacing.xs,
                  child: GestureDetector(
                    onTap: () => _dismissMessage(message),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: AppAnimations.fast)
        .fadeIn(duration: AppAnimations.normal)
        .slideY(begin: -0.2, end: 0);
  }

  /// MOTD - Inspirational Quote Card
  /// Elegant card with decorative left border and quote typography
  /// For daily wisdom, hadith, and motivational content
  Widget _buildMOTDMessage(Message message) {
    final themeColors = ref.watch(themeColorsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = message.accentColorParsed ?? themeColors.primary;

    return Semantics(
      label: 'رسالة اليوم: ${message.titleAr}',
      button: message.hasAction,
      child: GestureDetector(
        onTap: message.hasAction ? () => _handleMessageTap(message) : null,
        child: Container(
          decoration: BoxDecoration(
            color: themeColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                // Decorative left border
                border: Border(
                  right: BorderSide(
                    color: accentColor,
                    width: 4,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Quote section with decorative marks
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Opening quote mark
                        Text(
                          '»',
                          style: TextStyle(
                            fontSize: 32,
                            color: accentColor.withValues(alpha: 0.4),
                            fontWeight: FontWeight.bold,
                            height: 0.8,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Main quote content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.titleAr,
                                style: AppTypography.titleMedium.copyWith(
                                  color: themeColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                  height: 1.7,
                                  fontSize: 17,
                                ),
                              )
                                  .animate()
                                  .fadeIn(delay: 200.ms, duration: 300.ms)
                                  .slideY(begin: 0.2, end: 0, delay: 200.ms, duration: 300.ms),

                              if (message.bodyAr != null && message.bodyAr!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  message.bodyAr!,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: themeColors.textSecondary,
                                    height: 1.6,
                                  ),
                                )
                                    .animate()
                                    .fadeIn(delay: 350.ms, duration: 300.ms),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),
                        // Closing quote mark
                        Text(
                          '«',
                          style: TextStyle(
                            fontSize: 32,
                            color: accentColor.withValues(alpha: 0.4),
                            fontWeight: FontWeight.bold,
                            height: 0.8,
                          ),
                        ),
                      ],
                    ),

                    // Footer divider
                    if (message.iconName != null || message.hasAction || message.isDismissible) ...[
                      const SizedBox(height: 16),
                      Container(
                        height: 1,
                        color: themeColors.divider.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),

                      // Footer row
                      Row(
                        children: [
                          // Icon + label using new graphics system
                          if (message.iconName != null) ...[
                            MessageGraphicFactory.buildBadge(
                              message: message,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'رسالة اليوم',
                              style: AppTypography.labelSmall.copyWith(
                                color: themeColors.textHint,
                              ),
                            ),
                          ],

                          const Spacer(),

                          // CTA link with arrow animation
                          if (message.hasAction && message.ctaTextAr != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  message.ctaTextAr!,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: accentColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_back_ios_rounded,
                                  size: 10,
                                  color: accentColor,
                                )
                                    .animate(onPlay: (c) => c.repeat(reverse: true))
                                    .moveX(begin: 0, end: -4, duration: 800.ms),
                              ],
                            ),

                          // Dismiss button
                          if (message.isDismissible && !message.hasAction) ...[
                            GestureDetector(
                              onTap: () => _dismissMessage(message),
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: themeColors.textHint,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, curve: Curves.easeOut);
  }

  /// TOOLTIP - Floating Hint Pill
  /// Fully adaptive - uses theme colors (glassmorphic) or custom admin colors
  /// Quick tips and contextual hints - tap anywhere to dismiss
  Widget _buildTooltipMessage(Message message) {
    debugPrint('[MessageWidget] Building tooltip: ${message.id}');
    final themeColors = ref.watch(themeColorsProvider);
    final accentColor = message.accentColorParsed ?? themeColors.primary;

    // Color mode from admin: theme = glassmorphic, custom = use configured colors
    final useThemeMode = message.usesThemeColors;
    final gradient = message.gradientParsed;

    // Determine text colors based on color mode
    final Color effectiveTextColor;
    final Color secondaryTextColor;
    if (useThemeMode) {
      // Theme mode - use theme colors (glassmorphic will adapt)
      effectiveTextColor = themeColors.textPrimary;
      secondaryTextColor = themeColors.textSecondary;
    } else {
      // Custom mode - use admin-configured colors with auto-contrast
      final isLightBg = message.backgroundColorParsed.computeLuminance() > 0.5;
      effectiveTextColor = message.textColorParsed;
      secondaryTextColor = isLightBg ? Colors.black54 : Colors.white70;
    }

    // Build content row
    Widget buildContentRow() => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.iconName != null || message.usesLottie) ...[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: MessageGraphicFactory.buildBadge(
                  message: message,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.titleAr,
                    style: AppTypography.labelMedium.copyWith(
                      color: effectiveTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (message.bodyAr != null && message.bodyAr!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      message.bodyAr!,
                      style: AppTypography.bodySmall.copyWith(
                        color: secondaryTextColor,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (message.hasAction || message.isDismissible) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  message.hasAction
                      ? Icons.arrow_back_ios_rounded
                      : Icons.close_rounded,
                  size: 10,
                  color: accentColor,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveX(
                    begin: 0,
                    end: message.hasAction ? -2 : 0,
                    duration: 600.ms,
                  ),
            ],
          ],
        );

    // Build tooltip container
    Widget tooltipContent;
    if (useThemeMode) {
      // Theme mode - glassmorphic blur that adapts to whatever is behind
      tooltipContent = Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                // Minimal neutral overlay - just enough for blur effect
                color: Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 0.5,
                ),
              ),
              child: buildContentRow(),
            ),
          ),
        ),
      );
    } else {
      // Custom background from admin
      tooltipContent = Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: gradient == null ? message.backgroundColorParsed : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: buildContentRow(),
      );
    }

    return Semantics(
      label: 'تلميح: ${message.titleAr}',
      button: true,
      child: GestureDetector(
        onTap: () {
          if (message.hasAction) {
            _handleMessageTap(message);
          } else {
            _dismissMessage(message);
          }
        },
        child: tooltipContent,
      ),
    )
        .animate()
        .fadeIn(duration: 250.ms, curve: Curves.easeOut)
        .slideY(begin: -0.15, end: 0, curve: Curves.easeOutCubic, duration: 280.ms)
        .scale(begin: const Offset(0.96, 0.96), end: const Offset(1.0, 1.0), duration: 250.ms);
  }

  }
