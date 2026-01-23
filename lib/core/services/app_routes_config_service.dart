import 'package:supabase_flutter/supabase_flutter.dart';

import 'cache_config_service.dart';

/// Model for route category from admin_route_categories table
class RouteCategory {
  final String id;
  final String categoryKey;
  final String labelAr;
  final String? labelEn;
  final String? icon;
  final int sortOrder;
  final bool isActive;

  RouteCategory({
    required this.id,
    required this.categoryKey,
    required this.labelAr,
    this.labelEn,
    this.icon,
    required this.sortOrder,
    required this.isActive,
  });

  factory RouteCategory.fromJson(Map<String, dynamic> json) {
    return RouteCategory(
      id: json['id'] as String,
      categoryKey: json['category_key'] as String,
      labelAr: json['label_ar'] as String,
      labelEn: json['label_en'] as String?,
      icon: json['icon'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

/// Model for app route from admin_app_routes table
class AppRouteConfig {
  final String id;
  final String path;
  final String routeKey;
  final String labelAr;
  final String? labelEn;
  final String? icon;
  final String? descriptionAr;
  final String categoryKey;
  final String? parentRouteKey;
  final int sortOrder;
  final bool isActive;
  final bool isPublic;
  final bool requiresAuth;
  final bool requiresPremium;
  final String? featureId;

  AppRouteConfig({
    required this.id,
    required this.path,
    required this.routeKey,
    required this.labelAr,
    this.labelEn,
    this.icon,
    this.descriptionAr,
    required this.categoryKey,
    this.parentRouteKey,
    required this.sortOrder,
    required this.isActive,
    required this.isPublic,
    required this.requiresAuth,
    required this.requiresPremium,
    this.featureId,
  });

  factory AppRouteConfig.fromJson(Map<String, dynamic> json) {
    return AppRouteConfig(
      id: json['id'] as String,
      path: json['path'] as String,
      routeKey: json['route_key'] as String,
      labelAr: json['label_ar'] as String,
      labelEn: json['label_en'] as String?,
      icon: json['icon'] as String?,
      descriptionAr: json['description_ar'] as String?,
      categoryKey: json['category_key'] as String,
      parentRouteKey: json['parent_route_key'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      isPublic: json['is_public'] as bool? ?? true,
      requiresAuth: json['requires_auth'] as bool? ?? true,
      requiresPremium: json['requires_premium'] as bool? ?? false,
      featureId: json['feature_id'] as String?,
    );
  }
}

/// Service for fetching and caching app routes from Supabase
/// Used by MessageWidget for CTA route navigation
class AppRoutesConfigService {
  AppRoutesConfigService._();
  static final AppRoutesConfigService instance = AppRoutesConfigService._();

  // Use lazy initialization to avoid accessing Supabase before it's initialized
  SupabaseClient get _supabase => Supabase.instance.client;

  // Cached configs
  List<AppRouteConfig>? _routesCache;
  List<RouteCategory>? _categoriesCache;
  DateTime? _lastFetchTime;

  // Cache duration from remote config
  final CacheConfigService _cacheConfig = CacheConfigService();
  static const String _serviceKey = 'app_routes_config';

  /// Initialize the service by loading routes
  Future<void> initialize() async {
    try {
      await Future.wait([
        getRoutes(forceRefresh: true),
        getCategories(forceRefresh: true),
      ]);
    } catch (_) {
      // Routes initialization failed silently
    }
  }

  /// Get all route configurations
  Future<List<AppRouteConfig>> getRoutes({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid && _routesCache != null) {
      return _routesCache!;
    }

    try {
      final response = await _supabase
          .from('admin_app_routes')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      _routesCache = (response as List)
          .map((json) => AppRouteConfig.fromJson(json))
          .toList();
      _lastFetchTime = DateTime.now();

      return _routesCache!;
    } catch (_) {
      if (_routesCache != null) return _routesCache!;
      return _fallbackRoutes;
    }
  }

  /// Get all route categories
  Future<List<RouteCategory>> getCategories({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid && _categoriesCache != null) {
      return _categoriesCache!;
    }

    try {
      final response = await _supabase
          .from('admin_route_categories')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      _categoriesCache = (response as List)
          .map((json) => RouteCategory.fromJson(json))
          .toList();

      return _categoriesCache!;
    } catch (_) {
      if (_categoriesCache != null) return _categoriesCache!;
      return [];
    }
  }

  /// Get a specific route by key
  AppRouteConfig? getRouteByKey(String routeKey) {
    if (_routesCache == null) return null;
    return _routesCache!.cast<AppRouteConfig?>().firstWhere(
      (r) => r?.routeKey == routeKey,
      orElse: () => null,
    );
  }

  /// Get a specific route by path
  AppRouteConfig? getRouteByPath(String path) {
    if (_routesCache == null) return null;
    return _routesCache!.cast<AppRouteConfig?>().firstWhere(
      (r) => r?.path == path,
      orElse: () => null,
    );
  }

  /// Get routes by category
  List<AppRouteConfig> getRoutesByCategory(String categoryKey) {
    if (_routesCache == null) return [];
    return _routesCache!.where((r) => r.categoryKey == categoryKey).toList();
  }

  /// Get child routes of a parent route
  List<AppRouteConfig> getChildRoutes(String parentRouteKey) {
    if (_routesCache == null) return [];
    return _routesCache!.where((r) => r.parentRouteKey == parentRouteKey).toList();
  }

  /// Check if a route requires premium subscription
  bool routeRequiresPremium(String routeKey) {
    final route = getRouteByKey(routeKey);
    return route?.requiresPremium ?? false;
  }

  /// Get the feature ID associated with a route (for feature gating)
  String? getRouteFeatureId(String routeKey) {
    return getRouteByKey(routeKey)?.featureId;
  }

  /// Clear cache and force refresh on next fetch
  void clearCache() {
    _routesCache = null;
    _categoriesCache = null;
    _lastFetchTime = null;
  }

  /// Refresh all configs
  Future<void> refresh() async {
    await Future.wait([
      getRoutes(forceRefresh: true),
      getCategories(forceRefresh: true),
    ]);
  }

  bool get _isCacheValid {
    if (_lastFetchTime == null) return false;
    return !_cacheConfig.isCacheExpired(_serviceKey, _lastFetchTime);
  }

  bool get isLoaded => _routesCache != null;

  /// Fallback routes when config cannot be loaded
  List<AppRouteConfig> get _fallbackRoutes => [
    AppRouteConfig(
      id: 'fallback_home',
      path: '/home',
      routeKey: 'home',
      labelAr: 'الرئيسية',
      categoryKey: 'main',
      sortOrder: 1,
      isActive: true,
      isPublic: true,
      requiresAuth: true,
      requiresPremium: false,
    ),
    AppRouteConfig(
      id: 'fallback_ai_chat',
      path: '/ai-chat',
      routeKey: 'ai_chat',
      labelAr: 'المحادثة',
      categoryKey: 'ai',
      sortOrder: 2,
      isActive: true,
      isPublic: true,
      requiresAuth: true,
      requiresPremium: true,
      featureId: 'ai_chat',
    ),
    AppRouteConfig(
      id: 'fallback_reminders',
      path: '/reminders',
      routeKey: 'reminders',
      labelAr: 'التذكيرات',
      categoryKey: 'main',
      sortOrder: 3,
      isActive: true,
      isPublic: true,
      requiresAuth: true,
      requiresPremium: false,
    ),
    AppRouteConfig(
      id: 'fallback_family_tree',
      path: '/family-tree',
      routeKey: 'family_tree',
      labelAr: 'شجرة العائلة',
      categoryKey: 'main',
      sortOrder: 4,
      isActive: true,
      isPublic: true,
      requiresAuth: true,
      requiresPremium: false,
    ),
    AppRouteConfig(
      id: 'fallback_profile',
      path: '/profile',
      routeKey: 'profile',
      labelAr: 'الملف الشخصي',
      categoryKey: 'account',
      sortOrder: 5,
      isActive: true,
      isPublic: true,
      requiresAuth: true,
      requiresPremium: false,
    ),
    AppRouteConfig(
      id: 'fallback_settings',
      path: '/settings',
      routeKey: 'settings',
      labelAr: 'الإعدادات',
      categoryKey: 'account',
      sortOrder: 6,
      isActive: true,
      isPublic: true,
      requiresAuth: true,
      requiresPremium: false,
    ),
    AppRouteConfig(
      id: 'fallback_subscription',
      path: '/subscription',
      routeKey: 'subscription',
      labelAr: 'الاشتراك',
      categoryKey: 'account',
      sortOrder: 7,
      isActive: true,
      isPublic: true,
      requiresAuth: true,
      requiresPremium: false,
    ),
  ];
}
