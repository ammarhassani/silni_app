import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gamification_stats_card.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/models/interaction_model.dart';
import '../../../shared/services/relatives_service.dart';
import '../../../shared/providers/interactions_provider.dart';
import '../../auth/providers/auth_provider.dart';

// Providers
final relativesServiceProvider = Provider((ref) => RelativesService());

final userRelativesProvider = StreamProvider.family<List<Relative>, String>((ref, userId) {
  final service = ref.watch(relativesServiceProvider);
  return service.getRelativesStream(userId);
});

final userInteractionsProvider = StreamProvider.family<List<Interaction>, String>((ref, userId) {
  final service = ref.watch(interactionsServiceProvider);
  return service.getInteractionsStream(userId);
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isEditingName = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? '';
    final themeColors = ref.watch(themeColorsProvider);

    final relativesAsync = ref.watch(userRelativesProvider(userId));
    final interactionsAsync = ref.watch(userInteractionsProvider(userId));

    return Scaffold(
      body: GradientBackground(
        animated: true,
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header with avatar
              SliverToBoxAdapter(
                child: _buildHeader(user, themeColors),
              ),

              // User info card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: _buildUserInfoCard(user, themeColors),
                ),
              ),

              // Statistics
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(
                    '📊 إحصائياتي',
                    style: AppTypography.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

              // Gamification Stats
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: GamificationStatsCard(
                    userId: userId,
                    compact: false,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

              // Statistics
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(
                    '📊 إحصائياتي',
                    style: AppTypography.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: relativesAsync.when(
                    data: (relatives) => interactionsAsync.when(
                      data: (interactions) => _buildStatistics(relatives, interactions, themeColors),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

              // Account actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(
                    '⚙️ إعدادات الحساب',
                    style: AppTypography.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: _buildAccountActions(themeColors),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic user, ThemeColors themeColors) {
    final displayName = user?.userMetadata?['full_name'] ?? user?.email?.split('@')[0] ?? 'المستخدم';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // Back button
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              ),
              const Spacer(),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Avatar with edit button
          Stack(
            children: [
              Hero(
                tag: 'profile-avatar',
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: themeColors.goldenGradient,
                    boxShadow: [
                      BoxShadow(
                        color: themeColors.accent.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: user?.userMetadata?['profile_picture_url'] != null
                      ? ClipOval(
                          child: Image.network(
                            user!.userMetadata!['profile_picture_url'] as String,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildDefaultAvatar(displayName),
                          ),
                        )
                      : _buildDefaultAvatar(displayName),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تغيير الصورة قريباً')),
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: themeColors.primaryGradient,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Name with edit button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isEditingName)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: 120,
                    maxWidth: MediaQuery.of(context).size.width * 0.6,
                  ),
                  child: TextField(
                    controller: _nameController,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white60),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                )
              else
                Text(
                  displayName,
                  style: AppTypography.headlineLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    if (_isEditingName) {
                      // Save name
                      _saveName();
                    } else {
                      // Start editing
                      _nameController.text = displayName;
                      _isEditingName = true;
                    }
                  });
                },
                icon: Icon(
                  _isEditingName ? Icons.check_circle : Icons.edit_rounded,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xs),

          // Email
          Text(
            user?.email ?? '',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 600))
        .slideY(begin: -0.1, end: 0);
  }

  Widget _buildDefaultAvatar(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '؟',
        style: const TextStyle(
          fontSize: 48,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(dynamic user, ThemeColors themeColors) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: themeColors.accent),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'معلومات الحساب',
                style: AppTypography.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          _buildInfoRow(
            icon: Icons.email_outlined,
            label: 'البريد الإلكتروني',
            value: user?.email ?? 'غير متوفر',
            themeColors: themeColors,
          ),

          const SizedBox(height: AppSpacing.md),

          _buildInfoRow(
            icon: Icons.verified_user_outlined,
            label: 'حالة التحقق',
            value: user?.emailConfirmedAt != null ? 'تم التحقق ✓' : 'لم يتم التحقق',
            themeColors: themeColors,
          ),

          const SizedBox(height: AppSpacing.md),

          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'تاريخ الانضمام',
            value: user?.createdAt != null
                ? _formatDate(user!.createdAt)
                : 'غير متوفر',
            themeColors: themeColors,
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.1, end: 0);
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeColors themeColors,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: themeColors.primary.withOpacity(0.2),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white.withOpacity(0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics(List<Relative> relatives, List<Interaction> interactions, ThemeColors themeColors) {
    final thisMonth = DateTime.now();
    final monthStart = DateTime(thisMonth.year, thisMonth.month, 1);
    final thisMonthInteractions = interactions.where((i) => i.date.isAfter(monthStart)).length;

    final needsContact = relatives.where((r) => r.needsContact).length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.people_rounded,
                label: 'إجمالي الأقارب',
                value: '${relatives.length}',
                gradient: themeColors.primaryGradient,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildStatCard(
                icon: Icons.call_rounded,
                label: 'تواصل هذا الشهر',
                value: '$thisMonthInteractions',
                gradient: themeColors.goldenGradient,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.timeline_rounded,
                label: 'إجمالي التفاعلات',
                value: '${interactions.length}',
                gradient: LinearGradient(
                  colors: [themeColors.accent, themeColors.primaryLight],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildStatCard(
                icon: Icons.notifications_active_rounded,
                label: 'يحتاجون تواصل',
                value: '$needsContact',
                gradient: needsContact > 0 ? AppColors.streakFire : themeColors.primaryGradient,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Gradient gradient,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      gradient: gradient,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.headlineLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildAccountActions(ThemeColors themeColors) {
    return Column(
      children: [
        GlassCard(
          child: ListTile(
            leading: Icon(Icons.lock_outline, color: themeColors.accent),
            title: Text(
              'تغيير كلمة المرور',
              style: AppTypography.titleMedium.copyWith(color: Colors.white),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.5),
              size: 20,
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              _showChangePasswordDialog();
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          child: ListTile(
            leading: Icon(Icons.shield_outlined, color: themeColors.accent),
            title: Text(
              'الخصوصية والأمان',
              style: AppTypography.titleMedium.copyWith(color: Colors.white),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.5),
              size: 20,
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('إعدادات الخصوصية قريباً')),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          child: ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: Text(
              'حذف الحساب',
              style: AppTypography.titleMedium.copyWith(color: Colors.red),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.5),
              size: 20,
            ),
            onTap: () {
              HapticFeedback.heavyImpact();
              _showDeleteAccountDialog();
            },
          ),
        ),
      ],
    );
  }

  Future<void> _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الاسم لا يمكن أن يكون فارغاً'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (newName.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الاسم يجب أن يكون حرفين على الأقل'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;

      // Update Supabase user profile in database
      await SupabaseConfig.client
          .from('users')
          .update({'full_name': newName})
          .eq('id', user.id);

      if (mounted) {
        setState(() => _isEditingName = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الاسم بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'تغيير كلمة المرور',
          style: AppTypography.headlineMedium.copyWith(color: Colors.white),
        ),
        content: Text(
          'سيتم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
          style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                final user = SupabaseConfig.client.auth.currentUser;
                if (user == null || user.email == null) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('البريد الإلكتروني غير متوفر'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                  return;
                }

                final authService = ref.read(authServiceProvider);
                await authService.resetPassword(user.email!);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم إرسال رابط إعادة التعيين إلى بريدك الإلكتروني'),
                      backgroundColor: AppColors.success,
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('حدث خطأ: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'حذف الحساب',
          style: AppTypography.headlineMedium.copyWith(color: Colors.red),
        ),
        content: Text(
          'هل أنت متأكد من حذف حسابك؟ سيتم حذف جميع بياناتك بشكل نهائي ولا يمكن التراجع عن هذا الإجراء.',
          style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading dialog
              if (mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              try {
                // Use Supabase delete account method (handles all cascading deletions via RPC)
                final authService = ref.read(authServiceProvider);
                await authService.deleteAccount();

                // Close loading dialog
                if (mounted) {
                  Navigator.pop(context);

                  // Navigate to login
                  context.go(AppRoutes.login);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف حسابك بنجاح'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                // Close loading dialog
                if (mounted) {
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('حدث خطأ: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
