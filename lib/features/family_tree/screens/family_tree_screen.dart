import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/models/relative_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/screens/home_screen.dart';
import '../widgets/tree_node_widget.dart';
import '../models/tree_node.dart';
import '../../../core/providers/realtime_provider.dart';

// Note: relativesStreamProvider is now imported from features/home/screens/home_screen.dart

class FamilyTreeScreen extends ConsumerStatefulWidget {
  const FamilyTreeScreen({super.key});

  @override
  ConsumerState<FamilyTreeScreen> createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends ConsumerState<FamilyTreeScreen> {
  final TransformationController _transformationController =
      TransformationController();
  double _currentScale = 1.0;
  String? _selectedNodeId;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? '';
    final displayName =
        user?.userMetadata?['full_name'] ?? user?.email ?? 'أنا';

    // Initialize real-time subscriptions for this user
    ref.watch(autoRealtimeSubscriptionsProvider);

    debugPrint('🌳 [FAMILY TREE] Building family tree for user: $userId');
    final relativesAsync = ref.watch(relativesStreamProvider(userId));

    // Log when relatives data changes
    relativesAsync.whenData((relatives) {
      debugPrint(
        '🌳 [FAMILY TREE] Relatives updated: ${relatives.length} relatives',
      );
      final relativeNames = relatives
          .map((r) => '${r.fullName} (${r.id})')
          .toList();
      debugPrint('🌳 [FAMILY TREE] Current relatives in tree: $relativeNames');
    });

    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(animated: true, child: SizedBox.expand()),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: relativesAsync.when(
                    data: (relatives) => _buildTreeContent(
                      context,
                      relatives,
                      displayName,
                      userId,
                    ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    error: (_,_) => _buildError(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'شجرة العائلة',
                  style: AppTypography.headlineLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'تصور جميل لأفراد عائلتك',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          // Zoom controls
          Row(
            children: [
              IconButton(
                onPressed: _zoomOut,
                icon: const Icon(Icons.zoom_out_rounded, color: Colors.white),
                tooltip: 'تصغير',
              ),
              Text(
                '${(_currentScale * 100).toInt()}%',
                style: AppTypography.bodySmall.copyWith(color: Colors.white),
              ),
              IconButton(
                onPressed: _zoomIn,
                icon: const Icon(Icons.zoom_in_rounded, color: Colors.white),
                tooltip: 'تكبير',
              ),
              IconButton(
                onPressed: _resetZoom,
                icon: const Icon(
                  Icons.center_focus_strong_rounded,
                  color: Colors.white,
                ),
                tooltip: 'إعادة ضبط',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTreeContent(
    BuildContext context,
    List<Relative> relatives,
    String userName,
    String userId,
  ) {
    if (relatives.isEmpty) {
      return _buildEmptyState();
    }

    // Build tree structure
    final treeData = _buildTreeData(relatives, userName);

    return InteractiveViewer(
      transformationController: _transformationController,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      constrained: false,
      minScale: 0.1,
      maxScale: 3.0,
      onInteractionUpdate: (details) {
        // Read scale directly from matrix entry (0,0) instead of getMaxScaleOnAxis()
        // getMaxScaleOnAxis() returns 1.0 when zoomed out because Z axis is always 1.0
        final matrixScale = _transformationController.value.entry(0, 0);
        if (matrixScale != _currentScale) {
          setState(() {
            _currentScale = matrixScale;
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: _buildTreeLayout(treeData, relatives),
      ),
    );
  }

  TreeNode _buildTreeData(List<Relative> relatives, String userName) {
    // Root node (user)
    final root = TreeNode(
      id: 'me',
      name: userName,
      emoji: '👤',
      relationship: 'أنا',
      level: 0,
      isRoot: true,
    );

    // Separate relatives by generation
    final parents = relatives
        .where(
          (r) =>
              r.relationshipType == RelationshipType.father ||
              r.relationshipType == RelationshipType.mother,
        )
        .toList();

    final grandparents = relatives
        .where(
          (r) =>
              r.relationshipType == RelationshipType.grandfather ||
              r.relationshipType == RelationshipType.grandmother,
        )
        .toList();

    final siblings = relatives
        .where(
          (r) =>
              r.relationshipType == RelationshipType.brother ||
              r.relationshipType == RelationshipType.sister,
        )
        .toList();

    final children = relatives
        .where(
          (r) =>
              r.relationshipType == RelationshipType.son ||
              r.relationshipType == RelationshipType.daughter,
        )
        .toList();

    final spouse = relatives
        .where(
          (r) =>
              r.relationshipType == RelationshipType.husband ||
              r.relationshipType == RelationshipType.wife,
        )
        .toList();

    final extended = relatives
        .where(
          (r) =>
              r.relationshipType == RelationshipType.uncle ||
              r.relationshipType == RelationshipType.aunt ||
              r.relationshipType == RelationshipType.cousin ||
              r.relationshipType == RelationshipType.nephew ||
              r.relationshipType == RelationshipType.niece ||
              r.relationshipType == RelationshipType.other,
        )
        .toList();

    // Add parents to root
    for (final parent in parents) {
      root.addChild(
        TreeNode(
          id: parent.id,
          name: parent.fullName,
          emoji: parent.displayEmoji,
          relationship: parent.relationshipType.arabicName,
          level: -1,
          priority: parent.priority,
        ),
      );
    }

    // Add grandparents to parents
    for (final grandparent in grandparents) {
      if (root.children.isNotEmpty) {
        root.children.first.addChild(
          TreeNode(
            id: grandparent.id,
            name: grandparent.fullName,
            emoji: grandparent.displayEmoji,
            relationship: grandparent.relationshipType.arabicName,
            level: -2,
            priority: grandparent.priority,
          ),
        );
      }
    }

    // Add spouse to root
    for (final s in spouse) {
      root.addSibling(
        TreeNode(
          id: s.id,
          name: s.fullName,
          emoji: s.displayEmoji,
          relationship: s.relationshipType.arabicName,
          level: 0,
          priority: s.priority,
        ),
      );
    }

    // Add siblings to root
    for (final sibling in siblings) {
      root.addSibling(
        TreeNode(
          id: sibling.id,
          name: sibling.fullName,
          emoji: sibling.displayEmoji,
          relationship: sibling.relationshipType.arabicName,
          level: 0,
          priority: sibling.priority,
        ),
      );
    }

    // Add children to root
    for (final child in children) {
      root.addChild(
        TreeNode(
          id: child.id,
          name: child.fullName,
          emoji: child.displayEmoji,
          relationship: child.relationshipType.arabicName,
          level: 1,
          priority: child.priority,
        ),
      );
    }

    // Add extended family to root
    for (final ext in extended) {
      root.addChild(
        TreeNode(
          id: ext.id,
          name: ext.fullName,
          emoji: ext.displayEmoji,
          relationship: ext.relationshipType.arabicName,
          level: 1,
          priority: ext.priority,
          isExtended: true,
        ),
      );
    }

    return root;
  }

  Widget _buildTreeLayout(TreeNode root, List<Relative> relatives) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Grandparents (Level -2)
        if (root.children.isNotEmpty &&
            root.children.first.children.isNotEmpty) ...[
          _buildGeneration(root.children.first.children, relatives, -2),
          const SizedBox(height: AppSpacing.md),
          _buildConnectionLines(
            root.children.first.children.length,
            vertical: true,
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Parents (Level -1)
        if (root.children.where((n) => n.level == -1).isNotEmpty) ...[
          _buildGeneration(
            root.children.where((n) => n.level == -1).toList(),
            relatives,
            -1,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildConnectionLines(
            root.children.where((n) => n.level == -1).length,
            vertical: true,
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // User + Siblings + Spouse (Level 0)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Siblings before user
            if (root.siblings.isNotEmpty) ...[
              ...root.siblings.map(
                (sibling) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: TreeNodeWidget(
                    node: sibling,
                    isSelected: _selectedNodeId == sibling.id,
                    onTap: () => _onNodeTap(sibling, relatives),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _buildConnectionLines(root.siblings.length + 1, vertical: false),
              const SizedBox(width: AppSpacing.md),
            ],

            // User (root)
            TreeNodeWidget(
              node: root,
              isSelected: _selectedNodeId == root.id,
              onTap: () => _onNodeTap(root, relatives),
            ),
          ],
        ),

        // Children + Extended (Level 1+)
        if (root.children.where((n) => n.level >= 1).isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _buildConnectionLines(
            root.children.where((n) => n.level >= 1).length,
            vertical: true,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildGeneration(
            root.children.where((n) => n.level >= 1).toList(),
            relatives,
            1,
          ),
        ],
      ],
    );
  }

  Widget _buildGeneration(
    List<TreeNode> nodes,
    List<Relative> relatives,
    int level,
  ) {
    if (nodes.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      alignment: WrapAlignment.center,
      children: nodes.map((node) {
        return TreeNodeWidget(
          node: node,
          isSelected: _selectedNodeId == node.id,
          onTap: () => _onNodeTap(node, relatives),
        );
      }).toList(),
    );
  }

  Widget _buildConnectionLines(int count, {required bool vertical}) {
    if (count <= 0) return const SizedBox.shrink();

    if (vertical) {
      return Container(
        height: 30,
        width: 3,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    } else {
      return Container(
        width: 30,
        height: 3,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }
  }

  void _onNodeTap(TreeNode node, List<Relative> relatives) {
    setState(() {
      _selectedNodeId = node.id;
    });

    if (node.isRoot) {
      // Show user info
      _showNodeDetails(node, null);
    } else {
      // Find relative and show details
      final relative = relatives.firstWhere((r) => r.id == node.id);
      _showNodeDetails(node, relative);
    }
  }

  void _showNodeDetails(TreeNode node, Relative? relative) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GlassCard(
          margin: const EdgeInsets.all(AppSpacing.md),
          borderRadius: AppSpacing.radiusXl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.md),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: node.isRoot
                      ? AppColors.goldenGradient
                      : AppColors.primaryGradient,
                ),
                child: Center(
                  child: Text(node.emoji, style: const TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Name
              Text(
                node.name,
                style: AppTypography.headlineMedium.copyWith(
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Relationship
              Text(
                node.relationship,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),

              if (relative != null) ...[
                const SizedBox(height: AppSpacing.lg),
                const Divider(color: Colors.white24),
                const SizedBox(height: AppSpacing.md),

                // Details
                if (relative.phoneNumber != null)
                  _buildDetailRow(Icons.phone_rounded, relative.phoneNumber!),
                if (relative.email != null)
                  _buildDetailRow(Icons.email_rounded, relative.email!),
                if (relative.address != null)
                  _buildDetailRow(Icons.location_on_rounded, relative.address!),

                const SizedBox(height: AppSpacing.lg),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          context.push(
                            '${AppRoutes.relativeDetail}/${relative.id}',
                          );
                        },
                        icon: const Icon(Icons.visibility_rounded),
                        label: const Text('عرض التفاصيل'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.islamicGreenPrimary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌳', style: TextStyle(fontSize: 64)),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'شجرة عائلتك فارغة',
                style: AppTypography.headlineMedium.copyWith(
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'ابدأ بإضافة أقاربك لرؤية شجرة العائلة',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.addRelative),
                icon: const Icon(Icons.person_add_rounded),
                label: const Text('إضافة قريب'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.islamicGreenPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: GlassCard(
        margin: const EdgeInsets.all(AppSpacing.xl),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'حدث خطأ في تحميل شجرة العائلة',
              style: AppTypography.bodyLarge.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _zoomIn() {
    final newScale = (_currentScale * 1.2).clamp(0.1, 3.0);
    _applyZoom(newScale);
  }

  void _zoomOut() {
    final newScale = (_currentScale / 1.2).clamp(0.1, 3.0);
    _applyZoom(newScale);
  }

  void _applyZoom(double newScale) {
    // Preserve current translation while changing scale
    final currentMatrix = _transformationController.value;
    final translation = currentMatrix.getTranslation();

    // Adjust translation to zoom towards center
    final scaleFactor = newScale / _currentScale;
    final newTranslationX = translation.x * scaleFactor;
    final newTranslationY = translation.y * scaleFactor;

    // Build new matrix with scale and adjusted translation
    final newMatrix = Matrix4.identity();
    newMatrix.setEntry(0, 0, newScale); // scaleX
    newMatrix.setEntry(1, 1, newScale); // scaleY
    newMatrix.setEntry(0, 3, newTranslationX); // translateX
    newMatrix.setEntry(1, 3, newTranslationY); // translateY

    setState(() {
      _currentScale = newScale;
      _transformationController.value = newMatrix;
    });
  }

  void _resetZoom() {
    setState(() {
      _currentScale = 1.0;
      _transformationController.value = Matrix4.identity();
    });
  }
}
