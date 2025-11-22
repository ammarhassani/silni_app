import 'package:cloud_firestore/cloud_firestore.dart';

/// Reminder frequency types
enum ReminderFrequency {
  daily('daily', 'يومي', '📅'),
  weekly('weekly', 'أسبوعي', '📆'),
  monthly('monthly', 'شهري', '📋'),
  friday('friday', 'جمعة', '🕌'),
  custom('custom', 'مخصص', '⚙️');

  final String value;
  final String arabicName;
  final String emoji;

  const ReminderFrequency(this.value, this.arabicName, this.emoji);

  static ReminderFrequency fromString(String value) {
    return ReminderFrequency.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ReminderFrequency.custom,
    );
  }
}

/// Model for reminder schedules
class ReminderSchedule {
  final String id;
  final String userId;
  final ReminderFrequency frequency;
  final List<String> relativeIds; // List of relative IDs in this schedule
  final String time; // HH:mm format
  final bool isActive;
  final List<int>? customDays; // For weekly: [1=Monday, 2=Tuesday, etc.]
  final int? dayOfMonth; // For monthly: 1-31
  final DateTime createdAt;
  final DateTime? updatedAt;

  ReminderSchedule({
    required this.id,
    required this.userId,
    required this.frequency,
    required this.relativeIds,
    required this.time,
    this.isActive = true,
    this.customDays,
    this.dayOfMonth,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create from Firestore document
  factory ReminderSchedule.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ReminderSchedule(
      id: doc.id,
      userId: data['userId'] as String,
      frequency: ReminderFrequency.fromString(data['frequency'] as String),
      relativeIds: List<String>.from(data['relativeIds'] ?? []),
      time: data['time'] as String,
      isActive: data['isActive'] as bool? ?? true,
      customDays: data['customDays'] != null
          ? List<int>.from(data['customDays'])
          : null,
      dayOfMonth: data['dayOfMonth'] as int?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'frequency': frequency.value,
      'relativeIds': relativeIds,
      'time': time,
      'isActive': isActive,
      'customDays': customDays,
      'dayOfMonth': dayOfMonth,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Copy with method
  ReminderSchedule copyWith({
    String? id,
    String? userId,
    ReminderFrequency? frequency,
    List<String>? relativeIds,
    String? time,
    bool? isActive,
    List<int>? customDays,
    int? dayOfMonth,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReminderSchedule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      frequency: frequency ?? this.frequency,
      relativeIds: relativeIds ?? this.relativeIds,
      time: time ?? this.time,
      isActive: isActive ?? this.isActive,
      customDays: customDays ?? this.customDays,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get description based on frequency
  String get description {
    switch (frequency) {
      case ReminderFrequency.daily:
        return 'كل يوم في الساعة $time';
      case ReminderFrequency.weekly:
        if (customDays != null && customDays!.isNotEmpty) {
          final dayNames = customDays!.map((d) => _getDayName(d)).join('، ');
          return 'كل $dayNames في الساعة $time';
        }
        return 'كل أسبوع في الساعة $time';
      case ReminderFrequency.monthly:
        if (dayOfMonth != null) {
          return 'يوم $dayOfMonth من كل شهر في الساعة $time';
        }
        return 'كل شهر في الساعة $time';
      case ReminderFrequency.friday:
        return 'كل جمعة في الساعة $time';
      case ReminderFrequency.birthday:
        return 'في عيد الميلاد';
      case ReminderFrequency.custom:
        return 'مخصص';
    }
  }

  String _getDayName(int day) {
    switch (day) {
      case 1:
        return 'الاثنين';
      case 2:
        return 'الثلاثاء';
      case 3:
        return 'الأربعاء';
      case 4:
        return 'الخميس';
      case 5:
        return 'الجمعة';
      case 6:
        return 'السبت';
      case 7:
        return 'الأحد';
      default:
        return '';
    }
  }

  /// Check if reminder should fire today
  bool shouldFireToday() {
    final now = DateTime.now();

    switch (frequency) {
      case ReminderFrequency.daily:
        return true;

      case ReminderFrequency.weekly:
        if (customDays != null && customDays!.isNotEmpty) {
          return customDays!.contains(now.weekday);
        }
        return true;

      case ReminderFrequency.monthly:
        if (dayOfMonth != null) {
          return now.day == dayOfMonth;
        }
        return false;

      case ReminderFrequency.friday:
        return now.weekday == 5; // Friday

      case ReminderFrequency.birthday:
      case ReminderFrequency.custom:
        return false;
    }
  }
}

/// Predefined reminder templates
class ReminderTemplate {
  final ReminderFrequency frequency;
  final String title;
  final String description;
  final String suggestedRelationships;
  final String defaultTime;

  const ReminderTemplate({
    required this.frequency,
    required this.title,
    required this.description,
    required this.suggestedRelationships,
    required this.defaultTime,
  });

  static const List<ReminderTemplate> templates = [
    ReminderTemplate(
      frequency: ReminderFrequency.daily,
      title: 'تذكير يومي',
      description: 'للأقارب الأقرب (الوالدين، الزوج/الزوجة)',
      suggestedRelationships: 'أب، أم، زوج، زوجة',
      defaultTime: '09:00',
    ),
    ReminderTemplate(
      frequency: ReminderFrequency.weekly,
      title: 'تذكير أسبوعي',
      description: 'للإخوة والأجداد',
      suggestedRelationships: 'أخ، أخت، جد، جدة',
      defaultTime: '10:00',
    ),
    ReminderTemplate(
      frequency: ReminderFrequency.monthly,
      title: 'تذكير شهري',
      description: 'للأعمام والأخوال وأبناء العم',
      suggestedRelationships: 'عم، خال، ابن العم، بنت الخالة',
      defaultTime: '11:00',
    ),
    ReminderTemplate(
      frequency: ReminderFrequency.friday,
      title: 'تذكير يوم الجمعة',
      description: 'تواصل خاص يوم الجمعة المبارك',
      suggestedRelationships: 'جميع الأقارب',
      defaultTime: '16:00',
    ),
  ];
}
