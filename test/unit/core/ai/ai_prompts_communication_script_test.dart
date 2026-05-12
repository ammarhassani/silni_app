import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/core/ai/ai_prompts.dart';
import 'package:silni_app/shared/models/relative_model.dart';

import '../../../helpers/model_factories.dart';

void main() {
  group('communicationScriptPrompt — gender awareness', () {
    test('includes relative.gender in the prompt body when set (female)', () {
      final aunt = createTestRelative(
        fullName: 'صالحة',
        relationshipType: RelationshipType.aunt,
        gender: Gender.female,
      );
      final prompt =
          AIPrompts.communicationScriptPrompt('تهنئة', aunt, null);
      expect(prompt, contains('أنثى'));
    });

    test('includes relative.gender in the prompt body when set (male)', () {
      final uncle = createTestRelative(
        fullName: 'صالح',
        relationshipType: RelationshipType.uncle,
        gender: Gender.male,
      );
      final prompt =
          AIPrompts.communicationScriptPrompt('تهنئة', uncle, null);
      expect(prompt, contains('ذكر'));
    });

    test('female relative → prompt instructs feminine address forms', () {
      final aunt = createTestRelative(
        fullName: 'صالحة',
        relationshipType: RelationshipType.aunt,
        gender: Gender.female,
      );
      final prompt =
          AIPrompts.communicationScriptPrompt('تهنئة', aunt, null);
      expect(prompt, contains('المؤنث'));
    });

    test('male relative → prompt instructs masculine address forms', () {
      final uncle = createTestRelative(
        fullName: 'صالح',
        relationshipType: RelationshipType.uncle,
        gender: Gender.male,
      );
      final prompt =
          AIPrompts.communicationScriptPrompt('تهنئة', uncle, null);
      expect(prompt, contains('المذكر'));
    });

    test('null gender → prompt asks the model to infer, not default to male', () {
      // Build a relative with gender = null. Factory defaults to male, so we
      // override explicitly using copyWith.
      final r = createTestRelative(
        fullName: 'فلان',
        relationshipType: RelationshipType.cousin,
      ).copyWith(); // copyWith doesn't null gender; build directly:
      final rNoGender = Relative(
        id: r.id,
        userId: r.userId,
        fullName: r.fullName,
        relationshipType: r.relationshipType,
        gender: null,
        createdAt: r.createdAt,
      );
      final prompt =
          AIPrompts.communicationScriptPrompt('تهنئة', rNoGender, null);
      expect(prompt, contains('استنتج'));
    });
  });

  group('communicationScriptPrompt — condolence semantics', () {
    test(
        'scenarioKey "condolence" → prompt clarifies relative is bereaved, not deceased',
        () {
      final aunt = createTestRelative(
        fullName: 'صالحة',
        relationshipType: RelationshipType.aunt,
        gender: Gender.female,
      );
      final prompt = AIPrompts.communicationScriptPrompt(
        'مواساة',
        aunt,
        null,
        scenarioKey: 'condolence',
      );
      // The recipient must NOT be addressed as the deceased.
      expect(prompt, contains('مواساته'));
      expect(prompt, contains('ليس المتوفى'));
    });

    test('non-condolence scenarios omit the bereavement clarification', () {
      final aunt = createTestRelative(
        fullName: 'صالحة',
        relationshipType: RelationshipType.aunt,
        gender: Gender.female,
      );
      final prompt = AIPrompts.communicationScriptPrompt(
        'تهنئة',
        aunt,
        null,
        scenarioKey: 'congratulation',
      );
      expect(prompt, isNot(contains('ليس المتوفى')));
    });
  });

  group('communicationScriptPrompt — no relative provided', () {
    test('does not add gender or condolence-role lines when relative is null',
        () {
      final prompt = AIPrompts.communicationScriptPrompt(
        'مواساة',
        null,
        null,
        scenarioKey: 'condolence',
      );
      expect(prompt, isNot(contains('النوع:')));
      expect(prompt, isNot(contains('ليس المتوفى')));
    });
  });
}
