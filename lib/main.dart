import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/config/supabase_config.dart';
import 'core/config/app_scroll_behavior.dart'; // Enable mouse drag scrolling for web
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';
import 'features/auth/providers/auth_provider.dart'; // Auth providers
import 'shared/widgets/floating_points_overlay.dart';
import 'shared/widgets/logger_host.dart'; // In-app logger
import 'core/services/app_logger_service.dart'; // Logger service
import 'shared/services/fcm_notification_service.dart';
import 'shared/services/unified_notification_service.dart';

// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print('🔔 [FCM] Background message: ${message.notification?.title}');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logger service FIRST
  final logger = AppLoggerService();

  // Enable logger for TestFlight builds and debug mode
  logger.setEnabled(
    kDebugMode ||
        const bool.fromEnvironment('ENABLE_LOGGER', defaultValue: false),
  );

  // ========================================
  // DIAGNOSTIC LOGGING - iOS Debug
  // ========================================
  logger.info(
    'Silni App Initializing...',
    category: LogCategory.lifecycle,
    tag: 'main',
  );

  // Platform Detection
  logger.info(
    'Build Mode: ${kDebugMode ? 'DEBUG' : 'RELEASE'}',
    category: LogCategory.lifecycle,
    tag: 'Platform',
  );

  if (kIsWeb) {
    logger.info(
      'Running on: WEB',
      category: LogCategory.lifecycle,
      tag: 'Platform',
    );
  } else if (Platform.isIOS) {
    logger.info(
      'Running on: iOS ${Platform.operatingSystemVersion}',
      category: LogCategory.lifecycle,
      tag: 'Platform',
    );
  } else if (Platform.isAndroid) {
    logger.info(
      'Running on: Android ${Platform.operatingSystemVersion}',
      category: LogCategory.lifecycle,
      tag: 'Platform',
    );
  } else {
    logger.info(
      'Running on: ${Platform.operatingSystem}',
      category: LogCategory.lifecycle,
      tag: 'Platform',
    );
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load environment variables
  logger.info(
    'Loading environment variables from .env file...',
    category: LogCategory.lifecycle,
    tag: 'ENV',
  );
  try {
    await dotenv.load(fileName: '.env');
    logger.info(
      '.env file loaded successfully',
      category: LogCategory.lifecycle,
      tag: 'ENV',
    );

    // Log which environment variables are available (without exposing sensitive data)
    final envKeys = dotenv.env.keys.toList();
    logger.debug(
      'Environment variables loaded',
      category: LogCategory.lifecycle,
      tag: 'ENV',
      metadata: {
        'variableCount': envKeys.length,
        'hasSupabaseUrl': dotenv.env.containsKey('SUPABASE_STAGING_URL'),
        'hasSupabaseKey': dotenv.env.containsKey('SUPABASE_STAGING_ANON_KEY'),
        'hasAppEnv': dotenv.env.containsKey('APP_ENV'),
      },
    );

    // Check dart-define values (these take precedence)
    final dartDefineUrl = const String.fromEnvironment('SUPABASE_STAGING_URL');
    final dartDefineAppEnv = const String.fromEnvironment('APP_ENV');
    logger.debug(
      'Dart-define values checked',
      category: LogCategory.lifecycle,
      tag: 'DART-DEFINE',
      metadata: {
        'hasSupabaseUrl': dartDefineUrl.isNotEmpty,
        'appEnv': dartDefineAppEnv.isNotEmpty ? dartDefineAppEnv : '(empty)',
      },
    );
  } catch (e, stackTrace) {
    logger.critical(
      'Could not load .env file',
      category: LogCategory.lifecycle,
      tag: 'ENV',
      metadata: {'error': e.toString()},
      stackTrace: stackTrace,
    );
    logger.warning(
      'App will rely on --dart-define flags from build command',
      category: LogCategory.lifecycle,
      tag: 'ENV',
    );

    // Check if dart-define provides fallback
    final dartDefineUrl = const String.fromEnvironment('SUPABASE_STAGING_URL');
    if (dartDefineUrl.isEmpty) {
      logger.critical(
        'No dart-define fallback found! App WILL FAIL - no credentials available',
        category: LogCategory.lifecycle,
        tag: 'ENV',
      );
    } else {
      logger.info(
        'dart-define fallback is available',
        category: LogCategory.lifecycle,
        tag: 'ENV',
      );
    }
  }

  // Initialize Supabase (primary backend)
  logger.info(
    'Starting Supabase initialization...',
    category: LogCategory.database,
    tag: 'Supabase',
  );
  try {
    await SupabaseConfig.initialize();
    logger.info(
      'Supabase initialization completed successfully',
      category: LogCategory.database,
      tag: 'Supabase',
    );
    logger.info(
      'Supabase client is ready',
      category: LogCategory.database,
      tag: 'Supabase',
    );
  } catch (e, stackTrace) {
    logger.critical(
      'Supabase initialization FAILED - Auth will NOT work',
      category: LogCategory.database,
      tag: 'Supabase',
      metadata: {'error': e.toString()},
      stackTrace: stackTrace,
    );
    // Don't rethrow - let app start so we can see logs
  }

  // Initialize Firebase for FCM (push notifications only)
  logger.info(
    'Initializing Firebase for FCM...',
    category: LogCategory.service,
    tag: 'Firebase',
  );
  try {
    await Firebase.initializeApp();

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    logger.info(
      'Firebase initialized successfully',
      category: LogCategory.service,
      tag: 'Firebase',
    );
  } catch (e, stackTrace) {
    logger.error(
      'Firebase initialization failed',
      category: LogCategory.service,
      tag: 'Firebase',
      metadata: {'error': e.toString()},
      stackTrace: stackTrace,
    );
    // Don't rethrow - app can work without push notifications
  }

  // Initialize unified notification service (FCM + local notifications)
  logger.info(
    'Initializing notification services...',
    category: LogCategory.service,
    tag: 'Notifications',
  );
  try {
    final unifiedNotifications = UnifiedNotificationService();
    await unifiedNotifications.initialize();
    logger.info(
      'Notification services initialized successfully',
      category: LogCategory.service,
      tag: 'Notifications',
    );
  } catch (e, stackTrace) {
    logger.error(
      'Notification services initialization failed',
      category: LogCategory.service,
      tag: 'Notifications',
      metadata: {'error': e.toString()},
      stackTrace: stackTrace,
    );
    // Don't rethrow - app can work without notifications
  }

  // Configure global error handlers with device context
  logger.info(
    'Configuring error handlers...',
    category: LogCategory.service,
    tag: 'ErrorHandling',
  );

  // Enhanced Flutter error handler with device context
  FlutterError.onError = (FlutterErrorDetails details) async {
    // Log locally
    logger.critical(
      'Flutter Error: ${details.exceptionAsString()}',
      category: LogCategory.lifecycle,
      metadata: {
        'stack_trace': details.stack.toString(),
        'library': details.library ?? 'unknown',
        'context': details.context?.toString() ?? 'no context',
      },
      stackTrace: details.stack,
    );

    // Send to Sentry (will be filtered by beforeSend hook)
    await Sentry.captureException(details.exception, stackTrace: details.stack);
  };

  // Catch errors outside Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.critical(
      'Platform Error: ${error.toString()}',
      category: LogCategory.lifecycle,
      metadata: {'error_type': error.runtimeType.toString()},
      stackTrace: stack,
    );

    Sentry.captureException(error, stackTrace: stack);
    return true;
  };

  // Initialize Sentry and run app
  logger.info(
    'Initializing error tracking...',
    category: LogCategory.service,
    tag: 'Sentry',
  );
  await SentryFlutter.init(
    (options) {
      options.dsn = dotenv.env['SENTRY_DSN'] ?? '';
      options.tracesSampleRate =
          1.0; // Capture 100% of transactions in debug/staging
      options.enableAutoPerformanceTracing = true;
      options.attachThreads = true;
      options.attachStacktrace = true;
      options.environment = dotenv.env['ENVIRONMENT'] ?? 'development';
      logger.debug(
        'Sentry environment: ${options.environment}',
        category: LogCategory.service,
        tag: 'Sentry',
      );
      // Configure beforeSend to enable TestFlight and staging logging
      options.beforeSend = (event, hint) {
        final environment = dotenv.env['ENVIRONMENT'] ?? 'development';
        final isTestFlight =
            const String.fromEnvironment(
              'IS_TESTFLIGHT',
              defaultValue: 'false',
            ) ==
            'true';

        // Send events from production OR staging/TestFlight builds
        // Block only from local development
        if (environment == 'production' ||
            environment == 'staging' ||
            isTestFlight) {
          logger.debug(
            'Sentry event sent',
            category: LogCategory.service,
            tag: 'Sentry',
            metadata: {
              'environment': environment,
              'is_testflight': isTestFlight,
            },
          );

          // Add custom tags for better debugging
          event.tags ??= {};
          event.tags!['app_environment'] = environment;
          event.tags!['is_testflight'] = isTestFlight.toString();
          event.tags!['build_mode'] = kDebugMode ? 'debug' : 'release';
          event.tags!['platform'] = Platform.operatingSystem;

          return event;
        }

        // Block local development events
        logger.debug(
          'Sentry event captured (local dev - not sent)',
          category: LogCategory.service,
          tag: 'Sentry',
        );
        return null;
      };

      logger.debug(
        'Sentry configured',
        category: LogCategory.service,
        tag: 'Sentry',
        metadata: {
          'environment': dotenv.env['ENVIRONMENT'] ?? 'development',
          'will_send_events':
              dotenv.env['ENVIRONMENT'] == 'production' ||
              dotenv.env['ENVIRONMENT'] == 'staging' ||
              const String.fromEnvironment(
                    'IS_TESTFLIGHT',
                    defaultValue: 'false',
                  ) ==
                  'true',
        },
      );
    },
    appRunner: () {
      logger.info(
        'Sentry initialized successfully',
        category: LogCategory.service,
        tag: 'Sentry',
      );
      logger.info(
        'All services initialized - Starting app',
        category: LogCategory.lifecycle,
        tag: 'main',
      );
      return runApp(const ProviderScope(child: SilniApp()));
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

    // Initialize session persistence
    final sessionInitialization = ref.watch(sessionInitializationProvider);

    // Generate dynamic themes based on selected color scheme
    final lightTheme = AppTheme.fromThemeColors(themeColors, isDark: false);
    final darkTheme = AppTheme.fromThemeColors(themeColors, isDark: true);

    return MaterialApp.router(
      title: 'صِلْني - Silni',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode
          .light, // Always use light mode (theme colors change instead)
      themeAnimationDuration: const Duration(
        milliseconds: 400,
      ), // Smooth theme transitions
      themeAnimationCurve: Curves.easeInOut,
      scrollBehavior:
          AppScrollBehavior(), // Enable mouse drag scrolling for web
      routerConfig: router,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl, // Arabic RTL
          child: LoggerHost(
            showFAB: false, // Hide logger FAB - not needed anymore
            child: FloatingPointsHost(
              key: floatingPointsHostKey,
              child: sessionInitialization.when(
                data: (hasValidSession) {
                  // Session initialization complete
                  return child!;
                },
                loading: () {
                  // Show loading while checking session
                  return const Scaffold(
                    backgroundColor: Colors.transparent,
                    body: Center(child: CircularProgressIndicator()),
                  );
                },
                error: (error, stack) {
                  // Session initialization failed, but still show app
                  return child!;
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
