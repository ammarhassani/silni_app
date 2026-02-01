import '../../../shared/models/relative_model.dart';

/// Service that analyzes the existing family tree and provides intelligent
/// suggestions for new relationship types and gender inference from Arabic names.
///
/// All methods are static and pure (no side effects), making this easy to test.
class RelationshipInferenceService {
  RelationshipInferenceService._();

  /// Analyzes gaps in the family tree and returns relationship types
  /// in suggested order (most likely first).
  ///
  /// Returns 4-6 suggestions based on which relatives already exist.
  static List<RelationshipType> suggestRelationships(
    List<Relative> existingRelatives,
  ) {
    final existingTypes = existingRelatives
        .map((r) => r.relationshipType)
        .toSet();

    final suggestions = <RelationshipType>[];

    // 1. If no parents exist, suggest parents first
    final hasParents = existingTypes.contains(RelationshipType.father) &&
        existingTypes.contains(RelationshipType.mother);
    final hasFather = existingTypes.contains(RelationshipType.father);
    final hasMother = existingTypes.contains(RelationshipType.mother);

    if (!hasFather) suggestions.add(RelationshipType.father);
    if (!hasMother) suggestions.add(RelationshipType.mother);

    // 2. If parents exist but no spouse, suggest spouse
    if (hasParents) {
      final hasSpouse = existingTypes.contains(RelationshipType.husband) ||
          existingTypes.contains(RelationshipType.wife);
      if (!hasSpouse) {
        suggestions.add(RelationshipType.husband);
        suggestions.add(RelationshipType.wife);
      }
    }

    // 3. If parents exist but no siblings, suggest siblings
    if (hasParents) {
      final hasSiblings = existingTypes.contains(RelationshipType.brother) ||
          existingTypes.contains(RelationshipType.sister);
      if (!hasSiblings) {
        suggestions.add(RelationshipType.brother);
        suggestions.add(RelationshipType.sister);
      }
    }

    // If we already have enough suggestions, cap and return
    if (suggestions.length >= 6) {
      return suggestions.sublist(0, 6);
    }

    // 4. If immediate family exists but no grandparents, suggest them
    final hasGrandparents =
        existingTypes.contains(RelationshipType.grandfather) ||
            existingTypes.contains(RelationshipType.grandmother);
    if (!hasGrandparents) {
      if (!existingTypes.contains(RelationshipType.grandfather)) {
        suggestions.add(RelationshipType.grandfather);
      }
      if (!existingTypes.contains(RelationshipType.grandmother)) {
        suggestions.add(RelationshipType.grandmother);
      }
    }

    if (suggestions.length >= 6) {
      return suggestions.sublist(0, 6);
    }

    // 5. If close family exists but no uncles/aunts, suggest them
    final hasUnclesAunts = existingTypes.contains(RelationshipType.uncle) ||
        existingTypes.contains(RelationshipType.aunt);
    if (!hasUnclesAunts) {
      suggestions.add(RelationshipType.uncle);
      suggestions.add(RelationshipType.aunt);
    }

    if (suggestions.length >= 6) {
      return suggestions.sublist(0, 6);
    }

    // Fill remaining slots with children, nephew/niece, cousin, other
    final fillers = [
      RelationshipType.son,
      RelationshipType.daughter,
      RelationshipType.brother,
      RelationshipType.sister,
      RelationshipType.cousin,
      RelationshipType.other,
    ];

    for (final type in fillers) {
      if (!suggestions.contains(type)) {
        suggestions.add(type);
      }
      if (suggestions.length >= 6) break;
    }

    // Safety: always return at least 4 items, never more than 6
    if (suggestions.length < 4) {
      // Add remaining types that aren't already suggested
      for (final type in RelationshipType.values) {
        if (!suggestions.contains(type)) {
          suggestions.add(type);
        }
        if (suggestions.length >= 4) break;
      }
    }

    return suggestions.length > 6 ? suggestions.sublist(0, 6) : suggestions;
  }

  /// Infers gender from an Arabic name using common patterns.
  ///
  /// Returns [Gender.male] or [Gender.female] for high-confidence matches,
  /// or `null` for ambiguous names.
  static Gender? inferGender(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    // Use first name only (split on space)
    final firstName = trimmed.split(' ').first;

    // Check against known male names first (exact match)
    if (_commonMaleNames.contains(firstName)) return Gender.male;

    // Check against known female names (exact match)
    if (_commonFemaleNames.contains(firstName)) return Gender.female;

    // Check against ambiguous names
    if (_ambiguousNames.contains(firstName)) return null;

    // Pattern-based inference:
    // Names ending in ة (taa marbouta) are almost always female
    if (firstName.endsWith('\u0629')) return Gender.female; // ة

    // Names ending in اء are often female
    if (firstName.endsWith('\u0627\u0621')) return Gender.female; // اء

    // Names starting with عبد (Abd) are always male
    if (firstName.startsWith('\u0639\u0628\u062F')) return Gender.male; // عبد

    // Cannot determine with confidence
    return null;
  }

  // Common Arabic male names
  static const _commonMaleNames = <String>{
    'محمد',
    'أحمد',
    'عبدالله',
    'عبدالرحمن',
    'عبدالعزيز',
    'سعد',
    'خالد',
    'عمر',
    'علي',
    'سلطان',
    'فهد',
    'تركي',
    'ناصر',
    'سعود',
    'يوسف',
    'إبراهيم',
    'حسن',
    'حسين',
    'مصطفى',
    'طارق',
    'سامي',
    'ماجد',
    'وليد',
    'عادل',
    'بندر',
    'فيصل',
    'بدر',
    'نواف',
    'مشاري',
    'صالح',
    'راشد',
    'سلمان',
    'عماد',
    'هاني',
    'أسامة',
    'زياد',
    'جاسم',
    'حمد',
    'منصور',
    'عمار',
  };

  // Common Arabic female names
  static const _commonFemaleNames = <String>{
    'فاطمة',
    'عائشة',
    'نورة',
    'سارة',
    'مريم',
    'هند',
    'لطيفة',
    'منيرة',
    'نوف',
    'غادة',
    'ريم',
    'أمل',
    'دانة',
    'لمى',
    'رنا',
    'هيا',
    'لينا',
    'جوهرة',
    'بدور',
    'شيخة',
    'موضي',
    'العنود',
    'خلود',
    'أسماء',
    'زينب',
    'رقية',
    'آمنة',
    'حصة',
    'مها',
    'سمية',
  };

  // Names that are common for both genders
  static const _ambiguousNames = <String>{
    'نور',
    'إيمان',
    'إحسان',
    'وسام',
    'هتون',
    'عصام',
    'رفاء',
    'ملاك',
    'رضا',
    'صفاء',
  };
}
