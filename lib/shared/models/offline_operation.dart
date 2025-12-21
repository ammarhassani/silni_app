/// Types of operations that can be queued for offline sync.
enum OperationType {
  create,
  update,
  delete,
}

/// Represents a pending operation to be synced when back online.
class OfflineOperation {
  final int id;
  final OperationType type;
  final String entityType; // 'relative', 'interaction', 'schedule'
  final String entityId;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;
  final bool isDeadLetter; // true after max retries exceeded

  OfflineOperation({
    required this.id,
    required this.type,
    required this.entityType,
    required this.entityId,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
    this.isDeadLetter = false,
  });

  /// Create a copy with incremented retry count and error message.
  OfflineOperation copyWithRetry(String error) {
    return OfflineOperation(
      id: id,
      type: type,
      entityType: entityType,
      entityId: entityId,
      data: data,
      createdAt: createdAt,
      retryCount: retryCount + 1,
      lastError: error,
      isDeadLetter: isDeadLetter,
    );
  }

  /// Create a copy marked as dead letter (failed permanently).
  OfflineOperation copyAsDeadLetter() {
    return OfflineOperation(
      id: id,
      type: type,
      entityType: entityType,
      entityId: entityId,
      data: data,
      createdAt: createdAt,
      retryCount: retryCount,
      lastError: lastError,
      isDeadLetter: true,
    );
  }

  /// General copy with method.
  OfflineOperation copyWith({
    int? id,
    OperationType? type,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    int? retryCount,
    String? lastError,
    bool? isDeadLetter,
  }) {
    return OfflineOperation(
      id: id ?? this.id,
      type: type ?? this.type,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      isDeadLetter: isDeadLetter ?? this.isDeadLetter,
    );
  }

  /// Convert to JSON for debugging/logging.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'entity_type': entityType,
      'entity_id': entityId,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'retry_count': retryCount,
      'last_error': lastError,
      'is_dead_letter': isDeadLetter,
    };
  }

  @override
  String toString() {
    return 'OfflineOperation(id: $id, type: ${type.name}, '
        'entityType: $entityType, entityId: $entityId, '
        'retryCount: $retryCount, isDeadLetter: $isDeadLetter)';
  }
}
