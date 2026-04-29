import 'dart:async' show unawaited;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'core/router/app_router.dart' as router;
import 'core/router/app_router.dart';
import 'core/router/navigation_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/connectivity_service.dart';
import 'features/auth/providers/auth_provider.dart'; // Auth providers
import 'shared/widgets/logger_host.dart'; // In-app logger
import 'core/services/app_logger_service.dart'; // Logger service
import 'shared/services/fcm_notification_service.dart';
import 'shared/services/unified_notification_service.dart';
import 'core/services/analytics.dart';
import 'core/services/performance_monitoring_service.dart';
import 'core/services/app_health_service.dart';
import 'core/services/subscription_service.dart';
import 'core/services/cache_config_service.dart';
import 'core/services/feature_config_service.dart';
import 'core/services/ai_config_service.dart';
import 'core/services/streak_config_service.dart';
import 'core/services/content_config_service.dart';
import 'core/services/notification_config_service.dart';
import 'core/services/design_config_service.dart';
import 'core/services/app_routes_config_service.dart';
import 'core/services/message_service.dart';
import 'core/services/ui_strings_service.dart';
import 'core/services/onboarding_config_service.dart';
import 'shared/widgets/error_boundary.dart';
import 'shared/widgets/premium_loading_indicator.dart';
import 'features/widgets/home_widget_service.dart';
import 'core/services/session_cleanup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Phase 9.X.D.B hot-fix #12 (launch perf): timing instrumentation.
  // Founder reported "app takes forever to launch" — these logs let us
  // measure each phase. Look for "[boot]" tag in logs.
  final bootStart = Stopwatch()..start();
  void bootMark(String label, int ms) {
    logger.info(
      '[boot] $label: ${ms}ms (total ${bootStart.elapsedMilliseconds}ms)',
      category: LogCategory.lifecycle,
      tag: 'boot',
    );
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  bootMark('orientation', bootStart.elapsedMilliseconds);

  // Digit display policy: Western digits (0123) used app-wide, including in
  // time pickers, dates, prices, points, streaks, and durations. Decision
  // rationale: iOS system UI uses Western digits in Arabic locale, ecosystem
  // norm in Saudi mobile apps (WhatsApp, banking apps, ride-share). Decision
  // confirmed by CTO 2026-04-26 audit. Revisit only if users specifically
  // request Arabic-Indic (٠١٢٣).

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

  // Phase 9.X.D.B hot-fix #12 (launch perf): four independent inits run in
  // PARALLEL via Future.wait — used to be serial awaits taking 1.5–6s combined.
  // Each future has its own try/catch so a single failure doesn't sink the
  // others (Future.wait propagates the first error otherwise).
  final phase1 = Stopwatch()..start();
  await Future.wait([
    _safeInit(
      logger: logger,
      tag: 'Locale',
      action: () => initializeDateFormatting('ar'),
      severity: _InitSeverity.error,
    ),
    _safeInit(
      logger: logger,
      tag: 'Supabase',
      action: () => SupabaseConfig.initialize(),
      severity: _InitSeverity.critical,
    ),
    // Phase 9.X.D.B hot-fix #14 (Tier 2 Step 1): Hive moved out of the
    // blocking phase1 — was 772ms (longest single item). CacheService
    // already wraps every Hive call in try/catch returning []/null, so
    // any pre-init access during the deferred window gracefully no-ops.
    // Real data flows through Supabase streams meanwhile.
    _safeInit(
      logger: logger,
      tag: 'Firebase',
      action: () async {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        // Background message handler must be wired right after init.
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );
      },
      severity: _InitSeverity.error,
    ),
  ]);
  phase1.stop();
  bootMark('phase1 (parallel: locale + supabase + hive + firebase)',
      phase1.elapsedMilliseconds);

  // Connectivity is sync (returns immediately, listener attaches in background).
  connectivityService.initialize();

  // Phase 9.X.D.B hot-fix #13 (launch perf): Subscription init MOVED to
  // deferred. Founder's runtime report showed it eating 3.2s of preamble
  // (RevenueCat login + customer-info fetch + offerings + edge-function
  // sync to Supabase — all synchronous). The free tier is the safe
  // default; subscriptionTierProvider returns SubscriptionTier.free until
  // RevenueCat resolves, and any tier-gated UI updates reactively when
  // the real tier comes in. See _initDeferredServices below.

  // Defer non-critical config services + post-Firebase telemetry +
  // subscription. All have safe fallbacks; nothing here blocks first-frame.
  unawaited(_initDeferredServices(logger));

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
  final phase3 = Stopwatch()..start();
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
      phase3.stop();
      bootMark('phase3 (sentry init)', phase3.elapsedMilliseconds);
      bootStart.stop();
      logger.info(
        '[boot] runApp — total cold-start preamble: '
        '${bootStart.elapsedMilliseconds}ms',
        category: LogCategory.lifecycle,
        tag: 'boot',
      );
      return runApp(const ProviderScope(child: SilniApp()));
    },
  );
}

/// Severity for an init failure — drives which logger level fires.
enum _InitSeverity { critical, error, warning }

/// Wraps an init future in per-future try/catch + logging. Used inside
/// Future.wait so a single service failure doesn't sink the whole batch
/// (Future.wait propagates the first error otherwise).
Future<void> _safeInit({
  required AppLoggerService logger,
  required String tag,
  required Future<void> Function() action,
  required _InitSeverity severity,
}) async {
  final sw = Stopwatch()..start();
  try {
    await action();
    sw.stop();
    logger.info(
      '$tag initialized in ${sw.elapsedMilliseconds}ms',
      category: LogCategory.lifecycle,
      tag: tag,
    );
  } catch (e, stack) {
    sw.stop();
    final meta = {'error': e.toString(), 'durationMs': sw.elapsedMilliseconds};
    switch (severity) {
      case _InitSeverity.critical:
        logger.critical('$tag init FAILED',
            category: LogCategory.lifecycle,
            tag: tag,
            metadata: meta,
            stackTrace: stack);
      case _InitSeverity.error:
        logger.error('$tag init failed',
            category: LogCategory.lifecycle,
            tag: tag,
            metadata: meta,
            stackTrace: stack);
      case _InitSeverity.warning:
        logger.warning('$tag init failed - using defaults',
            category: LogCategory.lifecycle, tag: tag, metadata: meta);
    }
  }
}

/// Non-critical services deferred to run in parallel while the splash screen
/// plays. All of these have hardcoded fallback defaults, so the app works
/// correctly even if they haven't finished loading yet.
Future<void> _initDeferredServices(AppLoggerService logger) async {
  Future<void> init(Future<void> Function() fn, String tag) async {
    try {
      await fn();
      logger.info('$tag loaded', category: LogCategory.service, tag: tag);
    } catch (e) {
      logger.warning(
        '$tag failed - using defaults',
        category: LogCategory.service,
        tag: tag,
        metadata: {'error': e.toString()},
      );
    }
  }

  await Future.wait([
    // Phase 9.X.D.B hot-fix #12: moved out of the blocking Firebase block.
    // logAppOpen + perf monitoring + health monitoring are non-critical
    // and were each adding 100–300ms of synchronous round-trip to startup.
    init(() => AnalyticsService().logAppOpen(), 'Analytics'),
    init(() => PerformanceMonitoringService().initialize(), 'Performance'),
    init(() async => AppHealthService().startMonitoring(), 'AppHealth'),
    // Phase 9.X.D.B hot-fix #13: Subscription was 3.2s of phase2 preamble.
    // Free tier is the safe default; the real tier comes in when this
    // resolves and tier-gated UI rebuilds reactively.
    init(
      () => SubscriptionService.instance.initialize(
        userId: SupabaseConfig.isInitialized
            ? SupabaseConfig.currentUserId
            : null,
      ),
      'Subscription',
    ),
    // Phase 9.X.D.B hot-fix #14 (Tier 2 Step 1): Hive deferred from phase1.
    // Was 772ms of cold-start preamble. CacheService methods all wrap
    // Hive access in try/catch → return []/null on error, so the brief
    // window between runApp and Hive ready is safe (Supabase streams
    // emit fresh data anyway). The eventual Tier 2 Step 2 strips the
    // read-cache layer entirely; for now this just shifts the cost
    // post-runApp.
    init(() => HiveInitializer.initialize(), 'Hive'),
    init(() => HomeWidgetService.initialize(), 'HomeWidget'),
    init(() => SyncService.instance.initialize(), 'Sync'),
    init(() => UnifiedNotificationService().initialize(), 'Notifications'),
    init(() => FeatureConfigService.instance.refresh(), 'FeatureConfig'),
    init(() => CacheConfigService().initialize(), 'CacheConfig'),
    init(() => AIConfigService.instance.initialize(), 'AIConfig'),
    init(() => StreakConfigService.instance.initialize(), 'StreakConfig'),
    init(() => ContentConfigService.instance.refresh(), 'ContentConfig'),
    init(() => NotificationConfigService.instance.refresh(), 'NotificationConfig'),
    init(() => DesignConfigService.instance.initialize(), 'DesignConfig'),
    init(() => AppRoutesConfigService.instance.initialize(), 'AppRoutesConfig'),
    init(() => MessageService.instance.initialize(), 'Messages'),
    init(() => UIStringsService.instance.initialize(), 'UIStrings'),
    init(() => OnboardingConfigService.instance.initialize(), 'OnboardingConfig'),
    // Phase 9.X.D.B Track B3: hydrate the setupComplete cache so the router's
    // synchronous redirect knows whether to push the wizard. The auth listener
    // re-hydrates from DB on signedIn; this just primes the cache from the
    // last-known SharedPreferences value.
    init(() => router.hydrateSetupCompleteCache(), 'SetupCompleteCache'),
  ]);

  logger.info(
    'All deferred services initialized',
    category: LogCategory.lifecycle,
    tag: 'main',
  );
}

class SilniApp extends ConsumerStatefulWidget {
  const SilniApp({super.key});

  @override
  ConsumerState<SilniApp> createState() => _SilniAppState();
}

class _SilniAppState extends ConsumerState<SilniApp> with WidgetsBindingObserver {
  late final AppLinks _appLinks;
  String? _previousUserId;

  @override
  void initState() {
    super.initState();
    _previousUserId = SupabaseConfig.isInitialized
        ? SupabaseConfig.client.auth.currentUser?.id
        : null;
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

  /// Process the deep link URL for Supabase auth or in-app navigation
  void _handleDeepLink(Uri uri) {
    final logger = AppLoggerService();

    // Handle family group join links: com.silni.app://join/<code>?rid=<id>
    // URI parses as: host="join", path="/<code>"
    if (uri.scheme == 'com.silni.app' && uri.host == 'join') {
      final code = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      if (code != null) {
        final rid = uri.queryParameters['rid'];
        final path = rid != null ? '/join/$code?rid=$rid' : '/join/$code';
        logger.info(
          'Family join deep link detected',
          category: LogCategory.auth,
          tag: 'main',
          metadata: {'code': code, 'rid': rid},
        );
        NavigationService.navigateTo(path);
        return;
      }
    }

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
      final currentUserId = session?.user.id;

      logger.debug(
        'Auth state change detected',
        category: LogCategory.auth,
        tag: 'main',
        metadata: {
          'event': event.toString(),
          'hasSession': session != null,
          'userId': currentUserId,
          'previousUserId': _previousUserId,
        },
      );

      // Clear stale data when user signs out or switches accounts
      if (_previousUserId != null && _previousUserId != currentUserId) {
        logger.info(
          'User changed — clearing previous session data',
          category: LogCategory.auth,
          tag: 'main',
          metadata: {
            'from': _previousUserId,
            'to': currentUserId,
          },
        );
        clearUserSessionFromWidget(ref, previousUserId: _previousUserId);
      }
      _previousUserId = currentUserId;

      // Ensure the public.users row exists for the current auth user.
      // Re-login via OAuth (Google, Apple) reuses the auth.users row without
      // firing handle_new_user, so any user who deleted their account and
      // came back would otherwise have an empty public.users row and FK
      // violations on relatives.user_id, family_edges.user_id, etc.
      // RPC is idempotent and cheap.
      if ((event == AuthChangeEvent.signedIn ||
              event == AuthChangeEvent.initialSession) &&
          session != null) {
        unawaited(_ensureUserRecord(session.user.id, logger));
        // Mark onboarding as complete on first authenticated session.
        // The onboarding screen no longer writes the flag — see
        // onboarding_screen.dart#_finish — so a user who tapped "تخطي"
        // without ever signing up will see the carousel again on next
        // cold-start.
        unawaited(_markOnboardingCompleted());
        // Phase 9.X.D Track A7: legacy one-shot notification permission
        // ask for existing users. New users get the prompt from the Track B
        // wizard step. The flag is server-side (users.onboarding_metadata->>
        // 'permissionAsked') so we never ask twice across reinstalls.
        unawaited(_legacyOneShotPermissionAsk(session.user.id, logger));
        // Phase 9.X.D.B Track B3: hydrate the setupComplete cache from DB
        // → SharedPreferences → in-memory router cache. Needed for the
        // synchronous router redirect to know whether to push the wizard.
        unawaited(_hydrateSetupCompleteFromDb(session.user.id, logger));
      }

      // Phone-invite subsystem cut from v1 (CTO 2026-04-26). The
      // _checkPendingInvitations call here used to surface
      // node_invitations as notification_history rows; removed because
      // the bell, the InvitationDetailScreen route, and the
      // node_invitations creation UI are all cut.

      if (event == AuthChangeEvent.passwordRecovery) {
        logger.info(
          'Password recovery event detected - Supabase handles reset via redirect',
          category: LogCategory.auth,
          tag: 'main',
        );
      }
    });
  }

  /// Ensure the public.users mirror exists for the current auth user.
  ///
  /// Called on every signedIn / initialSession event. Idempotent server-side
  /// (UPSERT). Fixes the case where a user deleted their account and came
  /// back via OAuth — the auth.users row gets reused so handle_new_user
  /// doesn't fire, leaving public.users empty and FK-dependent inserts
  /// (relatives, family_edges, etc.) failing with 23503.
  Future<void> _ensureUserRecord(
    String userId,
    AppLoggerService logger,
  ) async {
    try {
      await SupabaseConfig.client.rpc('ensure_user_record');
    } catch (e) {
      // Server-side function logs the SQL error; we never block the client.
      logger.warning(
        'ensure_user_record RPC failed',
        category: LogCategory.auth,
        tag: 'main',
        metadata: {'userId': userId, 'error': e.toString()},
      );
    }
  }

  /// Set the `onboarding_completed` SharedPreferences flag on first
  /// authenticated session. Idempotent — checks the existing value first
  /// so we don't pay the disk write on every sign-in.
  Future<void> _markOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('onboarding_completed') == true) return;
      await prefs.setBool('onboarding_completed', true);
    } catch (_) {
      // Disk failure here just means the user might see the carousel
      // again next cold-start. Not user-visible enough to surface.
    }
  }

  /// Phase 9.X.D.B Track B3 — hydrate the setupComplete cache.
  ///
  /// Reads `users.onboarding_metadata->>'setupComplete'` for the current user
  /// and writes the boolean into SharedPreferences (`setup_complete`) AND the
  /// router's in-memory cache. The router redirect reads the cache
  /// synchronously to decide whether to push the wizard.
  ///
  /// Idempotent + fire-and-forget. A network error here means the next
  /// router check sees a stale cache; the wizard route covers the case
  /// when needed.
  Future<void> _hydrateSetupCompleteFromDb(
    String userId,
    AppLoggerService logger,
  ) async {
    try {
      final row = await SupabaseConfig.client
          .from('users')
          .select('onboarding_metadata')
          .eq('id', userId)
          .maybeSingle();
      final meta =
          (row?['onboarding_metadata'] as Map<String, dynamic>?) ?? const {};
      final isComplete = meta['setupComplete'] == true ||
          meta['setupComplete'] == 'true';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('setup_complete', isComplete);
      router.setCachedSetupComplete(isComplete);
    } catch (e) {
      logger.warning(
        'setup_complete hydration failed (router will treat as unknown)',
        category: LogCategory.auth,
        tag: 'main',
        metadata: {'userId': userId, 'error': e.toString()},
      );
    }
  }

  /// Phase 9.X.D Track A7: legacy one-shot notification-permission ask.
  ///
  /// Existing users (those with `onboarding_metadata->>'setupComplete'='true'`
  /// from the Phase 9.X.D.A6 backfill) bypass the wizard. They still need to
  /// see the OS notification prompt at least once. This method:
  ///   • Checks `users.onboarding_metadata->>'permissionAsked'`. If `'true'`,
  ///     no-op.
  ///   • Otherwise calls FCMNotificationService.requestPermission() to fire
  ///     the OS prompt, then marks `permissionAsked='true'` server-side.
  ///   • For users without `setupComplete=true` (new accounts), this method
  ///     returns early and the wizard owns the ask.
  ///   • Fires-and-forgets — never blocks signin.
  Future<void> _legacyOneShotPermissionAsk(
    String userId,
    AppLoggerService logger,
  ) async {
    try {
      final supabase = SupabaseConfig.client;
      final row = await supabase
          .from('users')
          .select('onboarding_metadata')
          .eq('id', userId)
          .maybeSingle();
      final meta =
          (row?['onboarding_metadata'] as Map<String, dynamic>?) ?? const {};
      // New users (wizard not done) → wizard owns the ask. Skip.
      if (meta['setupComplete'] != true && meta['setupComplete'] != 'true') {
        return;
      }
      // Already asked once → don't re-ask.
      if (meta['permissionAsked'] == true ||
          meta['permissionAsked'] == 'true') {
        return;
      }
      // Fire the OS prompt via the deferred ask path.
      final granted = await FCMNotificationService().requestPermission();
      // Mark asked regardless of outcome — we don't re-prompt denied users.
      final updatedMeta = Map<String, dynamic>.from(meta)
        ..['permissionAsked'] = true
        ..['permissionGranted'] = granted;
      await supabase
          .from('users')
          .update({'onboarding_metadata': updatedMeta})
          .eq('id', userId);
      logger.info(
        'Legacy one-shot permission ask completed',
        category: LogCategory.auth,
        tag: 'main',
        metadata: {'granted': granted},
      );
    } catch (e) {
      logger.warning(
        'Legacy one-shot permission ask failed (non-critical)',
        category: LogCategory.auth,
        tag: 'main',
        metadata: {'userId': userId, 'error': e.toString()},
      );
    }
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
      StreakConfigService.instance.refresh();
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
      // Localization — Material/Cupertino/Widgets delegates so dialogs
      // (DatePicker, AlertDialog defaults, accessibility labels) render
      // in Arabic instead of falling back to English.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', 'SA'), Locale('en')],
      scrollBehavior:
          AppScrollBehavior(), // Enable mouse drag scrolling for web
      routerConfig: router,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl, // Arabic RTL
          child: LoggerHost(
            showFAB: false, // Hide logger FAB - not needed anymore
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
        );
      },
    );
  }
}
