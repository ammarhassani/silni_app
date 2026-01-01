import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/ai_identity.dart';
import '../../../core/ai/ai_models.dart';
import '../../../core/ai/ai_prompts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/ai_config_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/services/chat_history_service.dart';
import '../providers/ai_chat_provider.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../../shared/widgets/theme_aware_dialog.dart';

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
    final themeColors = ref.watch(themeColorsProvider);

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
      backgroundColor: themeColors.background1,
      appBar: AppBar(
        backgroundColor: themeColors.background1,
        title: Text(
          'ذاكرة ${AIIdentity.name}',
          style: AppTypography.headlineSmall.copyWith(color: themeColors.textOnGradient),
        ),
        centerTitle: true,
        leading: Semantics(
          label: 'رجوع',
          button: true,
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: themeColors.textOnGradient),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Semantics(
            label: 'معلومات عن ذاكرة ${AIIdentity.name}',
            button: true,
            child: IconButton(
              icon: Icon(Icons.info_outline, color: themeColors.textOnGradient.withValues(alpha: 0.7)),
              onPressed: () => _showInfoDialog(themeColors),
            ),
          ),
        ],
      ),
      body: Semantics(
        label: 'قائمة ذكريات ${AIIdentity.name}',
        child: memoriesAsync.when(
          data: (memories) {
            // Use local list for immediate Dismissible removal
            final displayList = _localMemories ?? memories;
            return displayList.isEmpty
                ? _buildEmptyState(themeColors)
                : _buildMemoriesList(displayList, themeColors);
          },
          loading: () => Center(
            child: CircularProgressIndicator(color: themeColors.primaryLight),
          ),
          error: (error, stack) => _buildErrorState(error.toString(), themeColors),
        ),
      ),
    );
  }

  Widget _buildEmptyState(dynamic themeColors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology_outlined,
              size: 80,
              color: themeColors.textOnGradient.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'لا توجد ذكريات محفوظة',
              style: AppTypography.headlineSmall.copyWith(
                color: themeColors.textOnGradient.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'عندما تتحدث مع ${AIIdentity.name}، سيتذكر المعلومات المهمة عنك وعن عائلتك',
              style: AppTypography.bodyMedium.copyWith(
                color: themeColors.textOnGradient.withValues(alpha: 0.54),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, dynamic themeColors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withValues(alpha: 0.7),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'حدث خطأ في تحميل الذكريات',
              style: AppTypography.bodyLarge.copyWith(
                color: themeColors.textOnGradient.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoriesList(List<AIMemory> memories, dynamic themeColors) {
    // Get active category keys from admin config
    final activeKeys = AIPrompts.activeMemoryCategoryKeys;

    // Filter memories to only include active categories
    final activeMemories = memories.where((m) => activeKeys.contains(m.category.value)).toList();

    // Group memories by category
    final grouped = <AIMemoryCategory, List<AIMemory>>{};
    for (final memory in activeMemories) {
      grouped.putIfAbsent(memory.category, () => []).add(memory);
    }

    // Get dynamic category order from admin config
    final config = AIConfigService.instance;
    List<AIMemoryCategory> sortedCategories;

    if (config.isLoaded && config.memoryCategories.isNotEmpty) {
      // Use order from admin config
      sortedCategories = config.memoryCategories
          .where((c) => grouped.containsKey(AIMemoryCategory.fromString(c.categoryKey)))
          .map((c) => AIMemoryCategory.fromString(c.categoryKey))
          .toList();
    } else {
      // Fallback order
      sortedCategories = [
        AIMemoryCategory.userPreference,
        AIMemoryCategory.relativeFact,
        AIMemoryCategory.importantDate,
        AIMemoryCategory.conversationInsight,
      ].where((cat) => grouped.containsKey(cat)).toList();
    }

    if (sortedCategories.isEmpty) {
      return _buildEmptyState(themeColors);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final categoryMemories = grouped[category]!;
        return _buildCategorySection(category, categoryMemories, themeColors);
      },
    );
  }

  Widget _buildCategorySection(AIMemoryCategory category, List<AIMemory> memories, dynamic themeColors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Icon(
                _getCategoryIcon(category),
                size: 20,
                color: themeColors.primaryLight,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                category.arabicName,
                style: AppTypography.titleMedium.copyWith(
                  color: themeColors.primaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${memories.length}',
                style: AppTypography.bodySmall.copyWith(
                  color: themeColors.textOnGradient.withValues(alpha: 0.54),
                ),
              ),
            ],
          ),
        ),
        ...memories.map((memory) => _buildMemoryCard(memory, themeColors)),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _buildMemoryCard(AIMemory memory, dynamic themeColors) {
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
      confirmDismiss: (direction) => _confirmDelete(memory, themeColors),
      onDismissed: (direction) => _deleteMemory(memory, themeColors),
      child: Semantics(
        label: 'ذكرى: ${memory.content}',
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: themeColors.textOnGradient.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: themeColors.textOnGradient.withValues(alpha: 0.1),
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
                        color: themeColors.textOnGradient,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
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
                                : themeColors.textOnGradient.withValues(alpha: 0.2),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(memory.createdAt),
                          style: AppTypography.bodySmall.copyWith(
                            color: themeColors.textOnGradient.withValues(alpha: 0.38),
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

  Future<bool> _confirmDelete(AIMemory memory, dynamic themeColors) async {
    HapticFeedback.lightImpact();
    return await showDialog<bool>(
          context: context,
          builder: (context) => ThemeAwareAlertDialog(
            title: 'حذف المعلومة؟',
            titleIcon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
            content: Text(
              'هل تريد حذف هذه المعلومة من ذاكرة ${AIIdentity.name}؟',
              style: AppTypography.bodyMedium.copyWith(
                color: themeColors.textOnGradient.withValues(alpha: 0.9),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'إلغاء',
                  style: AppTypography.labelLarge.copyWith(
                    color: themeColors.textOnGradient.withValues(alpha: 0.54),
                  ),
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

  Future<void> _deleteMemory(AIMemory memory, dynamic themeColors) async {
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
      UIHelpers.showSnackBar(
        context,
        'تم حذف الذكرى',
        backgroundColor: themeColors.background2,
      );
    }
  }

  void _showInfoDialog(dynamic themeColors) {
    showDialog(
      context: context,
      builder: (context) => ThemeAwareAlertDialog(
        title: 'عن ذاكرة ${AIIdentity.name}',
        titleIcon: Icon(Icons.psychology, color: themeColors.primaryLight),
        content: Text(
          '${AIIdentity.name} يتذكر المعلومات المهمة من محادثاتكم لتقديم نصائح شخصية أفضل.\n\n'
          'يحفظ:\n'
          '• اسمك وتفضيلاتك\n'
          '• معلومات عن أقاربك\n'
          '• التواريخ المهمة\n'
          '• أنماط عائلتك\n\n'
          'يمكنك حذف أي معلومة بالسحب لليسار.',
          style: AppTypography.bodyMedium.copyWith(
            color: themeColors.textOnGradient.withValues(alpha: 0.8),
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'فهمت',
              style: AppTypography.labelLarge.copyWith(
                color: themeColors.primaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
