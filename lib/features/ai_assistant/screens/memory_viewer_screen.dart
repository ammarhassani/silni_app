import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/ai_models.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/services/chat_history_service.dart';
import '../providers/ai_chat_provider.dart';

/// Screen to view and manage AI memories
class MemoryViewerScreen extends ConsumerStatefulWidget {
  const MemoryViewerScreen({super.key});

  @override
  ConsumerState<MemoryViewerScreen> createState() => _MemoryViewerScreenState();
}

class _MemoryViewerScreenState extends ConsumerState<MemoryViewerScreen> {
  final ChatHistoryService _chatHistoryService = ChatHistoryService();

  // Local list for immediate removal (Dismissible requires sync removal)
  List<AIMemory>? _localMemories;
  // Track IDs being deleted to avoid showing them
  final Set<String> _deletingIds = {};

  @override
  Widget build(BuildContext context) {
    final memoriesAsync = ref.watch(aiMemoriesProvider);

    // Update local list when provider data changes (but preserve deletions)
    memoriesAsync.whenData((memories) {
      if (_localMemories == null) {
        _localMemories = List.from(memories);
      } else {
        // Merge new data, keeping deletions
        _localMemories = memories.where((m) => !_deletingIds.contains(m.id)).toList();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.islamicGreenDark,
      appBar: AppBar(
        backgroundColor: AppColors.islamicGreenDark,
        title: Text(
          'ذاكرة واصل',
          style: AppTypography.headlineSmall.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white70),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: memoriesAsync.when(
        data: (memories) {
          // Use local list for immediate Dismissible removal
          final displayList = _localMemories ?? memories;
          return displayList.isEmpty
              ? _buildEmptyState()
              : _buildMemoriesList(displayList);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.islamicGreenLight),
        ),
        error: (error, stack) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology_outlined,
              size: 80,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'لا توجد ذكريات محفوظة',
              style: AppTypography.headlineSmall.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'عندما تتحدث مع واصل، سيتذكر المعلومات المهمة عنك وعن عائلتك',
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ في تحميل الذكريات',
              style: AppTypography.bodyLarge.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoriesList(List<AIMemory> memories) {
    // Group memories by category
    final grouped = <AIMemoryCategory, List<AIMemory>>{};
    for (final memory in memories) {
      grouped.putIfAbsent(memory.category, () => []).add(memory);
    }

    // Sort categories by importance
    final sortedCategories = [
      AIMemoryCategory.userPreference,
      AIMemoryCategory.relativeFact,
      AIMemoryCategory.familyDynamic,
      AIMemoryCategory.importantDate,
      AIMemoryCategory.conversationInsight,
    ].where((cat) => grouped.containsKey(cat)).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final categoryMemories = grouped[category]!;
        return _buildCategorySection(category, categoryMemories);
      },
    );
  }

  Widget _buildCategorySection(AIMemoryCategory category, List<AIMemory> memories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(
                _getCategoryIcon(category),
                size: 20,
                color: AppColors.islamicGreenLight,
              ),
              const SizedBox(width: 8),
              Text(
                category.arabicName,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.islamicGreenLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${memories.length}',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
        ...memories.map((memory) => _buildMemoryCard(memory)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMemoryCard(AIMemory memory) {
    return Dismissible(
      key: Key(memory.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      confirmDismiss: (direction) => _confirmDelete(memory),
      onDismissed: (direction) => _deleteMemory(memory),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memory.content,
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Importance indicator
                      ...List.generate(
                        5,
                        (i) => Icon(
                          Icons.star,
                          size: 12,
                          color: i < (memory.importance / 2).ceil()
                              ? AppColors.premiumGold
                              : Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(memory.createdAt),
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(AIMemoryCategory category) {
    switch (category) {
      case AIMemoryCategory.userPreference:
        return Icons.person_outline;
      case AIMemoryCategory.relativeFact:
        return Icons.family_restroom;
      case AIMemoryCategory.familyDynamic:
        return Icons.groups_outlined;
      case AIMemoryCategory.importantDate:
        return Icons.calendar_today;
      case AIMemoryCategory.conversationInsight:
        return Icons.lightbulb_outline;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'اليوم';
    } else if (diff.inDays == 1) {
      return 'أمس';
    } else if (diff.inDays < 7) {
      return 'منذ ${diff.inDays} أيام';
    } else if (diff.inDays < 30) {
      return 'منذ ${(diff.inDays / 7).round()} أسابيع';
    } else {
      return 'منذ ${(diff.inDays / 30).round()} شهور';
    }
  }

  Future<bool> _confirmDelete(AIMemory memory) async {
    HapticFeedback.lightImpact();
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.islamicGreenDark,
            title: Text(
              'حذف الذكرى؟',
              style: AppTypography.titleLarge.copyWith(color: Colors.white),
            ),
            content: Text(
              'هل تريد حذف هذه المعلومة من ذاكرة واصل؟',
              style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'إلغاء',
                  style: AppTypography.labelLarge.copyWith(color: Colors.white54),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'حذف',
                  style: AppTypography.labelLarge.copyWith(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteMemory(AIMemory memory) async {
    // Immediately remove from local list (Dismissible requires sync removal)
    setState(() {
      _deletingIds.add(memory.id);
      _localMemories?.removeWhere((m) => m.id == memory.id);
    });

    // Delete from database in background
    await _chatHistoryService.deleteMemory(memory.id);
    ref.invalidate(aiMemoriesProvider);

    // Clean up tracking set after provider refreshes
    _deletingIds.remove(memory.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم حذف الذكرى',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.islamicGreenDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.islamicGreenDark,
        title: Row(
          children: [
            Icon(Icons.psychology, color: AppColors.islamicGreenLight),
            const SizedBox(width: 8),
            Text(
              'عن ذاكرة واصل',
              style: AppTypography.titleLarge.copyWith(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          'واصل يتذكر المعلومات المهمة من محادثاتكم لتقديم نصائح شخصية أفضل.\n\n'
          'يحفظ:\n'
          '• اسمك وتفضيلاتك\n'
          '• معلومات عن أقاربك\n'
          '• التواريخ المهمة\n'
          '• أنماط عائلتك\n\n'
          'يمكنك حذف أي معلومة بالسحب لليسار.',
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white70,
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'فهمت',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.islamicGreenLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
