import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/contact_launcher.dart';
import '../../../core/providers/cache_provider.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/voice_note_button.dart';
import '../../../shared/services/supabase_storage_service.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/models/interaction_model.dart';
import '../../../shared/services/auth_service.dart';
import '../../../core/services/error_handler_service.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../home/providers/home_providers.dart';
import '../widgets/detail/widgets.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../../shared/utils/relationship_label_helper.dart';
import '../../auth/providers/auth_provider.dart';
import '../../family_groups/services/family_sharing_service.dart';
import '../../family_tree/providers/family_graph_providers.dart';
import 'package:share_plus/share_plus.dart';

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
  bool _isInviting = false;

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
                  ref.watch(userFamilyGroupProvider).valueOrNull;
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

                  // Invite to family tree
                  if (!relative.isSelf)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: GestureDetector(
                          onTap: _isInviting ? null : () => _inviteRelative(relative),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isInviting)
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                else
                                  const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  relative.gender == Gender.female ? 'ادعيها لصِلني' : 'ادعيه لصِلني',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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

  Future<void> _inviteRelative(Relative relative) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isInviting = true);

    final box = context.findRenderObject() as RenderBox?;
    final shareOrigin =
        box != null ? box.localToGlobal(Offset.zero) & box.size : Rect.zero;

    try {
      // Check if user already has a group
      var group = await FamilySharingService.getUserGroup(user.id);

      if (group == null) {
        // Auto-create group from personal tree
        final familyName =
            user.userMetadata?['family_name'] as String? ?? 'عائلتي';
        final userGender =
            Gender.fromString(user.userMetadata?['gender'] as String?);

        group = await FamilySharingService.initializeSharedTree(
          userId: user.id,
          familyName: familyName,
          userDisplayName:
              user.userMetadata?['display_name'] as String? ?? 'أنا',
          userGender: userGender,
        );
      }

      // Generate invite link with relative ID
      final link = FamilySharingService.generateInviteLink(
        inviteCode: group.inviteCode,
        relativeId: relative.id,
      );

      // Share via system sheet (WhatsApp preferred)
      await Share.share(
        'انضم/ي لعائلتنا في صِلني 🌳\n$link',
        sharePositionOrigin: shareOrigin,
      );
    } catch (e) {
      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          'حدث خطأ أثناء إنشاء الدعوة',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isInviting = false);
    }
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
      builder: (dialogContext) => AlertDialog(
        backgroundColor: themeColors.background1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: Icon(iconData, color: buttonColor, size: 32),
        title: Text(
          title,
          style: AppTypography.titleLarge.copyWith(
            color: themeColors.textOnGradient,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor:
                          themeColors.surface.withValues(alpha: 0.3),
                    ),
                    style: TextStyle(color: themeColors.textOnGradient),
                    maxLines: 3,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 12),
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
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'إلغاء',
              style: AppTypography.labelLarge.copyWith(
                color: themeColors.textOnGradient.withValues(alpha: 0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
            ),
            child: Text(
              'تسجيل',
              style: AppTypography.labelLarge.copyWith(
                color: themeColors.onPrimary,
                fontWeight: FontWeight.bold,
              ),
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

      // Upload voice note if recorded
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
          debugPrint('[VoiceNote] Upload failed: $e');
        }
      }

      if (mounted) {
        final themeColors = ref.read(themeColorsProvider);
        HapticFeedback.lightImpact();
        UIHelpers.showSnackBar(
          context,
          'تم تسجيل التواصل: ${type.arabicName}',
          backgroundColor: themeColors.primary,
        );
      }
    } catch (_) {
      // Interaction logging failed silently
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      _isLoggingInteraction = false;
    }
  }

  Future<void> _showDeleteConfirmation(Relative relative) async {
    final themeColors = ref.read(themeColorsProvider);

    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: themeColors.background1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: Icon(Icons.warning_rounded, color: themeColors.statusError, size: 32),
        title: Text(
          'تأكيد الحذف',
          style: AppTypography.titleLarge.copyWith(
            color: themeColors.textOnGradient,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'هل أنت متأكد من حذف هذا القريب؟',
                style: AppTypography.bodyLarge.copyWith(color: themeColors.textOnGradient),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'اسم: ${relative.fullName}',
                style: AppTypography.bodyMedium.copyWith(
                  color: themeColors.textOnGradient.withValues(alpha: 0.7),
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'صلة القرابة: ${relative.relationshipType.arabicName}',
                style: AppTypography.bodyMedium.copyWith(
                  color: themeColors.textOnGradient.withValues(alpha: 0.7),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: themeColors.statusError.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: themeColors.statusError.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'هذا الإجراء لا يمكن التراجع عنه',
                  style: AppTypography.bodySmall.copyWith(
                    color: themeColors.statusError,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'إلغاء',
              style: AppTypography.labelLarge.copyWith(color: themeColors.textOnGradient.withValues(alpha: 0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColors.statusError,
            ),
            child: Text(
              'حذف',
              style: AppTypography.labelLarge.copyWith(
                color: themeColors.onPrimary,
                fontWeight: FontWeight.bold,
              ),
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
      final groupInfo = ref.read(userFamilyGroupProvider).valueOrNull;
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
