import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/features/family_groups/models/node_invitation_model.dart';

void main() {
  group('NodeInvitation', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'inv-1',
        'group_id': 'g-1',
        'relative_id': 'r-1',
        'phone_number': '+966512345678',
        'invited_by': 'u-1',
        'status': 'pending',
        'accepted_by': null,
        'created_at': '2026-03-08T10:00:00Z',
        'accepted_at': null,
        'cancelled_at': null,
        'group_name': 'عائلة الأحمد',
        'relative_name': 'محمود',
        'relationship_type': 'son',
        'invited_by_name': 'أحمد',
      };
      final inv = NodeInvitation.fromJson(json);
      expect(inv.id, 'inv-1');
      expect(inv.groupName, 'عائلة الأحمد');
      expect(inv.isPending, true);
      expect(inv.isAccepted, false);
    });

    test('maskedPhone masks middle digits', () {
      final inv = NodeInvitation(
        id: '1',
        groupId: '1',
        relativeId: '1',
        phoneNumber: '+966512345678',
        invitedBy: '1',
        status: 'pending',
        createdAt: DateTime.now(),
      );
      expect(inv.maskedPhone, '+966 ***** 5678');
    });

    test('maskedPhone handles short numbers', () {
      final inv = NodeInvitation(
        id: '1',
        groupId: '1',
        relativeId: '1',
        phoneNumber: '+96651',
        invitedBy: '1',
        status: 'pending',
        createdAt: DateTime.now(),
      );
      expect(inv.maskedPhone, '+96651');
    });

    test('status getters work correctly', () {
      NodeInvitation makeWithStatus(String s) => NodeInvitation(
            id: '1',
            groupId: '1',
            relativeId: '1',
            phoneNumber: '+966512345678',
            invitedBy: '1',
            status: s,
            createdAt: DateTime.now(),
          );
      expect(makeWithStatus('pending').isPending, true);
      expect(makeWithStatus('accepted').isAccepted, true);
      expect(makeWithStatus('cancelled').isCancelled, true);
    });
  });
}
