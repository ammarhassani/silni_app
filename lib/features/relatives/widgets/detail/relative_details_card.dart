import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/models/relative_model.dart';

/// Details card showing relative information
class RelativeDetailsCard extends ConsumerWidget {
  const RelativeDetailsCard({
    super.key,
    required this.relative,
  });

  final Relative relative;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.premiumGold),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'التفاصيل',
                style: AppTypography.titleLarge.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Phone
          if (relative.phoneNumber != null)
            _DetailRow(
              icon: Icons.phone,
              label: 'رقم الهاتف',
              value: relative.phoneNumber!,
            ),

          // Email
          if (relative.email != null) ...[
            const SizedBox(height: AppSpacing.md),
            _DetailRow(
              icon: Icons.email,
              label: 'البريد الإلكتروني',
              value: relative.email!,
            ),
          ],

          // Address
          if (relative.address != null) ...[
            const SizedBox(height: AppSpacing.md),
            _DetailRow(
              icon: Icons.location_on,
              label: 'العنوان',
              value: relative.address!,
            ),
          ],

          // City
          if (relative.city != null) ...[
            const SizedBox(height: AppSpacing.md),
            _DetailRow(
              icon: Icons.location_city,
              label: 'المدينة',
              value: relative.city!,
            ),
          ],

          // Notes
          if (relative.notes != null && relative.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _DetailRow(
              icon: Icons.note,
              label: 'ملاحظات',
              value: relative.notes!,
            ),
          ],

          // Best time to contact
          if (relative.bestTimeToContact != null) ...[
            const SizedBox(height: AppSpacing.md),
            _DetailRow(
              icon: Icons.schedule,
              label: 'أفضل وقت للتواصل',
              value: relative.bestTimeToContact!,
            ),
          ],

          // Gender
          if (relative.gender != null) ...[
            const SizedBox(height: AppSpacing.md),
            _DetailRow(
              icon: Icons.person,
              label: 'الجنس',
              value: relative.gender!.arabicName,
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends ConsumerWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: themeColors.primary, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(color: Colors.white70),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
