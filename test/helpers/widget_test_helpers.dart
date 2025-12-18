import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:silni_app/core/router/app_routes.dart';
import 'package:silni_app/features/home/screens/home_screen.dart';
import 'package:silni_app/features/relatives/screens/relatives_screen.dart';
import 'package:silni_app/features/profile/screens/profile_screen.dart';

// =====================================================
// TEST WIDGET WRAPPER
// =====================================================

/// Creates a test widget wrapped with necessary providers
Widget createTestWidget({
  required Widget child,
  List<Override>? overrides,
  GoRouter? router,
  ThemeData? theme,
  Locale locale = const Locale('ar'),
}) {
  final widget = MaterialApp(
    locale: locale,
    theme: theme ?? _createTestTheme(),
    home: child,
  );

  if (router != null) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp.router(
        routerConfig: router,
        locale: locale,
        theme: theme ?? _createTestTheme(),
      ),
    );
  }

  return ProviderScope(
    overrides: overrides ?? [],
    child: widget,
  );
}

/// Creates a test widget with a Scaffold wrapper
Widget createTestScaffold({
  required Widget body,
  List<Override>? overrides,
  AppBar? appBar,
  Widget? floatingActionButton,
  Widget? bottomNavigationBar,
}) {
  return createTestWidget(
    overrides: overrides,
    child: Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    ),
  );
}

/// Create default test theme
ThemeData _createTestTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4CAF50),
      brightness: Brightness.light,
    ),
    fontFamily: 'Cairo',
  );
}

// =====================================================
// MOCK ROUTER HELPERS
// =====================================================

/// Creates a simple mock router for testing navigation
GoRouter createMockRouter({
  String initialLocation = AppRoutes.home,
  Map<String, Widget Function(BuildContext, GoRouterState)>? routeBuilders,
}) {
  final defaultBuilders = <String, Widget Function(BuildContext, GoRouterState)>{
    AppRoutes.home: (context, state) => const HomeScreen(),
    AppRoutes.relatives: (context, state) => const RelativesScreen(),
    AppRoutes.profile: (context, state) => const ProfileScreen(),
    AppRoutes.login: (context, state) => const Scaffold(
      body: Center(child: Text('Login Screen')),
    ),
    AppRoutes.signup: (context, state) => const Scaffold(
      body: Center(child: Text('Signup Screen')),
    ),
    '/test': (context, state) => const Scaffold(
      body: Center(child: Text('Test Screen')),
    ),
  };

  final builders = routeBuilders ?? defaultBuilders;

  return GoRouter(
    initialLocation: initialLocation,
    routes: builders.entries.map((entry) {
      return GoRoute(
        path: entry.key,
        builder: entry.value,
      );
    }).toList(),
  );
}

/// Creates a minimal router with just placeholder screens
GoRouter createMinimalRouter({
  String initialLocation = '/test',
  Widget? initialScreen,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: initialLocation,
        builder: (context, state) => initialScreen ?? const Scaffold(
          body: Center(child: Text('Test Screen')),
        ),
      ),
    ],
  );
}

// =====================================================
// WIDGET TEST EXTENSIONS
// =====================================================

extension WidgetTesterExtensions on WidgetTester {
  /// Pump the widget and wait for all animations to complete
  Future<void> pumpAndSettleWithTimeout({
    Duration duration = const Duration(seconds: 10),
  }) async {
    try {
      await pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.build,
        duration,
      );
    } on FlutterError {
      // If pumpAndSettle times out due to ongoing animations,
      // just pump a few more frames
      for (int i = 0; i < 10; i++) {
        await pump(const Duration(milliseconds: 100));
      }
    }
  }

  /// Find a widget by its key string
  Finder findByKeyString(String key) {
    return find.byKey(Key(key));
  }

  /// Scroll until a widget is visible
  Future<void> scrollUntilVisible(
    Finder finder,
    double delta, {
    Finder? scrollable,
    int maxScrolls = 50,
  }) async {
    final scrollableFinder = scrollable ?? find.byType(Scrollable).first;

    int scrollCount = 0;
    while (finder.evaluate().isEmpty && scrollCount < maxScrolls) {
      await scrollUntilVisible(
        finder,
        delta,
        scrollable: scrollableFinder,
      );
      await pump();
      scrollCount++;
    }
  }

  /// Enter text in a field found by label
  Future<void> enterTextByLabel(String label, String text) async {
    // Find the TextField associated with the label
    final labelFinder = find.text(label);
    expect(labelFinder, findsOneWidget);

    // Find nearest TextFormField
    final textField = find.ancestor(
      of: labelFinder,
      matching: find.byType(TextFormField),
    );

    if (textField.evaluate().isNotEmpty) {
      await enterText(textField.first, text);
    } else {
      // Try to find TextField directly
      final allFields = find.byType(TextFormField);
      if (allFields.evaluate().isNotEmpty) {
        await enterText(allFields.first, text);
      }
    }
  }

  /// Tap a button found by text
  Future<void> tapButtonByText(String text) async {
    final button = find.text(text);
    expect(button, findsWidgets);
    await tap(button.first);
    await pump();
  }

  /// Verify snackbar is shown with message
  Future<void> expectSnackbar(String message) async {
    await pump();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text(message), findsOneWidget);
  }
}

// =====================================================
// FINDER HELPERS
// =====================================================

/// Find widgets with Arabic text
Finder findArabicText(String text) {
  return find.text(text);
}

/// Find widget by semantic label
Finder findBySemanticLabel(String label) {
  return find.bySemanticsLabel(label);
}

/// Find all buttons
Finder findAllButtons() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is ElevatedButton ||
        widget is TextButton ||
        widget is OutlinedButton ||
        widget is IconButton ||
        widget is FloatingActionButton,
  );
}

/// Find all text fields
Finder findAllTextFields() {
  return find.byWidgetPredicate(
    (widget) => widget is TextField || widget is TextFormField,
  );
}

/// Find widget by type with specific text child
Finder findByTypeWithText<T extends Widget>(String text) {
  return find.ancestor(
    of: find.text(text),
    matching: find.byType(T),
  );
}

// =====================================================
// MOCK NAVIGATION OBSERVER
// =====================================================

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

/// Create a navigation observer that tracks routes
MockNavigatorObserver createMockNavigatorObserver() {
  final observer = MockNavigatorObserver();
  return observer;
}

// =====================================================
// ASYNC HELPERS
// =====================================================

/// Wait for async operations to complete
Future<void> waitForAsync(WidgetTester tester, {int frames = 5}) async {
  for (int i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Wait for a condition to be true
Future<bool> waitForCondition(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 5),
  Duration interval = const Duration(milliseconds: 100),
}) async {
  final stopwatch = Stopwatch()..start();

  while (stopwatch.elapsed < timeout) {
    await tester.pump(interval);
    if (condition()) {
      return true;
    }
  }

  return false;
}

// =====================================================
// GOLDEN TEST HELPERS
// =====================================================

/// Match a widget against a golden file
Future<void> matchGolden(
  WidgetTester tester,
  String goldenFileName,
) async {
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$goldenFileName.png'),
  );
}

// =====================================================
// ACCESSIBILITY HELPERS
// =====================================================

/// Check if widget meets accessibility guidelines
Future<void> checkAccessibility(WidgetTester tester) async {
  final handle = tester.ensureSemantics();

  // Check for semantic labels on interactive elements
  final buttons = findAllButtons();
  for (final button in buttons.evaluate()) {
    final semantics = tester.getSemantics(find.byWidget(button.widget));
    expect(
      semantics.label.isNotEmpty || semantics.tooltip.isNotEmpty,
      isTrue,
      reason: 'Interactive element should have semantic label',
    );
  }

  handle.dispose();
}

// =====================================================
// SCREEN SIZE HELPERS
// =====================================================

/// Set screen size for testing
Future<void> setScreenSize(
  WidgetTester tester, {
  double width = 390,
  double height = 844,
}) async {
  await tester.binding.setSurfaceSize(Size(width, height));
}

/// Reset screen size to default
Future<void> resetScreenSize(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(null);
}

/// Screen sizes for common devices
class TestScreenSizes {
  static const Size iPhoneSE = Size(375, 667);
  static const Size iPhone14 = Size(390, 844);
  static const Size iPhone14Pro = Size(393, 852);
  static const Size iPhone14ProMax = Size(430, 932);
  static const Size iPadMini = Size(744, 1133);
  static const Size iPad = Size(810, 1080);
  static const Size iPadPro11 = Size(834, 1194);
  static const Size iPadPro12 = Size(1024, 1366);
  static const Size pixel7 = Size(412, 915);
  static const Size galaxyS21 = Size(360, 800);
}
