import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/premium_loading_indicator.dart';
import '../../auth/providers/auth_provider.dart';
import '../../family_tree/providers/family_graph_providers.dart';
import '../models/family_group_model.dart';
import '../providers/family_group_providers.dart';
import '../services/family_group_service.dart';
import '../services/node_invitation_service.dart';

/// Screen for joining a family group via invite code.
///
/// Accepts an invite code from the route parameter, looks up the group,
/// and provides a join button. Handles invalid codes, already-member,
/// and unauthenticated states.
///
/// Public links only add members — node claiming is handled by the
/// phone-based invitation system.
class JoinGroupScreen extends ConsumerStatefulWidget {
  final String inviteCode;

  const JoinGroupScreen({super.key, required this.inviteCode});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  FamilyGroup? _group;
  bool _isLoadingGroup = true;
  bool _isJoining = false;
  bool _alreadyMember = false;
  String? _errorMessage;
  // Member-slot replace flow: when the user is at the 2-member cap and
  // tries to join a 3rd group, we surface a picker of their current 2
  // groups instead of an error. `null` = no blocker; non-null = render
  // the picker view in place of the normal join CTA.
  List<FamilyGroup>? _memberSlotFullGroups;
  // Id of the group currently being left (drives per-tile spinner / disable).
  String? _leavingGroupId;

  @override
  void initState() {
    super.initState();
    _lookupGroup();
  }

  Future<void> _lookupGroup() async {
    try {
      // Validate invite code format
      if (widget.inviteCode.isEmpty || widget.inviteCode.length > 100) {
        if (mounted) {
          setState(() {
            _errorMessage = 'رمز الدعوة غير صالح';
            _isLoadingGroup = false;
          });
        }
        return;
      }

      final group = await FamilyGroupService.lookupGroupByInviteCode(
        widget.inviteCode,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => null,
      );

      if (group == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'رمز الدعوة غير صالح';
            _isLoadingGroup = false;
          });
        }
        return;
      }

      // Check if user is already a member
      final user = ref.read(currentUserProvider);
      if (user != null) {
        final isMember = await FamilyGroupService.isMember(
          groupId: group.id,
          userId: user.id,
        );
        if (mounted) {
          setState(() {
            _group = group;
            _alreadyMember = isMember;
            _isLoadingGroup = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _group = group;
            _isLoadingGroup = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'حدث خطأ أثناء البحث عن المجموعة';
          _isLoadingGroup = false;
        });
      }
    }
  }

  Future<void> _joinGroup() async {
    if (_isJoining) return;
    final user = ref.read(currentUserProvider);
    if (user == null) {
      final redirectPath = Uri.encodeComponent(
        '${AppRoutes.joinFamilyGroup}/${widget.inviteCode}',
      );
      context.go('${AppRoutes.login}?redirect=$redirectPath');
      return;
    }

    // Quota gate: the DB trigger caps member-role rows per user at 2. If
    // the user is already at the cap, swap the join view for a "replace"
    // picker so the user can leave one of their existing groups and
    // continue without bouncing back home.
    setState(() => _isJoining = true);
    try {
      final slots = await ref.read(myMembershipSlotsProvider.future);
      if (slots.memberSlotFull && mounted) {
        setState(() {
          _isJoining = false;
          _memberSlotFullGroups = slots.members;
        });
        return;
      }
    } catch (e) {
      // Slot fetch failure shouldn't block — the server-side trigger is
      // the source of truth and will return a friendly error if needed.
      debugPrint('Slot check failed (pre-join): $e');
    }

    try {
      // Validate the invite code (no DB write yet).
      final group = await FamilyGroupService.acceptInvite(
        inviteCode: widget.inviteCode,
      );

      if (!mounted) return;
      HapticFeedback.heavyImpact();

      // Check for a phone-based invitation — it's a fast-path that
      // skips the wizard because the admin already pre-identified the
      // joiner. This branch still creates the membership through the
      // invitation-accept RPC (not this refactor's concern).
      try {
        final invitationService = NodeInvitationService();
        final pending = await invitationService.getMyPendingInvitations();
        final matchingInvitation = pending.where(
          (inv) => inv.groupId == group.id,
        );
        if (matchingInvitation.isNotEmpty && mounted) {
          context.go(
            '${AppRoutes.invitationDetail}/${matchingInvitation.first.id}',
          );
          return;
        }
      } catch (e) {
        debugPrint('Failed to check pending invitations: $e');
      }

      // Drop the joiner into the identity-claim wizard, passing the
      // invite code as the auth token for pre-member RPCs.
      if (mounted) {
        context.go(
          '${AppRoutes.identityClaim}/${group.id}?invite=${Uri.encodeQueryComponent(widget.inviteCode)}',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isJoining = false;
          _errorMessage = e.toString().contains('invite') ||
                  e.toString().contains('دعوة')
              ? 'رمز الدعوة غير صالح أو منتهي الصلاحية'
              : 'حدث خطأ أثناء التحقق من المجموعة. يرجى المحاولة مرة أخرى';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);
    final user = ref.watch(currentUserProvider);

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
                          'انضمام لمجموعة عائلية',
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
                  child: _isLoadingGroup
                      ? const Center(child: PremiumLoadingIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: _errorMessage != null
                              ? _buildErrorView(themeColors)
                              : _memberSlotFullGroups != null
                                  ? _buildMemberCapView(themeColors)
                                  : _buildGroupPreview(
                                      themeColors,
                                      user != null,
                                    ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Member-cap "replace" view — shown when the user is already in 2
  /// groups and tries to join a 3rd. Lists their current member-role
  /// groups with a "pick to leave" button on each. After a successful
  /// leave we invalidate the slot provider and call `_joinGroup` again
  /// so the wizard kicks off seamlessly.
  Widget _buildMemberCapView(ThemeColors themeColors) {
    final groups = _memberSlotFullGroups ?? const <FamilyGroup>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Icon(
          Icons.swap_horizontal_circle_rounded,
          size: AppSpacing.iconXxl,
          color: themeColors.onSurface,
          semanticLabel: 'استبدال مجموعة',
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'للانضمام لهذه العائلة، عليك مغادرة إحدى عائلاتك',
          style: AppTypography.bodyLarge.copyWith(
            color: themeColors.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final group in groups) ...[
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.groups_rounded,
                      color: themeColors.onSurface,
                      size: AppSpacing.iconMd,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        group.name,
                        style: AppTypography.titleMedium.copyWith(
                          color: themeColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                GradientButton(
                  text: 'اختر للمغادرة',
                  // Disable every tile while any leave is in flight so the
                  // user can't double-tap or fire two leaves in parallel.
                  enabled: _leavingGroupId == null,
                  onPressed: () => _confirmAndLeave(group),
                  isLoading: _leavingGroupId == group.id,
                  icon: Icons.logout_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  Future<void> _confirmAndLeave(FamilyGroup group) async {
    final themeColors = ref.read(themeColorsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: themeColors.background2,
        title: Text(
          'مغادرة ${group.name}',
          style: AppTypography.titleMedium.copyWith(
            color: themeColors.onSurface,
          ),
        ),
        content: Text(
          'سيتم إزالتك من هذه المجموعة قبل الانضمام للمجموعة الجديدة.',
          style: AppTypography.bodyMedium.copyWith(
            color: themeColors.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: themeColors.statusError,
            ),
            child: const Text('مغادرة'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _leaveAndContinue(group);
  }

  Future<void> _leaveAndContinue(FamilyGroup group) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _leavingGroupId = group.id);
    try {
      // If the user is leaving their currently-active group, clear the
      // active-group preference first so the rest of the UI doesn't keep
      // pointing at a group the user no longer belongs to.
      final activeGroupInfo =
          ref.read(activeFamilyGroupProvider).valueOrNull;
      if (activeGroupInfo?.groupId == group.id) {
        await ref.read(activeGroupIdProvider.notifier).setActive(null);
      }

      await FamilyGroupService.leaveGroup(
        groupId: group.id,
        userId: user.id,
      );

      if (!mounted) return;
      // Refresh slot state + group list + active-group resolution so the
      // UI everywhere reflects the new membership shape.
      ref.invalidate(myMembershipSlotsProvider);
      ref.invalidate(userGroupsProvider(user.id));
      ref.invalidate(activeFamilyGroupProvider);

      setState(() {
        _memberSlotFullGroups = null;
        _leavingGroupId = null;
      });

      // Continue the original join flow — slot is now free.
      await _joinGroup();
    } catch (e) {
      if (!mounted) return;
      setState(() => _leavingGroupId = null);
      final themeColors = ref.read(themeColorsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذّر مغادرة المجموعة: ${e.toString()}'),
          backgroundColor: themeColors.statusError,
        ),
      );
    }
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

  Widget _buildGroupPreview(ThemeColors themeColors, bool isAuthenticated) {
    final group = _group;
    if (group == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),

        // Group icon
        Icon(
          Icons.family_restroom_rounded,
          size: AppSpacing.iconXxl,
          color: themeColors.onSurface,
        ),
        const SizedBox(height: AppSpacing.md),

        // Invitation text
        Text(
          'تمت دعوتك للانضمام إلى',
          style: AppTypography.bodyLarge.copyWith(
            color: themeColors.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),

        // Group name
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            group.name,
            style: AppTypography.headlineSmall.copyWith(
              color: themeColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Join / Already member / Login button
        if (_alreadyMember) ...[
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: themeColors.onSurface,
                  size: AppSpacing.iconMd,
                  semanticLabel: 'عضو بالفعل',
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'أنت عضو بالفعل في هذه المجموعة',
                  style: AppTypography.bodyMedium.copyWith(
                    color: themeColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GradientButton(
            text: 'عرض المجموعة',
            onPressed: () {
              context.go('${AppRoutes.familyGroupDetail}/${group.id}');
            },
            icon: Icons.arrow_forward_rounded,
          ),
        ] else if (!isAuthenticated) ...[
          Text(
            'سجّل دخولك أولاً للانضمام',
            style: AppTypography.bodyMedium.copyWith(
              color: themeColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          GradientButton(
            text: 'تسجيل الدخول',
            onPressed: () {
              final redirectPath = Uri.encodeComponent(
                '${AppRoutes.joinFamilyGroup}/${widget.inviteCode}',
              );
              context.go('${AppRoutes.login}?redirect=$redirectPath');
            },
            icon: Icons.login_rounded,
          ),
        ] else ...[
          GradientButton(
            text: 'متابعة للتعرّف عليك',
            onPressed: _joinGroup,
            isLoading: _isJoining,
            icon: Icons.group_add_rounded,
          ),
        ],
      ],
    );
  }
}
