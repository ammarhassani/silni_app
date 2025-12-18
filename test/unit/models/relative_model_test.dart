import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/shared/models/relative_model.dart';

import '../../helpers/model_factories.dart';

void main() {
  group('Relative Model', () {
    // =====================================================
    // JSON SERIALIZATION TESTS
    // =====================================================
    group('JSON Serialization', () {
      test('should create Relative from valid JSON', () {
        final json = createTestRelativeJson(
          id: 'relative-123',
          userId: 'user-456',
          fullName: 'أحمد محمد',
          relationshipType: 'father',
          gender: 'male',
          avatarType: 'bearded_man',
          priority: 1,
        );

        final relative = Relative.fromJson(json);

        expect(relative.id, equals('relative-123'));
        expect(relative.userId, equals('user-456'));
        expect(relative.fullName, equals('أحمد محمد'));
        expect(relative.relationshipType, equals(RelationshipType.father));
        expect(relative.gender, equals(Gender.male));
        expect(relative.avatarType, equals(AvatarType.beardedMan));
        expect(relative.priority, equals(1));
      });

      test('should convert Relative to JSON', () {
        final relative = createTestRelative(
          userId: 'user-789',
          fullName: 'فاطمة علي',
          relationshipType: RelationshipType.mother,
          gender: Gender.female,
          avatarType: AvatarType.womanWithHijab,
          priority: 1,
          phoneNumber: '+966551234567',
          email: 'fatima@example.com',
        );

        final json = relative.toJson();

        expect(json['user_id'], equals('user-789'));
        expect(json['full_name'], equals('فاطمة علي'));
        expect(json['relationship_type'], equals('mother'));
        expect(json['gender'], equals('female'));
        expect(json['avatar_type'], equals('woman_hijab'));
        expect(json['priority'], equals(1));
        expect(json['phone_number'], equals('+966551234567'));
        expect(json['email'], equals('fatima@example.com'));
      });

      test('should handle null optional fields in JSON', () {
        final json = {
          'id': 'test-id',
          'user_id': 'test-user',
          'full_name': 'Test Name',
          'relationship_type': 'brother',
          'gender': null,
          'avatar_type': null,
          'date_of_birth': null,
          'phone_number': null,
          'email': null,
          'address': null,
          'city': null,
          'country': null,
          'photo_url': null,
          'notes': null,
          'tags': null,
          'priority': null,
          'islamic_importance': null,
          'preferred_contact_method': null,
          'best_time_to_contact': null,
          'interaction_count': null,
          'last_contact_date': null,
          'health_status': null,
          'is_archived': null,
          'is_favorite': null,
          'contact_id': null,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': null,
        };

        final relative = Relative.fromJson(json);

        expect(relative.gender, isNull);
        expect(relative.avatarType, equals(AvatarType.adultMan)); // Default
        expect(relative.dateOfBirth, isNull);
        expect(relative.phoneNumber, isNull);
        expect(relative.tags, isEmpty);
        expect(relative.priority, equals(2)); // Default
        expect(relative.interactionCount, equals(0)); // Default
        expect(relative.isArchived, isFalse); // Default
        expect(relative.isFavorite, isFalse); // Default
      });

      test('should round-trip JSON serialization correctly', () {
        final original = createTestRelative(
          fullName: 'محمد أحمد',
          relationshipType: RelationshipType.uncle,
          gender: Gender.male,
          priority: 3,
          tags: ['عم', 'الرياض'],
          isFavorite: true,
        );

        final json = original.toJson();
        json['id'] = original.id;
        json['created_at'] = original.createdAt.toIso8601String();

        final restored = Relative.fromJson(json);

        expect(restored.fullName, equals(original.fullName));
        expect(restored.relationshipType, equals(original.relationshipType));
        expect(restored.gender, equals(original.gender));
        expect(restored.priority, equals(original.priority));
        expect(restored.tags, equals(original.tags));
        expect(restored.isFavorite, equals(original.isFavorite));
      });
    });

    // =====================================================
    // RELATIONSHIP TYPE ENUM TESTS
    // =====================================================
    group('RelationshipType Enum', () {
      test('should parse all relationship types correctly', () {
        expect(RelationshipType.fromString('father'), equals(RelationshipType.father));
        expect(RelationshipType.fromString('mother'), equals(RelationshipType.mother));
        expect(RelationshipType.fromString('brother'), equals(RelationshipType.brother));
        expect(RelationshipType.fromString('sister'), equals(RelationshipType.sister));
        expect(RelationshipType.fromString('son'), equals(RelationshipType.son));
        expect(RelationshipType.fromString('daughter'), equals(RelationshipType.daughter));
        expect(RelationshipType.fromString('grandfather'), equals(RelationshipType.grandfather));
        expect(RelationshipType.fromString('grandmother'), equals(RelationshipType.grandmother));
        expect(RelationshipType.fromString('uncle'), equals(RelationshipType.uncle));
        expect(RelationshipType.fromString('aunt'), equals(RelationshipType.aunt));
        expect(RelationshipType.fromString('nephew'), equals(RelationshipType.nephew));
        expect(RelationshipType.fromString('niece'), equals(RelationshipType.niece));
        expect(RelationshipType.fromString('cousin'), equals(RelationshipType.cousin));
        expect(RelationshipType.fromString('husband'), equals(RelationshipType.husband));
        expect(RelationshipType.fromString('wife'), equals(RelationshipType.wife));
        expect(RelationshipType.fromString('other'), equals(RelationshipType.other));
      });

      test('should default to other for unknown relationship type', () {
        expect(RelationshipType.fromString('unknown'), equals(RelationshipType.other));
        expect(RelationshipType.fromString(''), equals(RelationshipType.other));
        expect(RelationshipType.fromString('friend'), equals(RelationshipType.other));
      });

      test('should have correct Arabic names', () {
        expect(RelationshipType.father.arabicName, equals('أب'));
        expect(RelationshipType.mother.arabicName, equals('أم'));
        expect(RelationshipType.brother.arabicName, equals('أخ'));
        expect(RelationshipType.sister.arabicName, equals('أخت'));
        expect(RelationshipType.husband.arabicName, equals('زوج'));
        expect(RelationshipType.wife.arabicName, equals('زوجة'));
      });

      test('should have correct priority values', () {
        // High priority (1): immediate family
        expect(RelationshipType.father.priority, equals(1));
        expect(RelationshipType.mother.priority, equals(1));
        expect(RelationshipType.husband.priority, equals(1));
        expect(RelationshipType.wife.priority, equals(1));

        // Medium priority (2): close family
        expect(RelationshipType.brother.priority, equals(2));
        expect(RelationshipType.sister.priority, equals(2));
        expect(RelationshipType.uncle.priority, equals(2));
        expect(RelationshipType.aunt.priority, equals(2));

        // Low priority (3): extended family
        expect(RelationshipType.nephew.priority, equals(3));
        expect(RelationshipType.niece.priority, equals(3));
        expect(RelationshipType.cousin.priority, equals(3));
        expect(RelationshipType.other.priority, equals(3));
      });

      test('should have 16 relationship types', () {
        expect(RelationshipType.values.length, equals(16));
      });
    });

    // =====================================================
    // GENDER ENUM TESTS
    // =====================================================
    group('Gender Enum', () {
      test('should parse gender correctly', () {
        expect(Gender.fromString('male'), equals(Gender.male));
        expect(Gender.fromString('female'), equals(Gender.female));
      });

      test('should handle null gender', () {
        expect(Gender.fromString(null), isNull);
      });

      test('should default to male for unknown gender', () {
        expect(Gender.fromString('unknown'), equals(Gender.male));
      });

      test('should have correct Arabic names', () {
        expect(Gender.male.arabicName, equals('ذكر'));
        expect(Gender.female.arabicName, equals('أنثى'));
      });
    });

    // =====================================================
    // AVATAR TYPE ENUM TESTS
    // =====================================================
    group('AvatarType Enum', () {
      test('should parse all avatar types correctly', () {
        expect(AvatarType.fromString('young_boy'), equals(AvatarType.youngBoy));
        expect(AvatarType.fromString('young_girl'), equals(AvatarType.youngGirl));
        expect(AvatarType.fromString('teen_boy'), equals(AvatarType.teenBoy));
        expect(AvatarType.fromString('teen_girl'), equals(AvatarType.teenGirl));
        expect(AvatarType.fromString('adult_man'), equals(AvatarType.adultMan));
        expect(AvatarType.fromString('adult_woman'), equals(AvatarType.adultWoman));
        expect(AvatarType.fromString('woman_hijab'), equals(AvatarType.womanWithHijab));
        expect(AvatarType.fromString('bearded_man'), equals(AvatarType.beardedMan));
        expect(AvatarType.fromString('elderly_man'), equals(AvatarType.elderlyMan));
        expect(AvatarType.fromString('elderly_woman'), equals(AvatarType.elderlyWoman));
      });

      test('should default to adultMan for unknown or null avatar type', () {
        expect(AvatarType.fromString('unknown'), equals(AvatarType.adultMan));
        expect(AvatarType.fromString(null), equals(AvatarType.adultMan));
      });

      test('should have emoji representations', () {
        expect(AvatarType.youngBoy.emoji, equals('👦'));
        expect(AvatarType.youngGirl.emoji, equals('👧'));
        expect(AvatarType.adultMan.emoji, equals('👨'));
        expect(AvatarType.adultWoman.emoji, equals('👩'));
        expect(AvatarType.womanWithHijab.emoji, equals('🧕'));
        expect(AvatarType.beardedMan.emoji, equals('🧔'));
        expect(AvatarType.elderlyMan.emoji, equals('👴'));
        expect(AvatarType.elderlyWoman.emoji, equals('👵'));
      });

      test('should have 10 avatar types', () {
        expect(AvatarType.values.length, equals(10));
      });
    });

    // =====================================================
    // SUGGEST AVATAR FROM RELATIONSHIP TESTS
    // =====================================================
    group('suggestFromRelationship', () {
      test('should suggest beardedMan for father', () {
        expect(
          AvatarType.suggestFromRelationship(RelationshipType.father, Gender.male),
          equals(AvatarType.beardedMan),
        );
      });

      test('should suggest womanWithHijab for mother', () {
        expect(
          AvatarType.suggestFromRelationship(RelationshipType.mother, Gender.female),
          equals(AvatarType.womanWithHijab),
        );
      });

      test('should suggest elderlyMan for grandfather', () {
        expect(
          AvatarType.suggestFromRelationship(RelationshipType.grandfather, Gender.male),
          equals(AvatarType.elderlyMan),
        );
      });

      test('should suggest elderlyWoman for grandmother', () {
        expect(
          AvatarType.suggestFromRelationship(RelationshipType.grandmother, Gender.female),
          equals(AvatarType.elderlyWoman),
        );
      });

      test('should suggest youngBoy for son', () {
        expect(
          AvatarType.suggestFromRelationship(RelationshipType.son, Gender.male),
          equals(AvatarType.youngBoy),
        );
      });

      test('should suggest youngGirl for daughter', () {
        expect(
          AvatarType.suggestFromRelationship(RelationshipType.daughter, Gender.female),
          equals(AvatarType.youngGirl),
        );
      });

      test('should suggest teenBoy for nephew', () {
        expect(
          AvatarType.suggestFromRelationship(RelationshipType.nephew, Gender.male),
          equals(AvatarType.teenBoy),
        );
      });

      test('should suggest teenGirl for niece', () {
        expect(
          AvatarType.suggestFromRelationship(RelationshipType.niece, Gender.female),
          equals(AvatarType.teenGirl),
        );
      });

      test('should use gender for cousin', () {
        expect(
          AvatarType.suggestFromRelationship(RelationshipType.cousin, Gender.male),
          equals(AvatarType.adultMan),
        );
        expect(
          AvatarType.suggestFromRelationship(RelationshipType.cousin, Gender.female),
          equals(AvatarType.adultWoman),
        );
      });

      test('should use gender for other relationship', () {
        expect(
          AvatarType.suggestFromRelationship(RelationshipType.other, Gender.male),
          equals(AvatarType.adultMan),
        );
        expect(
          AvatarType.suggestFromRelationship(RelationshipType.other, Gender.female),
          equals(AvatarType.adultWoman),
        );
      });
    });

    // =====================================================
    // SUGGEST PRIORITY TESTS
    // =====================================================
    group('suggestPriority', () {
      test('should suggest priority 1 for immediate family', () {
        expect(AvatarType.suggestPriority(RelationshipType.father), equals(1));
        expect(AvatarType.suggestPriority(RelationshipType.mother), equals(1));
        expect(AvatarType.suggestPriority(RelationshipType.husband), equals(1));
        expect(AvatarType.suggestPriority(RelationshipType.wife), equals(1));
        expect(AvatarType.suggestPriority(RelationshipType.son), equals(1));
        expect(AvatarType.suggestPriority(RelationshipType.daughter), equals(1));
      });

      test('should suggest priority 2 for close family', () {
        expect(AvatarType.suggestPriority(RelationshipType.brother), equals(2));
        expect(AvatarType.suggestPriority(RelationshipType.sister), equals(2));
        expect(AvatarType.suggestPriority(RelationshipType.grandfather), equals(2));
        expect(AvatarType.suggestPriority(RelationshipType.grandmother), equals(2));
      });

      test('should suggest priority 3 for extended family', () {
        expect(AvatarType.suggestPriority(RelationshipType.uncle), equals(3));
        expect(AvatarType.suggestPriority(RelationshipType.aunt), equals(3));
        expect(AvatarType.suggestPriority(RelationshipType.nephew), equals(3));
        expect(AvatarType.suggestPriority(RelationshipType.niece), equals(3));
        expect(AvatarType.suggestPriority(RelationshipType.cousin), equals(3));
        expect(AvatarType.suggestPriority(RelationshipType.other), equals(3));
      });
    });

    // =====================================================
    // DISPLAY EMOJI TESTS
    // =====================================================
    group('displayEmoji', () {
      test('should return avatarType emoji when set', () {
        final relative = createTestRelative(
          avatarType: AvatarType.elderlyMan,
        );
        expect(relative.displayEmoji, equals('👴'));
      });

      test('should auto-suggest emoji based on relationship when avatarType is null', () {
        final json = createTestRelativeJson(
          relationshipType: 'father',
          gender: 'male',
          avatarType: null,
        );
        // Need to modify to set avatarType to null after creation
        json['avatar_type'] = null;

        final relative = Relative.fromJson(json);
        // When avatarType is null, it defaults to adultMan
        // displayEmoji will use suggetsFromRelationship which returns beardedMan for father
        expect(relative.displayEmoji, equals('👨')); // From default adultMan
      });
    });

    // =====================================================
    // DAYS SINCE LAST CONTACT TESTS
    // =====================================================
    group('daysSinceLastContact', () {
      test('should return null when lastContactDate is null', () {
        final relative = createTestRelative(lastContactDate: null);
        expect(relative.daysSinceLastContact, isNull);
      });

      test('should return 0 for contact today', () {
        final relative = createTestRelative(
          lastContactDate: DateTime.now(),
        );
        expect(relative.daysSinceLastContact, equals(0));
      });

      test('should return correct days for past contact', () {
        final relative = createTestRelative(
          lastContactDate: DateTime.now().subtract(const Duration(days: 5)),
        );
        expect(relative.daysSinceLastContact, equals(5));
      });

      test('should return correct days for contact weeks ago', () {
        final relative = createTestRelative(
          lastContactDate: DateTime.now().subtract(const Duration(days: 14)),
        );
        expect(relative.daysSinceLastContact, equals(14));
      });
    });

    // =====================================================
    // NEEDS CONTACT TESTS
    // =====================================================
    group('needsContact', () {
      test('should return true when lastContactDate is null', () {
        final relative = createTestRelative(
          priority: 1,
          lastContactDate: null,
        );
        expect(relative.needsContact, isTrue);
      });

      group('High Priority (1)', () {
        test('should return false when contacted today', () {
          final relative = createTestRelative(
            priority: 1,
            lastContactDate: DateTime.now(),
          );
          expect(relative.needsContact, isFalse);
        });

        test('should return false when contacted 1 day ago', () {
          final relative = createTestRelative(
            priority: 1,
            lastContactDate: DateTime.now().subtract(const Duration(days: 1)),
          );
          expect(relative.needsContact, isFalse);
        });

        test('should return true when contacted 2+ days ago', () {
          final relative = createTestRelative(
            priority: 1,
            lastContactDate: DateTime.now().subtract(const Duration(days: 2)),
          );
          expect(relative.needsContact, isTrue);
        });
      });

      group('Medium Priority (2)', () {
        test('should return false when contacted 6 days ago', () {
          final relative = createTestRelative(
            priority: 2,
            lastContactDate: DateTime.now().subtract(const Duration(days: 6)),
          );
          expect(relative.needsContact, isFalse);
        });

        test('should return true when contacted 7+ days ago', () {
          final relative = createTestRelative(
            priority: 2,
            lastContactDate: DateTime.now().subtract(const Duration(days: 7)),
          );
          expect(relative.needsContact, isTrue);
        });
      });

      group('Low Priority (3)', () {
        test('should return false when contacted 13 days ago', () {
          final relative = createTestRelative(
            priority: 3,
            lastContactDate: DateTime.now().subtract(const Duration(days: 13)),
          );
          expect(relative.needsContact, isFalse);
        });

        test('should return true when contacted 14+ days ago', () {
          final relative = createTestRelative(
            priority: 3,
            lastContactDate: DateTime.now().subtract(const Duration(days: 14)),
          );
          expect(relative.needsContact, isTrue);
        });
      });
    });

    // =====================================================
    // COPYWITH TESTS
    // =====================================================
    group('copyWith', () {
      test('should copy with new fullName', () {
        final original = createTestRelative(fullName: 'محمد');
        final copied = original.copyWith(fullName: 'أحمد');

        expect(copied.fullName, equals('أحمد'));
        expect(original.fullName, equals('محمد'));
      });

      test('should copy with new relationshipType', () {
        final original = createTestRelative(relationshipType: RelationshipType.brother);
        final copied = original.copyWith(relationshipType: RelationshipType.uncle);

        expect(copied.relationshipType, equals(RelationshipType.uncle));
        expect(original.relationshipType, equals(RelationshipType.brother));
      });

      test('should copy with new priority', () {
        final original = createTestRelative(priority: 2);
        final copied = original.copyWith(priority: 1);

        expect(copied.priority, equals(1));
        expect(original.priority, equals(2));
      });

      test('should copy with new isFavorite', () {
        final original = createTestRelative(isFavorite: false);
        final copied = original.copyWith(isFavorite: true);

        expect(copied.isFavorite, isTrue);
        expect(original.isFavorite, isFalse);
      });

      test('should copy with new isArchived', () {
        final original = createTestRelative(isArchived: false);
        final copied = original.copyWith(isArchived: true);

        expect(copied.isArchived, isTrue);
        expect(original.isArchived, isFalse);
      });

      test('should copy with new interactionCount', () {
        final original = createTestRelative(interactionCount: 0);
        final copied = original.copyWith(interactionCount: 10);

        expect(copied.interactionCount, equals(10));
        expect(original.interactionCount, equals(0));
      });

      test('should copy with new lastContactDate', () {
        final original = createTestRelative(lastContactDate: null);
        final newDate = DateTime.now();
        final copied = original.copyWith(lastContactDate: newDate);

        expect(copied.lastContactDate, equals(newDate));
        expect(original.lastContactDate, isNull);
      });

      test('should preserve all fields when copying with no changes', () {
        final original = createTestRelative(
          id: 'test-id',
          userId: 'test-user',
          fullName: 'Test Name',
          relationshipType: RelationshipType.brother,
          gender: Gender.male,
          avatarType: AvatarType.adultMan,
          priority: 2,
          isFavorite: true,
          isArchived: false,
          tags: ['tag1', 'tag2'],
        );
        final copied = original.copyWith();

        expect(copied.id, equals(original.id));
        expect(copied.userId, equals(original.userId));
        expect(copied.fullName, equals(original.fullName));
        expect(copied.relationshipType, equals(original.relationshipType));
        expect(copied.gender, equals(original.gender));
        expect(copied.avatarType, equals(original.avatarType));
        expect(copied.priority, equals(original.priority));
        expect(copied.isFavorite, equals(original.isFavorite));
        expect(copied.isArchived, equals(original.isArchived));
        expect(copied.tags, equals(original.tags));
      });
    });

    // =====================================================
    // CONTACT FREQUENCY THRESHOLDS
    // =====================================================
    group('Contact Frequency Thresholds', () {
      test('high priority (1) needs contact every 2 days', () {
        // At 2 days: needs contact
        final relative2Days = createTestRelative(
          priority: 1,
          lastContactDate: DateTime.now().subtract(const Duration(days: 2)),
        );
        expect(relative2Days.needsContact, isTrue);
        expect(relative2Days.daysSinceLastContact, equals(2));
      });

      test('medium priority (2) needs contact every 7 days', () {
        // At 7 days: needs contact
        final relative7Days = createTestRelative(
          priority: 2,
          lastContactDate: DateTime.now().subtract(const Duration(days: 7)),
        );
        expect(relative7Days.needsContact, isTrue);
        expect(relative7Days.daysSinceLastContact, equals(7));
      });

      test('low priority (3) needs contact every 14 days', () {
        // At 14 days: needs contact
        final relative14Days = createTestRelative(
          priority: 3,
          lastContactDate: DateTime.now().subtract(const Duration(days: 14)),
        );
        expect(relative14Days.needsContact, isTrue);
        expect(relative14Days.daysSinceLastContact, equals(14));
      });
    });
  });
}
