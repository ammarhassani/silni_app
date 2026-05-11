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
    // the user is already at the cap, fail fast on this screen rather than
    // letting them traverse the identity-claim wizard only to hit a server
    // error at the end. Phase 3 will add a "leave one first" picker — for
    // now we surface the explanation and stay put.
    setState(() => _isJoining = true);
    try {
      final slots = await ref.read(myMembershipSlotsProvider.future);
      if (slots.memberSlotFull && mounted) {
        setState(() {
          _isJoining = false;
          _errorMessage =
              'أنت بالفعل في عائلتَين. غادر إحداهما قبل الانضمام لهذه.';
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
