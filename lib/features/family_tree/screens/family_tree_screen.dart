import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:screenshot_callback/screenshot_callback.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/models/relative_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/home_providers.dart';
import '../../../core/providers/realtime_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/models/subscription_tier.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../subscription/screens/paywall_screen.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../providers/family_graph_providers.dart';
import '../painters/family_tree_painter.dart';
import '../models/tree_layout.dart';
import '../services/family_tree_layout_service.dart';

// Note: relativesStreamProvider is now imported from features/home/screens/home_screen.dart

class FamilyTreeScreen extends ConsumerStatefulWidget {
  const FamilyTreeScreen({super.key});

  @override
  ConsumerState<FamilyTreeScreen> createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends ConsumerState<FamilyTreeScreen>
    with TickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  final ScreenshotCallback _screenshotCallback = ScreenshotCallback();
  double _currentScale = 1.0;
  bool _showWatermark = false;

  late final AnimationController _breathingController;
  late final AnimationController _entryController;
  OverlayEntry? _nodeOverlay;
  OverlayEntry? _overlayBarrier;

  @override
  void initState() {
    super.initState();
    _initScreenshotDetection();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  void _initScreenshotDetection() {
    _screenshotCallback.addListener(() {
      // User took a screenshot - show watermark temporarily
      if (mounted) {
        setState(() => _showWatermark = true);
        // Show snackbar with branding
        // Hide previous snackbars
        ScaffoldMessenger.of(context).clearSnackBars();

        // Show custom branded snackbar
        UIHelpers.showSnackBar(
          context,
          'شجرة عائلتي من صلني 🌳',
          backgroundColor: AppColors.islamicGreenDark,
          duration: const Duration(seconds: 3),
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
    _breathingController.dispose();
    _entryController.dispose();
    _dismissOverlay();
    _transformationController.dispose();
    _screenshotCallback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? '';
    final displayName =
        user?.userMetadata?['full_name'] ?? user?.email ?? 'أنا';

    // Check feature access
    final hasFamilyTreeAccess = ref.watch(featureAccessProvider(FeatureIds.familyTree));

    // Initialize real-time subscriptions for this user
    ref.watch(autoRealtimeSubscriptionsProvider);

    final relativesAsync = ref.watch(relativesStreamProvider(userId));

    final themeColors = ref.watch(themeColorsProvider);

    // Show locked state for free users
    if (!hasFamilyTreeAccess) {
      return _buildLockedState(context, themeColors);
    }

    return Scaffold(
      body: Semantics(
        label: 'شجرة العائلة',
        child: Stack(
          children: [
            const GradientBackground(animated: true, child: SizedBox.expand()),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, themeColors),
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
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic themeColors) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Semantics(
            label: 'رجوع',
            button: true,
            child: IconButton(
              onPressed: () => context.pop(),
              icon: Icon(Icons.arrow_back_ios_rounded, color: themeColors.textOnGradient),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'شجرة العائلة',
              style: AppTypography.headlineMedium.copyWith(
                color: themeColors.textOnGradient,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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

  // ---------------------------------------------------------------------------
  // Canvas-based tree content
  // ---------------------------------------------------------------------------

  Widget _buildTreeContent(
    BuildContext context,
    List<Relative> relatives,
    String userName,
    String userId,
  ) {
    if (relatives.isEmpty) {
      return _buildEmptyState();
    }

    // Watch family graph for perspective-shifting labels
    final graph = ref.watch(familyGraphProvider(userId));
    final relativesMap = {for (final r in relatives) r.id: r};

    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(
          max(constraints.maxWidth, 400),
          max(constraints.maxHeight, 600),
        );

        // Compute layout from graph
        final layout = FamilyTreeLayoutService.computeLayout(
          userId: userId,
          userName: userName,
          graph: graph,
          relatives: relatives,
          relativesMap: relativesMap,
          canvasSize: canvasSize,
        );

        // Start entry animation on first build
        if (!_entryController.isAnimating && _entryController.value == 0) {
          _entryController.forward();
        }

        return Stack(
          children: [
            // Main tree canvas
            GestureDetector(
              onTapUp: (details) => _handleCanvasTap(
                details, layout, relativesMap, userId,
              ),
              child: InteractiveViewer(
                transformationController: _transformationController,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                constrained: false,
                minScale: 0.1,
                maxScale: 3.0,
                onInteractionUpdate: (details) {
                  final matrixScale = _transformationController.value.entry(0, 0);
                  if (matrixScale != _currentScale) {
                    setState(() => _currentScale = matrixScale);
                  }
                },
                child: ListenableBuilder(
                  listenable: Listenable.merge([
                    _breathingController,
                    _entryController,
                  ]),
                  builder: (context, _) {
                    return CustomPaint(
                      painter: FamilyTreePainter(
                        layout: layout,
                        animationValue: _breathingController.value,
                        entryProgress: _entryController.value,
                      ),
                      size: layout.bounds.size,
                    );
                  },
                ),
              ),
            ),
            // Watermark overlay
            if (_showWatermark)
              _buildWatermark(),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Canvas tap handling
  // ---------------------------------------------------------------------------

  void _handleCanvasTap(
    TapUpDetails details,
    FamilyTreeLayout layout,
    Map<String, Relative> relativesMap,
    String userId,
  ) {
    _dismissOverlay();

    // Convert screen coordinates to canvas coordinates
    final matrix = _transformationController.value.clone()..invert();
    final localPosition = MatrixUtils.transformPoint(
      matrix,
      details.localPosition,
    );

    final node = layout.findNodeAtPosition(localPosition);
    if (node == null) return;

    if (node.isUser) {
      // Show user info bottom sheet
      _showUserDetails(node);
    } else {
      final relative = relativesMap[node.id];
      if (relative != null) {
        _showNodeOverlay(node, relative, details.globalPosition);
      }
    }
  }

  void _showUserDetails(LayoutNode node) {
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
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.goldenGradient,
                ),
                child: Center(
                  child: Text(node.emoji, style: const TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                node.name,
                style: AppTypography.headlineMedium.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                node.label,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }

  void _showNodeOverlay(
    LayoutNode node,
    Relative relative,
    Offset globalPosition,
  ) {
    _dismissOverlay();

    // Create barrier
    _overlayBarrier = OverlayEntry(
      builder: (_) => GestureDetector(
        onTap: _dismissOverlay,
        behavior: HitTestBehavior.opaque,
        child: const SizedBox.expand(),
      ),
    );

    // Create overlay card
    _nodeOverlay = OverlayEntry(
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;
        const cardWidth = 220.0;
        const cardHeight = 200.0;

        // Position card above or below the tap point
        double top = globalPosition.dy - cardHeight - 20;
        if (top < 60) {
          top = globalPosition.dy + 20;
        }
        double left = (globalPosition.dx - cardWidth / 2)
            .clamp(16.0, screenSize.width - cardWidth - 16.0);

        return Positioned(
          top: top,
          left: left,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: cardWidth,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.islamicGreenDark.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Emoji + Name
                  Text(node.emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    node.name,
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    node.label,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Health indicator
                  _buildHealthIndicator(node),
                  const SizedBox(height: AppSpacing.sm),
                  // Last contact
                  if (relative.lastContactDate != null)
                    Text(
                      'آخر تواصل: ${_formatLastContact(relative)}',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _dismissOverlay();
                        context.push(
                          '${AppRoutes.relativeDetail}/${relative.id}',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.islamicGreenPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      ),
                      child: const Text('عرض التفاصيل'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayBarrier!);
    Overlay.of(context).insert(_nodeOverlay!);
  }

  Widget _buildHealthIndicator(LayoutNode node) {
    final color = switch (node.healthColor) {
      HealthColor.green => const Color(0xFF4CAF50),
      HealthColor.amber => const Color(0xFFFFCA28),
      HealthColor.red => const Color(0xFFEF5350),
    };
    final label = switch (node.healthColor) {
      HealthColor.green => 'تواصل ممتاز',
      HealthColor.amber => 'يحتاج تواصل',
      HealthColor.red => 'تواصل ضعيف',
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: color),
        ),
      ],
    );
  }

  String _formatLastContact(Relative relative) {
    if (relative.lastContactDate == null) return 'لم يتم التواصل';
    final days = DateTime.now().difference(relative.lastContactDate!).inDays;
    if (days == 0) return 'اليوم';
    if (days == 1) return 'أمس';
    if (days < 7) return 'منذ $days أيام';
    if (days < 30) return 'منذ ${days ~/ 7} أسابيع';
    return 'منذ ${days ~/ 30} أشهر';
  }

  void _dismissOverlay() {
    _overlayBarrier?.remove();
    _overlayBarrier = null;
    _nodeOverlay?.remove();
    _nodeOverlay = null;
  }

  // ---------------------------------------------------------------------------
  // Watermark
  // ---------------------------------------------------------------------------

  Widget _buildWatermark() {
    return Positioned(
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
    );
  }

  // ---------------------------------------------------------------------------
  // Empty / Error states
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Locked / Premium gating state
  // ---------------------------------------------------------------------------

  Widget _buildLockedState(BuildContext context, dynamic themeColors) {
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? '';
    final displayName = user?.userMetadata?['full_name'] ?? user?.email ?? 'أنا';
    final relativesAsync = ref.watch(relativesStreamProvider(userId));

    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(animated: true, child: SizedBox.expand()),
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: Icon(Icons.arrow_back_ios_rounded, color: themeColors.textOnGradient),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'شجرة العائلة',
                        style: AppTypography.headlineMedium.copyWith(
                          color: themeColors.textOnGradient,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Blurred preview content
                Expanded(
                  child: Stack(
                    children: [
                      // Blurred tree preview
                      ClipRRect(
                        child: ImageFiltered(
                          imageFilter: ui.ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                          child: relativesAsync.when(
                            data: (relatives) => _buildPreviewTree(
                              relatives.isNotEmpty ? relatives : null,
                              displayName,
                            ),
                            loading: () => _buildPreviewTree(null, displayName),
                            error: (e, s) => _buildPreviewTree(null, displayName),
                          ),
                        ),
                      ),
                      // Gradient fade overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                themeColors.background1.withValues(alpha: 0.2),
                                themeColors.background1.withValues(alpha: 0.65),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Upgrade CTA at bottom
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _buildUpgradeCTA(context, themeColors),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build a preview tree using user's data or demo data
  Widget _buildPreviewTree(List<Relative>? relatives, String userName) {
    // Demo data for users without family members
    final demoNodes = [
      _PreviewNode('👨', 'الأب', -1),
      _PreviewNode('👩', 'الأم', -1),
      _PreviewNode('👤', 'أنت', 0, isRoot: true),
      _PreviewNode('👦', 'الأخ', 0),
      _PreviewNode('👧', 'الأخت', 0),
      _PreviewNode('👶', 'الابن', 1),
    ];

    // Use user's actual data if available
    final List<_PreviewNode> previewNodes;
    if (relatives != null && relatives.isNotEmpty) {
      previewNodes = [
        _PreviewNode('👤', userName, 0, isRoot: true),
        ...relatives.take(5).map((r) => _PreviewNode(
              r.displayEmoji,
              r.fullName,
              _getLevelForRelationship(r.relationshipType),
            )),
      ];
    } else {
      previewNodes = demoNodes;
    }

    // Group by level
    final parentsLevel = previewNodes.where((n) => n.level == -1).toList();
    final userLevel = previewNodes.where((n) => n.level == 0).toList();
    final childrenLevel = previewNodes.where((n) => n.level == 1).toList();

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.xl),
            // Parents level
            if (parentsLevel.isNotEmpty) ...[
              _buildPreviewGeneration(parentsLevel, 70),
              const SizedBox(height: AppSpacing.md),
              _buildConnectionLines(parentsLevel.length, vertical: true),
              const SizedBox(height: AppSpacing.md),
            ],
            // User + siblings level
            if (userLevel.isNotEmpty) ...[
              _buildPreviewGeneration(userLevel, 80),
            ],
            // Children level
            if (childrenLevel.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _buildConnectionLines(childrenLevel.length, vertical: true),
              const SizedBox(height: AppSpacing.md),
              _buildPreviewGeneration(childrenLevel, 60),
            ],
            const SizedBox(height: AppSpacing.ctaCardPadding), // Space for CTA card
          ],
        ),
      ),
    );
  }

  int _getLevelForRelationship(RelationshipType type) {
    switch (type) {
      case RelationshipType.father:
      case RelationshipType.mother:
      case RelationshipType.grandfather:
      case RelationshipType.grandmother:
        return -1;
      case RelationshipType.brother:
      case RelationshipType.sister:
      case RelationshipType.husband:
      case RelationshipType.wife:
        return 0;
      case RelationshipType.son:
      case RelationshipType.daughter:
      case RelationshipType.uncle:
      case RelationshipType.aunt:
      case RelationshipType.cousin:
      case RelationshipType.nephew:
      case RelationshipType.niece:
      case RelationshipType.other:
        return 1;
    }
  }

  Widget _buildPreviewGeneration(List<_PreviewNode> nodes, double nodeSize) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      children: nodes.map((node) => _buildPreviewNode(node, nodeSize)).toList(),
    );
  }

  Widget _buildPreviewNode(_PreviewNode node, double nodeSize) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: nodeSize,
          height: nodeSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: node.isRoot
                ? const LinearGradient(
                    colors: [AppColors.premiumGold, AppColors.premiumGoldDark],
                  )
                : LinearGradient(
                    colors: [
                      AppColors.islamicGreenPrimary.withValues(alpha: 0.8),
                      AppColors.islamicGreenDark.withValues(alpha: 0.8),
                    ],
                  ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (node.isRoot ? AppColors.premiumGold : AppColors.islamicGreenPrimary)
                    .withValues(alpha: 0.3),
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
        const SizedBox(height: 6),
        Text(
          node.name,
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white,
            fontWeight: node.isRoot ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Connection lines used by _buildPreviewTree in locked state
  Widget _buildConnectionLines(int count, {required bool vertical}) {
    if (count <= 0) return const SizedBox.shrink();

    if (vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 20,
            width: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.islamicGreenLight.withValues(alpha: 0.8),
                  AppColors.islamicGreenPrimary.withValues(alpha: 0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.islamicGreenPrimary.withValues(alpha: 0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return Container(
        width: 20,
        height: 3,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }
  }

  Widget _buildUpgradeCTA(BuildContext context, dynamic themeColors) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.premiumGold.withValues(alpha: 0.25),
            AppColors.premiumGoldDark.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: AppColors.premiumGold.withValues(alpha: 0.6),
          width: 2,
        ),
        boxShadow: [
          // Gold outer glow
          BoxShadow(
            color: AppColors.premiumGold.withValues(alpha: 0.3),
            blurRadius: 24,
            spreadRadius: 2,
          ),
          // Depth shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Lock icon with gradient + glow
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.premiumGold, AppColors.premiumGoldDark],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.premiumGold.withValues(alpha: 0.5),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.lock_rounded, size: 32, color: Colors.black87),
          ),
          const SizedBox(height: AppSpacing.md),
          // Title
          Text(
            'اكتشف شجرة عائلتك',
            style: AppTypography.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Description
          Text(
            'اعرض شجرة عائلتك بشكل تفاعلي وشاركها مع أفراد عائلتك',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          // Upgrade button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PaywallScreen(
                      featureToUnlock: FeatureIds.familyTree,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.premiumGold,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.workspace_premium, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'ترقية للاشتراك المميز',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Zoom controls
  // ---------------------------------------------------------------------------

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

/// Simple data class for preview tree nodes
class _PreviewNode {
  final String emoji;
  final String name;
  final int level;
  final bool isRoot;

  _PreviewNode(this.emoji, this.name, this.level, {this.isRoot = false});
}
