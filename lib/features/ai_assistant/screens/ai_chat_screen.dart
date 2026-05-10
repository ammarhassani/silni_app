import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/directional_icon.dart';

import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/glass_dialog.dart';
import '../../../core/ai/ai_identity.dart';
import '../../../core/ai/ai_models.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../providers/ai_chat_provider.dart';
import '../services/ai_mode_detector.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/conversation_message.dart';
import '../widgets/chat_history_drawer.dart';
import '../widgets/memory_indicator.dart';
import '../widgets/persona_greeting_block.dart';

/// AI Chat Screen - Family Counselor (أنيس)
class AIChatScreen extends ConsumerStatefulWidget {
  final String? relativeId;

  const AIChatScreen({
    super.key,
    this.relativeId,
  });

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Tracks whether the composer has any text. Drives send-button enabled
  // animation (β3) and dismisses the suggested-prompt chip row.
  bool _hasComposerText = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onComposerChanged);
  }

  void _onComposerChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _hasComposerText) {
      setState(() => _hasComposerText = hasText);
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onComposerChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check inside callback - controller may detach between scheduling and execution
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    _focusNode.unfocus();

    // Auto-detect mode from context
    final relativeContext = ref.read(chatRelativeContextProvider);
    final detectedMode = AIModeDetector.detect(relativeContext: relativeContext);
    ref.read(counselingModeProvider.notifier).state = detectedMode;

    // Use streaming for GPT-like animation
    ref.read(aiChatProvider.notifier).sendMessageStreaming(
          content,
          mode: detectedMode,
          relativeContext: relativeContext,
        );

    _scrollToBottom();
  }

  void _selectSuggestedPrompt(String prompt) {
    HapticFeedback.lightImpact();
    _messageController.text = prompt;
    _sendMessage();
  }

  void _startNewChat() {
    // Just clear the state - conversation is created lazily on first message
    ref.read(aiChatProvider.notifier).clearConversation();
  }

  void _loadConversation(String conversationId) {
    ref.read(aiChatProvider.notifier).loadConversation(conversationId);
  }

  void _openHistoryDrawer() {
    HapticFeedback.lightImpact();
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProvider);
    final themeColors = ref.watch(themeColorsProvider);

    // Listen for new messages to scroll
    ref.listen<AIChatState>(aiChatProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    return GradientBackground(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        // Custom scrim — replaces Material's grey overlay with a deep
        // glass-tinted dim that matches the rest of the app's modal pattern.
        drawerScrimColor: Colors.black.withValues(alpha: 0.55),
        appBar: _buildAppBar(context, themeColors),
        endDrawer: ChatHistoryDrawer(
          onNewChat: _startNewChat,
          onSelectConversation: _loadConversation,
        ),
        body: Semantics(
          label: 'محادثة ${AIIdentity.name} المساعد الذكي',
          child: Column(
            children: [
              // Chat messages — always renders. The persona greeting block
              // sits at index 0 of the list; suggested prompts (when the
              // conversation is empty) live above the composer per β3.
              Expanded(
                child: _buildMessagesList(chatState, themeColors),
              ),

              // Memory saved indicator (like ChatGPT)
              if (chatState.memorySavedCount > 0)
                Center(
                  child: MemorySavedIndicator(
                    count: chatState.memorySavedCount,
                    onTap: () => ref.read(aiChatProvider.notifier).clearMemoryIndicator(),
                    onDismiss: () => ref.read(aiChatProvider.notifier).clearMemoryIndicator(),
                  ),
                ),

              // Error banner
              if (chatState.error != null) _buildErrorBanner(chatState.error!, themeColors),

              // Input area
              _buildInputArea(chatState, themeColors),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, dynamic themeColors) {
    // β8 — minimal AppBar. The persona pill (avatar + name + mode subtitle)
    // moved into the in-conversation PersonaGreetingBlock; the AppBar now
    // carries only navigation chrome so the conversation is the focus.
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 56,
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
        child: Center(
          child: GlassIconButton(
            tooltip: 'رجوع',
            icon: DirectionalIcon(
              Icons.arrow_back_ios_rounded,
              color: themeColors.textOnGradient,
              size: 18,
            ),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      title: const SizedBox.shrink(),
      actions: [
        Padding(
          padding: const EdgeInsetsDirectional.only(end: AppSpacing.md),
          child: Center(
            child: _ChatHeaderControlCluster(
              themeColors: themeColors,
              onHistory: _openHistoryDrawer,
              onNewChat: () {
                HapticFeedback.mediumImpact();
                _showClearConfirmation(themeColors);
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showEditDialog(ChatMessage message) {
    final editController = TextEditingController(text: message.content);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Builder(
          builder: (dialogContext) {
            final dialogTheme = ref.watch(themeColorsProvider);
            return Container(
              margin: const EdgeInsets.all(AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: dialogTheme.background2,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(
                  color: dialogTheme.textOnGradient.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit_rounded, color: dialogTheme.textOnGradient.withValues(alpha: 0.7), size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'تعديل الرسالة',
                        style: AppTypography.titleMedium.copyWith(
                          color: dialogTheme.textOnGradient,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: editController,
                    maxLines: 5,
                    minLines: 2,
                    autofocus: true,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    cursorColor: dialogTheme.textOnGradient,
                    keyboardAppearance: Brightness.dark,
                    style: AppTypography.bodyMedium.copyWith(color: dialogTheme.textOnGradient),
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالتك المعدلة...',
                      hintStyle: AppTypography.bodyMedium.copyWith(
                        color: dialogTheme.textOnGradient.withValues(alpha: 0.54),
                      ),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide: BorderSide(
                          color: dialogTheme.textOnGradient.withValues(alpha: 0.4),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide: BorderSide(
                          color: dialogTheme.textOnGradient.withValues(alpha: 0.4),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide: BorderSide(
                          color: dialogTheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(
                            'إلغاء',
                            style: AppTypography.buttonMedium.copyWith(
                              color: dialogTheme.textOnGradient.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final newContent = editController.text.trim();
                            if (newContent.isNotEmpty && newContent != message.content) {
                              Navigator.pop(dialogContext);
                              HapticFeedback.mediumImpact();
                              final mode = ref.read(counselingModeProvider);
                              final relativeContext = ref.read(chatRelativeContextProvider);
                              ref.read(aiChatProvider.notifier).editAndResend(
                                message.id,
                                newContent,
                                mode: mode,
                                relativeContext: relativeContext,
                              );
                            }
                          },
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: Text('إرسال', style: AppTypography.buttonMedium),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: dialogTheme.primary,
                            foregroundColor: dialogTheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _regenerateLastResponse() {
    HapticFeedback.mediumImpact();
    final mode = ref.read(counselingModeProvider);
    final relativeContext = ref.read(chatRelativeContextProvider);
    ref.read(aiChatProvider.notifier).regenerateLastResponse(
      mode: mode,
      relativeContext: relativeContext,
    );
  }

  Widget _buildMessagesList(AIChatState chatState, dynamic themeColors) {
    // β.fix#3 (rev 6) — turn-box rendering. Each user question + its
    // AI response is grouped into one boxed turn with a continuous neon
    // rail on the box's left edge. The persona greeting block stays at
    // index 0; turns follow.
    final turns = groupMessagesIntoTurns(chatState.messages);
    final hasActivity = chatState.isStreaming || chatState.isLoading;

    // If there's activity but no turns yet (very transient), append a
    // synthesized empty turn so the typing indicator has somewhere to live.
    final renderTurns = (hasActivity && turns.isEmpty) ? [Turn()] : turns;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.xl),
      itemCount: 1 + renderTurns.length,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const PersonaGreetingBlock();
        }

        final turnIndex = index - 1;
        final turn = renderTurns[turnIndex];
        final isLastTurn = turnIndex == renderTurns.length - 1;

        final showStream = isLastTurn &&
            chatState.isStreaming &&
            chatState.currentStreamContent.isNotEmpty;
        final showTyping = isLastTurn &&
            (chatState.isLoading ||
                (chatState.isStreaming &&
                    chatState.currentStreamContent.isEmpty));

        return ConversationTurn(
          turn: turn,
          streamingContent: showStream ? chatState.currentStreamContent : null,
          showTyping: showTyping,
          onEdit: turn.userMessage != null
              ? () => _showEditDialog(turn.userMessage!)
              : null,
          onRegenerate: isLastTurn && turn.aiMessages.isNotEmpty
              ? _regenerateLastResponse
              : null,
        ).animate().fadeIn(duration: AppAnimations.fast);
      },
    );
  }

  Widget _buildErrorBanner(String error, dynamic themeColors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: themeColors.statusError.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: themeColors.statusError.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: themeColors.statusError),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              error,
              style: AppTypography.bodySmall.copyWith(
                color: themeColors.textOnGradient,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: themeColors.textOnGradient.withValues(alpha: 0.7), size: 20),
            onPressed: () => ref.read(aiChatProvider.notifier).clearError(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppAnimations.fast).slideY(begin: -0.2, end: 0);
  }

  Widget _buildInputArea(AIChatState chatState, dynamic themeColors) {
    final isDisabled = chatState.isLoading || chatState.isStreaming;
    final canSend = _hasComposerText && !isDisabled;
    final showPromptChips = chatState.messages.isEmpty &&
        !chatState.isStreaming &&
        !chatState.isLoading &&
        !_hasComposerText;
    final suggestedPrompts = ref.watch(suggestedPromptsProvider);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // β3 — empty-conversation suggested prompt chips. Fade out as
            // soon as the user starts typing.
            AnimatedSwitcher(
              duration: AppAnimations.normal,
              child: showPromptChips
                  ? _buildPromptChipRow(
                      suggestedPrompts.take(3).toList(),
                      themeColors,
                    )
                  : const SizedBox.shrink(),
            ),
            // β3 — glass-pill composer.
            _buildGlassComposer(
              themeColors: themeColors,
              isDisabled: isDisabled,
              canSend: canSend,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptChipRow(List<String> prompts, dynamic themeColors) {
    return Padding(
      key: const ValueKey('prompt-chip-row'),
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        alignment: WrapAlignment.center,
        children: prompts.map((p) {
          return SuggestedPromptChip(
            text: p,
            onTap: () => _selectSuggestedPrompt(p),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGlassComposer({
    required dynamic themeColors,
    required bool isDisabled,
    required bool canSend,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: themeColors.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs + 2,
            vertical: AppSpacing.xs + 2,
          ),
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            textDirection: TextDirection.rtl,
            children: [
              // Text input — sits at the start of reading direction (right
              // edge in RTL) and grows leftward.
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.md,
                  ),
                  child: Semantics(
                    label: 'حقل كتابة الرسالة',
                    textField: true,
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      enabled: !isDisabled,
                      maxLines: 5,
                      minLines: 1,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      cursorColor: themeColors.textOnGradient,
                      keyboardAppearance: Brightness.dark,
                      style: AppTypography.bodyMedium.copyWith(
                        color: themeColors.textOnGradient,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'اسأل ${AIIdentity.name}...',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: themeColors.textOnGradient
                              .withValues(alpha: 0.4),
                          fontSize: 16,
                        ),
                        // β.fix#1 — opt out of the global InputDecorationTheme
                        // (filled: true + fillColor: Colors.white) which was
                        // painting an opaque white over the glass surface.
                        filled: false,
                        fillColor: Colors.transparent,
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              // β3 — embedded send button. Sits at the end of the row,
              // which in RTL is the physical LEFT edge of the composer.
              _ComposerSendButton(
                themeColors: themeColors,
                enabled: canSend,
                onTap: _sendMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearConfirmation(dynamic themeColors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: themeColors.background2,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: themeColors.textOnGradient.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.refresh_rounded,
              size: 48,
              color: themeColors.textOnGradient,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'بدء محادثة جديدة؟',
              style: AppTypography.titleLarge.copyWith(
                color: themeColors.textOnGradient,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'سيتم مسح المحادثة الحالية وبدء محادثة جديدة',
              style: AppTypography.bodyMedium.copyWith(
                color: themeColors.textOnGradient.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'إلغاء',
                    button: true,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'إلغاء',
                        style: AppTypography.buttonMedium.copyWith(
                          color: themeColors.textOnGradient.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Semantics(
                    label: 'بدء محادثة جديدة',
                    button: true,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(aiChatProvider.notifier).clearConversation();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColors.primary,
                        foregroundColor: themeColors.textOnGradient,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.buttonRadius),
                        ),
                      ),
                      child: Text(
                        'بدء جديدة',
                        style: AppTypography.buttonMedium,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Segmented glass-pill control cluster used in the AI chat header.
/// Fuses the two header actions (history + new-chat) into one pill so the
/// AppBar reads as a coherent control row, not two floating circles.
class _ChatHeaderControlCluster extends StatelessWidget {
  const _ChatHeaderControlCluster({
    required this.themeColors,
    required this.onHistory,
    required this.onNewChat,
  });

  final dynamic themeColors;
  final VoidCallback onHistory;
  final VoidCallback onNewChat;

  @override
  Widget build(BuildContext context) {
    final fg = themeColors.textOnGradient as Color;
    return Container(
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
        border: Border.all(
          color: fg.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ClusterButton(
            tooltip: 'المحادثات السابقة',
            icon: Icons.history_rounded,
            color: fg,
            onPressed: onHistory,
          ),
          Container(
            width: 1,
            height: 20,
            color: fg.withValues(alpha: 0.18),
          ),
          _ClusterButton(
            tooltip: 'محادثة جديدة',
            icon: Icons.refresh_rounded,
            color: fg,
            onPressed: onNewChat,
          ),
        ],
      ),
    );
  }
}

class _ClusterButton extends StatelessWidget {
  const _ClusterButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }
}

/// β3 composer send button. Embedded inside the glass-pill composer.
/// Disabled state = outline only; enabled = gradient fill with subtle glow.
/// Animates on enable (scale + shimmer cue) and on press (squash).
class _ComposerSendButton extends StatefulWidget {
  const _ComposerSendButton({
    required this.themeColors,
    required this.enabled,
    required this.onTap,
  });

  final dynamic themeColors;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_ComposerSendButton> createState() => _ComposerSendButtonState();
}

class _ComposerSendButtonState extends State<_ComposerSendButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final tc = widget.themeColors;
    final Color accent = tc.accent;
    final scale = _isPressed ? 0.92 : (widget.enabled ? 1.0 : 0.9);

    return Semantics(
      label: 'إرسال الرسالة',
      button: true,
      enabled: widget.enabled,
      child: GestureDetector(
        onTapDown: widget.enabled
            ? (_) => setState(() => _isPressed = true)
            : null,
        onTapUp: widget.enabled
            ? (_) {
                setState(() => _isPressed = false);
                HapticFeedback.lightImpact();
                widget.onTap();
              }
            : null,
        onTapCancel: widget.enabled
            ? () => setState(() => _isPressed = false)
            : null,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: widget.enabled
                  ? LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [tc.primary, tc.primaryLight],
                    )
                  : null,
              color: widget.enabled ? null : Colors.transparent,
              border: widget.enabled
                  ? null
                  : Border.all(
                      color: accent.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
              boxShadow: widget.enabled
                  ? [
                      BoxShadow(
                        color: tc.primary.withValues(alpha: 0.45),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            // β.fix#2 — Icons.send_rounded points right by default. In RTL
            // we want it pointing left (toward where the text reads to).
            // Previous Transform.rotate(angle: pi) rotated 180° which also
            // flipped vertically — the wing curvature was inverted, reading
            // as a wrong/upside-down arrow. Transform.flip(flipX: true) is
            // a horizontal mirror only.
            child: Transform.flip(
              flipX: true,
              child: Icon(
                Icons.send_rounded,
                color: widget.enabled
                    ? tc.textOnGradient
                    : tc.textOnGradient.withValues(alpha: 0.45),
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
