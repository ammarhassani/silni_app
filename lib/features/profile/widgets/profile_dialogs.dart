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
import '../../../shared/widgets/glass_dialog.dart';
import '../../../shared/widgets/gradient_button.dart';
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
    builder: (BuildContext dialogContext) {
      return GlassDialog(
        icon: Icons.photo_camera_rounded,
        title: 'اختر مصدر الصورة',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ImageSourceOption(
              icon: Icons.photo_library_rounded,
              label: 'المعرض',
              onTap: () {
                Navigator.of(dialogContext).pop();
                onSourceSelected(ImageSource.gallery);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _ImageSourceOption(
              icon: Icons.camera_alt_rounded,
              label: 'الكاميرا',
              onTap: () {
                Navigator.of(dialogContext).pop();
                onSourceSelected(ImageSource.camera);
              },
            ),
          ],
        ),
        actions: [
          GlassActionButton(
            text: 'إلغاء',
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      );
    },
  );
}

/// Distinct image-source row with leading squircle icon — replaces stock
/// ListTile for the gallery/camera picker.
class _ImageSourceOption extends ConsumerWidget {
  const _ImageSourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: themeColors.primaryColor.withValues(alpha: 0.22),
                  border: Border.all(
                    color: themeColors.primaryColor.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  icon,
                  color: themeColors.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.4),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
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
    builder: (dialogContext) => GlassDialog(
      icon: Icons.warning_amber_rounded,
      iconAccent: const Color(0xFFD32F2F),
      title: 'حذف الحساب',
      subtitle:
          'هل أنت متأكد من حذف حسابك؟ سيتم حذف جميع بياناتك بشكل نهائي ولا يمكن التراجع عن هذا الإجراء.',
      content: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: Colors.amber.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: Colors.amber.withValues(alpha: 0.9),
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'اشتراك صِلْني MAX مرتبط بحساب Apple أو Google عندك، وحذف الحساب لا يلغي الاشتراك. لإلغاء الاشتراك افتح إعدادات متجر التطبيقات > الاشتراكات.',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.amber.withValues(alpha: 0.95),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        GlassActionButton(
          text: 'إلغاء',
          onPressed: () => Navigator.pop(dialogContext, false),
        ),
        GradientButton(
          text: 'متابعة',
          icon: Icons.arrow_forward_rounded,
          onPressed: () => Navigator.pop(dialogContext, true),
          gradient: const LinearGradient(
            colors: [Color(0xFFD32F2F), Color(0xFF8B1F1F)],
          ),
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

  /// True when the signed-in user has a password to verify against (i.e.
  /// they signed up via email + password). Apple and Google sign-in users
  /// have no password — for them, the typed-word confirmation is the only
  /// re-auth step. App Store 5.1.1(v) requires deletion be available; the
  /// two-step dialog (warning → typed "حذف") satisfies that on its own.
  late final bool _requiresPassword = _detectRequiresPassword();

  bool _detectRequiresPassword() {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return true; // fail closed — show password
    final provider = user.appMetadata['provider'] as String?;
    return provider == null || provider == 'email';
  }

  @override
  void dispose() {
    _confirmController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final wordOk = _confirmController.text.trim() == _confirmWord;
    if (_isVerifying) return false;
    if (!_requiresPassword) return wordOk;
    return wordOk && _passwordController.text.isNotEmpty;
  }

  Future<void> _onSubmit() async {
    // Social-auth users (Apple, Google) have no password to verify. The
    // typed-word confirmation is the sole re-auth gate for them.
    if (!_requiresPassword) {
      Navigator.of(context).pop(true);
      return;
    }

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
    return GlassDialog(
      icon: Icons.delete_forever_rounded,
      iconAccent: const Color(0xFFD32F2F),
      title: 'تأكيد حذف الحساب',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اكتب كلمة "$_confirmWord" لتأكيد طلبك:',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _GlassTextField(
            controller: _confirmController,
            onChanged: (_) => setState(() {}),
            hintText: _confirmWord,
            textDirection: TextDirection.rtl,
          ),
          if (_requiresPassword) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'أدخل كلمة المرور لتأكيد هويتك:',
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _GlassTextField(
              controller: _passwordController,
              onChanged: (_) => setState(() {}),
              hintText: 'كلمة المرور',
              obscureText: true,
              textDirection: TextDirection.ltr,
            ),
          ],
          if (_inlineError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                  color: const Color(0xFFD32F2F).withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFFFAFA3),
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      _inlineError!,
                      style: AppTypography.bodySmall.copyWith(
                        color: const Color(0xFFFFAFA3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        GlassActionButton(
          text: 'إلغاء',
          onPressed: _isVerifying
              ? () {}
              : () => Navigator.of(context).pop(false),
        ),
        GradientButton(
          text: 'احذف الحساب',
          icon: Icons.delete_forever_rounded,
          isLoading: _isVerifying,
          enabled: _canSubmit,
          onPressed: _canSubmit ? _onSubmit : () {},
          gradient: const LinearGradient(
            colors: [Color(0xFFD32F2F), Color(0xFF8B1F1F)],
          ),
        ),
      ],
    );
  }
}

/// Compact glass-styled TextField used inside delete-account dialog.
class _GlassTextField extends StatelessWidget {
  const _GlassTextField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.obscureText = false,
    this.textDirection,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final bool obscureText;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      obscureText: obscureText,
      textDirection: textDirection,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
