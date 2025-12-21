import 'package:hive/hive.dart';
import '../../../shared/models/sync_metadata.dart';
import '../cache_config.dart';

/// Hive adapter for SyncMetadata model.
class SyncMetadataAdapter extends TypeAdapter<SyncMetadata> {
  @override
  final int typeId = CacheConfig.syncMetadataTypeId;

  @override
  SyncMetadata read(BinaryReader reader) {
    final key = reader.readString();
    final lastSyncMillis = reader.readInt();
    final itemCount = reader.readInt();
    final hasError = reader.readBool();
    final lastError = hasError ? reader.readString() : null;

    return SyncMetadata(
      key: key,
      lastSync: DateTime.fromMillisecondsSinceEpoch(lastSyncMillis),
      itemCount: itemCount,
      lastError: lastError,
    );
  }

  @override
  void write(BinaryWriter writer, SyncMetadata obj) {
    writer.writeString(obj.key);
    writer.writeInt(obj.lastSync.millisecondsSinceEpoch);
    writer.writeInt(obj.itemCount);
    writer.writeBool(obj.lastError != null);
    if (obj.lastError != null) {
      writer.writeString(obj.lastError!);
    }
  }
}
