import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/utils/ui_helpers.dart';

/// Long-press action sheet for chat messages.
///
/// Replaces the persistent inline action row (Phase α2) with a discoverable
/// long-press affordance. User messages: copy / edit / regenerate. AI
/// messages: copy / regenerate / report.
class MessageActionSheet extends ConsumerWidget {
  const MessageActionSheet({
    super.key,
    required this.isUser,
    required this.content,
    this.onEdit,
    this.onRegenerate,
  });

  final bool isUser;
  final String content;
  final VoidCallback? onEdit;
  final VoidCallback? onRegenerate;

  static Future<void> show({
    required BuildContext context,
    required bool isUser,
    required String content,
    VoidCallback? onEdit,
    VoidCallback? onRegenerate,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      isScrollControlled: true,
      builder: (_) => MessageActionSheet(
        isUser: isUser,
        content: content,
        onEdit: onEdit,
        onRegenerate: onRegenerate,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: themeColors.background2.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ActionTile(
                      icon: Icons.copy_rounded,
                      label: 'نسخ',
                      onTap: () {
                        Navigator.pop(context);
                        Clipboard.setData(ClipboardData(text: content));
                        UIHelpers.showSnackBar(
                          context,
                          'تم نسخ الرسالة',
                          backgroundColor: themeColors.primary,
                          duration: const Duration(seconds: 2),
                        );
                      },
                    ),
                    if (isUser && onEdit != null)
                      _ActionTile(
                        icon: Icons.edit_rounded,
                        label: 'تعديل',
                        onTap: () {
                          Navigator.pop(context);
                          onEdit!.call();
                        },
                      ),
                    if (isUser && onRegenerate != null)
                      _ActionTile(
                        icon: Icons.refresh_rounded,
                        label: 'إعادة توليد الرد',
                        onTap: () {
                          Navigator.pop(context);
                          onRegenerate!.call();
                        },
                      ),
                    if (!isUser && onRegenerate != null)
                      _ActionTile(
                        icon: Icons.refresh_rounded,
                        label: 'إعادة',
                        onTap: () {
                          Navigator.pop(context);
                          onRegenerate!.call();
                        },
                      ),
                    if (!isUser)
                      _ActionTile(
                        icon: Icons.flag_outlined,
                        label: 'إبلاغ',
                        onTap: () {
                          Navigator.pop(context);
                          UIHelpers.showSnackBar(
                            context,
                            'شكرًا للملاحظة',
                            backgroundColor: themeColors.primary,
                            duration: const Duration(seconds: 2),
                          );
                        },
                      ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends ConsumerWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(icon, color: themeColors.textOnGradient, size: 20),
              const SizedBox(width: AppSpacing.md),
              Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: themeColors.textOnGradient,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
