import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/swipeable_relative_card.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/models/interaction_model.dart';
import '../../../shared/providers/interactions_provider.dart';
import '../../../core/router/app_routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/screens/home_screen.dart';
import '../../../core/providers/realtime_provider.dart';

// Note: relativesServiceProvider is now imported from shared/services/relatives_service.dart
// Note: interactionsServiceProvider is now imported from shared/providers/interactions_provider.dart
// Note: relativesStreamProvider is now imported from features/home/screens/home_screen.dart

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

    // Initialize real-time subscriptions for this user
    ref.watch(autoRealtimeSubscriptionsProvider);

    final relativesAsync = ref.watch(relativesStreamProvider(userId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Column(
                children: [
                  // Header
                  _buildHeader(context),

                  // Search bar
                  _buildSearchBar(),

                  // Filter chips
                  _buildFilterChips(),

                  // Relatives list
                  Expanded(
                    child: relativesAsync.when(
                      data: (relatives) {
                        final filteredRelatives = _filterRelatives(relatives);

                        if (relatives.isEmpty) {
                          return _buildEmptyState(context);
                        }

                        if (filteredRelatives.isEmpty) {
                          return _buildNoResults();
                        }

                        return _buildRelativesList(filteredRelatives);
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      error: (error, stack) =>
                          _buildErrorState(error.toString()),
                    ),
                  ),
                ],
            ),
          ),
          // Glassmorphism FAB positioned on left
          Positioned(
            bottom: 100, // Above navigation bar
            left: 20, // Left side instead of right
            child: _buildGlassmorphismFAB(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const SizedBox(width: AppSpacing.sm),
              Text(
                'الأقارب',
                style: AppTypography.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 400))
        .slideY(begin: -0.2, end: 0);
  }

  Widget _buildSearchBar() {
    // Use theme-aware colors
    final themeColors = ref.watch(themeColorsProvider);

    return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'ابحث عن قريب...',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.6),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: themeColors.primary.withOpacity(0.8),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: themeColors.primary.withOpacity(0.8),
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
                filled: false, // Make background transparent
              ),
            ),
          ),
        )
        .animate(delay: const Duration(milliseconds: 200))
        .fadeIn()
        .slideX(begin: 0.2, end: 0);
  }

  Widget _buildFilterChips() {
    return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _buildFilterChip('الكل', 'all'),
              _buildFilterChip('يحتاجون تواصل', 'needs_contact'),
              _buildFilterChip('المفضلة', 'favorites'),
            ],
          ),
        )
        .animate(delay: const Duration(milliseconds: 400))
        .fadeIn()
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;

    return GestureDetector(
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
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: Colors.white.withOpacity(isSelected ? 0.5 : 0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRelativesList(List<Relative> relatives) {
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
        return _buildRelativeCard(relatives[index], index);
      },
    );
  }

  Widget _buildRelativeCard(Relative relative, int index) {
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? '';

    return SwipeableRelativeCard(
          relative: relative,
          onTap: () {
            context.push('${AppRoutes.relativeDetail}/${relative.id}');
          },
          onMarkContacted: () async {
            final interactionsService = ref.read(interactionsServiceProvider);
            await interactionsService.createInteraction(
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

  Widget _buildDefaultAvatar(Relative relative) {
    return Center(
      child: Text(
        relative.fullName.isNotEmpty ? relative.fullName[0] : '؟',
        style: AppTypography.headlineMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
                          color: Colors.white.withOpacity(0.5),
                        )
                        .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        .scale(
                          duration: const Duration(seconds: 2),
                          begin: const Offset(1.0, 1.0),
                          end: const Offset(1.1, 1.1),
                        ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'لا يوجد أقارب بعد',
                      style: AppTypography.headlineSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'ابدأ بإضافة أفراد عائلتك\nوالديك، إخوتك، أجدادك',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    GradientButton(
                      text: 'إضافة أول قريب',
                      onPressed: () {
                        // TODO: Navigate to add relative
                      },
                      icon: Icons.person_add,
                    ),
                  ],
                )
                .animate()
                .fadeIn(duration: const Duration(milliseconds: 600))
                .slideY(begin: 0.2, end: 0),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 80,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'لا توجد نتائج',
            style: AppTypography.titleLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'جرب البحث بكلمة أخرى',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ).animate().fadeIn().scale(),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: AppColors.error.withOpacity(0.7),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'حدث خطأ',
            style: AppTypography.titleLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            error,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGlassmorphismFAB(BuildContext context) {
    return Container(
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
              child: const Center(
                child: Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          duration: const Duration(seconds: 2),
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.05, 1.05),
        )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 600));
  }
}
