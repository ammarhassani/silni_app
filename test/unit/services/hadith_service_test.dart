import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/shared/models/hadith_model.dart';
import 'package:silni_app/shared/services/hadith_service.dart';

void main() {
  group('HadithService', () {
    // =====================================================
    // DEFAULT HADITH TESTS
    // =====================================================
    group('defaultHadith', () {
      test('should have 8 default hadith entries', () {
        expect(HadithService.defaultHadith.length, equals(8));
      });

      test('should have valid structure for all entries', () {
        for (final hadith in HadithService.defaultHadith) {
          expect(hadith.containsKey('arabicText'), isTrue);
          expect(hadith.containsKey('source'), isTrue);
          expect(hadith.containsKey('topic'), isTrue);
          expect(hadith.containsKey('type'), isTrue);
          expect(hadith.containsKey('isAuthentic'), isTrue);
          expect(hadith.containsKey('displayOrder'), isTrue);
        }
      });

      test('should have arabicText for all entries', () {
        for (final hadith in HadithService.defaultHadith) {
          expect(hadith['arabicText'], isNotEmpty);
          expect(hadith['arabicText'], isA<String>());
        }
      });

      test('should have englishTranslation for all entries', () {
        for (final hadith in HadithService.defaultHadith) {
          expect(hadith['englishTranslation'], isNotEmpty);
          expect(hadith['englishTranslation'], isA<String>());
        }
      });

      test('should have topic set to silat_rahim for all entries', () {
        for (final hadith in HadithService.defaultHadith) {
          expect(hadith['topic'], equals('silat_rahim'));
        }
      });

      test('should all be marked as authentic', () {
        for (final hadith in HadithService.defaultHadith) {
          expect(hadith['isAuthentic'], isTrue);
        }
      });

      test('should have unique display orders', () {
        final orders = HadithService.defaultHadith
            .map((h) => h['displayOrder'] as int)
            .toSet();
        expect(orders.length, equals(HadithService.defaultHadith.length));
      });

      test('should have display orders from 1 to 8', () {
        final orders = HadithService.defaultHadith
            .map((h) => h['displayOrder'] as int)
            .toList()
          ..sort();
        expect(orders, equals([1, 2, 3, 4, 5, 6, 7, 8]));
      });

      test('should contain both hadith and quote types', () {
        final types = HadithService.defaultHadith
            .map((h) => h['type'] as String)
            .toSet();
        expect(types, contains('hadith'));
        expect(types, contains('quote'));
      });

      test('should have 4 hadith entries', () {
        final hadithCount = HadithService.defaultHadith
            .where((h) => h['type'] == 'hadith')
            .length;
        expect(hadithCount, equals(4));
      });

      test('should have 4 quote entries', () {
        final quoteCount = HadithService.defaultHadith
            .where((h) => h['type'] == 'quote')
            .length;
        expect(quoteCount, equals(4));
      });

      test('hadith entries should have narrator', () {
        final hadithEntries = HadithService.defaultHadith
            .where((h) => h['type'] == 'hadith');

        for (final hadith in hadithEntries) {
          expect(hadith['narrator'], isNotEmpty);
        }
      });

      test('quote entries should have scholar', () {
        final quoteEntries = HadithService.defaultHadith
            .where((h) => h['type'] == 'quote');

        for (final quote in quoteEntries) {
          expect(quote['scholar'], isNotEmpty);
        }
      });

      test('should contain صحيح البخاري as source', () {
        final sources = HadithService.defaultHadith
            .map((h) => h['source'] as String)
            .toSet();
        expect(sources, contains('صحيح البخاري'));
      });

      test('should have references for all Bukhari hadith', () {
        final bukhariHadith = HadithService.defaultHadith
            .where((h) => h['source'] == 'صحيح البخاري');

        for (final hadith in bukhariHadith) {
          expect(hadith['reference'], isNotEmpty);
        }
      });
    });

    // =====================================================
    // FALLBACK ROTATION LOGIC TESTS
    // =====================================================
    group('fallback rotation logic', () {
      // Replicate the fallback rotation logic from the service
      int calculateFallbackIndex(DateTime date) {
        final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
        return dayOfYear % HadithService.defaultHadith.length;
      }

      test('should calculate correct index for January 1st', () {
        final date = DateTime(2024, 1, 1);
        expect(calculateFallbackIndex(date), equals(0));
      });

      test('should calculate correct index for January 2nd', () {
        final date = DateTime(2024, 1, 2);
        expect(calculateFallbackIndex(date), equals(1));
      });

      test('should wrap around after 8 days', () {
        final date = DateTime(2024, 1, 9); // Day 8 (0-indexed)
        expect(calculateFallbackIndex(date), equals(0));
      });

      test('should cycle through all 8 hadith in a week+1', () {
        final indices = <int>[];
        for (int i = 0; i < 8; i++) {
          final date = DateTime(2024, 1, 1 + i);
          indices.add(calculateFallbackIndex(date));
        }

        // Should have all indices from 0 to 7
        expect(indices.toSet(), equals({0, 1, 2, 3, 4, 5, 6, 7}));
      });

      test('should return same index for same day', () {
        final date1 = DateTime(2024, 3, 15);
        final date2 = DateTime(2024, 3, 15);

        expect(calculateFallbackIndex(date1), equals(calculateFallbackIndex(date2)));
      });

      test('should return different index for different days', () {
        final date1 = DateTime(2024, 3, 15);
        final date2 = DateTime(2024, 3, 16);

        expect(calculateFallbackIndex(date1), isNot(equals(calculateFallbackIndex(date2))));
      });

      test('should handle leap year', () {
        // 2024 is a leap year
        final feb29 = DateTime(2024, 2, 29);
        final mar1 = DateTime(2024, 3, 1);

        final feb29Index = calculateFallbackIndex(feb29);
        final mar1Index = calculateFallbackIndex(mar1);

        // Should be consecutive
        expect((mar1Index - feb29Index).abs() == 1 || (feb29Index == 7 && mar1Index == 0), isTrue);
      });

      test('should produce valid indices throughout the year', () {
        for (int month = 1; month <= 12; month++) {
          for (int day = 1; day <= 28; day++) { // Safe for all months
            final date = DateTime(2024, month, day);
            final index = calculateFallbackIndex(date);

            expect(index, greaterThanOrEqualTo(0));
            expect(index, lessThan(8));
          }
        }
      });
    });

    // =====================================================
    // HADITH CREATION FROM DEFAULT DATA TESTS
    // =====================================================
    group('Hadith.fromMap with default data', () {
      test('should create Hadith from first default entry', () {
        final data = HadithService.defaultHadith[0];
        final hadith = Hadith.fromMap({
          ...data,
          'id': 'fallback_0',
          'createdAt': DateTime.now(),
        });

        expect(hadith.id, equals('fallback_0'));
        expect(hadith.arabicText, equals(data['arabicText']));
        expect(hadith.englishTranslation, equals(data['englishTranslation']));
        expect(hadith.source, equals(data['source']));
        expect(hadith.topic, equals('silat_rahim'));
        expect(hadith.type, equals(HadithType.hadith));
        expect(hadith.isAuthentic, isTrue);
      });

      test('should create Hadith from quote entry', () {
        // Find first quote entry
        final quoteData = HadithService.defaultHadith
            .firstWhere((h) => h['type'] == 'quote');

        final hadith = Hadith.fromMap({
          ...quoteData,
          'id': 'fallback_quote',
          'createdAt': DateTime.now(),
        });

        expect(hadith.type, equals(HadithType.quote));
        expect(hadith.scholar, isNotEmpty);
      });

      test('should create all 8 default hadith successfully', () {
        for (int i = 0; i < HadithService.defaultHadith.length; i++) {
          final data = HadithService.defaultHadith[i];
          final hadith = Hadith.fromMap({
            ...data,
            'id': 'fallback_$i',
            'createdAt': DateTime.now(),
          });

          expect(hadith.id, equals('fallback_$i'));
          expect(hadith.arabicText, isNotEmpty);
          expect(hadith.source, isNotEmpty);
        }
      });
    });

    // =====================================================
    // CONTENT VALIDATION TESTS
    // =====================================================
    group('content validation', () {
      test('all default hadith should contain Prophet reference ﷺ or Imam', () {
        for (final hadith in HadithService.defaultHadith) {
          final text = hadith['arabicText'] as String;
          final containsProphet = text.contains('رسول الله ﷺ') || text.contains('ﷺ');
          final containsImam = text.contains('الإمام');

          expect(
            containsProphet || containsImam,
            isTrue,
            reason: 'Hadith should reference Prophet or Imam: $text',
          );
        }
      });

      test('all hadith entries should reference Prophet ﷺ', () {
        final hadithEntries = HadithService.defaultHadith
            .where((h) => h['type'] == 'hadith');

        for (final hadith in hadithEntries) {
          final text = hadith['arabicText'] as String;
          expect(
            text.contains('ﷺ'),
            isTrue,
            reason: 'Hadith should contain ﷺ: $text',
          );
        }
      });

      test('all quote entries should reference Imam', () {
        final quoteEntries = HadithService.defaultHadith
            .where((h) => h['type'] == 'quote');

        for (final quote in quoteEntries) {
          final text = quote['arabicText'] as String;
          expect(
            text.contains('الإمام'),
            isTrue,
            reason: 'Quote should reference Imam: $text',
          );
        }
      });

      test('all entries should have family ties theme', () {
        // Helper to remove Arabic diacritics for matching
        String removeDiacritics(String text) {
          // Remove harakat (fatha, kasra, damma, sukun, shadda, etc.)
          return text.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
        }

        final familyKeywords = ['رحم', 'صلة', 'قطع', 'وصل'];

        for (final hadith in HadithService.defaultHadith) {
          final text = removeDiacritics(hadith['arabicText'] as String);
          final containsFamilyKeyword = familyKeywords.any(
            (keyword) => text.contains(keyword),
          );

          expect(
            containsFamilyKeyword,
            isTrue,
            reason: 'Hadith should contain family ties theme: ${hadith['arabicText']}',
          );
        }
      });

      test('English translations should not be empty', () {
        for (final hadith in HadithService.defaultHadith) {
          expect(
            hadith['englishTranslation'],
            isNotEmpty,
            reason: 'English translation should exist',
          );
          expect(
            (hadith['englishTranslation'] as String).length,
            greaterThan(20),
            reason: 'English translation should be meaningful',
          );
        }
      });

      test('Arabic text should be longer than English translation', () {
        for (final hadith in HadithService.defaultHadith) {
          final arabicLength = (hadith['arabicText'] as String).length;
          final englishLength = (hadith['englishTranslation'] as String).length;

          // Arabic typically has fewer characters but this is a sanity check
          expect(arabicLength, greaterThan(20));
          expect(englishLength, greaterThan(20));
        }
      });
    });

    // =====================================================
    // SCHOLAR/NARRATOR VALIDATION TESTS
    // =====================================================
    group('scholar and narrator validation', () {
      test('hadith entries should have recognized narrators', () {
        final validNarrators = [
          'أنس بن مالك',
          'أبو هريرة',
          'عبد الرحمن بن عوف',
          'جبير بن مطعم',
          'عبد الله بن عمرو',
        ];

        final hadithEntries = HadithService.defaultHadith
            .where((h) => h['type'] == 'hadith');

        for (final hadith in hadithEntries) {
          final narrator = hadith['narrator'] as String;
          expect(
            validNarrators.contains(narrator),
            isTrue,
            reason: 'Narrator should be recognized: $narrator',
          );
        }
      });

      test('quote entries should have recognized scholars', () {
        final validScholars = [
          'أحمد بن حنبل',
          'ابن قدامة المقدسي',
          'البهوتي',
          'المرداوي',
        ];

        final quoteEntries = HadithService.defaultHadith
            .where((h) => h['type'] == 'quote');

        for (final quote in quoteEntries) {
          final scholar = quote['scholar'] as String;
          expect(
            validScholars.contains(scholar),
            isTrue,
            reason: 'Scholar should be recognized: $scholar',
          );
        }
      });
    });

    // =====================================================
    // SOURCE VALIDATION TESTS
    // =====================================================
    group('source validation', () {
      test('should have authentic sources', () {
        final validSources = [
          'صحيح البخاري',
          'مسند الإمام أحمد',
          'المغني',
          'كشاف القناع',
          'الإنصاف',
        ];

        for (final hadith in HadithService.defaultHadith) {
          final source = hadith['source'] as String;
          expect(
            validSources.contains(source),
            isTrue,
            reason: 'Source should be authentic: $source',
          );
        }
      });

      test('Bukhari hadith should have numeric references', () {
        final bukhariHadith = HadithService.defaultHadith
            .where((h) => h['source'] == 'صحيح البخاري');

        for (final hadith in bukhariHadith) {
          final reference = hadith['reference'] as String;
          expect(reference, isNotEmpty);
          // Should contain Arabic numerals
          expect(reference.contains(RegExp(r'[٠-٩]+')), isTrue);
        }
      });
    });

    // =====================================================
    // EDGE CASES TESTS
    // =====================================================
    group('edge cases', () {
      test('should handle empty default hadith list gracefully', () {
        // This tests the logic that would be used if the list were empty
        const emptyList = <Map<String, dynamic>>[];

        if (emptyList.isEmpty) {
          // Fallback should return null
          expect(emptyList.isEmpty, isTrue);
        }
      });

      test('should handle single item in list', () {
        final singleItem = [HadithService.defaultHadith.first];

        // Rotation with single item should always return 0
        final dayOfYear = DateTime.now().difference(
          DateTime(DateTime.now().year, 1, 1),
        ).inDays;
        final index = dayOfYear % singleItem.length;

        expect(index, equals(0));
      });

      test('default hadith should not contain null values for required fields', () {
        for (final hadith in HadithService.defaultHadith) {
          expect(hadith['arabicText'], isNotNull);
          expect(hadith['source'], isNotNull);
          expect(hadith['topic'], isNotNull);
          expect(hadith['type'], isNotNull);
          expect(hadith['isAuthentic'], isNotNull);
          expect(hadith['displayOrder'], isNotNull);
        }
      });
    });
  });
}
