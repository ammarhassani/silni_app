import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
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

  // ========================================
  // DIAGNOSTIC LOGGING - iOS Debug
  // ========================================
  debugPrint('');
  debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  debugPrint('🚀 [APP STARTUP] Silni App Initializing...');
  debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  debugPrint('');

  // Platform Detection
  debugPrint('📱 [PLATFORM] Build Mode: ${kDebugMode ? 'DEBUG' : 'RELEASE'}');
  if (kIsWeb) {
    debugPrint('📱 [PLATFORM] Running on: WEB');
  } else if (Platform.isIOS) {
    debugPrint('📱 [PLATFORM] Running on: iOS');
    debugPrint('📱 [PLATFORM] iOS Version: ${Platform.operatingSystemVersion}');
  } else if (Platform.isAndroid) {
    debugPrint('📱 [PLATFORM] Running on: Android');
    debugPrint('📱 [PLATFORM] Android Version: ${Platform.operatingSystemVersion}');
  } else {
    debugPrint('📱 [PLATFORM] Running on: ${Platform.operatingSystem}');
  }
  debugPrint('');

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load environment variables
  debugPrint('📂 [ENV] Loading environment variables from .env file...');
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('✅ [ENV] .env file loaded successfully');

    // Log which environment variables are available (without exposing sensitive data)
    final envKeys = dotenv.env.keys.toList();
    debugPrint('📋 [ENV] Available variables: ${envKeys.length} keys');
    debugPrint('📋 [ENV] Has SUPABASE_STAGING_URL: ${dotenv.env.containsKey('SUPABASE_STAGING_URL')}');
    debugPrint('📋 [ENV] Has SUPABASE_STAGING_ANON_KEY: ${dotenv.env.containsKey('SUPABASE_STAGING_ANON_KEY')}');
    debugPrint('📋 [ENV] Has APP_ENV: ${dotenv.env.containsKey('APP_ENV')}');

    // Check dart-define values (these take precedence)
    final dartDefineUrl = const String.fromEnvironment('SUPABASE_STAGING_URL');
    final dartDefineAppEnv = const String.fromEnvironment('APP_ENV');
    debugPrint('🔧 [DART-DEFINE] SUPABASE_STAGING_URL: ${dartDefineUrl.isNotEmpty ? '(provided)' : '(empty)'}');
    debugPrint('🔧 [DART-DEFINE] APP_ENV: ${dartDefineAppEnv.isNotEmpty ? dartDefineAppEnv : '(empty)'}');
    debugPrint('');
  } catch (e, stackTrace) {
    debugPrint('❌ [ENV] CRITICAL: Could not load .env file');
    debugPrint('❌ [ENV] Error: $e');
    debugPrint('❌ [ENV] Stack trace: $stackTrace');
    debugPrint('⚠️ [ENV] App will rely on --dart-define flags from build command');
    debugPrint('⚠️ [ENV] If dart-define flags are missing, Supabase will fail to initialize');

    // Check if dart-define provides fallback
    final dartDefineUrl = const String.fromEnvironment('SUPABASE_STAGING_URL');
    if (dartDefineUrl.isEmpty) {
      debugPrint('🔴 [ENV] CRITICAL: No dart-define fallback found!');
      debugPrint('🔴 [ENV] App WILL FAIL - no credentials available');
    } else {
      debugPrint('🟢 [ENV] OK: dart-define fallback is available');
    }
    debugPrint('');
  }

  // Initialize Supabase (primary backend)
  debugPrint('🔵 [SUPABASE] Starting initialization...');
  try {
    await SupabaseConfig.initialize();
    debugPrint('✅ [SUPABASE] Initialization completed successfully');
    debugPrint('✅ [SUPABASE] Client is ready');
    debugPrint('');
  } catch (e, stackTrace) {
    debugPrint('🔴 [SUPABASE] CRITICAL: Initialization FAILED');
    debugPrint('🔴 [SUPABASE] Error: $e');
    debugPrint('🔴 [SUPABASE] Stack trace: $stackTrace');
    debugPrint('🔴 [SUPABASE] Auth will NOT work - app is broken');
    debugPrint('');
    // Don't rethrow - let app start so we can see logs
  }

  // Initialize Firebase (for FCM notifications only)
  debugPrint('🟠 [FIREBASE] Starting initialization...');
  try {
    await FirebaseConfig.initialize();
    debugPrint('✅ [FIREBASE] Initialization completed');
    debugPrint('');
  } catch (e) {
    debugPrint('⚠️ [FIREBASE] Initialization failed: $e');
    debugPrint('⚠️ [FIREBASE] FCM notifications may not work');
    debugPrint('');
  }

  // Initialize Sentry and run app
  debugPrint('🐛 [SENTRY] Initializing error tracking...');
  await SentryFlutter.init(
    (options) {
      options.dsn = dotenv.env['SENTRY_DSN'] ?? '';
      options.tracesSampleRate = 1.0; // Capture 100% of transactions in debug/staging
      options.enableAutoPerformanceTracing = true;
      options.attachThreads = true;
      options.attachStacktrace = true;
      options.environment = dotenv.env['ENVIRONMENT'] ?? 'development';
      debugPrint('🐛 [SENTRY] Environment: ${options.environment}');
      // Only report crashes in production - skip sending in development
      if (dotenv.env['ENVIRONMENT'] != 'production') {
        options.beforeSend = (event, hint) {
          debugPrint('🐛 [SENTRY] Event captured (dev mode - not sent)');
          return null; // Don't send in development/staging
        };
        debugPrint('🐛 [SENTRY] Running in dev mode - errors will NOT be sent to Sentry');
      }
    },
    appRunner: () {
      debugPrint('✅ [SENTRY] Initialized successfully');
      debugPrint('');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('✅ [APP STARTUP] All services initialized - Starting app');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('');
      return runApp(
        const ProviderScope(
          child: SilniApp(),
        ),
      );
    },
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
