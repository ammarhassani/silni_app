import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../auth/providers/auth_provider.dart';

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
                    // Header
                    _buildHeader(displayName),
                    const SizedBox(height: AppSpacing.xl),

                    // Streak card
                    _buildStreakCard(),
                    const SizedBox(height: AppSpacing.lg),

                    // Quick stats
                    _buildQuickStats(),
                    const SizedBox(height: AppSpacing.xl),

                    // Today's connections
                    _buildTodaysConnections(),
                    const SizedBox(height: AppSpacing.xl),

                    // Quick actions
                    _buildQuickActions(context),
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

  Widget _buildHeader(String displayName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'السلام عليكم',
              style: AppTypography.bodyLarge.copyWith(
                color: Colors.white.withOpacity(0.8),
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
        )
            .animate()
            .fadeIn(duration: const Duration(milliseconds: 600))
            .slideX(begin: -0.2, end: 0),

        // Profile avatar with glow
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.goldenGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.premiumGold.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: 30,
            ),
          ),
        )
            .animate(
              onPlay: (controller) => controller.repeat(reverse: true),
            )
            .shimmer(
              duration: const Duration(seconds: 2),
              color: Colors.white.withOpacity(0.5),
            ),
      ],
    );
  }

  Widget _buildStreakCard() {
    return DramaticGlassCard(
      gradient: LinearGradient(
        colors: [
          AppColors.islamicGreenPrimary.withOpacity(0.3),
          AppColors.premiumGold.withOpacity(0.2),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.streakFire,
            ),
            child: const Center(
              child: Icon(
                Icons.local_fire_department_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سلسلة التواصل',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '7',
                      style: AppTypography.numberLarge.copyWith(
                        color: Colors.white,
                        fontSize: 48,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'أيام',
                      style: AppTypography.titleLarge.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white.withOpacity(0.5),
            size: 20,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: const Duration(milliseconds: 200))
        .slideY(begin: 0.3, end: 0, curve: Curves.easeOut)
        .then() // After initial animation
        .animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        )
        .scale(
          duration: const Duration(seconds: 2),
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.02, 1.02),
        );
  }

  Widget _buildQuickStats() {
    final stats = [
      {'icon': Icons.people, 'value': '12', 'label': 'أقارب'},
      {'icon': Icons.phone, 'value': '45', 'label': 'تواصل'},
      {'icon': Icons.star, 'value': '450', 'label': 'نقاط'},
    ];

    return Row(
      children: List.generate(
        stats.length,
        (index) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index < stats.length - 1 ? AppSpacing.sm : 0,
            ),
            child: GlassCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  Icon(
                    stats[index]['icon'] as IconData,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stats[index]['value'] as String,
                    style: AppTypography.numberMedium.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stats[index]['label'] as String,
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            )
                .animate(delay: Duration(milliseconds: 400 + (index * 100)))
                .fadeIn()
                .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
          ),
        ),
      ),
    );
  }

  Widget _buildTodaysConnections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'تواصل اليوم',
              style: AppTypography.headlineSmall.copyWith(
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {
                context.push(AppRoutes.relatives);
              },
              child: Text(
                'عرض الكل',
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        GlassCard(
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: const Center(
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أحمد محمد',
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'آخر تواصل: منذ 3 أيام',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
        )
            .animate(delay: const Duration(milliseconds: 600))
            .fadeIn()
            .slideX(begin: 0.3, end: 0, curve: Curves.easeOut),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'إجراءات سريعة',
          style: AppTypography.headlineSmall.copyWith(
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: GradientButton(
                text: 'إضافة قريب',
                onPressed: () {
                  // TODO: Navigate to add relative
                },
                icon: Icons.person_add_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedGradientButton(
                text: 'إحصائيات',
                onPressed: () {
                  context.push(AppRoutes.statistics);
                },
                icon: Icons.bar_chart_rounded,
              ),
            ),
          ],
        )
            .animate(delay: const Duration(milliseconds: 800))
            .fadeIn()
            .slideY(begin: 0.3, end: 0),
      ],
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
          _confettiController.play();
          // TODO: Add interaction
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
          end: const Offset(1.1, 1.1),
        );
  }
}
