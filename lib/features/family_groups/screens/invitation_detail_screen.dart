import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/premium_loading_indicator.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/home_providers.dart';
import '../../family_tree/providers/family_graph_providers.dart';
import '../models/node_invitation_model.dart';
import '../providers/family_group_providers.dart';
import '../providers/node_invitation_providers.dart';
import '../services/node_invitation_service.dart';
import '../services/family_sharing_service.dart';

/// Screen where an invitee can view and accept/decline a node invitation.
class InvitationDetailScreen extends ConsumerStatefulWidget {
  final String invitationId;

  const InvitationDetailScreen({super.key, required this.invitationId});

  @override
  ConsumerState<InvitationDetailScreen> createState() =>
      _InvitationDetailScreenState();
}

class _InvitationDetailScreenState
    extends ConsumerState<InvitationDetailScreen> {
  NodeInvitation? _invitation;
  bool _isLoading = true;
  bool _isAccepting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInvitation();
  }

  Future<void> _loadInvitation() async {
    try {
      final service = ref.read(nodeInvitationServiceProvider);
      final invitations = await service.getMyPendingInvitations();
      final match = invitations
          .where((inv) => inv.id == widget.invitationId)
          .toList();

      if (match.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = 'الدعوة غير موجودة أو لم تعد متاحة';
            _isLoading = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _invitation = match.first;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'حدث خطأ أثناء تحميل الدعوة';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _acceptInvitation() async {
    if (_isAccepting) return;
    final invitation = _invitation;
    if (invitation == null) return;

    setState(() => _isAccepting = true);

    try {
      final service = ref.read(nodeInvitationServiceProvider);
      await service.acceptInvitation(invitation.id);

      // Best-effort edge verification
      try {
        await FamilySharingService.verifySharedEdges(
          groupId: invitation.groupId,
        );
      } catch (e) {
        debugPrint('Edge verification failed (post-accept): $e');
      }

      if (mounted) {
        final user = ref.read(currentUserProvider);

        // Invalidate relevant providers
        ref.invalidate(userFamilyGroupProvider);
        ref.invalidate(groupRelativesStreamProvider(invitation.groupId));
        ref.invalidate(sharedFamilyEdgesStreamProvider(invitation.groupId));
        ref.invalidate(groupMemberNodeIdsProvider(invitation.groupId));
        if (user != null) {
          ref.invalidate(userGroupsProvider(user.id));
          ref.invalidate(relativesStreamProvider(user.id));
        }
        ref.invalidate(myPendingInvitationsProvider);
        ref.invalidate(pendingInvitationCountProvider);

        HapticFeedback.heavyImpact();
        context.go(AppRoutes.familyTree);

        // Show success snackbar after navigation
        Future.microtask(() {
          if (mounted) {
            UIHelpers.showSnackBar(
              context,
              'تم قبول الدعوة بنجاح! مرحباً بك في العائلة',
              icon: Icons.celebration_rounded,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAccepting = false);
        UIHelpers.showSnackBar(
          context,
          'حدث خطأ أثناء قبول الدعوة. يرجى المحاولة مرة أخرى',
          isError: true,
        );
      }
    }
  }

  Future<void> _declineInvitation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final themeColors = ref.read(themeColorsProvider);
        return AlertDialog(
          backgroundColor: themeColors.surface,
          title: Text(
            'رفض الدعوة',
            style: AppTypography.headlineSmall.copyWith(
              color: themeColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'هل تريد رفض الدعوة؟',
            style: AppTypography.bodyLarge.copyWith(
              color: themeColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'إلغاء',
                style: AppTypography.bodyMedium.copyWith(
                  color: themeColors.onSurface,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'نعم، رفض',
                style: AppTypography.bodyMedium.copyWith(
                  color: themeColors.statusError,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);

    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(animated: true, child: SizedBox.expand()),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.sm,
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(AppRoutes.home);
                          }
                        },
                        tooltip: 'العودة',
                        icon: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: themeColors.onSurface,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'دعوة عائلية',
                          style: AppTypography.headlineSmall.copyWith(
                            color: themeColors.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.iconXl),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: _isLoading
                      ? const Center(child: PremiumLoadingIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: _errorMessage != null
                              ? _buildErrorView(themeColors)
                              : _buildInvitationContent(themeColors),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(ThemeColors themeColors) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: AppSpacing.xxxl),
        Icon(
          Icons.error_outline_rounded,
          size: AppSpacing.iconXxl,
          color: themeColors.statusError,
          semanticLabel: 'خطأ',
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          _errorMessage ?? 'حدث خطأ غير معروف',
          style: AppTypography.bodyLarge.copyWith(
            color: themeColors.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        GradientButton(
          text: 'العودة للرئيسية',
          onPressed: () => context.go(AppRoutes.home),
          icon: Icons.home_rounded,
        ),
      ],
    );
  }

  Widget _buildInvitationContent(ThemeColors themeColors) {
    final invitation = _invitation;
    if (invitation == null) return const SizedBox.shrink();

    // Get Arabic label for the relationship type
    final relationshipArabic = invitation.relationshipType != null
        ? RelationshipType.fromString(invitation.relationshipType!).arabicName
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),

        // Family icon
        Icon(
          Icons.family_restroom_rounded,
          size: AppSpacing.iconXxl,
          color: themeColors.onSurface,
        ),
        const SizedBox(height: AppSpacing.md),

        // Group info card
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Text(
                invitation.groupName ?? 'مجموعة عائلية',
                style: AppTypography.headlineSmall.copyWith(
                  color: themeColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              if (invitation.invitedByName != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'دعاك ${invitation.invitedByName}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: themeColors.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Node info — which relative and relationship type
        if (invitation.relativeName != null) ...[
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: AppTypography.bodyLarge.copyWith(
                  color: themeColors.onSurface,
                ),
                children: [
                  const TextSpan(text: 'ستنضم كـ '),
                  TextSpan(
                    text: relationshipArabic != null
                        ? '${invitation.relativeName} ($relationshipArabic)'
                        : invitation.relativeName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],

        const SizedBox(height: AppSpacing.md),

        // Accept button
        GradientButton(
          text: 'قبول الدعوة',
          onPressed: _acceptInvitation,
          isLoading: _isAccepting,
          icon: Icons.check_circle_rounded,
        ),
        const SizedBox(height: AppSpacing.sm),

        // Decline button
        Center(
          child: TextButton(
            onPressed: _declineInvitation,
            child: Text(
              'رفض',
              style: AppTypography.bodyMedium.copyWith(
                color: themeColors.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
