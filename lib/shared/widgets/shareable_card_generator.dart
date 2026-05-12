import '../utils/family_name_formatter.dart';

/// Data model for shareable celebration cards.
///
/// Contains the text content and visual data needed to generate
/// a branded share card image.
class ShareableCardData {
  /// Large emoji displayed on the card
  final String emoji;

  /// Main title text on the card
  final String title;

  /// Subtitle / description text on the card
  final String subtitle;

  /// Natural-sounding share text sent alongside the image
  final String shareText;

  const ShareableCardData({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.shareText,
  });

  /// Create card data for a streak milestone celebration.
  ///
  /// [streak] - the number of consecutive days.
  /// [relativeName] - optional name of the relative (StreakMilestoneModal
  /// does not have this, so it defaults to generic text).
  factory ShareableCardData.streak({
    required int streak,
    String? relativeName,
  }) {
    final title = '$streak يوم متتالي!';
    final subtitle = relativeName != null
        ? 'سلسلة $streak يوم من التواصل مع $relativeName!'
        : 'سلسلة $streak يوم من التواصل!';
    final shareText = relativeName != null
        ? 'الحمدلله، $streak يوم وأنا أتواصل مع $relativeName بدون انقطاع!'
        : 'الحمدلله، $streak يوم تواصل بدون انقطاع!';

    return ShareableCardData(
      emoji: '\u{1F525}', // fire emoji
      title: title,
      subtitle: subtitle,
      shareText: shareText,
    );
  }

  /// Create card data for a badge unlock celebration.
  ///
  /// [badgeName] - the display name of the badge.
  /// [badgeEmoji] - the emoji for the badge.
  factory ShareableCardData.badge({
    required String badgeName,
    required String badgeEmoji,
  }) {
    return ShareableCardData(
      emoji: badgeEmoji,
      title: badgeName,
      subtitle: 'حصلت على وسام جديد!',
      shareText: 'الحمدلله، حصلت على وسام "$badgeName" في صلة الرحم!',
    );
  }

  /// Create card data for a level-up celebration.
  ///
  /// [newLevel] - the new level reached.
  factory ShareableCardData.levelUp({
    required int newLevel,
  }) {
    return ShareableCardData(
      emoji: '\u{2B50}', // star emoji
      title: 'المستوى $newLevel',
      subtitle: 'وصلت لمستوى جديد!',
      shareText: 'الحمدلله، وصلت للمستوى $newLevel في صلة الرحم!',
    );
  }

  /// Create card data for an occasion greeting card.
  ///
  /// [occasionName] - display name of the occasion (e.g. عيد الفطر).
  /// [occasionEmoji] - emoji representing the occasion.
  /// [familyName] - optional family name (used when no specific relative).
  /// [relativeName] - optional specific relative name (takes priority over familyName).
  factory ShareableCardData.occasion({
    required String occasionName,
    required String occasionEmoji,
    String? familyName,
    String? relativeName,
  }) {
    final target = relativeName ??
        (familyName != null ? formatFamilyGroupDisplayName(familyName) : null);
    final subtitle = target != null
        ? '$occasionName مبارك يا $target!'
        : '$occasionName مبارك!';
    final shareText = target != null
        ? '$occasionName مبارك! كل عام و$target بخير 🤍 #صِلْني'
        : '$occasionName مبارك! كل عام وأنتم بخير 🤍 #صِلْني';

    return ShareableCardData(
      emoji: occasionEmoji,
      title: occasionName,
      subtitle: subtitle,
      shareText: shareText,
    );
  }

  /// Create card data for a monthly/yearly wrapped summary.
  ///
  /// [periodName] - display name of the period (e.g. يناير 2025, ملخص السنة).
  /// [personalityEmoji] - emoji for the user's relationship personality.
  /// [personalityLabel] - label for the personality type (e.g. الواصل الدائم).
  /// [totalInteractions] - total number of interactions in the period.
  /// [uniqueRelatives] - number of unique relatives interacted with.
  factory ShareableCardData.wrapped({
    required String periodName,
    required String personalityEmoji,
    required String personalityLabel,
    required int totalInteractions,
    required int uniqueRelatives,
  }) {
    return ShareableCardData(
      emoji: personalityEmoji,
      title: personalityLabel,
      subtitle: 'ملخص $periodName: $totalInteractions تواصل مع $uniqueRelatives شخص',
      shareText: 'ملخص $periodName: تواصلت $totalInteractions مرة مع '
          '$uniqueRelatives شخص! شخصيتي: $personalityLabel $personalityEmoji '
          '#صِلْني',
    );
  }
}
