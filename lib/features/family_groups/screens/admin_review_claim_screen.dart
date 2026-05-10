import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:silni_app/core/constants/app_spacing.dart';
import 'package:silni_app/core/constants/app_typography.dart';
import 'package:silni_app/core/theme/app_themes.dart';
import 'package:silni_app/core/theme/theme_provider.dart';
import 'package:silni_app/features/family_groups/models/node_claim_model.dart';
import 'package:silni_app/features/family_groups/providers/node_claim_providers.dart';
import 'package:silni_app/features/family_groups/services/family_sharing_service.dart';
import 'package:silni_app/features/family_groups/services/node_claim_service.dart';
import 'package:silni_app/features/family_tree/providers/family_graph_providers.dart';
import 'package:silni_app/shared/utils/ui_helpers.dart';
import 'package:silni_app/shared/widgets/glass_card.dart';
import 'package:silni_app/shared/widgets/gradient_background.dart';
import 'package:silni_app/shared/widgets/gradient_button.dart';

/// The admin's trust gate. Surfaces a single pending claim with enough
/// context to verify in one glance, then approve / reject / snooze.
///
/// Reachable from:
///   1. Push notification ("X يقول إنه عمك") — direct deep link.
///   2. Family-group screen "الدعوات" badge → claim list → tap.
///   3. Inline tree node with pulsing orange ring (Phase 4).
class AdminReviewClaimScreen extends ConsumerStatefulWidget {
  final String claimId;
  const AdminReviewClaimScreen({super.key, required this.claimId});

  @override
  ConsumerState<AdminReviewClaimScreen> createState() =>
      _AdminReviewClaimScreenState();
}

class _AdminReviewClaimScreenState
    extends ConsumerState<AdminReviewClaimScreen> {
  bool _isWorking = false;
  NodeClaim? _claim;

  @override
  void initState() {
    super.initState();
    _loadClaim();
  }

  Future<void> _loadClaim() async {
    // The current API only exposes a list of pending claims per group;
    // we look up by ID by scanning the joiner's "my pending" view first
    // (works for self-cancellation flow) and falling back to the group
    // queue via Riverpod when admin opens this from a notification.
    // For v1, we accept that the screen needs a groupId override or an
    // initial round-trip. The route is reached in two ways:
    //   - admin queue → already has claim in memory (could pass via extra)
    //   - push notification → only has claim_id
    // We resolve via a query on node_claims directly with RLS handling.
    try {
      final svc = ref.read(nodeClaimServiceProvider);
      // Try: it's one of MY pending claims (joiner-self-cancel path).
      final mine = await svc.getMyPendingClaims();
      final found = mine.where((c) => c.id == widget.claimId).toList();
      if (found.isNotEmpty) {
        if (mounted) setState(() => _claim = found.first);
        return;
      }
    } catch (_) {/* fall through */}

    // Otherwise: fetch via group queue. Need to know the group_id; without
    // it we can't query. For now show an error and let the caller pass
    // groupId via extra. Most production callers should use the admin
    // queue (which provides the full claim object via Riverpod) — this
    // direct-load fallback exists only for notification deep links.
    if (mounted) {
      UIHelpers.showSnackBar(
        context,
        'تعذّر تحميل الطلب — افتحه من قائمة الدعوات',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);
    final claim = _claim;
    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(animated: true, child: SizedBox.expand()),
          SafeArea(
            child: claim == null
                ? Center(
                    child: CircularProgressIndicator(
                        color: themeColors.onSurface),
                  )
                : _buildContent(themeColors, claim),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeColors themeColors, NodeClaim claim) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded,
                color: themeColors.onSurface),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'مراجعة طلب',
            style: AppTypography.titleLarge.copyWith(
              color: themeColors.onSurface,
            ),
          ),
          centerTitle: true,
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.md),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildClaimSentence(themeColors, claim),
              const SizedBox(height: AppSpacing.md),
              _buildPlacementContext(themeColors, claim),
              const SizedBox(height: AppSpacing.md),
              _buildClaimantProfile(themeColors, claim),
              const SizedBox(height: AppSpacing.xl),
              _buildActions(themeColors, claim),
            ]),
          ),
        ),
      ],
    );
  }

  // -------- Claim sentence (top: "X يدّعي أنه عمك")

  Widget _buildClaimSentence(ThemeColors themeColors, NodeClaim claim) {
    final claimantDisplay = claim.claimantName ??
        claim.proposedFullName ??
        'مستخدم';
    final roleLabel = _arabicRoleLabel(
      claim.declaredEdgePath,
      claim.declaredParentSide,
      claim.declaredGender,
    );
    final anchorName = claim.declaredAnchorName ?? 'فرد العائلة';

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Icon(Icons.help_outline_rounded,
              size: AppSpacing.iconXl, color: themeColors.onSurface),
          const SizedBox(height: AppSpacing.md),
          Text(
            '$claimantDisplay يقول إنه $roleLabel $anchorName',
            style: AppTypography.titleLarge.copyWith(
              color: themeColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // -------- Placement context (middle: where they'd land + claimed-vs-add-me)

  Widget _buildPlacementContext(ThemeColors themeColors, NodeClaim claim) {
    final isAddMe = claim.claimedRelativeId == null;
    final claimedName = claim.claimedRelativeName;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAddMe
                    ? Icons.person_add_alt_1_rounded
                    : Icons.person_pin_circle_rounded,
                color: themeColors.accent,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                isAddMe ? 'إضافة شخص جديد للشجرة' : 'مطالبة بعقدة موجودة',
                style: AppTypography.titleMedium.copyWith(
                  color: themeColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (!isAddMe && claimedName != null)
            Text(
              'يطالب أن يكون: $claimedName',
              style: AppTypography.bodyLarge.copyWith(
                color: themeColors.onSurface.withValues(alpha: 0.85),
              ),
            )
          else
            Text(
              'سيُنشأ هذا الشخص كعقدة جديدة في الشجرة عند التأكيد',
              style: AppTypography.bodyMedium.copyWith(
                color: themeColors.onSurface.withValues(alpha: 0.7),
              ),
            ),
        ],
      ),
    );
  }

  // -------- Claimant profile (signed-up details)

  Widget _buildClaimantProfile(ThemeColors themeColors, NodeClaim claim) {
    final fullName = claim.claimantName ??
        claim.proposedFullName ??
        'مستخدم';
    final birth = claim.proposedBirthYear?.toString();
    final city = claim.proposedCity;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'بيانات صاحب الطلب',
            style: AppTypography.titleSmall.copyWith(
              color: themeColors.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _profileRow(themeColors, Icons.person_outline_rounded, fullName),
          if (birth != null)
            _profileRow(
                themeColors, Icons.cake_outlined, 'سنة الميلاد: $birth'),
          if (city != null && city.isNotEmpty)
            _profileRow(themeColors, Icons.location_on_outlined, city),
        ],
      ),
    );
  }

  Widget _profileRow(ThemeColors themeColors, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: themeColors.onSurface.withValues(alpha: 0.7)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyLarge.copyWith(
                color: themeColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------- Action bar (bottom)

  Widget _buildActions(ThemeColors themeColors, NodeClaim claim) {
    return Column(
      children: [
        GradientButton(
          text: 'تأكيد',
          onPressed: () => _approve(claim),
          icon: Icons.check_circle_rounded,
          isLoading: _isWorking,
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: _isWorking ? null : () => _showRejectSheet(claim),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            side: BorderSide(
                color: themeColors.onSurface.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
          ),
          icon: Icon(Icons.cancel_outlined, color: themeColors.onSurface),
          label: Text(
            'رفض',
            style: AppTypography.bodyLarge.copyWith(
              color: themeColors.onSurface,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextButton.icon(
          onPressed: _isWorking ? null : () => _snooze(claim),
          icon: Icon(Icons.schedule_rounded,
              color: themeColors.onSurface.withValues(alpha: 0.6)),
          label: Text(
            'لاحقاً (تأجيل 24 ساعة)',
            style: AppTypography.bodyMedium.copyWith(
              color: themeColors.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }

  // -------- Actions

  Future<void> _approve(NodeClaim claim) async {
    setState(() => _isWorking = true);
    try {
      final svc = ref.read(nodeClaimServiceProvider);
      final result = await svc.approveClaim(claim.id);

      // Re-materialize edges for the (possibly newly created) node.
      // Wrapped in try/catch — best-effort, the claim is already approved.
      try {
        await FamilySharingService.verifySharedEdges(groupId: claim.groupId);
      } catch (_) {}

      if (mounted) {
        ref.invalidate(groupPendingClaimsProvider(claim.groupId));
        ref.invalidate(groupRelativesStreamProvider(claim.groupId));
        ref.invalidate(sharedFamilyEdgesStreamProvider(claim.groupId));
        HapticFeedback.heavyImpact();
        UIHelpers.showSnackBar(
          context,
          result.createdNewNode
              ? 'تم تأكيد الطلب وإضافة الشخص للشجرة'
              : 'تم تأكيد الطلب',
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isWorking = false);
        UIHelpers.showSnackBar(
            context, 'تعذّر تأكيد الطلب: $e', isError: true);
      }
    }
  }

  Future<void> _showRejectSheet(NodeClaim claim) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  'لماذا الرفض؟',
                  style: AppTypography.titleLarge
                      .copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.error_outline,
                    color: Colors.white),
                title: const Text('خطأ في القرابة',
                    style: TextStyle(color: Colors.white)),
                onTap: () =>
                    Navigator.pop(ctx, ClaimRejectionReason.wrongRelationship),
              ),
              ListTile(
                leading: const Icon(Icons.person_off_outlined,
                    color: Colors.white),
                title: const Text('لا أعرف هذا الشخص',
                    style: TextStyle(color: Colors.white)),
                onTap: () =>
                    Navigator.pop(ctx, ClaimRejectionReason.unknownPerson),
              ),
              ListTile(
                leading:
                    const Icon(Icons.more_horiz, color: Colors.white),
                title: const Text('سبب آخر',
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, ClaimRejectionReason.other),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء',
                    style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
    if (reason == null) return;

    setState(() => _isWorking = true);
    try {
      final svc = ref.read(nodeClaimServiceProvider);
      await svc.rejectClaim(claimId: claim.id, reason: reason);
      if (mounted) {
        ref.invalidate(groupPendingClaimsProvider(claim.groupId));
        HapticFeedback.mediumImpact();
        UIHelpers.showSnackBar(context, 'تم رفض الطلب');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isWorking = false);
        UIHelpers.showSnackBar(
            context, 'تعذّر رفض الطلب: $e', isError: true);
      }
    }
  }

  Future<void> _snooze(NodeClaim claim) async {
    setState(() => _isWorking = true);
    try {
      final svc = ref.read(nodeClaimServiceProvider);
      await svc.snoozeClaim(
        claimId: claim.id,
        until: DateTime.now().add(const Duration(hours: 24)),
      );
      if (mounted) {
        ref.invalidate(groupPendingClaimsProvider(claim.groupId));
        UIHelpers.showSnackBar(context, 'تم تأجيل الطلب 24 ساعة');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isWorking = false);
        UIHelpers.showSnackBar(
            context, 'تعذّر تأجيل الطلب: $e', isError: true);
      }
    }
  }
}

// Maps the canonical (edge_path, parent_side, gender) tuple to a single
// Arabic kinship label. Mirrors the seed data in
// admin_relationship_labels (see migration 20260204130000_family_sharing.sql).
String _arabicRoleLabel(String edgePath, String? parentSide, String gender) {
  switch (edgePath) {
    case 'parent':
      return gender == 'male' ? 'أب' : 'أم';
    case 'child':
      return gender == 'male' ? 'ابن' : 'ابنة';
    case 'sibling':
      return gender == 'male' ? 'أخ' : 'أخت';
    case 'spouse':
      return gender == 'male' ? 'زوج' : 'زوجة';
    case 'uncle_aunt':
      if (parentSide == 'paternal') {
        return gender == 'male' ? 'عم' : 'عمة';
      }
      return gender == 'male' ? 'خال' : 'خالة';
    case 'grandparent':
      if (parentSide == 'paternal') {
        return gender == 'male' ? 'جد لأب' : 'جدة لأب';
      }
      return gender == 'male' ? 'جد لأم' : 'جدة لأم';
    case 'grandchild':
      return gender == 'male' ? 'حفيد' : 'حفيدة';
    case 'cousin':
      if (parentSide == 'paternal') {
        return gender == 'male' ? 'ابن عم/عمة' : 'بنت عم/عمة';
      }
      return gender == 'male' ? 'ابن خال/خالة' : 'بنت خال/خالة';
    case 'nephew_niece':
      return gender == 'male' ? 'ابن أخ/أخت' : 'بنت أخ/أخت';
    default:
      return 'قريب';
  }
}
