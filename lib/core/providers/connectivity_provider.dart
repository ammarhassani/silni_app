import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/connectivity_service.dart';

/// Provider for connectivity service singleton
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  service.initialize();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Stream provider for connectivity status changes
final connectivityStatusProvider =
    StreamProvider<ConnectivityStatus>((ref) async* {
  final service = ref.watch(connectivityServiceProvider);

  // Emit current status first
  yield service.currentStatus;

  // Then stream updates
  await for (final status in service.onStatusChange) {
    yield status;
  }
});

/// Provider for current online/offline state
final isOnlineProvider = Provider<bool>((ref) {
  final statusAsync = ref.watch(connectivityStatusProvider);

  return statusAsync.maybeWhen(
    data: (status) => status == ConnectivityStatus.online,
    orElse: () => true, // Assume online until proven otherwise
  );
});

/// Provider to check connectivity on demand
final connectivityCheckProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(connectivityServiceProvider);
  return service.checkConnectivity(force: true);
});

/// Notifier for manual connectivity refresh
class ConnectivityRefreshNotifier extends Notifier<AsyncValue<bool>> {
  @override
  AsyncValue<bool> build() {
    return const AsyncValue.data(true);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(connectivityServiceProvider);
      final isOnline = await service.checkConnectivity(force: true);
      state = AsyncValue.data(isOnline);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final connectivityRefreshProvider =
    NotifierProvider<ConnectivityRefreshNotifier, AsyncValue<bool>>(
  ConnectivityRefreshNotifier.new,
);
