import 'package:purchases_flutter/purchases_flutter.dart' as rc;

import 'subscription_tier.dart';

/// Represents the current subscription state
class SubscriptionState {
  /// Current subscription tier
  final SubscriptionTier tier;

  /// Whether subscription is currently active
  final bool isActive;

  /// Subscription expiration date (null for free tier)
  final DateTime? expirationDate;

  /// Whether user is in trial period
  final bool isTrialActive;

  /// Days remaining in trial
  final int trialDaysRemaining;

  /// Current product ID (null for free tier)
  final String? productId;

  /// Available offerings from RevenueCat
  final rc.Offerings? offerings;

  /// Whether subscription state is loading
  final bool isLoading;

  /// Error message if any
  final String? error;

  /// Raw customer info from RevenueCat
  final rc.CustomerInfo? customerInfo;

  const SubscriptionState({
    this.tier = SubscriptionTier.free,
    this.isActive = false,
    this.expirationDate,
    this.isTrialActive = false,
    this.trialDaysRemaining = 0,
    this.productId,
    this.offerings,
    this.isLoading = true,
    this.error,
    this.customerInfo,
  });

  /// Create initial loading state
  factory SubscriptionState.loading() {
    return const SubscriptionState(isLoading: true);
  }

  /// Create free tier state
  factory SubscriptionState.free() {
    return const SubscriptionState(
      tier: SubscriptionTier.free,
      isActive: false,
      isLoading: false,
    );
  }

  /// Create error state
  factory SubscriptionState.error(String message) {
    return SubscriptionState(
      tier: SubscriptionTier.free,
      isLoading: false,
      error: message,
    );
  }

  /// Create a copy with updated fields
  SubscriptionState copyWith({
    SubscriptionTier? tier,
    bool? isActive,
    DateTime? expirationDate,
    bool? isTrialActive,
    int? trialDaysRemaining,
    String? productId,
    rc.Offerings? offerings,
    bool? isLoading,
    String? error,
    rc.CustomerInfo? customerInfo,
    bool clearError = false,
    bool clearExpiration = false,
    bool clearProductId = false,
  }) {
    return SubscriptionState(
      tier: tier ?? this.tier,
      isActive: isActive ?? this.isActive,
      expirationDate: clearExpiration ? null : (expirationDate ?? this.expirationDate),
      isTrialActive: isTrialActive ?? this.isTrialActive,
      trialDaysRemaining: trialDaysRemaining ?? this.trialDaysRemaining,
      productId: clearProductId ? null : (productId ?? this.productId),
      offerings: offerings ?? this.offerings,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      customerInfo: customerInfo ?? this.customerInfo,
    );
  }

  // =====================================================
  // CONVENIENCE GETTERS
  // =====================================================

  /// Whether user has MAX subscription (paid tier)
  bool get isMax => tier.isMax;

  /// Whether user has any paid subscription (active or trial)
  bool get hasPaidAccess => isActive || isTrialActive;

  /// Whether subscription is expiring soon (within 3 days)
  bool get isExpiringSoon {
    if (expirationDate == null) return false;
    final daysUntilExpiry = expirationDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 3 && daysUntilExpiry >= 0;
  }

  /// Days until subscription expires (-1 if no expiration)
  int get daysUntilExpiry {
    if (expirationDate == null) return -1;
    return expirationDate!.difference(DateTime.now()).inDays;
  }

  /// Whether this is an annual subscription
  bool get isAnnual {
    if (productId == null) return false;
    return SubscriptionProducts.isAnnual(productId!);
  }

  /// Get formatted expiration date
  String? get formattedExpirationDate {
    if (expirationDate == null) return null;
    return '${expirationDate!.year}/${expirationDate!.month}/${expirationDate!.day}';
  }

  /// Get Arabic formatted expiration date
  String? get arabicFormattedExpirationDate {
    if (expirationDate == null) return null;
    final months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${expirationDate!.day} ${months[expirationDate!.month - 1]} ${expirationDate!.year}';
  }

  // =====================================================
  // FEATURE ACCESS
  // =====================================================

  /// Check if user has access to a specific feature
  ///
  /// Uses [SubscriptionTier.hasFeature] which delegates to
  /// [FeatureConfigService] for admin-configured feature access.
  bool hasFeatureAccess(String featureId) {
    return tier.hasFeature(featureId);
  }

  @override
  String toString() {
    return 'SubscriptionState(tier: ${tier.id}, isActive: $isActive, '
           'isTrialActive: $isTrialActive, isLoading: $isLoading)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubscriptionState &&
        other.tier == tier &&
        other.isActive == isActive &&
        other.expirationDate == expirationDate &&
        other.isTrialActive == isTrialActive &&
        other.trialDaysRemaining == trialDaysRemaining &&
        other.productId == productId &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode {
    return Object.hash(
      tier,
      isActive,
      expirationDate,
      isTrialActive,
      trialDaysRemaining,
      productId,
      isLoading,
      error,
    );
  }
}
