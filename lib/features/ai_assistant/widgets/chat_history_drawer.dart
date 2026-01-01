import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/ai/ai_identity.dart';
import '../../../core/ai/ai_models.dart';
import '../providers/ai_chat_provider.dart';

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

    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      decoration: BoxDecoration(
        color: AppColors.islamicGreenDark,
        border: Border(
          left: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // New Chat Button
            _buildNewChatButton(context),

            const SizedBox(height: AppSpacing.sm),

            // Divider
            Divider(
              color: Colors.white.withValues(alpha: 0.1),
              height: 1,
            ),

            // Conversation List
            Expanded(
              child: historyAsync.when(
                data: (conversations) => _buildConversationList(
                  context,
                  ref,
                  conversations,
                  currentConversation?.id,
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.islamicGreenLight,
                  ),
                ),
                error: (error, stack) => _buildEmptyState(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
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
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'اختر محادثة لاستكمالها',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildNewChatButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
            onNewChat();
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.islamicGreenPrimary.withValues(alpha: 0.5),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.islamicGreenPrimary.withValues(alpha: 0.2),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: AppColors.islamicGreenLight,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'محادثة جديدة',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.islamicGreenLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConversationList(
    BuildContext context,
    WidgetRef ref,
    List<ChatConversation> conversations,
    String? currentId,
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

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: [
        if (todayConversations.isNotEmpty) ...[
          _buildSectionHeader('اليوم'),
          ...todayConversations.map((conv) => _buildConversationTile(
                context,
                ref,
                conv,
                conv.id == currentId,
              )),
        ],
        if (yesterdayConversations.isNotEmpty) ...[
          _buildSectionHeader('أمس'),
          ...yesterdayConversations.map((conv) => _buildConversationTile(
                context,
                ref,
                conv,
                conv.id == currentId,
              )),
        ],
        if (thisWeekConversations.isNotEmpty) ...[
          _buildSectionHeader('هذا الأسبوع'),
          ...thisWeekConversations.map((conv) => _buildConversationTile(
                context,
                ref,
                conv,
                conv.id == currentId,
              )),
        ],
        if (olderConversations.isNotEmpty) ...[
          _buildSectionHeader('أقدم'),
          ...olderConversations.map((conv) => _buildConversationTile(
                context,
                ref,
                conv,
                conv.id == currentId,
              )),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Text(
        title,
        style: AppTypography.labelSmall.copyWith(
          color: Colors.white54,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    WidgetRef ref,
    ChatConversation conversation,
    bool isSelected,
  ) {
    final date = conversation.updatedAt ?? conversation.createdAt;
    final timeStr = DateFormat.Hm('ar').format(date);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
            onSelectConversation(conversation.id);
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.islamicGreenPrimary.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: isSelected
                  ? Border.all(
                      color: AppColors.islamicGreenPrimary.withValues(alpha: 0.5),
                    )
                  : null,
            ),
            child: Row(
              children: [
                // Mode icon
                _buildModeIcon(conversation.mode),
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
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
                              color: Colors.white54,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '•',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white38,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            timeStr,
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Delete button
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white.withValues(alpha: 0.4),
                    size: 18,
                  ),
                  onPressed: () => _showDeleteConfirmation(context, ref, conversation),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 200));
  }

  Widget _buildModeIcon(CounselingMode mode) {
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
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Icon(
        icon,
        color: AppColors.islamicGreenLight,
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
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.islamicGreenDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Text(
          'حذف المحادثة؟',
          style: AppTypography.titleMedium.copyWith(color: Colors.white),
          textAlign: TextAlign.right,
        ),
        content: Text(
          'سيتم حذف هذه المحادثة نهائياً ولا يمكن استرجاعها.',
          style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: AppTypography.buttonMedium.copyWith(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final chatHistoryService = ref.read(chatHistoryServiceProvider);
              await chatHistoryService.deleteConversation(conversation.id);
              ref.invalidate(chatHistoryProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'حذف',
              style: AppTypography.buttonMedium,
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
