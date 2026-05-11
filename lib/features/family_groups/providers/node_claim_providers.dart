import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:silni_app/core/config/supabase_config.dart';
import 'package:silni_app/features/family_groups/models/node_claim_model.dart';
import 'package:silni_app/features/family_groups/services/node_claim_service.dart';

/// Internal "tick" stream that emits an int every time a row in
/// `node_claims` changes for a given group. Driven by Supabase realtime,
/// auto-cleans up when no widgets are watching the parent provider.
///
/// Watching this from a FutureProvider gives us "re-fetch when data
/// changes server-side" with zero polling.
final _groupClaimsRealtimeTickProvider =
    StreamProvider.autoDispose.family<int, String>((ref, groupId) {
  final controller = StreamController<int>.broadcast();
  var tick = 0;
  controller.add(tick);

  final channel = SupabaseConfig.client
      .channel('node_claims:$groupId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'node_claims',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'group_id',
          value: groupId,
        ),
        callback: (payload) {
          tick++;
          debugPrint(
            '[node_claims realtime] tick=$tick group=$groupId '
            'event=${payload.eventType} new=${payload.newRecord} '
            'old=${payload.oldRecord}',
          );
          if (!controller.isClosed) controller.add(tick);
        },
      )
      .subscribe();

  ref.onDispose(() {
    debugPrint('[node_claims realtime] disposing channel for group=$groupId');
    channel.unsubscribe();
    controller.close();
  });

  return controller.stream;
});

/// Pending claims for the current user (across all groups). Drives the
/// "في انتظار تأكيد المسؤول" banner on the joiner's home/tree.
final myPendingClaimsProvider =
    FutureProvider<List<NodeClaim>>((ref) async {
  final service = ref.read(nodeClaimServiceProvider);
  return service.getMyPendingClaims();
});

/// Pending claims for a specific group (admin queue).
///
/// Auto-refreshes via [_groupClaimsRealtimeTickProvider] when any claim
/// row in this group changes (insert / update / delete). Excludes
/// snoozed-into-the-future claims (the RPC handles that).
final groupPendingClaimsProvider =
    FutureProvider.autoDispose.family<List<NodeClaim>, String>((ref, groupId) async {
  // Watch the realtime tick — every emission re-runs this provider body.
  ref.watch(_groupClaimsRealtimeTickProvider(groupId));
  final service = ref.read(nodeClaimServiceProvider);
  return service.getGroupPendingClaims(groupId);
});

/// Counter for the badge on the family-group "الدعوات" tab.
final groupPendingClaimsCountProvider =
    FutureProvider.autoDispose.family<int, String>((ref, groupId) async {
  final claims = await ref.watch(groupPendingClaimsProvider(groupId).future);
  return claims.length;
});

/// Counter for any badge on home/profile when the joiner has at least
/// one pending claim of their own.
final myPendingClaimsCountProvider = FutureProvider<int>((ref) async {
  final claims = await ref.watch(myPendingClaimsProvider.future);
  return claims.length;
});

/// Streams a single claim's row in realtime. Re-fetches via getClaimById
/// on every postgres-changes event for the claim's id. Used by
/// ClaimPendingReviewScreen so the joiner sees approval/rejection
/// without pulling-to-refresh.
final claimByIdRealtimeProvider = StreamProvider.autoDispose
    .family<NodeClaim, String>((ref, claimId) async* {
  final service = ref.watch(nodeClaimServiceProvider);

  // Initial fetch.
  yield await service.getClaimById(claimId);

  // Realtime subscription: re-fetch on any UPDATE for this row.
  final controller = StreamController<NodeClaim>();
  final channel = SupabaseConfig.client
      .channel('node_claim_$claimId')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'node_claims',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: claimId,
        ),
        callback: (_) async {
          try {
            final fresh = await service.getClaimById(claimId);
            if (!controller.isClosed) controller.add(fresh);
          } catch (_) {
            // Swallow — next event will retry.
          }
        },
      )
      .subscribe();

  ref.onDispose(() {
    debugPrint('[node_claim realtime] disposing channel for claim=$claimId');
    channel.unsubscribe();
    controller.close();
  });

  yield* controller.stream;
});
