import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/connectivity_service.dart';

/// Provider for connectivity service singleton
/// Uses the global singleton that's initialized in main.dart
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  // Use the global singleton instead of creating a new instance
  // This ensures we don't double-initialize connectivity
  return connectivityService;
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

  return statusAsync.when(
    data: (status) => status == ConnectivityStatus.online,
    loading: () => true, // Assume online during initial check
    error: (e, st) => false, // Assume offline on error - safer default
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
