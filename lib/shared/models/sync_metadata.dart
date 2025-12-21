/// Metadata for tracking sync state of cached data.
class SyncMetadata {
  final String key;
  final DateTime lastSync;
  final int itemCount;
  final String? lastError;

  SyncMetadata({
    required this.key,
    required this.lastSync,
    this.itemCount = 0,
    this.lastError,
  });

  /// Check if the cache is stale based on threshold.
  bool isStale(Duration threshold) {
    return DateTime.now().difference(lastSync) > threshold;
  }

  /// Create a copy with updated values.
  SyncMetadata copyWith({
    String? key,
    DateTime? lastSync,
    int? itemCount,
    String? lastError,
  }) {
    return SyncMetadata(
      key: key ?? this.key,
      lastSync: lastSync ?? this.lastSync,
      itemCount: itemCount ?? this.itemCount,
      lastError: lastError ?? this.lastError,
    );
  }

  /// Convert to JSON for debugging/logging.
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'last_sync': lastSync.toIso8601String(),
      'item_count': itemCount,
      'last_error': lastError,
    };
  }

  @override
  String toString() {
    return 'SyncMetadata(key: $key, lastSync: $lastSync, '
        'itemCount: $itemCount, lastError: $lastError)';
  }
}
