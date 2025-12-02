import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'core/config/firebase_config.dart'; // Still needed for FCM
import 'core/config/supabase_config.dart'; // NEW: Supabase configuration
import 'core/config/app_scroll_behavior.dart'; // Enable mouse drag scrolling for web
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';
import 'shared/widgets/floating_points_overlay.dart';

// Firebase Analytics instance
final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('✅ Environment variables loaded successfully');
  } catch (e) {
    debugPrint('❌ CRITICAL: Could not load .env file: $e');
    debugPrint('⚠️ App will continue but Supabase, Firebase, and Sentry may not function properly');
    debugPrint('💡 Make sure .env file exists and is listed in pubspec.yaml assets');
  }

  // Initialize Supabase (primary backend)
  await SupabaseConfig.initialize();

  // Initialize Firebase (for FCM notifications only)
  await FirebaseConfig.initialize();

  // Initialize Sentry and run app
  await SentryFlutter.init(
    (options) {
      options.dsn = dotenv.env['SENTRY_DSN'] ?? '';
      options.tracesSampleRate = 1.0; // Capture 100% of transactions in debug/staging
      options.enableAutoPerformanceTracing = true;
      options.attachThreads = true;
      options.attachStacktrace = true;
      options.environment = dotenv.env['ENVIRONMENT'] ?? 'development';
      // Only report crashes in production - skip sending in development
      if (dotenv.env['ENVIRONMENT'] != 'production') {
        options.beforeSend = (event, hint) {
          debugPrint('🐛 [Sentry] Event captured (dev mode - not sent)');
          return null; // Don't send in development/staging
        };
      }
    },
    appRunner: () => runApp(
      const ProviderScope(
        child: SilniApp(),
      ),
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
      scrollBehavior: AppScrollBehavior(), // Enable mouse drag scrolling for web
      routerConfig: router,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl, // Arabic RTL
          child: FloatingPointsHost(
            key: floatingPointsHostKey,
            child: child!,
          ),
        );
      },
    );
  }
}
