import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/gradient_button.dart';

// Fallback error color for dialog without theme context
const _kErrorColor = Color(0xFFE53935);

/// A dialog that prompts the user to enter their display name
/// Used after Apple Sign-In when user chose "Hide My Email"
class NamePromptDialog extends StatefulWidget {
  final String? initialName;
  final Future<void> Function(String name) onSubmit;

  const NamePromptDialog({
    super.key,
    this.initialName,
    required this.onSubmit,
  });

  /// Shows the name prompt dialog and returns the entered name
  static Future<String?> show(
    BuildContext context, {
    String? initialName,
    required Future<void> Function(String name) onSubmit,
  }) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => NamePromptDialog(
        initialName: initialName,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<NamePromptDialog> createState() => _NamePromptDialogState();
}

class _NamePromptDialogState extends State<NamePromptDialog> {
  late final TextEditingController _nameController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'الرجاء إدخال اسمك';
      });
      return;
    }

    if (name.length < 2) {
      setState(() {
        _errorMessage = 'الاسم قصير جداً';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.onSubmit(name);
      if (mounted) {
        Navigator.of(context).pop(name);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'حدث خطأ، الرجاء المحاولة مرة أخرى';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.islamicGreenDark.withValues(alpha: 0.95),
              const Color(0xFF2D7A3E).withValues(alpha: 0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.goldenGradient,
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 35,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Title
            Text(
              'مرحباً بك!',
              style: AppTypography.headlineMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Subtitle
            Text(
              'ما اسمك الذي تريد أن يظهر في التطبيق؟',
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Name input field
            TextField(
              controller: _nameController,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: AppTypography.bodyLarge.copyWith(
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: 'أدخل اسمك',
                hintStyle: AppTypography.bodyLarge.copyWith(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: BorderSide(
                    color: AppColors.premiumGold,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                errorText: _errorMessage,
                errorStyle: AppTypography.bodySmall.copyWith(
                  color: _kErrorColor,
                ),
              ),
              onSubmitted: (_) => _submit(),
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                text: 'متابعة',
                onPressed: _submit,
                isLoading: _isLoading,
                icon: Icons.arrow_forward_rounded,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Skip button
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      Navigator.of(context).pop(null);
                    },
              child: Text(
                'تخطي الآن',
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
