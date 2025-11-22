import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/services/relatives_service.dart';
import '../../auth/providers/auth_provider.dart';

// Provider for relatives service
final relativesServiceProvider = Provider((ref) => RelativesService());

// Provider for relatives stream
final relativesStreamProvider = StreamProvider.family<List<Relative>, String>((ref, userId) {
  final service = ref.watch(relativesServiceProvider);
  return service.getRelativesStream(userId);
});

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
    final userId = user?.uid ?? '';
    final relativesAsync = ref.watch(relativesStreamProvider(userId));

    return Scaffold(
      body: GradientBackground(
        animated: true,
        child: SafeArea(
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
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  error: (error, stack) => _buildErrorState(error.toString()),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
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
              color: Colors.white.withOpacity(0.5),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.white.withOpacity(0.7),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: Colors.white.withOpacity(0.7),
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
      child: Row(
        children: [
          _buildFilterChip('الكل', 'all'),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip('يحتاجون تواصل', 'needs_contact'),
          const SizedBox(width: AppSpacing.sm),
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
          gradient: isSelected
              ? AppColors.primaryGradient
              : null,
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
    final needsAttention = relative.needsContact;
    final daysSince = relative.daysSinceLastContact ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        onTap: () {
          // TODO: Navigate to relative detail
        },
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: needsAttention
                        ? AppColors.streakFire
                        : AppColors.primaryGradient,
                  ),
                  child: relative.photoUrl != null
                      ? ClipOval(
                          child: Image.network(
                            relative.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildDefaultAvatar(relative),
                          ),
                        )
                      : _buildDefaultAvatar(relative),
                ),
                if (relative.isFavorite)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.premiumGold,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          relative.fullName,
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          relative.relationshipType.arabicName,
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        relative.lastContactDate == null
                            ? Icons.phone_disabled
                            : Icons.phone,
                        size: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          relative.lastContactDate == null
                              ? 'لم تتواصل معه بعد'
                              : 'آخر تواصل: منذ $daysSince يوم',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                      if (needsAttention)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.joyfulOrange,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Text(
                            'حان وقت التواصل',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.5),
              size: 20,
            ),
          ],
        ),
      ),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 120,
              color: Colors.white.withOpacity(0.5),
            )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
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
            style: AppTypography.titleLarge.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'جرب البحث بكلمة أخرى',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      )
          .animate()
          .fadeIn()
          .scale(),
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
            style: AppTypography.titleLarge.copyWith(
              color: Colors.white,
            ),
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

  Widget _buildFAB(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.goldenGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.premiumGold.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 3,
          ),
        ],
      ),
      child: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: () {
          // TODO: Navigate to add relative
        },
        child: const Icon(
          Icons.person_add_rounded,
          size: 28,
          color: Colors.white,
        ),
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        )
        .scale(
          duration: const Duration(seconds: 2),
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.05, 1.05),
        );
  }
}
