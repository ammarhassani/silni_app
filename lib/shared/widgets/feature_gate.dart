import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/subscription_tier.dart';
import '../../core/providers/subscription_provider.dart';

/// Reusable widget for gating features behind subscription tiers
/// Wraps a child widget and shows locked UI when user doesn't have access
class FeatureGate extends ConsumerWidget {
  /// The feature ID to check access for
  final String featureId;

  /// The child widget to show when access is granted
  final Widget child;

  /// Optional custom widget to show when locked
  final Widget? lockedWidget;

  /// Callback when locked widget is tapped (e.g., show paywall)
  final VoidCallback? onLockedTap;

  /// The required tier for this feature (for display purposes)
  final SubscriptionTier requiredTier;

  /// Whether to show a subtle overlay instead of replacing the widget
  final bool useOverlay;

  const FeatureGate({
    super.key,
    required this.featureId,
    required this.child,
    this.lockedWidget,
    this.onLockedTap,
    this.requiredTier = SubscriptionTier.max,
    this.useOverlay = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAccess = ref.watch(featureAccessProvider(featureId));

    if (hasAccess) {
      return child;
    }

    if (useOverlay) {
      return _buildOverlayLocked(context);
    }

    if (lockedWidget != null) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onLockedTap?.call();
        },
        child: lockedWidget,
      );
    }

    return _buildDefaultLocked(context);
  }

  Widget _buildDefaultLocked(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onLockedTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: AppColors.premiumGold.withValues(alpha: 0.6),
            width: 2,
          ),
          boxShadow: [
            // Gold outer glow
            BoxShadow(
              color: AppColors.premiumGold.withValues(alpha: 0.25),
              blurRadius: 20,
              spreadRadius: 2,
            ),
            // Depth shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lock icon with gradient + glow
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.premiumGold,
                    AppColors.premiumGoldDark,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.premiumGold.withValues(alpha: 0.5),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: Colors.black87,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'ميزة ${requiredTier.arabicName}',
              style: AppTypography.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'اشترك للوصول',
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlayLocked(BuildContext context) {
    return Stack(
      children: [
        // Blurred child (maintains visual continuity)
        ClipRRect(
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
            child: IgnorePointer(child: child),
          ),
        ),
        // Subtle dark overlay
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.1),
          ),
        ),
        // Lock overlay
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onLockedTap?.call();
            },
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: _PremiumBadge(tier: requiredTier),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Simple locked badge overlay for cards/tiles
class LockedBadge extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final SubscriptionTier tier;
  final bool showFullOverlay;

  const LockedBadge({
    super.key,
    required this.child,
    this.onTap,
    this.tier = SubscriptionTier.max,
    this.showFullOverlay = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (showFullOverlay)
          ClipRRect(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
              child: IgnorePointer(child: child),
            ),
          )
        else
          child,
        if (showFullOverlay)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.1),
            ),
          ),
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap?.call();
            },
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: _PremiumBadge(tier: tier),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Premium badge pill widget
class _PremiumBadge extends StatelessWidget {
  final SubscriptionTier tier;

  const _PremiumBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.premiumGold,
            AppColors.premiumGoldDark,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.premiumGold.withValues(alpha: 0.4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_rounded,
            size: 16,
            color: Colors.black87,
          ),
          const SizedBox(width: 6),
          Text(
            'MAX',
            style: AppTypography.labelMedium.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple icon badge for use in cards/tiles
class PremiumIconBadge extends StatelessWidget {
  final double size;

  const PremiumIconBadge({
    super.key,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.premiumGold,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.premiumGold.withValues(alpha: 0.5),
            blurRadius: 8,
          ),
        ],
      ),
      child: Icon(
        Icons.workspace_premium,
        size: size,
        color: Colors.black87,
      ),
    );
  }
}

/// Conditional feature gate that only gates when needed
/// Use this when you want to conditionally wrap a feature
class ConditionalFeatureGate extends ConsumerWidget {
  final String featureId;
  final Widget child;
  final VoidCallback? onLockedTap;
  final SubscriptionTier requiredTier;

  const ConditionalFeatureGate({
    super.key,
    required this.featureId,
    required this.child,
    this.onLockedTap,
    this.requiredTier = SubscriptionTier.max,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAccess = ref.watch(featureAccessProvider(featureId));

    if (hasAccess) {
      return child;
    }

    return LockedBadge(
      onTap: onLockedTap,
      tier: requiredTier,
      child: child,
    );
  }
}
