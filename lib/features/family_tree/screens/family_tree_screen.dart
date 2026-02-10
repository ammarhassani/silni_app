import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show UserAttributes;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:screenshot_callback/screenshot_callback.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/providers/cache_provider.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/services/auto_reminder_service.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/models/relative_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../contacts/screens/contact_import_screen.dart';
import '../../home/providers/home_providers.dart';
import '../../../core/providers/realtime_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/models/subscription_tier.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../relatives/services/relationship_inference_service.dart';
import '../../relatives/widgets/smart_relationship_picker.dart';
import '../../subscription/screens/paywall_screen.dart';
import '../../family_groups/services/family_group_service.dart';
import '../../family_groups/services/family_sharing_service.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../models/placeholder_node.dart';
import '../models/family_graph.dart';
import '../providers/family_graph_providers.dart';
import '../painters/family_tree_painter.dart';
import '../models/tree_layout.dart';
import '../services/family_graph_service.dart';
import '../services/family_tree_layout_service.dart';
import '../widgets/placeholder_node_widget.dart';
import '../widgets/tree_node_widget.dart';

class FamilyTreeScreen extends ConsumerStatefulWidget {
  const FamilyTreeScreen({super.key});

  @override
  ConsumerState<FamilyTreeScreen> createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends ConsumerState<FamilyTreeScreen> {
  final TransformationController _transformationController =
      TransformationController();
  final ScreenshotCallback _screenshotCallback = ScreenshotCallback();
  double _currentScale = 1.0;
  bool _showWatermark = false;
  bool _showPlaceholders = true;
  bool _hasCenteredOnUser = false;

  /// IDs of nodes that were just created (placeholder → filled).
  /// Used to trigger a one-shot scale-spring entrance animation.
  final Set<String> _newlyFilledIds = {};

  /// Flag to track if we've attempted migration for this session.
  bool _hasMigratedRelatives = false;

  String _familyName = 'شجرة العائلة';
  bool _isEditingName = false;
  final _nameController = TextEditingController();

  OverlayEntry? _nodeOverlay;
  OverlayEntry? _overlayBarrier;

  @override
  void initState() {
    super.initState();
    _initScreenshotDetection();

    // Load persisted family name from user metadata
    final user = SupabaseConfig.client.auth.currentUser;
    final name = user?.userMetadata?['family_name'] as String?;
    if (name != null && name.isNotEmpty) {
      _familyName = name;
    } else {
      // Joiner may not have family_name in metadata — load from group
      _loadGroupName();
    }
  }

  Future<void> _loadGroupName() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;
    final group = await FamilySharingService.getUserGroup(userId);
    if (group != null && mounted) {
      setState(() => _familyName = group.name);
    }
  }

  /// Ensure user's relatives are migrated to their group.
  ///
  /// Called once per session when we detect the user is in a group.
  /// Handles the case where a user created a group but their relatives
  /// weren't migrated (e.g., due to earlier bugs or race conditions).
  Future<void> _ensureRelativesMigrated(String groupId) async {
    if (_hasMigratedRelatives) return;
    _hasMigratedRelatives = true;

    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await FamilySharingService.ensureRelativesInGroup(
        userId: userId,
        groupId: groupId,
      );
      // Verify and fill any missing shared edges
      await FamilySharingService.verifySharedEdges(groupId: groupId);
      // Invalidate providers to refresh with migrated data
      if (mounted) {
        ref.invalidate(groupRelativesStreamProvider(groupId));
        ref.invalidate(sharedFamilyEdgesStreamProvider(groupId));
      }
    } catch (e, st) {
      debugPrint('ensureRelativesInGroup failed: $e\n$st');
      // Allow retry on next screen mount by resetting the flag
      _hasMigratedRelatives = false;
    }
  }

  void _initScreenshotDetection() {
    _screenshotCallback.addListener(() {
      // User took a screenshot — show watermark, hide placeholders
      if (mounted) {
        setState(() {
          _showWatermark = true;
          _showPlaceholders = false;
        });
        ScaffoldMessenger.of(context).clearSnackBars();
        UIHelpers.showSnackBar(
          context,
          'شجرة عائلتي من صلني 🌳',
          backgroundColor: AppColors.islamicGreenDark,
          duration: const Duration(seconds: 3),
        );
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showWatermark = false;
              _showPlaceholders = true;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _dismissOverlay();
    _nameController.dispose();
    _transformationController.dispose();
    _screenshotCallback.dispose();
    super.dispose();
  }

  Future<void> _saveFamilyName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      setState(() => _isEditingName = false);
      return;
    }
    setState(() {
      _familyName = trimmed;
      _isEditingName = false;
    });
    await SupabaseConfig.client.auth.updateUser(
      UserAttributes(data: {'family_name': trimmed}),
    );

    // Also update the family group name if user has one
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId != null) {
      final group = await FamilySharingService.getUserGroup(userId);
      if (group != null) {
        await FamilyGroupService.updateGroupName(
          groupId: group.id,
          name: trimmed,
        );
      }
    }
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

    // Check if user is in a family group — wait for this to resolve before
    // deciding which tree to show (prevents flicker from personal→shared)
    final groupInfoAsync = ref.watch(userFamilyGroupProvider);

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
                  groupInfoAsync.when(
                    loading: () => _buildHeader(context, themeColors, null),
                    error: (_, __) => _buildHeader(context, themeColors, null),
                    data: (groupInfo) => _buildHeader(context, themeColors, groupInfo),
                  ),
                Expanded(
                  // Wait for group info to resolve before deciding which tree
                  // to show. This prevents the flicker from personal→shared.
                  child: groupInfoAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    error: (_, __) => _buildError(),
                    data: (groupInfo) {
                      final relativesAsync = groupInfo != null
                          ? ref.watch(groupRelativesStreamProvider(groupInfo.groupId))
                          : ref.watch(relativesStreamProvider(userId));

                      return relativesAsync.when(
                        data: (relatives) {
                          // If user is in a group, ensure their personal relatives
                          // are migrated to the group (handles older data or failed migrations).
                          // Schedule via post-frame callback to avoid setState during build.
                          if (groupInfo != null && !_hasMigratedRelatives) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                _ensureRelativesMigrated(groupInfo.groupId);
                              }
                            });
                          }
                          return _buildTreeContent(
                            context,
                            relatives,
                            displayName,
                            userId,
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                        error: (_, __) => _buildError(),
                      );
                    },
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
          // FAB fallback — manual add button
          Positioned(
            bottom: AppSpacing.xl,
            left: AppSpacing.md,
            child: SafeArea(
              child: _buildAddFab(userId),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    dynamic themeColors,
    ({String groupId, String? nodeId})? groupInfo,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        // Semi-transparent dark scrim for WCAG2 contrast on all themes
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.3),
            Colors.black.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Row(
        children: [
          Semantics(
            label: 'رجوع',
            button: true,
            child: IconButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.home);
                }
              },
              icon: Icon(Icons.arrow_back_ios_rounded, color: themeColors.textOnGradient),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _isEditingName
                ? TextField(
                    controller: _nameController,
                    autofocus: true,
                    cursorColor: themeColors.textOnGradient,
                    style: AppTypography.headlineMedium.copyWith(
                      color: themeColors.textOnGradient,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      filled: false,
                      border: InputBorder.none,
                      hintText: 'شجرة العائلة',
                      hintStyle: AppTypography.headlineMedium.copyWith(
                        color: (themeColors.textOnGradient as Color)
                            .withValues(alpha: 0.6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: _saveFamilyName,
                    onTapOutside: (_) =>
                        _saveFamilyName(_nameController.text),
                  )
                : GestureDetector(
                    onTap: () {
                      if (groupInfo != null) {
                        // Navigate to group details (like WhatsApp)
                        context.push('${AppRoutes.familyGroupDetail}/${groupInfo.groupId}');
                      } else {
                        // Enable editing for personal tree
                        setState(() {
                          _nameController.text = _familyName;
                          _isEditingName = true;
                        });
                      }
                    },
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            _familyName,
                            style: AppTypography.headlineMedium.copyWith(
                              color: themeColors.textOnGradient,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          groupInfo != null
                              ? Icons.chevron_right_rounded
                              : Icons.edit_rounded,
                          size: groupInfo != null ? 24 : 16,
                          color: themeColors.textOnGradient,
                        ),
                      ],
                    ),
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
  // FAB fallback — manual add
  // ---------------------------------------------------------------------------

  Widget _buildAddFab(String userId) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'لإضافة المزيد\nعم، خال، وغيرهم',
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 9,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 6),
        FloatingActionButton.small(
          heroTag: 'tree_add_fab',
          onPressed: () => _showFallbackAddSheet(userId),
          backgroundColor: AppColors.islamicGreenDark.withValues(alpha: 0.9),
          child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 20),
        ),
      ],
    );
  }

  Future<void> _showFallbackAddSheet(String userId) async {
    HapticFeedback.lightImpact();

    final relatives =
        ref.read(relativesStreamProvider(userId)).valueOrNull ?? <Relative>[];
    final suggestions =
        RelationshipInferenceService.suggestRelationships(relatives);

    RelationshipType? selectedType;
    FamilySide? selectedSide;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              margin: const EdgeInsets.all(AppSpacing.md),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.65,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      child: SmartRelationshipPicker(
                        selected: selectedType ?? (suggestions.isNotEmpty ? suggestions.first : RelationshipType.other),
                        suggestions: suggestions,
                        existingRelatives: relatives,
                        selectedSide: selectedSide,
                        onChanged: (type) {
                          setSheetState(() => selectedType = type);
                        },
                        onSideChanged: (side) {
                          setSheetState(() => selectedSide = side);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.islamicGreenPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'اختيار جهة اتصال',
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final chosenType = selectedType ?? (suggestions.isNotEmpty ? suggestions.first : RelationshipType.other);
    final chosenSide = selectedSide;

    // Open contact picker
    final dynamic result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ContactImportScreen(singleSelect: true),
      ),
    );

    if (!mounted || result == null) return;

    final String fullName = (result.displayName as String?) ?? '';
    final phones = result.phones as List<dynamic>?;
    final String? phoneNumber =
        (phones != null && phones.isNotEmpty) ? phones.first.number as String? : null;

    if (fullName.trim().isEmpty) return;

    // Build a synthetic PlaceholderNode to reuse existing creation logic
    final gender = RelationshipInferenceService.inferGender(fullName.trim());
    final placeholder = PlaceholderNode(
      id: 'fab-manual',
      type: chosenType,
      side: chosenSide,
      expectedGender: gender,
      label: '',
      generation: 0,
      position: Offset.zero,
      radius: 30.0,
    );

    await _createRelativeFromPlaceholder(
      placeholder: placeholder,
      userId: userId,
      fullName: fullName.trim(),
      phoneNumber: phoneNumber,
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
    // Check for shared tree context — if user is in a family group,
    // use the group's relatives and edges for the tree.
    final groupInfo = ref.watch(userFamilyGroupProvider).valueOrNull;
    final graph = groupInfo != null
        ? ref.watch(sharedFamilyGraphProvider((
            groupId: groupInfo.groupId,
            viewerNodeId: groupInfo.nodeId,
          )))
        : ref.watch(familyGraphProvider(userId));

    // For shared trees, use the viewer's node ID as the layout anchor.
    // If user isn't linked to a node yet, use their auth userId as fallback
    // (won't match any node, but layout will still work).
    final effectiveUserId = groupInfo?.nodeId ?? userId;

    // For shared trees, apply rahim scope filter so each viewer only
    // sees their blood relatives (plus direct spouse), then remap
    // relationship types to the viewer's perspective.
    final List<Relative> visibleRelatives;
    if (groupInfo != null && graph != null) {
      final enrichedGraph = FamilyGraphService.enrichAllSiblingEdges(graph);
      final rahimScope = FamilyGraphService.computeRahimScope(
        viewerId: effectiveUserId,
        graph: enrichedGraph,
      );
      final scoped = relatives.where((r) => rahimScope.contains(r.id)).toList();
      final scopedMap = {for (final r in scoped) r.id: r};
      visibleRelatives = FamilyGraphService.remapForViewer(
        viewerId: effectiveUserId,
        graph: enrichedGraph,
        relatives: scoped,
        relativesMap: scopedMap,
      );
    } else {
      visibleRelatives = relatives;
    }

    final relativesMap = {for (final r in visibleRelatives) r.id: r};

    // Fetch linked member node IDs for badge rendering
    final linkedMemberNodeIds = groupInfo != null
        ? ref.watch(groupMemberNodeIdsProvider(groupInfo.groupId)).valueOrNull ?? <String>{}
        : <String>{};

    // Infer user gender from name for placeholder labels
    final userGender = RelationshipInferenceService.inferGender(userName);

    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(
          max(constraints.maxWidth, 400),
          max(constraints.maxHeight, 600),
        );

        // Compute layout from graph (includes placeholder positions)
        final layout = FamilyTreeLayoutService.computeLayout(
          userId: effectiveUserId,
          userName: userName,
          graph: graph,
          relatives: visibleRelatives,
          relativesMap: relativesMap,
          canvasSize: canvasSize,
          userGender: userGender,
          linkedMemberNodeIds: linkedMemberNodeIds,
        );

        // The hybrid approach: painted edges + widget nodes + placeholder widgets
        final boundsSize = layout.bounds.size;
        final boundsOrigin = layout.bounds.topLeft;

        // Center on user node on first render
        if (!_hasCenteredOnUser) {
          _hasCenteredOnUser = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final userLocalX = layout.userPosition.dx - boundsOrigin.dx;
            final userLocalY = layout.userPosition.dy - boundsOrigin.dy;
            final viewW = constraints.maxWidth;
            final viewH = constraints.maxHeight;
            final tx = -(userLocalX - viewW / 2);
            final ty = -(userLocalY - viewH / 2);
            final matrix = Matrix4.identity();
            matrix.setEntry(0, 3, tx);
            matrix.setEntry(1, 3, ty);
            _transformationController.value = matrix;
          });
        }

        return Stack(
          children: [
            // Main tree with InteractiveViewer for pan/zoom
            InteractiveViewer(
              transformationController: _transformationController,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              constrained: false,
              minScale: 0.1,
              maxScale: 3.0,
              onInteractionUpdate: (details) {
                final matrixScale =
                    _transformationController.value.entry(0, 0);
                if (matrixScale != _currentScale) {
                  setState(() => _currentScale = matrixScale);
                }
              },
              child: SizedBox(
                width: boundsSize.width,
                height: boundsSize.height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Layer 1: Painted edges + placeholder connections
                    Positioned.fill(
                      child: CustomPaint(
                        painter: FamilyTreeEdgePainter(
                          layout: layout,
                          boundsOrigin: boundsOrigin,
                          showPlaceholders: _showPlaceholders,
                        ),
                      ),
                    ),
                    // Layer 2: Placeholder widgets (below filled nodes)
                    if (_showPlaceholders)
                      for (var i = 0; i < layout.placeholders.length; i++)
                        Builder(builder: (context) {
                          final ph = layout.placeholders[i];
                          return Positioned(
                            left: ph.position.dx -
                                boundsOrigin.dx -
                                (ph.isCompact
                                    ? PlaceholderNodeWidget.compactSize / 2
                                    : PlaceholderNodeWidget.nodeSize / 2),
                            top: ph.position.dy -
                                boundsOrigin.dy -
                                (ph.isCompact
                                    ? PlaceholderNodeWidget.compactSize / 2
                                    : PlaceholderNodeWidget.nodeSize / 2),
                            child: PlaceholderNodeWidget(
                              placeholder: ph,
                              onTap: () => _handlePlaceholderTap(ph, userId),
                            )
                                .animate(delay: Duration(milliseconds: 60 * i))
                                .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                                .scaleXY(
                                  begin: 0.5,
                                  end: 1.0,
                                  duration: 400.ms,
                                  curve: Curves.elasticOut,
                                ),
                          );
                        }),
                    // Layer 3: Widget-based filled nodes
                    for (final node in layout.nodes)
                      Positioned(
                        left: node.position.dx -
                            boundsOrigin.dx -
                            TreeNodeWidget.nodeWidth / 2,
                        top: node.position.dy -
                            boundsOrigin.dy -
                            TreeNodeWidget.nodeHeight / 2,
                        child: _buildNodeWithAnimation(node, relativesMap, userId),
                      ),
                  ],
                ),
              ),
            ),
            // Watermark overlay
            if (_showWatermark) _buildWatermark(),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Node rendering with fill animation
  // ---------------------------------------------------------------------------

  Widget _buildNodeWithAnimation(
    LayoutNode node,
    Map<String, Relative> relativesMap,
    String userId,
  ) {
    Widget child = TreeNodeWidget(
      node: node,
      onTap: () => _handleNodeTap(node, relativesMap, userId),
    );

    // One-shot spring scale for newly filled nodes
    if (_newlyFilledIds.contains(node.id)) {
      child = child
          .animate(onComplete: (_) {
            // Remove from set after animation to avoid replaying
            _newlyFilledIds.remove(node.id);
          })
          .scaleXY(
            begin: 0.0,
            end: 1.0,
            duration: 500.ms,
            curve: Curves.elasticOut,
          );
    }

    return child;
  }

  // ---------------------------------------------------------------------------
  // Node tap handling
  // ---------------------------------------------------------------------------

  void _handleNodeTap(
    LayoutNode node,
    Map<String, Relative> relativesMap,
    String userId,
  ) {
    _dismissOverlay();

    if (node.isUser) {
      _showUserDetails(node);
    } else {
      final relative = relativesMap[node.id];
      if (relative != null) {
        // Navigate directly to relative detail
        context.push('${AppRoutes.relativeDetail}/${relative.id}');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Placeholder tap → contact picker → create relative
  // ---------------------------------------------------------------------------

  Future<void> _handlePlaceholderTap(
    PlaceholderNode placeholder,
    String userId,
  ) async {
    HapticFeedback.lightImpact();

    // Open contact picker in single-select mode.
    // Returns a flutter_contacts Contact object (displayName + phones).
    final dynamic result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ContactImportScreen(singleSelect: true),
      ),
    );

    if (!mounted || result == null) return;

    // Extract name and phone from the Contact object
    final String fullName = (result.displayName as String?) ?? '';
    final phones = result.phones as List<dynamic>?;
    final String? phoneNumber =
        (phones != null && phones.isNotEmpty) ? phones.first.number as String? : null;

    if (fullName.trim().isEmpty) return;

    await _createRelativeFromPlaceholder(
      placeholder: placeholder,
      userId: userId,
      fullName: fullName.trim(),
      phoneNumber: phoneNumber,
    );
  }

  Future<void> _createRelativeFromPlaceholder({
    required PlaceholderNode placeholder,
    required String userId,
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      // Determine gender from placeholder or infer from name
      final gender = placeholder.expectedGender ??
          RelationshipInferenceService.inferGender(fullName);

      final avatarType = AvatarType.suggestFromRelationship(
        placeholder.type,
        gender,
      );
      final priority = AvatarType.suggestPriority(placeholder.type);

      // Check if we're in a family group context
      final groupInfo = ref.read(userFamilyGroupProvider).valueOrNull;
      final isGroupMode = groupInfo != null;

      final relative = Relative(
        id: '',
        userId: userId,
        fullName: fullName,
        relationshipType: placeholder.type,
        gender: gender,
        avatarType: avatarType,
        phoneNumber: phoneNumber,
        priority: priority,
        familySide: placeholder.side,
        familyGroupId: isGroupMode ? groupInfo.groupId : null,
        addedBy: isGroupMode ? userId : null,
        createdAt: DateTime.now(),
      );

      // Save relative — this is the critical operation
      final repository = ref.read(relativesRepositoryProvider);
      final createdId = await repository.createRelative(relative);

      // Track for fill animation (scale spring on next rebuild)
      _newlyFilledIds.add(createdId);

      // Edge inference + persistence is non-critical — don't let it
      // block the success feedback if it fails.
      try {
        final List<FamilyEdge> existingEdges;
        final List<Relative> existingRelatives;
        final String edgeAnchorId;

        if (isGroupMode) {
          existingEdges = ref
                  .read(sharedFamilyEdgesStreamProvider(groupInfo.groupId))
                  .valueOrNull ??
              <FamilyEdge>[];
          existingRelatives = ref
                  .read(groupRelativesStreamProvider(groupInfo.groupId))
                  .valueOrNull ??
              <Relative>[];
          edgeAnchorId = groupInfo.nodeId ?? userId;
        } else {
          existingEdges =
              ref.read(familyEdgesStreamProvider(userId)).valueOrNull ??
                  <FamilyEdge>[];
          existingRelatives =
              ref.read(relativesStreamProvider(userId)).valueOrNull ??
                  <Relative>[];
          edgeAnchorId = userId;
        }

        final inferredEdges = FamilyGraphService.inferEdges(
          userId: edgeAnchorId,
          newRelativeId: createdId,
          relationshipType: placeholder.type,
          side: placeholder.side,
          existingEdges: existingEdges,
          existingRelatives: existingRelatives,
        );

        if (inferredEdges.isNotEmpty) {
          // For shared edges, set family_group_id and ensure user_id is the
          // auth user ID (not the node ID used as edge anchor for inference).
          final edgesToPersist = isGroupMode
              ? inferredEdges
                  .map((e) => FamilyEdge(
                        id: e.id,
                        userId: userId,
                        fromId: e.fromId,
                        toId: e.toId,
                        type: e.type,
                        createdAt: e.createdAt,
                        familyGroupId: groupInfo.groupId,
                      ))
                  .toList()
              : inferredEdges;

          await SupabaseConfig.client.from('family_edges').upsert(
            edgesToPersist.map((e) => e.toJson()).toList(),
            onConflict: 'user_id,from_id,to_id,edge_type',
          );
        }
      } catch (edgeError) {
        debugPrint('Non-critical: edge persistence failed: $edgeError');
      }

      // Auto-create reminder (fire-and-forget)
      unawaited(AutoReminderService.createAutoReminder(
        userId: userId,
        relativeId: createdId,
        relationshipType: placeholder.type,
        remindersRepository: ref.read(reminderSchedulesRepositoryProvider),
      ));

      // Invalidate providers to refresh tree immediately after creation.
      // The Supabase .stream() realtime also picks up changes, but
      // explicit invalidation gives instant visual feedback.
      if (isGroupMode) {
        ref.invalidate(groupRelativesStreamProvider(groupInfo.groupId));
        ref.invalidate(sharedFamilyEdgesStreamProvider(groupInfo.groupId));
      } else {
        ref.invalidate(relativesStreamProvider(userId));
        ref.invalidate(familyEdgesStreamProvider(userId));
      }

      // Re-center viewport on user after tree rebuilds with new node
      _hasCenteredOnUser = false;

      if (!mounted) return;

      HapticFeedback.mediumImpact();
      UIHelpers.showSnackBar(
        context,
        'تم إضافة $fullName بنجاح',
        backgroundColor: AppColors.islamicGreenPrimary,
      );
    } catch (e) {
      debugPrint('Failed to create relative from placeholder: $e');
      if (!mounted) return;
      UIHelpers.showSnackBar(
        context,
        'حدث خطأ أثناء الإضافة',
        backgroundColor: Colors.red.shade700,
      );
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
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(AppRoutes.home);
                          }
                        },
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
                          imageFilter: ui.ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
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
                                themeColors.background1.withValues(alpha: 0.1),
                                themeColors.background1.withValues(alpha: 0.4),
                                themeColors.background1.withValues(alpha: 0.7),
                              ],
                              stops: const [0.0, 0.4, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Upgrade CTA centered
                      Positioned.fill(
                        child: Center(
                          child: _buildUpgradeCTA(context, themeColors),
                        ),
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
      constraints: const BoxConstraints(maxWidth: 300),
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
      decoration: BoxDecoration(
        color: themeColors.background1.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: AppColors.premiumGold.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.premiumGold.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Lock icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.premiumGold, AppColors.premiumGoldDark],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.premiumGold.withValues(alpha: 0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(Icons.lock_rounded, size: 24, color: Colors.black87),
          ),
          const SizedBox(height: AppSpacing.md),
          // Title
          Text(
            'اكتشف شجرة عائلتك',
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Description
          Text(
            'اعرض شجرة عائلتك بشكل تفاعلي\nوشاركها مع أفراد عائلتك',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white60,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
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
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.workspace_premium, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    'ترقية للاشتراك المميز',
                    style: AppTypography.labelLarge.copyWith(
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
    // Re-trigger centering on next build
    setState(() {
      _currentScale = 1.0;
      _hasCenteredOnUser = false;
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
