import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../shared/models/relative_model.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Redesigned contact actions widget - theme-aware and consolidated
class RelativeContactActions extends ConsumerWidget {
  const RelativeContactActions({
    super.key,
    required this.relative,
    required this.onCall,
    required this.onWhatsApp,
    required this.onSms,
    required this.onDetails,
    this.onVisit,
    this.onGift,
    this.onEvent,
    this.onConversationStarters,
    this.isMaxUser = false,
  });

  final Relative relative;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback onSms;
  final VoidCallback onDetails;
  final VoidCallback? onVisit;
  final VoidCallback? onGift;
  final VoidCallback? onEvent;
  final VoidCallback? onConversationStarters;
  final bool isMaxUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final hasPhone = relative.phoneNumber != null;

    return Column(
      children: [
        // Primary contact actions in a glass card
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              _ActionButton(
                icon: Icons.phone_rounded,
                label: 'اتصال',
                themeColors: themeColors,
                onTap: onCall,
                isEnabled: hasPhone,
              ),
              const SizedBox(width: AppSpacing.xs),
              _ActionButton(
                icon: FontAwesomeIcons.whatsapp,
                label: 'واتساب',
                themeColors: themeColors,
                onTap: onWhatsApp,
                isEnabled: hasPhone,
                useFaIcon: true,
              ),
              const SizedBox(width: AppSpacing.xs),
              _ActionButton(
                icon: Icons.message_rounded,
                label: 'رسالة',
                themeColors: themeColors,
                onTap: onSms,
                isEnabled: hasPhone,
              ),
              const SizedBox(width: AppSpacing.xs),
              _ActionButton(
                icon: Icons.info_outline_rounded,
                label: 'تفاصيل',
                themeColors: themeColors,
                onTap: onDetails,
                isEnabled: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Quick log interaction section - unified card
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'تسجيل تواصل',
                style: AppTypography.labelMedium.copyWith(
                  color: themeColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Quick action buttons - all in a row, evenly distributed
              Row(
                children: [
                  if (onVisit != null)
                    Expanded(
                      child: _QuickLogButton(
                        icon: LucideIcons.home,
                        label: 'زيارة',
                        themeColors: themeColors,
                        onTap: onVisit!,
                      ),
                    ),
                  if (onVisit != null) const SizedBox(width: AppSpacing.xs),
                  if (onGift != null)
                    Expanded(
                      child: _QuickLogButton(
                        icon: LucideIcons.gift,
                        label: 'هدية',
                        themeColors: themeColors,
                        onTap: onGift!,
                      ),
                    ),
                  if (onGift != null) const SizedBox(width: AppSpacing.xs),
                  if (onEvent != null)
                    Expanded(
                      child: _QuickLogButton(
                        icon: LucideIcons.partyPopper,
                        label: 'مناسبة',
                        themeColors: themeColors,
                        onTap: onEvent!,
                      ),
                    ),
                ],
              ),

              // AI Conversation starters - separate row, full width
              if (isMaxUser && onConversationStarters != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _AIConversationButton(
                  themeColors: themeColors,
                  onTap: onConversationStarters!,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Primary action button (call, whatsapp, sms, details)
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.themeColors,
    required this.onTap,
    required this.isEnabled,
    this.useFaIcon = false,
  });

  final IconData icon;
  final String label;
  final dynamic themeColors;
  final VoidCallback onTap;
  final bool isEnabled;
  final bool useFaIcon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: isEnabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: themeColors.glassBackground,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isEnabled
                  ? themeColors.glassBorder
                  : themeColors.textSecondary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              useFaIcon
                  ? FaIcon(
                      icon,
                      color: isEnabled ? themeColors.textPrimary : themeColors.textSecondary,
                      size: 20,
                    )
                  : Icon(
                      icon,
                      color: isEnabled ? themeColors.textPrimary : themeColors.textSecondary,
                      size: 22,
                    ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: isEnabled ? themeColors.textPrimary : themeColors.textSecondary,
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

/// Quick log button (visit, gift, event) - with solid gradient
class _QuickLogButton extends StatelessWidget {
  const _QuickLogButton({
    required this.icon,
    required this.label,
    required this.themeColors,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final dynamic themeColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              themeColors.primary.withValues(alpha: 0.9),
              themeColors.primaryLight.withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: [
            BoxShadow(
              color: themeColors.primary.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: themeColors.onPrimary,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: themeColors.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// AI conversation starters button - full width, prominent
class _AIConversationButton extends StatelessWidget {
  const _AIConversationButton({
    required this.themeColors,
    required this.onTap,
  });

  final dynamic themeColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              themeColors.primary,
              themeColors.primaryLight,
            ],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: [
            BoxShadow(
              color: themeColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.sparkles,
              color: themeColors.onPrimary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'أفكار للحديث',
              style: AppTypography.labelLarge.copyWith(
                color: themeColors.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'AI',
                style: AppTypography.labelSmall.copyWith(
                  color: themeColors.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
