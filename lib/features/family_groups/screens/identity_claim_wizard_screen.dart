import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:silni_app/core/config/supabase_config.dart';
import 'package:silni_app/core/constants/app_spacing.dart';
import 'package:silni_app/core/constants/app_typography.dart';
import 'package:silni_app/core/router/app_routes.dart';
import 'package:silni_app/core/theme/app_themes.dart';
import 'package:silni_app/core/theme/theme_provider.dart';
import 'package:silni_app/features/family_groups/models/candidate_relative_model.dart';
import 'package:silni_app/features/family_groups/providers/node_claim_providers.dart';
import 'package:silni_app/features/family_groups/services/node_claim_service.dart';
import 'package:silni_app/shared/utils/ui_helpers.dart';
import 'package:silni_app/shared/widgets/glass_card.dart';
import 'package:silni_app/shared/widgets/gradient_background.dart';
import 'package:silni_app/shared/widgets/gradient_button.dart';

/// 5-step joiner journey to claim an identity in the shared family tree.
///
/// 1. Anchor: "Are you a relative of [admin]?" Yes / No-and-pick-someone-else.
/// 2. Category: pick relationship-class (parent/child/sibling/spouse,
///    older generation, grandparent generation, cousin, etc).
/// 3. Role: pick the specific kinship term within the category. Maps to
///    the (edge_path, parent_side, gender) taxonomy.
/// 4. Candidates: app shows tree members matching the declared role.
///    Joiner taps to claim or "ما أحد منهم أنا — أضِفني للشجرة" to add self.
/// 5. Add-me form: only when no candidates or joiner picks add-me.
///    Pre-filled with auth name + declared gender.
///
/// On submit, creates a node_claim record. Joiner lands on the family tree
/// with a pending banner until admin acts.
class IdentityClaimWizardScreen extends ConsumerStatefulWidget {
  final String groupId;
  const IdentityClaimWizardScreen({super.key, required this.groupId});

  @override
  ConsumerState<IdentityClaimWizardScreen> createState() =>
      _IdentityClaimWizardScreenState();
}

class _IdentityClaimWizardScreenState
    extends ConsumerState<IdentityClaimWizardScreen> {
  final _pageController = PageController();
  int _step = 0;

  // Step 1 state
  String? _adminName;
  String? _adminRelativeId;
  String? _groupName;
  // The chosen anchor for the claim (defaults to admin's relative_id_in_tree).
  String? _anchorRelativeId;
  String? _anchorName;
  // Tree members for the anchor switcher.
  List<_TreeMember> _treeMembers = const [];
  // Set when _bootstrapAdminAndTree throws — anchor step renders an error
  // card with retry instead of an indefinite spinner.
  String? _bootstrapError;

  // Step 2/3 state — the declared role.
  _RoleCategory? _category;
  _ClaimRole? _role;

  // Step 4 state — fetched candidates.
  List<CandidateRelative> _candidates = const [];
  bool _candidatesLoading = false;
  String? _candidatesError;
  String? _selectedCandidateId;

  // Step 5 state — add-me form.
  final _addMeFormKey = GlobalKey<FormState>();
  final _proposedNameController = TextEditingController();
  final _proposedCityController = TextEditingController();
  final _proposedPhoneController = TextEditingController();
  int? _proposedBirthYear;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _bootstrapAdminAndTree();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _proposedNameController.dispose();
    _proposedCityController.dispose();
    _proposedPhoneController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------- Bootstrap

  Future<void> _bootstrapAdminAndTree() async {
    // Fetch the admin's name + relative_id_in_tree, and the full list of
    // tree members (for the anchor switcher). One round trip if possible.
    //
    // Wrapped in try/catch so a runtime error here doesn't leave the wizard
    // sitting on the anchor-step spinner forever — surface the failure to
    // the user instead.
    debugPrint('[IdentityClaimWizard] bootstrap → group=${widget.groupId}');
    try {
      final client = SupabaseConfig.client;

      // Single SECURITY DEFINER RPC that returns group + admin info.
      // Using the RPC (instead of two direct queries) because the
      // public.users RLS only lets a user read their OWN profile, so the
      // joiner can't directly read the admin's name. The RPC pulls the
      // admin's display name from auth.users.raw_user_meta_data.
      final anchorInfo = await client
          .rpc('get_group_anchor_info', params: {
            'p_group_id': widget.groupId,
          })
          .timeout(const Duration(seconds: 10));

      final info = anchorInfo as Map<String, dynamic>;
      final String adminName = info['admin_name'] as String;
      final String? adminTreeId = info['admin_relative_id'] as String?;
      final String groupName = info['group_name'] as String;

      final relativesData = await client
          .from('relatives')
          .select('id, full_name, gender, family_side')
          .eq('family_group_id', widget.groupId)
          .eq('is_archived', false)
          .order('full_name', ascending: true);

      final treeMembers = (relativesData as List)
          .cast<Map<String, dynamic>>()
          .map((r) => _TreeMember(
                id: r['id'] as String,
                name: r['full_name'] as String,
                gender: r['gender'] as String?,
              ))
          .toList();

      debugPrint(
        '[IdentityClaimWizard] bootstrap ✓ group=$groupName admin=$adminName '
        'adminTreeId=$adminTreeId members=${treeMembers.length}',
      );

      if (mounted) {
        setState(() {
          _groupName = groupName;
          _adminName = adminName;
          _adminRelativeId = adminTreeId;
          _anchorRelativeId = adminTreeId;
          _anchorName = adminName;
          _treeMembers = treeMembers;
          _bootstrapError = null;
        });
      }
    } catch (e, st) {
      debugPrint('[IdentityClaimWizard] bootstrap ✗ $e\n$st');
      if (mounted) {
        setState(() => _bootstrapError = e.toString());
      }
    }
  }

  // ------------------------------------------------------------------ Steps

  void _goTo(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _previous() {
    if (_step > 0) _goTo(_step - 1);
  }

  Future<void> _onCategoryPicked(_RoleCategory category) async {
    setState(() => _category = category);
    HapticFeedback.lightImpact();
    _goTo(2);
  }

  Future<void> _onRolePicked(_ClaimRole role) async {
    setState(() {
      _role = role;
      _candidates = const [];
      _candidatesLoading = true;
      _candidatesError = null;
      _selectedCandidateId = null;
    });
    HapticFeedback.lightImpact();
    _goTo(3);

    // Fetch candidates.
    if (_anchorRelativeId == null) {
      setState(() {
        _candidatesLoading = false;
        _candidatesError = 'Anchor not resolved (admin has no tree node yet).';
      });
      return;
    }

    try {
      final svc = ref.read(nodeClaimServiceProvider);
      final list = await svc.findCandidates(
        groupId: widget.groupId,
        anchorRelativeId: _anchorRelativeId!,
        edgePath: role.edgePath,
        parentSide: role.parentSide,
        gender: role.gender,
      );
      if (mounted) {
        setState(() {
          _candidates = list;
          _candidatesLoading = false;
          _candidatesError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _candidatesLoading = false;
          _candidatesError = e.toString();
        });
        UIHelpers.showSnackBar(context, 'حدث خطأ في البحث: $e', isError: true);
      }
    }
  }

  // ------------------------------------------------------------- Submission

  Future<void> _submitExistingNodeClaim(CandidateRelative candidate) async {
    if (_role == null || _anchorRelativeId == null) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(nodeClaimServiceProvider).createClaim(
            groupId: widget.groupId,
            claimedRelativeId: candidate.id,
            anchorRelativeId: _anchorRelativeId!,
            edgePath: _role!.edgePath,
            parentSide: _role!.parentSide,
            gender: _role!.gender,
          );
      if (mounted) {
        ref.invalidate(myPendingClaimsProvider);
        HapticFeedback.heavyImpact();
        _goToSubmittedScreen();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        UIHelpers.showSnackBar(context, 'تعذّر إرسال الطلب: $e', isError: true);
      }
    }
  }

  Future<void> _submitAddMeClaim() async {
    if (!(_addMeFormKey.currentState?.validate() ?? false)) return;
    if (_role == null || _anchorRelativeId == null) return;

    // Add-me path is constrained to direct relationships (parent/child/spouse/
    // sibling) by the RPC. Guard here too for clearer UX.
    if (!const {'parent', 'child', 'spouse', 'sibling'}
        .contains(_role!.edgePath)) {
      UIHelpers.showSnackBar(
        context,
        'الإضافة الذاتية متاحة للقرابة المباشرة فقط — اطلب من المسؤول إضافتك',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(nodeClaimServiceProvider).createClaim(
            groupId: widget.groupId,
            anchorRelativeId: _anchorRelativeId!,
            edgePath: _role!.edgePath,
            parentSide: _role!.parentSide,
            gender: _role!.gender,
            proposedFullName: _proposedNameController.text.trim(),
            proposedPhoneNumber: _proposedPhoneController.text.trim().isEmpty
                ? null
                : _proposedPhoneController.text.trim(),
            proposedGender: _role!.gender,
            proposedBirthYear: _proposedBirthYear,
            proposedCity: _proposedCityController.text.trim().isEmpty
                ? null
                : _proposedCityController.text.trim(),
          );
      if (mounted) {
        ref.invalidate(myPendingClaimsProvider);
        HapticFeedback.heavyImpact();
        _goToSubmittedScreen();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        UIHelpers.showSnackBar(context, 'تعذّر إرسال الطلب: $e', isError: true);
      }
    }
  }

  void _goToSubmittedScreen() {
    // Navigate to family tree; the pending banner will surface there.
    context.go(AppRoutes.familyTree);
  }

  // ----------------------------------------------------------------- Build

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
                _buildHeader(themeColors),
                _buildStepIndicator(themeColors),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildAnchorStep(themeColors),
                      _buildCategoryStep(themeColors),
                      _buildRoleStep(themeColors),
                      _buildCandidatesStep(themeColors),
                      _buildAddMeStep(themeColors),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeColors themeColors) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        left: AppSpacing.md,
        right: AppSpacing.md,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            IconButton(
              onPressed: _step > 0 ? _previous : null,
              icon: Icon(Icons.arrow_back_ios_rounded,
                  color: themeColors.onSurface),
            ),
            Expanded(
              child: Text(
                'تأكيد مكانك في الشجرة',
                style: AppTypography.titleLarge.copyWith(
                  color: themeColors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: AppSpacing.iconXl),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(ThemeColors themeColors) {
    final activeSteps = _step >= 4 ? 5 : 4;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: List.generate(activeSteps, (i) {
          final isActive = i <= _step;
          return Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: i == 0 || i == activeSteps - 1 ? 0 : AppSpacing.xs,
              ),
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: isActive
                    ? themeColors.onSurface
                    : themeColors.onSurface.withValues(alpha: 0.2),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ----- Step 0: Anchor question

  Widget _buildAnchorStep(ThemeColors themeColors) {
    if (_bootstrapError != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: GlassCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: AppSpacing.iconXl, color: themeColors.onSurface),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'تعذّر تحميل بيانات المجموعة',
                  style: AppTypography.titleMedium
                      .copyWith(color: themeColors.onSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                SelectableText(
                  _bootstrapError!,
                  style: AppTypography.bodySmall.copyWith(
                    color: themeColors.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _bootstrapError = null);
                    _bootstrapAdminAndTree();
                  },
                  icon: Icon(Icons.refresh_rounded,
                      color: themeColors.onSurface),
                  label: Text('إعادة المحاولة',
                      style: AppTypography.bodyLarge
                          .copyWith(color: themeColors.onSurface)),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_adminName == null) {
      return Center(
        child: CircularProgressIndicator(color: themeColors.onSurface),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          // Group name banner — orienting context for the joiner who may
          // not know who the group's "admin" is by name.
          if (_groupName != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: themeColors.onSurface.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppSpacing.lg),
                border: Border.all(
                  color: themeColors.onSurface.withValues(alpha: 0.20),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.family_restroom_rounded,
                      size: 18, color: themeColors.onSurface),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      _groupName!,
                      style: AppTypography.titleSmall.copyWith(
                        color: themeColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Icon(Icons.account_tree_rounded,
              size: AppSpacing.iconXxl, color: themeColors.onSurface),
          const SizedBox(height: AppSpacing.md),
          Text(
            'كيف تنتمي لهذه العائلة؟',
            style: AppTypography.headlineSmall.copyWith(
              color: themeColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'أرسل لك $_adminName هذه الدعوة. سنحتاج لمعرفة كيف تنتمي للعائلة '
            'لنضعك في المكان الصحيح في الشجرة.',
            style: AppTypography.bodyLarge.copyWith(
              color: themeColors.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          GradientButton(
            text: 'أنا قريب لـ $_adminName',
            onPressed: () {
              // Anchor stays on admin (default).
              setState(() {
                _anchorRelativeId = _adminRelativeId;
                _anchorName = _adminName;
              });
              _goTo(1);
            },
            icon: Icons.check_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: _treeMembers.isEmpty ? null : _showAnchorPicker,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              side: BorderSide(color: themeColors.onSurface.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
            ),
            icon: Icon(Icons.people_outline_rounded, color: themeColors.onSurface),
            label: Text(
              'أنا قريب لشخص آخر في العائلة',
              style: AppTypography.bodyLarge.copyWith(
                color: themeColors.onSurface,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'إذا لم تكن تعرف $_adminName شخصياً، اضغط هنا واختر شخصاً تعرفه من العائلة',
            style: AppTypography.bodySmall.copyWith(
              color: themeColors.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _showAnchorPicker() async {
    final picked = await showModalBottomSheet<_TreeMember>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AnchorPickerSheet(members: _treeMembers),
    );
    if (picked != null && mounted) {
      setState(() {
        _anchorRelativeId = picked.id;
        _anchorName = picked.name;
      });
      _goTo(1);
    }
  }

  // ----- Step 1: Category

  Widget _buildCategoryStep(ThemeColors themeColors) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ما صلة قرابتك بـ ${_anchorName ?? "..."}؟',
            style: AppTypography.titleLarge.copyWith(
              color: themeColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: _RoleCategory.values.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (ctx, i) {
                final c = _RoleCategory.values[i];
                return _CategoryTile(
                  category: c,
                  themeColors: themeColors,
                  onTap: () => _onCategoryPicked(c),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ----- Step 2: Specific role

  Widget _buildRoleStep(ThemeColors themeColors) {
    final cat = _category;
    if (cat == null) {
      return const SizedBox.shrink();
    }
    final roles = cat.roles;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            cat.label,
            style: AppTypography.titleLarge.copyWith(
              color: themeColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'اختر القرابة المحددة',
            style: AppTypography.bodyMedium.copyWith(
              color: themeColors.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 2.4,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              children: roles
                  .map((r) => _RoleButton(
                        role: r,
                        themeColors: themeColors,
                        onTap: () => _onRolePicked(r),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ----- Step 3: Candidates

  Widget _buildCandidatesStep(ThemeColors themeColors) {
    if (_role == null) return const SizedBox.shrink();

    if (_candidatesLoading) {
      return Center(
          child: CircularProgressIndicator(color: themeColors.onSurface));
    }

    if (_candidatesError != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: GlassCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: AppSpacing.iconXl, color: themeColors.onSurface),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'تعذّر جلب المرشحين',
                  style: AppTypography.titleMedium
                      .copyWith(color: themeColors.onSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                SelectableText(
                  _candidatesError!,
                  style: AppTypography.bodySmall.copyWith(
                    color: themeColors.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton.icon(
                  onPressed: () {
                    final r = _role;
                    if (r != null) _onRolePicked(r);
                  },
                  icon: Icon(Icons.refresh_rounded,
                      color: themeColors.onSurface),
                  label: Text('إعادة المحاولة',
                      style: AppTypography.bodyLarge
                          .copyWith(color: themeColors.onSurface)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isAddMeAllowed = const {'parent', 'child', 'spouse', 'sibling'}
        .contains(_role!.edgePath);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _candidates.isEmpty
                ? 'لم نجد أحداً مطابقاً'
                : 'اختر من تكون',
            style: AppTypography.titleLarge.copyWith(
              color: themeColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'القرابة المعلنة: ${_role!.label}',
            style: AppTypography.bodyMedium.copyWith(
              color: themeColors.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          if (_candidates.isEmpty)
            Expanded(
              child: Center(
                child: GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_search_rounded,
                          size: AppSpacing.iconXl,
                          color: themeColors.onSurface
                              .withValues(alpha: 0.5)),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        isAddMeAllowed
                            ? 'يمكنك إضافة نفسك للشجرة'
                            : 'اطلب من المسؤول إضافتك للشجرة',
                        style: AppTypography.bodyLarge.copyWith(
                          color: themeColors.onSurface
                              .withValues(alpha: 0.85),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: _candidates.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (ctx, i) {
                  final c = _candidates[i];
                  final selected = _selectedCandidateId == c.id;
                  return _CandidateRow(
                    candidate: c,
                    selected: selected,
                    themeColors: themeColors,
                    onTap: () =>
                        setState(() => _selectedCandidateId = c.id),
                    onConfirm: () => _submitExistingNodeClaim(c),
                  );
                },
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          if (isAddMeAllowed)
            TextButton.icon(
              onPressed: _isSubmitting
                  ? null
                  : () {
                      // Pre-fill name from auth metadata.
                      final user = SupabaseConfig.client.auth.currentUser;
                      final authName =
                          (user?.userMetadata?['full_name'] as String?) ?? '';
                      _proposedNameController.text = authName;
                      _goTo(4);
                    },
              icon: Icon(Icons.person_add_rounded,
                  color: themeColors.onSurface),
              label: Text(
                'ما أحد منهم أنا — أضِفني للشجرة',
                style: AppTypography.bodyLarge.copyWith(
                  color: themeColors.onSurface,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ----- Step 4: Add-me form

  Widget _buildAddMeStep(ThemeColors themeColors) {
    if (_role == null) return const SizedBox.shrink();
    final currentYear = DateTime.now().year;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Form(
        key: _addMeFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            Text(
              'أضِفني للشجرة',
              style: AppTypography.titleLarge.copyWith(
                color: themeColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'سأكون ${_role!.label} ${_anchorName ?? ""}',
              style: AppTypography.bodyMedium.copyWith(
                color: themeColors.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            GlassCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: TextFormField(
                controller: _proposedNameController,
                style: AppTypography.bodyLarge.copyWith(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'اسمك الكامل',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  prefixIcon: Icon(Icons.person_outline_rounded,
                      color: Colors.white.withValues(alpha: 0.7)),
                ),
                validator: (v) {
                  if (v == null || v.trim().length < 2) {
                    return 'يرجى إدخال اسمك';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: TextFormField(
                controller: _proposedPhoneController,
                keyboardType: TextInputType.phone,
                style: AppTypography.bodyLarge.copyWith(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'رقم الجوال (اختياري — يساعد المسؤول للتحقق)',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  prefixIcon: Icon(Icons.phone_outlined,
                      color: Colors.white.withValues(alpha: 0.7)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final cleaned = v.trim().replaceAll(RegExp(r'\s+'), '');
                  if (cleaned.length < 7 || cleaned.length > 16) {
                    return 'رقم الجوال غير صالح';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: TextFormField(
                controller: _proposedCityController,
                style: AppTypography.bodyLarge.copyWith(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'المدينة (اختياري)',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  prefixIcon: Icon(Icons.location_on_outlined,
                      color: Colors.white.withValues(alpha: 0.7)),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: TextFormField(
                keyboardType: TextInputType.number,
                style: AppTypography.bodyLarge.copyWith(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'سنة الميلاد (اختياري)',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  prefixIcon: Icon(Icons.cake_outlined,
                      color: Colors.white.withValues(alpha: 0.7)),
                ),
                onChanged: (v) {
                  final n = int.tryParse(v.trim());
                  if (n != null && n >= 1900 && n <= currentYear) {
                    _proposedBirthYear = n;
                  } else {
                    _proposedBirthYear = null;
                  }
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            GradientButton(
              text: 'إرسال الطلب',
              onPressed: _submitAddMeClaim,
              icon: Icons.send_rounded,
              isLoading: _isSubmitting,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Internal helpers
// ============================================================================

class _TreeMember {
  final String id;
  final String name;
  final String? gender;
  const _TreeMember(
      {required this.id, required this.name, required this.gender});
}

/// Categories shown in step 1 (relationship class). Each maps to a list of
/// specific [_ClaimRole]s shown in step 2.
enum _RoleCategory {
  household,
  olderGeneration,
  grandparentGeneration,
  cousins,
  youngerGeneration,
  grandchildGeneration,
}

extension _RoleCategoryX on _RoleCategory {
  String get label {
    switch (this) {
      case _RoleCategory.household:
        return 'من أهل البيت';
      case _RoleCategory.olderGeneration:
        return 'جيل أكبر (عم/خال)';
      case _RoleCategory.grandparentGeneration:
        return 'جيل الأجداد';
      case _RoleCategory.cousins:
        return 'ابن/بنت عم أو خال';
      case _RoleCategory.youngerGeneration:
        return 'ابن/بنت أخ أو أخت';
      case _RoleCategory.grandchildGeneration:
        return 'حفيد/حفيدة';
    }
  }

  IconData get icon {
    switch (this) {
      case _RoleCategory.household:
        return Icons.home_rounded;
      case _RoleCategory.olderGeneration:
        return Icons.elderly_rounded;
      case _RoleCategory.grandparentGeneration:
        return Icons.history_edu_rounded;
      case _RoleCategory.cousins:
        return Icons.people_alt_rounded;
      case _RoleCategory.youngerGeneration:
        return Icons.child_care_rounded;
      case _RoleCategory.grandchildGeneration:
        return Icons.child_friendly_rounded;
    }
  }

  List<_ClaimRole> get roles {
    switch (this) {
      case _RoleCategory.household:
        return const [
          _ClaimRole('أب', 'parent', null, 'male'),
          _ClaimRole('أم', 'parent', null, 'female'),
          _ClaimRole('ابن', 'child', null, 'male'),
          _ClaimRole('ابنة', 'child', null, 'female'),
          _ClaimRole('أخ', 'sibling', null, 'male'),
          _ClaimRole('أخت', 'sibling', null, 'female'),
          _ClaimRole('زوج', 'spouse', null, 'male'),
          _ClaimRole('زوجة', 'spouse', null, 'female'),
        ];
      case _RoleCategory.olderGeneration:
        return const [
          _ClaimRole('عم', 'uncle_aunt', 'paternal', 'male'),
          _ClaimRole('عمة', 'uncle_aunt', 'paternal', 'female'),
          _ClaimRole('خال', 'uncle_aunt', 'maternal', 'male'),
          _ClaimRole('خالة', 'uncle_aunt', 'maternal', 'female'),
        ];
      case _RoleCategory.grandparentGeneration:
        return const [
          _ClaimRole('جد لأب', 'grandparent', 'paternal', 'male'),
          _ClaimRole('جدة لأب', 'grandparent', 'paternal', 'female'),
          _ClaimRole('جد لأم', 'grandparent', 'maternal', 'male'),
          _ClaimRole('جدة لأم', 'grandparent', 'maternal', 'female'),
        ];
      case _RoleCategory.cousins:
        return const [
          _ClaimRole('ابن عم/عمة', 'cousin', 'paternal', 'male'),
          _ClaimRole('بنت عم/عمة', 'cousin', 'paternal', 'female'),
          _ClaimRole('ابن خال/خالة', 'cousin', 'maternal', 'male'),
          _ClaimRole('بنت خال/خالة', 'cousin', 'maternal', 'female'),
        ];
      case _RoleCategory.youngerGeneration:
        return const [
          _ClaimRole('ابن أخ/أخت', 'nephew_niece', null, 'male'),
          _ClaimRole('بنت أخ/أخت', 'nephew_niece', null, 'female'),
        ];
      case _RoleCategory.grandchildGeneration:
        return const [
          _ClaimRole('حفيد', 'grandchild', null, 'male'),
          _ClaimRole('حفيدة', 'grandchild', null, 'female'),
        ];
    }
  }
}

class _ClaimRole {
  final String label;
  final String edgePath;
  final String? parentSide;
  final String gender;
  const _ClaimRole(this.label, this.edgePath, this.parentSide, this.gender);
}

class _CategoryTile extends StatelessWidget {
  final _RoleCategory category;
  final ThemeColors themeColors;
  final VoidCallback onTap;
  const _CategoryTile({
    required this.category,
    required this.themeColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.md),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(category.icon, color: themeColors.onSurface),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                category.label,
                style: AppTypography.bodyLarge.copyWith(
                  color: themeColors.onSurface,
                ),
              ),
            ),
            Icon(Icons.chevron_left_rounded,
                color: themeColors.onSurface.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final _ClaimRole role;
  final ThemeColors themeColors;
  final VoidCallback onTap;
  const _RoleButton({
    required this.role,
    required this.themeColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Center(
          child: Text(
            role.label,
            style: AppTypography.bodyLarge.copyWith(
              color: themeColors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _CandidateRow extends StatelessWidget {
  final CandidateRelative candidate;
  final bool selected;
  final ThemeColors themeColors;
  final VoidCallback onTap;
  final VoidCallback onConfirm;
  const _CandidateRow({
    required this.candidate,
    required this.selected,
    required this.themeColors,
    required this.onTap,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.md),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      themeColors.onSurface.withValues(alpha: 0.1),
                  child: Text(
                    candidate.fullName.isNotEmpty
                        ? candidate.fullName.characters.first
                        : '?',
                    style: AppTypography.titleMedium
                        .copyWith(color: themeColors.onSurface),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate.fullName,
                        style: AppTypography.bodyLarge.copyWith(
                          color: themeColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (candidate.parentFullName != null)
                        Text(
                          'ابن/ابنة ${candidate.parentFullName}',
                          style: AppTypography.bodySmall.copyWith(
                            color: themeColors.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected
                      ? themeColors.accent
                      : themeColors.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
            if (selected) ...[
              const SizedBox(height: AppSpacing.md),
              GradientButton(
                text: 'هذا أنا — أرسل الطلب',
                onPressed: onConfirm,
                icon: Icons.send_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnchorPickerSheet extends StatefulWidget {
  final List<_TreeMember> members;
  const _AnchorPickerSheet({required this.members});

  @override
  State<_AnchorPickerSheet> createState() => _AnchorPickerSheetState();
}

class _AnchorPickerSheetState extends State<_AnchorPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.members
        : widget.members
            .where((m) =>
                m.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, sc) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'من تعرف في العائلة؟',
                style: AppTypography.titleLarge
                    .copyWith(color: Colors.white),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: TextField(
                controller: _searchController,
                style: AppTypography.bodyLarge
                    .copyWith(color: Colors.white),
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'بحث بالاسم',
                  hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5)),
                  prefixIcon: Icon(Icons.search,
                      color: Colors.white.withValues(alpha: 0.7)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: sc,
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final m = filtered[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Colors.white.withValues(alpha: 0.1),
                      child: Text(
                        m.name.isNotEmpty ? m.name.characters.first : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(m.name,
                        style: const TextStyle(color: Colors.white)),
                    onTap: () => Navigator.pop(context, m),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
