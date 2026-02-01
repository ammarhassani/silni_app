import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/core/constants/notification_templates.dart';

void main() {
  group('NotificationTemplates', () {
    test('returns dialect reminder for 3-day gap', () {
      final text = NotificationTemplates.getReminder(
        relativeName: 'عمك سعد',
        daysSinceContact: 3,
      );
      expect(text, isNotEmpty);
      expect(text, contains('عمك سعد'));
      // Should not contain formal Arabic patterns
      expect(text, isNot(contains('تذكير:')));
    });

    test('escalates tone for 14-day gap', () {
      final text = NotificationTemplates.getReminder(
        relativeName: 'أبوك',
        daysSinceContact: 14,
      );
      expect(text, contains('أبوك'));
      expect(text, contains('أسبوعين'));
    });

    test('heavy tone for 30-day gap', () {
      final text = NotificationTemplates.getReminder(
        relativeName: 'جدتك',
        daysSinceContact: 30,
      );
      expect(text, contains('جدتك'));
      expect(text, contains('شهر'));
    });

    test('returns different text on subsequent calls (rotation)', () {
      final texts = List.generate(
        10,
        (_) => NotificationTemplates.getReminder(
          relativeName: 'أمك',
          daysSinceContact: 7,
        ),
      );
      // Should have at least 2 unique variations
      expect(texts.toSet().length, greaterThan(1));
    });
  });
}
