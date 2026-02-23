import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../providers/home_providers.dart';
import 'widgets.dart';

/// Isolated section for the setup reminders prompt.
///
/// Only watches [reminderSchedulesStreamProvider]. Rebuilds independently
/// from relatives, interactions, and other home screen data.
class SetupRemindersSection extends ConsumerWidget {
  const SetupRemindersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    final schedulesAsync = ref.watch(reminderSchedulesStreamProvider(user.id));

    return schedulesAsync.when(
      data: (schedules) => SetupRemindersPrompt(
        hasReminders: schedules.isNotEmpty,
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
