import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/premium_loading_indicator.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/family_group_model.dart';
import '../providers/family_group_providers.dart';
import '../services/family_group_service.dart';
import '../widgets/family_leaderboard.dart';
import '../widgets/invite_link_card.dart';

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

  Future<void> _leaveGroup() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مغادرة المجموعة'),
        content: const Text('هل أنت متأكد من مغادرة هذه المجموعة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('مغادرة'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLeaving = true);

    try {
      await FamilyGroupService.leaveGroup(
        groupId: widget.groupId,
        userId: user.id,
      );
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLeaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء مغادرة المجموعة: $e')),
        );
      }
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
                        onPressed: () => context.pop(),
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
    final group = _group!;

    return SingleChildScrollView(
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
                  color: themeColors.primary,
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

          // Invite link card
          InviteLinkCard(inviteCode: group.inviteCode),
          const SizedBox(height: AppSpacing.md),

          // Weekly leaderboard
          FamilyLeaderboard(groupId: widget.groupId),
          const SizedBox(height: AppSpacing.md),

          // Members section
          Text(
            'الأعضاء',
            style: AppTypography.titleMedium.copyWith(
              color: themeColors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          membersAsync.when(
            data: (members) => _buildMembersList(themeColors, members),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: PremiumLoadingIndicator(),
              ),
            ),
            error: (error, _) => GlassCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'حدث خطأ في تحميل الأعضاء',
                style: AppTypography.bodyMedium.copyWith(
                  color: themeColors.onSurface,
                ),
                textAlign: TextAlign.center,
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
        ],
      ),
    );
  }

  Widget _buildMembersList(
    ThemeColors themeColors,
    List<FamilyGroupMember> members,
  ) {
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
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: GlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: AppSpacing.avatarSm / 2,
                  backgroundColor: themeColors.primary.withValues(alpha: 0.2),
                  child: Icon(
                    Icons.person_rounded,
                    size: AppSpacing.iconSm,
                    color: themeColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Member info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.userId,
                        style: AppTypography.bodyMedium.copyWith(
                          color: themeColors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
                      color: themeColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      'مسؤول',
                      style: AppTypography.labelSmall.copyWith(
                        color: themeColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
