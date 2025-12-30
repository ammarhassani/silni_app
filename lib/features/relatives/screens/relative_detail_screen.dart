import 'package:flutter/foundation.dart' show kDebugMode;
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
import '../../../shared/models/relative_model.dart';
import '../../../shared/models/interaction_model.dart';
import '../../../shared/services/relatives_service.dart';
import '../../../shared/services/auth_service.dart';
import '../../../core/services/error_handler_service.dart';
import '../widgets/detail/widgets.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../../shared/widgets/theme_aware_dialog.dart';

/// Provider for watching a single relative (cache-first)
final relativeDetailProvider =
    StreamProvider.family<Relative?, String>((ref, relativeId) {
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
  final RelativesService _relativesService = RelativesService();
  final AuthService _authService = AuthService();

  bool _isLoggingInteraction = false;

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);
    final relativeAsync = ref.watch(relativeDetailProvider(widget.relativeId));

    return Scaffold(
      body: Semantics(
        label: 'تفاصيل القريب',
        child: GradientBackground(
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

                return CustomScrollView(
                  slivers: [
                    // Header with avatar and name
                    SliverToBoxAdapter(
                      child: RelativeHeaderWidget(
                        relative: relative,
                        themeColors: themeColors,
                        onDelete: () => _showDeleteConfirmation(relative),
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

  Future<void> _logInteraction(InteractionType type, String notes) async {
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
      await repository.createInteraction(interaction);

      if (mounted) {
        final themeColors = ref.read(themeColorsProvider);
        HapticFeedback.lightImpact();
        UIHelpers.showSnackBar(
          context,
          'تم تسجيل التواصل: ${type.arabicName}',
          backgroundColor: themeColors.primary,
        );
      }
    } catch (e) {
      if (mounted && kDebugMode) {
        debugPrint('Error logging interaction: $e');
      }
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      _isLoggingInteraction = false;
    }
  }

  Future<void> _showDeleteConfirmation(Relative relative) async {
    final themeColors = ref.read(themeColorsProvider);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ThemeAwareAlertDialog(
        title: 'تأكيد الحذف',
        titleIcon: const Icon(Icons.warning_rounded, color: Colors.red),
        content: Column(
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
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Text(
                'هذا الإجراء لا يمكن التراجع عنه',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'إلغاء',
              style: AppTypography.labelLarge.copyWith(color: themeColors.textOnGradient.withValues(alpha: 0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: themeColors.textOnGradient,
            ),
            child: Text(
              'حذف',
              style: AppTypography.labelLarge.copyWith(
                color: themeColors.textOnGradient,
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
      await _relativesService.permanentlyDeleteRelative(relative.id);

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
