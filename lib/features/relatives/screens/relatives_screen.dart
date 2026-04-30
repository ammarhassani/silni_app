import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glass_pill_title.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/swipeable_relative_card.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/models/interaction_model.dart';
import '../../../core/providers/cache_provider.dart';
import '../../../core/providers/relative_streak_provider.dart';
import '../../../core/router/app_routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/home_providers.dart';
import '../../../core/providers/realtime_provider.dart';
import '../../../shared/widgets/premium_loading_indicator.dart';
import '../../../shared/widgets/message_widget.dart';
import '../../../shared/utils/relationship_label_helper.dart';
import '../../family_tree/providers/family_graph_providers.dart';
import '../../../shared/widgets/persistent_bottom_nav.dart';

class RelativesScreen extends ConsumerStatefulWidget {
  const RelativesScreen({super.key});

  @override
  ConsumerState<RelativesScreen> createState() => _RelativesScreenState();
}

class _RelativesScreenState extends ConsumerState<RelativesScreen> {
  String _searchQuery = '';
  String _filterType = 'all'; // all, needs_contact, favorites
  RelativeCategory? _categoryFilter; // null = all categories
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Relative> _filterRelatives(List<Relative> relatives, {String? viewerNodeId}) {
    // Exclude the viewer's own node (they shouldn't see themselves in the list).
    // In shared groups, OTHER members' self-nodes are real relatives and must stay.
    var filtered = relatives.where((r) => r.id != viewerNodeId).toList();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((r) {
        return r.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            r.relationshipType.arabicName.contains(_searchQuery);
      }).toList();
    }

    // Apply type filter
    switch (_filterType) {
      case 'needs_contact':
        filtered = filtered.where((r) => r.needsContact).toList();
        break;
      case 'favorites':
        filtered = filtered.where((r) => r.isFavorite).toList();
        break;
      default:
        break;
    }

    // Apply category filter
    if (_categoryFilter != null) {
      filtered = filtered.where((r) => r.relativeCategory == _categoryFilter).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);

    // Initialize real-time subscriptions for this user
    ref.watch(autoRealtimeSubscriptionsProvider);

    // Rahim-scoped + self-node-filtered relatives via central provider
    final groupInfo = ref.watch(userFamilyGroupProvider).valueOrNull;
    final relativesAsync = ref.watch(viewerFilteredRelativesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Semantics(
        label: 'قائمة الأقارب',
        child: Stack(
          children: [
            // Main content
            SafeArea(
              bottom: false,
              child: Column(
                  children: [
                    // Header + Search (compact)
                    _buildHeader(context, themeColors),

                    // Search bar
                    _buildSearchBar(themeColors),

                    // Combined filter chips (single scrollable row)
                    _buildCombinedFilters(themeColors),

                    // In-App Messages (minimal padding)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: MessageWidget(screenPath: '/relatives'),
                    ),

                    // Relatives list
                    Expanded(
                      child: relativesAsync.when(
                        data: (relatives) {
                          final filteredRelatives = _filterRelatives(relatives, viewerNodeId: groupInfo?.nodeId);

                          if (relatives.isEmpty) {
                            return _buildEmptyState(context, themeColors);
                          }

                          if (filteredRelatives.isEmpty) {
                            return _buildNoResults(themeColors);
                          }

                          return _buildRelativesList(filteredRelatives);
                        },
                        loading: () => const Center(
                          child: PremiumLoadingIndicator(
                            message: 'جاري تحميل الأقارب...',
                          ),
                        ),
                        error: (error, stack) =>
                            _buildErrorState(error.toString(), themeColors),
                      ),
                    ),
                  ],
              ),
            ),
            // Glassmorphism FAB positioned on left
            Positioned(
              bottom: 130, // Above floating navigation bar
              left: 20, // Left side instead of right
              child: _buildGlassmorphismFAB(context, themeColors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic themeColors) {
    return Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.xs,
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.xs,
          ),
          child: Row(
            children: [
              const SizedBox(width: AppSpacing.sm),
              const GlassPillTitle(text: 'الأقارب'),
              const Spacer(),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: AppAnimations.modal)
        .slideY(begin: -0.2, end: 0);
  }

  Widget _buildSearchBar(dynamic themeColors) {
    return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Semantics(
            label: 'البحث عن قريب',
            textField: true,
            child: GlassCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 4,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: AppTypography.bodyMedium.copyWith(color: themeColors.textOnGradient),
                decoration: InputDecoration(
                  hintText: 'ابحث عن قريب...',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: themeColors.textOnGradient.withValues(alpha: 0.6),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: themeColors.primary.withValues(alpha: 0.8),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: themeColors.primary.withValues(alpha: 0.8),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
          ),
        )
        .animate(delay: AppAnimations.fast)
        .fadeIn(duration: AppAnimations.normal)
        .slideX(begin: 0.2, end: 0);
  }

  Widget _buildCombinedFilters(dynamic themeColors) {
    return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            children: [
              // Type filters
              _buildChip('الكل', isSelected: _filterType == 'all' && _categoryFilter == null, onTap: () {
                setState(() { _filterType = 'all'; _categoryFilter = null; });
              }, themeColors: themeColors),
              const SizedBox(width: 8),
              _buildChip('يحتاجون تواصل', isSelected: _filterType == 'needs_contact', onTap: () {
                setState(() { _filterType = _filterType == 'needs_contact' ? 'all' : 'needs_contact'; });
              }, themeColors: themeColors),
              const SizedBox(width: 8),
              _buildChip('المفضلة', isSelected: _filterType == 'favorites', onTap: () {
                setState(() { _filterType = _filterType == 'favorites' ? 'all' : 'favorites'; });
              }, themeColors: themeColors),
              const SizedBox(width: 12),
              // Divider
              Center(
                child: Container(
                  width: 1,
                  height: 20,
                  color: themeColors.textOnGradient.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(width: 12),
              // Category filters
              _buildChip('🏠 أهل البيت', isSelected: _categoryFilter == RelativeCategory.household, onTap: () {
                setState(() { _categoryFilter = _categoryFilter == RelativeCategory.household ? null : RelativeCategory.household; });
              }, themeColors: themeColors),
              const SizedBox(width: 8),
              _buildChip('📞 ممتدة', isSelected: _categoryFilter == RelativeCategory.extended, onTap: () {
                setState(() { _categoryFilter = _categoryFilter == RelativeCategory.extended ? null : RelativeCategory.extended; });
              }, themeColors: themeColors),
              const SizedBox(width: 8),
              _buildChip('🌙 مناسبات', isSelected: _categoryFilter == RelativeCategory.distant, onTap: () {
                setState(() { _categoryFilter = _categoryFilter == RelativeCategory.distant ? null : RelativeCategory.distant; });
              }, themeColors: themeColors),
              const SizedBox(width: AppSpacing.md),
            ],
          ),
        ),
        )
        .animate(delay: AppAnimations.modal)
        .fadeIn(duration: AppAnimations.normal);
  }

  Widget _buildChip(String label, {required bool isSelected, required VoidCallback onTap, required dynamic themeColors}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(colors: [themeColors.primary, themeColors.primaryLight]) : null,
          color: isSelected ? null : themeColors.textOnGradient.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: themeColors.textOnGradient.withValues(alpha: isSelected ? 0.7 : 0.4),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: themeColors.textOnGradient,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRelativesList(List<Relative> relatives) {
    // Watch user ONCE at the list level - not per item (O(1) instead of O(n))
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? '';

    // Watch family graph for perspective-shifting labels (null if no edges yet).
    // In group mode, use the shared graph so labels are relative to the viewer.
    final groupInfo = ref.watch(userFamilyGroupProvider).valueOrNull;
    final graph = groupInfo != null
        ? ref.watch(sharedFamilyGraphProvider((
            groupId: groupInfo.groupId,
            viewerNodeId: groupInfo.nodeId,
          )))
        : ref.watch(familyGraphProvider(userId));
    final effectiveViewerId = groupInfo?.nodeId ?? userId;

    // Build labels map once for the entire list
    Map<String, String>? labelsMap;
    if (graph != null) {
      final relativesMap = {for (final r in relatives) r.id: r};
      labelsMap = {
        for (final r in relatives)
          r.id: getRelationshipLabel(
            relative: r,
            viewerId: effectiveViewerId,
            graph: graph,
            relativesMap: relativesMap,
          ),
      };
    }

    // One-shot stream of all relative streaks → map for O(1) lookup per card.
    final streaks = ref
            .watch(allRelativeStreaksStreamProvider(userId))
            .valueOrNull ??
        const [];
    final streaksByRelative = <String, int>{
      for (final s in streaks) s.relativeId: s.currentStreak,
    };

    // Group relatives by relationship priority
    final Map<int, List<Relative>> grouped = {};
    for (final relative in relatives) {
      grouped.putIfAbsent(relative.priority, () => []).add(relative);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: PersistentBottomNav.totalHeight,
      ),
      itemCount: relatives.length,
      itemBuilder: (context, index) {
        return _buildRelativeCard(
          relatives[index],
          index,
          userId,
          labelsMap,
          streaksByRelative[relatives[index].id],
        );
      },
    );
  }

  Widget _buildRelativeCard(
    Relative relative,
    int index,
    String userId,
    Map<String, String>? labelsMap,
    int? streakDays,
  ) {
    return SwipeableRelativeCard(
          relative: relative,
          relationshipLabel: labelsMap?[relative.id],
          streakDays: streakDays,
          onTap: () {
            context.push('${AppRoutes.relativeDetail}/${relative.id}');
          },
          onMarkContacted: () async {
            // Quick-swipe logs as InteractionType.other rather than .call —
            // the audit caught us silently misattributing every quick
            // contact as a phone call when it might have been a message,
            // visit, or anything else. Users wanting to attribute a
            // specific type tap into the relative detail screen.
            final repository = ref.read(interactionsRepositoryProvider);
            await repository.createInteraction(
              Interaction(
                id: '',
                userId: userId,
                relativeId: relative.id,
                type: InteractionType.other,
                date: DateTime.now(),
                notes: 'تواصل سريع',
                createdAt: DateTime.now(),
              ),
            );
          },
        )
        .animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn()
        .slideX(begin: 0.2, end: 0);
  }

  Widget _buildEmptyState(BuildContext context, dynamic themeColors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child:
            Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                          Icons.people_outline,
                          size: 120,
                          color: themeColors.textOnGradient.withValues(alpha: 0.5),
                        )
                        .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        .scale(
                          duration: AppAnimations.loop,
                          begin: const Offset(1.0, 1.0),
                          end: const Offset(1.1, 1.1),
                        ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'لا يوجد أقارب بعد',
                      style: AppTypography.headlineSmall.copyWith(
                        color: themeColors.textOnGradient,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'ابدأ بإضافة أفراد عائلتك\nوالديك، إخوتك، أجدادك',
                      style: AppTypography.bodyMedium.copyWith(
                        color: themeColors.textOnGradient.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Semantics(
                      label: 'إضافة أول قريب',
                      button: true,
                      child: GradientButton(
                        text: 'إضافة أول قريب',
                        onPressed: () => context.push(AppRoutes.addRelative),
                        icon: Icons.person_add,
                      ),
                    ),
                  ],
                )
                .animate()
                .fadeIn(duration: AppAnimations.slow)
                .slideY(begin: 0.2, end: 0),
      ),
    );
  }

  Widget _buildNoResults(dynamic themeColors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 80,
            color: themeColors.textOnGradient.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'لا توجد نتائج',
            style: AppTypography.titleLarge.copyWith(color: themeColors.textOnGradient),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'جرب البحث بكلمة أخرى',
            style: AppTypography.bodyMedium.copyWith(
              color: themeColors.textOnGradient.withValues(alpha: 0.7),
            ),
          ),
        ],
      ).animate().fadeIn(duration: AppAnimations.normal).scale(),
    );
  }

  Widget _buildErrorState(String error, dynamic themeColors) {
    // Pattern mirrors reminders_screen._buildError (audit gold-standard):
    // clear Arabic copy + connectivity hint + retry that invalidates the
    // upstream provider. The raw Dart exception string is no longer
    // shown — it leaked SocketException, etc., into the UI.
    final user = ref.read(currentUserProvider);
    return Center(
      child: GlassCard(
        margin: const EdgeInsets.all(AppSpacing.xl),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: themeColors.textOnGradient,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'حدث خطأ في تحميل الأقارب',
              style: AppTypography.bodyLarge
                  .copyWith(color: themeColors.textOnGradient),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'يرجى التحقق من الاتصال بالإنترنت والمحاولة مرة أخرى',
              style: AppTypography.bodySmall.copyWith(
                color: themeColors.textOnGradient.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            GradientButton(
              onPressed: () {
                if (user != null) {
                  ref.invalidate(relativesStreamProvider(user.id));
                }
              },
              text: 'إعادة المحاولة',
              icon: Icons.refresh_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassmorphismFAB(BuildContext context, dynamic themeColors) {
    return Semantics(
      label: 'إضافة قريب جديد',
      button: true,
      child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.premiumGold,
                  AppColors.joyfulOrange,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.premiumGold.withValues(alpha: 0.5),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () {
                  context.push(AppRoutes.addRelative);
                },
                child: Center(
                  child: Icon(
                    Icons.add_rounded,
                    color: themeColors.textOnGradient,
                    size: 28,
                  ),
                ),
              ),
            ),
          )
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scale(
            duration: AppAnimations.loop,
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.05, 1.05),
          )
          .animate()
          .fadeIn(duration: AppAnimations.slow),
    );
  }
}
