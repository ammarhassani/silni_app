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
import '../../home/providers/home_providers.dart';
import '../models/family_group_model.dart';
import '../../family_tree/providers/family_graph_providers.dart';
import '../providers/family_group_providers.dart';
import '../services/family_group_service.dart';

/// Screen for joining a family group via invite code.
///
/// Accepts an invite code from the route parameter, looks up the group,
/// and provides a join button. Handles invalid codes, already-member,
/// and unauthenticated states.
class JoinGroupScreen extends ConsumerStatefulWidget {
  final String inviteCode;
  final String? targetRelativeId;

  const JoinGroupScreen({super.key, required this.inviteCode, this.targetRelativeId});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  FamilyGroup? _group;
  bool _isLoadingGroup = true;
  bool _isJoining = false;
  bool _alreadyMember = false;
  String? _errorMessage;

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
      // Redirect to login with redirect back to this page (preserve rid param)
      final ridParam = widget.targetRelativeId != null ? '?rid=${widget.targetRelativeId}' : '';
      final redirectPath = Uri.encodeComponent(
        '${AppRoutes.joinFamilyGroup}/${widget.inviteCode}$ridParam',
      );
      context.go('${AppRoutes.login}?redirect=$redirectPath');
      return;
    }

    setState(() => _isJoining = true);

    try {
      // Validate targetRelativeId format — pass null if invalid UUID
      final validRid = widget.targetRelativeId != null &&
              RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
                      caseSensitive: false)
                  .hasMatch(widget.targetRelativeId!)
          ? widget.targetRelativeId
          : null;

      final joinedGroup = await FamilyGroupService.joinGroup(
        inviteCode: widget.inviteCode,
        userId: user.id,
        relativeIdInTree: validRid,
      );

      if (mounted) {
        ref.invalidate(userFamilyGroupProvider);
        ref.invalidate(groupRelativesStreamProvider(joinedGroup.id));
        ref.invalidate(sharedFamilyEdgesStreamProvider(joinedGroup.id));
        ref.invalidate(groupMemberNodeIdsProvider(joinedGroup.id));
        ref.invalidate(userGroupsProvider(user.id));
        ref.invalidate(relativesStreamProvider(user.id));
        ref.invalidate(todayInteractionsStreamProvider(user.id));
        HapticFeedback.heavyImpact();
        context.go(AppRoutes.familyTree);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isJoining = false;
          _errorMessage = e.toString().contains('invite') || e.toString().contains('دعوة')
              ? 'رمز الدعوة غير صالح أو منتهي الصلاحية'
              : 'حدث خطأ أثناء الانضمام للمجموعة. يرجى المحاولة مرة أخرى';
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
                              : _buildGroupPreview(themeColors, user != null),
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
              final ridParam = widget.targetRelativeId != null ? '?rid=${widget.targetRelativeId}' : '';
              final redirectPath = Uri.encodeComponent(
                '${AppRoutes.joinFamilyGroup}/${widget.inviteCode}$ridParam',
              );
              context.go('${AppRoutes.login}?redirect=$redirectPath');
            },
            icon: Icons.login_rounded,
          ),
        ] else ...[
          GradientButton(
            text: 'انضم للمجموعة',
            onPressed: _joinGroup,
            isLoading: _isJoining,
            icon: Icons.group_add_rounded,
          ),
        ],
      ],
    );
  }
}
