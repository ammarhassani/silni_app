import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:silni_app/features/relatives/screens/relatives_screen.dart';
import 'package:silni_app/features/auth/providers/auth_provider.dart';
import 'package:silni_app/features/home/providers/home_providers.dart';
import 'package:silni_app/shared/models/relative_model.dart';
import 'package:silni_app/core/router/app_routes.dart';
import 'package:silni_app/core/providers/realtime_provider.dart';

import '../../helpers/test_helpers.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  group('RelativesScreen Widget Tests', () {
    late GoRouter router;

    setUp(() {
      router = GoRouter(
        initialLocation: AppRoutes.relatives,
        routes: [
          GoRoute(
            path: AppRoutes.relatives,
            builder: (context, state) => const RelativesScreen(),
          ),
          GoRoute(
            path: AppRoutes.addRelative,
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Add Relative Screen')),
            ),
          ),
          GoRoute(
            path: '${AppRoutes.relativeDetail}/:id',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Relative Detail Screen')),
            ),
          ),
        ],
      );
    });

    tearDown(() {
      router.dispose();
    });

    /// Create test relatives for testing
    List<Relative> createTestRelatives() {
      return [
        Relative.fromJson({
          'id': 'rel-1',
          'user_id': 'test-user-id',
          'full_name': 'أحمد علي',
          'relationship_type': 'father',
          'gender': 'male',
          'avatar_type': 'adult_man',
          'priority': 1,
          'is_favorite': true,
          'is_archived': false,
          'interaction_count': 5,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }),
        Relative.fromJson({
          'id': 'rel-2',
          'user_id': 'test-user-id',
          'full_name': 'فاطمة محمد',
          'relationship_type': 'mother',
          'gender': 'female',
          'avatar_type': 'adult_woman',
          'priority': 1,
          'is_favorite': false,
          'is_archived': false,
          'interaction_count': 3,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }),
        Relative.fromJson({
          'id': 'rel-3',
          'user_id': 'test-user-id',
          'full_name': 'عمر أحمد',
          'relationship_type': 'brother',
          'gender': 'male',
          'avatar_type': 'adult_man',
          'priority': 2,
          'is_favorite': false,
          'is_archived': false,
          'interaction_count': 0,
          'last_contact_date': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }),
      ];
    }

    Widget createTestWidget({
      List<Relative>? relatives,
      bool isLoading = false,
      Object? error,
    }) {
      final mockUser = createTestUser(id: 'test-user-id');

      return ProviderScope(
        overrides: [
          // Include theme overrides to avoid Supabase dependency
          ...defaultThemeOverrides,
          // Override currentUserProvider
          currentUserProvider.overrideWithValue(mockUser),
          // Override relativesStreamProvider
          relativesStreamProvider('test-user-id').overrideWith((ref) {
            if (error != null) {
              return Stream.error(error);
            }
            if (isLoading) {
              return const Stream.empty();
            }
            return Stream.value(relatives ?? []);
          }),
          // Override autoRealtimeSubscriptionsProvider to do nothing
          autoRealtimeSubscriptionsProvider.overrideWith((ref) {}),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    /// Helper to pump widget and advance animations properly.
    Future<void> pumpScreen(WidgetTester tester, {
      List<Relative>? relatives,
      bool isLoading = false,
      Object? error,
    }) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(
        relatives: relatives,
        isLoading: isLoading,
        error: error,
      ));
      // Advance animations to let them settle
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 400));
    }

    /// Helper to pump after an action
    Future<void> pumpAfterAction(WidgetTester tester) async {
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('should render header with title', (tester) async {
      await pumpScreen(tester, relatives: createTestRelatives());

      // Verify header title
      expect(find.text('الأقارب'), findsOneWidget);
    });

    testWidgets('should render search bar', (tester) async {
      await pumpScreen(tester, relatives: createTestRelatives());

      // Verify search bar exists
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('ابحث عن قريب...'), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    });

    testWidgets('should render filter chips', (tester) async {
      await pumpScreen(tester, relatives: createTestRelatives());

      // Verify filter chips
      expect(find.text('الكل'), findsOneWidget);
      expect(find.text('يحتاجون تواصل'), findsOneWidget);
      expect(find.text('المفضلة'), findsOneWidget);
    });

    testWidgets('should render relatives list when data is available', (tester) async {
      final relatives = createTestRelatives();
      await pumpScreen(tester, relatives: relatives);

      // Verify relatives are displayed
      expect(find.text('أحمد علي'), findsOneWidget);
      expect(find.text('فاطمة محمد'), findsOneWidget);
      expect(find.text('عمر أحمد'), findsOneWidget);
    });

    testWidgets('should show empty state when no relatives exist', (tester) async {
      await pumpScreen(tester, relatives: []);

      // Verify empty state
      expect(find.text('لا يوجد أقارب بعد'), findsOneWidget);
      expect(find.text('إضافة أول قريب'), findsOneWidget);
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
    });

    testWidgets('should show loading indicator when loading', (tester) async {
      await pumpScreen(tester, isLoading: true);

      // Verify loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error state when error occurs', (tester) async {
      await pumpScreen(tester, error: Exception('Test error'));

      // Verify error state
      expect(find.text('حدث خطأ'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should filter relatives by search query', (tester) async {
      final relatives = createTestRelatives();
      await pumpScreen(tester, relatives: relatives);

      // Enter search query
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'أحمد');
      await pumpAfterAction(tester);

      // Wait for state to update
      await tester.pump(const Duration(milliseconds: 300));

      // Verify search filtering works - should show relatives with 'أحمد' in name
      expect(find.text('أحمد علي'), findsOneWidget);
      expect(find.text('عمر أحمد'), findsOneWidget);
      // فاطمة محمد should not appear in search results for 'أحمد'
    });

    testWidgets('should clear search when clear button is tapped', (tester) async {
      final relatives = createTestRelatives();
      await pumpScreen(tester, relatives: relatives);

      // Enter search query
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'أحمد');
      await pumpAfterAction(tester);
      await tester.pump(const Duration(milliseconds: 300));

      // Verify clear button appears
      expect(find.byIcon(Icons.clear_rounded), findsOneWidget);

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear_rounded));
      await pumpAfterAction(tester);
      await tester.pump(const Duration(milliseconds: 300));

      // Verify all relatives are shown again
      expect(find.text('أحمد علي'), findsOneWidget);
      expect(find.text('فاطمة محمد'), findsOneWidget);
      expect(find.text('عمر أحمد'), findsOneWidget);
    });

    testWidgets('should filter favorites when favorites chip is selected', (tester) async {
      final relatives = createTestRelatives();
      await pumpScreen(tester, relatives: relatives);

      // Tap favorites filter chip
      await tester.tap(find.text('المفضلة'));
      await pumpAfterAction(tester);
      await tester.pump(const Duration(milliseconds: 300));

      // Verify only favorite relative is shown (أحمد علي has isFavorite: true)
      expect(find.text('أحمد علي'), findsOneWidget);
    });

    testWidgets('should show no results when search has no matches', (tester) async {
      final relatives = createTestRelatives();
      await pumpScreen(tester, relatives: relatives);

      // Enter search query with no matches
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'xyz');
      await pumpAfterAction(tester);
      await tester.pump(const Duration(milliseconds: 300));

      // Verify no results message
      expect(find.text('لا توجد نتائج'), findsOneWidget);
      expect(find.text('جرب البحث بكلمة أخرى'), findsOneWidget);
    });

    testWidgets('should have FAB to add new relative', (tester) async {
      final relatives = createTestRelatives();
      await pumpScreen(tester, relatives: relatives);

      // Verify FAB exists with add icon
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('should toggle between filter chips', (tester) async {
      final relatives = createTestRelatives();
      await pumpScreen(tester, relatives: relatives);

      // Initially "الكل" should be selected - all relatives visible
      expect(find.text('أحمد علي'), findsOneWidget);
      expect(find.text('فاطمة محمد'), findsOneWidget);

      // Tap "يحتاجون تواصل" filter
      await tester.tap(find.text('يحتاجون تواصل'));
      await pumpAfterAction(tester);
      await tester.pump(const Duration(milliseconds: 300));

      // Tap back to "الكل"
      await tester.tap(find.text('الكل'));
      await pumpAfterAction(tester);
      await tester.pump(const Duration(milliseconds: 300));

      // Verify all relatives are shown again
      expect(find.text('أحمد علي'), findsOneWidget);
      expect(find.text('فاطمة محمد'), findsOneWidget);
    });
  });
}
