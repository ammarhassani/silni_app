import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/config/firebase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load environment variables (gracefully handle if not available on web)
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // .env file not available (common in web builds)
    // Environment variables should be set through build configuration
    debugPrint('⚠️ Could not load .env file: $e');
  }

  // Initialize Firebase
  await FirebaseConfig.initialize();

  // Run app
  runApp(
    const ProviderScope(
      child: SilniApp(),
    ),
  );
}

class SilniApp extends ConsumerWidget {
  const SilniApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Watch theme provider for dynamic theme changes
    final themeColors = ref.watch(themeColorsProvider);

    // Generate dynamic themes based on selected color scheme
    final lightTheme = AppTheme.fromThemeColors(themeColors, isDark: false);
    final darkTheme = AppTheme.fromThemeColors(themeColors, isDark: true);

    return MaterialApp.router(
      title: 'صِلْني - Silni',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.light, // Always use light mode (theme colors change instead)
      themeAnimationDuration: const Duration(milliseconds: 400), // Smooth theme transitions
      themeAnimationCurve: Curves.easeInOut,
      routerConfig: router,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl, // Arabic RTL
          child: child!,
        );
      },
    );
  }
}
