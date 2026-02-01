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
}
