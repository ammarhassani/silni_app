import 'package:hive/hive.dart';
import '../../../shared/models/offline_operation.dart';
import '../cache_config.dart';

/// Hive adapter for OperationType enum.
///
/// Phase 9.X.D.B Tier 2: the other enum adapters (RelationshipType, Gender,
/// AvatarType, InteractionType, ReminderFrequency) were used only by the
/// read-cache model adapters that have been removed. OperationType stays
/// because OfflineOperation (the durability layer) still uses it.
class OperationTypeAdapter extends TypeAdapter<OperationType> {
  @override
  final int typeId = CacheConfig.operationTypeTypeId;

  @override
  OperationType read(BinaryReader reader) {
    final index = reader.readInt();
    return OperationType.values[index];
  }

  @override
  void write(BinaryWriter writer, OperationType obj) {
    writer.writeInt(obj.index);
  }
}
