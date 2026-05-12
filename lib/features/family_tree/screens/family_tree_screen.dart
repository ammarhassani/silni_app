import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:screenshot_callback/screenshot_callback.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/providers/cache_provider.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glass_dialog.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/models/relative_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../contacts/screens/contact_import_screen.dart';
import '../../home/providers/home_providers.dart';
import '../../../core/providers/realtime_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/models/subscription_tier.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../relatives/services/relationship_inference_service.dart';
import '../../../shared/widgets/flat_relationship_picker.dart';
import '../../subscription/screens/paywall_screen.dart';
import '../../family_groups/services/family_sharing_service.dart';
import '../../family_groups/models/node_claim_model.dart';
import '../../family_groups/providers/family_group_providers.dart';
import '../../family_groups/providers/node_claim_providers.dart';
import '../../family_groups/services/node_claim_service.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../models/placeholder_node.dart';
import '../models/family_graph.dart';
import '../providers/family_graph_providers.dart';
import '../painters/family_tree_painter.dart';
import '../models/tree_layout.dart';
import '../services/family_graph_service.dart';
import '../services/family_tree_layout_service.dart';
import '../widgets/group_switcher_chip.dart';
import '../widgets/placeholder_node_widget.dart';
import '../widgets/tree_node_widget.dart';
import '../../../shared/widgets/directional_icon.dart';
import '../../../shared/widgets/persistent_bottom_nav.dart';

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
  bool _hasCenteredOnUser = false;

  /// IDs of nodes that were just created (placeholder → filled).
  /// Used to trigger a one-shot scale-spring entrance animation.
  final Set<String> _newlyFilledIds = {};

  /// Flag to track if we've attempted migration for this session.
  bool _hasMigratedRelatives = false;

  /// Group-mode shared-graph load timeout. The shared-graph stream
  /// historically had no timeout — if it failed silently, the screen
  /// spun forever. After 10s without a graph the spinner gives way to
  /// an error state with retry.
  Timer? _graphTimeoutTimer;
  bool _graphLoadTimedOut = false;

  final _nameController = TextEditingController();

  OverlayEntry? _nodeOverlay;
  OverlayEntry? _overlayBarrier;

  @override
  void initState() {
    super.initState();
    _initScreenshotDetection();
  }

  /// SharedPreferences key for the user's migration choice.
  /// Stored globally — once chosen, we don't ask again on subsequent groups.
  static const String _migrationChoiceKey = 'family_migration_choice';

  /// SharedPreferences key prefix for the per-group "personal vs shared"
  /// explainer-banner dismissal flag. Keyed by groupId so joining a new
  /// group re-shows the banner (new context).
  static const String _personalVsSharedBannerKeyPrefix =
      'banner_dismissed_personal_vs_shared_';

  /// In-memory cache of per-group dismissal state for the personal-vs-shared
  /// banner. `null` = not yet loaded from prefs (banner hidden until then to
  /// avoid a flash); `true` = previously dismissed; `false` = should show.
  final Map<String, bool> _personalVsSharedDismissed = {};

  /// Tracks which groupIds have an in-flight prefs load so we don't fire
  /// duplicate reads on every build.
  final Set<String> _personalVsSharedLoading = {};

  /// Kick off an async load of the dismissal flag for [groupId] if we
  /// haven't already. Idempotent.
  void _loadPersonalVsSharedDismissal(String groupId) {
    if (_personalVsSharedDismissed.containsKey(groupId)) return;
    if (_personalVsSharedLoading.contains(groupId)) return;
    _personalVsSharedLoading.add(groupId);
    SharedPreferences.getInstance().then((prefs) {
      final dismissed = prefs.getBool(
            '$_personalVsSharedBannerKeyPrefix$groupId',
          ) ??
          false;
      if (!mounted) return;
      setState(() {
        _personalVsSharedDismissed[groupId] = dismissed;
        _personalVsSharedLoading.remove(groupId);
      });
    });
  }

  /// Persist the dismissal for [groupId] and update local state immediately.
  Future<void> _dismissPersonalVsSharedBanner(String groupId) async {
    if (mounted) {
      setState(() {
        _personalVsSharedDismissed[groupId] = true;
      });
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      '$_personalVsSharedBannerKeyPrefix$groupId',
      true,
    );
  }

  /// Ensure the group admin's relatives are migrated to their group.
  ///
  /// Called once per session when we detect the user is in a group.
  /// Only the admin's personal relatives are migrated — joiners keep
  /// their personal data separate (they mapped to an existing node).
  ///
  /// On first-time setup (admin has no self-node yet), prompts the user
  /// before silently moving their personal relatives into the shared tree.
  Future<void> _ensureRelativesMigrated(String groupId) async {
    if (_hasMigratedRelatives) return;
    _hasMigratedRelatives = true;

    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Only the admin should migrate personal relatives into the group.
      // Joiners already have a tree node and their personal relatives are
      // a separate, independent dataset that shouldn't pollute the group.
      final memberRow = await SupabaseConfig.client
          .from('family_group_members')
          .select('role, relative_id_in_tree')
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .maybeSingle();

      if (memberRow == null) {
        // User is not (yet) a member of this group — could be because they
        // tapped a deep link without going through the wizard, or because
        // their unlinked-membership row was pruned by the 2026-05-11 backfill.
        // Route them home; they can re-tap the invite link.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لست عضواً في هذه المجموعة بعد')),
          );
          context.go(AppRoutes.home);
        }
        return;
      }

      final isAdmin = memberRow['role'] == 'admin';
      final hasSelfNode = memberRow['relative_id_in_tree'] != null;

      if (isAdmin) {
        // First-time setup only (no self-node yet) — ask the user before
        // moving their personal relatives. Subsequent calls early-return
        // inside the service.
        bool migrateRelatives = true;
        if (!hasSelfNode) {
          migrateRelatives = await _resolveMigrationChoice(userId);
        }

        await FamilySharingService.ensureRelativesInGroup(
          userId: userId,
          groupId: groupId,
          migrateRelatives: migrateRelatives,
        );
      }

      // Verify and fill any missing shared edges (for all members)
      await FamilySharingService.verifySharedEdges(groupId: groupId);
      // Invalidate providers to refresh with migrated data
      if (mounted) {
        ref.invalidate(groupRelativesStreamProvider(groupId));
        ref.invalidate(sharedFamilyEdgesStreamProvider(groupId));
      }
    } catch (e, st) {
      debugPrint('ensureRelativesMigrated failed: $e\n$st');
      // Allow retry on next screen mount by resetting the flag
      _hasMigratedRelatives = false;
    }
  }

  /// Resolve the user's choice to migrate personal relatives.
  ///
  /// Returns the stored choice if one exists. Otherwise counts personal
  /// relatives, shows a modal, persists the choice, and returns it.
  /// Skips the modal entirely (returns false) if there are no personal
  /// relatives — nothing to ask about.
  Future<bool> _resolveMigrationChoice(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_migrationChoiceKey);
    if (stored != null) return stored;

    final personal = await SupabaseConfig.client
        .from('relatives')
        .select('id')
        .eq('user_id', userId)
        .isFilter('family_group_id', null)
        .eq('is_archived', false);
    final count = personal.length;
    if (count == 0) return false;

    if (!mounted) return false;
    final choice = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GlassDialog(
        icon: Icons.account_tree_rounded,
        title: 'نقل أقاربك إلى الشجرة المشتركة؟',
        subtitle:
            'الأقارب اللي عندك حالياً: $count. تبي تنقلهم للشجرة المشتركة عشان أهل المجموعة يقدرون يشوفونهم؟',
        content: const SizedBox.shrink(),
        actions: [
          GlassActionButton(
            text: 'اتركهم منفصلين',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          GradientButton(
            text: 'انقلهم',
            icon: Icons.swap_horiz_rounded,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );

    final result = choice ?? false;
    await prefs.setBool(_migrationChoiceKey, result);
    return result;
  }

  void _initScreenshotDetection() {
    _screenshotCallback.addListener(() {
      // The corner brand badge is always rendered, so the screenshot the
      // user just took already includes the logo — no need to flash a
      // second-pass watermark and ask them to re-capture. Confirm + offer
      // a properly-branded share via the share-capture pipeline if they
      // want a richer header.
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      UIHelpers.showSnackBar(
        context,
        'شعار صِلْني مدمج في الصورة 🌳 — اضغط على المشاركة لنسخة أوضح',
        backgroundColor: AppColors.islamicGreenDark,
        duration: const Duration(seconds: 4),
      );
    });
  }

  @override
  void dispose() {
    _dismissOverlay();
    _nameController.dispose();
    _transformationController.dispose();
    _screenshotCallback.dispose();
    _graphTimeoutTimer?.cancel();
    super.dispose();
  }

  /// Arm the 10-second graph-load timeout. Idempotent — if the timer is
  /// already running it's left alone.
  void _armGraphTimeout() {
    if (_graphTimeoutTimer != null) return;
    _graphTimeoutTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => _graphLoadTimedOut = true);
    });
  }

  /// Cancel + reset the timeout (called when the graph arrives or on retry).
  void _resetGraphTimeout() {
    _graphTimeoutTimer?.cancel();
    _graphTimeoutTimer = null;
    if (_graphLoadTimedOut && mounted) {
      setState(() => _graphLoadTimedOut = false);
    }
  }

  /// Error state shown after the 10s graph-load timeout fires. Tapping
  /// "إعادة المحاولة" invalidates the upstream stream and resets the
  /// timeout flag, returning the user to the spinner with a fresh chance.
  Widget _buildGraphLoadTimeoutState(String groupId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'تعذّر تحميل شجرة العائلة',
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'تحقق من الاتصال بالإنترنت ثم حاول مرة أخرى',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () {
                _resetGraphTimeout();
                ref.invalidate(sharedFamilyEdgesStreamProvider(groupId));
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
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
    final groupInfoAsync = ref.watch(activeFamilyGroupProvider);

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
                    loading: () => _buildHeader(
                      context,
                      themeColors,
                      null,
                      _resolveHeaderTitle(null, user?.id),
                    ),
                    error: (_, _) => _buildHeader(
                      context,
                      themeColors,
                      null,
                      _resolveHeaderTitle(null, user?.id),
                    ),
                    data: (groupInfo) => _buildHeader(
                      context,
                      themeColors,
                      groupInfo,
                      _resolveHeaderTitle(groupInfo, user?.id),
                    ),
                  ),
                  // Group switcher: surfaces the current active context
                  // (personal vs. a group name) and opens a picker. Hidden
                  // entirely when the user belongs to zero groups so it
                  // doesn't add visual noise in personal-only mode.
                  const Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.xs,
                    ),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: GroupSwitcherChip(),
                    ),
                  ),
                Expanded(
                  // Wait for group info to resolve before deciding which tree
                  // to show. This prevents the flicker from personal→shared.
                  child: groupInfoAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    error: (e, st) {
                      debugPrint('TREE-DEBUG groupInfoAsync error: $e\n$st');
                      return _buildError(e);
                    },
                    data: (groupInfo) {
                      // In group mode, merge shared group relatives with the
                      // viewer's OWN personal relatives (family_group_id IS NULL).
                      // Non-admin members add into personal scope (Task A1/A2),
                      // so without this merge their own additions are invisible
                      // from the group tree. RLS keeps the viewer's personal
                      // rows hidden from other members.
                      final relativesAsync = groupInfo != null
                          ? ref.watch(groupTreeRelativesProvider(groupInfo.groupId))
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
                          // Unlinked-member banner: when the user is in a
                          // group but hasn't claimed a tree node yet, surface
                          // the identity-claim wizard CTA at the top so they
                          // can re-enter it without going through the public
                          // join link again.
                          final isUnlinkedMember = groupInfo != null &&
                              groupInfo.nodeId == null;

                          // Personal-vs-shared explainer banner: shown
                          // whenever a NON-admin user is in a group AND
                          // hasn't dismissed it for that group. The banner
                          // copy talks about "the admin's additions appear
                          // here" — nonsensical when you ARE the admin, so
                          // we suppress it for them entirely. Triggers the
                          // SharedPreferences load lazily so the prefs read
                          // doesn't block the tree from rendering (skipped
                          // for admins to avoid wasted async work).
                          final isAdminOfThisGroup = groupInfo != null &&
                              groupInfo.role == 'admin';
                          if (groupInfo != null && !isAdminOfThisGroup) {
                            _loadPersonalVsSharedDismissal(groupInfo.groupId);
                          }
                          final showScopeBanner = groupInfo != null &&
                              !isAdminOfThisGroup &&
                              _personalVsSharedDismissed[groupInfo.groupId] ==
                                  false;

                          return Column(
                            children: [
                              if (showScopeBanner)
                                _buildPersonalVsSharedBanner(
                                    context, groupInfo.groupId),
                              if (isUnlinkedMember)
                                _buildUnlinkedMemberBanner(
                                    context, groupInfo.groupId),
                              Expanded(
                                child: _buildTreeContent(
                                  context,
                                  relatives,
                                  displayName,
                                  userId,
                                ),
                              ),
                            ],
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                        error: (e, st) {
                          debugPrint('TREE-DEBUG relativesAsync error: $e\n$st');
                          return _buildError(e);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Floating zoom controls — bottom offset clears the persistent nav.
          Positioned(
            bottom: PersistentBottomNav.totalHeight + AppSpacing.sm,
            right: AppSpacing.md,
            child: SafeArea(
              child: _buildZoomControls(),
            ),
          ),
          // FAB fallback — manual add button. Same nav-clearance offset.
          Positioned(
            bottom: PersistentBottomNav.totalHeight + AppSpacing.sm,
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

  /// Resolves the header title reactively based on the active group.
  ///
  /// - Personal mode (no active group): "شجرتي" — matches the switcher chip.
  /// - Group mode: the active group's name from [userGroupsProvider].
  /// - Loading / stale states: generic "شجرة العائلة" fallback.
  String _resolveHeaderTitle(
    ({String groupId, String? nodeId, String? role})? groupInfo,
    String? userId,
  ) {
    if (groupInfo == null) {
      // Personal mode — mirror the switcher's wording.
      return 'شجرتي';
    }
    if (userId == null || userId.isEmpty) return 'شجرة العائلة';
    final groups = ref.watch(userGroupsProvider(userId)).valueOrNull;
    if (groups == null) {
      // Loading — generic placeholder until the list resolves.
      return 'شجرة العائلة';
    }
    for (final g in groups) {
      if (g.id == groupInfo.groupId) return g.name;
    }
    // Stale (user no longer in that group) — safe fallback.
    return 'شجرة العائلة';
  }

  Widget _buildHeader(
    BuildContext context,
    dynamic themeColors,
    ({String groupId, String? nodeId, String? role})? groupInfo,
    String title,
  ) {
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
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.home);
                }
              },
              icon: DirectionalIcon(Icons.arrow_back_ios_rounded, color: themeColors.textOnGradient),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: groupInfo != null
                ? GestureDetector(
                    onTap: () => context.push(
                        '${AppRoutes.familyGroupDetail}/${groupInfo.groupId}'),
                    child: Row(
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              title,
                              style: AppTypography.headlineMedium.copyWith(
                                color: themeColors.textOnGradient,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 24,
                          color: themeColors.textOnGradient,
                        ),
                      ],
                    ),
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.center,
                    child: Text(
                      title,
                      style: AppTypography.headlineMedium.copyWith(
                        color: themeColors.textOnGradient,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
          ),
          if (groupInfo == null)
            Semantics(
              label: 'إنشاء مجموعة عائلية',
              button: true,
              child: IconButton(
                onPressed: () => context.push(AppRoutes.createFamilyGroup),
                icon: Icon(Icons.group_add_rounded, color: themeColors.textOnGradient),
                tooltip: 'إنشاء مجموعة عائلية ✨',
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
            // 44×44 minimum tap target — Material default applies.
            padding: const EdgeInsets.all(AppSpacing.xs),
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
            // 44×44 minimum tap target — Material default applies.
            padding: const EdgeInsets.all(AppSpacing.xs),
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
            // 44×44 minimum tap target — Material default applies.
            padding: const EdgeInsets.all(AppSpacing.xs),
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
    RelationshipType? selectedType;
    FamilySide? selectedSide;
    Gender? selectedGender;

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
                      child: FlatRelationshipPicker(
                        selectedType: selectedType ?? RelationshipType.other,
                        selectedSide: selectedSide,
                        selectedGender: selectedGender,
                        existingRelatives: relatives,
                        onSelectionChanged: (type, side, gender) {
                          setSheetState(() {
                            selectedType = type;
                            selectedSide = side;
                            selectedGender = gender;
                          });
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

    final chosenType = selectedType ?? RelationshipType.other;
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
    final gender = selectedGender ?? RelationshipInferenceService.inferGender(fullName.trim());
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
    final groupInfo = ref.watch(activeFamilyGroupProvider).valueOrNull;
    final graph = groupInfo != null
        ? ref.watch(sharedFamilyGraphProvider((
            groupId: groupInfo.groupId,
            viewerNodeId: groupInfo.nodeId,
          )))
        : ref.watch(familyGraphProvider(userId));

    // For shared trees, use the viewer's node ID as the layout anchor.
    // For personal mode, look up the user's personal NULL-scope self-node
    // and use its relative.id — the graph uses relative ids as node ids,
    // not auth user UUIDs. Falling back to userId would leave the viewer
    // off-graph, breaking perspective-aware labels (every relative would
    // be labeled with its own full_name instead of a relationship).
    // Final `?? userId` is a defensive fallback for users without a
    // personal self-node (backfill should guarantee one).
    String? personalSelfId;
    for (final r in relatives) {
      if (r.isSelf && r.familyGroupId == null && r.userId == userId) {
        personalSelfId = r.id;
        break;
      }
    }
    final effectiveUserId = groupInfo?.nodeId ?? personalSelfId ?? userId;

    // In group mode, wait for the shared graph before rendering.
    // Without the graph, _inferGraph creates wrong edges from the adder's
    // relationship types (e.g. uncle's wife appears as viewer's wife).
    // 10-second timeout — without it the spinner ran forever on stream
    // failures (audit Cat 8 finding).
    if (groupInfo != null && graph == null) {
      if (_graphLoadTimedOut) {
        return _buildGraphLoadTimeoutState(groupInfo.groupId);
      }
      // Schedule the timer in a post-frame callback so we don't call
      // setState during build.
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _armGraphTimeout());
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    // Graph arrived — clear any pending timeout state.
    if (graph != null && (_graphTimeoutTimer != null || _graphLoadTimedOut)) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _resetGraphTimeout());
    }

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
      // Personal mode: filter out self-nodes that live in other group scopes.
      // The user's personal NULL-scope self-node survives as the anchor; the
      // in-group self-nodes from any groups they belong to are not part of
      // their personal tree.
      visibleRelatives = relatives
          .where((r) => !r.isSelf || r.familyGroupId == null)
          .toList();
    }

    final relativesMap = {for (final r in visibleRelatives) r.id: r};

    // Fetch linked member node IDs for badge rendering
    final linkedMemberNodeIds = groupInfo != null
        ? ref.watch(groupMemberNodeIdsProvider(groupInfo.groupId)).valueOrNull ?? <String>{}
        : <String>{};

    // Prefer stored gender from self-node, fall back to name inference
    final selfNode = relatives.where((r) => r.isSelf).firstOrNull;
    final userGender = selfNode?.gender ??
        RelationshipInferenceService.inferGender(userName);



    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(
          max(constraints.maxWidth, 400),
          max(constraints.maxHeight, 600),
        );

        // Compute layout from graph (includes placeholder positions)
        final rawLayout = FamilyTreeLayoutService.computeLayout(
          userId: effectiveUserId,
          userName: userName,
          graph: graph,
          relatives: visibleRelatives,
          relativesMap: relativesMap,
          canvasSize: canvasSize,
          userGender: userGender,
          linkedMemberNodeIds: linkedMemberNodeIds,
        );

        // Enrich nodes with pending-claim flags so admin can spot claim
        // targets at a glance (Phase 4 of identity-claim design). Only when
        // the viewer is admin of the shared group — RPC RLS would deny
        // for non-admins anyway, but skip the watch to avoid the request.
        final pendingClaimIds = groupInfo != null
            ? (ref.watch(groupPendingClaimsProvider(groupInfo.groupId))
                    .valueOrNull
                    ?.map((c) => c.claimedRelativeId)
                    .whereType<String>()
                    .toSet() ??
                <String>{})
            : <String>{};

        // Hide "add relative" placeholder leaves for non-admin members in
        // shared groups. They can only add personal relatives, and showing
        // the shared-tree placeholders implies they'd add to the shared
        // lineage. Cleaner UX without them — admins keep theirs.
        final isNonAdminInGroup =
            groupInfo != null && groupInfo.role != 'admin';

        final enrichedNodes = pendingClaimIds.isEmpty
            ? rawLayout.nodes
            : rawLayout.nodes
                .map((n) => pendingClaimIds.contains(n.id)
                    ? n.copyWith(hasPendingClaim: true)
                    : n)
                .toList();

        final layout = (pendingClaimIds.isEmpty && !isNonAdminInGroup)
            ? rawLayout
            : FamilyTreeLayout(
                nodes: enrichedNodes,
                edges: rawLayout.edges,
                junctions: rawLayout.junctions,
                placeholders:
                    isNonAdminInGroup ? const [] : rawLayout.placeholders,
                bounds: rawLayout.bounds,
                userPosition: rawLayout.userPosition,
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

        return RepaintBoundary(
          child: Stack(
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
                          showPlaceholders: true,
                        ),
                      ),
                    ),
                    // Layer 2: Placeholder widgets (below filled nodes)
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
            // Persistent corner brand — small enough to be unobtrusive,
            // present on every screenshot so the user can't accidentally
            // share an unbranded image.
            _buildCornerBrand(),
          ],
        ),
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
      // 1. Try local resolution first (covers ~95% of cases)
      var nameGender = placeholder.expectedGender ??
          RelationshipInferenceService.inferGender(fullName);

      // 2. LAST RESORT: AI only if local returned null
      nameGender ??= await RelationshipInferenceService.inferGenderWithAI(fullName);

      // 3. Adjust relationship type to match gender (brother → sister if female)
      final adjustedType = RelationshipInferenceService.adjustRelationshipForGender(
        placeholder.type, nameGender,
      );

      // 4. Final gender from adjusted type
      final gender = RelationshipInferenceService.resolveGender(
        relationshipType: adjustedType,
        storedGender: placeholder.expectedGender,
        fullName: fullName,
      );

      final avatarType = AvatarType.suggestFromRelationship(
        adjustedType,
        gender,
      );
      final priority = AvatarType.suggestPriority(adjustedType);

      // Check if we're in a family group context
      final groupInfo = ref.read(activeFamilyGroupProvider).valueOrNull;
      final isGroupMode = groupInfo != null;

      final relative = Relative(
        id: '',
        userId: userId,
        fullName: fullName,
        relationshipType: adjustedType,
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

  /// Persistent corner brand badge — always rendered so any phone-level
  /// screenshot or in-app share inherits the logo. Sits bottom-right above
  /// the bottom nav, glass-styled to read as part of the UI rather than a
  /// loud watermark.
  Widget _buildCornerBrand() {
    return Positioned(
      right: AppSpacing.md,
      bottom: PersistentBottomNav.totalHeight + AppSpacing.md,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.islamicGreenDark.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/app_icon.png',
                  width: 22,
                  height: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'صِلْني',
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
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

  /// Dismissible explainer surfaced at the top of the family-tree screen
  /// whenever the user is viewing a group's tree. Explains the
  /// personal-vs-shared scope model so users understand:
  ///   - admin's additions appear in the shared tree
  ///   - their personal additions stay personal (only they see them)
  ///
  /// Dismissal is persisted per-group in [SharedPreferences] so it doesn't
  /// re-appear on every visit, but a fresh context (new group) re-shows it.
  Widget _buildPersonalVsSharedBanner(BuildContext context, String groupId) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          onTap: () => _dismissPersonalVsSharedBanner(groupId),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.md),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.30),
                width: 1.2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.groups_rounded,
                    color: Colors.white,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'أنت داخل عائلة مشتركة',
                          style: AppTypography.titleSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'الإضافات الجديدة من المسؤول ستظهر هنا. أضف '
                          'أقاربك الخاصين بحرية — لن يظهروا للأعضاء الآخرين '
                          'لأن أقاربك قد لا يكونون أقاربهم.',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.78),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Semantics(
                    label: 'إخفاء',
                    button: true,
                    child: InkResponse(
                      onTap: () => _dismissPersonalVsSharedBanner(groupId),
                      radius: 20,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white.withValues(alpha: 0.85),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Banner surfaced at the top of the family-tree screen when the user
  /// is a group member but their `relative_id_in_tree` is null. Two
  /// flavors:
  ///   - has a pending claim → "في انتظار تأكيد المسؤول" (no tap action,
  ///     they already submitted; gives a "cancel and re-pick" affordance)
  ///   - no pending claim    → "حدد مكانك في الشجرة" CTA → wizard
  Widget _buildUnlinkedMemberBanner(BuildContext context, String groupId) {
    final myClaimsAsync = ref.watch(myPendingClaimsProvider);
    final pendingForThisGroup = myClaimsAsync.valueOrNull
            ?.where((c) => c.groupId == groupId)
            .toList() ??
        const [];
    final hasPendingClaim = pendingForThisGroup.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          onTap: hasPendingClaim
              ? () => _showPendingClaimSheet(
                    context, groupId, pendingForThisGroup.first)
              : () => context.push('${AppRoutes.identityClaim}/$groupId'),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.md),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.30),
                width: 1.2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    hasPendingClaim
                        ? Icons.hourglass_top_rounded
                        : Icons.account_tree_rounded,
                    color: Colors.white,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasPendingClaim
                              ? 'في انتظار تأكيد المسؤول'
                              : 'حدد مكانك في الشجرة',
                          style: AppTypography.titleSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          hasPendingClaim
                              ? 'تم إرسال طلبك — اضغط لإلغائه أو تعديله'
                              : 'لم يتم تحديد مكانك بعد — اضغط للبدء',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Bottom sheet shown when joiner taps the "pending claim" banner —
  /// summary of what they submitted plus a button to cancel-and-restart.
  Future<void> _showPendingClaimSheet(
    BuildContext context,
    String groupId,
    NodeClaim claim,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  'طلبك قيد المراجعة',
                  style: AppTypography.titleLarge
                      .copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                claim.proposedFullName != null
                    ? 'أرسلت طلب إضافة "${claim.proposedFullName}" للشجرة'
                    : 'أرسلت طلب تأكيد مكانك في الشجرة',
                style: AppTypography.bodyMedium
                    .copyWith(color: Colors.white.withValues(alpha: 0.85)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.tonalIcon(
                onPressed: () async {
                  Navigator.of(sheetCtx).pop();
                  try {
                    await ref
                        .read(nodeClaimServiceProvider)
                        .cancelClaim(claim.id);
                    ref.invalidate(myPendingClaimsProvider);
                    if (!context.mounted) return;
                    UIHelpers.showSnackBar(
                        context, 'تم إلغاء الطلب');
                    // Push wizard so they can re-pick fresh.
                    context.push('${AppRoutes.identityClaim}/$groupId');
                  } catch (e) {
                    if (!context.mounted) return;
                    UIHelpers.showSnackBar(
                        context, 'تعذّر إلغاء الطلب: $e',
                        isError: true);
                  }
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إلغاء الطلب وإعادة الاختيار'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => Navigator.of(sheetCtx).pop(),
                child: const Text('متابعة الانتظار',
                    style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError([Object? error]) {
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
            if (error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              SelectableText(
                error.toString(),
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        icon: DirectionalIcon(Icons.arrow_back_ios_rounded, color: themeColors.textOnGradient),
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
                    builder: (_) => PaywallScreen(
                      featureToUnlock: FeatureIds.familyTree,
                      contextHeadline: PaywallContext.headlineForFeature(FeatureIds.familyTree),
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
