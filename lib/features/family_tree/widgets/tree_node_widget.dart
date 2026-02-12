import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../models/tree_layout.dart';

/// A card-based widget representing a single node in the family tree.
///
/// Styled as a compact card with rounded corners, frosted glass background,
/// emoji avatar in a rounded square, name, and a colored relationship badge.
class TreeNodeWidget extends StatelessWidget {
  final LayoutNode node;
  final VoidCallback? onTap;

  const TreeNodeWidget({
    super.key,
    required this.node,
    this.onTap,
  });

  /// Total widget width (for positioning calculations).
  static const double nodeWidth = 80.0;

  /// Total widget height including card and contents.
  static const double nodeHeight = 100.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: nodeWidth,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: _cardBackground,
            border: Border.all(
              color: _cardBorderColor,
              width: node.isUser ? 1.8 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              // Subtle glow for user node
              if (node.isUser)
                BoxShadow(
                  color: AppColors.premiumGold.withValues(alpha: 0.2),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAvatar(),
              const SizedBox(height: 4),
              _buildName(),
              const SizedBox(height: 3),
              _buildBadge(),
            ],
          ),
        ),
      ),
    );
  }

  /// Emoji avatar in a rounded square, with optional Silni badge.
  Widget _buildAvatar() {
    final avatar = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: _avatarBackground,
      ),
      child: Center(
        child: Text(
          node.emoji,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );

    if (!node.isLinkedMember || node.isUser) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          top: -4,
          right: -4,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.calmBlue, width: 1),
            ),
            padding: const EdgeInsets.all(2),
            child: Image.asset(
              'assets/images/app_icon.png',
              width: 10,
              height: 10,
            ),
          ),
        ),
      ],
    );
  }

  /// Name text — white, compact.
  Widget _buildName() {
    return Text(
      node.name,
      style: AppTypography.labelSmall.copyWith(
        color: Colors.white,
        fontWeight: node.isUser ? FontWeight.bold : FontWeight.w600,
        fontSize: 10,
        height: 1.1,
      ),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Colored relationship badge pill.
  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: _badgeColor,
      ),
      child: Text(
        node.label,
        style: AppTypography.labelSmall.copyWith(
          color: _badgeTextColor,
          fontSize: 8,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Card colors — glass-style tinted by health
  // ---------------------------------------------------------------------------

  Color get _cardBackground {
    if (node.isUser) {
      return AppColors.premiumGold.withValues(alpha: 0.12);
    }
    return switch (node.healthColor) {
      HealthColor.green => const Color(0xFF4CAF50).withValues(alpha: 0.10),
      HealthColor.amber => const Color(0xFFFF9800).withValues(alpha: 0.10),
      HealthColor.red => const Color(0xFFE53935).withValues(alpha: 0.10),
    };
  }

  Color get _cardBorderColor {
    if (node.isUser) {
      return AppColors.premiumGold.withValues(alpha: 0.5);
    }
    return switch (node.healthColor) {
      HealthColor.green => Colors.white.withValues(alpha: 0.15),
      HealthColor.amber => const Color(0xFFFFCA28).withValues(alpha: 0.25),
      HealthColor.red => const Color(0xFFEF5350).withValues(alpha: 0.25),
    };
  }

  Color get _avatarBackground {
    if (node.isUser) {
      return AppColors.premiumGold.withValues(alpha: 0.2);
    }
    return switch (node.healthColor) {
      HealthColor.green => Colors.white.withValues(alpha: 0.08),
      HealthColor.amber => const Color(0xFFFF9800).withValues(alpha: 0.12),
      HealthColor.red => const Color(0xFFE53935).withValues(alpha: 0.12),
    };
  }

  Color get _badgeColor {
    if (node.isUser) {
      return AppColors.premiumGold.withValues(alpha: 0.85);
    }
    return switch (node.healthColor) {
      HealthColor.green => const Color(0xFF4CAF50).withValues(alpha: 0.75),
      HealthColor.amber => const Color(0xFFF57F17).withValues(alpha: 0.75),
      HealthColor.red => const Color(0xFFC62828).withValues(alpha: 0.75),
    };
  }

  Color get _badgeTextColor {
    if (node.isUser) return Colors.black87;
    return Colors.white;
  }
}
