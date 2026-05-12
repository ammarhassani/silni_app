import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/core/ai/ai_context_engine.dart';
import 'package:silni_app/core/ai/ai_models.dart';
import 'package:silni_app/core/ai/ai_prompts.dart';

void main() {
  group('buildEnhancedChatSystemPrompt — strict scope enforcement', () {
    test('every chat prompt includes the strict-scope refusal rule', () {
      for (final mode in CounselingMode.values) {
        final prompt = AIPrompts.buildEnhancedChatSystemPrompt(
          mode: mode,
          context: AIContext.empty(),
        );
        expect(
          prompt,
          contains(AIPrompts.strictScopeRule),
          reason: 'mode ${mode.name} must carry the strict scope rule',
        );
      }
    });

    test('strict scope rule explicitly forbids partial answers', () {
      // The bug was: AI said "out of scope" then answered anyway. The rule
      // must call out the refusal as total, no answer, no alternatives.
      final rule = AIPrompts.strictScopeRule;
      expect(rule, contains('خارج نطاق'));
      expect(rule, contains('لا تجيب'));
    });

    test('general-mode hardcoded fallback no longer says "be flexible"', () {
      // Regression guard: the "كن مرناً في المواضيع" line was the smoking
      // gun in Defect 2.
      final fallback = AIPrompts.getModeInstructions(CounselingMode.general);
      expect(fallback, isNot(contains('كن مرناً في المواضيع')));
    });
  });
}
