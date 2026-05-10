import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/services/error_reporter.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/glass_dialog.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/premium_loading_indicator.dart';
import '../../auth/providers/auth_provider.dart';
import '../../family_tree/providers/family_graph_providers.dart';
import '../../home/providers/home_providers.dart';
import '../models/family_group_model.dart';
import '../providers/family_group_providers.dart';
import '../services/family_group_service.dart';
import '../widgets/family_activity_card.dart';
import '../widgets/family_activity_feed.dart';
import '../providers/node_claim_providers.dart';
import '../widgets/invite_link_card.dart';
import '../widgets/pending_claims_card.dart';

/// Screen showing the detail view of a family group.
///
/// Displays group name, member list, invite link, and a leave button.
/// Uses GlassCard, GradientBackground, and AppTypography patterns.
class FamilyGroupScreen extends ConsumerStatefulWidget {
  final String groupId;

  const FamilyGroupScreen({super.key, required this.groupId});

  @override
  ConsumerState<FamilyGroupScreen> createState() => _FamilyGroupScreenState();
}

class _FamilyGroupScreenState extends ConsumerState<FamilyGroupScreen> {
  FamilyGroup? _group;
  bool _isLoadingGroup = true;
  bool _isLeaving = false;
  bool _isDeleting = false;
  String? _removingMemberId;

  @override
  void initState() {
    super.initState();
    _loadGroup();
  }

  Future<void> _loadGroup() async {
    try {
      final groups = await FamilyGroupService.getUserGroups(
        ref.read(currentUserProvider)?.id ?? '',
      );
      final match = groups.where((g) => g.id == widget.groupId).toList();
      if (mounted) {
        setState(() {
          _group = match.isNotEmpty ? match.first : null;
          _isLoadingGroup = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingGroup = false);
      }
    }
  }

  /// Whether the current user is an admin in this group.
  bool _isCurrentUserAdmin(List<FamilyGroupMember> members) {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return false;
    return members.any((m) => m.userId == userId && m.isAdmin);
  }

  Future<void> _removeMember(FamilyGroupMember member) async {
    if (_removingMemberId != null) return; // Guard against double-tap

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => GlassDialog(
        icon: Icons.person_remove_rounded,
        iconAccent: const Color(0xFFD32F2F),
        title: 'إزالة العضو',
        subtitle:
            'هل تريد إزالة ${member.displayName ?? 'هذا العضو'} من المجموعة؟',
        content: const SizedBox.shrink(),
        actions: [
          GlassActionButton(
            text: 'إلغاء',
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          GradientButton(
            text: 'إزالة',
            icon: Icons.person_remove_rounded,
            onPressed: () => Navigator.of(ctx).pop(true),
            gradient: const LinearGradient(
              colors: [Color(0xFFD32F2F), Color(0xFF8B1F1F)],
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _removingMemberId = member.id);

    try {
      await FamilyGroupService.removeMember(
        groupId: widget.groupId,
        memberId: member.id,
      );
      if (mounted) {
        ref.invalidate(groupMembersProvider(widget.groupId));
        ref.invalidate(groupRelativesStreamProvider(widget.groupId));
        ref.invalidate(sharedFamilyEdgesStreamProvider(widget.groupId));
        ref.invalidate(groupMemberNodeIdsProvider(widget.groupId));
        UIHelpers.showSnackBar(context, 'تمت إزالة العضو');
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          'حدث خطأ أثناء إزالة العضو: ${errorHandler.getArabicMessage(e)}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _removingMemberId = null);
    }
  }

  Future<void> _leaveGroup() async {
    if (_isLeaving) return; // Guard against double-tap
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final themeColors = ref.read(themeColorsProvider);

    // Check if user is the last admin with other members remaining
    FamilyGroupMember? selectedNewAdmin;
    final members = ref.read(groupMembersProvider(widget.groupId)).valueOrNull;
    if (members != null) {
      final isAdmin = members.any((m) => m.userId == user.id && m.isAdmin);
      final otherAdmins = members.where(
        (m) => m.userId != user.id && m.isAdmin,
      );
      final otherMembers = members.where((m) => m.userId != user.id);

      if (isAdmin && otherAdmins.isEmpty && otherMembers.isNotEmpty) {
        // Last admin — must pick a successor before leaving
        selectedNewAdmin = await _showAdminTransferPicker(
          themeColors,
          otherMembers.toList(),
        );
        if (selectedNewAdmin == null || !mounted) return;
      }
    }

    if (!mounted) return;

    // Confirm leave — admin transfer happens atomically after confirmation
    final leaveMessage = selectedNewAdmin != null
        ? 'سيتم نقل الإدارة إلى ${selectedNewAdmin.displayName ?? 'العضو المختار'} ومغادرة المجموعة. متابعة؟'
        : 'هل أنت متأكد من مغادرة هذه المجموعة؟';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => GlassDialog(
        icon: Icons.exit_to_app_rounded,
        iconAccent: themeColors.statusWarning,
        title: 'مغادرة المجموعة',
        subtitle: leaveMessage,
        content: const SizedBox.shrink(),
        actions: [
          GlassActionButton(
            text: 'إلغاء',
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          GradientButton(
            text: 'مغادرة',
            icon: Icons.logout_rounded,
            onPressed: () => Navigator.of(ctx).pop(true),
            gradient: LinearGradient(
              colors: [
                themeColors.statusWarning,
                themeColors.statusWarning.withValues(alpha: 0.7),
              ],
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLeaving = true);

    try {
      // Transfer admin first (if needed), then leave — both after confirmation
      if (selectedNewAdmin != null) {
        await FamilyGroupService.transferAdmin(
          groupId: widget.groupId,
          currentUserId: user.id,
          newAdminMemberId: selectedNewAdmin.id,
        );
      }

      await FamilyGroupService.leaveGroup(
        groupId: widget.groupId,
        userId: user.id,
      );
      if (mounted) {
        _invalidateAllProviders();
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.home);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLeaving = false);
        UIHelpers.showSnackBar(
          context,
          'حدث خطأ أثناء مغادرة المجموعة: ${errorHandler.getArabicMessage(e)}',
          isError: true,
        );
      }
    }
  }

  /// Show a picker for the user to select the new admin before leaving.
  Future<FamilyGroupMember?> _showAdminTransferPicker(
    ThemeColors themeColors,
    List<FamilyGroupMember> candidates,
  ) async {
    return showDialog<FamilyGroupMember>(
      context: context,
      builder: (ctx) => GlassDialog(
        icon: Icons.admin_panel_settings_rounded,
        iconAccent: themeColors.accent,
        title: 'اختر المسؤول الجديد',
        subtitle: 'اختر العضو الذي سيتولى إدارة المجموعة بعد مغادرتك',
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: candidates.length,
            itemBuilder: (ctx, i) {
              final member = candidates[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(ctx).pop(member),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: themeColors.accent.withValues(alpha: 0.22),
                              border: Border.all(
                                color: themeColors.accent
                                    .withValues(alpha: 0.5),
                                width: 1.2,
                              ),
                            ),
                            child: Icon(
                              Icons.person_rounded,
                              color: themeColors.accent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              member.displayName ?? 'عضو',
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white.withValues(alpha: 0.4),
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          GlassActionButton(
            text: 'إلغاء',
            onPressed: () => Navigator.of(ctx).pop(null),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGroup() async {
    if (_isDeleting) return; // Guard against double-tap
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => GlassDialog(
        icon: Icons.delete_forever_rounded,
        iconAccent: const Color(0xFFD32F2F),
        title: 'حذف المجموعة',
        subtitle:
            'سيتم حذف المجموعة وجميع البيانات المشتركة نهائيًا. هل تريد المتابعة؟',
        content: const SizedBox.shrink(),
        actions: [
          GlassActionButton(
            text: 'إلغاء',
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          GradientButton(
            text: 'حذف',
            icon: Icons.delete_forever_rounded,
            onPressed: () => Navigator.of(ctx).pop(true),
            gradient: const LinearGradient(
              colors: [Color(0xFFD32F2F), Color(0xFF8B1F1F)],
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      await FamilyGroupService.deleteGroup(widget.groupId);
      if (mounted) {
        _invalidateAllProviders();
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.home);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        UIHelpers.showSnackBar(
          context,
          'حدث خطأ أثناء حذف المجموعة: ${errorHandler.getArabicMessage(e)}',
          isError: true,
        );
      }
    }
  }

  void _invalidateAllProviders() {
    final userId = ref.read(currentUserProvider)?.id;
    ref.invalidate(userFamilyGroupProvider);
    ref.invalidate(groupRelativesStreamProvider(widget.groupId));
    ref.invalidate(sharedFamilyEdgesStreamProvider(widget.groupId));
    ref.invalidate(groupMembersProvider(widget.groupId));
    ref.invalidate(groupMemberNodeIdsProvider(widget.groupId));
    ref.invalidate(groupTodayInteractionsStreamProvider(widget.groupId));
    ref.invalidate(groupTodayContactedRelativesProvider(widget.groupId));
    if (userId != null) {
      ref.invalidate(userGroupsProvider(userId));
      ref.invalidate(relativesStreamProvider(userId));
      ref.invalidate(todayInteractionsStreamProvider(userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);
    final membersAsync = ref.watch(groupMembersProvider(widget.groupId));

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
                          _group?.name ?? 'المجموعة',
                          style: AppTypography.headlineSmall.copyWith(
                            color: themeColors.onSurface,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
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
                      : _group == null
                          ? _buildErrorView(themeColors)
                          : _buildGroupContent(themeColors, membersAsync),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(ThemeColors themeColors) {
    return Center(
      child: Text(
        'لم يتم العثور على المجموعة',
        style: AppTypography.bodyLarge.copyWith(
          color: themeColors.onSurface,
        ),
      ),
    );
  }

  Widget _buildGroupContent(
    ThemeColors themeColors,
    AsyncValue<List<FamilyGroupMember>> membersAsync,
  ) {
    final group = _group;
    if (group == null) return const SizedBox.shrink();
    final isAdmin = membersAsync.whenOrNull(
          data: (members) => _isCurrentUserAdmin(members),
        ) ??
        false;

    // Phone-invite subsystem cut from v1 launch (CTO 2026-04-26). Admins
    // and members both see the main group tab; link-share via
    // InviteLinkCard is the v1 invite mechanism.
    return _buildMainTab(themeColors, membersAsync, group, isAdmin);
  }

  Widget _buildMainTab(
    ThemeColors themeColors,
    AsyncValue<List<FamilyGroupMember>> membersAsync,
    FamilyGroup group,
    bool isAdmin,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        _invalidateAllProviders();
        await _loadGroup();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Group info card
            GlassCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  Icon(
                    Icons.family_restroom_rounded,
                    size: AppSpacing.iconXl,
                    color: themeColors.onSurface,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    group.name,
                    style: AppTypography.titleLarge.copyWith(
                      color: themeColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Family activity stats
            FamilyActivityCard(
              groupId: widget.groupId,
              familyName: group.name,
            ),
            const SizedBox(height: AppSpacing.md),

            // Family activity feed
            FamilyActivityFeed(groupId: widget.groupId),
            const SizedBox(height: AppSpacing.md),

            // Invite link card (admins only)
            if (isAdmin) ...[
              InviteLinkCard(
                inviteCode: group.inviteCode,
                isAdmin: true,
                onRotate: () async {
                  try {
                    final newCode = await FamilyGroupService.rotateInviteCode(group.id);
                    if (mounted) {
                      setState(() {
                        _group = group.copyWith(inviteCode: newCode);
                      });
                    }
                  } catch (e) {
                    if (mounted) {
                      UIHelpers.showSnackBar(
                        context,
                        'حدث خطأ أثناء تجديد الرابط: ${errorHandler.getArabicMessage(e)}',
                        isError: true,
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Pending identity-claim queue (hidden when empty).
              PendingClaimsCard(groupId: widget.groupId),
              const SizedBox(height: AppSpacing.md),
            ],

            // Members section
            Text(
              'الأعضاء',
              style: AppTypography.titleMedium.copyWith(
                color: themeColors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            membersAsync.when(
              data: (members) => _buildMembersList(themeColors, members, isAdmin),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: PremiumLoadingIndicator(),
                ),
              ),
              error: (error, _) => GlassCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Text(
                      'حدث خطأ في تحميل الأعضاء',
                      style: AppTypography.bodyMedium.copyWith(
                        color: themeColors.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton.icon(
                      onPressed: () => ref.invalidate(groupMembersProvider(widget.groupId)),
                      icon: Icon(Icons.refresh_rounded, color: themeColors.onSurface),
                      label: Text(
                        'إعادة المحاولة',
                        style: TextStyle(color: themeColors.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Leave group button
            GlassCard(
              onTap: _isLeaving ? null : _leaveGroup,
              semanticsLabel: 'غادر المجموعة',
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLeaving)
                    SizedBox(
                      width: AppSpacing.iconSm,
                      height: AppSpacing.iconSm,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          themeColors.statusError,
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.exit_to_app_rounded,
                      size: AppSpacing.iconMd,
                      color: themeColors.statusError,
                    ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'غادر المجموعة',
                    style: AppTypography.labelLarge.copyWith(
                      color: themeColors.statusError,
                    ),
                  ),
                ],
              ),
            ),

            // Delete group button (admin only)
            if (isAdmin) ...[
              const SizedBox(height: AppSpacing.sm),
              GlassCard(
                onTap: _isDeleting ? null : _deleteGroup,
                semanticsLabel: 'حذف المجموعة',
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                  horizontal: AppSpacing.md,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isDeleting)
                      SizedBox(
                        width: AppSpacing.iconSm,
                        height: AppSpacing.iconSm,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            themeColors.statusError,
                          ),
                        ),
                      )
                    else
                      Icon(
                        Icons.delete_forever_rounded,
                        size: AppSpacing.iconMd,
                        color: themeColors.statusError,
                      ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'حذف المجموعة',
                      style: AppTypography.labelLarge.copyWith(
                        color: themeColors.statusError,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMembersList(
    ThemeColors themeColors,
    List<FamilyGroupMember> members,
    bool isAdmin,
  ) {
    final currentUserId = ref.read(currentUserProvider)?.id;

    if (members.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          'لا يوجد أعضاء بعد',
          style: AppTypography.bodyMedium.copyWith(
            color: themeColors.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: members.map((member) {
        // Admin can remove non-admin members (not themselves)
        final canRemove =
            isAdmin && !member.isAdmin && member.userId != currentUserId;
        final isUnlinked = !member.isAdmin && member.relativeIdInTree == null;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: InkWell(
            // Admin-only: tap an unlinked-member row to review their
            // pending node_claim (or get a hint that they haven't
            // submitted yet). Non-admins / linked members: no-op.
            onTap: (isAdmin && isUnlinked)
                ? () => _openClaimForMember(member)
                : null,
            borderRadius: BorderRadius.circular(AppSpacing.md),
            child: GlassCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: AppSpacing.avatarSm / 2,
                  backgroundColor: themeColors.onSurface.withValues(alpha: 0.15),
                  child: Icon(
                    Icons.person_rounded,
                    size: AppSpacing.iconSm,
                    color: themeColors.onSurface,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Member info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.displayName ?? 'عضو',
                        style: AppTypography.bodyMedium.copyWith(
                          color: themeColors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Status sub-line: linked nodes get nothing; unlinked
                      // members get a "hasn't picked their spot yet" hint so
                      // admin can tell apart approved members from joiners
                      // who are still mid-wizard or awaiting approval.
                      if (member.relativeIdInTree == null && !member.isAdmin)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'لم يُحدِّد مكانه في الشجرة بعد',
                            style: AppTypography.labelSmall.copyWith(
                              color:
                                  themeColors.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Validated badge (linked to tree node)
                if (member.relativeIdInTree != null)
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xs),
                    child: Icon(
                      Icons.verified_rounded,
                      size: AppSpacing.iconSm,
                      color: themeColors.onSurface,
                      semanticLabel: 'مرتبط بالشجرة',
                    ),
                  )
                else if (!member.isAdmin)
                  // Unlinked-member badge — clearer than the absence of the
                  // verified mark
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xs),
                    child: Icon(
                      Icons.help_outline_rounded,
                      size: AppSpacing.iconSm,
                      color: themeColors.onSurface.withValues(alpha: 0.55),
                      semanticLabel: 'لم يُحدِّد مكانه',
                    ),
                  ),
                // Role badge
                if (member.isAdmin)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: themeColors.onSurface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      'مسؤول',
                      style: AppTypography.labelSmall.copyWith(
                        color: themeColors.onSurface,
                      ),
                    ),
                  ),
                // Remove button (admin only, not on self or other admins)
                if (canRemove)
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xs),
                    child: _removingMemberId == member.id
                        ? SizedBox(
                            width: AppSpacing.iconSm,
                            height: AppSpacing.iconSm,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                themeColors.statusError,
                              ),
                            ),
                          )
                        : IconButton(
                            onPressed: _removingMemberId != null
                                ? null
                                : () => _removeMember(member),
                            tooltip: 'إزالة العضو',
                            icon: Icon(
                              Icons.person_remove_rounded,
                              size: AppSpacing.iconSm,
                              color: themeColors.statusError,
                            ),
                          ),
                  ),
              ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Admin tapped an unlinked-member row. Look up their pending
  /// node_claim in this group; if found, navigate to the admin review
  /// screen. If not, surface a snackbar explaining the state.
  ///
  /// Force-invalidates the provider before reading so a claim that
  /// landed via realtime AFTER the screen first rendered is picked up.
  Future<void> _openClaimForMember(FamilyGroupMember member) async {
    ref.invalidate(groupPendingClaimsProvider(widget.groupId));
    try {
      final claims = await ref
          .read(groupPendingClaimsProvider(widget.groupId).future);
      final match = claims.where((c) => c.claimantUserId == member.userId);
      if (match.isNotEmpty) {
        final claimId = match.first.id;
        if (!mounted) return;
        context.push('${AppRoutes.reviewClaim}/$claimId');
        return;
      }
      if (!mounted) return;
      UIHelpers.showSnackBar(
        context,
        'هذا العضو لم يقدم طلب انضمام بعد. اطلب منه فتح التطبيق وإكمال "تأكيد المكان".',
      );
    } catch (e) {
      if (!mounted) return;
      UIHelpers.showSnackBar(
        context,
        'تعذّر تحميل الطلبات: $e',
        isError: true,
      );
    }
  }
}
