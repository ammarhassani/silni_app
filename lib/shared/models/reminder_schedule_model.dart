import 'package:silni_app/core/errors/app_errors.dart';
import 'package:silni_app/shared/models/relative_model.dart';

/// Reminder frequency types
enum ReminderFrequency {
  daily('daily', 'يومي', '📅'),
  weekly('weekly', 'أسبوعي', '📆'),
  monthly('monthly', 'شهري', '📋'),
  friday('friday', 'جمعة', '🕌');

  final String value;
  final String arabicName;
  final String emoji;

  const ReminderFrequency(this.value, this.arabicName, this.emoji);

  static ReminderFrequency fromString(String value) {
    return ReminderFrequency.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ReminderFrequency.daily,
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

  /// Create from Supabase JSON
  factory ReminderSchedule.fromJson(Map<String, dynamic> json) {
    try {
      // Check for required fields
      final id = json['id'];
      final userId = json['user_id'];
      final frequency = json['frequency'];
      // Use 'time' field as that's what database actually has
      final reminderTime = json['time'];
      final createdAt = json['created_at'];

      if (id == null ||
          userId == null ||
          frequency == null ||
          reminderTime == null ||
          createdAt == null) {
        throw const ValidationError(
          message: 'Missing required fields in ReminderSchedule.fromJson',
          arabicMessage: 'بيانات جدول التذكير غير مكتملة',
          field: 'ReminderSchedule',
        );
      }

      return ReminderSchedule(
        id: id as String,
        userId: userId as String,
        frequency: ReminderFrequency.fromString(frequency as String),
        relativeIds: json['relative_ids'] != null
            ? List<String>.from(json['relative_ids'] as List)
            : [],
        time: reminderTime as String,
        isActive: json['is_active'] as bool? ?? true,
        customDays: json['custom_days'] != null
            ? List<int>.from(json['custom_days'] as List)
            : null,
        dayOfMonth: json['day_of_month'] as int?,
        createdAt: DateTime.parse(createdAt as String),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'frequency': frequency.value,
      'relative_ids': relativeIds,
      'time': time, // Use 'time' field to match database schema
      'is_active': isActive,
      'custom_days': customDays,
      'day_of_month': dayOfMonth,
      // Don't include id, created_at, updated_at - managed by database
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
    }
  }
}

/// A relative paired with the reminder frequencies that triggered them today/tomorrow
class DueRelativeWithFrequencies {
  final Relative relative;
  final Set<ReminderFrequency> frequencies;

  const DueRelativeWithFrequencies({
    required this.relative,
    required this.frequencies,
  });

  /// Check if this relative has Friday reminder
  bool get hasFridayReminder => frequencies.contains(ReminderFrequency.friday);

  /// Get sorted frequencies for display (Friday first, then by arabic name)
  List<ReminderFrequency> get sortedFrequencies {
    final list = frequencies.toList();
    list.sort((a, b) {
      // Friday first (special religious significance)
      if (a == ReminderFrequency.friday) return -1;
      if (b == ReminderFrequency.friday) return 1;
      return a.arabicName.compareTo(b.arabicName);
    });
    return list;
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
