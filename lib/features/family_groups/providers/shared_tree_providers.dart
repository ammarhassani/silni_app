import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:silni_app/shared/models/relative_model.dart';

import '../services/shared_tree_service.dart';

/// Cache duration — matches the project-wide 5-minute convention.
const _cacheTimeout = Duration(minutes: 5);

/// Stream provider for shared relatives in a family group.
///
/// Accepts a [groupId] and streams the list of non-archived shared
/// [Relative]s in that group, sorted alphabetically by name.
/// Uses autoDispose with timed cache (5 min) to balance freshness
/// and performance.
final sharedRelativesProvider =
    StreamProvider.autoDispose.family<List<Relative>, String>(
  (ref, groupId) {
    final link = ref.keepAlive();
    Timer? timer;

    ref.onDispose(() => timer?.cancel());
    ref.onCancel(() {
      timer = Timer(_cacheTimeout, () => link.close());
    });
    ref.onResume(() => timer?.cancel());

    return SharedTreeService.watchSharedRelatives(groupId);
  },
);
