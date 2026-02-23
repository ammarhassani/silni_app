import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/error_widgets.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../providers/home_providers.dart';
import '../providers/relationship_labels_provider.dart';
import 'widgets.dart';

/// Isolated section that watches its own providers for family circles.
///
/// Only rebuilds when [viewerFilteredRelativesProvider] or
/// [relationshipLabelsProvider] change -- not when interactions,
/// reminders, or other unrelated providers update.
class FamilyCirclesSection extends ConsumerWidget {
  const FamilyCirclesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relativesAsync = ref.watch(viewerFilteredRelativesProvider);
    final relationshipLabels = ref.watch(relationshipLabelsProvider);

    return relativesAsync.when(
      data: (relatives) => FamilyCirclesWidget(
        relatives: relatives,
        relationshipLabels: relationshipLabels,
      ),
      loading: () => const FamilyCirclesSkeleton(),
      error: (error, _) => InlineErrorWidget(
        message: '\u0641\u0634\u0644 \u0641\u064a \u062a\u062d\u0645\u064a\u0644 \u0628\u064a\u0627\u0646\u0627\u062a \u0627\u0644\u0639\u0627\u0626\u0644\u0629',
        onRetry: () => ref.invalidate(viewerFilteredRelativesProvider),
      ),
    );
  }
}
