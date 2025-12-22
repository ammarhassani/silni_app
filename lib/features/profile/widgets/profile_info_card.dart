import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/app_themes.dart';
import '../../../shared/widgets/glass_card.dart';

/// Card displaying user account information
class ProfileInfoCard extends StatelessWidget {
  const ProfileInfoCard({
    super.key,
    required this.user,
    required this.themeColors,
  });

  final dynamic user;
  final ThemeColors themeColors;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: themeColors.accent),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'معلومات الحساب',
                style: AppTypography.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          _ProfileInfoRow(
            icon: Icons.email_outlined,
            label: 'البريد الإلكتروني',
            value: user?.email ?? 'غير متوفر',
            themeColors: themeColors,
          ),

          const SizedBox(height: AppSpacing.md),

          _ProfileInfoRow(
            icon: Icons.verified_user_outlined,
            label: 'حالة التحقق',
            value: user?.emailConfirmedAt != null
                ? 'تم التحقق ✓'
                : 'لم يتم التحقق',
            themeColors: themeColors,
          ),

          const SizedBox(height: AppSpacing.md),

          _ProfileInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'تاريخ الانضمام',
            value: user?.createdAt != null
                ? _formatDate(_parseDateTime(user!.createdAt))
                : 'غير متوفر',
            themeColors: themeColors,
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.1, end: 0);
  }

  DateTime _parseDateTime(dynamic date) {
    if (date == null) {
      return DateTime.now();
    }

    if (date is DateTime) {
      return date;
    }

    if (date is String) {
      try {
        return DateTime.parse(date);
      } catch (e) {
        return DateTime.now();
      }
    }

    return DateTime.now();
  }

  String _formatDate(DateTime date) {
    final months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.themeColors,
  });

  final IconData icon;
  final String label;
  final String value;
  final ThemeColors themeColors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: themeColors.primary.withValues(alpha: 0.2),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
