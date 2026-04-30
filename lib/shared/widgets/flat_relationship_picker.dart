import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../models/relative_model.dart';
import '../../features/family_tree/models/family_graph.dart';

/// A single entry in the flat relationship picker grid.
/// Each entry maps to exactly one (type, side, gender) tuple.
typedef RelationshipEntry = ({
  RelationshipType type,
  FamilySide? side,
  Gender? gender,
  String label,
  String emoji,
});

/// A section grouping entries under a header label.
typedef _Section = ({String header, String icon, List<RelationshipEntry> entries});

/// All possible relationship entries, grouped by generation.
List<_Section> _buildSections() {
  return [
    (
      header: 'الأهل',
      icon: '👨‍👩‍👦',
      entries: [
        (type: RelationshipType.father, side: null, gender: Gender.male, label: 'أب', emoji: '🧔'),
        (type: RelationshipType.mother, side: null, gender: Gender.female, label: 'أم', emoji: '🧕'),
        // Informal possessive form: literally "father/mother of my
        // dad/mom" — unambiguous in Saudi conversational Arabic. The
        // earlier "جد أبي" / "جدة أبي" forms accidentally meant
        // "great-grandfather" (grandfather of my dad), one generation
        // off. The relationship type stored is still grandfather/
        // grandmother + the paternal/maternal FamilySide; only the
        // picker label changes.
        (type: RelationshipType.grandfather, side: FamilySide.paternal, gender: Gender.male, label: 'أبو أبي', emoji: '👴'),
        (type: RelationshipType.grandmother, side: FamilySide.paternal, gender: Gender.female, label: 'أم أبي', emoji: '👵'),
        (type: RelationshipType.grandfather, side: FamilySide.maternal, gender: Gender.male, label: 'أبو أمي', emoji: '👴'),
        (type: RelationshipType.grandmother, side: FamilySide.maternal, gender: Gender.female, label: 'أم أمي', emoji: '👵'),
      ],
    ),
    (
      header: 'الزوج',
      icon: '💍',
      entries: [
        (type: RelationshipType.husband, side: null, gender: Gender.male, label: 'زوج', emoji: '🧔'),
        (type: RelationshipType.wife, side: null, gender: Gender.female, label: 'زوجة', emoji: '🧕'),
      ],
    ),
    (
      header: 'الإخوان',
      icon: '👫',
      entries: [
        (type: RelationshipType.brother, side: null, gender: Gender.male, label: 'أخ', emoji: '👨'),
        (type: RelationshipType.sister, side: null, gender: Gender.female, label: 'أخت', emoji: '🧕'),
      ],
    ),
    (
      header: 'الأعمام',
      icon: '👨‍👦',
      entries: [
        (type: RelationshipType.uncle, side: FamilySide.paternal, gender: Gender.male, label: 'عم', emoji: '🧔'),
        (type: RelationshipType.uncle, side: FamilySide.maternal, gender: Gender.male, label: 'خال', emoji: '🧔'),
        (type: RelationshipType.aunt, side: FamilySide.paternal, gender: Gender.female, label: 'عمة', emoji: '🧕'),
        (type: RelationshipType.aunt, side: FamilySide.maternal, gender: Gender.female, label: 'خالة', emoji: '🧕'),
      ],
    ),
    (
      header: 'الأقارب',
      icon: '👥',
      entries: [
        (type: RelationshipType.cousin, side: FamilySide.paternal, gender: Gender.male, label: 'ابن العم', emoji: '👨'),
        (type: RelationshipType.cousin, side: FamilySide.paternal, gender: Gender.female, label: 'بنت العم', emoji: '👩'),
        (type: RelationshipType.cousin, side: FamilySide.maternal, gender: Gender.male, label: 'ابن الخال', emoji: '👨'),
        (type: RelationshipType.cousin, side: FamilySide.maternal, gender: Gender.female, label: 'بنت الخال', emoji: '👩'),
      ],
    ),
    (
      header: 'الأبناء',
      icon: '👶',
      entries: [
        (type: RelationshipType.son, side: null, gender: Gender.male, label: 'ابن', emoji: '👦'),
        (type: RelationshipType.daughter, side: null, gender: Gender.female, label: 'ابنة', emoji: '👧'),
        (type: RelationshipType.nephew, side: null, gender: Gender.male, label: 'ابن أخ/أخت', emoji: '🧑'),
        (type: RelationshipType.niece, side: null, gender: Gender.female, label: 'ابنة أخ/أخت', emoji: '👧'),
      ],
    ),
    (
      header: 'أخرى',
      icon: '➕',
      entries: [
        (type: RelationshipType.other, side: null, gender: null, label: 'أخرى', emoji: '👤'),
      ],
    ),
  ];
}

/// Relationship types that can only exist once total.
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

/// A compact relationship picker with horizontal category tabs and a card grid.
/// Every card maps to exactly one (type, side, gender) tuple.
///
/// Used in add-relative, contact-import, and family-tree flows.
class FlatRelationshipPicker extends StatefulWidget {
  const FlatRelationshipPicker({
    super.key,
    required this.selectedType,
    required this.onSelectionChanged,
    this.selectedSide,
    this.selectedGender,
    this.existingRelatives = const [],
  });

  final RelationshipType selectedType;
  final FamilySide? selectedSide;
  final Gender? selectedGender;
  final List<Relative> existingRelatives;
  final void Function(RelationshipType type, FamilySide? side, Gender? gender) onSelectionChanged;

  @override
  State<FlatRelationshipPicker> createState() => _FlatRelationshipPickerState();
}

class _FlatRelationshipPickerState extends State<FlatRelationshipPicker> {
  late int _activeTabIndex;
  late List<_Section> _sections;
  late Set<RelationshipEntry> _hidden;

  @override
  void initState() {
    super.initState();
    _sections = _buildSections();
    _hidden = _computeHidden();
    _activeTabIndex = _findTabForSelection();
  }

  @override
  void didUpdateWidget(FlatRelationshipPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.existingRelatives != widget.existingRelatives) {
      _hidden = _computeHidden();
    }
  }

  Set<RelationshipEntry> _computeHidden() {
    final hidden = <RelationshipEntry>{};
    final existingTypes = widget.existingRelatives.map((r) => r.relationshipType).toSet();

    for (final section in _sections) {
      for (final entry in section.entries) {
        if (_singletonTypes.contains(entry.type) && existingTypes.contains(entry.type)) {
          hidden.add(entry);
          continue;
        }
        if (_perSideSingletonTypes.contains(entry.type)) {
          final filled = widget.existingRelatives.any(
            (r) => r.relationshipType == entry.type && r.familySide == entry.side,
          );
          if (filled) hidden.add(entry);
        }
      }
    }
    return hidden;
  }

  /// Find which tab contains the currently selected entry.
  int _findTabForSelection() {
    for (var i = 0; i < _sections.length; i++) {
      for (final entry in _sections[i].entries) {
        if (_isSelected(entry)) return i;
      }
    }
    return 0;
  }

  bool _isSelected(RelationshipEntry entry) {
    if (entry.type != widget.selectedType) return false;
    if (entry.side != null && entry.side != widget.selectedSide) return false;
    if (entry.gender != null && entry.gender != widget.selectedGender) return false;
    return true;
  }

  /// Visible sections (those with at least one non-hidden entry).
  List<(int, _Section)> get _visibleSections {
    return [
      for (var i = 0; i < _sections.length; i++)
        if (_sections[i].entries.any((e) => !_hidden.contains(e)))
          (i, _sections[i]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleSections;
    // Clamp active tab to valid range
    if (!visible.any((v) => v.$1 == _activeTabIndex)) {
      _activeTabIndex = visible.isNotEmpty ? visible.first.$1 : 0;
    }

    final activeSection = _sections[_activeTabIndex];
    final activeEntries = activeSection.entries.where((e) => !_hidden.contains(e)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Category tabs — horizontal scrollable
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            itemCount: visible.length,
            separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.xs),
            itemBuilder: (context, index) {
              final (sectionIndex, section) = visible[index];
              final isActive = sectionIndex == _activeTabIndex;
              // Check if this tab contains the selected entry
              final containsSelection = section.entries.any((e) => _isSelected(e));

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _activeTabIndex = sectionIndex);
                },
                child: AnimatedContainer(
                  duration: AppAnimations.fast,
                  curve: AppAnimations.toggleCurve,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    gradient: isActive ? AppColors.primaryGradient : null,
                    color: isActive ? null : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: containsSelection && !isActive
                        ? Border.all(color: AppColors.islamicGreenLight.withValues(alpha: 0.5), width: 1)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(section.icon, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 3),
                      Text(
                        section.header,
                        style: AppTypography.labelSmall.copyWith(
                          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.7),
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Card grid for active section (3 columns)
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          crossAxisSpacing: AppSpacing.xs,
          mainAxisSpacing: AppSpacing.xs,
          childAspectRatio: 1.1,
          children: [
            for (final (i, entry) in activeEntries.indexed)
              _RelationshipCard(
                key: ValueKey('${entry.type}-${entry.side}-${entry.gender}'),
                entry: entry,
                isSelected: _isSelected(entry),
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onSelectionChanged(entry.type, entry.side, entry.gender);
                },
                animationDelay: Duration(milliseconds: 30 * i),
              ),
          ],
        ),
      ],
    );
  }
}

class _RelationshipCard extends StatelessWidget {
  const _RelationshipCard({
    super.key,
    required this.entry,
    required this.isSelected,
    required this.onTap,
    required this.animationDelay,
  });

  final RelationshipEntry entry;
  final bool isSelected;
  final VoidCallback onTap;
  final Duration animationDelay;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        curve: AppAnimations.toggleCurve,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected
                ? AppColors.islamicGreenLight
                : Colors.white.withValues(alpha: 0.15),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.islamicGreenPrimary.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              entry.emoji,
              style: TextStyle(fontSize: isSelected ? 22 : 20),
            ),
            const SizedBox(height: 4),
            Text(
              entry.label,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    )
        .animate(delay: animationDelay)
        .fadeIn(duration: AppAnimations.normal)
        .scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1, 1),
          duration: AppAnimations.normal,
        );
  }
}
