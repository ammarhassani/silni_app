import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/shared/widgets/shareable_card_generator.dart';

void main() {
  group('ShareableCardData', () {
    group('streak factory', () {
      test('creates card with relativeName', () {
        final card = ShareableCardData.streak(
          streak: 7,
          relativeName: 'أحمد',
        );

        expect(card.emoji, '\u{1F525}');
        expect(card.title, '7 يوم متتالي!');
        expect(card.subtitle, 'سلسلة 7 يوم من التواصل مع أحمد!');
        expect(card.shareText,
            'الحمدلله، 7 يوم وأنا أتواصل مع أحمد بدون انقطاع!');
      });

      test('creates card without relativeName', () {
        final card = ShareableCardData.streak(streak: 30);

        expect(card.emoji, '\u{1F525}');
        expect(card.title, '30 يوم متتالي!');
        expect(card.subtitle, 'سلسلة 30 يوم من التواصل!');
        expect(card.shareText, 'الحمدلله، 30 يوم تواصل بدون انقطاع!');
      });
    });

    group('badge factory', () {
      test('creates card with badge info', () {
        final card = ShareableCardData.badge(
          badgeName: 'واصل الأرحام',
          badgeEmoji: '\u{1F3C6}',
        );

        expect(card.emoji, '\u{1F3C6}');
        expect(card.title, 'واصل الأرحام');
        expect(card.subtitle, 'حصلت على وسام جديد!');
        expect(card.shareText,
            'الحمدلله، حصلت على وسام "واصل الأرحام" في صلة الرحم!');
      });
    });

    group('levelUp factory', () {
      test('creates card with new level', () {
        final card = ShareableCardData.levelUp(newLevel: 5);

        expect(card.emoji, '\u{2B50}');
        expect(card.title, 'المستوى 5');
        expect(card.subtitle, 'وصلت لمستوى جديد!');
        expect(
            card.shareText, 'الحمدلله، وصلت للمستوى 5 في صلة الرحم!');
      });
    });

    group('occasion factory', () {
      test('creates card with familyName', () {
        final card = ShareableCardData.occasion(
          occasionName: 'عيد الفطر',
          occasionEmoji: '\u{1F319}',
          familyName: 'العمري',
        );

        expect(card.emoji, '\u{1F319}');
        expect(card.title, 'عيد الفطر');
        expect(card.subtitle, 'عيد الفطر مبارك يا عائلة العمري!');
        expect(card.shareText,
            'عيد الفطر مبارك! كل عام وعائلة العمري بخير 🤍 #صِلني');
      });

      test('creates card with relativeName (takes priority over familyName)',
          () {
        final card = ShareableCardData.occasion(
          occasionName: 'رمضان',
          occasionEmoji: '\u{2728}',
          familyName: 'العمري',
          relativeName: 'خالد',
        );

        expect(card.emoji, '\u{2728}');
        expect(card.title, 'رمضان');
        expect(card.subtitle, 'رمضان مبارك يا خالد!');
        expect(card.shareText, 'رمضان مبارك! كل عام وخالد بخير 🤍 #صِلني');
      });

      test('creates card without familyName or relativeName', () {
        final card = ShareableCardData.occasion(
          occasionName: 'اليوم الوطني',
          occasionEmoji: '\u{1F1F8}\u{1F1E6}',
        );

        expect(card.emoji, '\u{1F1F8}\u{1F1E6}');
        expect(card.title, 'اليوم الوطني');
        expect(card.subtitle, 'اليوم الوطني مبارك!');
        expect(card.shareText,
            'اليوم الوطني مبارك! كل عام وأنتم بخير 🤍 #صِلني');
      });
    });

    group('wrapped factory', () {
      test('creates card with all fields', () {
        final card = ShareableCardData.wrapped(
          periodName: 'يناير 2025',
          personalityEmoji: '\u{1F31F}',
          personalityLabel: 'الواصل الدائم',
          totalInteractions: 45,
          uniqueRelatives: 12,
        );

        expect(card.emoji, '\u{1F31F}');
        expect(card.title, 'الواصل الدائم');
        expect(card.subtitle,
            'ملخص يناير 2025: 45 تواصل مع 12 شخص');
        expect(card.shareText,
            'ملخص يناير 2025: تواصلت 45 مرة مع 12 شخص! '
            'شخصيتي: الواصل الدائم \u{1F31F} #صِلني');
      });
    });
  });
}
