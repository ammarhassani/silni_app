import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/swipeable_relative_card.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/models/interaction_model.dart';
import '../../../core/providers/cache_provider.dart';
import '../../../core/router/app_routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/home_providers.dart';
import '../../../core/providers/realtime_provider.dart';
import '../../../shared/widgets/premium_loading_indicator.dart';
import '../../../shared/widgets/message_widget.dart';

class RelativesScreen extends ConsumerStatefulWidget {
  const RelativesScreen({super.key});

  @override
  ConsumerState<RelativesScreen> createState() => _RelativesScreenState();
}

class _RelativesScreenState extends ConsumerState<RelativesScreen> {
  String _searchQuery = '';
  String _filterType = 'all'; // all, needs_contact, favorites
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Relative> _filterRelatives(List<Relative> relatives) {
    var filtered = relatives;

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

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? '';
    final themeColors = ref.watch(themeColorsProvider);

    // Initialize real-time subscriptions for this user
    ref.watch(autoRealtimeSubscriptionsProvider);

    final relativesAsync = ref.watch(relativesStreamProvider(userId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Semantics(
        label: 'قائمة الأقارب',
        child: Stack(
          children: [
            // Main content
            SafeArea(
              child: Column(
                  children: [
                    // Header
                    _buildHeader(context, themeColors),

                    // In-App Messages
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: MessageWidget(screenPath: '/relatives'),
                    ),

                    // Search bar
                    _buildSearchBar(themeColors),

                    // Filter chips
                    _buildFilterChips(themeColors),

                    // Relatives list
                    Expanded(
                      child: relativesAsync.when(
                        data: (relatives) {
                          final filteredRelatives = _filterRelatives(relatives);

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
            top: AppSpacing.sm,
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.sm,
          ),
          child: Row(
            children: [
              const SizedBox(width: AppSpacing.sm),
              Text(
                'الأقارب',
                style: AppTypography.headlineMedium.copyWith(
                  color: themeColors.textOnGradient,
                  fontWeight: FontWeight.bold,
                ),
              ),
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

  Widget _buildFilterChips(dynamic themeColors) {
    return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _buildFilterChip('الكل', 'all', themeColors),
              _buildFilterChip('يحتاجون تواصل', 'needs_contact', themeColors),
              _buildFilterChip('المفضلة', 'favorites', themeColors),
            ],
          ),
        )
        .animate(delay: AppAnimations.modal)
        .fadeIn(duration: AppAnimations.normal)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildFilterChip(String label, String value, dynamic themeColors) {
    final isSelected = _filterType == value;

    return Semantics(
      label: label,
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _filterType = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            gradient: isSelected ? LinearGradient(colors: [themeColors.primary, themeColors.primaryLight]) : null,
            color: isSelected ? null : themeColors.textOnGradient.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: themeColors.textOnGradient.withValues(alpha: isSelected ? 0.5 : 0.3),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: themeColors.textOnGradient,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRelativesList(List<Relative> relatives) {
    // Watch user ONCE at the list level - not per item (O(1) instead of O(n))
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? '';

    // Group relatives by relationship priority
    final Map<int, List<Relative>> grouped = {};
    for (final relative in relatives) {
      grouped.putIfAbsent(relative.priority, () => []).add(relative);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.xxxl,
      ),
      itemCount: relatives.length,
      itemBuilder: (context, index) {
        return _buildRelativeCard(relatives[index], index, userId);
      },
    );
  }

  Widget _buildRelativeCard(Relative relative, int index, String userId) {
    // userId is now passed from parent - no more O(n) rebuilds!

    return SwipeableRelativeCard(
          relative: relative,
          onTap: () {
            context.push('${AppRoutes.relativeDetail}/${relative.id}');
          },
          onMarkContacted: () async {
            final repository = ref.read(interactionsRepositoryProvider);
            await repository.createInteraction(
              Interaction(
                id: '',
                userId: userId,
                relativeId: relative.id,
                type: InteractionType.call,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: themeColors.statusError.withValues(alpha: 0.7),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'حدث خطأ',
            style: AppTypography.titleLarge.copyWith(color: themeColors.textOnGradient),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            error,
            style: AppTypography.bodySmall.copyWith(
              color: themeColors.textOnGradient.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
