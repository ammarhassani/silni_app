/// Tree node model for family tree visualization
class TreeNode {
  final String id;
  final String name;
  final String emoji;
  final String relationship;
  final int level; // -2: grandparents, -1: parents, 0: user/siblings, 1: children
  final int priority;
  final bool isRoot;
  final bool isExtended;
  final List<TreeNode> children;
  final List<TreeNode> siblings;

  TreeNode({
    required this.id,
    required this.name,
    required this.emoji,
    required this.relationship,
    required this.level,
    this.priority = 2,
    this.isRoot = false,
    this.isExtended = false,
    List<TreeNode>? children,
    List<TreeNode>? siblings,
  })  : children = children ?? [],
        siblings = siblings ?? [];

  void addChild(TreeNode child) {
    children.add(child);
  }

  void addSibling(TreeNode sibling) {
    siblings.add(sibling);
  }

  /// Get color based on priority
  int get priorityColor {
    switch (priority) {
      case 1:
        return 0xFFFFD700; // Gold - high priority
      case 2:
        return 0xFF4CAF50; // Green - medium priority
      case 3:
        return 0xFF2196F3; // Blue - low priority
      default:
        return 0xFF4CAF50;
    }
  }

  /// Get level description
  String get levelDescription {
    switch (level) {
      case -2:
        return 'الأجداد';
      case -1:
        return 'الوالدين';
      case 0:
        return isRoot ? 'أنا' : 'الإخوة';
      case 1:
        return isExtended ? 'العائلة الممتدة' : 'الأبناء';
      default:
        return '';
    }
  }
}
