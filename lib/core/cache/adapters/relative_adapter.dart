import 'package:hive/hive.dart';
import '../../../shared/models/relative_model.dart';
import '../cache_config.dart';

/// Hive adapter for Relative model.
/// Uses JSON serialization via existing toJson/fromJson methods.
class RelativeAdapter extends TypeAdapter<Relative> {
  @override
  final int typeId = CacheConfig.relativeTypeId;

  @override
  Relative read(BinaryReader reader) {
    final json = Map<String, dynamic>.from(reader.readMap());
    return Relative.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, Relative obj) {
    // Include all fields for local cache (including id and timestamps)
    final json = obj.toJson();
    json['id'] = obj.id;
    json['created_at'] = obj.createdAt.toUtc().toIso8601String();
    if (obj.updatedAt != null) {
      json['updated_at'] = obj.updatedAt!.toUtc().toIso8601String();
    }
    writer.writeMap(json);
  }
}
