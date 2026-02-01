import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/features/family_groups/models/family_group_model.dart';
import 'package:silni_app/features/family_groups/services/family_group_service.dart';

/// Unit tests for FamilyGroup models and FamilyGroupService utilities.
///
/// Tests cover:
/// 1. FamilyGroup fromJson/toJson roundtrip
/// 2. FamilyGroup copyWith
/// 3. FamilyGroupMember fromJson/toJson roundtrip
/// 4. FamilyGroupMember isAdmin property
/// 5. FamilyGroupService.generateInviteLink format
void main() {
  // ---------------------------------------------------------------------------
  // Shared test data
  // ---------------------------------------------------------------------------
  final now = DateTime.utc(2026, 2, 1, 12, 0, 0);

  final sampleGroupJson = {
    'id': 'group-123',
    'name': 'عائلة الأحمد',
    'created_by': 'user-abc',
    'invite_code': 'a1b2c3d4e5f6',
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
  };

  final sampleMemberAdminJson = {
    'id': 'member-1',
    'group_id': 'group-123',
    'user_id': 'user-abc',
    'relative_id_in_tree': 'relative-xyz',
    'role': 'admin',
    'joined_at': now.toIso8601String(),
  };

  final sampleMemberJson = {
    'id': 'member-2',
    'group_id': 'group-123',
    'user_id': 'user-def',
    'role': 'member',
    'joined_at': now.toIso8601String(),
  };

  // ---------------------------------------------------------------------------
  // FamilyGroup tests
  // ---------------------------------------------------------------------------
  group('FamilyGroup', () {
    test('fromJson creates correct instance', () {
      final group = FamilyGroup.fromJson(sampleGroupJson);

      expect(group.id, 'group-123');
      expect(group.name, 'عائلة الأحمد');
      expect(group.createdBy, 'user-abc');
      expect(group.inviteCode, 'a1b2c3d4e5f6');
      expect(group.createdAt, now);
      expect(group.updatedAt, now);
    });

    test('fromJson handles null updatedAt', () {
      final json = Map<String, dynamic>.from(sampleGroupJson);
      json.remove('updated_at');

      final group = FamilyGroup.fromJson(json);
      expect(group.updatedAt, isNull);
    });

    test('toJson produces correct map', () {
      final group = FamilyGroup.fromJson(sampleGroupJson);
      final json = group.toJson();

      expect(json['id'], 'group-123');
      expect(json['name'], 'عائلة الأحمد');
      expect(json['created_by'], 'user-abc');
      expect(json['invite_code'], 'a1b2c3d4e5f6');
      expect(json['created_at'], isNotNull);
      expect(json['updated_at'], isNotNull);
    });

    test('toJson omits updatedAt when null', () {
      final group = FamilyGroup(
        id: 'g1',
        name: 'Test',
        createdBy: 'u1',
        inviteCode: 'abc123',
        createdAt: now,
        updatedAt: null,
      );

      final json = group.toJson();
      expect(json.containsKey('updated_at'), isFalse);
    });

    test('fromJson/toJson roundtrip preserves data', () {
      final original = FamilyGroup.fromJson(sampleGroupJson);
      final roundtripped = FamilyGroup.fromJson(original.toJson());

      expect(roundtripped.id, original.id);
      expect(roundtripped.name, original.name);
      expect(roundtripped.createdBy, original.createdBy);
      expect(roundtripped.inviteCode, original.inviteCode);
    });

    test('copyWith creates modified copy', () {
      final group = FamilyGroup.fromJson(sampleGroupJson);
      final modified = group.copyWith(name: 'عائلة محمد');

      expect(modified.name, 'عائلة محمد');
      expect(modified.id, group.id);
      expect(modified.createdBy, group.createdBy);
      expect(modified.inviteCode, group.inviteCode);
    });

    test('copyWith with no changes returns equivalent object', () {
      final group = FamilyGroup.fromJson(sampleGroupJson);
      final copy = group.copyWith();

      expect(copy.id, group.id);
      expect(copy.name, group.name);
      expect(copy == group, isTrue);
    });

    test('equality is based on id', () {
      final group1 = FamilyGroup.fromJson(sampleGroupJson);
      final group2 = FamilyGroup.fromJson(sampleGroupJson);

      expect(group1, equals(group2));
      expect(group1.hashCode, equals(group2.hashCode));
    });

    test('different ids are not equal', () {
      final json2 = Map<String, dynamic>.from(sampleGroupJson);
      json2['id'] = 'different-id';

      final group1 = FamilyGroup.fromJson(sampleGroupJson);
      final group2 = FamilyGroup.fromJson(json2);

      expect(group1, isNot(equals(group2)));
    });

    test('toString returns readable representation', () {
      final group = FamilyGroup.fromJson(sampleGroupJson);
      final str = group.toString();

      expect(str, contains('group-123'));
      expect(str, contains('عائلة الأحمد'));
      expect(str, contains('a1b2c3d4e5f6'));
    });
  });

  // ---------------------------------------------------------------------------
  // FamilyGroupMember tests
  // ---------------------------------------------------------------------------
  group('FamilyGroupMember', () {
    test('fromJson creates correct admin instance', () {
      final member = FamilyGroupMember.fromJson(sampleMemberAdminJson);

      expect(member.id, 'member-1');
      expect(member.groupId, 'group-123');
      expect(member.userId, 'user-abc');
      expect(member.relativeIdInTree, 'relative-xyz');
      expect(member.role, 'admin');
      expect(member.joinedAt, now);
    });

    test('fromJson creates correct member instance', () {
      final member = FamilyGroupMember.fromJson(sampleMemberJson);

      expect(member.id, 'member-2');
      expect(member.userId, 'user-def');
      expect(member.relativeIdInTree, isNull);
      expect(member.role, 'member');
    });

    test('fromJson defaults role to member when null', () {
      final json = Map<String, dynamic>.from(sampleMemberJson);
      json.remove('role');

      final member = FamilyGroupMember.fromJson(json);
      expect(member.role, 'member');
    });

    test('isAdmin returns true for admin role', () {
      final member = FamilyGroupMember.fromJson(sampleMemberAdminJson);
      expect(member.isAdmin, isTrue);
    });

    test('isAdmin returns false for member role', () {
      final member = FamilyGroupMember.fromJson(sampleMemberJson);
      expect(member.isAdmin, isFalse);
    });

    test('toJson produces correct map', () {
      final member = FamilyGroupMember.fromJson(sampleMemberAdminJson);
      final json = member.toJson();

      expect(json['id'], 'member-1');
      expect(json['group_id'], 'group-123');
      expect(json['user_id'], 'user-abc');
      expect(json['relative_id_in_tree'], 'relative-xyz');
      expect(json['role'], 'admin');
      expect(json['joined_at'], isNotNull);
    });

    test('toJson omits relativeIdInTree when null', () {
      final member = FamilyGroupMember.fromJson(sampleMemberJson);
      final json = member.toJson();

      expect(json.containsKey('relative_id_in_tree'), isFalse);
    });

    test('fromJson/toJson roundtrip preserves data', () {
      final original = FamilyGroupMember.fromJson(sampleMemberAdminJson);
      final roundtripped = FamilyGroupMember.fromJson(original.toJson());

      expect(roundtripped.id, original.id);
      expect(roundtripped.groupId, original.groupId);
      expect(roundtripped.userId, original.userId);
      expect(roundtripped.relativeIdInTree, original.relativeIdInTree);
      expect(roundtripped.role, original.role);
    });

    test('equality is based on id', () {
      final member1 = FamilyGroupMember.fromJson(sampleMemberAdminJson);
      final member2 = FamilyGroupMember.fromJson(sampleMemberAdminJson);

      expect(member1, equals(member2));
      expect(member1.hashCode, equals(member2.hashCode));
    });

    test('toString returns readable representation', () {
      final member = FamilyGroupMember.fromJson(sampleMemberAdminJson);
      final str = member.toString();

      expect(str, contains('member-1'));
      expect(str, contains('group-123'));
      expect(str, contains('admin'));
    });
  });

  // ---------------------------------------------------------------------------
  // FamilyGroupService static utility tests
  // ---------------------------------------------------------------------------
  group('FamilyGroupService.generateInviteLink', () {
    test('returns correct URL format', () {
      final link = FamilyGroupService.generateInviteLink('abc123def456');
      expect(link, 'https://silni.app/join/abc123def456');
    });

    test('handles empty invite code', () {
      final link = FamilyGroupService.generateInviteLink('');
      expect(link, 'https://silni.app/join/');
    });

    test('handles invite code with special characters', () {
      final link = FamilyGroupService.generateInviteLink('a1b2c3');
      expect(link, startsWith('https://silni.app/join/'));
      expect(link, endsWith('a1b2c3'));
    });

    test('different codes produce different links', () {
      final link1 = FamilyGroupService.generateInviteLink('code1');
      final link2 = FamilyGroupService.generateInviteLink('code2');

      expect(link1, isNot(equals(link2)));
    });
  });
}
