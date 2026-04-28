// Phase 9.X.D.B Track B — Onboarding wizard parent screen + step renderers.
//
// Renders the 5 admin_onboarding_screens-driven steps for first-run setup.
// Step index + user-input state live in this widget's State (NOT in a
// Riverpod provider) so per-mount freshness is guaranteed regardless of
// hot-reload artifacts or autoDispose timing.
//
// Phase 9.X.D.B hot-fix history (founder reports, 2026-04-28):
//   #1 Wizard opens at step 5 instead of step 1.
//   #2 + Directionality.ltr wrapper on PageView.
//   #3 + diagnostic assert exposed the root cause.
//   #4 ROOT CAUSE: postgrest's .order() defaults to DESCENDING. The
//      Supabase query in OnboardingConfigService was returning screens
//      reversed, so screens[0] was the "finish" step. Fixed at the
//      source by passing ascending: true explicitly. Audited and fixed
//      the same landmine across 15 other callsites in lib/.

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
// Parent screen — owns step index + user-input state
// =============================================================================

class OnboardingWizardScreen extends ConsumerStatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  ConsumerState<OnboardingWizardScreen> createState() =>
      _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState
    extends ConsumerState<OnboardingWizardScreen> {
  // ── Step navigation ────────────────────────────────────────────────
  int _currentStep = 0;
  late final PageController _pageController;

  // ── User-input state ───────────────────────────────────────────────
  String? _confirmedName;
  int _householdAddedCount = 0;
  int _extendedAddedCount = 0;
  TimeOfDay? _reminderTime;

  @override
  void initState() {
    super.initState();
    // Page 0 is enforced both via initialPage and a debug-only assert below.
    _pageController = PageController(initialPage: 0);

    // Permanent guard: postgrest .order() defaults to DESCENDING — see
    // OnboardingConfigService._fetchScreens(). Hot-fix #4 made the order
    // explicit; this assert prevents regressions if someone strips it.
    assert(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final screens =
            OnboardingConfigService.instance.getScreens(forTier: 'free');
        if (screens.isNotEmpty &&
            screens.first.actionType != 'confirm_name') {
          throw FlutterError(
            '[wizard] expected screens[0].actionType == "confirm_name", '
            'got "${screens.first.actionType}". The Supabase query is '
            'returning screens in the wrong order. Check the .order() '
            'call in OnboardingConfigService — postgrest defaults to '
            'descending unless ascending: true is passed explicitly.',
          );
        }
      });
      return true;
    }());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── Navigation methods ─────────────────────────────────────────────

  void _next() {
    HapticFeedback.lightImpact();
    setState(() => _currentStep++);
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _back() {
    if (_currentStep == 0) return;
    setState(() => _currentStep--);
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleBackButton(BuildContext context) async {
    if (_currentStep == 0) {
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
        await _markSetupComplete(skipped: true);
      }
    } else {
      _back();
    }
  }

  // ── Finish path ────────────────────────────────────────────────────

  Future<void> _markSetupComplete({bool skipped = false}) async {
    final logger = AppLoggerService();
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      if (mounted) context.go(AppRoutes.home);
      return;
    }

    try {
      final row = await SupabaseConfig.client
          .from('users')
          .select('onboarding_metadata')
          .eq('id', user.id)
          .maybeSingle();
      final meta = (row?['onboarding_metadata'] as Map<String, dynamic>?) ?? {};
      final next = Map<String, dynamic>.from(meta)
        ..['setupComplete'] = true
        ..['permissionAsked'] = true;
      if (skipped) next['setupSkipped'] = true;
      await SupabaseConfig.client
          .from('users')
          .update({'onboarding_metadata': next})
          .eq('id', user.id);

      // Local mirror — splash + login redirect read this synchronously.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('setup_complete', true);

      // CRITICAL: update the router's in-memory cache too so the navigation
      // below doesn't get bounced back to the wizard via redirect Case 2b.
      router.setCachedSetupComplete(true);

      // Seed AI memory (only on full completion — skipped flow doesn't seed)
      if (!skipped) {
        try {
          await SupabaseConfig.client.rpc(
            'seed_onboarding_ai_memory',
            params: {
              'p_user_id': user.id,
              'p_full_name': _confirmedName ?? '',
              'p_household_count': _householdAddedCount,
              'p_extended_count': _extendedAddedCount,
              'p_reminder_preference': _reminderTime != null
                  ? 'daily at ${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
                  : 'default',
            },
          );
        } catch (e) {
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
    if (mounted) context.go(AppRoutes.home);
  }

  // ── Per-step actions ───────────────────────────────────────────────

  Future<void> _saveNameAndAdvance(String name) async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user != null && name.isNotEmpty) {
      try {
        await SupabaseConfig.client.auth.updateUser(
          UserAttributes(data: {'full_name': name, 'display_name': name}),
        );
        await SupabaseConfig.client
            .from('users')
            .update({'full_name': name})
            .eq('id', user.id);
      } catch (_) {
        // Non-blocking — name save failure shouldn't stop the wizard
      }
    }
    setState(() => _confirmedName = name);
    _next();
  }

  Future<void> _pushAddRelative(WizardMode mode) async {
    final result = await context.push<String>(
      '${AppRoutes.addRelative}?wizard=${mode.name}',
    );
    if (result != null && mounted) {
      setState(() {
        if (mode == WizardMode.householdOnly) {
          _householdAddedCount++;
        } else {
          _extendedAddedCount++;
        }
      });
    }
  }

  Future<void> _saveReminderAndAdvance(TimeOfDay time) async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user != null) {
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
    setState(() => _reminderTime = time);
    // OS permission prompt fires here — user has just chosen their preferred
    // time so the prompt has context (Phase 9.X.D Track A7's deferral pays off).
    // Grant outcome is not stored (the OS settings are the source of truth);
    // we just need the prompt to fire at this moment with the right context.
    await FCMNotificationService().requestPermission();
    if (mounted) _next();
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screens = OnboardingConfigService.instance.getScreens(forTier: 'free');
    if (screens.isEmpty) {
      // Defensive: fallback list should never be empty, but if it is,
      // navigate home rather than render nothing.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.home);
      });
      return const SizedBox.shrink();
    }

    // Clamp _currentStep defensively so navigation never lands out of range.
    if (_currentStep >= screens.length) {
      _currentStep = screens.length - 1;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBackButton(context);
      },
      // GradientBackground OUTSIDE the Scaffold so it covers the full screen
      // including the area behind the on-screen keyboard. The Scaffold's
      // body shrinks for the keyboard inset, but the gradient persists,
      // preventing a black strip from appearing when a text field opens
      // the keyboard.
      child: GradientBackground(
        animated: true,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(_currentStep, screens.length),
                Expanded(
                  // No Directionality override — native RTL flows page 0 to
                  // the right side and animates "next" sliding in from the
                  // left, matching Arabic reading direction.
                  child: PageView.builder(
                    controller: _pageController,
                    // Block swipe — buttons advance the wizard.
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: screens.length,
                    onPageChanged: (page) {
                      if (_currentStep != page) {
                        setState(() => _currentStep = page);
                      }
                    },
                    itemBuilder: (context, index) {
                      return _buildStep(screens[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int current, int total) {
    final colors = ref.watch(themeColorsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          // Back button — RTL convention: arrow points right (toward the
          // start of reading). Hidden on step 0 (PopScope handles exit).
          SizedBox(
            width: 48,
            height: 48,
            child: current > 0
                ? IconButton(
                    onPressed: _back,
                    icon: Icon(
                      Icons.arrow_forward_rounded,
                      color: colors.textOnGradient,
                    ),
                    tooltip: 'رجوع',
                  )
                : null,
          ),
          Expanded(child: _buildProgressDots(current, total)),
          // Symmetric spacer so the dots stay centered.
          const SizedBox(width: 48, height: 48),
        ],
      ),
    );
  }

  Widget _buildProgressDots(int current, int total) {
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

  Widget _buildStep(OnboardingScreenConfig screen) {
    switch (screen.actionType) {
      case 'confirm_name':
        return _ConfirmNameStep(
          screen: screen,
          onContinue: _saveNameAndAdvance,
        );
      case 'add_relative_household':
        return _AddRelativeStep(
          screen: screen,
          mode: WizardMode.householdOnly,
          count: _householdAddedCount,
          onAdd: () => _pushAddRelative(WizardMode.householdOnly),
          onContinue: _next,
        );
      case 'add_relative_extended':
        return _AddRelativeStep(
          screen: screen,
          mode: WizardMode.extendedOnly,
          count: _extendedAddedCount,
          onAdd: () => _pushAddRelative(WizardMode.extendedOnly),
          onContinue: _next,
        );
      case 'set_reminder_pref_and_permission':
        return _ReminderPrefStep(
          screen: screen,
          onContinue: _saveReminderAndAdvance,
        );
      case 'finish':
        return _FinishStep(
          screen: screen,
          onContinue: () => _markSetupComplete(skipped: false),
        );
      default:
        return _PresentationStep(screen: screen, onContinue: _next);
    }
  }
}

// =============================================================================
// Step 1 — Confirm name
// =============================================================================

class _ConfirmNameStep extends ConsumerStatefulWidget {
  const _ConfirmNameStep({required this.screen, required this.onContinue});
  final OnboardingScreenConfig screen;
  final Future<void> Function(String name) onContinue;

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
    await widget.onContinue(name);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeColorsProvider);
    final onGradient = colors.textOnGradient;
    return _StepShell(
      screen: widget.screen,
      bodyExtra: _needsPrompt
          ? Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: TextField(
                controller: _nameController,
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge.copyWith(color: onGradient),
                cursorColor: onGradient,
                decoration: InputDecoration(
                  hintText: 'كيف تحب أن نناديك؟',
                  hintStyle: AppTypography.bodyLarge.copyWith(
                    color: onGradient.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: onGradient.withValues(alpha: 0.1),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusLg),
                    borderSide: BorderSide(
                      color: onGradient.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusLg),
                    borderSide: BorderSide(
                      color: onGradient.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusLg),
                    borderSide: BorderSide(
                      color: onGradient.withValues(alpha: 0.7),
                      width: 2,
                    ),
                  ),
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
  const _AddRelativeStep({
    required this.screen,
    required this.mode,
    required this.count,
    required this.onAdd,
    required this.onContinue,
  });

  final OnboardingScreenConfig screen;
  final WizardMode mode;
  final int count;
  final VoidCallback onAdd;
  final VoidCallback onContinue;

  int _minCount() {
    final raw = screen.metadata['min_count'];
    return raw is int ? raw : 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeColorsProvider);
    final minCount = _minCount();
    final canContinue = count >= minCount;
    final showSkipOnExtended =
        mode == WizardMode.extendedOnly && count == 0 && screen.skipEnabled;

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
      // CTA structure:
      //   - count == 0  → primary "Add", optional skip on extended.
      //   - count >= 1  → primary "متابعة" (proceed), secondary "Add more".
      // The earlier UX (primary always = Add, tiny tertiary "متابعة") trapped
      // users on this step; founder couldn't find a way forward.
      onContinue: count > 0 && canContinue ? onContinue : onAdd,
      continueLabel: count > 0 && canContinue ? 'متابعة' : screen.buttonTextAr,
      tertiaryLabel: count > 0
          ? (mode == WizardMode.householdOnly
              ? 'إضافة المزيد من أهل البيت'
              : 'إضافة المزيد من الأقارب')
          : null,
      onTertiary: count > 0 ? onAdd : null,
      // Skip link on extended step (de-emphasized, only when count=0)
      skipLabel: showSkipOnExtended ? 'تخطي الآن' : null,
      onSkip: showSkipOnExtended ? onContinue : null,
    );
  }
}

// =============================================================================
// Step 4 — Reminder pref + permission
// =============================================================================

class _ReminderPrefStep extends ConsumerStatefulWidget {
  const _ReminderPrefStep({required this.screen, required this.onContinue});
  final OnboardingScreenConfig screen;
  final Future<void> Function(TimeOfDay time) onContinue;

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
      builder: (ctx, child) => Localizations.override(
        context: ctx,
        locale: const Locale('en'),
        child: child,
      ),
    );
    if (picked != null) setState(() => _picked = picked);
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
      onContinue: () => widget.onContinue(time),
      continueLabel: widget.screen.buttonTextAr,
    );
  }
}

// =============================================================================
// Step 5 — Anees intro / finish
// =============================================================================

class _FinishStep extends ConsumerWidget {
  const _FinishStep({required this.screen, required this.onContinue});
  final OnboardingScreenConfig screen;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _StepShell(
      screen: screen,
      onContinue: onContinue,
      continueLabel: screen.buttonTextAr,
    );
  }
}

// =============================================================================
// Generic presentation fallback
// =============================================================================

class _PresentationStep extends ConsumerWidget {
  const _PresentationStep({required this.screen, required this.onContinue});
  final OnboardingScreenConfig screen;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _StepShell(
      screen: screen,
      onContinue: onContinue,
      continueLabel: screen.buttonTextAr,
    );
  }
}

// =============================================================================
// Shared step shell — title + subtitle + optional body + CTA stack
// =============================================================================

class _StepShell extends ConsumerWidget {
  const _StepShell({
    required this.screen,
    this.bodyExtra,
    this.onContinue,
    this.continueLabel,
    this.tertiaryLabel,
    this.onTertiary,
    this.skipLabel,
    this.onSkip,
  });

  final OnboardingScreenConfig screen;
  final Widget? bodyExtra;
  final VoidCallback? onContinue;
  final String? continueLabel;
  // Optional second button beneath the primary CTA (e.g. "متابعة" on
  // add-relative steps when count > 0).
  final String? tertiaryLabel;
  final VoidCallback? onTertiary;
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
          if (onContinue != null)
            GradientButton(
              text: continueLabel ?? screen.buttonTextAr,
              onPressed: () {
                HapticFeedback.lightImpact();
                onContinue!();
              },
            ),
          if (tertiaryLabel != null && onTertiary != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onTertiary!();
              },
              child: Text(
                tertiaryLabel!,
                style: AppTypography.labelLarge.copyWith(
                  color: colors.primary,
                ),
              ),
            ),
          ],
          if (skipLabel != null && onSkip != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: onSkip,
              child: Text(
                skipLabel!,
                style: AppTypography.labelMedium.copyWith(
                  color: colors.textHint,
                ),
              ),
            ),
          ],
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
