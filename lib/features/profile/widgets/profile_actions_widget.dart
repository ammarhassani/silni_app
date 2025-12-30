import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/app_themes.dart';
import '../../../shared/widgets/glass_card.dart';

/// Widget displaying account action buttons
class ProfileActionsWidget extends StatelessWidget {
  const ProfileActionsWidget({
    super.key,
    required this.themeColors,
    required this.onChangePassword,
    required this.onPrivacySettings,
    required this.onExportData,
    required this.onDeleteAccount,
  });

  final ThemeColors themeColors;
  final VoidCallback onChangePassword;
  final VoidCallback onPrivacySettings;
  final VoidCallback onExportData;
  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) {
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
              color: Colors.white.withValues(alpha: 0.5),
              size: 20,
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              onChangePassword();
            },
            // Semantics for ListTile are handled by default but can be enhanced
            // No explicit wrapper needed as ListTile is already semantic
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
              color: Colors.white.withValues(alpha: 0.5),
              size: 20,
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              onPrivacySettings();
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          child: ListTile(
            leading: Icon(Icons.download_outlined, color: themeColors.accent),
            title: Text(
              'تصدير بياناتي',
              style: AppTypography.titleMedium.copyWith(color: Colors.white),
            ),
            subtitle: Text(
              'تحميل نسخة من جميع بياناتك',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withValues(alpha: 0.5),
              size: 20,
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              onExportData();
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
              color: Colors.white.withValues(alpha: 0.5),
              size: 20,
            ),
            onTap: () {
              HapticFeedback.heavyImpact();
              onDeleteAccount();
            },
          ),
        ),
      ],
    );
  }
}
