import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/shared/utils/family_name_formatter.dart';

void main() {
  group('normalizeFamilyGroupName (for storage)', () {
    test('strips leading "عائلة " prefix', () {
      expect(normalizeFamilyGroupName('عائلة الأحمد'), 'الأحمد');
    });

    test('strips leading "عائلة" with no separator space', () {
      expect(normalizeFamilyGroupName('عائلةالأحمد'), 'الأحمد');
    });

    test('returns name as-is if no prefix', () {
      expect(normalizeFamilyGroupName('الأحمد'), 'الأحمد');
    });

    test('trims surrounding whitespace', () {
      expect(normalizeFamilyGroupName('  الأحمد  '), 'الأحمد');
      expect(normalizeFamilyGroupName('  عائلة الأحمد  '), 'الأحمد');
    });

    test('handles double-prefixed input (defensive)', () {
      expect(normalizeFamilyGroupName('عائلة عائلة الأحمد'), 'الأحمد');
    });

    test('collapses internal whitespace inside the bare name', () {
      expect(normalizeFamilyGroupName('عائلة   الأحمد'), 'الأحمد');
    });
  });

  group('formatFamilyGroupDisplayName (for UI/notifications)', () {
    test('adds "عائلة " prefix when missing', () {
      expect(formatFamilyGroupDisplayName('الأحمد'), 'عائلة الأحمد');
    });

    test('idempotent — does not double the prefix', () {
      expect(formatFamilyGroupDisplayName('عائلة الأحمد'), 'عائلة الأحمد');
    });

    test('idempotent on already double-prefixed input', () {
      expect(
        formatFamilyGroupDisplayName('عائلة عائلة الأحمد'),
        'عائلة الأحمد',
      );
    });

    test('trims whitespace', () {
      expect(formatFamilyGroupDisplayName('  الأحمد  '), 'عائلة الأحمد');
    });

    test('handles empty / whitespace-only input by returning empty', () {
      expect(formatFamilyGroupDisplayName(''), '');
      expect(formatFamilyGroupDisplayName('   '), '');
    });
  });
}
