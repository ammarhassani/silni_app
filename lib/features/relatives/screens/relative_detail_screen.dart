import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/contact_launcher.dart';
import '../../../core/providers/cache_provider.dart';
import '../../../core/providers/relative_streak_provider.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/voice_note_button.dart';
import '../../../shared/widgets/glass_dialog.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/services/supabase_storage_service.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/models/interaction_model.dart';
import '../../../shared/services/auth_service.dart';
import '../../../core/services/error_reporter.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../home/providers/home_providers.dart';
import '../widgets/detail/widgets.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../../shared/utils/relationship_label_helper.dart';
import '../../family_tree/providers/family_graph_providers.dart';
import '../../family_groups/widgets/send_invitation_card.dart';

/// Provider for watching a single relative (cache-first)
final relativeDetailProvider =
    StreamProvider.autoDispose.family<Relative?, String>((ref, relativeId) {
  final repository = ref.watch(relativesRepositoryProvider);
  return repository.watchRelative(relativeId);
});

class RelativeDetailScreen extends ConsumerStatefulWidget {
  final String relativeId;

  const RelativeDetailScreen({super.key, required this.relativeId});

  @override
  ConsumerState<RelativeDetailScreen> createState() =>
      _RelativeDetailScreenState();
}

class _RelativeDetailScreenState extends ConsumerState<RelativeDetailScreen> {
  final AuthService _authService = AuthService();

  bool _isLoggingInteraction = false;

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);
    final relativeAsync = ref.watch(relativeDetailProvider(widget.relativeId));

    return Scaffold(
      body: GradientBackground(
        animated: true,
        child: SafeArea(
          child: relativeAsync.when(
            loading: () => Center(
              child: CircularProgressIndicator(color: themeColors.primary),
            ),
            error: (_, _) => _buildErrorState(context, themeColors),
            data: (relative) {
              if (relative == null) {
                return _buildErrorState(context, themeColors);
              }

              // Compute perspective-shifted label.
              // In group mode, use the shared graph so labels reflect the
              // viewer's perspective, not the relative creator's.
              final groupInfo =
                  ref.watch(activeFamilyGroupProvider).valueOrNull;
              final graph = groupInfo != null
                  ? ref.watch(sharedFamilyGraphProvider((
                      groupId: groupInfo.groupId,
                      viewerNodeId: groupInfo.nodeId,
                    )))
                  : ref.watch(familyGraphProvider(relative.userId));
              final effectiveViewerId =
                  groupInfo?.nodeId ?? relative.userId;
              final label = getRelationshipLabel(
                relative: relative,
                viewerId: effectiveViewerId,
                graph: graph,
                relativesMap: graph != null ? {relative.id: relative} : null,
              );

              return CustomScrollView(
                slivers: [
                  // Header with avatar and name
                  SliverToBoxAdapter(
                    child: RelativeHeaderWidget(
                      relative: relative,
                      themeColors: themeColors,
                      onDelete: () => _showDeleteConfirmation(relative),
                      relationshipLabel: label,
                    ),
                  ),

                  // Contact actions
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: RelativeContactActions(
                        relative: relative,
                        onCall: () => _handleCall(relative.phoneNumber!),
                        onWhatsApp: () => _handleWhatsApp(relative.phoneNumber!),
                        onSms: () => _handleSms(relative.phoneNumber!),
                        onDetails: _scrollToDetails,
                        onVisit: () => _showInteractionDialog(
                          InteractionType.visit,
                          'تسجيل زيارة',
                          'أضف ملاحظات عن الزيارة (اختياري)',
                        ),
                        onGift: () => _showInteractionDialog(
                          InteractionType.gift,
                          'تسجيل هدية',
                          'ما هي الهدية؟ (اختياري)',
                        ),
                        onEvent: () => _showInteractionDialog(
                          InteractionType.event,
                          'تسجيل مناسبة',
                          'ما هي المناسبة؟ (اختياري)',
                        ),
                        isMaxUser: ref.watch(isMaxProvider),
                        onConversationStarters: () => AIConversationStartersSheet.show(
                          context,
                          ref,
                          relative,
                        ),
                      ),
                    ),
                  ),

                  // Phone-OTP fast-path admin CTA — invite this specific
                  // tree node directly. Self-hides for non-admins,
                  // self-claimed nodes, and non-group relatives.
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: SendInvitationCard(relative: relative),
                    ),
                  ),

                  // Stats card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: RelativeStatsCard(relative: relative),
                    ),
                  ),

                  // Details card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: RelativeDetailsCard(relative: relative),
                    ),
                  ),

                  // Recent interactions header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Text(
                        'التفاعلات الأخيرة',
                        style: AppTypography.headlineSmall.copyWith(
                          color: themeColors.textOnGradient,
                        ),
                      ),
                    ),
                  ),

                  // Recent interactions list
                  SliverToBoxAdapter(
                    child: RelativeInteractionsList(relativeId: relative.id),
                  ),

                  // Bottom spacing
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xxl),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, dynamic themeColors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: themeColors.textOnGradient.withValues(alpha: 0.7),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'لم يتم العثور على القريب',
            style: AppTypography.headlineMedium.copyWith(
              color: themeColors.textOnGradient,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            label: 'رجوع',
            button: true,
            child: ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('رجوع'),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToDetails() {
    HapticFeedback.lightImpact();
  }

  /// Show dialog to log a visit, gift, or event interaction
  Future<void> _showInteractionDialog(
    InteractionType type,
    String title,
    String hintText,
  ) async {
    final themeColors = ref.read(themeColorsProvider);
    final notesController = TextEditingController();

    final buttonColor = type == InteractionType.visit
        ? themeColors.statusInfo
        : type == InteractionType.gift
            ? themeColors.secondary
            : themeColors.statusWarning;

    final iconData = type == InteractionType.visit
        ? Icons.home_rounded
        : type == InteractionType.gift
            ? Icons.card_giftcard_rounded
            : Icons.celebration_rounded;

    String? recordedFilePath;

    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => GlassDialog(
        icon: iconData,
        iconAccent: buttonColor,
        title: title,
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: notesController,
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: TextStyle(
                        color: themeColors.textOnGradient
                            .withValues(alpha: 0.5),
                      ),
                      filled: true,
                      fillColor:
                          Colors.white.withValues(alpha: 0.1),
                      contentPadding: const EdgeInsets.all(AppSpacing.md),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                        borderSide: BorderSide(
                          color: buttonColor.withValues(alpha: 0.7),
                          width: 1.5,
                        ),
                      ),
                    ),
                    style: TextStyle(color: themeColors.textOnGradient),
                    maxLines: 3,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  VoiceNoteRecorder(
                    idleColor: themeColors.textOnGradient
                        .withValues(alpha: 0.7),
                    recordingColor: themeColors.statusError,
                    onRecordingChanged: (path) {
                      setDialogState(() => recordedFilePath = path);
                    },
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          GlassActionButton(
            text: 'إلغاء',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          GradientButton(
            text: 'تسجيل',
            icon: Icons.check_rounded,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            gradient: LinearGradient(
              colors: [buttonColor, buttonColor.withValues(alpha: 0.7)],
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Let dialog fully dismiss before logging
      await Future.microtask(() {});
      final notes = notesController.text.trim();
      await _logInteraction(
        type,
        notes.isNotEmpty ? notes : type.arabicName,
        audioFilePath: recordedFilePath,
      );
    }

    notesController.dispose();
  }

  Future<void> _handleCall(String phoneNumber) async {
    final success = await ContactLauncher.makeCall(phoneNumber, context: context);
    if (success) {
      await _logInteraction(InteractionType.call, 'مكالمة هاتفية');
    }
  }

  Future<void> _handleWhatsApp(String phoneNumber) async {
    final success = await ContactLauncher.openWhatsApp(phoneNumber, context: context);
    if (success) {
      await _logInteraction(InteractionType.message, 'رسالة واتساب');
    }
  }

  Future<void> _handleSms(String phoneNumber) async {
    final success = await ContactLauncher.sendSms(phoneNumber, context: context);
    if (success) {
      await _logInteraction(InteractionType.message, 'رسالة نصية');
    }
  }

  Future<void> _logInteraction(
    InteractionType type,
    String notes, {
    String? audioFilePath,
  }) async {
    if (_isLoggingInteraction) return;

    _isLoggingInteraction = true;

    try {
      final user = _authService.currentUser;
      if (user == null) {
        _isLoggingInteraction = false;
        return;
      }

      final interaction = Interaction(
        id: '',
        userId: user.id,
        relativeId: widget.relativeId,
        type: type,
        date: DateTime.now(),
        notes: notes,
        createdAt: DateTime.now(),
      );

      final repository = ref.read(interactionsRepositoryProvider);
      final interactionId = await repository.createInteraction(interaction);

      // Upload voice note if recorded. The interaction itself was already
      // saved above, so a failed upload doesn't lose the user's tap — it
      // just means the audio attachment is missing. Surface a non-blocking
      // warning so the user knows.
      bool voiceNoteUploadFailed = false;
      if (audioFilePath != null) {
        try {
          final storageService = SupabaseStorageService();
          final audioUrl = await storageService.uploadVoiceNote(
            audioFilePath,
            user.id,
            interactionId,
          );
          await repository.updateInteraction(
            interactionId,
            {'audio_note_url': audioUrl},
          );
        } catch (e) {
          voiceNoteUploadFailed = true;
          debugPrint('[VoiceNote] Upload failed: $e');
        }
      }

      if (mounted) {
        final themeColors = ref.read(themeColorsProvider);

        // Read the streak that was just updated by the service.
        final streakService = ref.read(relativeStreakServiceProvider);
        final streak = await streakService.getRelativeStreak(
          userId: user.id,
          relativeId: widget.relativeId,
        );
        final streakDays = streak?.currentStreak ?? 0;

        // Relative name (the screen already streams this relative).
        final relativeName = ref
                .read(relativeDetailProvider(widget.relativeId))
                .valueOrNull
                ?.fullName ??
            '';

        const milestones = {7, 14, 30, 50, 100};
        final isMilestone = milestones.contains(streakDays);

        HapticFeedback.lightImpact();
        if (!mounted) return;
        if (isMilestone) {
          UIHelpers.showSnackBar(
            context,
            '🔥 وصلت لـ$streakDays يوم متواصل مع $relativeName',
            backgroundColor: themeColors.primary,
          );
        } else if (streakDays > 0) {
          UIHelpers.showSnackBar(
            context,
            '🔥 سلسلة $streakDays أيام مع $relativeName',
            backgroundColor: themeColors.primary,
          );
        } else {
          UIHelpers.showSnackBar(
            context,
            'تم تسجيل التواصل مع $relativeName',
            backgroundColor: themeColors.primary,
          );
        }

        // Voice-note upload failure follows the success toast so the
        // interaction-saved feedback still lands first; the user knows
        // the tap counted but the audio didn't.
        if (voiceNoteUploadFailed && mounted) {
          UIHelpers.showSnackBar(
            context,
            'تم تسجيل التواصل، لكن تعذّر رفع المقطع الصوتي.',
            isError: true,
          );
        }
      }
    } catch (e) {
      // Interaction save failed before any of the success-side bookkeeping
      // ran. Surface to the user — the audit caught us showing a fake
      // success snackbar in this branch, which is worse than no feedback.
      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          'تعذّر تسجيل التواصل. حاول مرة أخرى.',
          isError: true,
        );
      }
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      _isLoggingInteraction = false;
    }
  }

  Future<void> _showDeleteConfirmation(Relative relative) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => GlassDialog(
        icon: Icons.warning_amber_rounded,
        iconAccent: const Color(0xFFD32F2F),
        title: 'تأكيد الحذف',
        subtitle: 'هل أنت متأكد من حذف هذا القريب؟',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    relative.fullName,
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    getSideAwareLabel(
                      relative.relationshipType,
                      relative.familySide,
                      relative.gender,
                    ),
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F).withValues(alpha: 0.18),
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: const Color(0xFFD32F2F).withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFFFAFA3),
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'هذا الإجراء لا يمكن التراجع عنه',
                      style: AppTypography.bodySmall.copyWith(
                        color: const Color(0xFFFFAFA3),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          GlassActionButton(
            text: 'إلغاء',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          GradientButton(
            text: 'حذف',
            icon: Icons.delete_forever_rounded,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            gradient: const LinearGradient(
              colors: [Color(0xFFD32F2F), Color(0xFF8B1F1F)],
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteRelative(relative);
    }
  }

  Future<void> _deleteRelative(Relative relative) async {
    try {
      // Use repository for deletion to update cache immediately
      final repository = ref.read(relativesRepositoryProvider);
      await repository.permanentlyDeleteRelative(relative.id);

      // Invalidate provider to refresh any listening widgets
      final user = _authService.currentUser;
      if (user != null) {
        ref.invalidate(relativesStreamProvider(user.id));
      }

      // Invalidate group providers if user is in a group
      final groupInfo = ref.read(activeFamilyGroupProvider).valueOrNull;
      if (groupInfo != null) {
        ref.invalidate(groupRelativesStreamProvider(groupInfo.groupId));
        ref.invalidate(sharedFamilyEdgesStreamProvider(groupInfo.groupId));
      }

      if (!mounted) return;

      final themeColors = ref.read(themeColorsProvider);
      UIHelpers.showSnackBar(
        context,
        'تم حذف ${relative.fullName} بنجاح',
        backgroundColor: themeColors.primary,
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;

      UIHelpers.showSnackBar(
        context,
        errorHandler.getArabicMessage(e),
        isError: true,
      );
    }
  }
}
