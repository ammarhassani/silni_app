import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../models/relative_model.dart';
import 'glass_card.dart';

/// Data class for category display info
class _CategoryInfo {
  final RelativeCategory category;
  final String emoji;
  final String label;
  final String hint;

  const _CategoryInfo({
    required this.category,
    required this.emoji,
    required this.label,
    required this.hint,
  });
}

const _categories = [
  _CategoryInfo(
    category: RelativeCategory.household,
    emoji: '\u{1F3E0}',
    label: 'أهل البيت',
    hint: 'تواصل يومي',
  ),
  _CategoryInfo(
    category: RelativeCategory.extended,
    emoji: '\u{1F4DE}',
    label: 'تواصل دائم',
    hint: 'تواصل أسبوعي',
  ),
  _CategoryInfo(
    category: RelativeCategory.distant,
    emoji: '\u{1F319}',
    label: 'مناسبات',
    hint: 'أعياد ومناسبات',
  ),
];

/// A reusable picker for selecting a relative's category
/// (household, extended, distant).
class RelativeCategoryPicker extends StatelessWidget {
  final RelativeCategory selected;
  final ValueChanged<RelativeCategory> onChanged;

  const RelativeCategoryPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.category_rounded,
                color: Colors.white.withValues(alpha: 0.7),
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تصنيف القريب',
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'يحدد وتيرة التذكير بالتواصل',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: _categories.map((info) {
              final isSelected = selected == info.category;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: info.category == _categories.first.category
                        ? 0
                        : AppSpacing.xs,
                    right: info.category == _categories.last.category
                        ? 0
                        : AppSpacing.xs,
                  ),
                  child: _buildCategoryCard(info, isSelected),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(_CategoryInfo info, bool isSelected) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(info.category);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:
                        AppColors.islamicGreenPrimary.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              info.emoji,
              style: TextStyle(fontSize: isSelected ? 28 : 24),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              info.label,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              info.hint,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
