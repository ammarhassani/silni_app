import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/core/ai/ai_prompts.dart';

void main() {
  group('AIPrompts.shareCopyPrompt', () {
    test('streak prompt contains streak count and proud tone', () {
      final prompt = AIPrompts.shareCopyPrompt(
        cardType: 'streak',
        context: {
          'streak_count': 15,
          'relative_name': 'أبوي',
        },
      );

      expect(prompt, contains('15'));
      expect(prompt, contains('streak'));
      expect(prompt, contains('افتخار'));
    });

    test('badge prompt contains badge name', () {
      final prompt = AIPrompts.shareCopyPrompt(
        cardType: 'badge',
        context: {
          'badge_name': 'واصل الأسبوع',
          'badge_level': 'ذهبي',
        },
      );

      expect(prompt, contains('واصل الأسبوع'));
      expect(prompt, contains('ذهبي'));
      expect(prompt, contains('احتفالي'));
    });

    test('occasion prompt contains occasion name', () {
      final prompt = AIPrompts.shareCopyPrompt(
        cardType: 'occasion',
        context: {
          'occasion_name': 'عيد الفطر',
          'relative_count': 8,
        },
      );

      expect(prompt, contains('عيد الفطر'));
      expect(prompt, contains('تهنئة'));
    });

    test('level_up prompt contains motivational tone', () {
      final prompt = AIPrompts.shareCopyPrompt(
        cardType: 'level_up',
        context: {
          'new_level': 5,
          'total_points': 1200,
        },
      );

      expect(prompt, contains('5'));
      expect(prompt, contains('1200'));
      expect(prompt, contains('تحفيزي'));
    });

    test('wrapped prompt contains summary tone', () {
      final prompt = AIPrompts.shareCopyPrompt(
        cardType: 'wrapped',
        context: {
          'total_interactions': 250,
          'top_relative': 'أمي',
        },
      );

      expect(prompt, contains('250'));
      expect(prompt, contains('أمي'));
      expect(prompt, contains('ملخّص'));
    });

    test('prompt enforces max 20 words and plain text rules', () {
      final prompt = AIPrompts.shareCopyPrompt(
        cardType: 'streak',
        context: {'streak_count': 7},
      );

      expect(prompt, contains('٢٠'));
      expect(prompt, contains('بدون JSON'));
      expect(prompt, contains('بدون ماركداون'));
      expect(prompt, contains('إيموجي واحد'));
    });

    test('unknown card type uses positive fallback tone', () {
      final prompt = AIPrompts.shareCopyPrompt(
        cardType: 'unknown_type',
        context: {'data': 'test'},
      );

      expect(prompt, contains('إيجابي'));
    });

    test('prompt includes dynamic personality from admin config', () {
      final prompt = AIPrompts.shareCopyPrompt(
        cardType: 'streak',
        context: {'streak_count': 7},
      );

      // Should include the dynamic personality (fallback includes واصل)
      expect(prompt, contains(AIPrompts.dynamicPersonality));
    });
  });
}
