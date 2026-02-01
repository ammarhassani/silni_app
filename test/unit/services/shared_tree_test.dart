import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/shared/models/relative_model.dart';

void main() {
  group('Relative model — shared tree fields', () {
    test('fromJson parses familyGroupId and addedBy', () {
      final json = _baseJson()
        ..['family_group_id'] = 'group-123'
        ..['added_by'] = 'user-456';

      final relative = Relative.fromJson(json);

      expect(relative.familyGroupId, 'group-123');
      expect(relative.addedBy, 'user-456');
    });

    test('fromJson defaults familyGroupId and addedBy to null', () {
      final relative = Relative.fromJson(_baseJson());

      expect(relative.familyGroupId, isNull);
      expect(relative.addedBy, isNull);
    });

    test('toJson includes familyGroupId and addedBy when set', () {
      final relative = Relative.fromJson(
        _baseJson()
          ..['family_group_id'] = 'group-abc'
          ..['added_by'] = 'user-xyz',
      );

      final json = relative.toJson();

      expect(json['family_group_id'], 'group-abc');
      expect(json['added_by'], 'user-xyz');
    });

    test('toJson omits familyGroupId and addedBy when null', () {
      final relative = Relative.fromJson(_baseJson());

      final json = relative.toJson();

      expect(json.containsKey('family_group_id'), isFalse);
      expect(json.containsKey('added_by'), isFalse);
    });

    test('copyWith updates familyGroupId', () {
      final relative = Relative.fromJson(_baseJson());
      final shared = relative.copyWith(familyGroupId: 'new-group');

      expect(shared.familyGroupId, 'new-group');
      expect(shared.fullName, relative.fullName);
    });

    test('copyWith updates addedBy', () {
      final relative = Relative.fromJson(_baseJson());
      final shared = relative.copyWith(addedBy: 'adder-id');

      expect(shared.addedBy, 'adder-id');
    });

    test('copyWith preserves existing shared fields when not overridden', () {
      final relative = Relative.fromJson(
        _baseJson()
          ..['family_group_id'] = 'group-1'
          ..['added_by'] = 'user-1',
      );
      final updated = relative.copyWith(fullName: 'Updated Name');

      expect(updated.familyGroupId, 'group-1');
      expect(updated.addedBy, 'user-1');
      expect(updated.fullName, 'Updated Name');
    });

    test('fromJson/toJson roundtrip preserves shared tree fields', () {
      final original = _baseJson()
        ..['family_group_id'] = 'group-rt'
        ..['added_by'] = 'user-rt';

      final relative = Relative.fromJson(original);
      final json = relative.toJson();

      expect(json['family_group_id'], 'group-rt');
      expect(json['added_by'], 'user-rt');
    });

    test('personal relative (null group) is distinct from shared', () {
      final personal = Relative.fromJson(_baseJson());
      final shared = Relative.fromJson(
        _baseJson()..['family_group_id'] = 'group-x',
      );

      expect(personal.familyGroupId, isNull);
      expect(shared.familyGroupId, isNotNull);
    });
  });
}

/// Minimal valid JSON for a Relative with required fields.
Map<String, dynamic> _baseJson() => {
      'id': 'rel-001',
      'user_id': 'user-001',
      'full_name': 'محمد أحمد',
      'relationship_type': 'brother',
      'gender': 'male',
      'avatar_type': 'youngMan',
      'priority': 2,
      'interaction_count': 0,
      'is_archived': false,
      'is_favorite': false,
      'created_at': '2026-01-15T10:00:00Z',
      'updated_at': '2026-01-15T10:00:00Z',
    };
