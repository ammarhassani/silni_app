import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/models/reminder_schedule_model.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/services/reminder_schedules_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/home_providers.dart';
import '../../../core/providers/realtime_provider.dart';
import '../widgets/widgets.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  ReminderFrequency? _selectedFrequency;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? '';

    // Initialize real-time subscriptions for this user
    ref.watch(autoRealtimeSubscriptionsProvider);

    final schedulesAsync = ref.watch(reminderSchedulesStreamProvider(userId));
    final relativesAsync = ref.watch(relativesStreamProvider(userId));

    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(animated: true, child: SizedBox.expand()),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: relativesAsync.when(
                    data: (relatives) => schedulesAsync.when(
                      data: (schedules) =>
                          _buildContent(context, relatives, schedules),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, _) => _buildError(),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => _buildError(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تذكير صلة الرحم',
                  style: AppTypography.headlineLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'نظّم تذكيراتك للتواصل مع أحبتك',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Relative> relatives,
    List<ReminderSchedule> schedules,
  ) {
    if (relatives.isEmpty) {
      return _buildEmptyState();
    }

    final unassignedRelatives = _getUnassignedRelatives(relatives, schedules);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reminder Templates Section
          Text(
            '✨ اختر نوع التذكير',
            style: AppTypography.headlineMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.md),
          ReminderTemplatesWidget(
            selectedFrequency: _selectedFrequency,
            onTemplateSelected: (template) {
              setState(() {
                _selectedFrequency = _selectedFrequency == template.frequency
                    ? null
                    : template.frequency;
              });
              if (_selectedFrequency != null) {
                _showCreateScheduleDialog(template);
              }
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          // Schedule Cards
          Text(
            '📅 جداول التذكير',
            style: AppTypography.headlineMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildScheduleCards(schedules, relatives),
          const SizedBox(height: AppSpacing.xl),

          // Unassigned Relatives
          if (unassignedRelatives.isNotEmpty) ...[
            Text(
              '👥 الأقارب غير المضافين',
              style: AppTypography.headlineMedium.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.md),
            UnassignedRelativesWidget(
              unassignedRelatives: unassignedRelatives,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleCards(
    List<ReminderSchedule> schedules,
    List<Relative> relatives,
  ) {
    if (schedules.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const Text('📝', style: TextStyle(fontSize: 48)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'لا توجد جداول تذكير بعد',
              style: AppTypography.bodyLarge.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'اختر نوع تذكير من الأعلى للبدء',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: schedules.map((schedule) {
        return ScheduleCard(
          schedule: schedule,
          allRelatives: relatives,
          onToggle: (value) => _toggleSchedule(schedule, value),
          onEdit: () => _editSchedule(schedule),
          onDelete: () => _deleteSchedule(schedule),
          onAddRelatives: () => _showAddRelativesToSchedule(schedule, relatives),
          onRemoveRelative: (relativeId) =>
              _removeRelativeFromSchedule(schedule, relativeId),
          onDrop: (relative) => _handleDrop(schedule, relative),
        );
      }).toList(),
    );
  }

  List<Relative> _getUnassignedRelatives(
    List<Relative> allRelatives,
    List<ReminderSchedule> schedules,
  ) {
    final assignedIds = schedules
        .expand((schedule) => schedule.relativeIds)
        .toSet();

    return allRelatives
        .where((relative) => !assignedIds.contains(relative.id))
        .toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('👥', style: TextStyle(fontSize: 64)),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'لا يوجد أقارب بعد',
                style: AppTypography.headlineMedium.copyWith(
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'أضف أقاربك أولاً لتتمكن من إنشاء تذكيرات',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              GradientButton(
                onPressed: () => context.pop(),
                text: 'إضافة أقارب',
                icon: Icons.person_add_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    final user = ref.read(currentUserProvider);
    return Center(
      child: GlassCard(
        margin: const EdgeInsets.all(AppSpacing.xl),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'حدث خطأ في تحميل البيانات',
              style: AppTypography.bodyLarge.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'يرجى التحقق من الاتصال بالإنترنت والمحاولة مرة أخرى',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            GradientButton(
              onPressed: () {
                if (user != null) {
                  ref.invalidate(reminderSchedulesStreamProvider(user.id));
                }
              },
              text: 'إعادة المحاولة',
              icon: Icons.refresh_rounded,
            ),
          ],
        ),
      ),
    );
  }

  // --- Dialog methods ---

  void _showCreateScheduleDialog(ReminderTemplate template) {
    final user = ref.read(currentUserProvider);
    final userId = user?.id ?? '';

    showDialog(
      context: context,
      builder: (context) => CreateScheduleDialog(
        template: template,
        userId: userId,
      ),
    );
  }

  void _showAddRelativesToSchedule(
    ReminderSchedule schedule,
    List<Relative> allRelatives,
  ) {
    final unassigned = allRelatives
        .where((r) => !schedule.relativeIds.contains(r.id))
        .toList();

    showDialog(
      context: context,
      builder: (context) => AddRelativesDialog(
        schedule: schedule,
        relatives: unassigned,
      ),
    );
  }

  void _editSchedule(ReminderSchedule schedule) {
    showDialog(
      context: context,
      builder: (context) => EditScheduleDialog(schedule: schedule),
    );
  }

  // --- Action methods ---

  void _toggleSchedule(ReminderSchedule schedule, bool value) async {
    final service = ref.read(reminderSchedulesServiceProvider);
    try {
      await service.updateSchedule(
        schedule.id,
        schedule.copyWith(isActive: value).toJson(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  void _deleteSchedule(ReminderSchedule schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف التذكير'),
        content: const Text('هل أنت متأكد من حذف هذا التذكير؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final service = ref.read(reminderSchedulesServiceProvider);
      try {
        await service.deleteSchedule(schedule.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف التذكير')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: $e')),
          );
        }
      }
    }
  }

  void _removeRelativeFromSchedule(
    ReminderSchedule schedule,
    String relativeId,
  ) async {
    final service = ref.read(reminderSchedulesServiceProvider);
    try {
      final updatedRelativeIds = List<String>.from(schedule.relativeIds)
        ..remove(relativeId);

      await service.updateSchedule(
        schedule.id,
        schedule.copyWith(relativeIds: updatedRelativeIds).toJson(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  void _handleDrop(ReminderSchedule schedule, Relative relative) async {
    final updatedRelativeIds = [...schedule.relativeIds, relative.id];

    final service = ref.read(reminderSchedulesServiceProvider);
    try {
      await service.updateSchedule(schedule.id, {
        'relative_ids': updatedRelativeIds,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تمت إضافة ${relative.fullName} إلى التذكير'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }
}
