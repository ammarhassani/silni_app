import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/services/error_handler_service.dart';
import '../../../shared/providers/data_export_provider.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../../shared/widgets/data_export_dialog.dart';
import '../../../shared/widgets/theme_aware_dialog.dart';
import '../../auth/providers/auth_provider.dart';

/// Show image source selection dialog
void showImageSourceDialog({
  required BuildContext context,
  required ThemeColors themeColors,
  required void Function(ImageSource source) onSourceSelected,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return ThemeAwareAlertDialog(
        title: 'اختر مصدر الصورة',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library, color: themeColors.primary),
              title: Text(
                'المعرض',
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
              ),
              onTap: () {
                Navigator.of(context).pop();
                onSourceSelected(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: themeColors.primary),
              title: Text(
                'الكاميرا',
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
              ),
              onTap: () {
                Navigator.of(context).pop();
                onSourceSelected(ImageSource.camera);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'إلغاء',
              style: AppTypography.buttonMedium.copyWith(
                color: themeColors.primary,
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// Show change password dialog
void showChangePasswordDialog({
  required BuildContext context,
  required WidgetRef ref,
}) {
  showDialog(
    context: context,
    builder: (dialogContext) => ThemeAwareAlertDialog(
      title: 'تغيير كلمة المرور',
      content: Text(
        'سيتم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
        style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
      ),
      actions: [
        ThemeAwareDialogButton(
          text: 'إلغاء',
          isPrimary: false,
          onPressed: () => Navigator.pop(dialogContext),
        ),
        ThemeAwareDialogButton(
          text: 'إرسال',
          isPrimary: true,
          onPressed: () async {
            Navigator.pop(dialogContext);

            try {
              final user = SupabaseConfig.client.auth.currentUser;
              if (user == null || user.email == null) {
                UIHelpers.showSnackBar(
                  context,
                  'البريد الإلكتروني غير متوفر',
                  isError: true,
                );
                return;
              }

              final authService = ref.read(authServiceProvider);
              await authService.resetPassword(user.email!);

              if (context.mounted) {
                UIHelpers.showSnackBar(
                  context,
                  'تم إرسال رابط إعادة التعيين إلى بريدك الإلكتروني',
                );
              }
            } catch (e) {
              if (context.mounted) {
                UIHelpers.showSnackBar(
                  context,
                  errorHandler.getArabicMessage(e),
                  isError: true,
                );
              }
            }
          },
        ),
      ],
    ),
  );
}

/// Show export data dialog
Future<void> showExportDataDialogFlow({
  required BuildContext context,
  required WidgetRef ref,
  required ThemeColors themeColors,
}) async {
  final userId = SupabaseConfig.currentUserId;

  if (userId == null) {
    UIHelpers.showSnackBar(
      context,
      'يرجى تسجيل الدخول أولاً',
      isError: true,
    );
    return;
  }

  // Show confirmation dialog first
  final confirmed = await showDataExportConfirmationDialog(context, themeColors);

  if (confirmed != true) return;

  // Reset the export state before starting
  ref.read(dataExportNotifierProvider.notifier).reset();

  // Show export progress dialog
  if (context.mounted) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DataExportDialog(userId: userId),
    );
  }
}

/// Show delete account dialog
void showDeleteAccountDialog({
  required BuildContext context,
  required WidgetRef ref,
}) {
  showDialog(
    context: context,
    builder: (dialogContext) => ThemeAwareAlertDialog(
      title: 'حذف الحساب',
      content: Text(
        'هل أنت متأكد من حذف حسابك؟ سيتم حذف جميع بياناتك بشكل نهائي ولا يمكن التراجع عن هذا الإجراء.',
        style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
      ),
      actions: [
        ThemeAwareDialogButton(
          text: 'إلغاء',
          isPrimary: false,
          onPressed: () => Navigator.pop(dialogContext),
        ),
        ThemeAwareDialogButton(
          text: 'حذف',
          variant: DialogButtonVariant.destructive,
          onPressed: () async {
            Navigator.pop(dialogContext);

            // Show loading dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (loadingContext) =>
                  const Center(child: CircularProgressIndicator()),
            );

            try {
              // Use Supabase delete account method
              final authService = ref.read(authServiceProvider);
              await authService.deleteAccount();

              // Close loading dialog and navigate
              if (context.mounted) {
                Navigator.of(context).pop(); // Close loading
                GoRouter.of(context).go(AppRoutes.login);

                UIHelpers.showSnackBar(
                  context,
                  'تم حذف حسابك بنجاح',
                );
              }
            } catch (e) {
              // Close loading dialog
              if (context.mounted) {
                Navigator.of(context).pop(); // Close loading
                UIHelpers.showSnackBar(
                  context,
                  errorHandler.getArabicMessage(e),
                  isError: true,
                );
              }
            }
          },
        ),
      ],
    ),
  );
}
