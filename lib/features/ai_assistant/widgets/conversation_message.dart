import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/ai/ai_models.dart';
import 'markdown_styles.dart';
import 'message_actions.dart';

/// Claude-style conversation message widget
/// Replaces bubble design with clean, modern layout
class ConversationMessage extends StatelessWidget {
  final ChatMessage message;
  final bool isLast;
  final VoidCallback? onEdit;
  final VoidCallback? onRegenerate;

  const ConversationMessage({
    super.key,
    required this.message,
    this.isLast = false,
    this.onEdit,
    this.onRegenerate,
  });

  bool get isUser => message.role == MessageRole.user;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isUser)
            _buildUserMessage(context)
          else
            _buildAIMessage(context),
        ],
      ),
    );
  }

  /// User message: Right-aligned, minimal styling, subtle background
  Widget _buildUserMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message content with accent border
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border(
                right: BorderSide(
                  color: AppColors.islamicGreenPrimary.withValues(alpha: 0.6),
                  width: 3,
                ),
              ),
            ),
            child: SelectableText(
              message.content,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white,
                height: 1.6,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // Action buttons
          MessageActionsRow(
            isUserMessage: true,
            content: message.content,
            onEdit: onEdit,
          ),
        ],
      ),
    );
  }

  /// AI message: Full width, markdown rendered, with label
  Widget _buildAIMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI label with icon
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'واصل',
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Markdown content with RTL support
          Directionality(
            textDirection: TextDirection.rtl,
            child: MarkdownBody(
              data: message.content,
              styleSheet: buildChatMarkdownStyle(context),
              selectable: true,
              softLineBreak: true,
              onTapLink: (text, href, title) {
                if (href != null) {
                  launchUrl(Uri.parse(href));
                }
              },
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Action buttons
          MessageActionsRow(
            isUserMessage: false,
            content: message.content,
            onRegenerate: onRegenerate,
          ),
        ],
      ),
    );
  }
}

/// Streaming message widget for AI responses in progress
class StreamingMessage extends StatelessWidget {
  final String content;

  const StreamingMessage({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI label with animated indicator
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'واصل',
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                _TypingDots(),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            // Streaming markdown content with RTL support
            if (content.isNotEmpty)
              Directionality(
                textDirection: TextDirection.rtl,
                child: MarkdownBody(
                  data: content,
                  styleSheet: buildStreamingMarkdownStyle(context),
                  selectable: false,
                  softLineBreak: true,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Animated typing dots indicator
class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
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
            final delay = index * 0.2;
            final value = (_controller.value - delay).clamp(0.0, 1.0);
            final opacity = (value < 0.5 ? value * 2 : 2 - value * 2).clamp(0.3, 1.0);

            return Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 1),
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

/// Empty state for new conversations
class EmptyConversationState extends StatelessWidget {
  const EmptyConversationState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'مرحباً، أنا واصل',
            style: AppTypography.headlineSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'مساعدك الذكي في صلة الرحم',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}
