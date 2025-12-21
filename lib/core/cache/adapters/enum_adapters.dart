import 'package:hive/hive.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/models/interaction_model.dart';
import '../../../shared/models/reminder_schedule_model.dart';
import '../../../shared/models/offline_operation.dart';
import '../cache_config.dart';

/// Hive adapter for RelationshipType enum.
class RelationshipTypeAdapter extends TypeAdapter<RelationshipType> {
  @override
  final int typeId = CacheConfig.relationshipTypeTypeId;

  @override
  RelationshipType read(BinaryReader reader) {
    final value = reader.readString();
    return RelationshipType.fromString(value);
  }

  @override
  void write(BinaryWriter writer, RelationshipType obj) {
    writer.writeString(obj.value);
  }
}

/// Hive adapter for Gender enum.
class GenderAdapter extends TypeAdapter<Gender> {
  @override
  final int typeId = CacheConfig.genderTypeId;

  @override
  Gender read(BinaryReader reader) {
    final value = reader.readString();
    return Gender.fromString(value) ?? Gender.male;
  }

  @override
  void write(BinaryWriter writer, Gender obj) {
    writer.writeString(obj.value);
  }
}

/// Hive adapter for AvatarType enum.
class AvatarTypeAdapter extends TypeAdapter<AvatarType> {
  @override
  final int typeId = CacheConfig.avatarTypeTypeId;

  @override
  AvatarType read(BinaryReader reader) {
    final value = reader.readString();
    return AvatarType.fromString(value);
  }

  @override
  void write(BinaryWriter writer, AvatarType obj) {
    writer.writeString(obj.value);
  }
}

/// Hive adapter for InteractionType enum.
class InteractionTypeAdapter extends TypeAdapter<InteractionType> {
  @override
  final int typeId = CacheConfig.interactionTypeTypeId;

  @override
  InteractionType read(BinaryReader reader) {
    final value = reader.readString();
    return InteractionType.fromString(value);
  }

  @override
  void write(BinaryWriter writer, InteractionType obj) {
    writer.writeString(obj.value);
  }
}

/// Hive adapter for ReminderFrequency enum.
class ReminderFrequencyAdapter extends TypeAdapter<ReminderFrequency> {
  @override
  final int typeId = CacheConfig.reminderFrequencyTypeId;

  @override
  ReminderFrequency read(BinaryReader reader) {
    final value = reader.readString();
    return ReminderFrequency.fromString(value);
  }

  @override
  void write(BinaryWriter writer, ReminderFrequency obj) {
    writer.writeString(obj.value);
  }
}

/// Hive adapter for OperationType enum.
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
