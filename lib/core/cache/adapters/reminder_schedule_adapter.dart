import 'package:hive/hive.dart';
import '../../../shared/models/reminder_schedule_model.dart';
import '../cache_config.dart';

/// Hive adapter for ReminderSchedule model.
/// Uses JSON serialization via existing toJson/fromJson methods.
class ReminderScheduleAdapter extends TypeAdapter<ReminderSchedule> {
  @override
  final int typeId = CacheConfig.reminderScheduleTypeId;

  @override
  ReminderSchedule read(BinaryReader reader) {
    final json = Map<String, dynamic>.from(reader.readMap());
    return ReminderSchedule.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, ReminderSchedule obj) {
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
