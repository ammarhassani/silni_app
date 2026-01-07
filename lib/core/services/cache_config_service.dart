import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/supabase_config.dart';
import 'app_logger_service.dart';

/// Service for managing remote cache configuration
/// Allows admin panel to control cache durations for all config services
class CacheConfigService {
  static final CacheConfigService _instance = CacheConfigService._internal();
  factory CacheConfigService() => _instance;
  CacheConfigService._internal();

  final AppLoggerService _logger = AppLoggerService();
  bool _isInitialized = false;
  DateTime? _lastFetch;

  // Cache config values (service_key -> duration in seconds)
  final Map<String, int> _cacheConfigs = {};

  // Default values (fallback if remote config fails)
  static const Map<String, int> _defaults = {
    'feature_config': 300, // 5 minutes
    'ai_config': 300, // 5 minutes
    'gamification_config': 300, // 5 minutes
    'notification_config': 600, // 10 minutes
    'design_config': 600, // 10 minutes
    'content_config': 600, // 10 minutes
    'app_routes_config': 600, // 10 minutes
    'ui_strings': 3600, // 1 hour (strings rarely change)
    'onboarding_config': 3600, // 1 hour (onboarding rarely changes)
    'in_app_messages': 300, // 5 minutes (messages should be fresh)
  };

  // How often to re-fetch cache config itself (1 hour)
  static const Duration _selfCacheDuration = Duration(hours: 1);

  /// Initialize the cache config service
  /// Should be called early in app startup
  Future<void> initialize() async {
    if (_isInitialized && !_shouldRefetch()) return;

    try {
      final response = await SupabaseConfig.client
          .from('admin_cache_config')
          .select('service_key, cache_duration_seconds')
          .eq('is_active', true);

      _cacheConfigs.clear();
      for (final config in response) {
        _cacheConfigs[config['service_key'] as String] =
            config['cache_duration_seconds'] as int;
      }

      _lastFetch = DateTime.now();
      _isInitialized = true;

      _logger.info(
        'Cache config initialized with ${_cacheConfigs.length} services',
        category: LogCategory.service,
        tag: 'CacheConfigService',
      );
    } catch (e) {
      _logger.warning(
        'Failed to fetch cache config, using defaults',
        category: LogCategory.service,
        tag: 'CacheConfigService',
        metadata: {'error': e.toString()},
      );
      _isInitialized = true; // Mark as initialized with defaults
    }
  }

  bool _shouldRefetch() {
    if (_lastFetch == null) return true;
    return DateTime.now().difference(_lastFetch!) > _selfCacheDuration;
  }

  /// Get cache duration for a specific service
  /// Returns Duration, falling back to defaults if not configured
  Duration getCacheDuration(String serviceKey) {
    final seconds = _cacheConfigs[serviceKey] ?? _defaults[serviceKey] ?? 300;
    return Duration(seconds: seconds);
  }

  /// Get cache duration in seconds
  int getCacheDurationSeconds(String serviceKey) {
    return _cacheConfigs[serviceKey] ?? _defaults[serviceKey] ?? 300;
  }

  /// Check if a cached value has expired
  bool isCacheExpired(String serviceKey, DateTime? lastFetch) {
    if (lastFetch == null) return true;
    return DateTime.now().difference(lastFetch) > getCacheDuration(serviceKey);
  }

  /// Get all current cache configs (for debugging)
  Map<String, int> getAllConfigs() {
    return Map.from(_defaults)..addAll(_cacheConfigs);
  }

  /// Force refresh of cache config
  Future<void> refresh() async {
    _lastFetch = null;
    await initialize();
  }
}

/// Provider for cache config service
final cacheConfigServiceProvider = Provider<CacheConfigService>((ref) {
  return CacheConfigService();
});

/// Provider to get cache duration for a specific service
final cacheDurationProvider = Provider.family<Duration, String>((ref, serviceKey) {
  final service = ref.watch(cacheConfigServiceProvider);
  return service.getCacheDuration(serviceKey);
});
