import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/shared/models/hadith_model.dart';

import '../../helpers/model_factories.dart';

void main() {
  group('Hadith Model', () {
    // =====================================================
    // HADITH TYPE ENUM TESTS
    // =====================================================
    group('HadithType', () {
      test('should have 3 hadith types', () {
        expect(HadithType.values.length, equals(3));
      });

      test('should include all expected types', () {
        expect(HadithType.values, contains(HadithType.hadith));
        expect(HadithType.values, contains(HadithType.quote));
        expect(HadithType.values, contains(HadithType.verse));
      });

      test('should have correct value strings', () {
        expect(HadithType.hadith.value, equals('hadith'));
        expect(HadithType.quote.value, equals('quote'));
        expect(HadithType.verse.value, equals('verse'));
      });

      test('should have correct Arabic names', () {
        expect(HadithType.hadith.arabicName, equals('حديث'));
        expect(HadithType.quote.arabicName, equals('قول'));
        expect(HadithType.verse.arabicName, equals('آية'));
      });

      test('fromString should parse hadith', () {
        expect(HadithType.fromString('hadith'), equals(HadithType.hadith));
      });

      test('fromString should parse quote', () {
        expect(HadithType.fromString('quote'), equals(HadithType.quote));
      });

      test('fromString should parse verse', () {
        expect(HadithType.fromString('verse'), equals(HadithType.verse));
      });

      test('fromString should default to hadith for unknown value', () {
        expect(HadithType.fromString('unknown'), equals(HadithType.hadith));
        expect(HadithType.fromString(''), equals(HadithType.hadith));
        expect(HadithType.fromString('invalid'), equals(HadithType.hadith));
      });
    });

    // =====================================================
    // CONSTRUCTOR TESTS
    // =====================================================
    group('Constructor', () {
      test('should create hadith with required fields', () {
        final hadith = Hadith(
          id: 'test-id',
          arabicText: 'النص العربي',
          englishTranslation: 'English text',
          source: 'صحيح البخاري',
          reference: '5984',
          topic: 'silat_rahim',
          createdAt: DateTime(2024, 1, 1),
        );

        expect(hadith.id, equals('test-id'));
        expect(hadith.arabicText, equals('النص العربي'));
        expect(hadith.englishTranslation, equals('English text'));
        expect(hadith.source, equals('صحيح البخاري'));
        expect(hadith.reference, equals('5984'));
        expect(hadith.topic, equals('silat_rahim'));
      });

      test('should use default values for optional fields', () {
        final hadith = Hadith(
          id: 'test-id',
          arabicText: 'النص العربي',
          englishTranslation: 'English text',
          source: 'صحيح البخاري',
          reference: '5984',
          topic: 'silat_rahim',
          createdAt: DateTime(2024, 1, 1),
        );

        expect(hadith.type, equals(HadithType.hadith));
        expect(hadith.narrator, equals(''));
        expect(hadith.scholar, equals(''));
        expect(hadith.isAuthentic, isTrue);
        expect(hadith.displayOrder, equals(0));
        expect(hadith.updatedAt, isNull);
      });

      test('should accept custom values for optional fields', () {
        final hadith = Hadith(
          id: 'test-id',
          arabicText: 'النص العربي',
          englishTranslation: 'English text',
          source: 'المصدر',
          reference: 'المرجع',
          topic: 'family_bonds',
          type: HadithType.quote,
          narrator: 'الراوي',
          scholar: 'ابن القيم',
          isAuthentic: false,
          displayOrder: 5,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 6, 1),
        );

        expect(hadith.type, equals(HadithType.quote));
        expect(hadith.narrator, equals('الراوي'));
        expect(hadith.scholar, equals('ابن القيم'));
        expect(hadith.isAuthentic, isFalse);
        expect(hadith.displayOrder, equals(5));
        expect(hadith.updatedAt, equals(DateTime(2024, 6, 1)));
      });
    });

    // =====================================================
    // FROM JSON TESTS (Supabase format)
    // =====================================================
    group('fromJson', () {
      test('should create hadith from complete JSON', () {
        final json = {
          'id': 'hadith-123',
          'arabic_text': 'النص العربي للحديث',
          'english_translation': 'English translation',
          'source': 'صحيح مسلم',
          'reference': '2556',
          'topic': 'silat_rahim',
          'type': 'hadith',
          'narrator': 'أبو هريرة',
          'scholar': '',
          'is_authentic': true,
          'display_order': 1,
          'created_at': '2024-01-01T00:00:00Z',
          'updated_at': '2024-06-01T00:00:00Z',
        };

        final hadith = Hadith.fromJson(json);

        expect(hadith.id, equals('hadith-123'));
        expect(hadith.arabicText, equals('النص العربي للحديث'));
        expect(hadith.englishTranslation, equals('English translation'));
        expect(hadith.source, equals('صحيح مسلم'));
        expect(hadith.reference, equals('2556'));
        expect(hadith.topic, equals('silat_rahim'));
        expect(hadith.type, equals(HadithType.hadith));
        expect(hadith.narrator, equals('أبو هريرة'));
        expect(hadith.scholar, equals(''));
        expect(hadith.isAuthentic, isTrue);
        expect(hadith.displayOrder, equals(1));
        expect(hadith.updatedAt, isNotNull);
      });

      test('should handle minimal JSON with defaults', () {
        final json = {
          'id': 'hadith-minimal',
          'arabic_text': 'النص',
          'source': 'المصدر',
          'created_at': '2024-01-01T00:00:00Z',
        };

        final hadith = Hadith.fromJson(json);

        expect(hadith.id, equals('hadith-minimal'));
        expect(hadith.arabicText, equals('النص'));
        expect(hadith.englishTranslation, equals(''));
        expect(hadith.source, equals('المصدر'));
        expect(hadith.reference, equals(''));
        expect(hadith.topic, equals('silat_rahim'));
        expect(hadith.type, equals(HadithType.hadith));
        expect(hadith.narrator, equals(''));
        expect(hadith.scholar, equals(''));
        expect(hadith.isAuthentic, isTrue);
        expect(hadith.displayOrder, equals(0));
        expect(hadith.updatedAt, isNull);
      });

      test('should parse quote type', () {
        final json = {
          'id': 'quote-1',
          'arabic_text': 'قول الإمام',
          'source': 'المصدر',
          'type': 'quote',
          'scholar': 'ابن تيمية',
          'created_at': '2024-01-01T00:00:00Z',
        };

        final hadith = Hadith.fromJson(json);

        expect(hadith.type, equals(HadithType.quote));
        expect(hadith.scholar, equals('ابن تيمية'));
      });

      test('should parse verse type', () {
        final json = {
          'id': 'verse-1',
          'arabic_text': 'آية قرآنية',
          'source': 'القرآن الكريم',
          'type': 'verse',
          'reference': 'الرعد: 21',
          'created_at': '2024-01-01T00:00:00Z',
        };

        final hadith = Hadith.fromJson(json);

        expect(hadith.type, equals(HadithType.verse));
        expect(hadith.reference, equals('الرعد: 21'));
      });

      test('should handle null updated_at', () {
        final json = {
          'id': 'hadith-1',
          'arabic_text': 'النص',
          'source': 'المصدر',
          'created_at': '2024-01-01T00:00:00Z',
          'updated_at': null,
        };

        final hadith = Hadith.fromJson(json);

        expect(hadith.updatedAt, isNull);
      });

      test('should handle is_authentic false', () {
        final json = {
          'id': 'hadith-1',
          'arabic_text': 'النص',
          'source': 'المصدر',
          'is_authentic': false,
          'created_at': '2024-01-01T00:00:00Z',
        };

        final hadith = Hadith.fromJson(json);

        expect(hadith.isAuthentic, isFalse);
      });
    });

    // =====================================================
    // FROM MAP TESTS (Local fallback format)
    // =====================================================
    group('fromMap', () {
      test('should create hadith from complete map', () {
        final now = DateTime.now();
        final map = {
          'id': 'local-hadith-1',
          'arabicText': 'النص العربي',
          'englishTranslation': 'English',
          'source': 'صحيح البخاري',
          'reference': '5984',
          'topic': 'silat_rahim',
          'type': 'hadith',
          'narrator': 'أبو هريرة',
          'scholar': '',
          'isAuthentic': true,
          'displayOrder': 0,
          'createdAt': now,
          'updatedAt': now,
        };

        final hadith = Hadith.fromMap(map);

        expect(hadith.id, equals('local-hadith-1'));
        expect(hadith.arabicText, equals('النص العربي'));
        expect(hadith.createdAt, equals(now));
        expect(hadith.updatedAt, equals(now));
      });

      test('should handle minimal map with defaults', () {
        final map = {
          'arabicText': 'النص',
          'source': 'المصدر',
        };

        final hadith = Hadith.fromMap(map);

        expect(hadith.id, equals(''));
        expect(hadith.arabicText, equals('النص'));
        expect(hadith.englishTranslation, equals(''));
        expect(hadith.reference, equals(''));
        expect(hadith.topic, equals('silat_rahim'));
        expect(hadith.type, equals(HadithType.hadith));
        expect(hadith.isAuthentic, isTrue);
        expect(hadith.displayOrder, equals(0));
      });

      test('should handle null id', () {
        final map = {
          'id': null,
          'arabicText': 'النص',
          'source': 'المصدر',
        };

        final hadith = Hadith.fromMap(map);

        expect(hadith.id, equals(''));
      });

      test('should use DateTime.now() when createdAt is not DateTime', () {
        final map = {
          'arabicText': 'النص',
          'source': 'المصدر',
          'createdAt': 'not-a-date',
        };

        final before = DateTime.now();
        final hadith = Hadith.fromMap(map);
        final after = DateTime.now();

        expect(
          hadith.createdAt.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue,
        );
        expect(
          hadith.createdAt.isBefore(after.add(const Duration(seconds: 1))),
          isTrue,
        );
      });

      test('should handle updatedAt not being DateTime', () {
        final map = {
          'arabicText': 'النص',
          'source': 'المصدر',
          'updatedAt': 'not-a-date',
        };

        final hadith = Hadith.fromMap(map);

        expect(hadith.updatedAt, isNull);
      });
    });

    // =====================================================
    // TO JSON TESTS
    // =====================================================
    group('toJson', () {
      test('should convert to JSON with correct keys', () {
        final hadith = createTestHadith(
          arabicText: 'النص العربي',
          englishTranslation: 'English',
          source: 'صحيح البخاري',
          reference: '5984',
          topic: 'silat_rahim',
          type: HadithType.hadith,
          narrator: 'أبو هريرة',
          scholar: '',
          isAuthentic: true,
          displayOrder: 3,
        );

        final json = hadith.toJson();

        expect(json['arabic_text'], equals('النص العربي'));
        expect(json['english_translation'], equals('English'));
        expect(json['source'], equals('صحيح البخاري'));
        expect(json['reference'], equals('5984'));
        expect(json['topic'], equals('silat_rahim'));
        expect(json['type'], equals('hadith'));
        expect(json['narrator'], equals('أبو هريرة'));
        expect(json['scholar'], equals(''));
        expect(json['is_authentic'], isTrue);
        expect(json['display_order'], equals(3));
      });

      test('should not include id in JSON', () {
        final hadith = createTestHadith(id: 'should-not-appear');
        final json = hadith.toJson();

        expect(json.containsKey('id'), isFalse);
      });

      test('should not include created_at in JSON', () {
        final hadith = createTestHadith();
        final json = hadith.toJson();

        expect(json.containsKey('created_at'), isFalse);
      });

      test('should not include updated_at in JSON', () {
        final hadith = createTestHadith();
        final json = hadith.toJson();

        expect(json.containsKey('updated_at'), isFalse);
      });

      test('should convert quote type correctly', () {
        final hadith = createTestHadith(type: HadithType.quote);
        final json = hadith.toJson();

        expect(json['type'], equals('quote'));
      });

      test('should convert verse type correctly', () {
        final hadith = createTestHadith(type: HadithType.verse);
        final json = hadith.toJson();

        expect(json['type'], equals('verse'));
      });
    });

    // =====================================================
    // FORMATTED SOURCE TESTS
    // =====================================================
    group('formattedSource', () {
      test('should return source for hadith type', () {
        final hadith = createTestHadith(
          type: HadithType.hadith,
          source: 'صحيح البخاري',
          scholar: 'some scholar',
        );

        expect(hadith.formattedSource, equals('صحيح البخاري'));
      });

      test('should return formatted scholar name for quote type', () {
        final hadith = createTestHadith(
          type: HadithType.quote,
          source: 'المصدر',
          scholar: 'ابن القيم',
        );

        expect(hadith.formattedSource, equals('الإمام ابن القيم'));
      });

      test('should return source when quote has empty scholar', () {
        final hadith = createTestHadith(
          type: HadithType.quote,
          source: 'المصدر',
          scholar: '',
        );

        expect(hadith.formattedSource, equals('المصدر'));
      });

      test('should return source for verse type', () {
        final hadith = createTestHadith(
          type: HadithType.verse,
          source: 'القرآن الكريم',
        );

        expect(hadith.formattedSource, equals('القرآن الكريم'));
      });

      test('should return empty string when hadith source is empty', () {
        final hadith = createTestHadith(
          type: HadithType.hadith,
          source: '',
        );

        expect(hadith.formattedSource, equals(''));
      });
    });

    // =====================================================
    // JSON ROUND-TRIP TESTS
    // =====================================================
    group('JSON Round-trip', () {
      test('should preserve data through toJson/fromJson', () {
        final original = createTestHadith(
          id: 'round-trip-test',
          arabicText: 'النص العربي الأصلي',
          englishTranslation: 'Original English',
          source: 'صحيح مسلم',
          reference: '2556',
          topic: 'family_bonds',
          type: HadithType.quote,
          narrator: 'الراوي',
          scholar: 'ابن تيمية',
          isAuthentic: true,
          displayOrder: 7,
        );

        final json = original.toJson();
        // Add back the fields that toJson doesn't include
        json['id'] = original.id;
        json['created_at'] = original.createdAt.toIso8601String();

        final recreated = Hadith.fromJson(json);

        expect(recreated.arabicText, equals(original.arabicText));
        expect(recreated.englishTranslation, equals(original.englishTranslation));
        expect(recreated.source, equals(original.source));
        expect(recreated.reference, equals(original.reference));
        expect(recreated.topic, equals(original.topic));
        expect(recreated.type, equals(original.type));
        expect(recreated.narrator, equals(original.narrator));
        expect(recreated.scholar, equals(original.scholar));
        expect(recreated.isAuthentic, equals(original.isAuthentic));
        expect(recreated.displayOrder, equals(original.displayOrder));
      });
    });

    // =====================================================
    // EDGE CASE TESTS
    // =====================================================
    group('Edge Cases', () {
      test('should handle Arabic text with special characters', () {
        final hadith = createTestHadith(
          arabicText: 'قال ﷺ: «من وصل رحمه وصله الله»',
        );

        expect(hadith.arabicText, contains('ﷺ'));
        expect(hadith.arabicText, contains('«'));
        expect(hadith.arabicText, contains('»'));
      });

      test('should handle empty strings', () {
        final hadith = createTestHadith(
          englishTranslation: '',
          reference: '',
          narrator: '',
          scholar: '',
        );

        expect(hadith.englishTranslation, equals(''));
        expect(hadith.reference, equals(''));
        expect(hadith.narrator, equals(''));
        expect(hadith.scholar, equals(''));
      });

      test('should handle display order of 0', () {
        final hadith = createTestHadith(displayOrder: 0);
        expect(hadith.displayOrder, equals(0));
      });

      test('should handle large display order', () {
        final hadith = createTestHadith(displayOrder: 999);
        expect(hadith.displayOrder, equals(999));
      });

      test('should handle various topic values', () {
        final topics = ['silat_rahim', 'family_bonds', 'parents_rights', 'children_care'];

        for (final topic in topics) {
          final hadith = createTestHadith(topic: topic);
          expect(hadith.topic, equals(topic));
        }
      });
    });

    // =====================================================
    // FACTORY TESTS
    // =====================================================
    group('Factory Helper', () {
      test('createTestHadith should create valid hadith with defaults', () {
        final hadith = createTestHadith();

        expect(hadith.id, isNotEmpty);
        expect(hadith.arabicText, isNotEmpty);
        expect(hadith.source, isNotEmpty);
        expect(hadith.type, equals(HadithType.hadith));
        expect(hadith.isAuthentic, isTrue);
      });

      test('createTestHadith should allow overriding all fields', () {
        final customTime = DateTime(2024, 6, 15);
        final hadith = createTestHadith(
          id: 'custom-id',
          arabicText: 'نص مخصص',
          englishTranslation: 'Custom translation',
          source: 'مصدر مخصص',
          reference: 'مرجع مخصص',
          topic: 'custom_topic',
          type: HadithType.verse,
          narrator: 'الراوي المخصص',
          scholar: 'العالم المخصص',
          isAuthentic: false,
          displayOrder: 99,
          createdAt: customTime,
        );

        expect(hadith.id, equals('custom-id'));
        expect(hadith.arabicText, equals('نص مخصص'));
        expect(hadith.englishTranslation, equals('Custom translation'));
        expect(hadith.source, equals('مصدر مخصص'));
        expect(hadith.reference, equals('مرجع مخصص'));
        expect(hadith.topic, equals('custom_topic'));
        expect(hadith.type, equals(HadithType.verse));
        expect(hadith.narrator, equals('الراوي المخصص'));
        expect(hadith.scholar, equals('العالم المخصص'));
        expect(hadith.isAuthentic, isFalse);
        expect(hadith.displayOrder, equals(99));
        expect(hadith.createdAt, equals(customTime));
      });
    });
  });
}
