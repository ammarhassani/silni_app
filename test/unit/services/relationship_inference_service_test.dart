import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/features/relatives/services/relationship_inference_service.dart';
import 'package:silni_app/shared/models/relative_model.dart';

/// Helper to create a minimal [Relative] with a given [RelationshipType].
Relative _makeRelative(RelationshipType type) {
  return Relative(
    id: 'test-${type.value}',
    userId: 'user-1',
    fullName: 'Test ${type.arabicName}',
    relationshipType: type,
    createdAt: DateTime.now(),
  );
}

void main() {
  group('RelationshipInferenceService', () {
    // =========================================================
    // suggestRelationships
    // =========================================================
    group('suggestRelationships', () {
      test('should suggest parents first when none exist', () {
        final suggestions =
            RelationshipInferenceService.suggestRelationships([]);
        expect(suggestions.first, RelationshipType.father);
        expect(suggestions[1], RelationshipType.mother);
      });

      test('should handle empty list and return results', () {
        final suggestions =
            RelationshipInferenceService.suggestRelationships([]);
        expect(suggestions, isNotEmpty);
        expect(suggestions.length, greaterThanOrEqualTo(4));
        expect(suggestions.length, lessThanOrEqualTo(6));
      });

      test('should always return results (never empty)', () {
        // Even with a full family tree, we should get suggestions
        final allTypes = RelationshipType.values
            .map((type) => _makeRelative(type))
            .toList();
        final suggestions =
            RelationshipInferenceService.suggestRelationships(allTypes);
        expect(suggestions, isNotEmpty);
        expect(suggestions.length, greaterThanOrEqualTo(4));
      });

      test('should suggest siblings when parents exist but no siblings', () {
        final relatives = [
          _makeRelative(RelationshipType.father),
          _makeRelative(RelationshipType.mother),
        ];
        final suggestions =
            RelationshipInferenceService.suggestRelationships(relatives);

        // Siblings should be present in suggestions
        expect(suggestions, contains(RelationshipType.brother));
        expect(suggestions, contains(RelationshipType.sister));
      });

      test('should suggest spouse when parents exist but no spouse', () {
        final relatives = [
          _makeRelative(RelationshipType.father),
          _makeRelative(RelationshipType.mother),
        ];
        final suggestions =
            RelationshipInferenceService.suggestRelationships(relatives);

        // Spouse options should be present
        final hasSpouseOption =
            suggestions.contains(RelationshipType.husband) ||
                suggestions.contains(RelationshipType.wife);
        expect(hasSpouseOption, isTrue);
      });

      test(
          'should suggest extended family when immediate family exists',
          () {
        final relatives = [
          _makeRelative(RelationshipType.father),
          _makeRelative(RelationshipType.mother),
          _makeRelative(RelationshipType.brother),
          _makeRelative(RelationshipType.sister),
          _makeRelative(RelationshipType.husband),
        ];
        final suggestions =
            RelationshipInferenceService.suggestRelationships(relatives);

        // Extended family should be suggested
        final hasExtended =
            suggestions.contains(RelationshipType.grandfather) ||
                suggestions.contains(RelationshipType.grandmother) ||
                suggestions.contains(RelationshipType.uncle) ||
                suggestions.contains(RelationshipType.aunt);
        expect(hasExtended, isTrue);
      });

      test('should not suggest father if father already exists', () {
        final relatives = [
          _makeRelative(RelationshipType.father),
        ];
        final suggestions =
            RelationshipInferenceService.suggestRelationships(relatives);

        // Father should NOT be the first suggestion since it already exists
        expect(suggestions.first, isNot(RelationshipType.father));
      });

      test('should not suggest mother if mother already exists', () {
        final relatives = [
          _makeRelative(RelationshipType.mother),
        ];
        final suggestions =
            RelationshipInferenceService.suggestRelationships(relatives);

        // Mother should be absent; father should be first
        expect(suggestions.first, RelationshipType.father);
        expect(suggestions, isNot(contains(RelationshipType.mother)));
      });

      test('should return between 4 and 6 suggestions', () {
        // Test with various family sizes
        for (var i = 0; i < RelationshipType.values.length; i++) {
          final relatives = RelationshipType.values
              .take(i)
              .map((type) => _makeRelative(type))
              .toList();
          final suggestions =
              RelationshipInferenceService.suggestRelationships(relatives);
          expect(
            suggestions.length,
            greaterThanOrEqualTo(4),
            reason: 'With $i existing relatives, got ${suggestions.length} suggestions',
          );
          expect(
            suggestions.length,
            lessThanOrEqualTo(6),
            reason: 'With $i existing relatives, got ${suggestions.length} suggestions',
          );
        }
      });

      test('should not contain duplicates', () {
        final suggestions =
            RelationshipInferenceService.suggestRelationships([]);
        expect(suggestions.toSet().length, suggestions.length);
      });
    });

    // =========================================================
    // inferGender
    // =========================================================
    group('inferGender', () {
      test('should return male for common male name (محمد)', () {
        expect(
          RelationshipInferenceService.inferGender('محمد'),
          Gender.male,
        );
      });

      test('should return male for common male name (أحمد)', () {
        expect(
          RelationshipInferenceService.inferGender('أحمد'),
          Gender.male,
        );
      });

      test('should return male for common male name (عبدالله)', () {
        expect(
          RelationshipInferenceService.inferGender('عبدالله'),
          Gender.male,
        );
      });

      test('should return male for common male name (خالد)', () {
        expect(
          RelationshipInferenceService.inferGender('خالد'),
          Gender.male,
        );
      });

      test('should return female for common female name (فاطمة)', () {
        expect(
          RelationshipInferenceService.inferGender('فاطمة'),
          Gender.female,
        );
      });

      test('should return female for common female name (عائشة)', () {
        expect(
          RelationshipInferenceService.inferGender('عائشة'),
          Gender.female,
        );
      });

      test('should return female for common female name (نورة)', () {
        expect(
          RelationshipInferenceService.inferGender('نورة'),
          Gender.female,
        );
      });

      test('should return null for ambiguous name (نور)', () {
        expect(
          RelationshipInferenceService.inferGender('نور'),
          isNull,
        );
      });

      test('should return null for ambiguous name (إيمان)', () {
        expect(
          RelationshipInferenceService.inferGender('إيمان'),
          isNull,
        );
      });

      test('should return female for names ending in taa marbouta (ة)', () {
        // A name not in the explicit lists but ending in ة
        expect(
          RelationshipInferenceService.inferGender('حليمة'),
          Gender.female,
        );
      });

      test('should return female for names ending in اء (pattern match)', () {
        // Use هيفاء which is NOT in the known-names set but ends in اء
        expect(
          RelationshipInferenceService.inferGender('هيفاء'),
          Gender.female,
        );
      });

      test('should return female for أسماء (known name lookup)', () {
        expect(
          RelationshipInferenceService.inferGender('أسماء'),
          Gender.female,
        );
      });

      test('should return male for names starting with عبد', () {
        // A name not in the explicit lists but starting with عبد
        expect(
          RelationshipInferenceService.inferGender('عبدالملك'),
          Gender.male,
        );
      });

      test('should return null for empty string', () {
        expect(
          RelationshipInferenceService.inferGender(''),
          isNull,
        );
      });

      test('should return null for whitespace-only string', () {
        expect(
          RelationshipInferenceService.inferGender('   '),
          isNull,
        );
      });

      test('should use first name only for full names', () {
        // "محمد أحمد" — first name is محمد which is male
        expect(
          RelationshipInferenceService.inferGender('محمد أحمد'),
          Gender.male,
        );
      });

      test('should handle full female name', () {
        // "فاطمة علي" — first name is فاطمة which is female
        expect(
          RelationshipInferenceService.inferGender('فاطمة علي'),
          Gender.female,
        );
      });
    });
  });

  group('genderFromRelationship', () {
    test('returns male for male-only relationships', () {
      expect(
          RelationshipInferenceService.genderFromRelationship(
              RelationshipType.father),
          Gender.male);
      expect(
          RelationshipInferenceService.genderFromRelationship(
              RelationshipType.brother),
          Gender.male);
      expect(
          RelationshipInferenceService.genderFromRelationship(
              RelationshipType.son),
          Gender.male);
      expect(
          RelationshipInferenceService.genderFromRelationship(
              RelationshipType.grandfather),
          Gender.male);
      expect(
          RelationshipInferenceService.genderFromRelationship(
              RelationshipType.uncle),
          Gender.male);
      expect(
          RelationshipInferenceService.genderFromRelationship(
              RelationshipType.nephew),
          Gender.male);
      expect(
          RelationshipInferenceService.genderFromRelationship(
              RelationshipType.husband),
          Gender.male);
    });

    test('returns female for female-only relationships', () {
      expect(
          RelationshipInferenceService.genderFromRelationship(
              RelationshipType.mother),
          Gender.female);
      expect(
          RelationshipInferenceService.genderFromRelationship(
              RelationshipType.sister),
          Gender.female);
      expect(
          RelationshipInferenceService.genderFromRelationship(
              RelationshipType.daughter),
          Gender.female);
      expect(
          RelationshipInferenceService.genderFromRelationship(
              RelationshipType.grandmother),
          Gender.female);
      expect(
          RelationshipInferenceService.genderFromRelationship(
              RelationshipType.aunt),
          Gender.female);
      expect(
          RelationshipInferenceService.genderFromRelationship(
              RelationshipType.niece),
          Gender.female);
      expect(
          RelationshipInferenceService.genderFromRelationship(
              RelationshipType.wife),
          Gender.female);
    });

    test('returns null for gender-neutral relationships', () {
      expect(
          RelationshipInferenceService.genderFromRelationship(
              RelationshipType.cousin),
          isNull);
      expect(
          RelationshipInferenceService.genderFromRelationship(
              RelationshipType.other),
          isNull);
    });
  });

  group('resolveGender', () {
    test('relationship type wins over everything', () {
      expect(
        RelationshipInferenceService.resolveGender(
          relationshipType: RelationshipType.father,
          storedGender: Gender.female,
          fullName: 'فاطمة',
        ),
        Gender.male,
      );
    });

    test('stored gender wins over name inference', () {
      expect(
        RelationshipInferenceService.resolveGender(
          relationshipType: RelationshipType.cousin,
          storedGender: Gender.female,
          fullName: 'محمد',
        ),
        Gender.female,
      );
    });

    test('name inference used for gender-neutral types without stored gender',
        () {
      expect(
        RelationshipInferenceService.resolveGender(
          relationshipType: RelationshipType.cousin,
          fullName: 'محمد',
        ),
        Gender.male,
      );
      expect(
        RelationshipInferenceService.resolveGender(
          relationshipType: RelationshipType.other,
          fullName: 'فاطمة',
        ),
        Gender.female,
      );
    });

    test('returns null when nothing can determine gender', () {
      expect(
        RelationshipInferenceService.resolveGender(
          relationshipType: RelationshipType.cousin,
          fullName: 'John',
        ),
        isNull,
      );
      expect(
        RelationshipInferenceService.resolveGender(
          relationshipType: RelationshipType.cousin,
        ),
        isNull,
      );
    });
  });

  group('adjustRelationshipForGender', () {
    test('flips brother to sister for female', () {
      expect(
        RelationshipInferenceService.adjustRelationshipForGender(
          RelationshipType.brother,
          Gender.female,
        ),
        RelationshipType.sister,
      );
    });

    test('flips sister to brother for male', () {
      expect(
        RelationshipInferenceService.adjustRelationshipForGender(
          RelationshipType.sister,
          Gender.male,
        ),
        RelationshipType.brother,
      );
    });

    test('flips son to daughter for female', () {
      expect(
        RelationshipInferenceService.adjustRelationshipForGender(
          RelationshipType.son,
          Gender.female,
        ),
        RelationshipType.daughter,
      );
    });

    test('flips uncle to aunt for female', () {
      expect(
        RelationshipInferenceService.adjustRelationshipForGender(
          RelationshipType.uncle,
          Gender.female,
        ),
        RelationshipType.aunt,
      );
    });

    test('flips husband to wife for female', () {
      expect(
        RelationshipInferenceService.adjustRelationshipForGender(
          RelationshipType.husband,
          Gender.female,
        ),
        RelationshipType.wife,
      );
    });

    test('keeps gender-neutral types unchanged', () {
      expect(
        RelationshipInferenceService.adjustRelationshipForGender(
          RelationshipType.cousin,
          Gender.male,
        ),
        RelationshipType.cousin,
      );
      expect(
        RelationshipInferenceService.adjustRelationshipForGender(
          RelationshipType.other,
          Gender.female,
        ),
        RelationshipType.other,
      );
    });

    test('keeps type unchanged when gender is null', () {
      expect(
        RelationshipInferenceService.adjustRelationshipForGender(
          RelationshipType.brother,
          null,
        ),
        RelationshipType.brother,
      );
    });

    test('keeps matching type-gender pairs unchanged', () {
      expect(
        RelationshipInferenceService.adjustRelationshipForGender(
          RelationshipType.father,
          Gender.male,
        ),
        RelationshipType.father,
      );
      expect(
        RelationshipInferenceService.adjustRelationshipForGender(
          RelationshipType.mother,
          Gender.female,
        ),
        RelationshipType.mother,
      );
    });
  });

}
