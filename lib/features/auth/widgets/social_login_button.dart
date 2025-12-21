import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';

/// Social login provider type
enum SocialProvider {
  google,
  apple,
}

/// A button for social login providers (Google, Apple)
class SocialLoginButton extends StatelessWidget {
  final SocialProvider provider;
  final VoidCallback onPressed;
  final bool isLoading;

  const SocialLoginButton({
    super.key,
    required this.provider,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : FaIcon(
                _getIcon(),
                color: Colors.white,
                size: 20,
              ),
        label: Text(
          _getLabel(),
          style: AppTypography.labelLarge.copyWith(
            color: Colors.white,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.5),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppSpacing.radiusLg,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (provider) {
      case SocialProvider.google:
        return FontAwesomeIcons.google;
      case SocialProvider.apple:
        return FontAwesomeIcons.apple;
    }
  }

  String _getLabel() {
    switch (provider) {
      case SocialProvider.google:
        return 'المتابعة مع Google';
      case SocialProvider.apple:
        return 'المتابعة مع Apple';
    }
  }
}

/// A divider with "or" text for separating login methods
class OrDivider extends StatelessWidget {
  final String text;

  const OrDivider({
    super.key,
    this.text = 'أو',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
          ),
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}
