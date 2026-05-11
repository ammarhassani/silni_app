import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/premium_loading_indicator.dart';
import '../providers/node_claim_providers.dart';

/// Screen the joiner lands on after submitting an identity-claim.
///
/// Watches the claim row in realtime and re-renders as the admin
/// approves / rejects / cancels. On approval, auto-navigates the user
/// into the family tree after a short celebration delay so the success
/// state has time to read.
class ClaimPendingReviewScreen extends ConsumerStatefulWidget {
  final String claimId;

  const ClaimPendingReviewScreen({super.key, required this.claimId});

  @override
  ConsumerState<ClaimPendingReviewScreen> createState() =>
      _ClaimPendingReviewScreenState();
}

class _ClaimPendingReviewScreenState
    extends ConsumerState<ClaimPendingReviewScreen> {
  bool _approvalNavScheduled = false;

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);
    final claimAsync = ref.watch(claimByIdRealtimeProvider(widget.claimId));

    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(animated: true, child: SizedBox.expand()),
          SafeArea(
            child: claimAsync.when(
              loading: () => const Center(child: PremiumLoadingIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'تعذر تحميل الطلب: $e',
                    style: AppTypography.bodyLarge.copyWith(
                      color: themeColors.statusError,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (claim) {
                switch (claim.status) {
                  case 'approved':
                    _scheduleApprovedNav();
                    return _buildApproved(themeColors);
                  case 'rejected':
                    return _buildRejected(
                      themeColors,
                      claim.rejectionReason,
                    );
                  case 'cancelled':
                    return _buildCancelled(themeColors);
                  case 'pending':
                  default:
                    return _buildPending(themeColors);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _scheduleApprovedNav() {
    if (_approvalNavScheduled) return;
    _approvalNavScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted && context.mounted) {
          context.go(AppRoutes.familyTree);
        }
      });
    });
  }

  // ---------------------------------------------------------------------------
  // State views
  // ---------------------------------------------------------------------------

  Widget _buildPending(ThemeColors themeColors) {
    return _CenteredColumn(
      children: [
        Icon(
          Icons.hourglass_top_rounded,
          size: AppSpacing.iconXxl,
          color: themeColors.onSurface,
          semanticLabel: 'في الانتظار',
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'بانتظار موافقة المدير',
          style: AppTypography.headlineSmall.copyWith(
            color: themeColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'سنخبرك فور مراجعة طلبك. لا حاجة للبقاء على هذه الشاشة.',
          style: AppTypography.bodyMedium.copyWith(
            color: themeColors.onSurface.withValues(alpha: 0.8),
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

  Widget _buildApproved(ThemeColors themeColors) {
    return _CenteredColumn(
      children: [
        Icon(
          Icons.check_circle_rounded,
          size: AppSpacing.iconXxl,
          color: themeColors.statusSuccess,
          semanticLabel: 'تم القبول',
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'تم القبول!',
          style: AppTypography.headlineSmall.copyWith(
            color: themeColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'مرحباً بك في العائلة',
          style: AppTypography.bodyMedium.copyWith(
            color: themeColors.onSurface.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRejected(ThemeColors themeColors, String? rejectionReason) {
    final hasReason =
        rejectionReason != null && rejectionReason.trim().isNotEmpty;
    return _CenteredColumn(
      children: [
        Icon(
          Icons.cancel_rounded,
          size: AppSpacing.iconXxl,
          color: themeColors.statusError,
          semanticLabel: 'مرفوض',
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'لم يتم قبول طلبك',
          style: AppTypography.headlineSmall.copyWith(
            color: themeColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        if (hasReason) ...[
          const SizedBox(height: AppSpacing.md),
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              rejectionReason.trim(),
              style: AppTypography.bodyMedium.copyWith(
                color: themeColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        GradientButton(
          text: 'العودة للرئيسية',
          onPressed: () => context.go(AppRoutes.home),
          icon: Icons.home_rounded,
        ),
      ],
    );
  }

  Widget _buildCancelled(ThemeColors themeColors) {
    return _CenteredColumn(
      children: [
        Icon(
          Icons.do_disturb_alt_rounded,
          size: AppSpacing.iconXxl,
          color: themeColors.onSurface.withValues(alpha: 0.7),
          semanticLabel: 'ملغى',
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'تم إلغاء الطلب',
          style: AppTypography.headlineSmall.copyWith(
            color: themeColors.onSurface,
            fontWeight: FontWeight.w600,
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
}

/// Centers its children vertically and horizontally with a max width so
/// the page reads consistently across phone / tablet widths. Mirrors the
/// idiom used in join_group_screen.dart.
class _CenteredColumn extends StatelessWidget {
  final List<Widget> children;
  const _CenteredColumn({required this.children});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}
