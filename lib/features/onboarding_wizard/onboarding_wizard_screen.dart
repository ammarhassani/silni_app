// Phase 9.X.D.B Track B — Onboarding wizard parent screen + step renderers.
//
// Renders the 5 admin_onboarding_screens-driven steps for first-run setup.
// State for the wizard's progressive data lives in `wizardStateProvider`,
// scoped to the wizard's lifetime. Step content (titles, copy, button text,
// per-step metadata) comes from `OnboardingConfigService`; this file owns
// the per-step UI for each `action_type`.
//
// The 5 steps:
//   1. confirm_name — pure welcome unless full_name is missing/email-only
//   2. add_relative_household — pushes AddRelativeScreen w/ wizardMode locked
//   3. add_relative_extended  — same, min_count=1
//   4. set_reminder_pref_and_permission — time picker + OS permission ask
//   5. finish — Anees intro; on CTA: writes setupComplete + seed RPC + /home

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show UserAttributes;

import '../../core/config/supabase_config.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/router/app_router.dart' as router;
import '../../core/router/app_routes.dart';
import '../../core/services/app_logger_service.dart';
import '../../core/services/onboarding_config_service.dart';
import '../../core/theme/theme_provider.dart';
import '../../shared/services/fcm_notification_service.dart';
import '../../shared/utils/ui_helpers.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_background.dart';
import '../../shared/widgets/gradient_button.dart';
import '../auth/providers/auth_provider.dart';
import '../relatives/screens/add_relative_screen.dart';

// =============================================================================
// State
// =============================================================================

class WizardState {
  final int currentStep; // 0-indexed, 0..4 for 5 steps
  final String? confirmedName;
  final int householdAddedCount;
  final int extendedAddedCount;
  final TimeOfDay? reminderTime;
  final bool? permissionGranted;

  const WizardState({
    this.currentStep = 0,
    this.confirmedName,
    this.householdAddedCount = 0,
    this.extendedAddedCount = 0,
    this.reminderTime,
    this.permissionGranted,
  });

  WizardState copyWith({
    int? currentStep,
    String? confirmedName,
    int? householdAddedCount,
    int? extendedAddedCount,
    TimeOfDay? reminderTime,
    bool? permissionGranted,
  }) {
    return WizardState(
      currentStep: currentStep ?? this.currentStep,
      confirmedName: confirmedName ?? this.confirmedName,
      householdAddedCount: householdAddedCount ?? this.householdAddedCount,
      extendedAddedCount: extendedAddedCount ?? this.extendedAddedCount,
      reminderTime: reminderTime ?? this.reminderTime,
      permissionGranted: permissionGranted ?? this.permissionGranted,
    );
  }
}

class WizardStateNotifier extends StateNotifier<WizardState> {
  WizardStateNotifier() : super(const WizardState());

  /// Force a fresh state. Called from the wizard screen's initState to
  /// guarantee currentStep=0 on every mount, regardless of autoDispose
  /// timing or hot-reload artifacts.
  void reset() => state = const WizardState();

  void next() => state = state.copyWith(currentStep: state.currentStep + 1);
  void back() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void setName(String name) => state = state.copyWith(confirmedName: name);
  void incrementHousehold() => state = state.copyWith(
        householdAddedCount: state.householdAddedCount + 1,
      );
  void incrementExtended() => state = state.copyWith(
        extendedAddedCount: state.extendedAddedCount + 1,
      );
  void setReminderTime(TimeOfDay time) =>
      state = state.copyWith(reminderTime: time);
  void setPermissionGranted(bool granted) =>
      state = state.copyWith(permissionGranted: granted);
}

final wizardStateProvider =
    StateNotifierProvider.autoDispose<WizardStateNotifier, WizardState>(
  (ref) => WizardStateNotifier(),
);

// =============================================================================
// Parent screen
// =============================================================================

class OnboardingWizardScreen extends ConsumerStatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  ConsumerState<OnboardingWizardScreen> createState() =>
      _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState
    extends ConsumerState<OnboardingWizardScreen> {
  @override
  void initState() {
    super.initState();
    // Force fresh wizard state on every mount. Without this, a redirect
    // loop or autoDispose-not-yet-fired could leak previous session's
    // currentStep into the new mount, making the wizard appear to
    // "start at the end" (e.g. step 5 if a prior run got that far).
    // ref.read on the notifier eagerly creates it, then reset() puts it
    // back to defaults. Runs synchronously before the first build —
    // no flash.
    ref.read(wizardStateProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final wizard = ref.watch(wizardStateProvider);
    // The seeded admin screens drive the visible content + per-step action
    // discriminator. Falls back to OnboardingConfigService._fallbackScreens
    // if Supabase fetch hasn't completed.
    final screens = OnboardingConfigService.instance.getScreens(forTier: 'free');
    if (screens.isEmpty || wizard.currentStep >= screens.length) {
      // Defensive: shouldn't happen — but if it does, finish gracefully.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(AppRoutes.home);
      });
      return const SizedBox.shrink();
    }
    final screen = screens[wizard.currentStep];

    return PopScope(
      // Block accidental swipe-back. Step renderers handle explicit "back"
      // via the wizardStateNotifier.back() and the back-button on step 1
      // shows an exit-confirmation dialog.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBack(context, ref);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: GradientBackground(
          animated: true,
          child: SafeArea(
            child: Column(
              children: [
                // Progress dots (5 dots, current highlighted)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: _buildProgressDots(
                      ref, wizard.currentStep, screens.length),
                ),
                Expanded(
                  child: _renderStep(context, ref, screen),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressDots(WidgetRef ref, int current, int total) {
    final colors = ref.watch(themeColorsProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? colors.primary
                : colors.textSecondary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _renderStep(
      BuildContext context, WidgetRef ref, OnboardingScreenConfig screen) {
    switch (screen.actionType) {
      case 'confirm_name':
        return _ConfirmNameStep(screen: screen);
      case 'add_relative_household':
        return _AddRelativeStep(
          screen: screen,
          mode: WizardMode.householdOnly,
        );
      case 'add_relative_extended':
        return _AddRelativeStep(
          screen: screen,
          mode: WizardMode.extendedOnly,
        );
      case 'set_reminder_pref_and_permission':
        return _ReminderPrefStep(screen: screen);
      case 'finish':
        return _FinishStep(screen: screen);
      default:
        // Unknown action_type — render as a plain "next" presentation step
        return _PresentationStep(screen: screen);
    }
  }

  Future<void> _handleBack(BuildContext context, WidgetRef ref) async {
    final wizard = ref.read(wizardStateProvider);
    if (wizard.currentStep == 0) {
      final exit = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('هل تريد الخروج من الإعداد؟'),
          content: const Text(
            'لن تجد دليلاً لإعداد التطبيق لاحقاً. تستطيع الإكمال متى أردت من الإعدادات.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('متابعة الإعداد'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('خروج'),
            ),
          ],
        ),
      );
      if (exit == true && context.mounted) {
        // Mark setupComplete=true with a setupSkipped flag so the user isn't
        // forced through the wizard again on every launch. They can re-run
        // it from Settings (B6) if they want.
        await _markSetupComplete(context, ref, skipped: true);
      }
    } else {
      ref.read(wizardStateProvider.notifier).back();
    }
  }
}

/// Shared "mark setup complete + seed AI memory + go home" finish path.
/// Called from `_FinishStep` (full completion) and `_handleBack` on step 1
/// (setupSkipped=true variant).
Future<void> _markSetupComplete(
  BuildContext context,
  WidgetRef ref, {
  bool skipped = false,
}) async {
  final logger = AppLoggerService();
  final wizard = ref.read(wizardStateProvider);
  final user = SupabaseConfig.client.auth.currentUser;
  if (user == null) {
    if (context.mounted) context.go(AppRoutes.home);
    return;
  }

  try {
    // Read current metadata first to merge on top
    final row = await SupabaseConfig.client
        .from('users')
        .select('onboarding_metadata')
        .eq('id', user.id)
        .maybeSingle();
    final meta = (row?['onboarding_metadata'] as Map<String, dynamic>?) ?? {};
    final next = Map<String, dynamic>.from(meta)
      ..['setupComplete'] = true
      ..['permissionAsked'] = true; // wizard either fired the prompt or skipped
    if (skipped) next['setupSkipped'] = true;
    await SupabaseConfig.client
        .from('users')
        .update({'onboarding_metadata': next})
        .eq('id', user.id);

    // Local cache mirror — splash + login redirect read this synchronously
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setup_complete', true);

    // CRITICAL: update the router's in-memory cache too. Without this,
    // context.go(/home) hits the router redirect with a stale `false`
    // cache value, which redirects right back to /onboarding-wizard —
    // infinite loop. Symptom: tapping "جاهز" on step 5 looks stuck on
    // the Anees intro page (silent redirect re-mounts the wizard).
    router.setCachedSetupComplete(true);

    // Seed AI memory (only on full completion — skipped flow doesn't seed)
    if (!skipped) {
      try {
        await SupabaseConfig.client.rpc(
          'seed_onboarding_ai_memory',
          params: {
            'p_user_id': user.id,
            'p_full_name': wizard.confirmedName ?? '',
            'p_household_count': wizard.householdAddedCount,
            'p_extended_count': wizard.extendedAddedCount,
            'p_reminder_preference': wizard.reminderTime != null
                ? 'daily at ${wizard.reminderTime!.hour.toString().padLeft(2, '0')}:${wizard.reminderTime!.minute.toString().padLeft(2, '0')}'
                : 'default',
          },
        );
      } catch (e) {
        // AI seeding failure is non-blocking — wizard still completes.
        logger.warning(
          'seed_onboarding_ai_memory RPC failed (non-blocking)',
          category: LogCategory.service,
          tag: 'OnboardingWizard',
          metadata: {'error': e.toString()},
        );
      }
    }
  } catch (e) {
    logger.error(
      'Wizard finish failed',
      category: LogCategory.service,
      tag: 'OnboardingWizard',
      metadata: {'error': e.toString()},
    );
  }
  if (context.mounted) context.go(AppRoutes.home);
}

// =============================================================================
// Step 1 — Confirm name
// =============================================================================

class _ConfirmNameStep extends ConsumerStatefulWidget {
  const _ConfirmNameStep({required this.screen});
  final OnboardingScreenConfig screen;

  @override
  ConsumerState<_ConfirmNameStep> createState() => _ConfirmNameStepState();
}

class _ConfirmNameStepState extends ConsumerState<_ConfirmNameStep> {
  late final TextEditingController _nameController;
  late final bool _needsPrompt;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    final metaName = user?.userMetadata?['full_name'] as String? ??
        user?.userMetadata?['display_name'] as String? ??
        user?.userMetadata?['name'] as String?;
    final email = user?.email;
    final initial = (metaName != null && metaName.trim().isNotEmpty)
        ? metaName.trim()
        : '';
    _nameController = TextEditingController(text: initial);
    // Prompt for name when metadata name is missing OR equals the email
    // (Apple Hide-Email + some OAuth flows produce auto-generated values).
    _needsPrompt = (initial.isEmpty) ||
        (email != null && initial.toLowerCase() == email.toLowerCase());
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    final name = _nameController.text.trim();
    if (_needsPrompt && name.isEmpty) {
      UIHelpers.showSnackBar(context, 'الرجاء إدخال اسمك', isError: true);
      return;
    }
    final user = SupabaseConfig.client.auth.currentUser;
    if (user != null && name.isNotEmpty) {
      try {
        // Update both auth metadata + public.users.full_name
        await SupabaseConfig.client.auth.updateUser(
          UserAttributes(data: {'full_name': name, 'display_name': name}),
        );
        await SupabaseConfig.client
            .from('users')
            .update({'full_name': name})
            .eq('id', user.id);
      } catch (_) {
        // Non-blocking: name save failure shouldn't stop the wizard
      }
    }
    ref.read(wizardStateProvider.notifier).setName(name);
    ref.read(wizardStateProvider.notifier).next();
  }

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      screen: widget.screen,
      bodyExtra: _needsPrompt
          ? Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: TextField(
                controller: _nameController,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  labelText: 'اسمك',
                  hintText: 'كيف تحب أن نناديك؟',
                  border: OutlineInputBorder(),
                ),
              ),
            )
          : null,
      onContinue: _onContinue,
    );
  }
}

// =============================================================================
// Steps 2 + 3 — Add household / extended
// =============================================================================

class _AddRelativeStep extends ConsumerWidget {
  const _AddRelativeStep({required this.screen, required this.mode});
  final OnboardingScreenConfig screen;
  final WizardMode mode;

  int _minCount() {
    final raw = screen.metadata['min_count'];
    return raw is int ? raw : 0;
  }

  int _currentCount(WizardState state) {
    return mode == WizardMode.householdOnly
        ? state.householdAddedCount
        : state.extendedAddedCount;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(wizardStateProvider);
    final colors = ref.watch(themeColorsProvider);
    final count = _currentCount(wizard);
    final minCount = _minCount();
    final canContinue = count >= minCount;

    return _StepShell(
      screen: screen,
      bodyExtra: count > 0
          ? Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: GlassCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  mode == WizardMode.householdOnly
                      ? 'أضفت $count من أهل البيت'
                      : 'أضفت $count من الأقارب',
                  style: AppTypography.titleMedium.copyWith(
                    color: colors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : null,
      onContinue: canContinue
          ? () => ref.read(wizardStateProvider.notifier).next()
          : null,
      continueLabel: canContinue && count > 0 ? 'متابعة' : screen.buttonTextAr,
      secondaryButton: count > 0
          ? OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(mode == WizardMode.householdOnly
                  ? 'إضافة المزيد من أهل البيت'
                  : 'إضافة المزيد من الأقارب'),
              onPressed: () => _pushAddRelative(context, ref),
            )
          : GradientButton(
              text: screen.buttonTextAr,
              onPressed: () => _pushAddRelative(context, ref),
            ),
      // Skip link on extended step (min_count=1) — de-emphasized escape hatch
      skipLabel:
          mode == WizardMode.extendedOnly && count == 0 && screen.skipEnabled
              ? 'تخطي الآن'
              : null,
      onSkip: mode == WizardMode.extendedOnly
          ? () => ref.read(wizardStateProvider.notifier).next()
          : null,
    );
  }

  Future<void> _pushAddRelative(BuildContext context, WidgetRef ref) async {
    final result = await context.push<String>(
      '${AppRoutes.addRelative}?wizard=${mode.name}',
    );
    if (result != null) {
      // The wizard route variant strips wizard mode pre-add; pop returns the
      // created id. Increment the appropriate count.
      if (mode == WizardMode.householdOnly) {
        ref.read(wizardStateProvider.notifier).incrementHousehold();
      } else {
        ref.read(wizardStateProvider.notifier).incrementExtended();
      }
    }
  }
}

// =============================================================================
// Step 4 — Reminder pref + permission
// =============================================================================

class _ReminderPrefStep extends ConsumerStatefulWidget {
  const _ReminderPrefStep({required this.screen});
  final OnboardingScreenConfig screen;

  @override
  ConsumerState<_ReminderPrefStep> createState() => _ReminderPrefStepState();
}

class _ReminderPrefStepState extends ConsumerState<_ReminderPrefStep> {
  TimeOfDay? _picked;

  TimeOfDay _defaultTime() {
    final raw = widget.screen.metadata['default_time'] as String?;
    if (raw == null) return const TimeOfDay(hour: 9, minute: 0);
    final parts = raw.split(':');
    if (parts.length != 2) return const TimeOfDay(hour: 9, minute: 0);
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  Future<void> _pickTime() async {
    final initial = _picked ?? _defaultTime();
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      // Phase 4 digit policy: dates/times in Western digits.
      builder: (ctx, child) => Localizations.override(
        context: ctx,
        locale: const Locale('en'),
        child: child,
      ),
    );
    if (picked != null) setState(() => _picked = picked);
  }

  Future<void> _onContinue() async {
    final time = _picked ?? _defaultTime();
    final user = SupabaseConfig.client.auth.currentUser;
    if (user != null) {
      // Persist as HH:mm string in onboarding_metadata.reminderTime so the
      // founder + cron can use it later (the active cron uses
      // reminder_schedules.time per-schedule, not a user-level default —
      // but stashing the user's preferred time here lets the wizard's
      // post-finish path optionally create a default daily schedule, and
      // surfaces the value in metadata for analytics).
      try {
        final row = await SupabaseConfig.client
            .from('users')
            .select('onboarding_metadata')
            .eq('id', user.id)
            .maybeSingle();
        final meta =
            (row?['onboarding_metadata'] as Map<String, dynamic>?) ?? {};
        final next = Map<String, dynamic>.from(meta)
          ..['reminderTime'] =
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        await SupabaseConfig.client
            .from('users')
            .update({'onboarding_metadata': next})
            .eq('id', user.id);
      } catch (_) {
        // Non-blocking
      }
    }
    ref.read(wizardStateProvider.notifier).setReminderTime(time);
    // Now that the user has chosen a time, the OS permission prompt has
    // context. Phase 9.X.D Track A7 deferred this exact ask from app boot.
    final granted = await FCMNotificationService().requestPermission();
    ref.read(wizardStateProvider.notifier).setPermissionGranted(granted);
    if (mounted) ref.read(wizardStateProvider.notifier).next();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeColorsProvider);
    final time = _picked ?? _defaultTime();
    return _StepShell(
      screen: widget.screen,
      bodyExtra: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Text(
                'الوقت المختار',
                style: AppTypography.labelLarge.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                style: AppTypography.numberLarge.copyWith(
                  color: colors.textPrimary,
                  fontSize: 36,
                ),
                textDirection: TextDirection.ltr,
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: _pickTime,
                icon: const Icon(Icons.access_time),
                label: const Text('تغيير الوقت'),
              ),
            ],
          ),
        ),
      ),
      onContinue: _onContinue,
      continueLabel: widget.screen.buttonTextAr,
    );
  }
}

// =============================================================================
// Step 5 — Anees intro / finish
// =============================================================================

class _FinishStep extends ConsumerWidget {
  const _FinishStep({required this.screen});
  final OnboardingScreenConfig screen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _StepShell(
      screen: screen,
      onContinue: () => _markSetupComplete(context, ref),
      continueLabel: screen.buttonTextAr,
    );
  }
}

// =============================================================================
// Generic presentation fallback
// =============================================================================

class _PresentationStep extends ConsumerWidget {
  const _PresentationStep({required this.screen});
  final OnboardingScreenConfig screen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _StepShell(
      screen: screen,
      onContinue: () => ref.read(wizardStateProvider.notifier).next(),
      continueLabel: screen.buttonTextAr,
    );
  }
}

// =============================================================================
// Shared step shell — title + subtitle + optional body + CTA
// =============================================================================

class _StepShell extends ConsumerWidget {
  const _StepShell({
    required this.screen,
    this.bodyExtra,
    this.onContinue,
    this.continueLabel,
    this.secondaryButton,
    this.skipLabel,
    this.onSkip,
  });

  final OnboardingScreenConfig screen;
  final Widget? bodyExtra;
  final VoidCallback? onContinue;
  final String? continueLabel;
  final Widget? secondaryButton;
  final String? skipLabel;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeColorsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          const Spacer(flex: 1),
          // Lottie placeholder slot — Track C wires the real animations
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: colors.primaryGradient,
            ),
            child: Icon(
              _iconFor(screen.actionType),
              size: 64,
              color: colors.onPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            screen.titleAr,
            style: AppTypography.headlineMedium.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (screen.subtitleAr != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              screen.subtitleAr!,
              style: AppTypography.bodyLarge.copyWith(
                color: colors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (bodyExtra != null) bodyExtra!,
          const Spacer(flex: 2),
          if (secondaryButton != null) ...[
            secondaryButton!,
            const SizedBox(height: AppSpacing.md),
          ],
          if (onContinue != null && secondaryButton == null)
            GradientButton(
              text: continueLabel ?? screen.buttonTextAr,
              onPressed: () {
                HapticFeedback.lightImpact();
                onContinue!();
              },
            ),
          if (onContinue != null && secondaryButton != null)
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onContinue!();
              },
              child: Text(
                continueLabel ?? 'متابعة',
                style: AppTypography.labelLarge.copyWith(
                  color: colors.primary,
                ),
              ),
            ),
          if (skipLabel != null && onSkip != null)
            TextButton(
              onPressed: onSkip,
              child: Text(
                skipLabel!,
                style: AppTypography.labelMedium.copyWith(
                  color: colors.textHint,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  IconData _iconFor(String action) {
    return switch (action) {
      'confirm_name' => Icons.waving_hand_rounded,
      'add_relative_household' => Icons.home_rounded,
      'add_relative_extended' => Icons.people_alt_rounded,
      'set_reminder_pref_and_permission' => Icons.notifications_active_rounded,
      'finish' => Icons.auto_awesome_rounded,
      _ => Icons.arrow_forward_rounded,
    };
  }
}

