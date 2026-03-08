/// Model representing a notification history entry
class NotificationHistoryItem {
  final String id;
  final String userId;
  final String notificationType;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final DateTime sentAt;
  final String status;
  final bool isRead;

  const NotificationHistoryItem({
    required this.id,
    required this.userId,
    required this.notificationType,
    required this.title,
    required this.body,
    this.data,
    required this.sentAt,
    required this.status,
    this.isRead = false,
  });

  factory NotificationHistoryItem.fromJson(Map<String, dynamic> json) {
    return NotificationHistoryItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      notificationType: json['notification_type'] as String? ?? 'reminder',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>?,
      sentAt: DateTime.parse(json['sent_at'] as String),
      status: json['status'] as String? ?? 'sent',
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'notification_type': notificationType,
      'title': title,
      'body': body,
      'data': data,
      'sent_at': sentAt.toIso8601String(),
      'status': status,
      'is_read': isRead,
    };
  }

  NotificationHistoryItem copyWith({
    String? id,
    String? userId,
    String? notificationType,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    DateTime? sentAt,
    String? status,
    bool? isRead,
  }) {
    return NotificationHistoryItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      notificationType: notificationType ?? this.notificationType,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      sentAt: sentAt ?? this.sentAt,
      status: status ?? this.status,
      isRead: isRead ?? this.isRead,
    );
  }

  /// Get Arabic label for notification type
  String get typeLabel {
    switch (notificationType) {
      case 'reminder':
        return 'تذكير';
      case 'achievement':
        return 'إنجاز';
      case 'announcement':
        return 'إعلان';
      case 'streak':
        return 'نقاط';
      case 'invitation':
        return 'دعوة عائلية';
      default:
        return 'إشعار';
    }
  }

  /// Get icon data for notification type
  String get typeIcon {
    switch (notificationType) {
      case 'reminder':
        return '🔔';
      case 'achievement':
        return '🏆';
      case 'announcement':
        return '📢';
      case 'streak':
        return '🔥';
      case 'invitation':
        return '🌳';
      default:
        return '📬';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationHistoryItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
