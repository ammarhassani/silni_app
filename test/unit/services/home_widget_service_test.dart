import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/features/widgets/home_widget_service.dart';

void main() {
  group('HomeWidgetService', () {
    group('toArabicNumerals', () {
      test('converts 0', () {
        expect(HomeWidgetService.toArabicNumerals(0), '\u0660');
      });

      test('converts single digit', () {
        expect(HomeWidgetService.toArabicNumerals(5), '\u0665');
      });

      test('converts multi-digit number', () {
        expect(HomeWidgetService.toArabicNumerals(45), '\u0664\u0665');
      });

      test('converts large number', () {
        expect(HomeWidgetService.toArabicNumerals(100), '\u0661\u0660\u0660');
      });

      test('converts all digits 0-9', () {
        expect(
          HomeWidgetService.toArabicNumerals(1234567890),
          '\u0661\u0662\u0663\u0664\u0665\u0666\u0667\u0668\u0669\u0660',
        );
      });

      test('converts streak-like numbers', () {
        // "أمي 🔥٤٥" scenario
        expect(HomeWidgetService.toArabicNumerals(45), '\u0664\u0665');
        // Single day streak
        expect(HomeWidgetService.toArabicNumerals(1), '\u0661');
        // High streak
        expect(HomeWidgetService.toArabicNumerals(365), '\u0663\u0666\u0665');
      });

      test('handles negative numbers defensively', () {
        expect(HomeWidgetService.toArabicNumerals(-1), '\u0661');
        expect(HomeWidgetService.toArabicNumerals(-45), '\u0664\u0665');
      });
    });
  });
}
