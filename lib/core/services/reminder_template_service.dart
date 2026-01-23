import 'package:supabase_flutter/supabase_flutter.dart';

import 'cache_config_service.dart';

/// Model for admin-configured reminder templates
class AdminReminderTemplate {
  final String id;
  final String templateKey;
  final String frequency;
  final String titleAr;
  final String? titleEn;
  final String descriptionAr;
  final String? descriptionEn;
  final String suggestedRelationshipsAr;
  final String? suggestedRelationshipsEn;
  final String defaultTime;
  final String emoji;
  final int sortOrder;
  final bool isActive;

  const AdminReminderTemplate({
    required this.id,
    required this.templateKey,
    required this.frequency,
    required this.titleAr,
    this.titleEn,
    required this.descriptionAr,
    this.descriptionEn,
    required this.suggestedRelationshipsAr,
    this.suggestedRelationshipsEn,
    required this.defaultTime,
    required this.emoji,
    required this.sortOrder,
    required this.isActive,
  });

  factory AdminReminderTemplate.fromJson(Map<String, dynamic> json) {
    return AdminReminderTemplate(
      id: json['id'] as String,
      templateKey: json['template_key'] as String,
      frequency: json['frequency'] as String,
      titleAr: json['title_ar'] as String,
      titleEn: json['title_en'] as String?,
      descriptionAr: json['description_ar'] as String,
      descriptionEn: json['description_en'] as String?,
      suggestedRelationshipsAr: json['suggested_relationships_ar'] as String,
      suggestedRelationshipsEn: json['suggested_relationships_en'] as String?,
      defaultTime: json['default_time'] as String,
      emoji: json['emoji'] as String,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Fallback templates matching the original hardcoded ones
  static const List<AdminReminderTemplate> fallbackTemplates = [
    AdminReminderTemplate(
      id: 'fallback-daily',
      templateKey: 'daily',
      frequency: 'daily',
      titleAr: 'تذكير يومي',
      titleEn: 'Daily Reminder',
      descriptionAr: 'للأقارب الأقرب (الوالدين، الزوج/الزوجة)',
      descriptionEn: 'For closest relatives (parents, spouse)',
      suggestedRelationshipsAr: 'أب، أم، زوج، زوجة',
      suggestedRelationshipsEn: 'Father, Mother, Husband, Wife',
      defaultTime: '09:00',
      emoji: '📅',
      sortOrder: 1,
      isActive: true,
    ),
    AdminReminderTemplate(
      id: 'fallback-weekly',
      templateKey: 'weekly',
      frequency: 'weekly',
      titleAr: 'تذكير أسبوعي',
      titleEn: 'Weekly Reminder',
      descriptionAr: 'للإخوة والأجداد',
      descriptionEn: 'For siblings and grandparents',
      suggestedRelationshipsAr: 'أخ، أخت، جد، جدة',
      suggestedRelationshipsEn: 'Brother, Sister, Grandfather, Grandmother',
      defaultTime: '10:00',
      emoji: '📆',
      sortOrder: 2,
      isActive: true,
    ),
    AdminReminderTemplate(
      id: 'fallback-monthly',
      templateKey: 'monthly',
      frequency: 'monthly',
      titleAr: 'تذكير شهري',
      titleEn: 'Monthly Reminder',
      descriptionAr: 'للأعمام والأخوال وأبناء العم',
      descriptionEn: 'For uncles, aunts, and cousins',
      suggestedRelationshipsAr: 'عم، خال، ابن العم، بنت الخالة',
      suggestedRelationshipsEn: 'Uncle, Aunt, Cousin',
      defaultTime: '11:00',
      emoji: '📋',
      sortOrder: 3,
      isActive: true,
    ),
    AdminReminderTemplate(
      id: 'fallback-friday',
      templateKey: 'friday',
      frequency: 'friday',
      titleAr: 'تذكير يوم الجمعة',
      titleEn: 'Friday Reminder',
      descriptionAr: 'تواصل خاص يوم الجمعة المبارك',
      descriptionEn: 'Special connection on blessed Friday',
      suggestedRelationshipsAr: 'جميع الأقارب',
      suggestedRelationshipsEn: 'All relatives',
      defaultTime: '16:00',
      emoji: '🕌',
      sortOrder: 4,
      isActive: true,
    ),
  ];
}

/// Service for loading reminder templates from admin configuration
class ReminderTemplateService {
  ReminderTemplateService._();
  static final ReminderTemplateService instance = ReminderTemplateService._();

  // Use lazy initialization to avoid accessing Supabase before it's initialized
  SupabaseClient get _supabase => Supabase.instance.client;
  final CacheConfigService _cacheConfig = CacheConfigService();
  static const String _serviceKey = 'reminder_templates';

  // Cached templates
  List<AdminReminderTemplate>? _templatesCache;
  DateTime? _lastFetchTime;

  bool get _isCacheValid {
    if (_lastFetchTime == null) return false;
    return !_cacheConfig.isCacheExpired(_serviceKey, _lastFetchTime);
  }

  /// Check if templates are loaded
  bool get isLoaded => _lastFetchTime != null;

  /// Initialize and load templates
  Future<void> initialize() async {
    if (!_isCacheValid) {
      await refresh();
    }
  }

  /// Refresh templates from server
  Future<void> refresh() async {
    try {
      final response = await _supabase
          .from('admin_reminder_templates')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      _templatesCache = (response as List)
          .map((e) => AdminReminderTemplate.fromJson(e as Map<String, dynamic>))
          .toList();

      _lastFetchTime = DateTime.now();
    } catch (_) {
      // Keep existing cache or use fallback
      _templatesCache ??= AdminReminderTemplate.fallbackTemplates;
    }
  }

  /// Get all active reminder templates
  List<AdminReminderTemplate> getTemplates() {
    return _templatesCache ?? AdminReminderTemplate.fallbackTemplates;
  }

  /// Get template by frequency
  AdminReminderTemplate? getTemplateByFrequency(String frequency) {
    final templates = getTemplates();
    return templates.where((t) => t.frequency == frequency).firstOrNull;
  }

  /// Clear cache
  void clearCache() {
    _templatesCache = null;
    _lastFetchTime = null;
  }
}
