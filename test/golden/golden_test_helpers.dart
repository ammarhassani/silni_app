import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:silni_app/core/theme/app_themes.dart';
import 'package:silni_app/core/theme/dynamic_theme.dart';
import 'package:silni_app/core/theme/theme_provider.dart';

/// Configure golden tests for Silni App
///
/// Golden tests capture screenshots of widgets and compare them
/// against baseline images. If the UI changes unexpectedly, the test fails.
Future<void> configureGoldenTests() async {
  // Load fonts for consistent rendering
  await loadAppFonts();
}

/// Standard device configurations for golden tests
final goldenDevices = [
  Device.phone,
  Device.iphone11,
  Device.tabletPortrait,
];

/// Create a testable widget with proper theming and Riverpod support
///
/// Since GlassCard and other widgets use Riverpod providers for theming,
/// this wrapper ensures they have access to the theme providers.
Widget createGoldenTestWidget(
  Widget child, {
  AppThemeType themeType = AppThemeType.defaultGreen,
}) {
  // Get theme colors for the specified theme type
  final themeColors = ThemeColors.getTheme(themeType);

  return ProviderScope(
    overrides: [
      // themeColorsProvider is a StateNotifierProvider — current Riverpod
      // requires overrideWith returning a notifier instance. Plain Providers
      // below still take overrideWithValue.
      themeColorsProvider.overrideWith(
        (ref) => AnimatedThemeColorsNotifier(themeColors),
      ),
      themeKeyProvider.overrideWithValue(themeType.value),
      currentDynamicThemeProvider.overrideWithValue(
        DynamicTheme.fromAppTheme(themeType),
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.light,
      home: Scaffold(
        backgroundColor: themeColors.background1,
        body: Center(
          child: child,
        ),
      ),
    ),
  );
}

/// Multi-device golden test helper
///
/// Renders the widget across multiple device configurations and
/// compares against golden images.
Future<void> multiDeviceGoldenTest(
  WidgetTester tester,
  Widget widget,
  String name, {
  AppThemeType themeType = AppThemeType.defaultGreen,
}) async {
  final builder = DeviceBuilder()
    ..overrideDevicesForAllScenarios(devices: goldenDevices)
    ..addScenario(
      widget: createGoldenTestWidget(widget, themeType: themeType),
      name: 'default',
    );

  await tester.pumpDeviceBuilder(builder);
  await screenMatchesGolden(tester, name);
}

/// Single scenario golden test helper
///
/// Renders the widget in a single configuration for focused testing.
Future<void> singleGoldenTest(
  WidgetTester tester,
  Widget widget,
  String name, {
  AppThemeType themeType = AppThemeType.defaultGreen,
  Size size = const Size(400, 300),
}) async {
  await tester.pumpWidgetBuilder(
    createGoldenTestWidget(widget, themeType: themeType),
    surfaceSize: size,
  );
  await screenMatchesGolden(tester, name);
}

/// Golden test with multiple theme variations
///
/// Renders the same widget with different themes for comparison.
Future<void> multiThemeGoldenTest(
  WidgetTester tester,
  Widget widget,
  String name, {
  List<AppThemeType> themes = const [
    AppThemeType.defaultGreen,
    AppThemeType.lavenderPurple,
  ],
}) async {
  final builder = DeviceBuilder()
    ..overrideDevicesForAllScenarios(devices: [Device.phone]);

  for (final theme in themes) {
    builder.addScenario(
      widget: createGoldenTestWidget(widget, themeType: theme),
      name: theme.value,
    );
  }

  await tester.pumpDeviceBuilder(builder);
  await screenMatchesGolden(tester, name);
}

/// Tags for golden tests - useful for running specific test groups
const goldenTag = 'golden';

/// Common test setup that should be called in setUpAll
Future<void> goldenTestSetUp() async {
  await configureGoldenTests();
}
