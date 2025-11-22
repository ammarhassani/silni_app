import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../models/tree_node.dart';

class TreeNodeWidget extends StatelessWidget {
  final TreeNode node;
  final bool isSelected;
  final VoidCallback onTap;

  const TreeNodeWidget({
    super.key,
    required this.node,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow for selected node
              if (isSelected)
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: node.isRoot
                        ? AppColors.goldenGradient
                        : AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: node.isRoot
                            ? AppColors.premiumGold.withOpacity(0.6)
                            : AppColors.islamicGreenPrimary.withOpacity(0.6),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),

              // Main node circle
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: node.isRoot
                      ? AppColors.goldenGradient
                      : _getGradientByPriority(),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                    width: isSelected ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: node.isRoot
                          ? AppColors.premiumGold.withOpacity(0.3)
                          : AppColors.islamicGreenPrimary.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    node.emoji,
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              ),

              // Priority badge
              if (!node.isRoot && node.priority == 1)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.goldenGradient,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),

              // Extended family badge
              if (node.isExtended)
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.royalBlue,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.people_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Name
          Container(
            constraints: const BoxConstraints(maxWidth: 100),
            child: Text(
              node.name,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Relationship
          Text(
            node.relationship,
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      )
          .animate(delay: Duration(milliseconds: 100 * (node.level.abs() + 1)))
          .fadeIn(duration: const Duration(milliseconds: 400))
          .scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.0, 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
          ),
    );
  }

  Gradient _getGradientByPriority() {
    switch (node.priority) {
      case 1:
        // High priority - golden
        return LinearGradient(
          colors: [
            AppColors.premiumGold.withOpacity(0.8),
            AppColors.joyfulOrange.withOpacity(0.6),
          ],
        );
      case 2:
        // Medium priority - green
        return AppColors.primaryGradient;
      case 3:
        // Low priority - blue/purple
        return LinearGradient(
          colors: [
            AppColors.royalBlue.withOpacity(0.6),
            AppColors.emotionalPurple.withOpacity(0.4),
          ],
        );
      default:
        return AppColors.primaryGradient;
    }
  }
}
