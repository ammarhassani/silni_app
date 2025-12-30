import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/supabase_config.dart';
import '../constants/onboarding_content.dart';
import '../models/onboarding_state.dart';

/// Provider for onboarding storage service
final onboardingStorageProvider = Provider<OnboardingStorageService>((ref) {
  return OnboardingStorageService();
});

/// Service for persisting onboarding state
/// Handles local (SharedPreferences) and cloud (Supabase) storage
class OnboardingStorageService {
  /// Load onboarding state from local storage first, then sync with cloud
  /// Returns the most recent state between local and cloud
  Future<OnboardingState?> loadState() async {
    // 1. Load from local storage (instant)
    final localState = await _loadFromLocal();

    // 2. Fetch from Supabase (background)
    final cloudState = await _fetchFromSupabase();

    // 3. Merge - use most recent
    if (cloudState != null && localState != null) {
      final cloudTime = cloudState.completedAt ?? cloudState.startedAt;
      final localTime = localState.completedAt ?? localState.startedAt;

      if (cloudTime != null && localTime != null) {
        if (cloudTime.isAfter(localTime)) {
          // Cloud is newer, save to local
          await _saveToLocal(cloudState);
          return cloudState;
        }
      } else if (cloudTime != null) {
        // Only cloud has timestamp
        await _saveToLocal(cloudState);
        return cloudState;
      }
    }

    // Return local state if no cloud state, or cloud state if no local
    return localState ?? cloudState;
  }

  /// Save state to both local and cloud storage
  Future<void> saveState(OnboardingState state) async {
    // Save to local storage (synchronous feel)
    await _saveToLocal(state);

    // Sync to cloud (background, don't await)
    _syncToSupabase(state);
  }

  /// Clear all onboarding state (for testing/reset)
  Future<void> clearState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(OnboardingContent.localStorageKey);
  }

  // =====================================================
  // LOCAL STORAGE
  // =====================================================

  Future<OnboardingState?> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(OnboardingContent.localStorageKey);

      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }

      return OnboardingState.fromJsonString(jsonString);
    } catch (e) {
      debugPrint('[OnboardingStorage] Failed to load from local: $e');
      return null;
    }
  }

  Future<void> _saveToLocal(OnboardingState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        OnboardingContent.localStorageKey,
        state.toJsonString(),
      );
    } catch (e) {
      debugPrint('[OnboardingStorage] Failed to save to local: $e');
    }
  }

  // =====================================================
  // CLOUD STORAGE (SUPABASE)
  // =====================================================

  Future<OnboardingState?> _fetchFromSupabase() async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        debugPrint('[OnboardingStorage] No user ID for cloud fetch');
        return null;
      }

      final response = await SupabaseConfig.client
          .from('users')
          .select(OnboardingContent.supabaseColumn)
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        debugPrint('[OnboardingStorage] No user record found');
        return null;
      }

      final metadata = response[OnboardingContent.supabaseColumn];
      if (metadata == null || metadata is! Map<String, dynamic>) {
        return null;
      }

      if (metadata.isEmpty) {
        return null;
      }

      return OnboardingState.fromJson(metadata);
    } catch (e) {
      debugPrint('[OnboardingStorage] Failed to fetch from Supabase: $e');
      return null;
    }
  }

  Future<void> _syncToSupabase(OnboardingState state) async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        debugPrint('[OnboardingStorage] No user ID for cloud sync');
        return;
      }

      await SupabaseConfig.client.from('users').update({
        OnboardingContent.supabaseColumn: state.toJson(),
      }).eq('id', userId);

      debugPrint('[OnboardingStorage] Synced to Supabase successfully');
    } catch (e) {
      debugPrint('[OnboardingStorage] Failed to sync to Supabase: $e');
      // Don't throw - cloud sync is best effort
    }
  }

  // =====================================================
  // CONTEXTUAL TIPS STORAGE
  // =====================================================

  static const String _dismissedTipsKey = 'premium_onboarding_dismissed_tips';

  /// Load dismissed tips from local storage
  Future<Map<String, bool>> loadDismissedTips() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_dismissedTipsKey);

      if (jsonString == null || jsonString.isEmpty) {
        return {};
      }

      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as bool));
    } catch (e) {
      debugPrint('[OnboardingStorage] Failed to load dismissed tips: $e');
      return {};
    }
  }

  /// Save dismissed tips to local storage
  Future<void> saveDismissedTips(Map<String, bool> dismissedTips) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dismissedTipsKey, jsonEncode(dismissedTips));
    } catch (e) {
      debugPrint('[OnboardingStorage] Failed to save dismissed tips: $e');
    }
  }
}
