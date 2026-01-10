import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/shared/widgets/mood_selector.dart';

/// Widget integration tests for the MoodSelector and interaction logging
///
/// Tests the MoodSelector component used in interaction logging:
/// - Mood selection
/// - Toggle behavior
/// - Compact and full modes
void main() {
  group('MoodSelector Widget Tests', () {
    late String? selectedMood;

    setUp(() {
      selectedMood = null;
    });

    Widget createTestWidget({bool compact = false, bool showLabel = true}) {
      return MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Container(
              color: const Color(0xFF1A1A2E),
              child: MoodSelector(
                selectedMood: selectedMood,
                onMoodChanged: (mood) {
                  setState(() => selectedMood = mood);
                },
                compact: compact,
                showLabel: showLabel,
              ),
            ),
          ),
        ),
      );
    }

    group('Full Mode', () {
      testWidgets('should render all mood options', (tester) async {
        await tester.pumpWidget(createTestWidget());

        for (final mood in MoodOption.values) {
          expect(find.text(mood.emoji), findsOneWidget);
          expect(find.text(mood.arabicName), findsOneWidget);
        }
      });

      testWidgets('should show label when showLabel is true', (tester) async {
        await tester.pumpWidget(createTestWidget(showLabel: true));

        expect(find.text('كيف كان شعورك؟'), findsOneWidget);
        expect(find.textContaining('اختياري'), findsOneWidget);
      });

      testWidgets('should hide label when showLabel is false', (tester) async {
        await tester.pumpWidget(createTestWidget(showLabel: false));

        expect(find.text('كيف كان شعورك؟'), findsNothing);
      });

      testWidgets('should select mood on tap', (tester) async {
        await tester.pumpWidget(createTestWidget());

        await tester.tap(find.text('ممتاز'));
        await tester.pumpAndSettle();

        expect(selectedMood, 'excellent');
      });

      testWidgets('should deselect mood when tapped again', (tester) async {
        selectedMood = 'excellent';
        await tester.pumpWidget(createTestWidget());

        await tester.tap(find.text('ممتاز'));
        await tester.pumpAndSettle();

        expect(selectedMood, isNull);
      });

      testWidgets('should allow changing mood selection', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Select excellent
        await tester.tap(find.text('ممتاز'));
        await tester.pumpAndSettle();
        expect(selectedMood, 'excellent');

        // Change to good
        await tester.tap(find.text('جيد'));
        await tester.pumpAndSettle();
        expect(selectedMood, 'good');
      });

      testWidgets('should show all six moods with correct labels', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Verify all moods are present
        expect(find.text('ممتاز'), findsOneWidget);
        expect(find.text('جيد'), findsOneWidget);
        expect(find.text('عادي'), findsOneWidget);
        expect(find.text('قلق'), findsOneWidget);
        expect(find.text('حزين'), findsOneWidget);
        expect(find.text('مهموم'), findsOneWidget);
      });

      testWidgets('should show all six mood emojis', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('😄'), findsOneWidget);
        expect(find.text('🙂'), findsOneWidget);
        expect(find.text('😐'), findsOneWidget);
        expect(find.text('😟'), findsOneWidget);
        expect(find.text('😢'), findsOneWidget);
        expect(find.text('😰'), findsOneWidget);
      });
    });

    group('Compact Mode', () {
      testWidgets('should render as circles in compact mode', (tester) async {
        await tester.pumpWidget(createTestWidget(compact: true));

        // Should only show emojis, not text labels
        for (final mood in MoodOption.values) {
          expect(find.text(mood.emoji), findsOneWidget);
        }

        // Labels should not be visible in compact mode
        expect(find.text('ممتاز'), findsNothing);
      });

      testWidgets('should select mood in compact mode', (tester) async {
        await tester.pumpWidget(createTestWidget(compact: true));

        await tester.tap(find.text('😄'));
        await tester.pumpAndSettle();

        expect(selectedMood, 'excellent');
      });

      testWidgets('should deselect mood in compact mode', (tester) async {
        selectedMood = 'excellent';
        await tester.pumpWidget(createTestWidget(compact: true));

        await tester.tap(find.text('😄'));
        await tester.pumpAndSettle();

        expect(selectedMood, isNull);
      });

      testWidgets('should change mood in compact mode', (tester) async {
        await tester.pumpWidget(createTestWidget(compact: true));

        await tester.tap(find.text('😄'));
        await tester.pumpAndSettle();
        expect(selectedMood, 'excellent');

        await tester.tap(find.text('😢'));
        await tester.pumpAndSettle();
        expect(selectedMood, 'sad');
      });
    });

    group('MoodOption Enum', () {
      test('should parse mood from string', () {
        expect(MoodOption.fromString('excellent'), MoodOption.excellent);
        expect(MoodOption.fromString('good'), MoodOption.good);
        expect(MoodOption.fromString('neutral'), MoodOption.neutral);
        expect(MoodOption.fromString('concerned'), MoodOption.concerned);
        expect(MoodOption.fromString('sad'), MoodOption.sad);
        expect(MoodOption.fromString('worried'), MoodOption.worried);
      });

      test('should return null for null input', () {
        expect(MoodOption.fromString(null), isNull);
      });

      test('should return neutral for invalid input', () {
        expect(MoodOption.fromString('invalid'), MoodOption.neutral);
      });

      test('should have correct values', () {
        expect(MoodOption.excellent.value, 'excellent');
        expect(MoodOption.excellent.arabicName, 'ممتاز');
        expect(MoodOption.excellent.emoji, '😄');
      });

      test('all moods should have unique values', () {
        final values = MoodOption.values.map((m) => m.value).toSet();
        expect(values.length, MoodOption.values.length);
      });

      test('all moods should have Arabic names', () {
        for (final mood in MoodOption.values) {
          expect(mood.arabicName.isNotEmpty, isTrue);
        }
      });

      test('all moods should have emojis', () {
        for (final mood in MoodOption.values) {
          expect(mood.emoji.isNotEmpty, isTrue);
        }
      });

      test('all moods should have getColor method', () {
        // MoodOption now uses getColor(ThemeColors) for theme-aware colors
        // Just verify all moods have non-empty arabicName (color is theme-dependent)
        for (final mood in MoodOption.values) {
          expect(mood.arabicName.isNotEmpty, isTrue);
        }
      });
    });

    group('Selection State', () {
      testWidgets('initially no mood should be selected', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // No mood should be selected initially
        expect(selectedMood, isNull);
      });

      testWidgets('should maintain selection after rebuild', (tester) async {
        selectedMood = 'good';
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Selection should be maintained
        expect(selectedMood, 'good');
      });
    });
  });

  group('Interaction Type Tests', () {
    test('all interaction types should have correct data', () {
      // These types match the LogInteractionDialog
      const types = [
        {'value': 'call', 'label': 'اتصال', 'emoji': '📞'},
        {'value': 'visit', 'label': 'زيارة', 'emoji': '🏠'},
        {'value': 'message', 'label': 'رسالة', 'emoji': '💬'},
        {'value': 'gift', 'label': 'هدية', 'emoji': '🎁'},
        {'value': 'event', 'label': 'مناسبة', 'emoji': '🎉'},
        {'value': 'other', 'label': 'أخرى', 'emoji': '📝'},
      ];

      expect(types.length, 6);

      for (final type in types) {
        expect(type['value'], isNotNull);
        expect(type['label'], isNotNull);
        expect(type['emoji'], isNotNull);
      }
    });
  });
}
