import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../shared/widgets/error_widgets.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/providers/interactions_provider.dart';
import '../../family_tree/providers/family_graph_providers.dart';
import '../providers/home_providers.dart';
import '../providers/relationship_labels_provider.dart';
import 'widgets.dart';

/// Isolated section for due reminders.
///
/// Watches relatives, schedules, contacted status, and relationship labels.
/// Only rebuilds when these specific providers change.
class DueRemindersSection extends ConsumerWidget {
  const DueRemindersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    final relativesAsync = ref.watch(viewerFilteredRelativesProvider);
    final schedulesAsync = ref.watch(reminderSchedulesStreamProvider(user.id));
    final groupInfo = ref.watch(userFamilyGroupProvider).valueOrNull;
    final todayContactedAsync = groupInfo != null
        ? ref.watch(groupTodayContactedRelativesProvider(groupInfo.groupId))
        : ref.watch(todayContactedRelativesProvider(user.id));
    final relationshipLabels = ref.watch(relationshipLabelsProvider);

    return relativesAsync.when(
      data: (relatives) => schedulesAsync.when(
        data: (schedules) => DueRemindersCard(
          userId: user.id,
          relatives: relatives,
          schedules: schedules,
          contactedSet: todayContactedAsync.valueOrNull ?? <String>{},
          relationshipLabels: relationshipLabels,
        ),
        loading: () => const DueRemindersCardSkeleton(),
        error: (e, _) => InlineErrorWidget.fromError(
          e,
          compact: true,
          onRetry: () =>
              ref.invalidate(reminderSchedulesStreamProvider(user.id)),
        ),
      ),
      loading: () => const DueRemindersCardSkeleton(),
      error: (e, _) => InlineErrorWidget.fromError(
        e,
        compact: true,
        onRetry: () => ref.invalidate(viewerFilteredRelativesProvider),
      ),
    );
  }
}
