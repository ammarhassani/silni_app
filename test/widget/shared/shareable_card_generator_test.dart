import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/shared/widgets/shareable_card_generator.dart';

void main() {
  group('ShareableCardData', () {
    group('streak factory', () {
      test('contains streak number in title', () {
        final data = ShareableCardData.streak(streak: 30);
        expect(data.title, contains('30'));
      });

      test('contains streak number in share text', () {
        final data = ShareableCardData.streak(streak: 7);
        expect(data.shareText, contains('7'));
      });

      test('uses generic text when relativeName is not provided', () {
        final data = ShareableCardData.streak(streak: 14);
        expect(data.subtitle, contains('14'));
        expect(data.subtitle, contains('تواصل'));
      });

      test('contains relative name when provided', () {
        final data = ShareableCardData.streak(
          streak: 10,
          relativeName: 'أحمد',
        );
        expect(data.subtitle, contains('أحمد'));
        expect(data.shareText, contains('أحمد'));
      });

      test('has fire emoji', () {
        final data = ShareableCardData.streak(streak: 5);
        expect(data.emoji, '\u{1F525}');
      });
    });

    group('badge factory', () {
      test('contains badge name in title', () {
        final data = ShareableCardData.badge(
          badgeName: 'واصل الليل',
          badgeEmoji: '🌙',
        );
        expect(data.title, contains('واصل الليل'));
      });

      test('contains badge name in share text', () {
        final data = ShareableCardData.badge(
          badgeName: 'واصل الليل',
          badgeEmoji: '🌙',
        );
        expect(data.shareText, contains('واصل الليل'));
      });

      test('uses provided badge emoji', () {
        final data = ShareableCardData.badge(
          badgeName: 'المبادر',
          badgeEmoji: '🚀',
        );
        expect(data.emoji, '🚀');
      });
    });

    group('levelUp factory', () {
      test('contains level number in title', () {
        final data = ShareableCardData.levelUp(newLevel: 5);
        expect(data.title, contains('5'));
      });

      test('contains level number in share text', () {
        final data = ShareableCardData.levelUp(newLevel: 10);
        expect(data.shareText, contains('10'));
      });

      test('has star emoji', () {
        final data = ShareableCardData.levelUp(newLevel: 3);
        expect(data.emoji, '\u{2B50}');
      });
    });

    group('share text quality', () {
      test('streak share text does not contain promotional words', () {
        final data = ShareableCardData.streak(streak: 30);
        expect(data.shareText, isNot(contains('حمّل')));
        expect(data.shareText, isNot(contains('Download')));
        expect(data.shareText, isNot(contains('download')));
      });

      test('badge share text does not contain promotional words', () {
        final data = ShareableCardData.badge(
          badgeName: 'واصل الليل',
          badgeEmoji: '🌙',
        );
        expect(data.shareText, isNot(contains('حمّل')));
        expect(data.shareText, isNot(contains('Download')));
        expect(data.shareText, isNot(contains('download')));
      });

      test('level-up share text does not contain promotional words', () {
        final data = ShareableCardData.levelUp(newLevel: 5);
        expect(data.shareText, isNot(contains('حمّل')));
        expect(data.shareText, isNot(contains('Download')));
        expect(data.shareText, isNot(contains('download')));
      });

      test('streak share text with relativeName does not contain promotional words', () {
        final data = ShareableCardData.streak(
          streak: 14,
          relativeName: 'خالد',
        );
        expect(data.shareText, isNot(contains('حمّل')));
        expect(data.shareText, isNot(contains('Download')));
        expect(data.shareText, isNot(contains('download')));
      });
    });
  });
}
