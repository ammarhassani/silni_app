import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../family_tree/models/family_graph.dart';

/// Relationship types that require a "which side?" (من طرف أبوك ولا أمك؟)
/// follow-up question to correctly place in the family tree.
///
/// Uncle/aunt are NOT here — they are split into عم/خال and عمة/خالة buttons
/// with auto-set family side (no prompt needed).
const _extendedFamilyTypes = {
  RelationshipType.cousin,
  RelationshipType.grandfather,
  RelationshipType.grandmother,
};

/// Types that are split into paternal/maternal variants in the picker.
const _splitFamilyTypes = {
  RelationshipType.uncle,
  RelationshipType.aunt,
};

/// A contextual relationship picker that shows suggested relationship types
/// as tappable cards in a grid, with an expandable section for all options.
///
/// When an extended family type is selected, a follow-up "which side?"
/// (من طرف أبوك ولا أمك؟) selector appears automatically.
/// Relationship types that can only exist once in a family tree.
const _singletonTypes = {
  RelationshipType.father,
  RelationshipType.mother,
  RelationshipType.husband,
  RelationshipType.wife,
};

/// Types that exist once per family side (paternal + maternal = 2 max).
const _perSideSingletonTypes = {
  RelationshipType.grandfather,
  RelationshipType.grandmother,
};

class SmartRelationshipPicker extends StatefulWidget {
  /// Currently selected relationship type.
  final RelationshipType selected;

  /// Suggested relationship types (4-6 items) based on family tree analysis.
  final List<RelationshipType> suggestions;

  /// Called when the user selects a relationship type.
  final ValueChanged<RelationshipType> onChanged;

  /// Called when the user selects a family side (paternal/maternal).
  final ValueChanged<FamilySide?>? onSideChanged;

  /// Currently selected family side.
  final FamilySide? selectedSide;

  /// Existing relatives — used to hide singleton types that are already filled.
  final List<Relative> existingRelatives;

  const SmartRelationshipPicker({
    super.key,
    required this.selected,
    required this.suggestions,
    required this.onChanged,
    this.onSideChanged,
    this.selectedSide,
    this.existingRelatives = const [],
  });

  @override
  State<SmartRelationshipPicker> createState() =>
      _SmartRelationshipPickerState();
}

class _SmartRelationshipPickerState extends State<SmartRelationshipPicker> {
  bool _showAll = false;

  /// Types that should be hidden because all slots are filled.
  Set<RelationshipType> get _filledSingletons {
    final relatives = widget.existingRelatives;
    final existingTypes = relatives.map((r) => r.relationshipType).toSet();

    // Simple singletons: one allowed total.
    final filled = _singletonTypes.intersection(existingTypes);

    // Per-side singletons: one per side, hidden when both sides filled.
    for (final type in _perSideSingletonTypes) {
      final ofType = relatives.where((r) => r.relationshipType == type);
      final sides = ofType.map((r) => r.familySide).toSet();
      if (sides.contains(FamilySide.paternal) &&
          sides.contains(FamilySide.maternal)) {
        filled.add(type);
      }
    }

    return filled;
  }

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

          // "Which side?" selector for extended family
          if (_extendedFamilyTypes.contains(widget.selected) &&
              widget.onSideChanged != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildSideSelector(),
          ],

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
    final filled = _filledSingletons;

    // Expand suggestions: split uncle/aunt into paternal + maternal variants.
    // Skip singleton types that are already filled.
    final expanded = <_PickerEntry>[];
    for (final type in widget.suggestions) {
      if (filled.contains(type)) continue;
      if (_splitFamilyTypes.contains(type)) {
        final isUncle = type == RelationshipType.uncle;
        expanded.add(_PickerEntry(
          type: type,
          label: isUncle ? 'عم' : 'عمة',
          side: FamilySide.paternal,
        ));
        expanded.add(_PickerEntry(
          type: type,
          label: isUncle ? 'خال' : 'خالة',
          side: FamilySide.maternal,
        ));
      } else {
        expanded.add(_PickerEntry(type: type));
      }
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 2.2,
      ),
      itemCount: expanded.length,
      itemBuilder: (context, index) {
        final item = expanded[index];
        return _buildRelationshipCard(
          type: item.type,
          label: item.label,
          side: item.side,
          isSelected: item.type == widget.selected &&
              (item.side == null || item.side == widget.selectedSide),
          animationDelay: Duration(milliseconds: 50 * index),
        );
      },
    );
  }

  Widget _buildRelationshipCard({
    required RelationshipType type,
    required bool isSelected,
    String? label,
    FamilySide? side,
    Duration animationDelay = Duration.zero,
  }) {
    final avatar = AvatarType.suggestFromRelationship(type, null);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onChanged(type);
        if (side != null) {
          widget.onSideChanged?.call(side);
        }
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
                label ?? type.arabicName,
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

  Widget _buildSideSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'من طرف أبوك ولا أمك؟',
          style: AppTypography.labelMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildSideButton(
                label: 'طرف أبوي',
                emoji: '👨',
                side: FamilySide.paternal,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildSideButton(
                label: 'طرف أمي',
                emoji: '👩',
                side: FamilySide.maternal,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: AppAnimations.fast).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSideButton({
    required String label,
    required String emoji,
    required FamilySide side,
  }) {
    final isSelected = widget.selectedSide == side;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onSideChanged?.call(isSelected ? null : side);
      },
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        curve: AppAnimations.toggleCurve,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
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
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
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
    final filled = _filledSingletons;

    // Filter out types already shown in suggestions and filled singletons.
    final remaining = RelationshipType.values
        .where((type) =>
            !widget.suggestions.contains(type) && !filled.contains(type))
        .toList();

    // Build display entries, splitting uncle/aunt into paternal + maternal.
    final entries = <_PickerEntry>[];
    for (final type in remaining) {
      if (_splitFamilyTypes.contains(type)) {
        // Split: عم / خال  or  عمة / خالة
        final isUncle = type == RelationshipType.uncle;
        entries.add(_PickerEntry(
          type: type,
          label: isUncle ? 'عم' : 'عمة',
          side: FamilySide.paternal,
        ));
        entries.add(_PickerEntry(
          type: type,
          label: isUncle ? 'خال' : 'خالة',
          side: FamilySide.maternal,
        ));
      } else {
        entries.add(_PickerEntry(type: type));
      }
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: entries.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isSelected = item.type == widget.selected &&
            (item.side == null || item.side == widget.selectedSide);
        final avatar = AvatarType.suggestFromRelationship(item.type, null);

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onChanged(item.type);
            if (item.side != null) {
              widget.onSideChanged?.call(item.side);
            }
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
                  item.label,
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

/// A display entry in the "show all" picker, optionally with a pre-set side.
class _PickerEntry {
  final RelationshipType type;
  final String label;
  final FamilySide? side;

  _PickerEntry({required this.type, this.side, String? label})
      : label = label ?? type.arabicName;
}
