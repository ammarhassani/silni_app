import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/ai/ai_identity.dart';
import '../../../core/ai/ai_models.dart';
import '../../../core/theme/theme_provider.dart';
import '../providers/ai_chat_provider.dart';
import '../../../shared/widgets/glass_dialog.dart';
import '../../../shared/widgets/gradient_button.dart';

/// Drawer showing chat history with past conversations
class ChatHistoryDrawer extends ConsumerWidget {
  final VoidCallback onNewChat;
  final Function(String conversationId) onSelectConversation;

  const ChatHistoryDrawer({
    super.key,
    required this.onNewChat,
    required this.onSelectConversation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(chatHistoryProvider);
    final currentConversation = ref.watch(aiChatProvider).conversation;
    final themeColors = ref.watch(themeColorsProvider);

    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      decoration: BoxDecoration(
        // Theme-aware gradient — drawer adopts whichever theme is active
        // (green / purple / orange / etc.) instead of the fixed Islamic
        // green dark used previously.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeColors.primaryDark,
            themeColors.primary,
          ],
        ),
        border: Border(
          left: BorderSide(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, themeColors),

            // Divider
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.15),
            ),

            // β7 — list area + new-chat pill at the bottom. The pill is
            // fixed (does not scroll) and has a fade gradient mask above
            // it so scrolling content fades behind it cleanly.
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: historyAsync.when(
                      data: (conversations) => _buildConversationList(
                        context,
                        ref,
                        conversations,
                        currentConversation?.id,
                        themeColors,
                      ),
                      loading: () => Center(
                        child: CircularProgressIndicator(
                          color: themeColors.primaryLight,
                        ),
                      ),
                      error: (error, stack) => _buildEmptyState(),
                    ),
                  ),
                  // Fade mask + new-chat pill anchored to the drawer bottom.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildBottomNewChat(context, themeColors),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic themeColors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  themeColors.primary,
                  themeColors.primaryLight,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: themeColors.primary.withValues(alpha: 0.45),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(
              Icons.history_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المحادثات السابقة',
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'اختر محادثة لاستكمالها',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          // Glass close button — matches the back/header pattern used
          // elsewhere in the app instead of the Material ripple IconButton.
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              customBorder: const CircleBorder(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// β7 — fixed new-chat pill anchored to the drawer bottom with a fade
  /// gradient mask so list content fades into it cleanly while scrolling.
  Widget _buildBottomNewChat(BuildContext context, dynamic themeColors) {
    final maskColor = themeColors.primary as Color;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: IgnorePointer(
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      maskColor.withValues(alpha: 0),
                      maskColor.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: GradientButton(
              text: 'محادثة جديدة',
              icon: Icons.add_rounded,
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
                onNewChat();
              },
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  themeColors.primary,
                  themeColors.primaryLight,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList(
    BuildContext context,
    WidgetRef ref,
    List<ChatConversation> conversations,
    String? currentId,
    dynamic themeColors,
  ) {
    if (conversations.isEmpty) {
      return _buildEmptyState();
    }

    // Group by date
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final todayConversations = <ChatConversation>[];
    final yesterdayConversations = <ChatConversation>[];
    final thisWeekConversations = <ChatConversation>[];
    final olderConversations = <ChatConversation>[];

    for (final conv in conversations) {
      final date = conv.updatedAt ?? conv.createdAt;
      if (_isSameDay(date, today)) {
        todayConversations.add(conv);
      } else if (_isSameDay(date, yesterday)) {
        yesterdayConversations.add(conv);
      } else if (date.isAfter(weekAgo)) {
        thisWeekConversations.add(conv);
      } else {
        olderConversations.add(conv);
      }
    }

    // The first conversation in the most-recent (today, then yesterday,
    // then this-week, then older) section gets emphasis treatment per β7.
    final mostRecentId = (todayConversations.isNotEmpty
            ? todayConversations.first
            : yesterdayConversations.isNotEmpty
                ? yesterdayConversations.first
                : thisWeekConversations.isNotEmpty
                    ? thisWeekConversations.first
                    : olderConversations.isNotEmpty
                        ? olderConversations.first
                        : null)
        ?.id;

    Widget tileFor(ChatConversation conv) {
      return _buildConversationTile(
        context,
        ref,
        conv,
        conv.id == currentId,
        conv.id == mostRecentId,
        themeColors,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        0,
        AppSpacing.sm,
        0,
        // Bottom padding leaves room for the floating new-chat pill.
        80,
      ),
      children: [
        if (todayConversations.isNotEmpty) ...[
          _buildSectionHeader('اليوم', themeColors),
          ...todayConversations.map(tileFor),
        ],
        if (yesterdayConversations.isNotEmpty) ...[
          _buildSectionHeader('أمس', themeColors),
          ...yesterdayConversations.map(tileFor),
        ],
        if (thisWeekConversations.isNotEmpty) ...[
          _buildSectionHeader('هذا الأسبوع', themeColors),
          ...thisWeekConversations.map(tileFor),
        ],
        if (olderConversations.isNotEmpty) ...[
          _buildSectionHeader('أقدم', themeColors),
          ...olderConversations.map(tileFor),
        ],
      ],
    );
  }

  /// β7 — chip-styled section header. Theme-accent fill + border, small
  /// pill anchoring the conversation group below it.
  Widget _buildSectionHeader(String title, dynamic themeColors) {
    final Color accent = themeColors.accent;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.md,
        end: AppSpacing.md,
        top: AppSpacing.md,
        bottom: AppSpacing.xs,
      ),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            border: Border.all(
              color: accent.withValues(alpha: 0.5),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
          ),
          child: Text(
            title,
            style: AppTypography.labelSmall.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    WidgetRef ref,
    ChatConversation conversation,
    bool isSelected,
    bool isMostRecent,
    dynamic themeColors,
  ) {
    final date = conversation.updatedAt ?? conversation.createdAt;
    final timeStr = DateFormat.Hm('ar').format(date);
    final Color accent = themeColors.accent;

    // β7 — most-recent emphasis: stronger accent border, slightly more
    // padding (acts as a 1.1x visual scale without breaking layout), and
    // a heavier title weight.
    final borderColor = isSelected
        ? accent.withValues(alpha: 0.6)
        : isMostRecent
            ? accent.withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.12);
    final tilePadding = isMostRecent
        ? const EdgeInsets.all(AppSpacing.sm + 2)
        : const EdgeInsets.all(AppSpacing.sm);
    final titleWeight = (isSelected || isMostRecent)
        ? FontWeight.w700
        : FontWeight.w500;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
            onSelectConversation(conversation.id);
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: tilePadding,
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.18)
                  : isMostRecent
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: borderColor,
                width: isMostRecent ? 1.2 : 1,
              ),
              boxShadow: isMostRecent
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.18),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Mode icon
                _buildModeIcon(conversation.mode, themeColors),
                const SizedBox(width: AppSpacing.sm),

                // Title and info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversation.title ?? conversation.mode.arabicName,
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: titleWeight,
                          fontSize: isMostRecent ? 15 : 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '${conversation.messageCount} رسالة',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '•',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            timeStr,
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Delete glass-circle (replaces Material IconButton ripple)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showDeleteConfirmation(
                      context,
                      ref,
                      conversation,
                    ),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white.withValues(alpha: 0.55),
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 200));
  }

  Widget _buildModeIcon(CounselingMode mode, dynamic themeColors) {
    IconData icon;
    switch (mode) {
      case CounselingMode.general:
        icon = Icons.chat_bubble_outline_rounded;
        break;
      case CounselingMode.relationship:
        icon = Icons.favorite_outline_rounded;
        break;
      case CounselingMode.conflict:
        icon = Icons.handshake_outlined;
        break;
      case CounselingMode.communication:
        icon = Icons.message_outlined;
        break;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: themeColors.accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: themeColors.accent.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        color: themeColors.accent,
        size: 18,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 48,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'لا توجد محادثات سابقة',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'ابدأ محادثة جديدة مع ${AIIdentity.name}',
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    ChatConversation conversation,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => GlassDialog(
        icon: Icons.delete_forever_rounded,
        iconAccent: const Color(0xFFD32F2F),
        title: 'حذف المحادثة؟',
        subtitle: 'سيتم حذف هذه المحادثة نهائياً ولا يمكن استرجاعها.',
        content: const SizedBox.shrink(),
        actions: [
          GlassActionButton(
            text: 'إلغاء',
            onPressed: () => Navigator.pop(ctx),
          ),
          GradientButton(
            text: 'حذف',
            icon: Icons.delete_forever_rounded,
            onPressed: () async {
              Navigator.pop(ctx);
              final chatHistoryService = ref.read(chatHistoryServiceProvider);
              await chatHistoryService.deleteConversation(conversation.id);
              ref.invalidate(chatHistoryProvider);
            },
            gradient: const LinearGradient(
              colors: [Color(0xFFD32F2F), Color(0xFF8B1F1F)],
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
