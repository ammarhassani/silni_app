import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/shared/models/relative_model.dart';
import 'package:silni_app/shared/models/interaction_model.dart';
import 'package:silni_app/shared/models/reminder_schedule_model.dart';
import 'package:silni_app/core/cache/adapters/relative_adapter.dart';
import 'package:silni_app/core/cache/adapters/interaction_adapter.dart';
import 'package:silni_app/core/cache/adapters/reminder_schedule_adapter.dart';
import 'package:silni_app/core/cache/adapters/offline_operation_adapter.dart';
import 'package:silni_app/core/cache/adapters/sync_metadata_adapter.dart';
import 'package:silni_app/core/cache/adapters/enum_adapters.dart';
import 'package:silni_app/core/cache/cache_config.dart';

void main() {
  group('RelativeAdapter', () {
    late RelativeAdapter adapter;

    setUp(() {
      adapter = RelativeAdapter();
    });

    test('should have correct type ID', () {
      expect(adapter.typeId, equals(CacheConfig.relativeTypeId));
    });

    test('should serialize and deserialize relative correctly', () {
      final relative = Relative(
        id: 'test-id-123',
        userId: 'user-456',
        fullName: 'محمد أحمد',
        relationshipType: RelationshipType.father,
        gender: Gender.male,
        avatarType: AvatarType.beardedMan,
        priority: 1,
        isFavorite: true,
        isArchived: false,
        interactionCount: 5,
        createdAt: DateTime(2024, 1, 15),
        updatedAt: DateTime(2024, 6, 20),
        phoneNumber: '+966501234567',
        email: 'test@example.com',
      );

      // Use a mock writer/reader approach
      final json = relative.toJson();
      json['id'] = relative.id;
      json['created_at'] = relative.createdAt.toUtc().toIso8601String();
      json['updated_at'] = relative.updatedAt?.toUtc().toIso8601String();

      final deserialized = Relative.fromJson(json);

      expect(deserialized.id, equals(relative.id));
      expect(deserialized.userId, equals(relative.userId));
      expect(deserialized.fullName, equals(relative.fullName));
      expect(deserialized.relationshipType, equals(relative.relationshipType));
      expect(deserialized.gender, equals(relative.gender));
      expect(deserialized.avatarType, equals(relative.avatarType));
      expect(deserialized.priority, equals(relative.priority));
      expect(deserialized.isFavorite, equals(relative.isFavorite));
      expect(deserialized.phoneNumber, equals(relative.phoneNumber));
    });

    test('should handle nullable fields correctly', () {
      final relative = Relative(
        id: 'test-id',
        userId: 'user-id',
        fullName: 'Test Name',
        relationshipType: RelationshipType.other,
        createdAt: DateTime.now(),
      );

      final json = relative.toJson();
      json['id'] = relative.id;
      json['created_at'] = relative.createdAt.toUtc().toIso8601String();

      final deserialized = Relative.fromJson(json);

      expect(deserialized.gender, isNull);
      expect(deserialized.phoneNumber, isNull);
      expect(deserialized.email, isNull);
      expect(deserialized.updatedAt, isNull);
    });
  });

  group('InteractionAdapter', () {
    late InteractionAdapter adapter;

    setUp(() {
      adapter = InteractionAdapter();
    });

    test('should have correct type ID', () {
      expect(adapter.typeId, equals(CacheConfig.interactionTypeId));
    });

    test('should serialize and deserialize interaction correctly', () {
      final interaction = Interaction(
        id: 'interaction-123',
        userId: 'user-456',
        relativeId: 'relative-789',
        type: InteractionType.call,
        date: DateTime(2024, 6, 15, 14, 30),
        duration: 30,
        notes: 'مكالمة جيدة',
        mood: 'سعيد',
        rating: 5,
        createdAt: DateTime(2024, 6, 15),
      );

      final json = interaction.toJson();
      json['id'] = interaction.id;
      json['created_at'] = interaction.createdAt.toUtc().toIso8601String();

      final deserialized = Interaction.fromJson(json);

      expect(deserialized.id, equals(interaction.id));
      expect(deserialized.userId, equals(interaction.userId));
      expect(deserialized.relativeId, equals(interaction.relativeId));
      expect(deserialized.type, equals(interaction.type));
      expect(deserialized.duration, equals(interaction.duration));
      expect(deserialized.notes, equals(interaction.notes));
      expect(deserialized.rating, equals(interaction.rating));
    });
  });

  group('ReminderScheduleAdapter', () {
    late ReminderScheduleAdapter adapter;

    setUp(() {
      adapter = ReminderScheduleAdapter();
    });

    test('should have correct type ID', () {
      expect(adapter.typeId, equals(CacheConfig.reminderScheduleTypeId));
    });

    test('should serialize and deserialize schedule correctly', () {
      final schedule = ReminderSchedule(
        id: 'schedule-123',
        userId: 'user-456',
        frequency: ReminderFrequency.weekly,
        relativeIds: ['rel-1', 'rel-2', 'rel-3'],
        time: '09:00',
        isActive: true,
        customDays: [1, 3, 5], // Monday, Wednesday, Friday
        createdAt: DateTime(2024, 1, 1),
      );

      final json = schedule.toJson();
      json['id'] = schedule.id;
      json['created_at'] = schedule.createdAt.toUtc().toIso8601String();

      final deserialized = ReminderSchedule.fromJson(json);

      expect(deserialized.id, equals(schedule.id));
      expect(deserialized.userId, equals(schedule.userId));
      expect(deserialized.frequency, equals(schedule.frequency));
      expect(deserialized.relativeIds, equals(schedule.relativeIds));
      expect(deserialized.time, equals(schedule.time));
      expect(deserialized.isActive, equals(schedule.isActive));
      expect(deserialized.customDays, equals(schedule.customDays));
    });
  });

  group('OfflineOperationAdapter', () {
    late OfflineOperationAdapter adapter;

    setUp(() {
      adapter = OfflineOperationAdapter();
    });

    test('should have correct type ID', () {
      expect(adapter.typeId, equals(CacheConfig.offlineOperationTypeId));
    });
  });

  group('SyncMetadataAdapter', () {
    late SyncMetadataAdapter adapter;

    setUp(() {
      adapter = SyncMetadataAdapter();
    });

    test('should have correct type ID', () {
      expect(adapter.typeId, equals(CacheConfig.syncMetadataTypeId));
    });
  });

  group('Enum Adapters', () {
    test('RelationshipTypeAdapter should have correct type ID', () {
      final adapter = RelationshipTypeAdapter();
      expect(adapter.typeId, equals(CacheConfig.relationshipTypeTypeId));
    });

    test('GenderAdapter should have correct type ID', () {
      final adapter = GenderAdapter();
      expect(adapter.typeId, equals(CacheConfig.genderTypeId));
    });

    test('AvatarTypeAdapter should have correct type ID', () {
      final adapter = AvatarTypeAdapter();
      expect(adapter.typeId, equals(CacheConfig.avatarTypeTypeId));
    });

    test('InteractionTypeAdapter should have correct type ID', () {
      final adapter = InteractionTypeAdapter();
      expect(adapter.typeId, equals(CacheConfig.interactionTypeTypeId));
    });

    test('ReminderFrequencyAdapter should have correct type ID', () {
      final adapter = ReminderFrequencyAdapter();
      expect(adapter.typeId, equals(CacheConfig.reminderFrequencyTypeId));
    });

    test('OperationTypeAdapter should have correct type ID', () {
      final adapter = OperationTypeAdapter();
      expect(adapter.typeId, equals(CacheConfig.operationTypeTypeId));
    });
  });
}
