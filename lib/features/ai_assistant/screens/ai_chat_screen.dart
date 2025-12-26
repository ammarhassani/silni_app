import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/ai/ai_models.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../providers/ai_chat_provider.dart';
import '../../../core/router/app_routes.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/conversation_message.dart';
import '../widgets/chat_history_drawer.dart';
import '../widgets/memory_indicator.dart';

/// AI Chat Screen - Family Counselor (واصل)
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
  bool _showModeSelector = true;

  @override
  void initState() {
    super.initState();
    // Conversation is created lazily when user sends first message
  }

  @override
  void dispose() {
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

    final mode = ref.read(counselingModeProvider);
    final relativeContext = ref.read(chatRelativeContextProvider);

    // Use streaming for GPT-like animation
    ref.read(aiChatProvider.notifier).sendMessageStreaming(
          content,
          mode: mode,
          relativeContext: relativeContext,
        );

    _scrollToBottom();
    setState(() {
      _showModeSelector = false;
    });
  }

  void _selectSuggestedPrompt(String prompt) {
    HapticFeedback.lightImpact();
    _messageController.text = prompt;
    _sendMessage();
  }

  void _startNewChat() {
    // Just clear the state - conversation is created lazily on first message
    ref.read(aiChatProvider.notifier).clearConversation();
    setState(() {
      _showModeSelector = true;
    });
  }

  void _loadConversation(String conversationId) {
    ref.read(aiChatProvider.notifier).loadConversation(conversationId);
    setState(() {
      _showModeSelector = false;
    });
  }

  void _openHistoryDrawer() {
    HapticFeedback.lightImpact();
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProvider);
    final currentMode = ref.watch(counselingModeProvider);
    final suggestedPrompts = ref.watch(suggestedPromptsProvider);
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
        appBar: _buildAppBar(context, themeColors),
        endDrawer: ChatHistoryDrawer(
          onNewChat: _startNewChat,
          onSelectConversation: _loadConversation,
        ),
        body: Semantics(
          label: 'محادثة واصل المساعد الذكي',
          child: Column(
            children: [
              // Chat messages
              Expanded(
                child: chatState.messages.isEmpty && !chatState.isStreaming && !chatState.isLoading
                    ? _buildEmptyState(currentMode, suggestedPrompts, themeColors)
                    : _buildMessagesList(chatState, themeColors),
              ),

              // Memory saved indicator (like ChatGPT)
              if (chatState.memorySavedCount > 0)
                Center(
                  child: MemorySavedIndicator(
                    count: chatState.memorySavedCount,
                    onTap: () => context.push(AppRoutes.aiMemories),
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
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Semantics(
        label: 'رجوع',
        button: true,
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: themeColors.textOnGradient),
          onPressed: () => context.pop(),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [themeColors.primary, themeColors.primaryLight],
              ),
              boxShadow: [
                BoxShadow(
                  color: themeColors.primary.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              Icons.smart_toy_rounded,
              size: 20,
              color: themeColors.textOnGradient,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'واصل',
                style: AppTypography.titleMedium.copyWith(
                  color: themeColors.textOnGradient,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ref.watch(counselingModeProvider).arabicName,
                style: AppTypography.labelSmall.copyWith(
                  color: themeColors.textOnGradient.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Semantics(
          label: 'ذاكرة واصل',
          button: true,
          child: IconButton(
            icon: Icon(Icons.psychology_outlined, color: themeColors.textOnGradient.withValues(alpha: 0.7)),
            onPressed: () => context.push(AppRoutes.aiMemories),
            tooltip: 'ذاكرة واصل',
          ),
        ),
        Semantics(
          label: 'المحادثات السابقة',
          button: true,
          child: IconButton(
            icon: Icon(Icons.history_rounded, color: themeColors.textOnGradient.withValues(alpha: 0.7)),
            onPressed: _openHistoryDrawer,
            tooltip: 'المحادثات السابقة',
          ),
        ),
        Semantics(
          label: 'محادثة جديدة',
          button: true,
          child: IconButton(
            icon: Icon(Icons.refresh_rounded, color: themeColors.textOnGradient.withValues(alpha: 0.7)),
            onPressed: () {
              HapticFeedback.mediumImpact();
              _showClearConfirmation(themeColors);
            },
            tooltip: 'محادثة جديدة',
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(CounselingMode mode, List<String> prompts, dynamic themeColors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),

          // Welcome message
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [themeColors.primary, themeColors.primaryLight],
              ),
              boxShadow: [
                BoxShadow(
                  color: themeColors.primary.withValues(alpha: 0.5),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.smart_toy_rounded,
              size: 44,
              color: themeColors.textOnGradient,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(
                duration: AppAnimations.loop,
                color: themeColors.textOnGradient.withValues(alpha: 0.24),
              ),

          const SizedBox(height: AppSpacing.lg),

          Text(
            'مرحباً، أنا واصل',
            style: AppTypography.headlineSmall.copyWith(
              color: themeColors.textOnGradient,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(duration: AppAnimations.normal).slideY(begin: 0.2, end: 0),

          const SizedBox(height: AppSpacing.xs),

          Text(
            'مساعدك الذكي في صلة الرحم',
            style: AppTypography.bodyMedium.copyWith(
              color: themeColors.textOnGradient.withValues(alpha: 0.7),
            ),
          ).animate(delay: AppAnimations.instant).fadeIn(duration: AppAnimations.normal),

          const SizedBox(height: AppSpacing.xl),

          // Mode selector
          if (_showModeSelector) ...[
            Text(
              'اختر نوع المحادثة',
              style: AppTypography.titleSmall.copyWith(
                color: themeColors.textOnGradient.withValues(alpha: 0.7),
              ),
            ).animate(delay: AppAnimations.fast).fadeIn(duration: AppAnimations.normal),

            const SizedBox(height: AppSpacing.md),

            _buildModeSelector(themeColors)
                .animate(delay: AppAnimations.normal)
                .fadeIn(duration: AppAnimations.normal)
                .slideY(begin: 0.1, end: 0),

            const SizedBox(height: AppSpacing.xl),
          ],

          // Suggested prompts
          Text(
            'أو جرب أحد هذه الأسئلة',
            style: AppTypography.titleSmall.copyWith(
              color: themeColors.textOnGradient.withValues(alpha: 0.7),
            ),
          ).animate(delay: AppAnimations.modal).fadeIn(duration: AppAnimations.normal),

          const SizedBox(height: AppSpacing.md),

          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: prompts.asMap().entries.map((entry) {
              return SuggestedPromptChip(
                text: entry.value,
                onTap: () => _selectSuggestedPrompt(entry.value),
              )
                  .animate(
                      delay: Duration(milliseconds: 500 + (entry.key * 100)))
                  .fadeIn(duration: AppAnimations.normal)
                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector(dynamic themeColors) {
    final currentMode = ref.watch(counselingModeProvider);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.5,
      children: CounselingMode.values.map((mode) {
        return CounselingModeCard(
          mode: mode,
          isSelected: mode == currentMode,
          onTap: () {
            // Only set the mode - conversation is created lazily on first message
            ref.read(counselingModeProvider.notifier).state = mode;
          },
        );
      }).toList(),
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
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.islamicGreenDark,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit_rounded, color: Colors.white70, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'تعديل الرسالة',
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
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
                cursorColor: Colors.white,
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'اكتب رسالتك المعدلة...',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: Colors.white54,
                  ),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide(
                      color: AppColors.islamicGreenPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'إلغاء',
                        style: AppTypography.buttonMedium.copyWith(
                          color: Colors.white70,
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
                          Navigator.pop(context);
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
                        backgroundColor: AppColors.islamicGreenPrimary,
                        foregroundColor: Colors.white,
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
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.sm),
      itemCount: chatState.messages.length +
          (chatState.isLoading || chatState.isStreaming ? 1 : 0),
      itemBuilder: (context, index) {
        // Show typing indicator or streaming content at the end
        if (index == chatState.messages.length) {
          if (chatState.isStreaming && chatState.currentStreamContent.isNotEmpty) {
            return StreamingMessage(content: chatState.currentStreamContent)
                .animate()
                .fadeIn(duration: AppAnimations.fast);
          }
          return const TypingIndicator().animate().fadeIn(duration: AppAnimations.fast);
        }

        final message = chatState.messages[index];
        final isLast = index == chatState.messages.length - 1;
        final isUser = message.role == MessageRole.user;

        return ConversationMessage(
          message: message,
          isLast: isLast,
          onEdit: isUser ? () => _showEditDialog(message) : null,
          onRegenerate: !isUser && isLast ? _regenerateLastResponse : null,
        ).animate().fadeIn(duration: AppAnimations.fast);
      },
    );
  }

  Widget _buildErrorBanner(String error, dynamic themeColors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
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

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        border: Border(
          top: BorderSide(
            color: themeColors.textOnGradient.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          textDirection: TextDirection.rtl, // RTL: send button on right
          children: [
            // Send button (on right for RTL)
            Semantics(
              label: 'إرسال الرسالة',
              button: true,
              child: GestureDetector(
                onTap: isDisabled ? null : _sendMessage,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isDisabled
                        ? LinearGradient(
                            colors: [
                              Colors.grey.shade600,
                              Colors.grey.shade700,
                            ],
                          )
                        : LinearGradient(
                            colors: [themeColors.primary, themeColors.primaryLight],
                          ),
                    boxShadow: isDisabled
                        ? null
                        : [
                            BoxShadow(
                              color: themeColors.primary.withValues(alpha: 0.4),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                  ),
                  child: Transform.rotate(
                    angle: 3.14159, // Rotate 180 degrees for RTL send icon
                    child: Icon(
                      Icons.send_rounded,
                      color: themeColors.textOnGradient.withValues(alpha: isDisabled ? 0.5 : 1.0),
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // Text field (on left for RTL)
            Expanded(
              child: Semantics(
                label: 'حقل كتابة الرسالة',
                textField: true,
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  enabled: !isDisabled,
                  maxLines: 4,
                  minLines: 1,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  cursorColor: themeColors.textOnGradient,
                  style: AppTypography.bodyMedium.copyWith(
                    color: themeColors.textOnGradient,
                  ),
                  decoration: InputDecoration(
                    hintText: 'اكتب رسالتك...',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: themeColors.textOnGradient.withValues(alpha: 0.54),
                    ),
                    filled: true,
                    fillColor: themeColors.primary.withValues(alpha: 0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: themeColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: themeColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: themeColors.primary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm + 4,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
          ],
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
            color: themeColors.textOnGradient.withValues(alpha: 0.2),
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
                        setState(() {
                          _showModeSelector = true;
                        });
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
