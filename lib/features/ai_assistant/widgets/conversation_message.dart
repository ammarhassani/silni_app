import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/ai/ai_models.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/utils/ui_helpers.dart';
import 'markdown_styles.dart';
import 'message_action_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────
//  Turn data structure
// ─────────────────────────────────────────────────────────────────────────

/// A single conversation turn — one user question + the AI response(s)
/// that followed. The chat surface renders one [ConversationTurn] box
/// per [Turn].
///
/// β.fix#3 (rev 6) — turn-box redesign. Previously every message rendered
/// independently; the per-message accent rails left visible cutouts in
/// the inter-turn gap. The new design groups user+AI into a single
/// rounded-box card with one continuous neon rail on the physical-left
/// edge of the box.
class Turn {
  Turn({this.userMessage, List<ChatMessage>? aiMessages})
      : aiMessages = aiMessages ?? [];

  final ChatMessage? userMessage;
  final List<ChatMessage> aiMessages;
}

/// Group a flat message list into turns. Each user message starts a new
/// turn; consecutive assistant messages append to the current turn.
List<Turn> groupMessagesIntoTurns(List<ChatMessage> messages) {
  final turns = <Turn>[];
  Turn? current;
  for (final msg in messages) {
    if (msg.role == MessageRole.user) {
      if (current != null) turns.add(current);
      current = Turn(userMessage: msg);
    } else {
      current ??= Turn();
      current.aiMessages.add(msg);
    }
  }
  if (current != null) turns.add(current);
  return turns;
}

// ─────────────────────────────────────────────────────────────────────────
//  ConversationTurn — the boxed turn widget
// ─────────────────────────────────────────────────────────────────────────

/// A boxed conversation turn: rounded card with a neon-accent rail on its
/// physical-left edge, holding the user's question at the top, the AI's
/// response(s) below, and inline copy/regenerate action chips.
///
/// Streaming + typing states attach to the LAST turn (the active one)
/// via [streamingContent] and [showTyping] respectively.
class ConversationTurn extends ConsumerWidget {
  const ConversationTurn({
    super.key,
    required this.turn,
    this.streamingContent,
    this.showTyping = false,
    this.onEdit,
    this.onRegenerate,
  });

  final Turn turn;
  final String? streamingContent;
  final bool showTyping;
  final VoidCallback? onEdit;
  final VoidCallback? onRegenerate;

  bool get _hasAIContent =>
      turn.aiMessages.isNotEmpty ||
      streamingContent != null ||
      showTyping;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final Color accent = themeColors.accent;

    final bool actionsAvailable = turn.aiMessages.isNotEmpty &&
        streamingContent == null &&
        !showTyping;

    return Padding(
      // Outer turn padding — small so the rail sits near the screen edge.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        0,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: GestureDetector(
          onLongPress: _hasAIContent
              ? () => _onLongPress(context)
              : null,
          behavior: HitTestBehavior.opaque,
          child: IntrinsicHeight(
            child: Row(
              textDirection: TextDirection.ltr,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _NeonRail(accent: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (turn.userMessage != null)
                          _TurnUserBubble(
                            message: turn.userMessage!,
                            themeColors: themeColors,
                          ),
                        ..._buildAIBlocks(context, themeColors),
                        if (showTyping) ...[
                          if (turn.userMessage != null)
                            const SizedBox(height: AppSpacing.md),
                          _TurnTypingDots(accent: accent),
                        ],
                        if (streamingContent != null) ...[
                          if (turn.userMessage != null ||
                              turn.aiMessages.isNotEmpty)
                            const SizedBox(height: AppSpacing.md),
                          _TurnStreamingBody(
                            content: streamingContent!,
                            themeColors: themeColors,
                          ),
                        ],
                        if (actionsAvailable) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _TurnActionRow(
                            aiContent: turn.aiMessages.last.content,
                            themeColors: themeColors,
                            onCopy: () => _copyToClipboard(
                                context, turn.aiMessages.last.content),
                            onRegenerate: onRegenerate,
                            onEdit: onEdit,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAIBlocks(BuildContext context, dynamic themeColors) {
    final blocks = <Widget>[];
    for (var i = 0; i < turn.aiMessages.length; i++) {
      if (i > 0 || turn.userMessage != null) {
        blocks.add(const SizedBox(height: AppSpacing.md));
      }
      blocks.add(_TurnAIBody(
        message: turn.aiMessages[i],
        themeColors: themeColors,
      ));
    }
    return blocks;
  }

  void _onLongPress(BuildContext context) {
    HapticFeedback.lightImpact();
    final aiContent = turn.aiMessages.isNotEmpty
        ? turn.aiMessages.last.content
        : '';
    MessageActionSheet.show(
      context: context,
      isUser: false,
      content: aiContent,
      onRegenerate: onRegenerate,
    );
  }
}

void _copyToClipboard(BuildContext context, String content) {
  HapticFeedback.lightImpact();
  Clipboard.setData(ClipboardData(text: content));
  UIHelpers.showSnackBar(
    context,
    'تم نسخ الرسالة',
    duration: const Duration(seconds: 2),
  );
}

// ─────────────────────────────────────────────────────────────────────────
//  Inside-the-box pieces
// ─────────────────────────────────────────────────────────────────────────

/// User content inside the turn box — right-anchored bubble (RTL start).
class _TurnUserBubble extends StatelessWidget {
  const _TurnUserBubble({required this.message, required this.themeColors});

  final ChatMessage message;
  final dynamic themeColors;

  @override
  Widget build(BuildContext context) {
    final Color primary = themeColors.primary;
    final Color accent = themeColors.accent;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.18),
              border: Border.all(
                color: accent.withValues(alpha: 0.4),
                width: 1,
              ),
              borderRadius: const BorderRadiusDirectional.only(
                topStart: Radius.circular(14),
                topEnd: Radius.circular(14),
                bottomEnd: Radius.circular(14),
                bottomStart: Radius.circular(4),
              ),
            ),
            child: SelectableText(
              message.content,
              style: AppTypography.bodyMedium.copyWith(
                color: themeColors.textOnGradient,
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        ),
      ),
    );
  }
}

/// AI markdown body inside the turn box.
class _TurnAIBody extends StatelessWidget {
  const _TurnAIBody({required this.message, required this.themeColors});

  final ChatMessage message;
  final dynamic themeColors;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: MarkdownBody(
        data: message.content,
        styleSheet: buildChatMarkdownStyle(context, themeColors),
        selectable: true,
        softLineBreak: true,
        onTapLink: (text, href, title) {
          if (href != null) {
            launchUrl(Uri.parse(href));
          }
        },
      ),
    );
  }
}

/// Streaming AI body inside the turn box, with paced rendering + cursor.
class _TurnStreamingBody extends StatefulWidget {
  const _TurnStreamingBody({required this.content, required this.themeColors});

  final String content;
  final dynamic themeColors;

  @override
  State<_TurnStreamingBody> createState() => _TurnStreamingBodyState();
}

class _TurnStreamingBodyState extends State<_TurnStreamingBody> {
  static const Duration _tickInterval = Duration(milliseconds: 33);
  static const int _charsPerTick = 3;

  String _displayed = '';
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _displayed = widget.content;
    _maybeStartTicker();
  }

  @override
  void didUpdateWidget(_TurnStreamingBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.content.length < _displayed.length) {
      _displayed = widget.content;
    }
    _maybeStartTicker();
  }

  void _maybeStartTicker() {
    if (_ticker != null) return;
    if (_displayed.length >= widget.content.length) return;
    _ticker = Timer.periodic(_tickInterval, (_) => _advance());
  }

  void _advance() {
    if (!mounted) return;
    if (_displayed.length >= widget.content.length) {
      _ticker?.cancel();
      _ticker = null;
      return;
    }
    final next = (_displayed.length + _charsPerTick)
        .clamp(0, widget.content.length);
    setState(() {
      _displayed = widget.content.substring(0, next);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = widget.themeColors.accent;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: _displayed.isEmpty
          ? _BlinkingCursor(color: accent)
          : Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                MarkdownBody(
                  data: _displayed,
                  styleSheet:
                      buildStreamingMarkdownStyle(context, widget.themeColors),
                  selectable: false,
                  softLineBreak: true,
                ),
                _BlinkingCursor(color: accent),
              ],
            ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor({required this.color});
  final Color color;

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
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
      builder: (context, _) {
        return Opacity(
          opacity: 0.3 + (_controller.value * 0.7),
          child: Container(
            width: 2,
            height: 18,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
      },
    );
  }
}

class _TurnTypingDots extends StatefulWidget {
  const _TurnTypingDots({required this.accent});
  final Color accent;

  @override
  State<_TurnTypingDots> createState() => _TurnTypingDotsState();
}

class _TurnTypingDotsState extends State<_TurnTypingDots>
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
            final opacity =
                (value < 0.5 ? value * 2 : 2 - value * 2).clamp(0.3, 1.0);

            return Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.accent.withValues(alpha: opacity),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Inline action chips at the bottom of an AI response — copy, regenerate,
/// edit. Restored after Phase β5's long-press-only design omitted them.
class _TurnActionRow extends StatelessWidget {
  const _TurnActionRow({
    required this.aiContent,
    required this.themeColors,
    required this.onCopy,
    this.onRegenerate,
    this.onEdit,
  });

  final String aiContent;
  final dynamic themeColors;
  final VoidCallback onCopy;
  final VoidCallback? onRegenerate;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          _ActionChip(
            icon: Icons.copy_rounded,
            label: 'نسخ',
            themeColors: themeColors,
            onTap: onCopy,
          ),
          if (onRegenerate != null)
            _ActionChip(
              icon: Icons.refresh_rounded,
              label: 'إعادة',
              themeColors: themeColors,
              onTap: onRegenerate!,
            ),
          if (onEdit != null)
            _ActionChip(
              icon: Icons.edit_rounded,
              label: 'تعديل',
              themeColors: themeColors,
              onTap: onEdit!,
            ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.themeColors,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final dynamic themeColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color textOn = themeColors.textOnGradient;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: textOn.withValues(alpha: 0.7)),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: textOn.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Neon rail — the box's left-edge accent
// ─────────────────────────────────────────────────────────────────────────

class _NeonRail extends StatelessWidget {
  const _NeonRail({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.9),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.5),
            blurRadius: 14,
            spreadRadius: 0,
          ),
        ],
      ),
    );
  }
}
