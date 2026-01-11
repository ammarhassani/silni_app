import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
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

      // Debug: Log API key status (first 10 chars only for security)
      final keyPreview = apiKey.length > 10 ? '${apiKey.substring(0, 10)}...' : apiKey;
      debugPrint('🔑 RevenueCat API Key: $keyPreview (${apiKey.length} chars)');

      // Check if API key is configured
      if (apiKey.isEmpty) {
        _logger.warning(
          'RevenueCat API key not configured',
          category: LogCategory.service,
          tag: 'SubscriptionService',
        );
        debugPrint('❌ RevenueCat API key is EMPTY! Check .env and run build_runner');
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
      debugPrint('🔑 RevenueCat App User ID: ${customerInfo.originalAppUserId}');
      debugPrint('🔑 Active Entitlements: ${customerInfo.entitlements.active.keys.toList()}');
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

      // Debug: Log offerings details
      debugPrint('📦 Offerings fetch result:');
      debugPrint('  - current offering: ${offerings.current?.identifier ?? "NULL"}');
      debugPrint('  - all offerings count: ${offerings.all.length}');
      for (final entry in offerings.all.entries) {
        debugPrint('  - Offering "${entry.key}": ${entry.value.availablePackages.length} packages');
        for (final pkg in entry.value.availablePackages) {
          debugPrint('    - Package: ${pkg.identifier} -> ${pkg.storeProduct.identifier}');
        }
      }
      if (offerings.current != null) {
        debugPrint('  - Current offering packages:');
        for (final pkg in offerings.current!.availablePackages) {
          debugPrint('    - ${pkg.identifier}: ${pkg.storeProduct.identifier} (${pkg.storeProduct.priceString})');
        }
      } else {
        debugPrint('  ⚠️ NO CURRENT OFFERING SET! Check RevenueCat dashboard.');
      }

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
        'Failed to refresh subscription status',
        category: LogCategory.service,
        tag: 'SubscriptionService',
        metadata: {'error': e.toString()},
        stackTrace: stackTrace,
      );
      debugPrint('❌ Failed to refresh subscription: $e');
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

    final newState = SubscriptionState(
      tier: tier,
      isActive: tier != SubscriptionTier.free,
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

      // Debug: Log all entitlements received after purchase
      debugPrint('🎫 Purchase result - All entitlements: ${result.customerInfo.entitlements.all.keys.toList()}');
      debugPrint('🎫 Purchase result - Active entitlements: ${result.customerInfo.entitlements.active.keys.toList()}');
      debugPrint('🎫 Looking for MAX: "${SubscriptionProducts.entitlementMax}"');

      _processCustomerInfo(result.customerInfo, _currentState.offerings);

      _logger.info(
        'Purchase completed successfully',
        category: LogCategory.service,
        tag: 'SubscriptionService',
        metadata: {'tier': _currentState.tier.id},
      );

      debugPrint('✅ Purchase complete - New tier: ${_currentState.tier.id}');

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

    // Sync to Supabase when tier changes (and not loading)
    if (tierChanged && !state.isLoading) {
      _syncSubscriptionToSupabase(state);
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
