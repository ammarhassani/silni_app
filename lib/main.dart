import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'firebase_options.dart';
import 'core/config/supabase_config.dart';
import 'core/cache/hive_initializer.dart';
import 'core/config/app_scroll_behavior.dart'; // Enable mouse drag scrolling for web
import 'core/config/env/app_environment.dart';
import 'core/config/env/env_validator.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'core/router/navigation_service.dart';
import 'core/providers/gamification_events_provider.dart';
import 'core/services/sync_service.dart';
import 'core/services/connectivity_service.dart';
import 'features/auth/providers/auth_provider.dart'; // Auth providers
import 'shared/widgets/floating_points_overlay.dart';
import 'shared/widgets/logger_host.dart'; // In-app logger
import 'core/services/app_logger_service.dart'; // Logger service
import 'shared/services/fcm_notification_service.dart';
import 'shared/services/unified_notification_service.dart';
import 'core/services/analytics_service.dart';
import 'core/services/performance_monitoring_service.dart';
import 'core/services/app_health_service.dart';
import 'core/services/subscription_service.dart';
import 'core/services/cache_config_service.dart';
import 'core/services/feature_config_service.dart';
import 'core/services/ai_config_service.dart';
import 'core/services/gamification_config_service.dart';
import 'core/services/content_config_service.dart';
import 'core/services/notification_config_service.dart';
import 'core/services/design_config_service.dart';
import 'core/services/app_routes_config_service.dart';
import 'core/services/message_service.dart';
import 'core/services/ui_strings_service.dart';
import 'core/services/onboarding_config_service.dart';
import 'shared/widgets/error_boundary.dart';
import 'shared/widgets/premium_loading_indicator.dart';

// Background handler is now in fcm_notification_service.dart
// It's imported and used via FirebaseMessaging.onBackgroundMessage()

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

  // Initialize Arabic locale for date formatting
  await initializeDateFormatting('ar');

  // Validate environment configuration (compile-time type-safe via envied)
  logger.info(
    'Validating environment configuration...',
    category: LogCategory.lifecycle,
    tag: 'ENV',
  );
  try {
    // Validate all required environment variables are present
    EnvValidator.validate(throwOnError: !kDebugMode);
    // Log configuration details (without sensitive values)
    EnvValidator.logConfiguration();
    logger.info(
      'Environment configuration validated successfully',
      category: LogCategory.lifecycle,
      tag: 'ENV',
    );
  } catch (e, stackTrace) {
    logger.critical(
      'Environment validation failed',
      category: LogCategory.lifecycle,
      tag: 'ENV',
      metadata: {'error': e.toString()},
      stackTrace: stackTrace,
    );
    // In debug mode, continue anyway for development
    // In release mode, the exception will propagate
    if (!kDebugMode) rethrow;
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

  // Initialize Hive for local caching (offline support)
  logger.info(
    'Initializing Hive for local caching...',
    category: LogCategory.database,
    tag: 'Hive',
  );
  try {
    await HiveInitializer.initialize();
    logger.info(
      'Hive initialization completed successfully',
      category: LogCategory.database,
      tag: 'Hive',
    );
  } catch (e, stackTrace) {
    logger.error(
      'Hive initialization failed - Offline caching disabled',
      category: LogCategory.database,
      tag: 'Hive',
      metadata: {'error': e.toString()},
      stackTrace: stackTrace,
    );
    // Don't rethrow - app can work without local cache
  }

  // Initialize connectivity monitoring
  logger.info(
    'Initializing connectivity service...',
    category: LogCategory.network,
    tag: 'Connectivity',
  );
  connectivityService.initialize();

  // Initialize sync service (offline queue + background sync)
  logger.info(
    'Initializing sync service...',
    category: LogCategory.service,
    tag: 'Sync',
  );
  try {
    await SyncService.instance.initialize();
    logger.info(
      'Sync service initialized successfully',
      category: LogCategory.service,
      tag: 'Sync',
    );
  } catch (e, stackTrace) {
    logger.error(
      'Sync service initialization failed',
      category: LogCategory.service,
      tag: 'Sync',
      metadata: {'error': e.toString()},
      stackTrace: stackTrace,
    );
    // Don't rethrow - app can work without sync
  }

  // Initialize Firebase for FCM (push notifications only)
  logger.info(
    'Initializing Firebase for FCM...',
    category: LogCategory.service,
    tag: 'Firebase',
  );
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    logger.info(
      'Firebase initialized successfully',
      category: LogCategory.service,
      tag: 'Firebase',
    );

    // Initialize Firebase Analytics
    try {
      final analytics = AnalyticsService();
      await analytics.logAppOpen();
      logger.info(
        'Firebase Analytics initialized',
        category: LogCategory.service,
        tag: 'Analytics',
      );
    } catch (e) {
      logger.warning(
        'Firebase Analytics initialization failed',
        category: LogCategory.service,
        tag: 'Analytics',
        metadata: {'error': e.toString()},
      );
      // Don't rethrow - app can work without analytics
    }

    // Initialize Performance Monitoring
    logger.info(
      'Initializing performance monitoring...',
      category: LogCategory.service,
      tag: 'Performance',
    );
    try {
      final perfService = PerformanceMonitoringService();
      await perfService.initialize();

      // Start app health monitoring
      final healthService = AppHealthService();
      healthService.startMonitoring();

      logger.info(
        'Performance monitoring initialized',
        category: LogCategory.service,
        tag: 'Performance',
      );
    } catch (e) {
      logger.warning(
        'Performance monitoring initialization failed',
        category: LogCategory.service,
        tag: 'Performance',
        metadata: {'error': e.toString()},
      );
      // Don't rethrow - app can work without performance monitoring
    }
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

  // Initialize subscription service (RevenueCat)
  // Only pass userId if Supabase is initialized and user is authenticated
  logger.info(
    'Initializing subscription service...',
    category: LogCategory.service,
    tag: 'Subscription',
  );
  try {
    final currentUserId = SupabaseConfig.isInitialized ? SupabaseConfig.currentUserId : null;
    await SubscriptionService.instance.initialize(
      userId: currentUserId,
    );
    logger.info(
      'Subscription service initialized successfully',
      category: LogCategory.service,
      tag: 'Subscription',
      metadata: {'hasUserId': currentUserId != null},
    );
  } catch (e, stackTrace) {
    logger.error(
      'Subscription service initialization failed',
      category: LogCategory.service,
      tag: 'Subscription',
      metadata: {'error': e.toString()},
      stackTrace: stackTrace,
    );
    // Don't rethrow - app can work without subscriptions (defaults to free tier)
  }

  // Initialize feature config service (dynamic feature gating from admin panel)
  logger.info(
    'Loading feature configuration from admin panel...',
    category: LogCategory.service,
    tag: 'FeatureConfig',
  );
  try {
    await FeatureConfigService.instance.refresh();
    logger.info(
      'Feature configuration loaded successfully',
      category: LogCategory.service,
      tag: 'FeatureConfig',
    );
  } catch (e) {
    logger.warning(
      'Feature configuration loading failed - using hardcoded defaults',
      category: LogCategory.service,
      tag: 'FeatureConfig',
      metadata: {'error': e.toString()},
    );
    // Don't rethrow - app falls back to hardcoded feature config
  }

  // ========================================
  // CACHE CONFIGURATION - Load cache durations first
  // ========================================
  logger.info(
    'Loading cache configuration...',
    category: LogCategory.service,
    tag: 'CacheConfig',
  );
  try {
    await CacheConfigService().initialize();
    logger.info(
      'Cache configuration loaded successfully',
      category: LogCategory.service,
      tag: 'CacheConfig',
    );
  } catch (e) {
    logger.warning(
      'Cache configuration loading failed - using defaults',
      category: LogCategory.service,
      tag: 'CacheConfig',
      metadata: {'error': e.toString()},
    );
  }

  // ========================================
  // AI CONFIGURATION - Load from admin panel
  // ========================================
  logger.info(
    'Loading AI configuration from admin panel...',
    category: LogCategory.service,
    tag: 'AIConfig',
  );
  try {
    await AIConfigService.instance.initialize();
    logger.info(
      'AI configuration loaded successfully',
      category: LogCategory.service,
      tag: 'AIConfig',
    );
  } catch (e) {
    logger.warning(
      'AI configuration loading failed - using hardcoded defaults',
      category: LogCategory.service,
      tag: 'AIConfig',
      metadata: {'error': e.toString()},
    );
    // Don't rethrow - app falls back to hardcoded AI config
  }

  // Load gamification configuration from admin panel
  logger.info(
    'Loading gamification configuration from admin panel...',
    category: LogCategory.service,
    tag: 'GamificationConfig',
  );
  try {
    await GamificationConfigService.instance.initialize();
    logger.info(
      'Gamification configuration loaded successfully',
      category: LogCategory.service,
      tag: 'GamificationConfig',
    );
  } catch (e) {
    logger.warning(
      'Gamification configuration loading failed - using hardcoded defaults',
      category: LogCategory.service,
      tag: 'GamificationConfig',
      metadata: {'error': e.toString()},
    );
    // Don't rethrow - app falls back to hardcoded gamification config
  }

  // Load content configuration from admin panel (banners, hadith, quotes, MOTD)
  logger.info(
    'Loading content configuration from admin panel...',
    category: LogCategory.service,
    tag: 'ContentConfig',
  );
  try {
    await ContentConfigService.instance.refresh();
    logger.info(
      'Content configuration loaded successfully',
      category: LogCategory.service,
      tag: 'ContentConfig',
    );
  } catch (e) {
    logger.warning(
      'Content configuration loading failed - using hardcoded defaults',
      category: LogCategory.service,
      tag: 'ContentConfig',
      metadata: {'error': e.toString()},
    );
    // Don't rethrow - app falls back to hardcoded content
  }

  // Load notification configuration from admin panel (templates, time slots)
  logger.info(
    'Loading notification configuration from admin panel...',
    category: LogCategory.service,
    tag: 'NotificationConfig',
  );
  try {
    await NotificationConfigService.instance.refresh();
    logger.info(
      'Notification configuration loaded successfully',
      category: LogCategory.service,
      tag: 'NotificationConfig',
    );
  } catch (e) {
    logger.warning(
      'Notification configuration loading failed - using hardcoded defaults',
      category: LogCategory.service,
      tag: 'NotificationConfig',
      metadata: {'error': e.toString()},
    );
    // Don't rethrow - app falls back to hardcoded notification config
  }

  // Load design configuration from admin panel (colors, themes, animations)
  logger.info(
    'Loading design configuration from admin panel...',
    category: LogCategory.service,
    tag: 'DesignConfig',
  );
  try {
    await DesignConfigService.instance.initialize();
    logger.info(
      'Design configuration loaded successfully',
      category: LogCategory.service,
      tag: 'DesignConfig',
    );
  } catch (e) {
    logger.warning(
      'Design configuration loading failed - using hardcoded defaults',
      category: LogCategory.service,
      tag: 'DesignConfig',
      metadata: {'error': e.toString()},
    );
    // Don't rethrow - app falls back to hardcoded design config
  }

  // Load app routes configuration from admin panel (for banners/MOTD action routes)
  logger.info(
    'Loading app routes configuration from admin panel...',
    category: LogCategory.service,
    tag: 'AppRoutesConfig',
  );
  try {
    await AppRoutesConfigService.instance.initialize();
    logger.info(
      'App routes configuration loaded successfully',
      category: LogCategory.service,
      tag: 'AppRoutesConfig',
    );
  } catch (e) {
    logger.warning(
      'App routes configuration loading failed - using hardcoded defaults',
      category: LogCategory.service,
      tag: 'AppRoutesConfig',
      metadata: {'error': e.toString()},
    );
    // Don't rethrow - app falls back to hardcoded routes
  }

  // Initialize unified message service (replaces MOTD, Banners, In-App Messages)
  logger.info(
    'Initializing unified message service...',
    category: LogCategory.service,
    tag: 'Messages',
  );
  try {
    await MessageService.instance.initialize();
    logger.info(
      'Unified message service initialized',
      category: LogCategory.service,
      tag: 'Messages',
    );
  } catch (e) {
    logger.warning(
      'Unified message service initialization failed',
      category: LogCategory.service,
      tag: 'Messages',
      metadata: {'error': e.toString()},
    );
    // Don't rethrow - app works without messages
  }

  // Initialize UI strings service (remote-controlled strings from admin panel)
  logger.info(
    'Initializing UI strings service...',
    category: LogCategory.service,
    tag: 'UIStrings',
  );
  try {
    await UIStringsService.instance.initialize();
    logger.info(
      'UI strings service initialized',
      category: LogCategory.service,
      tag: 'UIStrings',
    );
  } catch (e) {
    logger.warning(
      'UI strings service initialization failed - using hardcoded strings',
      category: LogCategory.service,
      tag: 'UIStrings',
      metadata: {'error': e.toString()},
    );
    // Don't rethrow - app falls back to hardcoded strings
  }

  // Initialize onboarding config service (remote-controlled onboarding from admin panel)
  logger.info(
    'Initializing onboarding config service...',
    category: LogCategory.service,
    tag: 'OnboardingConfig',
  );
  try {
    await OnboardingConfigService.instance.initialize();
    logger.info(
      'Onboarding config service initialized',
      category: LogCategory.service,
      tag: 'OnboardingConfig',
    );
  } catch (e) {
    logger.warning(
      'Onboarding config service initialization failed - using hardcoded onboarding',
      category: LogCategory.service,
      tag: 'OnboardingConfig',
      metadata: {'error': e.toString()},
    );
    // Don't rethrow - app falls back to hardcoded onboarding
  }

  // Configure global error handlers with device context
  logger.info(
    'Configuring error handlers...',
    category: LogCategory.service,
    tag: 'ErrorHandling',
  );

  // Setup custom error widget builder for graceful error UI
  setupErrorWidgetBuilder();

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
      options.dsn = AppEnvironment.sentryDsn;
      // Production: 10% sampling for cost control
      // Staging/TestFlight: 50% for better visibility during testing
      options.tracesSampleRate = AppEnvironment.isProduction ? 0.1 : 0.5;
      options.enableAutoPerformanceTracing = true;
      options.attachThreads = true;
      options.attachStacktrace = true;
      options.environment = AppEnvironment.sentryEnvironment;
      logger.debug(
        'Sentry environment: ${options.environment}',
        category: LogCategory.service,
        tag: 'Sentry',
      );
      // Configure beforeSend to enable TestFlight and staging logging
      options.beforeSend = (event, hint) {
        final environment = AppEnvironment.sentryEnvironment;
        final isTestFlight = AppEnvironment.isTestFlight;

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
          'environment': AppEnvironment.sentryEnvironment,
          'will_send_events':
              AppEnvironment.sentryEnvironment == 'production' ||
              AppEnvironment.sentryEnvironment == 'staging' ||
              AppEnvironment.isTestFlight,
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

class SilniApp extends ConsumerStatefulWidget {
  const SilniApp({super.key});

  @override
  ConsumerState<SilniApp> createState() => _SilniAppState();
}

class _SilniAppState extends ConsumerState<SilniApp> with WidgetsBindingObserver {
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appLinks = AppLinks();
    _setupDeepLinkHandling();
    _setupPasswordRecoveryListener();
  }

  /// Handle incoming deep links for auth callbacks
  void _setupDeepLinkHandling() {
    final logger = AppLoggerService();

    // Handle deep link when app is opened from terminated state
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        logger.info(
          'Initial deep link received',
          category: LogCategory.auth,
          tag: 'main',
          metadata: {'uri': uri.toString()},
        );
        _handleDeepLink(uri);
      }
    });

    // Handle deep link when app is already running (from background)
    _appLinks.uriLinkStream.listen((uri) {
      logger.info(
        'Deep link received while app running',
        category: LogCategory.auth,
        tag: 'main',
        metadata: {'uri': uri.toString()},
      );
      _handleDeepLink(uri);
    });
  }

  /// Process the deep link URL for Supabase auth
  void _handleDeepLink(Uri uri) {
    final logger = AppLoggerService();

    // Check if this is a Supabase auth callback (has access_token in fragment)
    final fragment = uri.fragment;
    if (fragment.isNotEmpty && fragment.contains('access_token')) {
      logger.info(
        'Supabase auth callback detected',
        category: LogCategory.auth,
        tag: 'main',
        metadata: {'path': uri.path},
      );

      // Let Supabase handle the auth callback
      // The onAuthStateChange listener will fire with the appropriate event
      if (SupabaseConfig.isInitialized) {
        // Supabase should automatically handle the URL fragment,
        // but we can also manually trigger it by reconstructing the full URL
        final fullUri = uri.toString();
        SupabaseConfig.client.auth.getSessionFromUrl(Uri.parse(fullUri)).then((response) {
          logger.info(
            'Session from URL processed',
            category: LogCategory.auth,
            tag: 'main',
            metadata: {
              'hasSession': true,
              'userId': response.session.user.id,
            },
          );
        }).catchError((e) {
          logger.error(
            'Error processing session from URL',
            category: LogCategory.auth,
            tag: 'main',
            metadata: {'error': e.toString()},
          );
        });
      }
    }
  }

  /// Listen for password recovery events from Supabase deep links
  void _setupPasswordRecoveryListener() {
    if (!SupabaseConfig.isInitialized) return;

    SupabaseConfig.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;
      final logger = AppLoggerService();

      logger.debug(
        'Auth state change detected',
        category: LogCategory.auth,
        tag: 'main',
        metadata: {
          'event': event.toString(),
          'hasSession': session != null,
          'userId': session?.user.id,
        },
      );

      if (event == AuthChangeEvent.passwordRecovery) {
        logger.info(
          'Password recovery event detected - navigating to reset screen',
          category: LogCategory.auth,
          tag: 'main',
        );

        // Delay navigation slightly to ensure router is ready
        Future.delayed(const Duration(milliseconds: 100), () {
          final context = NavigationService.currentContext;
          if (context != null) {
            NavigationService.navigateTo(AppRoutes.resetPassword);
          } else {
            logger.warning(
              'Navigation context not ready, retrying...',
              category: LogCategory.auth,
              tag: 'main',
            );
            // Retry after a longer delay
            Future.delayed(const Duration(milliseconds: 500), () {
              NavigationService.navigateTo(AppRoutes.resetPassword);
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Dispose singleton services to prevent memory leaks
    connectivityService.dispose();
    FCMNotificationService().dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh configs when app comes back to foreground
      FeatureConfigService.instance.refresh();
      AIConfigService.instance.refresh();
      GamificationConfigService.instance.refresh();
      ContentConfigService.instance.refresh();
      NotificationConfigService.instance.refresh();
      DesignConfigService.instance.refresh();
      AppRoutesConfigService.instance.refresh();
      UIStringsService.instance.refresh();
      OnboardingConfigService.instance.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize SyncService with gamification events controller for UI feedback
    final eventsController = ref.read(gamificationEventsControllerProvider);
    SyncService.instance.setEventsController(eventsController);

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
                    body: Center(
                      child: PremiumLoadingIndicator(
                        message: 'جاري التحميل...',
                      ),
                    ),
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
