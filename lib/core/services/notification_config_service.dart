import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'cache_config_service.dart';

/// Singleton service that fetches and caches notification configuration from admin tables.
/// Provides dynamic notification templates and reminder time slots.
class NotificationConfigService {
  NotificationConfigService._();
  static final NotificationConfigService instance = NotificationConfigService._();

  // Use lazy initialization to avoid accessing Supabase before it's initialized
  SupabaseClient get _supabase => SupabaseConfig.client;

  // Cache variables
  Map<String, NotificationTemplate>? _templatesCache;
  List<ReminderTimeSlot>? _timeSlotsCache;

  DateTime? _lastRefresh;
  final CacheConfigService _cacheConfig = CacheConfigService();
  static const String _serviceKey = 'notification_config';

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool get isLoaded => _templatesCache != null;

  /// Refresh all notification config from admin tables
  Future<void> refresh() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      await Future.wait([
        _fetchTemplates(),
        _fetchTimeSlots(),
      ]);
      _lastRefresh = DateTime.now();
    } catch (_) {
      // Refresh failed silently
    } finally {
      _isLoading = false;
    }
  }

  /// Check if cache is stale and needs refresh
  Future<void> ensureFresh() async {
    if (_cacheConfig.isCacheExpired(_serviceKey, _lastRefresh)) {
      await refresh();
    }
  }

  /// Clear all caches
  void clearCache() {
    _templatesCache = null;
    _timeSlotsCache = null;
    _lastRefresh = null;
  }

  // ============ Notification Templates ============

  Future<void> _fetchTemplates() async {
    try {
      final response = await _supabase
          .from('admin_notification_templates')
          .select()
          .eq('is_active', true);
      final templates = (response as List)
          .map((json) => NotificationTemplate.fromJson(json))
          .toList();
      _templatesCache = {for (var t in templates) t.templateKey: t};
    } catch (_) {
      // Fetch templates failed silently
    }
  }

  /// Get all templates
  Map<String, NotificationTemplate> get templates =>
      _templatesCache ?? _fallbackTemplates();

  /// Get a specific template by key
  NotificationTemplate? getTemplate(String key) {
    return templates[key];
  }

  /// Get templates by category
  List<NotificationTemplate> getTemplatesByCategory(String category) {
    return templates.values.where((t) => t.category == category).toList();
  }

  /// Build notification content from template with variable substitution
  NotificationContent? buildNotification(String templateKey, Map<String, String> variables) {
    final template = getTemplate(templateKey);
    if (template == null) return null;

    var title = template.titleAr;
    var body = template.bodyAr;

    // Replace variables
    variables.forEach((key, value) {
      title = title.replaceAll('{{$key}}', value);
      body = body.replaceAll('{{$key}}', value);
    });

    return NotificationContent(
      title: title,
      body: body,
      category: template.category,
      sound: template.sound,
      priority: template.priority,
    );
  }

  Map<String, NotificationTemplate> _fallbackTemplates() {
    return {
      'reminder_due': NotificationTemplate(
        templateKey: 'reminder_due',
        titleAr: 'حان وقت التواصل! ⏰',
        bodyAr: 'حان موعد التواصل مع {{relative_name}}',
        category: 'reminder',
        variables: ['relative_name'],
        sound: 'default',
        priority: 'high',
      ),
      'streak_endangered': NotificationTemplate(
        templateKey: 'streak_endangered',
        titleAr: 'تذكير بسيط 💛',
        bodyAr: 'عائلتك تشتاق لك — تواصل بسيط يفرق 🤍',
        category: 'streak',
        variables: ['hours', 'streak_days'],
        sound: 'default',
        priority: 'high',
      ),
      'streak_broken': NotificationTemplate(
        templateKey: 'streak_broken',
        titleAr: 'مرحبًا بعودتك 🤍',
        bodyAr: 'عائلتك اشتاقت لك — رسالة بسيطة تفرق',
        category: 'streak',
        variables: [],
        sound: 'default',
        priority: 'normal',
      ),
      'nudge_7_days': NotificationTemplate(
        templateKey: 'nudge_7_days',
        titleAr: '{{relative_label}} يشتاق لك 💛',
        bodyAr: 'اتصال بسيط يسعدهم — وش رايك تتواصل معاهم؟',
        category: 'nudge',
        variables: ['relative_label'],
        sound: 'default',
        priority: 'normal',
      ),
      'nudge_14_days': NotificationTemplate(
        templateKey: 'nudge_14_days',
        titleAr: 'لك فترة ما تواصلت 🤍',
        bodyAr: 'رسالة بسيطة لـ {{relative_label}} تفرق كثير',
        category: 'nudge',
        variables: ['relative_label'],
        sound: 'default',
        priority: 'normal',
      ),
      'nudge_30_days': NotificationTemplate(
        templateKey: 'nudge_30_days',
        titleAr: 'وقت مناسب تتواصل 🤍',
        bodyAr: 'لك فترة ما تواصلت مع {{relative_label}} — رسالة بسيطة تفرق',
        category: 'nudge',
        variables: ['relative_label'],
        sound: 'default',
        priority: 'normal',
      ),
    };
  }

  // ============ Reminder Time Slots ============

  Future<void> _fetchTimeSlots() async {
    try {
      final response = await _supabase
          .from('admin_reminder_time_slots')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);
      _timeSlotsCache = (response as List)
          .map((json) => ReminderTimeSlot.fromJson(json))
          .toList();
    } catch (_) {
      // Fetch time slots failed silently
    }
  }

  /// Get all time slots
  List<ReminderTimeSlot> get timeSlots =>
      _timeSlotsCache ?? ReminderTimeSlot.fallbackSlots();

  /// Get the default time slot
  ReminderTimeSlot get defaultTimeSlot {
    final defaultSlot = timeSlots.cast<ReminderTimeSlot?>().firstWhere(
          (s) => s?.isDefault == true,
          orElse: () => null,
        );
    return defaultSlot ?? timeSlots.first;
  }

  /// Get time slot by key
  ReminderTimeSlot? getTimeSlot(String key) {
    return timeSlots.cast<ReminderTimeSlot?>().firstWhere(
          (s) => s?.slotKey == key,
          orElse: () => null,
        );
  }

  /// Get the best time slot for current hour
  ReminderTimeSlot getSlotForHour(int hour) {
    for (final slot in timeSlots) {
      if (hour >= slot.startHour && hour < slot.endHour) {
        return slot;
      }
    }
    return defaultTimeSlot;
  }
}

// ============ Models ============

class NotificationTemplate {
  final String templateKey;
  final String titleAr;
  final String? titleEn;
  final String bodyAr;
  final String? bodyEn;
  final String category;
  final List<String> variables;
  final String sound;
  final String priority;

  NotificationTemplate({
    required this.templateKey,
    required this.titleAr,
    this.titleEn,
    required this.bodyAr,
    this.bodyEn,
    required this.category,
    required this.variables,
    this.sound = 'default',
    this.priority = 'normal',
  });

  factory NotificationTemplate.fromJson(Map<String, dynamic> json) {
    return NotificationTemplate(
      templateKey: json['template_key'] as String,
      titleAr: json['title_ar'] as String,
      titleEn: json['title_en'] as String?,
      bodyAr: json['body_ar'] as String,
      bodyEn: json['body_en'] as String?,
      category: json['category'] as String? ?? 'system',
      variables: (json['variables'] as List?)?.cast<String>() ?? [],
      sound: json['sound'] as String? ?? 'default',
      priority: json['priority'] as String? ?? 'normal',
    );
  }
}

class NotificationContent {
  final String title;
  final String body;
  final String category;
  final String sound;
  final String priority;

  NotificationContent({
    required this.title,
    required this.body,
    required this.category,
    required this.sound,
    required this.priority,
  });
}

class ReminderTimeSlot {
  final String slotKey;
  final String displayNameAr;
  final String? displayNameEn;
  final int startHour;
  final int endHour;
  final String icon;
  final bool isDefault;
  final int sortOrder;

  ReminderTimeSlot({
    required this.slotKey,
    required this.displayNameAr,
    this.displayNameEn,
    required this.startHour,
    required this.endHour,
    required this.icon,
    this.isDefault = false,
    required this.sortOrder,
  });

  factory ReminderTimeSlot.fromJson(Map<String, dynamic> json) {
    return ReminderTimeSlot(
      slotKey: json['slot_key'] as String,
      displayNameAr: json['display_name_ar'] as String,
      displayNameEn: json['display_name_en'] as String?,
      startHour: json['start_hour'] as int,
      endHour: json['end_hour'] as int,
      icon: json['icon'] as String? ?? 'clock',
      isDefault: json['is_default'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  /// Get a formatted time range string (e.g., "6:00 - 12:00")
  String get timeRange => '${startHour.toString().padLeft(2, '0')}:00 - ${endHour.toString().padLeft(2, '0')}:00';

  static List<ReminderTimeSlot> fallbackSlots() {
    return [
      ReminderTimeSlot(
        slotKey: 'morning',
        displayNameAr: 'الصباح',
        displayNameEn: 'Morning',
        startHour: 6,
        endHour: 12,
        icon: 'sunrise',
        sortOrder: 1,
      ),
      ReminderTimeSlot(
        slotKey: 'afternoon',
        displayNameAr: 'الظهيرة',
        displayNameEn: 'Afternoon',
        startHour: 12,
        endHour: 17,
        icon: 'sun',
        isDefault: true,
        sortOrder: 2,
      ),
      ReminderTimeSlot(
        slotKey: 'evening',
        displayNameAr: 'المساء',
        displayNameEn: 'Evening',
        startHour: 17,
        endHour: 21,
        icon: 'sunset',
        sortOrder: 3,
      ),
      ReminderTimeSlot(
        slotKey: 'night',
        displayNameAr: 'الليل',
        displayNameEn: 'Night',
        startHour: 21,
        endHour: 24,
        icon: 'moon',
        sortOrder: 4,
      ),
    ];
  }
}
