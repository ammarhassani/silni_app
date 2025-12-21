import 'package:hive/hive.dart';
import '../../../shared/models/interaction_model.dart';
import '../cache_config.dart';

/// Hive adapter for Interaction model.
/// Uses JSON serialization via existing toJson/fromJson methods.
class InteractionAdapter extends TypeAdapter<Interaction> {
  @override
  final int typeId = CacheConfig.interactionTypeId;

  @override
  Interaction read(BinaryReader reader) {
    final json = Map<String, dynamic>.from(reader.readMap());
    return Interaction.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, Interaction obj) {
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
