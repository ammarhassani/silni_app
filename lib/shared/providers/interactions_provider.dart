import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/gamification_provider.dart';
import '../services/interactions_service.dart';

/// Provider for the Interactions service with gamification support
final interactionsServiceProvider = Provider<InteractionsService>((ref) {
  final gamificationService = ref.watch(gamificationServiceProvider);
  return InteractionsService(gamificationService: gamificationService);
});

/// Provider that streams today's contacted relative IDs
/// Used to derive "contacted" status in reminders screen
final todayContactedRelativesProvider =
    StreamProvider.family<Set<String>, String>((ref, userId) {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  return Supabase.instance.client
      .from('interactions')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .map((data) {
        // Filter to today's interactions and extract relative IDs
        final todayInteractions = data.where((interaction) {
          final dateStr = interaction['date'] as String?;
          if (dateStr == null) return false;
          final date = DateTime.parse(dateStr).toLocal();
          // Check both start and end of day boundaries
          return (date.isAfter(startOfDay) || date.isAtSameMomentAs(startOfDay))
              && date.isBefore(endOfDay);
        });
        return todayInteractions
            .map((i) => i['relative_id'] as String)
            .toSet();
      });
});
