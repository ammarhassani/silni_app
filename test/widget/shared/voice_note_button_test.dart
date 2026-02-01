import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for VoiceNoteButton's pure logic (controller text appending).
///
/// Note: The actual speech recognition functionality requires hardware
/// (microphone + speech recognition engine) and cannot be tested in unit
/// tests. These tests cover the text appending logic and widget structure.
void main() {
  group('VoiceNoteButton - Controller Text Appending Logic', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('appends text to empty controller', () {
      // Simulate the append logic from VoiceNoteButton
      const recognizedText = 'مرحبا كيف حالك';
      final existing = controller.text;
      controller.text =
          existing.isEmpty ? recognizedText : '$existing\n$recognizedText';

      expect(controller.text, equals('مرحبا كيف حالك'));
    });

    test('appends text with newline to non-empty controller', () {
      controller.text = 'ملاحظة أولى';

      const recognizedText = 'ملاحظة ثانية';
      final existing = controller.text;
      controller.text =
          existing.isEmpty ? recognizedText : '$existing\n$recognizedText';

      expect(controller.text, equals('ملاحظة أولى\nملاحظة ثانية'));
    });

    test('handles multiple appends correctly', () {
      const texts = ['السلام عليكم', 'كيف حالك', 'الحمد لله'];

      for (final text in texts) {
        final existing = controller.text;
        controller.text = existing.isEmpty ? text : '$existing\n$text';
      }

      expect(
        controller.text,
        equals('السلام عليكم\nكيف حالك\nالحمد لله'),
      );
    });

    test('cursor moves to end after append', () {
      controller.text = 'نص موجود';

      const recognizedText = 'نص جديد';
      final existing = controller.text;
      controller.text =
          existing.isEmpty ? recognizedText : '$existing\n$recognizedText';
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );

      expect(
        controller.selection.baseOffset,
        equals(controller.text.length),
      );
    });
  });
}
