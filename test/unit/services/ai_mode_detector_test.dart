import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/core/ai/ai_models.dart';
import 'package:silni_app/features/ai_assistant/services/ai_mode_detector.dart';
import 'package:silni_app/shared/models/relative_model.dart';

/// Helper to create a Relative with specific fields for testing
Relative _makeRelative({
  DateTime? lastContactDate,
  int interactionCount = 0,
}) {
  return Relative(
    id: 'test-id',
    userId: 'user-id',
    fullName: 'Test Relative',
    relationshipType: RelationshipType.brother,
    interactionCount: interactionCount,
    lastContactDate: lastContactDate,
    createdAt: DateTime(2024, 1, 1),
  );
}

void main() {
  group('AIModeDetector', () {
    test('detects relationship mode when relative not contacted in 30+ days',
        () {
      final relative = _makeRelative(
        lastContactDate: DateTime.now().subtract(const Duration(days: 35)),
        interactionCount: 10,
      );

      final mode = AIModeDetector.detect(relativeContext: relative);
      expect(mode, equals(CounselingMode.relationship));
    });

    test('detects conflict mode when relative not contacted in 60+ days', () {
      final relative = _makeRelative(
        lastContactDate: DateTime.now().subtract(const Duration(days: 65)),
        interactionCount: 10,
      );

      final mode = AIModeDetector.detect(relativeContext: relative);
      expect(mode, equals(CounselingMode.conflict));
    });

    test('detects communication mode for low-interaction relative', () {
      final relative = _makeRelative(
        lastContactDate: DateTime.now().subtract(const Duration(days: 2)),
        interactionCount: 1,
      );

      final mode = AIModeDetector.detect(relativeContext: relative);
      expect(mode, equals(CounselingMode.communication));
    });

    test('defaults to general when no context', () {
      final mode = AIModeDetector.detect();
      expect(mode, equals(CounselingMode.general));
    });

    test(
        'defaults to general when relative has recent contact and enough interactions',
        () {
      final relative = _makeRelative(
        lastContactDate: DateTime.now().subtract(const Duration(days: 3)),
        interactionCount: 10,
      );

      final mode = AIModeDetector.detect(relativeContext: relative);
      expect(mode, equals(CounselingMode.general));
    });

    test('loggedInteraction last action returns general mode', () {
      final mode =
          AIModeDetector.detect(lastAction: LastAction.loggedInteraction);
      expect(mode, equals(CounselingMode.general));
    });

    test(
        'loggedInteraction last action returns general even with 60+ day relative',
        () {
      final relative = _makeRelative(
        lastContactDate: DateTime.now().subtract(const Duration(days: 90)),
        interactionCount: 0,
      );

      final mode = AIModeDetector.detect(
        relativeContext: relative,
        lastAction: LastAction.loggedInteraction,
      );
      expect(mode, equals(CounselingMode.general));
    });

    test('60+ days takes priority over low interaction count', () {
      // Relative with 60+ days AND low interactions should be conflict,
      // not communication, because 60+ days rule has higher priority
      final relative = _makeRelative(
        lastContactDate: DateTime.now().subtract(const Duration(days: 65)),
        interactionCount: 1,
      );

      final mode = AIModeDetector.detect(relativeContext: relative);
      expect(mode, equals(CounselingMode.conflict));
    });

    test('30+ days takes priority over low interaction count', () {
      // Relative with 30+ days AND low interactions should be relationship,
      // not communication
      final relative = _makeRelative(
        lastContactDate: DateTime.now().subtract(const Duration(days: 40)),
        interactionCount: 1,
      );

      final mode = AIModeDetector.detect(relativeContext: relative);
      expect(mode, equals(CounselingMode.relationship));
    });

    test('detects communication for relative with null lastContactDate', () {
      // No contact date at all + low interactions -> communication
      final relative = _makeRelative(
        lastContactDate: null,
        interactionCount: 0,
      );

      final mode = AIModeDetector.detect(relativeContext: relative);
      expect(mode, equals(CounselingMode.communication));
    });

    test('defaults to general for relative with null lastContactDate but enough interactions', () {
      // No contact date but enough interactions -> general
      final relative = _makeRelative(
        lastContactDate: null,
        interactionCount: 5,
      );

      final mode = AIModeDetector.detect(relativeContext: relative);
      expect(mode, equals(CounselingMode.general));
    });

    test('viewedProfile last action does not override detection', () {
      final relative = _makeRelative(
        lastContactDate: DateTime.now().subtract(const Duration(days: 40)),
        interactionCount: 10,
      );

      final mode = AIModeDetector.detect(
        relativeContext: relative,
        lastAction: LastAction.viewedProfile,
      );
      expect(mode, equals(CounselingMode.relationship));
    });

    test('exactly 30 days triggers relationship mode', () {
      final relative = _makeRelative(
        lastContactDate: DateTime.now().subtract(const Duration(days: 30)),
        interactionCount: 10,
      );

      final mode = AIModeDetector.detect(relativeContext: relative);
      expect(mode, equals(CounselingMode.relationship));
    });

    test('exactly 60 days triggers conflict mode', () {
      final relative = _makeRelative(
        lastContactDate: DateTime.now().subtract(const Duration(days: 60)),
        interactionCount: 10,
      );

      final mode = AIModeDetector.detect(relativeContext: relative);
      expect(mode, equals(CounselingMode.conflict));
    });

    test('29 days does not trigger relationship mode for high-interaction relative', () {
      final relative = _makeRelative(
        lastContactDate: DateTime.now().subtract(const Duration(days: 29)),
        interactionCount: 10,
      );

      final mode = AIModeDetector.detect(relativeContext: relative);
      expect(mode, equals(CounselingMode.general));
    });

    test('exactly 3 interactions does not trigger communication mode', () {
      final relative = _makeRelative(
        lastContactDate: DateTime.now().subtract(const Duration(days: 5)),
        interactionCount: 3,
      );

      final mode = AIModeDetector.detect(relativeContext: relative);
      expect(mode, equals(CounselingMode.general));
    });
  });
}
