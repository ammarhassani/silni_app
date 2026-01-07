import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cache_config_service.dart';

/// Model for a UI string from admin_ui_strings table
class UIString {
  final String id;
  final String stringKey;
  final String category;
  final String valueAr;
  final String? valueEn;
  final String? description;
  final String? screen;
  final bool isActive;

  UIString({
    required this.id,
    required this.stringKey,
    required this.category,
    required this.valueAr,
    this.valueEn,
    this.description,
    this.screen,
    required this.isActive,
  });

  factory UIString.fromJson(Map<String, dynamic> json) {
    return UIString(
      id: json['id'] as String,
      stringKey: json['string_key'] as String,
      category: json['category'] as String? ?? 'general',
      valueAr: json['value_ar'] as String,
      valueEn: json['value_en'] as String?,
      description: json['description'] as String?,
      screen: json['screen'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

/// Service for fetching and caching UI strings from Supabase
/// Allows remote control of app text/labels
class UIStringsService {
  UIStringsService._();
  static final UIStringsService instance = UIStringsService._();

  final _supabase = Supabase.instance.client;

  // Cache
  Map<String, UIString>? _stringsCache;
  DateTime? _lastFetchTime;

  // Cache duration from remote config
  final CacheConfigService _cacheConfig = CacheConfigService();
  static const String _serviceKey = 'ui_strings';

  // Fallback strings (hardcoded defaults)
  static const Map<String, String> _fallbackStrings = {
    // General
    'app_name': 'صِلني',
    'loading': 'جاري التحميل...',
    'retry': 'إعادة المحاولة',

    // Buttons
    'save': 'حفظ',
    'cancel': 'إلغاء',
    'confirm': 'تأكيد',
    'delete': 'حذف',
    'edit': 'تعديل',
    'add': 'إضافة',
    'close': 'إغلاق',
    'next': 'التالي',
    'back': 'رجوع',
    'done': 'تم',
    'skip': 'تخطي',

    // Titles
    'home_title': 'الرئيسية',
    'profile_title': 'الملف الشخصي',
    'settings_title': 'الإعدادات',
    'reminders_title': 'التذكيرات',
    'relatives_title': 'الأقارب',

    // Labels
    'streak_label': 'سلسلة التواصل',
    'points_label': 'النقاط',
    'level_label': 'المستوى',
    'today': 'اليوم',
    'yesterday': 'أمس',
    'days_ago': 'يوم',

    // Messages
    'success_saved': 'تم الحفظ بنجاح',
    'success_deleted': 'تم الحذف بنجاح',
    'success_updated': 'تم التحديث بنجاح',
    'confirm_delete': 'هل أنت متأكد من الحذف؟',

    // Errors
    'error_network': 'خطأ في الاتصال بالشبكة',
    'error_generic': 'حدث خطأ ما',
    'error_try_again': 'الرجاء المحاولة مرة أخرى',
    'error_not_found': 'غير موجود',

    // Placeholders
    'search_placeholder': 'بحث...',
    'name_placeholder': 'الاسم',
    'notes_placeholder': 'ملاحظات...',

    // Gamification
    'streak_congrats': 'أحسنت! حافظت على السلسلة',
    'level_up': 'مبروك! ارتقيت لمستوى جديد',
    'badge_earned': 'حصلت على شارة جديدة!',
    'points_earned': 'نقطة',
  };

  /// Initialize the service (call on app start)
  Future<void> initialize() async {
    await _fetchStrings();
  }

  /// Fetch all strings from Supabase
  Future<void> _fetchStrings() async {
    try {
      final response = await _supabase
          .from('admin_ui_strings')
          .select()
          .eq('is_active', true);

      final strings = (response as List).map((json) => UIString.fromJson(json)).toList();

      _stringsCache = {for (var s in strings) s.stringKey: s};
      _lastFetchTime = DateTime.now();

      debugPrint('[UIStringsService] Fetched ${strings.length} strings');
    } catch (e) {
      debugPrint('[UIStringsService] Error fetching strings: $e');
      // Keep existing cache if available
    }
  }

  /// Get a UI string by key with optional fallback
  String get(String key, {String? fallback}) {
    // Try cache first
    if (_stringsCache != null && _stringsCache!.containsKey(key)) {
      return _stringsCache![key]!.valueAr;
    }

    // Try hardcoded fallback
    if (_fallbackStrings.containsKey(key)) {
      return _fallbackStrings[key]!;
    }

    // Use provided fallback or return key
    return fallback ?? key;
  }

  /// Get English version of a string if available
  String? getEn(String key) {
    if (_stringsCache != null && _stringsCache!.containsKey(key)) {
      return _stringsCache![key]!.valueEn;
    }
    return null;
  }

  /// Get all strings for a specific category
  List<UIString> getByCategory(String category) {
    if (_stringsCache == null) return [];
    return _stringsCache!.values.where((s) => s.category == category).toList();
  }

  /// Get all strings for a specific screen
  List<UIString> getByScreen(String screen) {
    if (_stringsCache == null) return [];
    return _stringsCache!.values.where((s) => s.screen == screen).toList();
  }

  /// Check if a string exists
  bool hasString(String key) {
    return (_stringsCache?.containsKey(key) ?? false) ||
        _fallbackStrings.containsKey(key);
  }

  /// Refresh strings from server
  Future<void> refresh() async {
    await _fetchStrings();
  }

  /// Check if cache needs refresh
  bool get needsRefresh {
    if (_lastFetchTime == null) return true;
    return _cacheConfig.isCacheExpired(_serviceKey, _lastFetchTime);
  }

  /// Ensure strings are fresh
  Future<void> ensureFresh() async {
    if (needsRefresh) {
      await _fetchStrings();
    }
  }

  /// Clear cache
  void clearCache() {
    _stringsCache = null;
    _lastFetchTime = null;
    debugPrint('[UIStringsService] Cache cleared');
  }
}

/// Extension for easy access to UI strings
extension UIStringsExtension on String {
  /// Get the translated UI string for this key
  /// Usage: 'save'.tr or 'home_title'.tr
  String get tr => UIStringsService.instance.get(this);

  /// Get translated string with fallback
  /// Usage: 'custom_key'.trOr('Default Text')
  String trOr(String fallback) => UIStringsService.instance.get(this, fallback: fallback);
}
