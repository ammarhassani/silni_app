import 'package:shared_preferences/shared_preferences.dart';
import '../../features/relatives/services/relationship_inference_service.dart';
import '../../shared/models/relative_model.dart';

/// Progressive fact-gathering engine.
/// Shows at most 4 follow-up questions per week to avoid overwhelming the user.
class OneQuestionEngine {
  static const _prefsKey = 'one_question_';
  static const _maxQuestionsPerWeek = 4;

  /// Returns a follow-up question for this relative, or null if not appropriate.
  /// [displayName] overrides fullName in question text (e.g. "عمك منصور" instead of "عمي منصور").
  static Future<FollowUpQuestion?> getQuestion({
    required Relative relative,
    required SharedPreferences prefs,
    String? displayName,
  }) async {
    // Check rate limit: max 4 questions per week
    final weekCount = prefs.getInt('${_prefsKey}week_count') ?? 0;
    final weekStart = prefs.getString('${_prefsKey}week_start');
    final now = DateTime.now();

    if (weekStart != null) {
      final start = DateTime.parse(weekStart);
      if (now.difference(start).inDays >= 7) {
        // New week — reset
        await prefs.setInt('${_prefsKey}week_count', 0);
        await prefs.setString('${_prefsKey}week_start', now.toIso8601String());
      } else if (weekCount >= _maxQuestionsPerWeek) {
        return null; // Already asked enough this week
      }
    } else {
      await prefs.setString('${_prefsKey}week_start', now.toIso8601String());
    }

    // Pick question based on what we DON'T know yet
    final asked = prefs.getStringList('${_prefsKey}asked_${relative.id}') ?? [];
    return _pickQuestion(relative, asked, displayName ?? relative.fullName);
  }

  static FollowUpQuestion? _pickQuestion(Relative relative, List<String> asked, String name) {
    // Resolve gender using the app's 3-step priority chain:
    // relationship type → stored gender → name inference
    final resolvedGender = RelationshipInferenceService.resolveGender(
      relationshipType: relative.relationshipType,
      storedGender: relative.gender,
      fullName: relative.fullName,
    );
    final isMale = resolvedGender != Gender.female; // null → male (app convention)

    // Gender-conditional verb forms (same pattern as proactive_insight_service)
    final likes = isMale ? 'يحبه' : 'تحبه';
    final does = isMale ? 'يسوّيه' : 'تسوّيه';
    final prefers = isMale ? 'يفضل' : 'تفضل';
    final upsets = isMale ? 'يزعل' : 'تزعل';
    final pronoun = isMale ? 'تكلمته' : 'تكلمتها';
    final freeTime = isMale ? 'فراغه' : 'فراغها';

    final questions = <String, FollowUpQuestion>{
      'interests': FollowUpQuestion(
        key: 'interests',
        text: 'وش الشي اللي $likes $name $does بوقت $freeTime؟',
        field: 'interests',
      ),
      'health': FollowUpQuestion(
        key: 'health',
        text: 'كيف صحة $name هالفترة؟',
        field: 'health_status',
      ),
      'communication_style': FollowUpQuestion(
        key: 'communication_style',
        text: '$name $prefers الاتصال ولا الرسائل؟',
        field: 'communication_style',
      ),
      'best_time': FollowUpQuestion(
        key: 'best_time',
        text: 'متى أحسن وقت تتواصل مع $name؟',
        field: 'best_time_to_contact',
      ),
      'sensitive_topics': FollowUpQuestion(
        key: 'sensitive_topics',
        text: 'فيه شي $upsets $name لو $pronoun عنه؟',
        field: 'sensitive_topics',
      ),
    };

    // Skip questions already asked or for fields already populated
    final candidates = questions.entries.where((e) {
      if (asked.contains(e.key)) return false;
      return switch (e.value.field) {
        'interests' => relative.interests == null || relative.interests!.isEmpty,
        'health_status' => relative.healthStatus == null,
        'communication_style' => relative.communicationStyle == null,
        'best_time_to_contact' => relative.bestTimeToContact == null,
        'sensitive_topics' => relative.sensitiveTopics == null || relative.sensitiveTopics!.isEmpty,
        _ => true,
      };
    }).toList();

    if (candidates.isEmpty) return null;
    return candidates.first.value;
  }

  /// Save the answer and update rate limit
  static Future<void> recordAnswer({
    required String relativeId,
    required String questionKey,
    required SharedPreferences prefs,
  }) async {
    final asked = prefs.getStringList('${_prefsKey}asked_$relativeId') ?? [];
    asked.add(questionKey);
    await prefs.setStringList('${_prefsKey}asked_$relativeId', asked);

    final weekCount = prefs.getInt('${_prefsKey}week_count') ?? 0;
    await prefs.setInt('${_prefsKey}week_count', weekCount + 1);
  }
}

class FollowUpQuestion {
  final String key;
  final String text;
  final String field; // maps to Relative model field name

  const FollowUpQuestion({
    required this.key,
    required this.text,
    required this.field,
  });
}
