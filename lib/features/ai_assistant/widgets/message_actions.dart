import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';

/// Visible action buttons for chat messages (Claude-style)
/// Shows Copy, Edit (for user messages), Regenerate (for AI messages)
import '../../../shared/utils/ui_helpers.dart';
class MessageActionsRow extends StatelessWidget {
  final bool isUserMessage;
  final String content;
  final VoidCallback? onEdit;
  final VoidCallback? onRegenerate;

  const MessageActionsRow({
    super.key,
    required this.isUserMessage,
    required this.content,
    this.onEdit,
    this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Copy button (always shown)
          _ActionButton(
            icon: Icons.copy_rounded,
            label: 'نسخ',
            onTap: () => _copyToClipboard(context),
          ),

          if (isUserMessage && onEdit != null) ...[
            const SizedBox(width: AppSpacing.sm),
            _ActionButton(
              icon: Icons.edit_rounded,
              label: 'تعديل',
              onTap: onEdit,
            ),
          ],

          if (!isUserMessage && onRegenerate != null) ...[
            const SizedBox(width: AppSpacing.sm),
            _ActionButton(
              icon: Icons.refresh_rounded,
              label: 'إعادة',
              onTap: onRegenerate,
            ),
          ],
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: content));
    UIHelpers.showSnackBar(
      context,
      'تم نسخ الرسالة',
      backgroundColor: AppColors.islamicGreenPrimary,
      duration: const Duration(seconds: 2),
    );
  }
}

/// Individual action button with icon and label
class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap?.call();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: _isHovered
                    ? Colors.white.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: AppTypography.labelSmall.copyWith(
                  color: _isHovered
                      ? Colors.white.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Standalone copy button for code blocks
class CopyCodeButton extends StatelessWidget {
  final String code;

  const CopyCodeButton({
    super.key,
    required this.code,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: AppSpacing.xs,
      left: AppSpacing.xs,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Clipboard.setData(ClipboardData(text: code));
          UIHelpers.showSnackBar(
            context,
            'تم نسخ الكود',
            backgroundColor: AppColors.islamicGreenPrimary,
            duration: const Duration(seconds: 2),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(
            Icons.copy_rounded,
            size: 14,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}
