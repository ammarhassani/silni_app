import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:silni_app/core/constants/app_spacing.dart';
import 'package:silni_app/core/constants/app_typography.dart';
import 'package:silni_app/core/router/app_routes.dart';
import 'package:silni_app/core/theme/theme_provider.dart';
import 'package:silni_app/features/family_groups/models/node_claim_model.dart';
import 'package:silni_app/features/family_groups/providers/node_claim_providers.dart';
import 'package:silni_app/shared/widgets/glass_card.dart';

/// Surfaces the admin's pending-claim queue inside the family-group
/// screen. Hidden when there are no pending claims (no empty card).
class PendingClaimsCard extends ConsumerWidget {
  final String groupId;
  const PendingClaimsCard({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final claimsAsync = ref.watch(groupPendingClaimsProvider(groupId));

    return claimsAsync.when(
      data: (claims) {
        if (claims.isEmpty) return const SizedBox.shrink();
        return GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: themeColors.accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_active_rounded,
                      color: themeColors.accent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'طلبات تأكيد معلقة (${claims.length})',
                      style: AppTypography.titleMedium.copyWith(
                        color: themeColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ...claims.map((c) => _ClaimTile(claim: c)),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _ClaimTile extends ConsumerWidget {
  final NodeClaim claim;
  const _ClaimTile({required this.claim});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final claimantName =
        claim.claimantName ?? claim.proposedFullName ?? 'مستخدم';
    final roleSummary = _summary(claim);

    return InkWell(
      onTap: () =>
          context.push('${AppRoutes.reviewClaim}/${claim.id}'),
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.xs,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor:
                  themeColors.onSurface.withValues(alpha: 0.1),
              child: Text(
                claimantName.isNotEmpty
                    ? claimantName.characters.first
                    : '?',
                style: TextStyle(color: themeColors.onSurface),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    claimantName,
                    style: AppTypography.bodyLarge.copyWith(
                      color: themeColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    roleSummary,
                    style: AppTypography.bodySmall.copyWith(
                      color:
                          themeColors.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_left_rounded,
                color: themeColors.onSurface.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  static String _summary(NodeClaim c) {
    final anchor = c.declaredAnchorName ?? 'فرد';
    final role = _roleLabel(
      c.declaredEdgePath,
      c.declaredParentSide,
      c.declaredGender,
    );
    return 'يقول إنه $role $anchor';
  }

  static String _roleLabel(String edgePath, String? parentSide, String gender) {
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
}
