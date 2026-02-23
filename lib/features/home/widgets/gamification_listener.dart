import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/gamification_event.dart';
import '../../../core/providers/gamification_events_provider.dart';
import '../../../core/config/supabase_config.dart';

/// Invisible widget that listens to gamification events and calls [onEvent].
///
/// Extracted from HomeScreen to isolate the gamification event listening
/// from the rest of the build method. Uses a callback to communicate
/// events back to the parent state.
class GamificationListener extends ConsumerWidget {
  final void Function(GamificationEvent event) onEvent;

  const GamificationListener({super.key, required this.onEvent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = SupabaseConfig.client.auth.currentUser?.id;

    ref.listen<AsyncValue<GamificationEvent>>(
      gamificationEventsStreamProvider,
      (previous, next) {
        next.whenData((event) {
          if (event.userId != userId) return;
          onEvent(event);
        });
      },
    );

    return const SizedBox.shrink();
  }
}
