import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Test helpers and utilities for Silni app tests
///
/// This file contains common test utilities, mock classes,
/// and helper functions used across multiple test files.

// ========================================
// Mock Classes
// ========================================

/// Mock Supabase Client for testing
class MockSupabaseClient extends Mock implements SupabaseClient {}

/// Mock Supabase Query Builder
class MockSupabaseQueryBuilder extends Mock implements PostgrestQueryBuilder {}

/// Mock Supabase Filter Builder
class MockSupabaseFilterBuilder extends Mock implements PostgrestFilterBuilder {}

/// Mock Auth Client
class MockGoTrueClient extends Mock implements GoTrueClient {}

/// Mock User
class MockUser extends Mock implements User {}

/// Mock Auth Response
class MockAuthResponse extends Mock implements AuthResponse {}

// ========================================
// Test Data Factories
// ========================================

/// Create a test relative map
Map<String, dynamic> createTestRelativeMap({
  String? id,
  String? userId,
  String? fullName,
  String? relationshipType,
}) {
  return {
    'id': id ?? 'test-relative-id',
    'user_id': userId ?? 'test-user-id',
    'full_name': fullName ?? 'Test Relative',
    'relationship_type': relationshipType ?? 'brother',
    'gender': 'male',
    'avatar_type': 'adult_man',
    'date_of_birth': null,
    'phone_number': '+1234567890',
    'email': 'test@example.com',
    'address': null,
    'city': null,
    'country': null,
    'photo_url': null,
    'notes': null,
    'tags': <String>[],
    'priority': 2,
    'islamic_importance': null,
    'preferred_contact_method': null,
    'best_time_to_contact': null,
    'interaction_count': 0,
    'last_contact_date': null,
    'health_status': null,
    'is_archived': false,
    'is_favorite': false,
    'contact_id': null,
    'created_at': DateTime.now().toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
  };
}

/// Create a test interaction map
Map<String, dynamic> createTestInteractionMap({
  String? id,
  String? userId,
  String? relativeId,
  String? type,
}) {
  return {
    'id': id ?? 'test-interaction-id',
    'user_id': userId ?? 'test-user-id',
    'relative_id': relativeId ?? 'test-relative-id',
    'interaction_type': type ?? 'call',
    'interaction_date': DateTime.now().toIso8601String(),
    'duration': 30,
    'location': null,
    'notes': 'Test interaction notes',
    'mood': 'positive',
    'rating': 5,
    'photo_urls': <String>[],
    'audio_note_url': null,
    'tags': <String>[],
    'is_recurring': false,
    'created_at': DateTime.now().toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
  };
}

/// Create a test user
User createTestUser({
  String? id,
  String? email,
}) {
  final user = MockUser();
  when(() => user.id).thenReturn(id ?? 'test-user-id');
  when(() => user.email).thenReturn(email ?? 'test@example.com');
  when(() => user.createdAt).thenReturn(DateTime.now().toIso8601String());
  return user;
}

// ========================================
// Test Utilities
// ========================================

/// Pump widget with MaterialApp wrapper
Future<void> pumpTestWidget(
  WidgetTester tester,
  Widget widget, {
  Duration? duration,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: widget,
    ),
  );

  if (duration != null) {
    await tester.pumpAndSettle(duration);
  }
}

/// Wait for async operations to complete
Future<void> waitForAsync() async {
  await Future.delayed(const Duration(milliseconds: 100));
}

/// Verify that a function throws a specific exception
void expectThrows<T extends Object>(
  Function() function, {
  String? message,
}) {
  expect(
    () => function(),
    throwsA(isA<T>()),
    reason: message,
  );
}

// ========================================
// Matcher Extensions
// ========================================

/// Custom matchers for common test scenarios

/// Matcher for checking if a map contains specific keys
Matcher containsKeys(List<String> keys) {
  return predicate<Map>(
    (map) => keys.every((key) => map.containsKey(key)),
    'contains keys: ${keys.join(", ")}',
  );
}

/// Matcher for valid ISO 8601 date strings
final Matcher isValidIso8601Date = predicate<String>(
  (value) {
    try {
      DateTime.parse(value);
      return true;
    } catch (_) {
      return false;
    }
  },
  'is a valid ISO 8601 date string',
);

/// Matcher for non-empty strings
final Matcher isNonEmptyString = predicate<String>(
  (value) => value.isNotEmpty,
  'is a non-empty string',
);
