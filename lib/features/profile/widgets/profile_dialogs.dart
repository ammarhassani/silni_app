import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/services/error_reporter.dart';
import '../../../shared/providers/data_export_provider.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../../shared/widgets/data_export_dialog.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/models/subscription_tier.dart';
import '../../../features/subscription/screens/paywall_screen.dart';

/// Show image source selection dialog
void showImageSourceDialog({
  required BuildContext context,
  required ThemeColors themeColors,
  required void Function(ImageSource source) onSourceSelected,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: themeColors.background1.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        title: Text(
          'اختر مصدر الصورة',
          style: AppTypography.titleLarge.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
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
              style: TextStyle(color: themeColors.primary),
            ),
          ),
        ],
      );
    },
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

  // Check subscription access for data export
  final hasAccess = ref.read(featureAccessProvider(FeatureIds.dataExport));
  if (!hasAccess) {
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const PaywallScreen(
            featureToUnlock: FeatureIds.dataExport,
            contextHeadline: 'صدّر بياناتك مع صِلْني MAX',
          ),
        ),
      );
    }
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

/// Two-step delete-account confirmation:
///   Step 1 — warning dialog (Cancel / Continue)
///   Step 2 — typed-string confirmation ("حذف") + password re-auth
/// Both must validate before the delete RPC is invoked. Hardened for App
/// Store 5.1.1(v) compliance — single-tap deletion is no longer possible.
Future<void> showDeleteAccountDialog({
  required BuildContext context,
  required WidgetRef ref,
  required ThemeColors themeColors,
}) async {
  // Step 1 — warning.
  final continueToStep2 = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: themeColors.background1.withValues(alpha: 0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      title: Text(
        'حذف الحساب',
        style: AppTypography.titleLarge.copyWith(color: Colors.white),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'هل أنت متأكد من حذف حسابك؟ سيتم حذف جميع بياناتك بشكل نهائي ولا يمكن التراجع عن هذا الإجراء.',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'ملاحظة: اشتراك صِلْني MAX مرتبط بحساب Apple أو Google عندك، '
            'وحذف الحساب لا يلغي الاشتراك. لإلغاء الاشتراك افتح إعدادات '
            'متجر التطبيقات > الاشتراكات.',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.amber.withValues(alpha: 0.9),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(
            'إلغاء',
            style: TextStyle(color: themeColors.primary),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('متابعة'),
        ),
      ],
    ),
  );

  if (continueToStep2 != true || !context.mounted) return;

  // Step 2 — typed confirmation + password re-auth.
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _DeleteAccountConfirmDialog(
      themeColors: themeColors,
      ref: ref,
    ),
  );

  if (confirmed != true || !context.mounted) return;

  // Loading spinner while the RPC runs.
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    await ref.read(authServiceProvider).deleteAccount();
    if (!context.mounted) return;
    Navigator.of(context).pop(); // Close loading
    GoRouter.of(context).go(AppRoutes.login);
    UIHelpers.showSnackBar(context, 'تم حذف حسابك بنجاح');
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context).pop(); // Close loading
    UIHelpers.showSnackBar(
      context,
      errorHandler.getArabicMessage(e),
      isError: true,
    );
  }
}

/// Step-2 dialog. Lives as a StatefulWidget so the typed-confirm and
/// password fields can manage their own controllers and validation
/// state without the caller juggling them.
class _DeleteAccountConfirmDialog extends StatefulWidget {
  const _DeleteAccountConfirmDialog({
    required this.themeColors,
    required this.ref,
  });

  final ThemeColors themeColors;
  final WidgetRef ref;

  @override
  State<_DeleteAccountConfirmDialog> createState() =>
      _DeleteAccountConfirmDialogState();
}

class _DeleteAccountConfirmDialogState
    extends State<_DeleteAccountConfirmDialog> {
  static const _confirmWord = 'حذف';

  final _confirmController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isVerifying = false;
  String? _inlineError;

  @override
  void dispose() {
    _confirmController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _confirmController.text.trim() == _confirmWord &&
      _passwordController.text.isNotEmpty &&
      !_isVerifying;

  Future<void> _onSubmit() async {
    final email = SupabaseConfig.client.auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      setState(() => _inlineError =
          'تعذّر التحقق من البريد الإلكتروني — حاول تسجيل الخروج وإعادة الدخول.');
      return;
    }

    setState(() {
      _isVerifying = true;
      _inlineError = null;
    });

    try {
      // Verify the password by attempting a fresh sign-in with the same
      // email. signInWithPassword keeps the existing session if it
      // succeeds; if the password is wrong, it raises an AuthException.
      // (Supabase's auth.reauthenticate() sends a nonce email rather than
      // verifying a password — wrong primitive for this flow.)
      await widget.ref.read(authServiceProvider).signInWithEmail(
            email: email,
            password: _passwordController.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _inlineError = errorHandler.getArabicMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.themeColors.background1.withValues(alpha: 0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      title: Text(
        'تأكيد حذف الحساب',
        style: AppTypography.titleLarge.copyWith(color: Colors.white),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اكتب كلمة "$_confirmWord" لتأكيد طلبك:',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _confirmController,
            onChanged: (_) => setState(() {}),
            textDirection: TextDirection.rtl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: _confirmWord,
              hintStyle:
                  TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'أدخل كلمة المرور لتأكيد هويتك:',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _passwordController,
            onChanged: (_) => setState(() {}),
            obscureText: true,
            textDirection: TextDirection.ltr,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'كلمة المرور',
              hintStyle:
                  TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_inlineError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _inlineError!,
              style: AppTypography.bodySmall.copyWith(color: Colors.red[200]),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isVerifying
              ? null
              : () => Navigator.of(context).pop(false),
          child: Text(
            'إلغاء',
            style: TextStyle(color: widget.themeColors.primary),
          ),
        ),
        ElevatedButton(
          onPressed: _canSubmit ? _onSubmit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.red.withValues(alpha: 0.3),
            disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
          ),
          child: _isVerifying
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('احذف الحساب'),
        ),
      ],
    );
  }
}
