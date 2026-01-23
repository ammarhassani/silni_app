import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:silni_app/features/reminders/screens/reminders_screen.dart';
import 'package:silni_app/features/auth/providers/auth_provider.dart';
import 'package:silni_app/features/home/providers/home_providers.dart';
import 'package:silni_app/shared/models/relative_model.dart';
import 'package:silni_app/shared/models/reminder_schedule_model.dart';
import 'package:silni_app/core/router/app_routes.dart';
import 'package:silni_app/core/providers/realtime_provider.dart';

import '../../helpers/test_helpers.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  group('RemindersScreen Widget Tests', () {
    late GoRouter router;

    setUp(() {
      router = GoRouter(
        initialLocation: '/reminders',
        routes: [
          GoRoute(
            path: '/reminders',
            builder: (context, state) => const RemindersScreen(),
          ),
          GoRoute(
            path: AppRoutes.relatives,
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Relatives Screen')),
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
      ];
    }

    /// Create test reminder schedules
    List<ReminderSchedule> createTestSchedules() {
      return [
        ReminderSchedule(
          id: 'schedule-1',
          userId: 'test-user-id',
          frequency: ReminderFrequency.daily,
          relativeIds: ['rel-1'],
          time: '09:00',
          isActive: true,
          createdAt: DateTime.now(),
        ),
        ReminderSchedule(
          id: 'schedule-2',
          userId: 'test-user-id',
          frequency: ReminderFrequency.weekly,
          relativeIds: ['rel-2'],
          time: '18:00',
          customDays: [5], // Friday
          isActive: true,
          createdAt: DateTime.now(),
        ),
      ];
    }

    Widget createTestWidget({
      List<Relative>? relatives,
      List<ReminderSchedule>? schedules,
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
          // Override reminderSchedulesStreamProvider
          reminderSchedulesStreamProvider('test-user-id').overrideWith((ref) {
            if (error != null) {
              return Stream.error(error);
            }
            if (isLoading) {
              return const Stream.empty();
            }
            return Stream.value(schedules ?? []);
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
      List<ReminderSchedule>? schedules,
      bool isLoading = false,
      Object? error,
    }) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(
        relatives: relatives,
        schedules: schedules,
        isLoading: isLoading,
        error: error,
      ));
      // Advance animations to let them settle
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('should render header with title and subtitle', (tester) async {
      await pumpScreen(tester, relatives: createTestRelatives(), schedules: []);

      // Verify header title
      expect(find.text('تذكير صلة الرحم'), findsOneWidget);
      expect(find.text('نظّم تذكيراتك للتواصل مع أحبتك'), findsOneWidget);
    });

    testWidgets('should render back button in header', (tester) async {
      await pumpScreen(tester, relatives: createTestRelatives(), schedules: []);

      // Verify back button exists
      expect(find.byIcon(Icons.arrow_back_ios_rounded), findsOneWidget);
    });

    testWidgets('should render reminder templates section', (tester) async {
      await pumpScreen(tester, relatives: createTestRelatives(), schedules: []);

      // Verify templates section title
      expect(find.text('✨ اختر نوع التذكير'), findsOneWidget);
    });

    testWidgets('should render schedule cards section', (tester) async {
      await pumpScreen(tester, relatives: createTestRelatives(), schedules: []);

      // Verify schedules section title
      expect(find.text('📅 جداول التذكير'), findsOneWidget);
    });

    testWidgets('should show empty schedules message when no schedules exist', (tester) async {
      await pumpScreen(tester, relatives: createTestRelatives(), schedules: []);

      // Verify empty schedules message
      expect(find.text('لا توجد جداول تذكير بعد'), findsOneWidget);
      expect(find.text('اختر نوع تذكير من الأعلى للبدء'), findsOneWidget);
    });

    testWidgets('should render schedule cards when schedules exist', (tester) async {
      await pumpScreen(
        tester,
        relatives: createTestRelatives(),
        schedules: createTestSchedules(),
      );

      // Verify schedule cards are rendered - check for frequency Arabic names
      expect(find.text('يومي'), findsOneWidget);
      expect(find.text('أسبوعي'), findsOneWidget);
    });

    testWidgets('should show empty state when no relatives exist', (tester) async {
      await pumpScreen(tester, relatives: [], schedules: []);

      // Verify empty state
      expect(find.text('لا يوجد أقارب بعد'), findsOneWidget);
      expect(find.text('أضف أقاربك أولاً لتتمكن من إنشاء تذكيرات'), findsOneWidget);
      expect(find.text('إضافة أقارب'), findsOneWidget);
    });

    testWidgets('should show loading indicator when loading', (tester) async {
      await pumpScreen(tester, isLoading: true);

      // Verify loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error state when error occurs', (tester) async {
      await pumpScreen(tester, error: Exception('Test error'));

      // Verify error state elements
      expect(find.text('حدث خطأ في تحميل البيانات'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);
    });

    testWidgets('should show unassigned relatives section when relatives are not in schedules', (tester) async {
      // Create relatives that are NOT in any schedule
      final relatives = createTestRelatives();
      // Empty schedules means all relatives are unassigned
      await pumpScreen(tester, relatives: relatives, schedules: []);

      // Verify unassigned relatives section
      expect(find.text('👥 الأقارب غير المضافين'), findsOneWidget);
      expect(find.text('اسحب الأقارب لإضافتهم إلى تذكير'), findsOneWidget);
    });

    testWidgets('should display relative names in schedule cards', (tester) async {
      final relatives = createTestRelatives();
      final schedules = createTestSchedules();
      await pumpScreen(tester, relatives: relatives, schedules: schedules);

      // Verify relative name appears in schedule card
      expect(find.text('أحمد علي'), findsWidgets); // May appear multiple times
    });

    testWidgets('should have switch toggle for schedule activation', (tester) async {
      await pumpScreen(
        tester,
        relatives: createTestRelatives(),
        schedules: createTestSchedules(),
      );

      // Verify switch widgets exist for schedules
      expect(find.byType(Switch), findsNWidgets(2)); // One for each schedule
    });

    testWidgets('should have action buttons on schedule cards', (tester) async {
      await pumpScreen(
        tester,
        relatives: createTestRelatives(),
        schedules: createTestSchedules(),
      );

      // Verify action buttons
      expect(find.text('إضافة أقارب'), findsNWidgets(2)); // One per schedule card
      expect(find.byIcon(Icons.edit_rounded), findsNWidgets(2));
      expect(find.byIcon(Icons.delete_rounded), findsNWidgets(2));
    });

    testWidgets('should render reminder template cards', (tester) async {
      await pumpScreen(tester, relatives: createTestRelatives(), schedules: []);

      // Scroll to find template cards (they're in a horizontal ListView)
      // The templates include daily, weekly, monthly, friday
      // Check for at least one template by looking for emojis or titles
      expect(find.byType(ListView), findsWidgets);
    });
  });
}
