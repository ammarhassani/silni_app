import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../../shared/widgets/glass_card.dart';
import '../services/family_group_service.dart';

/// A card displaying the invite link for a family group.
///
/// Provides copy-to-clipboard, WhatsApp share, and generic share actions.
/// All text is in Arabic following the RTL UI convention.
class InviteLinkCard extends ConsumerWidget {
  final String inviteCode;
  final bool isAdmin;
  final VoidCallback? onRotate;

  const InviteLinkCard({
    super.key,
    required this.inviteCode,
    this.isAdmin = false,
    this.onRotate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final inviteLink = FamilyGroupService.generateInviteLink(inviteCode);

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text(
            'رابط الدعوة',
            style: AppTypography.titleMedium.copyWith(
              color: themeColors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Link display with copy button
          GlassCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            onTap: () => _copyToClipboard(context, inviteLink),
            semanticsLabel: 'انسخ رابط الدعوة',
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    inviteLink,
                    style: AppTypography.bodyMedium.copyWith(
                      color: themeColors.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.copy_rounded,
                  size: AppSpacing.iconSm,
                  color: themeColors.onSurface,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Share buttons row
          Row(
            children: [
              // WhatsApp share button
              Expanded(
                child: _ShareButton(
                  icon: Icons.chat_rounded,
                  label: 'واتساب',
                  color: themeColors.onSurface,
                  onTap: () => _shareViaWhatsApp(context, inviteLink),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Generic share button
              Expanded(
                child: _ShareButton(
                  icon: Icons.share_rounded,
                  label: 'مشاركة',
                  color: themeColors.onSurface,
                  onTap: () => _shareGeneric(context, inviteLink),
                ),
              ),
            ],
          ),

          // Rotate invite code button (admin only)
          if (isAdmin && onRotate != null) ...[
            const SizedBox(height: AppSpacing.sm),
            GlassCard(
              onTap: () => _confirmRotate(context, themeColors),
              semanticsLabel: 'تجديد رابط الدعوة',
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    size: AppSpacing.iconSm,
                    color: themeColors.onSurface,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'تجديد الرابط',
                    style: AppTypography.labelMedium.copyWith(
                      color: themeColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmRotate(BuildContext context, dynamic themeColors) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: themeColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        title: Text(
          'تجديد رابط الدعوة',
          style: AppTypography.titleMedium.copyWith(
            color: themeColors.onSurface,
          ),
        ),
        content: Text(
          'سيتم إلغاء الرابط القديم ولن يعمل بعد الآن. هل تريد المتابعة؟',
          style: AppTypography.bodyMedium.copyWith(
            color: themeColors.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'إلغاء',
              style: TextStyle(color: themeColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'تجديد',
              style: TextStyle(color: themeColors.onSurface),
            ),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) onRotate?.call();
    });
  }

  void _copyToClipboard(BuildContext context, String link) {
    Clipboard.setData(ClipboardData(text: link));
    HapticFeedback.mediumImpact();
    UIHelpers.showSnackBar(
      context,
      'تم نسخ الرابط',
      icon: Icons.check_circle_outline_rounded,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _shareViaWhatsApp(BuildContext context, String link) async {
    final message = Uri.encodeComponent('انضم لعائلتنا في صِلْني 🌳 $link');
    final whatsappUrl = Uri.parse('https://wa.me/?text=$message');

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      // Fallback to generic share if WhatsApp is not installed
      if (context.mounted) {
        _shareGeneric(context, link);
      }
    }
  }

  Future<void> _shareGeneric(BuildContext context, String link) async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;
    await Share.share('انضم لعائلتنا في صِلْني 🌳 $link', sharePositionOrigin: origin);
  }
}

/// Internal share button widget with icon and label.
class _ShareButton extends ConsumerWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    return GlassCard(
      onTap: onTap,
      semanticsLabel: label,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: AppSpacing.iconSm,
            color: color,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: themeColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
