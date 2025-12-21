import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:screenshot/screenshot.dart';
import 'package:screenshot_callback/screenshot_callback.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/models/relative_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/home_providers.dart';
import '../widgets/tree_node_widget.dart';
import '../widgets/export_tree_node_widget.dart';
import '../models/tree_node.dart';
import '../../../core/providers/realtime_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_themes.dart';

// Note: relativesStreamProvider is now imported from features/home/screens/home_screen.dart

class FamilyTreeScreen extends ConsumerStatefulWidget {
  const FamilyTreeScreen({super.key});

  @override
  ConsumerState<FamilyTreeScreen> createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends ConsumerState<FamilyTreeScreen> {
  final TransformationController _transformationController =
      TransformationController();
  final ScreenshotController _screenshotController = ScreenshotController();
  final ScreenshotCallback _screenshotCallback = ScreenshotCallback();
  double _currentScale = 1.0;
  String? _selectedNodeId;
  bool _isExporting = false;
  bool _showWatermark = false;

  // Store tree data for export
  TreeNode? _currentTreeData;
  List<Relative>? _currentRelatives;

  @override
  void initState() {
    super.initState();
    _initScreenshotDetection();
  }

  void _initScreenshotDetection() {
    _screenshotCallback.addListener(() {
      // User took a screenshot - show watermark temporarily
      if (mounted) {
        setState(() => _showWatermark = true);
        // Show snackbar with branding
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Image.asset(
                  'assets/images/silni_branding.png',
                  width: 40,
                  height: 40,
                ),
                const SizedBox(width: AppSpacing.sm),
                const Text('شجرة عائلتي من صلني 🌳'),
              ],
            ),
            backgroundColor: AppColors.islamicGreenDark,
            duration: const Duration(seconds: 3),
          ),
        );
        // Hide watermark after delay
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _showWatermark = false);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _screenshotCallback.dispose();
    super.dispose();
  }

  /// Calculate responsive node size based on screen width and tree complexity
  double _calculateNodeSize(double screenWidth, TreeNode root) {
    // Count total members at level 0 (siblings + user + spouse)
    final level0Count = root.siblings.length + 1;

    // Base size calculations
    const double minNodeSize = 50.0;
    const double maxNodeSize = 90.0;
    const double defaultNodeSize = 80.0;

    // For small screens (< 400px), use smaller nodes
    if (screenWidth < 400) {
      return minNodeSize;
    }

    // For medium screens (400-600px)
    if (screenWidth < 600) {
      // Scale based on number of siblings
      if (level0Count > 4) return minNodeSize;
      if (level0Count > 3) return 60.0;
      return 70.0;
    }

    // For larger screens, adjust based on tree complexity
    if (level0Count > 5) return 60.0;
    if (level0Count > 3) return 70.0;

    // Default size for normal trees
    return defaultNodeSize.clamp(minNodeSize, maxNodeSize);
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
          // Floating zoom controls
          Positioned(
            bottom: AppSpacing.xl,
            right: AppSpacing.md,
            child: SafeArea(
              child: _buildZoomControls(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'شجرة العائلة',
              style: AppTypography.headlineMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Share button only
          IconButton(
            onPressed: _isExporting ? null : _exportTree,
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.share_rounded, color: Colors.white),
            tooltip: 'مشاركة الشجرة',
          ),
        ],
      ),
    );
  }

  Widget _buildZoomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.islamicGreenDark.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: _zoomOut,
            icon: const Icon(Icons.remove_rounded, color: Colors.white, size: 20),
            tooltip: 'تصغير',
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              '${(_currentScale * 100).toInt()}%',
              style: AppTypography.labelSmall.copyWith(color: Colors.white),
            ),
          ),
          IconButton(
            onPressed: _zoomIn,
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            tooltip: 'تكبير',
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
          Container(
            width: 1,
            height: 20,
            color: Colors.white.withValues(alpha: 0.3),
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          ),
          IconButton(
            onPressed: _resetZoom,
            icon: const Icon(Icons.center_focus_strong_rounded, color: Colors.white, size: 20),
            tooltip: 'إعادة ضبط',
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
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

    // Store for export
    _currentTreeData = treeData;
    _currentRelatives = relatives;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive node size based on screen width
        final screenWidth = constraints.maxWidth;
        final nodeSize = _calculateNodeSize(screenWidth, treeData);

        return Stack(
          children: [
            // Main tree view (NO branding - clean view)
            InteractiveViewer(
              transformationController: _transformationController,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              constrained: false,
              minScale: 0.1,
              maxScale: 3.0,
              onInteractionUpdate: (details) {
                final matrixScale = _transformationController.value.entry(0, 0);
                if (matrixScale != _currentScale) {
                  setState(() {
                    _currentScale = matrixScale;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                color: Colors.transparent,
                child: _buildTreeLayout(treeData, relatives, nodeSize),
              ),
            ),
            // Watermark overlay (shows when screenshot detected)
            if (_showWatermark)
              Positioned(
                bottom: AppSpacing.xxl,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.islamicGreenDark.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/silni_branding.png',
                          width: 50,
                          height: 50,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          'شجرة عائلتي',
                          style: AppTypography.headlineSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
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

  Widget _buildTreeLayout(TreeNode root, List<Relative> relatives, double nodeSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Grandparents (Level -2)
        if (root.children.isNotEmpty &&
            root.children.first.children.isNotEmpty) ...[
          _buildGeneration(root.children.first.children, relatives, -2, nodeSize),
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
            nodeSize,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildConnectionLines(
            root.children.where((n) => n.level == -1).length,
            vertical: true,
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // User + Siblings + Spouse (Level 0)
        _buildSiblingRow(root, relatives, nodeSize),

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
            nodeSize,
          ),
        ],
      ],
    );
  }

  Widget _buildGeneration(
    List<TreeNode> nodes,
    List<Relative> relatives,
    int level,
    double nodeSize,
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
          nodeSize: nodeSize,
        );
      }).toList(),
    );
  }

  Widget _buildSiblingRow(TreeNode root, List<Relative> relatives, double nodeSize) {
    // Combine all level 0 members: siblings + user + spouse
    final allMembers = <TreeNode>[];

    // Add siblings first
    allMembers.addAll(root.siblings.where((s) =>
      s.relationship == 'أخ' || s.relationship == 'أخت' ||
      s.relationship.contains('أخ') || s.relationship.contains('أخت')));

    // Add user (root) in the middle
    allMembers.add(root);

    // Add spouse after user
    allMembers.addAll(root.siblings.where((s) =>
      s.relationship == 'زوج' || s.relationship == 'زوجة' ||
      s.relationship.contains('زوج') || s.relationship.contains('زوجة')));

    if (allMembers.length == 1) {
      // Just the user, no siblings
      return TreeNodeWidget(
        node: root,
        isSelected: _selectedNodeId == root.id,
        onTap: () => _onNodeTap(root, relatives),
        nodeSize: nodeSize,
      );
    }

    // Build row with horizontal connection lines between siblings
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (int i = 0; i < allMembers.length; i++) ...[
          TreeNodeWidget(
            node: allMembers[i],
            isSelected: _selectedNodeId == allMembers[i].id,
            onTap: () => _onNodeTap(allMembers[i], relatives),
            nodeSize: nodeSize,
          ),
          // Add horizontal connection line between members (not after last one)
          if (i < allMembers.length - 1) ...[
            const SizedBox(width: AppSpacing.xs),
            _buildHorizontalConnection(
              isSpouseConnection: _isSpouseNode(allMembers[i]) || _isSpouseNode(allMembers[i + 1]),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ],
    );
  }

  bool _isSpouseNode(TreeNode node) {
    return node.relationship == 'زوج' ||
           node.relationship == 'زوجة' ||
           node.relationship.contains('زوج') ||
           node.relationship.contains('زوجة');
  }

  Widget _buildHorizontalConnection({bool isSpouseConnection = false}) {
    return Container(
      width: 40,
      height: 3,
      decoration: BoxDecoration(
        gradient: isSpouseConnection
            ? AppColors.goldenGradient  // Golden for spouse connection (marriage)
            : AppColors.primaryGradient, // Green for sibling connection
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: isSpouseConnection
                ? AppColors.premiumGold.withValues(alpha: 0.4)
                : AppColors.islamicGreenPrimary.withValues(alpha: 0.4),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
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

  Future<void> _exportTree() async {
    if (_currentTreeData == null || _currentRelatives == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد شجرة للتصدير'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Get the render box before async operations (required for iOS share sheet)
    final box = context.findRenderObject() as RenderBox?;
    final sharePositionOrigin = box != null
        ? Rect.fromLTWH(
            box.size.width / 2,
            0,
            box.size.width / 2,
            box.size.height / 2,
          )
        : null;

    setState(() => _isExporting = true);

    try {
      // Capture the branded export widget
      final image = await _screenshotController.captureFromWidget(
        _buildBrandedExportWidget(),
        delay: const Duration(milliseconds: 100),
        pixelRatio: 2.0,
      );

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/family_tree_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path);
      await file.writeAsBytes(image);

      await Share.shareXFiles(
        [XFile(path)],
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  /// Calculate optimal node size for export based on tree complexity
  double _calculateExportNodeSize(TreeNode root) {
    // Count members at each level
    final grandparentsCount = root.children.isNotEmpty
        ? root.children.first.children.length
        : 0;
    final parentsCount = root.children.where((n) => n.level == -1).length;
    final siblingsCount = root.siblings.length + 1; // +1 for user
    final childrenCount = root.children.where((n) => n.level >= 1).length;

    // Find the widest row (most members horizontally)
    final maxRowCount = [grandparentsCount, parentsCount, siblingsCount, childrenCount]
        .reduce((a, b) => a > b ? a : b);

    // Total members for vertical consideration
    final totalMembers = grandparentsCount + parentsCount + siblingsCount + childrenCount;

    // Node size bounds - reduced minimum to ensure siblings fit in one row
    const double minNodeSize = 35.0;
    const double maxNodeSize = 70.0;

    // Calculate based on widest row
    // Each node needs: nodeSize + spacing + text width (~nodeSize * 2.0)
    // Target export width ~350px (accounting for padding)
    double nodeSize;
    if (maxRowCount <= 2) {
      nodeSize = maxNodeSize;
    } else if (maxRowCount <= 3) {
      nodeSize = 60.0;
    } else if (maxRowCount <= 4) {
      nodeSize = 50.0;
    } else if (maxRowCount <= 5) {
      nodeSize = 42.0;
    } else if (maxRowCount <= 6) {
      nodeSize = 38.0;
    } else {
      // For 7+ members in a row, use minimum
      nodeSize = minNodeSize;
    }

    // Also consider total members (many members = smaller nodes)
    if (totalMembers > 12) {
      nodeSize = (nodeSize * 0.85).clamp(minNodeSize, maxNodeSize);
    }

    return nodeSize;
  }

  /// Build a branded widget specifically for export (with title and watermark)
  Widget _buildBrandedExportWidget() {
    // Calculate intelligent node size based on tree complexity
    final exportNodeSize = _calculateExportNodeSize(_currentTreeData!);
    // Get user's selected theme colors
    final themeColors = ref.read(themeColorsProvider);

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: themeColors.backgroundGradient,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title header
            Text(
              'شجرة عائلتي 🌳',
              style: AppTypography.headlineMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Tree content with intelligent node sizing
            _buildExportTreeLayout(_currentTreeData!, exportNodeSize, themeColors),
            const SizedBox(height: AppSpacing.lg),
            // App branding watermark
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/silni_branding.png',
                  width: 36,
                  height: 36,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'صلني',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build tree layout for export with intelligent sizing
  Widget _buildExportTreeLayout(TreeNode root, double nodeSize, ThemeColors themeColors) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Grandparents (Level -2)
        if (root.children.isNotEmpty &&
            root.children.first.children.isNotEmpty) ...[
          _buildExportGeneration(root.children.first.children, nodeSize, themeColors),
          SizedBox(height: nodeSize * 0.15),
          _buildExportConnectionLine(themeColors),
          SizedBox(height: nodeSize * 0.15),
        ],

        // Parents (Level -1)
        if (root.children.where((n) => n.level == -1).isNotEmpty) ...[
          _buildExportGeneration(
            root.children.where((n) => n.level == -1).toList(),
            nodeSize,
            themeColors,
          ),
          SizedBox(height: nodeSize * 0.15),
          _buildExportConnectionLine(themeColors),
          SizedBox(height: nodeSize * 0.15),
        ],

        // User + Siblings + Spouse (Level 0)
        _buildExportSiblingRow(root, nodeSize, themeColors),

        // Children + Extended (Level 1+)
        if (root.children.where((n) => n.level >= 1).isNotEmpty) ...[
          SizedBox(height: nodeSize * 0.15),
          _buildExportConnectionLine(themeColors),
          SizedBox(height: nodeSize * 0.15),
          _buildExportGeneration(
            root.children.where((n) => n.level >= 1).toList(),
            nodeSize,
            themeColors,
          ),
        ],
      ],
    );
  }

  Widget _buildExportConnectionLine(ThemeColors themeColors) {
    return Container(
      height: 25,
      width: 3,
      decoration: BoxDecoration(
        gradient: themeColors.primaryGradient,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildExportGeneration(List<TreeNode> nodes, double nodeSize, ThemeColors themeColors) {
    if (nodes.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: nodeSize * 0.2,
      runSpacing: nodeSize * 0.2,
      alignment: WrapAlignment.center,
      children: nodes.map((node) {
        return ExportTreeNodeWidget(
          node: node,
          nodeSize: nodeSize,
          themeColors: themeColors,
        );
      }).toList(),
    );
  }

  Widget _buildExportSiblingRow(TreeNode root, double nodeSize, ThemeColors themeColors) {
    // Combine all level 0 members: siblings + user + spouse
    final allMembers = <TreeNode>[];

    // Add siblings first (brothers/sisters)
    allMembers.addAll(root.siblings.where((s) =>
      s.relationship == 'أخ' || s.relationship == 'أخت' ||
      s.relationship.contains('أخ') || s.relationship.contains('أخت')));

    // Add user (root) in the middle
    allMembers.add(root);

    // Add spouse after user
    allMembers.addAll(root.siblings.where((s) =>
      s.relationship == 'زوج' || s.relationship == 'زوجة' ||
      s.relationship.contains('زوج') || s.relationship.contains('زوجة')));

    if (allMembers.length == 1) {
      return ExportTreeNodeWidget(
        node: root,
        nodeSize: nodeSize,
        themeColors: themeColors,
      );
    }

    // Use Row wrapped in FittedBox to ensure ALL siblings stay on ONE line
    // FittedBox will scale down if needed to prevent overflow
    // This prevents siblings from looking like children/different generation
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: allMembers.map((member) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: nodeSize * 0.1),
            child: ExportTreeNodeWidget(
              node: member,
              nodeSize: nodeSize,
              themeColors: themeColors,
            ),
          );
        }).toList(),
      ),
    );
  }
}
