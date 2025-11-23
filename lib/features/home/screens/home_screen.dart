import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import 'package:intl/intl.dart' as intl;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/avatar_carousel.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/models/interaction_model.dart';
import '../../../shared/models/hadith_model.dart';
import '../../../shared/services/relatives_service.dart';
import '../../../shared/services/interactions_service.dart';
import '../../../shared/services/hadith_service.dart';
import '../../auth/providers/auth_provider.dart';

// Providers for relatives and interactions
// keepAlive keeps the provider alive even when no longer watched (caching)
final relativesServiceProvider = Provider((ref) {
  return RelativesService();
});

final interactionsServiceProvider = Provider((ref) {
  return InteractionsService();
});

final hadithServiceProvider = Provider((ref) {
  return HadithService();
});

final relativesStreamProvider = StreamProvider.family<List<Relative>, String>((ref, userId) {
  // Keep provider alive to cache data
  ref.keepAlive();

  final service = ref.watch(relativesServiceProvider);
  return service.getRelativesStream(userId);
});

final todayInteractionsStreamProvider = StreamProvider.family<List<Interaction>, String>((ref, userId) {
  // Keep provider alive to cache data
  ref.keepAlive();

  final service = ref.watch(interactionsServiceProvider);
  return service.getTodayInteractionsStream(userId);
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatingController;
  late ConfettiController _confettiController;
  int _currentIndex = 0;
  Hadith? _dailyHadith;
  bool _isLoadingHadith = true;

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    _loadDailyHadith();
  }

  Future<void> _loadDailyHadith() async {
    final hadithService = ref.read(hadithServiceProvider);
    final hadith = await hadithService.getDailyHadith();
    if (mounted) {
      setState(() {
        _dailyHadith = hadith;
        _isLoadingHadith = false;
      });
    }
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _onNavTapped(int index) {
    setState(() => _currentIndex = index);

    switch (index) {
      case 0:
        // Home - already here
        break;
      case 1:
        context.push(AppRoutes.relatives);
        break;
      case 2:
        context.push(AppRoutes.statistics);
        break;
      case 3:
        context.push(AppRoutes.settings);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final displayName = user?.displayName ?? 'المستخدم';
    final userId = user?.uid ?? '';

    final relativesAsync = ref.watch(relativesStreamProvider(userId));
    final todayInteractionsAsync = ref.watch(todayInteractionsStreamProvider(userId));

    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          const GradientBackground(animated: true, child: SizedBox.expand()),

          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [
                AppColors.islamicGreenPrimary,
                AppColors.premiumGold,
                AppColors.emotionalPurple,
                AppColors.joyfulOrange,
              ],
            ),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Islamic greeting header
                    _buildIslamicHeader(displayName),
                    const SizedBox(height: AppSpacing.xl),

                    // Hadith/Islamic reminder of the day
                    _buildIslamicReminder(),
                    const SizedBox(height: AppSpacing.xl),

                    // Quick Actions
                    _buildQuickActions(),
                    const SizedBox(height: AppSpacing.xl),

                    // Family members circle avatars
                    relativesAsync.when(
                      data: (relatives) => _buildFamilyCircles(relatives),
                      loading: () => const FamilyCirclesSkeleton(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Today's connections
                    todayInteractionsAsync.when(
                      data: (interactions) => _buildTodaysActivity(interactions),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Who needs your call?
                    relativesAsync.when(
                      data: (relatives) => _buildNeedsContact(relatives),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _buildFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildIslamicHeader(String displayName) {
    final hour = DateTime.now().hour;
    String greeting = 'السلام عليكم';
    if (hour < 12) {
      greeting = 'صباح الخير';
    } else if (hour < 18) {
      greeting = 'مساء الخير';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: AppTypography.bodyLarge.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayName,
                    style: AppTypography.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Profile avatar
            GestureDetector(
              onTap: () => context.push(AppRoutes.settings),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.goldenGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.premiumGold.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '"ومن أحب أن يُبسَط له في رزقه، وأن يُنسَأ له في أثره، فليصل رحمه"',
          style: AppTypography.bodySmall.copyWith(
            color: Colors.white.withOpacity(0.8),
            fontStyle: FontStyle.italic,
            height: 1.6,
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 600))
        .slideY(begin: -0.1, end: 0);
  }

  Widget _buildIslamicReminder() {
    if (_isLoadingHadith) {
      return GlassCard(
        gradient: LinearGradient(
          colors: [
            AppColors.islamicGreenPrimary.withOpacity(0.2),
            AppColors.premiumGold.withOpacity(0.1),
          ],
        ),
        child: const HadithSkeletonLoader(),
      );
    }

    if (_dailyHadith == null) {
      return const SizedBox.shrink();
    }

    final hadith = _dailyHadith!;

    return GlassCard(
      gradient: LinearGradient(
        colors: [
          AppColors.islamicGreenPrimary.withOpacity(0.3),
          AppColors.premiumGold.withOpacity(0.2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.goldenGradient,
                ),
                child: const Center(
                  child: Text(
                    '📿',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hadith.type == HadithType.hadith ? 'حديث اليوم' : 'قول العلماء',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.premiumGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (hadith.formattedSource.isNotEmpty)
                      Text(
                        hadith.formattedSource,
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Hadith text
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: AppColors.premiumGold.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              hadith.arabicText,
              style: AppTypography.titleMedium.copyWith(
                color: Colors.white,
                height: 1.8,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.justify,
            ),
          ),

          // Reference
          if (hadith.reference.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.book,
                  size: 14,
                  color: Colors.white.withOpacity(0.6),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  hadith.reference,
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    )
        .animate(delay: const Duration(milliseconds: 200))
        .fadeIn()
        .slideX(begin: 0.2, end: 0);
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'إجراءات سريعة',
          style: AppTypography.headlineSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.notifications_active_rounded,
                title: 'التذكيرات',
                subtitle: 'نظّم تذكيراتك',
                gradient: AppColors.primaryGradient,
                onTap: () => context.push(AppRoutes.reminders),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.assessment_rounded,
                title: 'الإحصائيات',
                subtitle: 'تقدمك اليومي',
                gradient: LinearGradient(
                  colors: [
                    AppColors.emotionalPurple.withOpacity(0.6),
                    AppColors.calmBlue.withOpacity(0.4),
                  ],
                ),
                onTap: () => context.push(AppRoutes.statistics),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.account_tree_rounded,
                title: 'شجرة العائلة',
                subtitle: 'تصور جميل لعائلتك',
                gradient: LinearGradient(
                  colors: [
                    AppColors.islamicGreenDark,
                    AppColors.islamicGreenPrimary.withOpacity(0.8),
                  ],
                ),
                onTap: () => context.push(AppRoutes.familyTree),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: const SizedBox()),
          ],
        ),
      ],
    ).animate(delay: const Duration(milliseconds: 300)).fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        gradient: gradient,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyCircles(List<Relative> relatives) {
    if (relatives.isEmpty) {
      return _buildEmptyState();
    }

    // Show first 8 relatives in carousel
    final displayRelatives = relatives.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'عائلتك',
              style: AppTypography.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.relatives),
              child: Row(
                children: [
                  Text(
                    'عرض الكل',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AvatarCarousel(
          relatives: displayRelatives,
          onAddRelative: () => context.push(AppRoutes.addRelative),
        ),
      ],
    )
        .animate(delay: const Duration(milliseconds: 400))
        .fadeIn()
        .slideY(begin: 0.2, end: 0);
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

  Widget _buildEmptyState() {
    return GlassCard(
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'ابدأ بإضافة أفراد عائلتك',
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'أضف والديك، إخوتك، أجدادك وباقي أقاربك',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          GradientButton(
            text: 'إضافة أول قريب',
            onPressed: () {
              // TODO: Navigate to add relative
            },
            icon: Icons.person_add,
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysActivity(List<Interaction> interactions) {
    if (interactions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تواصل اليوم',
          style: AppTypography.headlineSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: interactions.take(3).length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final interaction = interactions[index];
            return _buildInteractionCard(interaction);
          },
        ),
      ],
    );
  }

  Widget _buildInteractionCard(Interaction interaction) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: Center(
              child: Text(
                interaction.type.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  interaction.type.arabicName,
                  style: AppTypography.titleSmall.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  interaction.relativeTime,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeedsContact(List<Relative> allRelatives) {
    // Don't show anything if there are no relatives at all
    if (allRelatives.isEmpty) {
      return const SizedBox.shrink();
    }

    final needsContact = allRelatives.where((r) => r.needsContact).take(3).toList();

    if (needsContact.isEmpty) {
      return GlassCard(
        gradient: LinearGradient(
          colors: [
            AppColors.islamicGreenLight.withOpacity(0.3),
            AppColors.premiumGold.withOpacity(0.2),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ممتاز! 🎉',
                    style: AppTypography.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'تواصلت مع جميع أقاربك مؤخراً',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'يحتاجون تواصلك ❤️',
          style: AppTypography.headlineSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: needsContact.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            return _buildNeedsContactCard(needsContact[index]);
          },
        ),
      ],
    );
  }

  Widget _buildNeedsContactCard(Relative relative) {
    final daysSince = relative.daysSinceLastContact ?? 0;

    return GestureDetector(
      onTap: () {
        context.push('${AppRoutes.relativeDetail}/${relative.id}');
      },
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.streakFire,
            ),
            child: relative.photoUrl != null
                ? ClipOval(
                    child: Image.network(
                      relative.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildDefaultAvatar(relative),
                    ),
                  )
                : _buildDefaultAvatar(relative),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  relative.fullName,
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  relative.lastContactDate == null
                      ? (relative.gender == Gender.female
                          ? 'لم تتواصل معها بعد'
                          : 'لم تتواصل معه بعد')
                      : 'آخر تواصل: منذ $daysSince يوم',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.phone,
            color: Colors.white.withOpacity(0.7),
            size: 24,
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.5),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusXl),
          topRight: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusXl),
          topRight: Radius.circular(AppSpacing.radiusXl),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onNavTapped,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.islamicGreenLight,
          unselectedItemColor: Colors.white.withOpacity(0.5),
          selectedLabelStyle: AppTypography.labelSmall,
          unselectedLabelStyle: AppTypography.labelSmall,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_rounded),
              label: 'الأقارب',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              label: 'الإحصائيات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'الإعدادات',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.goldenGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.premiumGold.withOpacity(0.5),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: () {
          context.push(AppRoutes.addRelative);
        },
        child: const Icon(
          Icons.add_rounded,
          size: 36,
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
