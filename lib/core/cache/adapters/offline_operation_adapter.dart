import 'package:hive/hive.dart';
import '../../../shared/models/offline_operation.dart';
import '../cache_config.dart';

/// Hive adapter for OfflineOperation model.
class OfflineOperationAdapter extends TypeAdapter<OfflineOperation> {
  @override
  final int typeId = CacheConfig.offlineOperationTypeId;

  @override
  OfflineOperation read(BinaryReader reader) {
    final id = reader.readInt();
    final typeIndex = reader.readInt();
    final entityType = reader.readString();
    final entityId = reader.readString();
    final data = Map<String, dynamic>.from(reader.readMap());
    final createdAtMillis = reader.readInt();
    final retryCount = reader.readInt();
    final hasError = reader.readBool();
    final lastError = hasError ? reader.readString() : null;
    final isDeadLetter = reader.readBool();

    return OfflineOperation(
      id: id,
      type: OperationType.values[typeIndex],
      entityType: entityType,
      entityId: entityId,
      data: data,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
      retryCount: retryCount,
      lastError: lastError,
      isDeadLetter: isDeadLetter,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineOperation obj) {
    writer.writeInt(obj.id);
    writer.writeInt(obj.type.index);
    writer.writeString(obj.entityType);
    writer.writeString(obj.entityId);
    writer.writeMap(obj.data);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.retryCount);
    writer.writeBool(obj.lastError != null);
    if (obj.lastError != null) {
      writer.writeString(obj.lastError!);
    }
    writer.writeBool(obj.isDeadLetter);
  }
}
