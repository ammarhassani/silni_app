import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../models/tree_node.dart';

class TreeNodeWidget extends StatelessWidget {
  final TreeNode node;
  final bool isSelected;
  final VoidCallback onTap;
  final double nodeSize;

  const TreeNodeWidget({
    super.key,
    required this.node,
    this.isSelected = false,
    required this.onTap,
    this.nodeSize = 80,
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
                  width: nodeSize + 10,
                  height: nodeSize + 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: node.isRoot
                        ? AppColors.goldenGradient
                        : AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: node.isRoot
                            ? AppColors.premiumGold.withValues(alpha: 0.6)
                            : AppColors.islamicGreenPrimary.withValues(alpha: 0.6),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),

              // Main node circle
              Container(
                width: nodeSize,
                height: nodeSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: node.isRoot
                      ? AppColors.goldenGradient
                      : _getGradientByPriority(),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                    width: isSelected ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: node.isRoot
                          ? AppColors.premiumGold.withValues(alpha: 0.3)
                          : AppColors.islamicGreenPrimary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    node.emoji,
                    style: TextStyle(fontSize: nodeSize * 0.45),
                  ),
                ),
              ),

              // Priority badge
              if (!node.isRoot && node.priority == 1)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: nodeSize * 0.3,
                    height: nodeSize * 0.3,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.goldenGradient,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      Icons.star_rounded,
                      size: nodeSize * 0.175,
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
                    width: nodeSize * 0.3,
                    height: nodeSize * 0.3,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.calmBlue,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      Icons.people_rounded,
                      size: nodeSize * 0.175,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Name
          Container(
            constraints: BoxConstraints(maxWidth: nodeSize * 1.25),
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
              color: Colors.white.withValues(alpha: 0.7),
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
            AppColors.premiumGold.withValues(alpha: 0.8),
            AppColors.joyfulOrange.withValues(alpha: 0.6),
          ],
        );
      case 2:
        // Medium priority - green
        return AppColors.primaryGradient;
      case 3:
        // Low priority - blue/purple
        return LinearGradient(
          colors: [
            AppColors.calmBlue.withValues(alpha: 0.6),
            AppColors.emotionalPurple.withValues(alpha: 0.4),
          ],
        );
      default:
        return AppColors.primaryGradient;
    }
  }
}
