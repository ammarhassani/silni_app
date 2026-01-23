import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../models/notification_history_model.dart';

/// Provider for the NotificationHistory service
final notificationHistoryServiceProvider = Provider<NotificationHistoryService>((
  ref,
) {
  return NotificationHistoryService();
});

/// Provider for notification history stream
final notificationHistoryStreamProvider =
    StreamProvider.family<List<NotificationHistoryItem>, String>((ref, userId) {
  final service = ref.watch(notificationHistoryServiceProvider);
  return service.getNotificationsStream(userId);
});

/// Provider for unread count stream
final unreadNotificationCountProvider =
    StreamProvider.family<int, String>((ref, userId) {
  final service = ref.watch(notificationHistoryServiceProvider);
  return service.getUnreadCountStream(userId);
});

class NotificationHistoryService {
  // Use lazy initialization to avoid accessing Supabase before it's initialized
  SupabaseClient get _supabase => SupabaseConfig.client;
  static const String _table = 'notification_history';

  /// Get all notifications for a user as a stream
  Stream<List<NotificationHistoryItem>> getNotificationsStream(String userId) {
    // Use .eq() to filter at database level for proper realtime updates
    return _supabase
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('sent_at', ascending: false)
        .map((data) {
      return data
          .map((json) => NotificationHistoryItem.fromJson(json))
          .toList();
    });
  }

  /// Get unread count stream for badge display
  Stream<int> getUnreadCountStream(String userId) {
    return getNotificationsStream(userId).map((notifications) {
      return notifications.where((n) => !n.isRead).length;
    });
  }

  /// Get all notifications (non-stream)
  Future<List<NotificationHistoryItem>> getNotifications(String userId) async {
    try {
      final response = await _supabase
          .from(_table)
          .select()
          .eq('user_id', userId)
          .order('sent_at', ascending: false);

      return (response as List)
          .map((json) => NotificationHistoryItem.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from(_table)
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      rethrow;
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from(_table)
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase.from(_table).delete().eq('id', notificationId);
    } catch (e) {
      rethrow;
    }
  }

  /// Get unread count (non-stream)
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _supabase
          .from(_table)
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }
}
