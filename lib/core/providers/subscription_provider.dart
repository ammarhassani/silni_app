import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;

import '../models/subscription_tier.dart';
import '../models/subscription_state.dart';
import '../services/subscription_service.dart';
import '../services/feature_config_service.dart';

/// Provider for subscription service singleton
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService.instance;
});

/// Stream provider for subscription state (reactive)
final subscriptionStateProvider = StreamProvider<SubscriptionState>((ref) {
  final service = ref.watch(subscriptionServiceProvider);

  // Create a stream that emits current state first, then continues with updates
  // This avoids the race condition in the previous asyncExpand implementation
  return Stream<SubscriptionState>.multi((controller) {
    // Emit current state immediately
    debugPrint('[SubscriptionProvider] Emitting initial state: ${service.currentState.tier.id}');
    controller.add(service.currentState);

    // Listen to future updates
    final subscription = service.stateStream.listen(
      (state) {
        debugPrint('[SubscriptionProvider] Received stream update: ${state.tier.id}');
        controller.add(state);
      },
      onError: controller.addError,
      onDone: controller.close,
    );

    // Cleanup when provider is disposed
    controller.onCancel = () {
      debugPrint('[SubscriptionProvider] Stream cancelled');
      subscription.cancel();
    };
  });
});

/// Provider for current subscription tier
final subscriptionTierProvider = Provider<SubscriptionTier>((ref) {
  final stateAsync = ref.watch(subscriptionStateProvider);
  return stateAsync.when(
    data: (state) => state.tier,
    loading: () => SubscriptionTier.free,
    error: (_, __) => SubscriptionTier.free,
  );
});

/// Provider for checking if user has MAX tier (paid)
final isMaxProvider = Provider<bool>((ref) {
  final tier = ref.watch(subscriptionTierProvider);
  return tier == SubscriptionTier.max;
});

/// Provider for trial status
final isTrialActiveProvider = Provider<bool>((ref) {
  final stateAsync = ref.watch(subscriptionStateProvider);
  return stateAsync.when(
    data: (state) => state.isTrialActive,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider for trial days remaining
final trialDaysRemainingProvider = Provider<int>((ref) {
  final stateAsync = ref.watch(subscriptionStateProvider);
  return stateAsync.when(
    data: (state) => state.trialDaysRemaining,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for available offerings
final offeringsProvider = Provider<rc.Offerings?>((ref) {
  final stateAsync = ref.watch(subscriptionStateProvider);
  return stateAsync.when(
    data: (state) => state.offerings,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider for subscription loading state
final subscriptionLoadingProvider = Provider<bool>((ref) {
  final stateAsync = ref.watch(subscriptionStateProvider);
  return stateAsync.when(
    data: (state) => state.isLoading,
    loading: () => true,
    error: (_, __) => false,
  );
});

/// Provider for subscription error
final subscriptionErrorProvider = Provider<String?>((ref) {
  final stateAsync = ref.watch(subscriptionStateProvider);
  return stateAsync.when(
    data: (state) => state.error,
    loading: () => null,
    error: (e, __) => e.toString(),
  );
});

/// Family provider for feature access
/// Uses dynamic configuration from admin panel (admin_features table)
/// Falls back to hardcoded logic if config not loaded
/// Usage: ref.watch(featureAccessProvider('ai_chat'))
final featureAccessProvider = Provider.family<bool, String>((ref, featureId) {
  final tier = ref.watch(subscriptionTierProvider);
  final configService = FeatureConfigService.instance;

  // Use sync method that checks cached config
  // Falls back to hardcoded logic if config not yet loaded
  return configService.hasFeatureAccessSync(featureId, tier.id);
});

/// Provider for reminder limit
final reminderLimitProvider = Provider<int>((ref) {
  final tier = ref.watch(subscriptionTierProvider);
  return tier.reminderLimit;
});

/// Provider for expiration date
final subscriptionExpirationProvider = Provider<DateTime?>((ref) {
  final stateAsync = ref.watch(subscriptionStateProvider);
  return stateAsync.when(
    data: (state) => state.expirationDate,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider for checking if subscription is expiring soon
final isExpiringProvider = Provider<bool>((ref) {
  final stateAsync = ref.watch(subscriptionStateProvider);
  return stateAsync.when(
    data: (state) => state.isExpiringSoon,
    loading: () => false,
    error: (_, __) => false,
  );
});
