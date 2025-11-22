import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: GradientBackground(
        animated: true,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
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
                          color: Colors.white.withOpacity(0.5),
                          size: 20,
                        ),
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    GlassCard(
                      child: ListTile(
                        leading:
                            const Icon(Icons.notifications, color: Colors.white),
                        title: Text(
                          'الإشعارات',
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white.withOpacity(0.5),
                          size: 20,
                        ),
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
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
      ),
    );
  }
}
