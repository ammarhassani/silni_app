import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/widgets/glass_card.dart';

/// A contextual relationship picker that shows suggested relationship types
/// as tappable cards in a grid, with an expandable section for all options.
class SmartRelationshipPicker extends StatefulWidget {
  /// Currently selected relationship type.
  final RelationshipType selected;

  /// Suggested relationship types (4-6 items) based on family tree analysis.
  final List<RelationshipType> suggestions;

  /// Called when the user selects a relationship type.
  final ValueChanged<RelationshipType> onChanged;

  const SmartRelationshipPicker({
    super.key,
    required this.selected,
    required this.suggestions,
    required this.onChanged,
  });

  @override
  State<SmartRelationshipPicker> createState() =>
      _SmartRelationshipPickerState();
}

class _SmartRelationshipPickerState extends State<SmartRelationshipPicker> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.family_restroom,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مين هالشخص لك؟',
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'اقتراحات ذكية بناءً على عائلتك',
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

          // Suggested relationships grid (2 columns)
          _buildSuggestionsGrid(),

          // Show All toggle
          const SizedBox(height: AppSpacing.sm),
          _buildShowAllToggle(),

          // All relationships (expandable)
          if (_showAll) ...[
            const SizedBox(height: AppSpacing.md),
            _buildAllRelationships(),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 2.2,
      ),
      itemCount: widget.suggestions.length,
      itemBuilder: (context, index) {
        final type = widget.suggestions[index];
        return _buildRelationshipCard(
          type: type,
          isSelected: type == widget.selected,
          animationDelay: Duration(milliseconds: 50 * index),
        );
      },
    );
  }

  Widget _buildRelationshipCard({
    required RelationshipType type,
    required bool isSelected,
    Duration animationDelay = Duration.zero,
  }) {
    final avatar = AvatarType.suggestFromRelationship(type, null);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onChanged(type);
      },
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        curve: AppAnimations.toggleCurve,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected
                ? AppColors.islamicGreenLight
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              avatar.emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                type.arabicName,
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: animationDelay)
        .fadeIn(duration: AppAnimations.normal)
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          duration: AppAnimations.normal,
        );
  }

  Widget _buildShowAllToggle() {
    return Center(
      child: TextButton.icon(
        onPressed: () {
          HapticFeedback.selectionClick();
          setState(() => _showAll = !_showAll);
        },
        icon: Icon(
          _showAll ? Icons.expand_less : Icons.expand_more,
          color: AppColors.islamicGreenLight,
          size: 20,
        ),
        label: Text(
          _showAll ? 'إخفاء الكل' : 'عرض الكل',
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.islamicGreenLight,
          ),
        ),
      ),
    );
  }

  Widget _buildAllRelationships() {
    // Filter out types already shown in suggestions
    final remaining = RelationshipType.values
        .where((type) => !widget.suggestions.contains(type))
        .toList();

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: remaining.asMap().entries.map((entry) {
        final index = entry.key;
        final type = entry.value;
        final isSelected = type == widget.selected;
        final avatar = AvatarType.suggestFromRelationship(type, null);

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onChanged(type);
          },
          child: AnimatedContainer(
            duration: AppAnimations.fast,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.primaryGradient : null,
              color:
                  isSelected ? null : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: isSelected
                    ? AppColors.islamicGreenLight
                    : Colors.white.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.islamicGreenPrimary
                            .withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  avatar.emoji,
                  style: TextStyle(fontSize: isSelected ? 20 : 16),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  type.arabicName,
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        )
            .animate(delay: Duration(milliseconds: 30 * index))
            .fadeIn(duration: AppAnimations.fast)
            .slideY(begin: 0.1, end: 0, duration: AppAnimations.fast);
      }).toList(),
    );
  }
}
