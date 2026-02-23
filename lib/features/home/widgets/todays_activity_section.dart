import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../shared/widgets/error_widgets.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../family_tree/providers/family_graph_providers.dart';
import '../providers/home_providers.dart';
import 'widgets.dart';

/// Isolated section for today's activity.
///
/// Watches relatives and today's interactions. Only rebuilds when
/// these specific providers change.
class TodaysActivitySection extends ConsumerWidget {
  const TodaysActivitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    final relativesAsync = ref.watch(viewerFilteredRelativesProvider);
    final groupInfo = ref.watch(userFamilyGroupProvider).valueOrNull;
    final todayInteractionsAsync = groupInfo != null
        ? ref.watch(groupTodayInteractionsStreamProvider(groupInfo.groupId))
        : ref.watch(todayInteractionsStreamProvider(user.id));

    return relativesAsync.when(
      data: (relatives) => todayInteractionsAsync.when(
        data: (interactions) => TodaysActivityWidget(
          interactions: interactions,
          relatives: relatives,
        ),
        loading: () => const TodaysActivitySkeleton(),
        error: (error, _) => InlineErrorWidget(
          message: '\u0641\u0634\u0644 \u0641\u064a \u062a\u062d\u0645\u064a\u0644 \u0646\u0634\u0627\u0637 \u0627\u0644\u064a\u0648\u0645',
          onRetry: () {
            if (groupInfo != null) {
              ref.invalidate(
                  groupTodayInteractionsStreamProvider(groupInfo.groupId));
            } else {
              ref.invalidate(todayInteractionsStreamProvider(user.id));
            }
          },
          compact: true,
        ),
      ),
      loading: () => const TodaysActivitySkeleton(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
