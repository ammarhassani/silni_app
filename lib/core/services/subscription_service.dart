import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;

import '../config/env/app_environment.dart';
import '../config/supabase_config.dart';
import '../models/subscription_tier.dart';
import '../models/subscription_state.dart';
import 'app_logger_service.dart';

/// Subscription service using RevenueCat
/// Manages in-app purchases and subscription state
class SubscriptionService {
  static SubscriptionService? _instance;
  final AppLoggerService _logger = AppLoggerService();
  bool _isInitialized = false;

  final _stateController = StreamController<SubscriptionState>.broadcast();
  SubscriptionState _currentState = const SubscriptionState();

  SubscriptionService._();

  // =====================================================
  // CACHE CONSTANTS
  // =====================================================
  static const String _cacheBoxName = 'subscription_cache';
  static const String _cacheTierKey = 'tier';
  static const String _cacheExpirationKey = 'expiration';
  static const String _cacheTimestampKey = 'cached_at';
  static const Duration _cacheValidity = Duration(hours: 24);

  /// Singleton instance
  static SubscriptionService get instance {
    _instance ??= SubscriptionService._();
    return _instance!;
  }

  /// Stream of subscription state changes
  Stream<SubscriptionState> get stateStream => _stateController.stream;

  /// Current subscription state
  SubscriptionState get currentState => _currentState;

  /// Whether the service is initialized
  bool get isInitialized => _isInitialized;

  /// Current subscription tier
  SubscriptionTier get currentTier => _currentState.tier;

  /// Whether user has paid (MAX) access
  bool get isPaid => _currentState.isMax;

  /// Whether user has MAX tier access
  bool get isMax => _currentState.isMax;

  // =====================================================
  // INITIALIZATION
  // =====================================================

  /// Initialize RevenueCat SDK
  Future<void> initialize({String? userId}) async {
    if (_isInitialized) {
      _logger.info(
        'SubscriptionService already initialized',
        category: LogCategory.service,
        tag: 'SubscriptionService',
      );
      return;
    }

    try {
      _logger.info(
        'Initializing RevenueCat',
        category: LogCategory.service,
        tag: 'SubscriptionService',
      );

      // Skip on web platform
      if (kIsWeb) {
        _logger.info(
          'Web platform - skipping RevenueCat initialization',
          category: LogCategory.service,
          tag: 'SubscriptionService',
        );
        _isInitialized = true;
        _updateState(_currentState.copyWith(isLoading: false));
        return;
      }

      // Get platform-specific API key
      String apiKey;
      if (Platform.isIOS || Platform.isMacOS) {
        apiKey = AppEnvironment.revenueCatAppleApiKey;
      } else if (Platform.isAndroid) {
        apiKey = AppEnvironment.revenueCatGoogleApiKey;
      } else {
        _logger.warning(
          'Unsupported platform for in-app purchases',
          category: LogCategory.service,
          tag: 'SubscriptionService',
        );
        _isInitialized = true;
        _updateState(_currentState.copyWith(isLoading: false));
        return;
      }

      // Check if API key is configured
      if (apiKey.isEmpty) {
        _logger.warning(
          'RevenueCat API key not configured',
          category: LogCategory.service,
          tag: 'SubscriptionService',
        );
        _isInitialized = true;
        _updateState(_currentState.copyWith(isLoading: false));
        return;
      }

      // Configure RevenueCat
      final configuration = rc.PurchasesConfiguration(apiKey);
      await rc.Purchases.configure(configuration);

      // Enable debug logs in development
      if (kDebugMode) {
        await rc.Purchases.setLogLevel(rc.LogLevel.debug);
      }

      // Set user ID if provided
      if (userId != null && userId.isNotEmpty) {
        _logger.info(
          'Logging in to RevenueCat with user ID',
          category: LogCategory.service,
          tag: 'SubscriptionService',
          metadata: {'userId': userId},
        );
        await rc.Purchases.logIn(userId);
      } else {
        _logger.warning(
          'No user ID provided - using anonymous RevenueCat user',
          category: LogCategory.service,
          tag: 'SubscriptionService',
        );
      }

      // Log the actual RevenueCat app user ID being used
      final customerInfo = await rc.Purchases.getCustomerInfo();
      _logger.info(
        'RevenueCat customer info retrieved',
        category: LogCategory.service,
        tag: 'SubscriptionService',
        metadata: {
          'rcAppUserId': customerInfo.originalAppUserId,
          'activeEntitlements': customerInfo.entitlements.active.keys.toList(),
        },
      );

      // Listen for customer info updates
      rc.Purchases.addCustomerInfoUpdateListener(_handleCustomerInfoUpdate);

      // Initial fetch
      await refreshSubscriptionStatus();

      // Sync to Supabase on init (ensures DB is up to date)
      await _syncSubscriptionToSupabase(_currentState);

      _isInitialized = true;

      _logger.info(
        'RevenueCat initialized successfully',
        category: LogCategory.service,
        tag: 'SubscriptionService',
        metadata: {'tier': _currentState.tier.id},
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to initialize RevenueCat',
        category: LogCategory.service,
        tag: 'SubscriptionService',
        metadata: {'error': e.toString()},
        stackTrace: stackTrace,
      );
      _updateState(_currentState.copyWith(
        isLoading: false,
        error: 'فشل تحميل الاشتراكات',
      ));
      _isInitialized = true; // Mark as initialized to prevent retries
    }
  }

  // =====================================================
  // SUBSCRIPTION STATUS
  // =====================================================

  /// Refresh subscription status from RevenueCat
  Future<void> refreshSubscriptionStatus() async {
    try {
      _updateState(_currentState.copyWith(isLoading: true, clearError: true));

      final customerInfo = await rc.Purchases.getCustomerInfo();
      final offerings = await rc.Purchases.getOfferings();

      _logger.info(
        'Offerings fetched',
        category: LogCategory.service,
        tag: 'SubscriptionService',
        metadata: {
          'hasCurrent': offerings.current != null,
          'currentId': offerings.current?.identifier,
          'allOfferingsCount': offerings.all.length,
          'packagesInCurrent': offerings.current?.availablePackages.length ?? 0,
        },
      );

      _processCustomerInfo(customerInfo, offerings);
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to refresh subscription status from RevenueCat',
        category: LogCategory.service,
        tag: 'SubscriptionService',
        metadata: {'error': e.toString()},
        stackTrace: stackTrace,
      );

      // Fallback chain: RevenueCat failed → try Cache → try Supabase → Free

      // Fallback 1: Load from local cache
      final cachedState = await _loadCachedSubscriptionState();
      if (cachedState != null) {
        _logger.info(
          'Using cached subscription state as fallback',
          category: LogCategory.service,
          tag: 'SubscriptionService',
          metadata: {'tier': cachedState.tier.id},
        );
        _updateState(cachedState.copyWith(isLoading: false));
        return;
      }

      // Fallback 2: Load from Supabase
      final supabaseState = await _loadFromSupabaseFallback();
      if (supabaseState != null) {
        _logger.info(
          'Using Supabase subscription fallback',
          category: LogCategory.service,
          tag: 'SubscriptionService',
          metadata: {'tier': supabaseState.tier.id},
        );
        _updateState(supabaseState.copyWith(isLoading: false));
        return;
      }

      // No fallback available - default to free with error
      _logger.warning(
        'All subscription fallbacks failed, defaulting to free tier',
        category: LogCategory.service,
        tag: 'SubscriptionService',
      );
      _updateState(_currentState.copyWith(
        isLoading: false,
        error: 'فشل تحميل حالة الاشتراك',
      ));
    }
  }

  void _handleCustomerInfoUpdate(rc.CustomerInfo customerInfo) {
    _logger.info(
      'Customer info updated',
      category: LogCategory.service,
      tag: 'SubscriptionService',
    );
    _processCustomerInfo(customerInfo, _currentState.offerings);
  }

  void _processCustomerInfo(rc.CustomerInfo customerInfo, rc.Offerings? offerings) {
    final entitlements = customerInfo.entitlements.active;

    // Debug: Log all active entitlements
    _logger.info(
      'Processing customer info - active entitlements: ${entitlements.keys.toList()}',
      category: LogCategory.service,
      tag: 'SubscriptionService',
      metadata: {
        'entitlementCount': entitlements.length,
        'entitlementKeys': entitlements.keys.toList(),
        'lookingForMax': SubscriptionProducts.entitlementMax,
      },
    );

    SubscriptionTier tier = SubscriptionTier.free;
    bool isTrialActive = false;
    DateTime? expirationDate;
    String? productId;

    // Check for Max entitlement (only paid tier)
    if (entitlements.containsKey(SubscriptionProducts.entitlementMax)) {
      tier = SubscriptionTier.max;
      final entitlement = entitlements[SubscriptionProducts.entitlementMax]!;
      isTrialActive = entitlement.periodType == rc.PeriodType.trial;
      // Parse expiration date from string
      final expirationStr = entitlement.expirationDate;
      if (expirationStr != null) {
        expirationDate = DateTime.tryParse(expirationStr);
      }
      productId = entitlement.productIdentifier;
    }

    // Calculate trial days remaining
    int trialDaysRemaining = 0;
    if (isTrialActive && expirationDate != null) {
      trialDaysRemaining = expirationDate.difference(DateTime.now()).inDays;
      if (trialDaysRemaining < 0) trialDaysRemaining = 0;
    }

    // Validate subscription is active: must be paid tier with valid expiration
    final isActive = tier != SubscriptionTier.free &&
        (expirationDate == null || expirationDate.isAfter(DateTime.now()));

    final newState = SubscriptionState(
      tier: tier,
      isActive: isActive,
      expirationDate: expirationDate,
      isTrialActive: isTrialActive,
      trialDaysRemaining: trialDaysRemaining,
      productId: productId,
      offerings: offerings,
      isLoading: false,
      customerInfo: customerInfo,
    );

    // Log tier change
    if (newState.tier != _currentState.tier) {
      _logger.info(
        'Subscription tier changed',
        category: LogCategory.service,
        tag: 'SubscriptionService',
        metadata: {
          'from': _currentState.tier.id,
          'to': newState.tier.id,
        },
      );
    }

    _updateState(newState);
  }

  // =====================================================
  // PURCHASES
  // =====================================================

  /// Purchase a subscription package
  Future<bool> purchase(rc.Package package) async {
    try {
      _logger.info(
        'Initiating purchase',
        category: LogCategory.service,
        tag: 'SubscriptionService',
        metadata: {'packageId': package.identifier},
      );

      final result = await rc.Purchases.purchase(rc.PurchaseParams.package(package));

      _processCustomerInfo(result.customerInfo, _currentState.offerings);

      _logger.info(
        'Purchase completed successfully',
        category: LogCategory.service,
        tag: 'SubscriptionService',
        metadata: {'tier': _currentState.tier.id},
      );

      return _currentState.tier != SubscriptionTier.free;
    } on rc.PurchasesErrorCode catch (e) {
      if (e == rc.PurchasesErrorCode.purchaseCancelledError) {
        _logger.info(
          'Purchase cancelled by user',
          category: LogCategory.service,
          tag: 'SubscriptionService',
        );
        return false;
      }

      _logger.error(
        'Purchase failed',
        category: LogCategory.service,
        tag: 'SubscriptionService',
        metadata: {'error': e.toString()},
      );

      _updateState(_currentState.copyWith(
        error: 'فشل في إتمام الشراء. يرجى المحاولة مرة أخرى.',
      ));
      return false;
    } catch (e) {
      _logger.error(
        'Purchase failed with unexpected error',
        category: LogCategory.service,
        tag: 'SubscriptionService',
        metadata: {'error': e.toString()},
      );

      _updateState(_currentState.copyWith(
        error: 'فشل في إتمام الشراء. يرجى المحاولة مرة أخرى.',
      ));
      return false;
    }
  }

  /// Restore purchases
  Future<bool> restorePurchases() async {
    try {
      _logger.info(
        'Restoring purchases',
        category: LogCategory.service,
        tag: 'SubscriptionService',
      );

      _updateState(_currentState.copyWith(isLoading: true));

      final customerInfo = await rc.Purchases.restorePurchases();
      _processCustomerInfo(customerInfo, _currentState.offerings);

      final restored = _currentState.tier != SubscriptionTier.free;

      if (restored) {
        _logger.info(
          'Purchases restored successfully',
          category: LogCategory.service,
          tag: 'SubscriptionService',
          metadata: {'tier': _currentState.tier.id},
        );
      } else {
        _logger.info(
          'No purchases to restore',
          category: LogCategory.service,
          tag: 'SubscriptionService',
        );
      }

      return restored;
    } catch (e) {
      _logger.error(
        'Restore purchases failed',
        category: LogCategory.service,
        tag: 'SubscriptionService',
        metadata: {'error': e.toString()},
      );

      _updateState(_currentState.copyWith(
        isLoading: false,
        error: 'فشل في استعادة المشتريات',
      ));
      return false;
    }
  }

  // =====================================================
  // FEATURE ACCESS
  // =====================================================

  /// Check if user has access to a specific feature
  bool hasFeatureAccess(String featureId) {
    return _currentState.hasFeatureAccess(featureId);
  }

  /// Get the reminder limit for current tier
  int get reminderLimit => _currentState.tier.reminderLimit;

  // =====================================================
  // USER MANAGEMENT
  // =====================================================

  /// Update user ID (for login)
  Future<void> setUserId(String userId) async {
    if (!_isInitialized || kIsWeb) return;

    try {
      _logger.info(
        'Setting RevenueCat user ID',
        category: LogCategory.service,
        tag: 'SubscriptionService',
      );

      await rc.Purchases.logIn(userId);
      await refreshSubscriptionStatus();
    } catch (e) {
      _logger.error(
        'Failed to set user ID',
        category: LogCategory.service,
        tag: 'SubscriptionService',
        metadata: {'error': e.toString()},
      );
    }
  }

  /// Clear user on logout
  Future<void> clearUser() async {
    if (!_isInitialized || kIsWeb) return;

    try {
      _logger.info(
        'Clearing RevenueCat user',
        category: LogCategory.service,
        tag: 'SubscriptionService',
      );

      await rc.Purchases.logOut();
      // Clear local subscription cache on logout
      await clearSubscriptionCache();
      _updateState(SubscriptionState.free());
    } catch (e) {
      _logger.error(
        'Failed to clear user',
        category: LogCategory.service,
        tag: 'SubscriptionService',
        metadata: {'error': e.toString()},
      );
    }
  }

  // =====================================================
  // SUBSCRIPTION CACHE & FALLBACK
  // =====================================================

  /// Cache subscription state locally using Hive
  Future<void> _cacheSubscriptionState(SubscriptionState state) async {
    try {
      final box = await Hive.openBox(_cacheBoxName);
      await box.put(_cacheTierKey, state.tier.id);
      await box.put(_cacheExpirationKey, state.expirationDate?.toIso8601String());
      await box.put(_cacheTimestampKey, DateTime.now().toIso8601String());
      _logger.info(
        'Subscription state cached',
        category: LogCategory.service,
        tag: 'SubscriptionService',
        metadata: {'tier': state.tier.id},
      );
    } catch (e) {
      _logger.warning(
        'Failed to cache subscription state: $e',
        category: LogCategory.service,
        tag: 'SubscriptionService',
      );
    }
  }

  /// Load cached subscription state from Hive
  Future<SubscriptionState?> _loadCachedSubscriptionState() async {
    try {
      final box = await Hive.openBox(_cacheBoxName);
      final tierStr = box.get(_cacheTierKey) as String?;
      final expirationStr = box.get(_cacheExpirationKey) as String?;
      final cachedAtStr = box.get(_cacheTimestampKey) as String?;

      if (tierStr == null) return null;

      // Check if cache is still valid (within 24 hours)
      if (cachedAtStr != null) {
        final cachedAt = DateTime.parse(cachedAtStr);
        if (DateTime.now().difference(cachedAt) > _cacheValidity) {
          _logger.info(
            'Subscription cache expired',
            category: LogCategory.service,
            tag: 'SubscriptionService',
          );
          return null; // Cache expired
        }
      }

      final tier = SubscriptionTierExtension.fromString(tierStr);
      final expirationDate = expirationStr != null ? DateTime.tryParse(expirationStr) : null;

      // Validate expiration - if subscription expired, return free tier
      if (tier != SubscriptionTier.free && expirationDate != null) {
        if (expirationDate.isBefore(DateTime.now())) {
          _logger.info(
            'Cached subscription expired, returning free tier',
            category: LogCategory.service,
            tag: 'SubscriptionService',
            metadata: {'expiredAt': expirationStr},
          );
          return SubscriptionState.free(); // Subscription expired
        }
      }

      // At this point, if tier is paid, expiration has already been validated above
      final isActive = tier != SubscriptionTier.free &&
          (expirationDate == null || expirationDate.isAfter(DateTime.now()));

      return SubscriptionState(
        tier: tier,
        isActive: isActive,
        expirationDate: expirationDate,
        isLoading: false,
      );
    } catch (e) {
      _logger.warning(
        'Failed to load cached subscription state: $e',
        category: LogCategory.service,
        tag: 'SubscriptionService',
      );
      return null;
    }
  }

  /// Fallback to Supabase subscription_status when RevenueCat fails
  Future<SubscriptionState?> _loadFromSupabaseFallback() async {
    try {
      final supabase = SupabaseConfig.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await supabase
          .from('users')
          .select('subscription_status')
          .eq('id', userId)
          .single();

      final status = response['subscription_status'] as String?;
      if (status == 'premium' || status == 'max') {
        _logger.info(
          'Supabase fallback returned premium status',
          category: LogCategory.service,
          tag: 'SubscriptionService',
          metadata: {'status': status},
        );
        return SubscriptionState(
          tier: SubscriptionTier.max,
          isActive: true,
          isLoading: false,
        );
      }
      return SubscriptionState.free();
    } catch (e) {
      _logger.warning(
        'Supabase fallback failed: $e',
        category: LogCategory.service,
        tag: 'SubscriptionService',
      );
      return null;
    }
  }

  /// Clear subscription cache (useful on logout)
  Future<void> clearSubscriptionCache() async {
    try {
      final box = await Hive.openBox(_cacheBoxName);
      await box.clear();
      _logger.info(
        'Subscription cache cleared',
        category: LogCategory.service,
        tag: 'SubscriptionService',
      );
    } catch (e) {
      _logger.warning(
        'Failed to clear subscription cache: $e',
        category: LogCategory.service,
        tag: 'SubscriptionService',
      );
    }
  }

  // =====================================================
  // HELPERS
  // =====================================================

  void _updateState(SubscriptionState state) {
    final tierChanged = state.tier != _currentState.tier;

    _logger.info(
      'Updating subscription state',
      category: LogCategory.service,
      tag: 'SubscriptionService',
      metadata: {
        'newTier': state.tier.id,
        'previousTier': _currentState.tier.id,
        'isActive': state.isActive,
        'isLoading': state.isLoading,
        'hasListeners': _stateController.hasListener,
      },
    );
    _currentState = state;
    _stateController.add(state);

    // When tier changes and not loading, sync and cache
    if (tierChanged && !state.isLoading) {
      _syncSubscriptionToSupabase(state);
      // Cache subscription state locally for offline fallback
      _cacheSubscriptionState(state);
    }
  }

  /// Force sync current subscription to Supabase (public method)
  Future<void> syncToSupabase() async {
    await _syncSubscriptionToSupabase(_currentState);
  }

  /// Sync subscription status to Supabase
  Future<void> _syncSubscriptionToSupabase(SubscriptionState state) async {
    try {
      final supabase = SupabaseConfig.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        _logger.warning(
          'Cannot sync subscription - no user logged in',
          category: LogCategory.service,
          tag: 'SubscriptionService',
        );
        return;
      }

      final status = state.tier == SubscriptionTier.max ? 'premium' : 'free';

      await supabase.from('users').update({
        'subscription_status': status,
        'trial_started_at': state.isTrialActive ? DateTime.now().toIso8601String() : null,
        'trial_used': state.isTrialActive ? false : null,
      }).eq('id', userId);

      _logger.info(
        'Subscription synced to Supabase',
        category: LogCategory.service,
        tag: 'SubscriptionService',
        metadata: {'userId': userId, 'status': status},
      );
    } catch (e) {
      _logger.error(
        'Failed to sync subscription to Supabase',
        category: LogCategory.service,
        tag: 'SubscriptionService',
        metadata: {'error': e.toString()},
      );
    }
  }

  /// Clear any error state
  void clearError() {
    _updateState(_currentState.copyWith(clearError: true));
  }

  /// Dispose resources
  void dispose() {
    _stateController.close();
  }
}
