import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/relative_model.dart';
import '../../auth/providers/auth_provider.dart';
import 'home_providers.dart';

/// AI Briefing data model
class AIBriefing {
  final String emoji;
  final String message;
  final List<BriefingAction> actions;
  final String? relativeId;

  const AIBriefing({
    required this.emoji,
    required this.message,
    required this.actions,
    this.relativeId,
  });
}

enum BriefingAction { call, message, visit }

/// Provider that generates a proactive AI briefing card based on user's family data
final aiBriefingProvider = Provider.autoDispose<AsyncValue<AIBriefing?>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const AsyncValue.data(null);

  final relativesAsync = ref.watch(viewerFilteredRelativesProvider);

  return relativesAsync.whenData((relatives) {
    if (relatives.isEmpty) return null;

    final now = DateTime.now();
    final upcoming = relatives.where((r) {
      if (r.dateOfBirth == null) return false;
      final days = _daysUntilBirthday(r.dateOfBirth!, now);
      return days <= 3;
    }).toList();

    // Priority 1: Upcoming birthday (with or without interests compound)
    if (upcoming.isNotEmpty) {
      final r = upcoming.first;
      final days = _daysUntilBirthday(r.dateOfBirth!, now);

      // Compound: birthday + interests
      if (days > 0 &&
          days <= 3 &&
          r.interests != null &&
          r.interests!.isNotEmpty) {
        final interest = r.interests!.first;
        return AIBriefing(
          emoji: '🎂',
          message:
              'عيد ميلاد ${r.fullName} بعد ${days == 1 ? "يوم" : "$days أيام"} — يحب $interest، وش رايك تفاجئه؟',
          actions: [BriefingAction.call, BriefingAction.message],
          relativeId: r.id,
        );
      }

      // Simple birthday
      return AIBriefing(
        emoji: '🎂',
        message: days == 0
            ? 'اليوم عيد ميلاد ${r.fullName}!'
            : 'عيد ميلاد ${r.fullName} بعد ${days == 1 ? "يوم" : "$days أيام"}',
        actions: [BriefingAction.call, BriefingAction.message],
        relativeId: r.id,
      );
    }

    // Priority 2: Health concern + contact gap compound
    final healthConcern = relatives
        .where((r) => r.relativeCategory == RelativeCategory.extended)
        .where((r) => r.healthStatus != null && r.healthStatus!.isNotEmpty)
        .where((r) => r.lastContactDate != null)
        .where((r) => now.difference(r.lastContactDate!).inDays >= 4)
        .toList();

    if (healthConcern.isNotEmpty) {
      final r = healthConcern.first;
      final days = now.difference(r.lastContactDate!).inDays;
      return AIBriefing(
        emoji: '💚',
        message:
            '${r.fullName} ذكر إنه ${r.healthStatus} + لك ${_arabicDays(days)} ما اتصلت — تطمّن عليه',
        actions: [BriefingAction.call],
        relativeId: r.id,
      );
    }

    // Priority 2.5: Friday suggestion
    if (now.weekday == DateTime.friday) {
      final fridayRelative = relatives
          .where((r) => r.relativeCategory == RelativeCategory.extended)
          .where((r) => r.lastContactDate != null)
          .where((r) => now.difference(r.lastContactDate!).inDays >= 3)
          .toList();

      if (fridayRelative.isNotEmpty) {
        final r = fridayRelative.first;
        return AIBriefing(
          emoji: '🤍',
          message: 'الجمعة يوم مبارك — وقت حلو تتصل على ${r.fullName}',
          actions: [BriefingAction.call],
          relativeId: r.id,
        );
      }
    }

    // Priority 3: Extended relative with longest gap (7+ days)
    final extended = relatives
        .where((r) => r.relativeCategory == RelativeCategory.extended)
        .where((r) => r.lastContactDate != null)
        .toList()
      ..sort((a, b) => a.lastContactDate!.compareTo(b.lastContactDate!));

    if (extended.isNotEmpty) {
      final r = extended.first;
      final days = now.difference(r.lastContactDate!).inDays;
      if (days >= 7) {
        return AIBriefing(
          emoji: '💛',
          message: 'لك ${_arabicDays(days)} ما تواصلت مع ${r.fullName}',
          actions: [BriefingAction.call, BriefingAction.message],
          relativeId: r.id,
        );
      }
    }

    // Priority 4: Household quality suggestion
    final household = relatives
        .where((r) => r.relativeCategory == RelativeCategory.household)
        .toList();

    if (household.isNotEmpty) {
      // Rotate suggestions based on day
      final index = now.day % household.length;
      final r = household[index];
      return AIBriefing(
        emoji: '🏠',
        message: 'وش رايك تسأل ${r.fullName} عن يومه اليوم؟',
        actions: [],
        relativeId: null,
      );
    }

    return null;
  });
});

int _daysUntilBirthday(DateTime birthday, DateTime now) {
  final todayDate = DateTime(now.year, now.month, now.day);
  var nextBirthday = DateTime(now.year, birthday.month, birthday.day);

  if (nextBirthday.isAtSameMomentAs(todayDate)) {
    return 0;
  }

  if (nextBirthday.isBefore(todayDate)) {
    nextBirthday = DateTime(now.year + 1, birthday.month, birthday.day);
  }

  return nextBirthday.difference(todayDate).inDays;
}

String _arabicDays(int days) {
  if (days == 1) return 'يوم';
  if (days == 2) return 'يومين';
  if (days >= 3 && days <= 10) return '$days أيام';
  return '$days يوم';
}
