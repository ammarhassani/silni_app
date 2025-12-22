import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_themes.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
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
                    'الإعدادات',
                    style: AppTypography.headlineMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Settings list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // Theme Selector
                  GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.palette,
                              color: AppColors.premiumGold,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'المظهر',
                              style: AppTypography.titleLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'اختر المظهر المفضل لديك',
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Theme Grid
                        GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: AppSpacing.sm,
                          mainAxisSpacing: AppSpacing.sm,
                          children: AppThemeType.values.map((theme) {
                            return _buildThemeCard(
                              context,
                              ref,
                              theme,
                              currentTheme == theme,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Profile
                  GlassCard(
                    child: ListTile(
                      leading: const Icon(Icons.person, color: Colors.white),
                      title: Text(
                        'الملف الشخصي',
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 20,
                      ),
                      onTap: () {
                        context.push(AppRoutes.profile);
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Notifications
                  GlassCard(
                    child: ListTile(
                      leading: const Icon(
                        Icons.notifications,
                        color: Colors.white,
                      ),
                      title: Text(
                        'الإشعارات',
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 20,
                      ),
                      onTap: () {
                        context.push(AppRoutes.notifications);
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Logout
                  GlassCard(
                    child: ListTile(
                      leading: const Icon(Icons.logout, color: Colors.white),
                      title: Text(
                        'تسجيل الخروج',
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      onTap: () async {
                        final authService = ref.read(authServiceProvider);
                        await authService.signOut();
                        if (context.mounted) {
                          context.go(AppRoutes.login);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard(
    BuildContext context,
    WidgetRef ref,
    AppThemeType theme,
    bool isSelected,
  ) {
    final themeColors = ThemeColors.getTheme(theme);

    return GestureDetector(
      onTap: () {
        ref.read(themeProvider.notifier).setTheme(theme);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تغيير المظهر إلى ${theme.arabicName}'),
            backgroundColor: themeColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: themeColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isSelected
                ? AppColors.premiumGold
                : Colors.white.withValues(alpha: 0.2),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.premiumGold.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.white, size: 32)
            else
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                child: Icon(Icons.palette, color: Colors.white, size: 20),
              ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              theme.arabicName,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
