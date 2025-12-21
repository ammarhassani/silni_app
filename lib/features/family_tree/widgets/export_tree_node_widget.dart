import 'package:flutter/material.dart';
import '../../../core/theme/app_themes.dart';
import '../models/tree_node.dart';

/// A simplified tree node widget for export
/// - No animations (renders immediately)
/// - Full opacity
/// - Full text (no truncation)
/// - Consistent colors (no contact/priority indicators)
/// - Respects user theme
class ExportTreeNodeWidget extends StatelessWidget {
  final TreeNode node;
  final double nodeSize;
  final ThemeColors themeColors;

  const ExportTreeNodeWidget({
    super.key,
    required this.node,
    required this.nodeSize,
    required this.themeColors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main node circle - CONSISTENT color for all nodes (no contact indicators)
        Container(
          width: nodeSize,
          height: nodeSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Root gets golden, ALL others get primaryGradient (no priority/contact distinction)
            gradient: node.isRoot
                ? themeColors.goldenGradient
                : themeColors.primaryGradient,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: node.isRoot
                    ? themeColors.secondary.withValues(alpha: 0.5)
                    : themeColors.primary.withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              node.emoji,
              style: TextStyle(fontSize: nodeSize * 0.4),
            ),
          ),
        ),
        SizedBox(height: nodeSize * 0.08),

        // Name - full text, no truncation
        SizedBox(
          width: nodeSize * 1.6,
          child: Text(
            node.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: nodeSize * 0.18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.visible,
          ),
        ),

        // Relationship
        Text(
          node.relationship,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: nodeSize * 0.14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
