import 'package:flutter_test/flutter_test.dart';

import 'package:silni_app/shared/models/notification_history_model.dart';

void main() {
  group('NotificationHistoryService Logic Tests', () {
    // =====================================================
    // NOTIFICATION HISTORY MODEL TESTS
    // =====================================================
    group('NotificationHistoryItem model', () {
      test('should create from JSON correctly', () {
        final json = {
          'id': 'notif-1',
          'user_id': 'user-1',
          'notification_type': 'reminder',
          'title': 'تذكير بصلة الرحم',
          'body': 'حان وقت التواصل مع والدك',
          'data': {'relative_id': 'rel-1'},
          'sent_at': '2024-06-15T10:00:00.000Z',
          'status': 'sent',
          'is_read': false,
        };

        final item = NotificationHistoryItem.fromJson(json);

        expect(item.id, equals('notif-1'));
        expect(item.userId, equals('user-1'));
        expect(item.notificationType, equals('reminder'));
        expect(item.title, equals('تذكير بصلة الرحم'));
        expect(item.body, equals('حان وقت التواصل مع والدك'));
        expect(item.data!['relative_id'], equals('rel-1'));
        expect(item.status, equals('sent'));
        expect(item.isRead, isFalse);
      });

      test('should convert to JSON correctly', () {
        final item = NotificationHistoryItem(
          id: 'notif-1',
          userId: 'user-1',
          notificationType: 'reminder',
          title: 'Test Title',
          body: 'Test Body',
          sentAt: DateTime(2024, 6, 15, 10, 0),
          status: 'sent',
          isRead: true,
        );

        final json = item.toJson();

        expect(json['id'], equals('notif-1'));
        expect(json['user_id'], equals('user-1'));
        expect(json['notification_type'], equals('reminder'));
        expect(json['title'], equals('Test Title'));
        expect(json['body'], equals('Test Body'));
        expect(json['status'], equals('sent'));
        expect(json['is_read'], isTrue);
      });

      test('should handle null optional fields in JSON', () {
        final json = {
          'id': 'notif-1',
          'user_id': 'user-1',
          'sent_at': '2024-06-15T10:00:00.000Z',
        };

        final item = NotificationHistoryItem.fromJson(json);

        expect(item.notificationType, equals('reminder')); // Default
        expect(item.title, equals('')); // Default
        expect(item.body, equals('')); // Default
        expect(item.data, isNull);
        expect(item.status, equals('sent')); // Default
        expect(item.isRead, isFalse); // Default
      });

      test('should copyWith correctly', () {
        final original = NotificationHistoryItem(
          id: 'notif-1',
          userId: 'user-1',
          notificationType: 'reminder',
          title: 'Original',
          body: 'Body',
          sentAt: DateTime(2024, 6, 15),
          status: 'sent',
          isRead: false,
        );

        final copy = original.copyWith(
          title: 'Updated',
          isRead: true,
        );

        expect(copy.title, equals('Updated'));
        expect(copy.isRead, isTrue);
        expect(copy.id, equals(original.id));
        expect(copy.userId, equals(original.userId));
        expect(copy.body, equals(original.body));
      });

      test('should have correct equality', () {
        final item1 = NotificationHistoryItem(
          id: 'notif-1',
          userId: 'user-1',
          notificationType: 'reminder',
          title: 'Title',
          body: 'Body',
          sentAt: DateTime(2024, 6, 15),
          status: 'sent',
        );

        final item2 = NotificationHistoryItem(
          id: 'notif-1', // Same ID
          userId: 'user-2', // Different user
          notificationType: 'achievement', // Different type
          title: 'Different',
          body: 'Different',
          sentAt: DateTime(2024, 7, 1),
          status: 'delivered',
        );

        // Equality is based on ID only
        expect(item1, equals(item2));
        expect(item1.hashCode, equals(item2.hashCode));
      });

      test('should have correct inequality', () {
        final item1 = NotificationHistoryItem(
          id: 'notif-1',
          userId: 'user-1',
          notificationType: 'reminder',
          title: 'Title',
          body: 'Body',
          sentAt: DateTime(2024, 6, 15),
          status: 'sent',
        );

        final item2 = NotificationHistoryItem(
          id: 'notif-2', // Different ID
          userId: 'user-1',
          notificationType: 'reminder',
          title: 'Title',
          body: 'Body',
          sentAt: DateTime(2024, 6, 15),
          status: 'sent',
        );

        expect(item1, isNot(equals(item2)));
      });
    });

    // =====================================================
    // TYPE LABEL TESTS
    // =====================================================
    group('notification type labels', () {
      test('reminder type should return Arabic label', () {
        final item = _createTestNotification(notificationType: 'reminder');
        expect(item.typeLabel, equals('تذكير'));
      });

      test('achievement type should return Arabic label', () {
        final item = _createTestNotification(notificationType: 'achievement');
        expect(item.typeLabel, equals('إنجاز'));
      });

      test('announcement type should return Arabic label', () {
        final item = _createTestNotification(notificationType: 'announcement');
        expect(item.typeLabel, equals('إعلان'));
      });

      test('streak type should return Arabic label', () {
        final item = _createTestNotification(notificationType: 'streak');
        expect(item.typeLabel, equals('نقاط'));
      });

      test('unknown type should return default Arabic label', () {
        final item = _createTestNotification(notificationType: 'unknown');
        expect(item.typeLabel, equals('إشعار'));
      });
    });

    // =====================================================
    // TYPE ICON TESTS
    // =====================================================
    group('notification type icons', () {
      test('reminder type should return bell icon', () {
        final item = _createTestNotification(notificationType: 'reminder');
        expect(item.typeIcon, equals('🔔'));
      });

      test('achievement type should return trophy icon', () {
        final item = _createTestNotification(notificationType: 'achievement');
        expect(item.typeIcon, equals('🏆'));
      });

      test('announcement type should return megaphone icon', () {
        final item = _createTestNotification(notificationType: 'announcement');
        expect(item.typeIcon, equals('📢'));
      });

      test('streak type should return fire icon', () {
        final item = _createTestNotification(notificationType: 'streak');
        expect(item.typeIcon, equals('🔥'));
      });

      test('unknown type should return mailbox icon', () {
        final item = _createTestNotification(notificationType: 'unknown');
        expect(item.typeIcon, equals('📬'));
      });
    });

    // =====================================================
    // UNREAD COUNT LOGIC TESTS
    // =====================================================
    group('unread count logic', () {
      int calculateUnreadCount(List<NotificationHistoryItem> notifications) {
        return notifications.where((n) => !n.isRead).length;
      }

      test('should return 0 for empty list', () {
        expect(calculateUnreadCount([]), equals(0));
      });

      test('should return 0 when all are read', () {
        final notifications = [
          _createTestNotification(id: 'n1', isRead: true),
          _createTestNotification(id: 'n2', isRead: true),
          _createTestNotification(id: 'n3', isRead: true),
        ];

        expect(calculateUnreadCount(notifications), equals(0));
      });

      test('should count unread correctly', () {
        final notifications = [
          _createTestNotification(id: 'n1', isRead: false),
          _createTestNotification(id: 'n2', isRead: true),
          _createTestNotification(id: 'n3', isRead: false),
          _createTestNotification(id: 'n4', isRead: true),
        ];

        expect(calculateUnreadCount(notifications), equals(2));
      });

      test('should return total when none are read', () {
        final notifications = [
          _createTestNotification(id: 'n1', isRead: false),
          _createTestNotification(id: 'n2', isRead: false),
          _createTestNotification(id: 'n3', isRead: false),
        ];

        expect(calculateUnreadCount(notifications), equals(3));
      });
    });

    // =====================================================
    // FILTERING TESTS
    // =====================================================
    group('notification filtering', () {
      test('should filter by user ID', () {
        final allNotifications = [
          _createTestNotification(id: 'n1', userId: 'user-1'),
          _createTestNotification(id: 'n2', userId: 'user-2'),
          _createTestNotification(id: 'n3', userId: 'user-1'),
        ];

        final filtered = allNotifications
            .where((n) => n.userId == 'user-1')
            .toList();

        expect(filtered.length, equals(2));
      });

      test('should filter by notification type', () {
        final allNotifications = [
          _createTestNotification(id: 'n1', notificationType: 'reminder'),
          _createTestNotification(id: 'n2', notificationType: 'achievement'),
          _createTestNotification(id: 'n3', notificationType: 'reminder'),
        ];

        final reminders = allNotifications
            .where((n) => n.notificationType == 'reminder')
            .toList();

        expect(reminders.length, equals(2));
      });

      test('should filter by read status', () {
        final allNotifications = [
          _createTestNotification(id: 'n1', isRead: false),
          _createTestNotification(id: 'n2', isRead: true),
          _createTestNotification(id: 'n3', isRead: false),
        ];

        final unread = allNotifications
            .where((n) => !n.isRead)
            .toList();

        expect(unread.length, equals(2));
      });
    });

    // =====================================================
    // SORTING TESTS
    // =====================================================
    group('notification sorting', () {
      test('should sort by sent_at descending', () {
        final notifications = [
          _createTestNotification(id: 'n1', sentAt: DateTime(2024, 1, 1)),
          _createTestNotification(id: 'n2', sentAt: DateTime(2024, 6, 15)),
          _createTestNotification(id: 'n3', sentAt: DateTime(2024, 3, 10)),
        ];

        notifications.sort((a, b) => b.sentAt.compareTo(a.sentAt));

        expect(notifications[0].id, equals('n2')); // June
        expect(notifications[1].id, equals('n3')); // March
        expect(notifications[2].id, equals('n1')); // January
      });

      test('should handle same timestamp', () {
        final sameTime = DateTime(2024, 6, 15, 10, 0);
        final notifications = [
          _createTestNotification(id: 'n1', sentAt: sameTime),
          _createTestNotification(id: 'n2', sentAt: sameTime),
        ];

        notifications.sort((a, b) => b.sentAt.compareTo(a.sentAt));
        expect(notifications.length, equals(2));
      });
    });

    // =====================================================
    // STATUS TESTS
    // =====================================================
    group('notification status', () {
      test('should recognize sent status', () {
        final item = _createTestNotification(status: 'sent');
        expect(item.status, equals('sent'));
      });

      test('should recognize delivered status', () {
        final item = _createTestNotification(status: 'delivered');
        expect(item.status, equals('delivered'));
      });

      test('should recognize failed status', () {
        final item = _createTestNotification(status: 'failed');
        expect(item.status, equals('failed'));
      });

      test('should have valid statuses', () {
        const validStatuses = ['sent', 'delivered', 'failed', 'read'];
        for (final status in validStatuses) {
          final item = _createTestNotification(status: status);
          expect(item.status, equals(status));
        }
      });
    });

    // =====================================================
    // DATA PAYLOAD TESTS
    // =====================================================
    group('notification data payload', () {
      test('should store relative_id in data', () {
        final item = NotificationHistoryItem(
          id: 'n1',
          userId: 'user-1',
          notificationType: 'reminder',
          title: 'Title',
          body: 'Body',
          data: {'relative_id': 'rel-123'},
          sentAt: DateTime.now(),
          status: 'sent',
        );

        expect(item.data!['relative_id'], equals('rel-123'));
      });

      test('should store schedule_id in data', () {
        final item = NotificationHistoryItem(
          id: 'n1',
          userId: 'user-1',
          notificationType: 'reminder',
          title: 'Title',
          body: 'Body',
          data: {'schedule_id': 'sched-456'},
          sentAt: DateTime.now(),
          status: 'sent',
        );

        expect(item.data!['schedule_id'], equals('sched-456'));
      });

      test('should store multiple data fields', () {
        final item = NotificationHistoryItem(
          id: 'n1',
          userId: 'user-1',
          notificationType: 'reminder',
          title: 'Title',
          body: 'Body',
          data: {
            'relative_id': 'rel-123',
            'schedule_id': 'sched-456',
            'frequency': 'daily',
          },
          sentAt: DateTime.now(),
          status: 'sent',
        );

        expect(item.data!.length, equals(3));
        expect(item.data!['frequency'], equals('daily'));
      });

      test('should handle null data', () {
        final item = _createTestNotification(data: null);
        expect(item.data, isNull);
      });
    });

    // =====================================================
    // MARK AS READ LOGIC TESTS
    // =====================================================
    group('mark as read logic', () {
      test('marking as read should change isRead to true', () {
        final item = _createTestNotification(isRead: false);
        final updated = item.copyWith(isRead: true);

        expect(item.isRead, isFalse);
        expect(updated.isRead, isTrue);
      });

      test('mark all as read should update all unread', () {
        var notifications = [
          _createTestNotification(id: 'n1', isRead: false),
          _createTestNotification(id: 'n2', isRead: true),
          _createTestNotification(id: 'n3', isRead: false),
        ];

        // Simulate marking all as read
        notifications = notifications.map((n) {
          if (!n.isRead) {
            return n.copyWith(isRead: true);
          }
          return n;
        }).toList();

        expect(notifications.every((n) => n.isRead), isTrue);
      });
    });

    // =====================================================
    // DATE FORMATTING TESTS
    // =====================================================
    group('date formatting', () {
      test('should parse ISO date string', () {
        final json = {
          'id': 'n1',
          'user_id': 'user-1',
          'sent_at': '2024-06-15T10:30:00.000Z',
        };

        final item = NotificationHistoryItem.fromJson(json);

        expect(item.sentAt.year, equals(2024));
        expect(item.sentAt.month, equals(6));
        expect(item.sentAt.day, equals(15));
      });

      test('should convert date to ISO string', () {
        final item = _createTestNotification(
          sentAt: DateTime(2024, 6, 15, 10, 30),
        );

        final json = item.toJson();
        expect(json['sent_at'], contains('2024-06-15'));
      });
    });

    // =====================================================
    // UI HELPER TESTS
    // =====================================================
    group('UI helpers', () {
      test('time ago calculation', () {
        String getTimeAgo(DateTime sentAt) {
          final now = DateTime.now();
          final diff = now.difference(sentAt);

          if (diff.inMinutes < 1) return 'الآن';
          if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
          if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
          if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
          return 'منذ أكثر من أسبوع';
        }

        final now = DateTime.now();

        expect(getTimeAgo(now), equals('الآن'));
        expect(
          getTimeAgo(now.subtract(const Duration(minutes: 5))),
          equals('منذ 5 دقيقة'),
        );
        expect(
          getTimeAgo(now.subtract(const Duration(hours: 3))),
          equals('منذ 3 ساعة'),
        );
        expect(
          getTimeAgo(now.subtract(const Duration(days: 2))),
          equals('منذ 2 يوم'),
        );
        expect(
          getTimeAgo(now.subtract(const Duration(days: 10))),
          equals('منذ أكثر من أسبوع'),
        );
      });

      test('badge count display', () {
        String formatBadgeCount(int count) {
          if (count <= 0) return '';
          if (count > 99) return '99+';
          return count.toString();
        }

        expect(formatBadgeCount(0), equals(''));
        expect(formatBadgeCount(5), equals('5'));
        expect(formatBadgeCount(99), equals('99'));
        expect(formatBadgeCount(100), equals('99+'));
        expect(formatBadgeCount(500), equals('99+'));
      });
    });

    // =====================================================
    // EDGE CASES
    // =====================================================
    group('edge cases', () {
      test('should handle empty title and body', () {
        final item = _createTestNotification(
          title: '',
          body: '',
        );

        expect(item.title, isEmpty);
        expect(item.body, isEmpty);
      });

      test('should handle very long title', () {
        final longTitle = 'أ' * 500;
        final item = _createTestNotification(title: longTitle);
        expect(item.title.length, equals(500));
      });

      test('should handle special characters in body', () {
        final item = _createTestNotification(
          body: 'تذكير: "صلة الرحم" - واجب! 🕌',
        );
        expect(item.body.contains('🕌'), isTrue);
        expect(item.body.contains('"'), isTrue);
      });

      test('should handle future dates', () {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final item = _createTestNotification(sentAt: futureDate);
        expect(item.sentAt.isAfter(DateTime.now()), isTrue);
      });

      test('should handle very old dates', () {
        final oldDate = DateTime(2020, 1, 1);
        final item = _createTestNotification(sentAt: oldDate);
        expect(item.sentAt.year, equals(2020));
      });
    });

    // =====================================================
    // BATCH OPERATIONS TESTS
    // =====================================================
    group('batch operations', () {
      test('should handle marking multiple as read', () {
        final ids = ['n1', 'n2', 'n3'];
        var notifications = ids
            .map((id) => _createTestNotification(id: id, isRead: false))
            .toList();

        // Simulate batch mark as read
        final idsToMark = {'n1', 'n3'};
        notifications = notifications.map((n) {
          if (idsToMark.contains(n.id)) {
            return n.copyWith(isRead: true);
          }
          return n;
        }).toList();

        expect(notifications[0].isRead, isTrue); // n1
        expect(notifications[1].isRead, isFalse); // n2
        expect(notifications[2].isRead, isTrue); // n3
      });

      test('should handle deleting from list', () {
        var notifications = [
          _createTestNotification(id: 'n1'),
          _createTestNotification(id: 'n2'),
          _createTestNotification(id: 'n3'),
        ];

        notifications = notifications
            .where((n) => n.id != 'n2')
            .toList();

        expect(notifications.length, equals(2));
        expect(notifications.any((n) => n.id == 'n2'), isFalse);
      });
    });
  });
}

/// Helper to create test notifications
NotificationHistoryItem _createTestNotification({
  String id = 'test-notif-id',
  String userId = 'test-user-id',
  String notificationType = 'reminder',
  String title = 'Test Title',
  String body = 'Test Body',
  Map<String, dynamic>? data,
  DateTime? sentAt,
  String status = 'sent',
  bool isRead = false,
}) {
  return NotificationHistoryItem(
    id: id,
    userId: userId,
    notificationType: notificationType,
    title: title,
    body: body,
    data: data,
    sentAt: sentAt ?? DateTime.now(),
    status: status,
    isRead: isRead,
  );
}
