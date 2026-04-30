import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/directional_icon.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/glass_bottom_sheet.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glass_pill_title.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/premium_loading_indicator.dart';
import '../../../shared/models/reminder_schedule_model.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/services/reminder_schedules_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../family_tree/providers/family_graph_providers.dart';
import '../../home/providers/home_providers.dart';
import '../../subscription/screens/paywall_screen.dart';
import '../../../core/providers/feature_config_provider.dart';
import '../../../core/providers/realtime_provider.dart';
import '../../../shared/utils/relationship_label_helper.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../widgets/widgets.dart';
import '../../../shared/widgets/message_widget.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  // Provider-sourced cache (for loading fallback)
  List<ReminderSchedule>? _providerSchedules;
  List<Relative>? _providerRelatives;
  // Optimistic override — set by mutations, takes priority over provider
  List<ReminderSchedule>? _optimisticSchedules;
  // Guard against concurrent mutations (rapid double-taps)
  bool _isMutating = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? '';
    final themeColors = ref.watch(themeColorsProvider);

    // Initialize real-time subscriptions for this user
    ref.watch(autoRealtimeSubscriptionsProvider);

    final schedulesAsync = ref.watch(reminderSchedulesStreamProvider(userId));

    // Clear optimistic override when stream emits fresh data
    ref.listen<AsyncValue<List<ReminderSchedule>>>(
      reminderSchedulesStreamProvider(userId),
      (previous, next) {
        if (next.hasValue && _optimisticSchedules != null) {
          setState(() => _optimisticSchedules = null);
        }
      },
    );

    // Rahim-scoped, self-node-excluded relatives via central gateway
    final relativesAsync = ref.watch(viewerFilteredRelativesProvider);

    List<Relative>? filteredRelatives;
    Map<String, String>? relationshipLabels;
    bool relativesHasError = false;

    if (relativesAsync.hasError) relativesHasError = true;

    if (relativesAsync.hasValue) {
      filteredRelatives = relativesAsync.value!;

      // Build perspective-aware relationship labels from family graph
      final groupInfo = ref.watch(userFamilyGroupProvider).valueOrNull;
      final graph = groupInfo != null
          ? ref.watch(sharedFamilyGraphProvider((
              groupId: groupInfo.groupId,
              viewerNodeId: groupInfo.nodeId,
            )))
          : ref.watch(familyGraphProvider(userId));
      final effectiveViewerId = groupInfo?.nodeId ?? userId;

      // Full raw relatives for relativesMap (labels need parent/sibling context)
      final rawAsync = groupInfo != null
          ? ref.watch(groupRelativesStreamProvider(groupInfo.groupId))
          : ref.watch(relativesStreamProvider(userId));
      final allRelatives = rawAsync.valueOrNull ?? filteredRelatives;
      final relativesMap = {for (final r in allRelatives) r.id: r};

      relationshipLabels = {
        for (final r in filteredRelatives)
          r.id: getRelationshipLabel(
            relative: r,
            viewerId: effectiveViewerId,
            graph: graph,
            relativesMap: relativesMap,
          ),
      };
    }

    // Update provider cache when data is available
    if (filteredRelatives != null) _providerRelatives = filteredRelatives;
    if (schedulesAsync.hasValue) _providerSchedules = schedulesAsync.value;

    // Optimistic schedules take priority over provider data
    final relatives = filteredRelatives ?? _providerRelatives;
    final schedules =
        _optimisticSchedules ?? schedulesAsync.valueOrNull ?? _providerSchedules;
    final hasError =
        relativesHasError || schedulesAsync.hasError;
    final isInitialLoad = relatives == null || schedules == null;

    return Scaffold(
      body: Semantics(
        label: 'شاشة التذكيرات',
        child: Stack(
          children: [
            const GradientBackground(animated: true, child: SizedBox.expand()),
            SafeArea(
              child: Column(
                children: [
                  // Messages (unified: banners + in-app messages)
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: MessageWidget(screenPath: '/reminders'),
                  ),
                  Expanded(
                    child: hasError && isInitialLoad
                        ? _buildError(themeColors)
                        : isInitialLoad
                            ? const Center(
                                child: PremiumLoadingIndicator(
                                  message: 'جاري تحميل البيانات...',
                                ),
                              )
                            : _buildContent(context, relatives, schedules,
                                themeColors, userId, relationshipLabels),
                  ),
                ],
              ),
            ),
            // Floating header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Semantics(
                        label: 'رجوع',
                        button: true,
                        child: IconButton(
                          onPressed: () => context.pop(),
                          icon: DirectionalIcon(Icons.arrow_back_ios_rounded,
                              color: themeColors.textOnGradient),
                        ),
                      ),
                      GlassPillTitle(
                        text: 'تذكير صلة الرحم',
                        subtitle: Text(
                          'نظّم تذكيراتك للتواصل مع أحبتك',
                          style: AppTypography.bodySmall.copyWith(
                            color: themeColors.textOnGradient
                                .withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Relative> relatives,
    List<ReminderSchedule> schedules,
    dynamic themeColors,
    String userId,
    Map<String, String>? relationshipLabels,
  ) {
    if (relatives.isEmpty) {
      return _buildEmptyState(themeColors);
    }

    final usedFrequencies =
        schedules.map((s) => s.frequency).toSet();
    final allFrequenciesUsed =
        usedFrequencies.length >= ReminderFrequency.values.length;

    return ListView(
      padding: const EdgeInsets.only(
        top: 100, // Clearance for floating header + subtitle
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.xxl,
      ),
      children: [
        // Unscheduled relatives banner
        UnscheduledRelativesSection(
          relatives: relatives,
          schedules: schedules,
        ),

        // Schedule cards or empty schedule state
        if (schedules.isEmpty)
          _buildEmptyScheduleState(themeColors)
        else ...[
          ...schedules.map((schedule) {
            return CompactScheduleCard(
              schedule: schedule,
              allRelatives: relatives,
              relationshipLabels: relationshipLabels,
              onToggle: (value) => _toggleSchedule(schedule, value),
              onEdit: () => _editSchedule(schedule),
              onDelete: () => _deleteSchedule(schedule),
              onAddRelatives: () =>
                  _showAddRelativesToSchedule(
                      schedule, schedules, relatives, relationshipLabels),
              onRemoveRelative: (relativeId) =>
                  _removeRelativeFromSchedule(schedule, relativeId),
            );
          }),
          const SizedBox(height: AppSpacing.sm),
          // Create new schedule button (hidden when all types used)
          if (!allFrequenciesUsed)
            _buildCreateScheduleButton(themeColors),
        ],
      ],
    );
  }

  Widget _buildCreateScheduleButton(dynamic themeColors) {
    return GlassCard(
      onTap: _showCreateScheduleBottomSheet,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.lg,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_rounded, color: themeColors.primary, size: 24),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'إنشاء تذكير جديد',
            style: AppTypography.titleSmall.copyWith(
              color: themeColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyScheduleState(dynamic themeColors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            const Text('🔔', style: TextStyle(fontSize: 48)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'لا توجد جداول تذكير بعد',
              style: AppTypography.bodyLarge
                  .copyWith(color: themeColors.textOnGradient),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'أنشئ أول تذكير للبدء بالتواصل مع أحبتك',
              style: AppTypography.bodySmall.copyWith(
                color: themeColors.textOnGradient.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            GradientButton(
              onPressed: _showCreateScheduleBottomSheet,
              text: 'أنشئ أول تذكير',
              icon: Icons.add_alarm_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(dynamic themeColors) {
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
                  color: themeColors.textOnGradient,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'أضف أقاربك أولاً لتتمكن من إنشاء تذكيرات',
                style: AppTypography.bodyMedium.copyWith(
                  color: themeColors.textOnGradient.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              GradientButton(
                onPressed: () => context.push(AppRoutes.relatives),
                text: 'إضافة أقارب',
                icon: Icons.person_add_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(dynamic themeColors) {
    final user = ref.read(currentUserProvider);
    return Center(
      child: GlassCard(
        margin: const EdgeInsets.all(AppSpacing.xl),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: themeColors.textOnGradient,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'حدث خطأ في تحميل البيانات',
              style: AppTypography.bodyLarge
                  .copyWith(color: themeColors.textOnGradient),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'يرجى التحقق من الاتصال بالإنترنت والمحاولة مرة أخرى',
              style: AppTypography.bodySmall.copyWith(
                color: themeColors.textOnGradient.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            GradientButton(
              onPressed: () {
                if (user != null) {
                  ref.invalidate(relativesStreamProvider(user.id));
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

  // --- Bottom sheet / dialog methods ---

  void _showCreateScheduleBottomSheet() {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final userId = user.id;

    // Use optimistic data if available (reflects pending deletes), then stream
    final schedulesAsync =
        ref.read(reminderSchedulesStreamProvider(userId));
    final schedules =
        _optimisticSchedules ?? schedulesAsync.valueOrNull ?? _providerSchedules ?? [];
    final usedFrequencies = schedules.map((s) => s.frequency).toSet();

    // Enforce reminder limit for free users
    final reminderLimit = ref.read(dynamicReminderLimitProvider);
    if (reminderLimit != -1 && schedules.length >= reminderLimit) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const PaywallScreen(
            featureToUnlock: 'unlimited_reminders',
            contextHeadline: 'تذكيرات غير محدودة',
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CreateScheduleBottomSheet(
        usedFrequencies: usedFrequencies,
        onTemplateSelected: (template) {
          Navigator.pop(context);
          _showCreateScheduleDialog(template, userId);
        },
      ),
    );
  }

  void _showCreateScheduleDialog(ReminderTemplate template, String userId) async {
    final result = await GlassBottomSheet.show<ReminderSchedule>(
      context: context,
      builder: (context) => CreateScheduleConfigSheet(
        template: template,
        userId: userId,
      ),
    );

    // Optimistic update — add created schedule to UI immediately
    if (result != null && mounted) {
      setState(() {
        _optimisticSchedules = [
          ...(_optimisticSchedules ?? _providerSchedules ?? []),
          result,
        ];
      });
      // Invalidate stream — ref.listen in build() clears optimistic on fresh data
      ref.invalidate(reminderSchedulesStreamProvider(userId));
    }
  }

  void _showAddRelativesToSchedule(
    ReminderSchedule schedule,
    List<ReminderSchedule> allSchedules,
    List<Relative> allRelatives,
    Map<String, String>? relationshipLabels,
  ) async {
    // Show relatives not already in THIS specific schedule
    // (viewer's own node already excluded by filteredRelatives)
    final notInThisSchedule = allRelatives
        .where((r) => !schedule.relativeIds.contains(r.id))
        .toList();
    final addedIds = await GlassBottomSheet.show<List<String>>(
      context: context,
      builder: (context) => AddRelativesBottomSheet(
        schedule: schedule,
        relatives: notInThisSchedule,
        relationshipLabels: relationshipLabels,
      ),
    );

    // Optimistic update so UI reflects changes immediately
    if (addedIds != null && addedIds.isNotEmpty && mounted) {
      setState(() {
        _optimisticSchedules =
            (_optimisticSchedules ?? _providerSchedules)?.map((s) {
          if (s.id == schedule.id) {
            return s.copyWith(
              relativeIds: [...s.relativeIds, ...addedIds],
            );
          }
          return s;
        }).toList();
      });
      // ref.listen in build() clears optimistic on fresh stream data
    }
  }

  void _editSchedule(ReminderSchedule schedule) async {
    final user = ref.read(currentUserProvider);
    await GlassBottomSheet.show(
      context: context,
      builder: (context) => EditScheduleBottomSheet(schedule: schedule),
    );

    // After bottom sheet closes, force refresh from this screen's ref
    if (mounted && user != null) {
      ref.invalidate(reminderSchedulesStreamProvider(user.id));
    }
  }

  // --- Action methods ---

  void _toggleSchedule(ReminderSchedule schedule, bool value) async {
    if (_isMutating) return;
    _isMutating = true;
    final service = ref.read(reminderSchedulesServiceProvider);

    // Optimistic update
    setState(() {
      _optimisticSchedules =
          (_optimisticSchedules ?? _providerSchedules)?.map((s) {
        if (s.id == schedule.id) return s.copyWith(isActive: value);
        return s;
      }).toList();
    });

    try {
      await service.updateSchedule(
        schedule.id,
        schedule.copyWith(isActive: value).toJson(),
      );
    } catch (e) {
      // Revert optimistic update
      setState(() => _optimisticSchedules = null);
      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          'حدث خطأ أثناء تحديث التذكير',
          isError: true,
        );
      }
    } finally {
      _isMutating = false;
    }
  }

  void _deleteSchedule(ReminderSchedule schedule) async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => _DeleteScheduleDialog(schedule: schedule),
    );

    if (confirmed == true && mounted) {
      if (_isMutating) return;
      _isMutating = true;
      final user = ref.read(currentUserProvider);
      final service = ref.read(reminderSchedulesServiceProvider);

      // Optimistic update — remove schedule from list
      setState(() {
        _optimisticSchedules =
            (_optimisticSchedules ?? _providerSchedules)
                ?.where((s) => s.id != schedule.id)
                .toList();
      });

      try {
        await service.deleteSchedule(schedule.id);
        // Invalidate stream so client-side checks (e.g. create gate) see fresh data
        if (mounted) {
          ref.invalidate(reminderSchedulesStreamProvider(user?.id ?? ''));
          UIHelpers.showSnackBar(context, 'تم حذف التذكير');
        }
      } catch (e) {
        // Revert optimistic update
        setState(() => _optimisticSchedules = null);
        if (mounted) {
          UIHelpers.showSnackBar(
            context,
            'حدث خطأ أثناء حذف التذكير',
            isError: true,
          );
        }
      } finally {
        _isMutating = false;
      }
    }
  }

  void _removeRelativeFromSchedule(
    ReminderSchedule schedule,
    String relativeId,
  ) async {
    if (_isMutating) return;
    _isMutating = true;
    final service = ref.read(reminderSchedulesServiceProvider);
    final updatedRelativeIds = List<String>.from(schedule.relativeIds)
      ..remove(relativeId);

    // Optimistic update — remove relative from schedule immediately
    setState(() {
      _optimisticSchedules =
          (_optimisticSchedules ?? _providerSchedules)?.map((s) {
        if (s.id == schedule.id) {
          return s.copyWith(relativeIds: updatedRelativeIds);
        }
        return s;
      }).toList();
    });

    try {
      await service.updateSchedule(
        schedule.id,
        schedule.copyWith(relativeIds: updatedRelativeIds).toJson(),
      );
    } catch (e) {
      // Revert optimistic update
      setState(() => _optimisticSchedules = null);
      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          'حدث خطأ أثناء إزالة القريب من التذكير',
          isError: true,
        );
      }
    } finally {
      _isMutating = false;
    }
  }
}

/// Premium glass delete confirmation dialog with warning icon and animations.
class _DeleteScheduleDialog extends ConsumerWidget {
  const _DeleteScheduleDialog({required this.schedule});

  final ReminderSchedule schedule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeColorsProvider);

    return Semantics(
      label: 'تأكيد حذف التذكير',
      liveRegion: true,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          borderRadius: AppSpacing.radiusLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning icon in red accent circle
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.statusError.withValues(alpha: 0.15),
                  border: Border.all(
                    color: colors.statusError.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.warning_rounded,
                    color: colors.statusError,
                    size: 32,
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms).scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.0, 1.0),
                    duration: 400.ms,
                    curve: Curves.easeOut,
                  ),

              const SizedBox(height: AppSpacing.lg),

              // Title
              Text(
                'حذف التذكير',
                style: AppTypography.titleLarge.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms).slideY(
                    begin: 0.05,
                    end: 0,
                    delay: 100.ms,
                    duration: 300.ms,
                  ),

              const SizedBox(height: AppSpacing.sm),

              // Body
              Text(
                'هل أنت متأكد من حذف هذا التذكير؟\nلا يمكن التراجع عن هذا الإجراء.',
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

              const SizedBox(height: AppSpacing.xl),

              // Action buttons
              Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: Semantics(
                      label: 'إلغاء',
                      button: true,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.textPrimary,
                          side: BorderSide(
                            color: colors.glassBorder,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                        ),
                        child: Text(
                          'إلغاء',
                          style: AppTypography.titleSmall.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: AppSpacing.md),

                  // Delete button
                  Expanded(
                    child: Semantics(
                      label: 'تأكيد الحذف',
                      button: true,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.statusError,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'حذف',
                          style: AppTypography.titleSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
            ],
          ),
        ),
      ),
    );
  }
}
