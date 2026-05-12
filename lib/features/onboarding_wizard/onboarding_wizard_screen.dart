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
import '../../core/providers/cache_provider.dart';
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
import '../../shared/widgets/glass_dialog.dart';
import '../relatives/screens/add_relative_screen.dart';
import '../subscription/screens/paywall_screen.dart';

// =============================================================================
// Reminder frequency — 5 cadences the wizard exposes (matches the app's
// reminder feature set: daily / weekly / Fridays / monthly / occasions).
// `key` is the value persisted to onboarding_metadata + sent to the AI
// memory seeder so downstream systems get a stable identifier.
// =============================================================================

enum ReminderFrequency {
  daily('daily', 'يومياً', Icons.today_rounded),
  weekly('weekly', 'أسبوعياً', Icons.view_week_rounded),
  fridays('fridays', 'كل يوم جمعة', Icons.mosque_rounded),
  monthly('monthly', 'شهرياً', Icons.calendar_month_rounded),
  occasions('occasions', 'مناسبات خاصة', Icons.celebration_rounded);

  final String key;
  final String labelAr;
  final IconData icon;
  const ReminderFrequency(this.key, this.labelAr, this.icon);

  /// True if a time-of-day picker is meaningful for this cadence.
  /// Special occasions don't fire on a fixed daily clock.
  bool get usesTimeOfDay => this != ReminderFrequency.occasions;
}

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
  /// Highest step index the user has navigated to (forward) — including
  /// via "Skip". Once they've passed a step, swiping back and then forward
  /// across it shouldn't re-trigger the data gate; that's a revisit, not a
  /// new progression. Founder rationale: skipping IS a choice.
  int _maxStepReached = 0;
  late final PageController _pageController;

  // ── User-input state ───────────────────────────────────────────────
  String? _confirmedName;
  /// 'male' | 'female' — set by the confirm_gender step. Persisted to
  /// auth metadata + the user's personal NULL-scope self-node so
  /// downstream features (cross-group personal shadows, relationship
  /// inference) can resolve gender-dependent labels.
  String? _selectedGender;
  // IDs (not just counts) — needed to build the reminder_schedules row
  // at finish-time so the user actually receives reminders. Counts derive
  // from list length.
  final List<String> _householdRelativeIds = [];
  final List<String> _extendedRelativeIds = [];
  int get _householdAddedCount => _householdRelativeIds.length;
  int get _extendedAddedCount => _extendedRelativeIds.length;
  TimeOfDay? _reminderTime;
  ReminderFrequency _reminderFrequency = ReminderFrequency.daily;

  @override
  void initState() {
    super.initState();
    // Page 0 is enforced both via initialPage and a debug-only assert below.
    _pageController = PageController(initialPage: 0);

    // If the auth metadata already carries a usable full_name (e.g. Google
    // sign-in), pre-populate _confirmedName so the welcome step's gate is
    // satisfied immediately and the user can swipe past without retyping.
    final user = SupabaseConfig.client.auth.currentUser;
    final metaName = user?.userMetadata?['full_name'] as String? ??
        user?.userMetadata?['display_name'] as String? ??
        user?.userMetadata?['name'] as String?;
    final email = user?.email;
    if (metaName != null &&
        metaName.trim().isNotEmpty &&
        (email == null ||
            metaName.toLowerCase() != email.toLowerCase())) {
      _confirmedName = metaName.trim();
    }

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
    setState(() {
      _currentStep++;
      if (_currentStep > _maxStepReached) _maxStepReached = _currentStep;
    });
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
        builder: (ctx) => GlassDialog(
          icon: Icons.exit_to_app_rounded,
          title: 'هل تريد الخروج من الإعداد؟',
          subtitle:
              'لن تجد دليلاً لإعداد التطبيق لاحقاً. تستطيع الإكمال متى أردت من الإعدادات.',
          content: const SizedBox.shrink(),
          actions: [
            GlassActionButton(
              text: 'خروج',
              onPressed: () => Navigator.of(ctx).pop(true),
              isDestructive: true,
            ),
            GradientButton(
              text: 'متابعة الإعداد',
              icon: Icons.arrow_forward_rounded,
              onPressed: () => Navigator.of(ctx).pop(false),
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
              'p_reminder_preference': _formatReminderPreference(),
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
    if (!mounted) return;
    // Non-skip finish path now pushes the paywall instead of the deleted
    // "Meet Anees" step. We replace the whole stack with home first so
    // dismissing the paywall lands the user on home (not back on the
    // wizard which is now setup-complete and would redirect-loop anyway).
    if (!skipped) {
      context.go(AppRoutes.home);
      // Brief delay to let go() commit before pushing on top.
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => const PaywallScreen(isFromOnboarding: true),
          fullscreenDialog: true,
        ),
      );
    } else {
      context.go(AppRoutes.home);
    }
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

  /// Persist the user's gender to BOTH auth metadata and their personal
  /// NULL-scope self-node, then advance. Throws on failure so the calling
  /// step widget can surface the error and stay put (mandatory step — no
  /// silent advance on error). The two writes happen sequentially; if the
  /// auth update succeeds but the relatives update fails, we still throw
  /// — onboarding_metadata only mattered for downstream consumers if both
  /// landed.
  Future<void> _saveGenderAndAdvance(String gender) async {
    final logger = AppLoggerService();
    try {
      final client = SupabaseConfig.client;
      final user = client.auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      // 1. Auth metadata — merge into existing so we don't clobber other
      // keys (full_name, display_name, etc. set by _saveNameAndAdvance).
      final existingMeta =
          Map<String, dynamic>.from(user.userMetadata ?? const {});
      await client.auth.updateUser(
        UserAttributes(data: {
          ...existingMeta,
          'gender': gender,
        }),
      );

      // 2. Personal NULL-scope self-node — the row created by handle_new_user
      // when the user signed up. Filtering on (user_id, is_self, family_group
      // IS NULL) uniquely identifies it.
      await client
          .from('relatives')
          .update({'gender': gender})
          .eq('user_id', user.id)
          .eq('is_self', true)
          .isFilter('family_group_id', null);

      if (!mounted) return;
      setState(() => _selectedGender = gender);
      _next();
    } catch (e, stack) {
      logger.error(
        'Wizard gender save failed',
        category: LogCategory.service,
        tag: 'OnboardingWizard',
        metadata: {'error': e.toString(), 'gender': gender},
        stackTrace: stack,
      );
      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          'تعذّر حفظ الجنس: ${e.toString()}',
          isError: true,
        );
      }
      rethrow;
    }
  }

  Future<void> _pushAddRelative(WizardMode mode) async {
    final result = await context.push<String>(
      '${AppRoutes.addRelative}?wizard=${mode.name}',
    );
    if (result != null && mounted) {
      setState(() {
        if (mode == WizardMode.householdOnly) {
          _householdRelativeIds.add(result);
        } else {
          _extendedRelativeIds.add(result);
        }
      });
    }
  }

  String _formatReminderPreference() {
    final time = _reminderTime;
    if (_reminderFrequency.usesTimeOfDay && time != null) {
      final hh = time.hour.toString().padLeft(2, '0');
      final mm = time.minute.toString().padLeft(2, '0');
      return '${_reminderFrequency.key} at $hh:$mm';
    }
    return _reminderFrequency.key;
  }

  Future<void> _saveReminderAndAdvance(
    ReminderFrequency frequency,
    TimeOfDay? time,
  ) async {
    final logger = AppLoggerService();
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
          ..['reminderFrequency'] = frequency.key;
        if (time != null && frequency.usesTimeOfDay) {
          next['reminderTime'] =
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        } else {
          next.remove('reminderTime');
        }
        await SupabaseConfig.client
            .from('users')
            .update({'onboarding_metadata': next})
            .eq('id', user.id);
      } catch (_) {
        // Non-blocking
      }

      // Phase 9.X.D.B fix: also create an actual reminder_schedules row so
      // the cron edge functions have something to fire on. Previously only
      // onboarding_metadata was written and the user never received reminders
      // despite picking frequency + time. Targets the EXTENDED relatives
      // only (the wizard copy explicitly says household members aren't
      // reminded — "we won't disturb you about people you see daily").
      final scheduleFreq = _wizardFrequencyToScheduleFrequency(frequency);
      if (scheduleFreq != null && _extendedRelativeIds.isNotEmpty) {
        try {
          final payload = <String, dynamic>{
            'user_id': user.id,
            'frequency': scheduleFreq,
            'is_active': true,
            'relative_ids': _extendedRelativeIds,
            if (frequency.usesTimeOfDay && time != null)
              'time':
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
          };
          await ref
              .read(reminderSchedulesRepositoryProvider)
              .createSchedule(payload);
          logger.info(
            'Onboarding reminder schedule created',
            category: LogCategory.service,
            tag: 'OnboardingWizard',
            metadata: {
              'frequency': scheduleFreq,
              'relativeCount': _extendedRelativeIds.length,
            },
          );
        } catch (e, stack) {
          logger.error(
            'Onboarding reminder schedule creation failed (non-blocking)',
            category: LogCategory.service,
            tag: 'OnboardingWizard',
            metadata: {'error': e.toString()},
            stackTrace: stack,
          );
        }
      }
    }
    setState(() {
      _reminderFrequency = frequency;
      _reminderTime = frequency.usesTimeOfDay ? time : null;
    });
    // OS permission prompt fires here — user has chosen their cadence so the
    // prompt has context (Phase 9.X.D Track A7's deferral pays off).
    await FCMNotificationService().requestPermission();
    if (!mounted) return;
    // Reminder is now the LAST step (Anees "finish" page deactivated in
    // admin_onboarding_screens). If we're at the last index, run the
    // finish flow directly — _next() would otherwise clamp back to here.
    final screens =
        OnboardingConfigService.instance.getScreens(forTier: 'free');
    if (_currentStep >= screens.length - 1) {
      await _markSetupComplete(skipped: false);
    } else {
      _next();
    }
  }

  /// Map the wizard's ReminderFrequency to the value the
  /// `reminder_schedules.frequency` column accepts. Returns null for
  /// "occasions" — no scheduled-cron equivalent exists; that flow is
  /// handled separately by the special-occasion notification path.
  String? _wizardFrequencyToScheduleFrequency(ReminderFrequency f) {
    switch (f) {
      case ReminderFrequency.daily:
        return 'daily';
      case ReminderFrequency.weekly:
        return 'weekly';
      case ReminderFrequency.fridays:
        return 'friday';
      case ReminderFrequency.monthly:
        return 'monthly';
      case ReminderFrequency.occasions:
        return null;
    }
  }

  // ── Step gating ────────────────────────────────────────────────────

  /// Whether the user has satisfied the bare minimum on `step` so they're
  /// allowed to advance past it. Backward navigation is always allowed —
  /// only forward swipe is gated.
  bool _isStepComplete(int step, List<OnboardingScreenConfig> screens) {
    if (step < 0 || step >= screens.length) return true;
    final screen = screens[step];
    switch (screen.actionType) {
      case 'confirm_name':
        // Satisfied when the user has either typed-and-saved a name or
        // arrived with a usable name in auth metadata (init populates it).
        return _confirmedName != null && _confirmedName!.trim().isNotEmpty;
      case 'confirm_gender':
        // Mandatory — no advance until the user picks male or female.
        return _selectedGender != null;
      case 'add_relative_household':
        final minCount = (screen.metadata['min_count'] as int?) ?? 0;
        return _householdAddedCount >= minCount;
      case 'add_relative_extended':
        final minCount = (screen.metadata['min_count'] as int?) ?? 0;
        // Extended step has a "skip" affordance when count == 0; respect
        // that escape hatch by also passing the gate via skipEnabled.
        if (minCount == 0) return true;
        if (_extendedAddedCount >= minCount) return true;
        return false;
      default:
        return true;
    }
  }

  void _showGateBlockedFeedback() {
    HapticFeedback.heavyImpact();
    if (mounted) {
      UIHelpers.showSnackBar(
        context,
        'أكمل هذه الخطوة قبل المتابعة',
        isError: true,
      );
    }
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
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: _buildProgressDots(_currentStep, screens.length),
                ),
                Expanded(
                  // Native RTL Directionality: page 0 renders on the right
                  // and "next" slides in from the left (Arabic reading flow).
                  // Swipe is enabled — backward always, forward only when
                  // the current step's gate is satisfied. If the user
                  // swipes forward past an unsatisfied gate, snap back +
                  // haptic + snackbar.
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: screens.length,
                    onPageChanged: (page) {
                      // Forward swipe gate: only block when the user is
                      // crossing INTO new territory. If they've already
                      // reached `page` before (via Next or Skip), this
                      // is a revisit — let them through. Skipping IS a
                      // choice; the user shouldn't be re-trapped at the
                      // same gate after they already passed it.
                      final isNewTerritory = page > _maxStepReached;
                      if (page > _currentStep &&
                          isNewTerritory &&
                          !_isStepComplete(_currentStep, screens)) {
                        _showGateBlockedFeedback();
                        WidgetsBinding.instance
                            .addPostFrameCallback((_) {
                          if (!mounted) return;
                          _pageController.animateToPage(
                            _currentStep,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          );
                        });
                        return;
                      }
                      if (_currentStep != page) {
                        setState(() {
                          _currentStep = page;
                          if (page > _maxStepReached) {
                            _maxStepReached = page;
                          }
                        });
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
          initialName: _confirmedName ?? '',
          onContinue: _saveNameAndAdvance,
        );
      case 'confirm_gender':
        return _ConfirmGenderStep(
          screen: screen,
          initialGender: _selectedGender,
          onContinue: _saveGenderAndAdvance,
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
          initialFrequency: _reminderFrequency,
          initialTime: _reminderTime,
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
  const _ConfirmNameStep({
    required this.screen,
    required this.initialName,
    required this.onContinue,
  });
  final OnboardingScreenConfig screen;
  final String initialName;
  final Future<void> Function(String name) onContinue;

  @override
  ConsumerState<_ConfirmNameStep> createState() => _ConfirmNameStepState();
}

class _ConfirmNameStepState extends ConsumerState<_ConfirmNameStep> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    // Always show the field — pre-filled from the parent's lifted state
    // (auth metadata seed OR a previous typed-and-saved name). The earlier
    // hide-when-metadata-set logic broke back-navigation: after the user
    // saved a name, swiping back found the field gone.
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
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
      reassuranceText: 'يمكنك تغيير اسمك في أي وقت من الإعدادات',
      bodyExtra: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: TextField(
          controller: _nameController,
          textAlign: TextAlign.center,
          // Dark keyboard variant matches the wizard's dark gradient
          // backdrop. Without this, iOS draws a light keyboard which
          // looks like a stray white panel under the field.
          keyboardAppearance: Brightness.dark,
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
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              borderSide: BorderSide(
                color: onGradient.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              borderSide: BorderSide(
                color: onGradient.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              borderSide: BorderSide(
                color: onGradient.withValues(alpha: 0.7),
                width: 2,
              ),
            ),
          ),
        ),
      ),
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
      reassuranceText: mode == WizardMode.householdOnly
          ? 'تستطيع إضافة أو تعديل أهل البيت لاحقاً من قائمة الأقارب'
          : 'تستطيع إضافة أو تعديل الأقارب لاحقاً من قائمة الأقارب',
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
  const _ReminderPrefStep({
    required this.screen,
    required this.initialFrequency,
    required this.initialTime,
    required this.onContinue,
  });
  final OnboardingScreenConfig screen;
  final ReminderFrequency initialFrequency;
  final TimeOfDay? initialTime;
  final Future<void> Function(ReminderFrequency frequency, TimeOfDay? time)
      onContinue;

  @override
  ConsumerState<_ReminderPrefStep> createState() => _ReminderPrefStepState();
}

class _ReminderPrefStepState extends ConsumerState<_ReminderPrefStep> {
  late ReminderFrequency _frequency;
  TimeOfDay? _picked;

  @override
  void initState() {
    super.initState();
    _frequency = widget.initialFrequency;
    _picked = widget.initialTime;
  }

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
    final onGradient = colors.textOnGradient;
    final time = _picked ?? _defaultTime();
    final showsTime = _frequency.usesTimeOfDay;

    return _StepShell(
      screen: widget.screen,
      reassuranceText:
          'يمكنك تغيير التذكيرات أو إضافة جداول جديدة من شاشة التذكيرات',
      bodyExtra: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: Column(
          children: [
            // Frequency selector — 5 compact pill chips in a centered Wrap.
            // Replaces the earlier full-width tile-stack (made the page too
            // tall on small screens — founder feedback).
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final f in ReminderFrequency.values)
                  _FrequencyChip(
                    frequency: f,
                    selected: f == _frequency,
                    onTap: () => setState(() => _frequency = f),
                  ),
              ],
            ),
            // Time picker — only meaningful when the cadence has a time of day.
            if (showsTime) ...[
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule_rounded,
                      color: onGradient.withValues(alpha: 0.85), size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                    style: AppTypography.numberLarge.copyWith(
                      color: onGradient,
                      fontSize: 28,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  TextButton(
                    onPressed: _pickTime,
                    child: Text(
                      'تغيير',
                      style: AppTypography.labelLarge.copyWith(
                        color: onGradient,
                        decoration: TextDecoration.underline,
                        decorationColor: onGradient,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      onContinue: () => widget.onContinue(
        _frequency,
        showsTime ? time : null,
      ),
      continueLabel: widget.screen.buttonTextAr,
    );
  }
}

// =============================================================================
// Frequency chip — compact pill in a Wrap, used by the reminder step.
// (Replaced the earlier full-width _FrequencyTile that made the step too tall
// on small screens.)
// =============================================================================

class _FrequencyChip extends ConsumerWidget {
  const _FrequencyChip({
    required this.frequency,
    required this.selected,
    required this.onTap,
  });
  final ReminderFrequency frequency;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeColorsProvider);
    final onGradient = colors.textOnGradient;
    final fillAlpha = selected ? 0.22 : 0.08;
    final borderAlpha = selected ? 0.85 : 0.3;
    return Semantics(
      button: true,
      selected: selected,
      label: frequency.labelAr,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: onGradient.withValues(alpha: fillAlpha),
              borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
              border: Border.all(
                color: onGradient.withValues(alpha: borderAlpha),
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(frequency.icon, color: onGradient, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  frequency.labelAr,
                  style: AppTypography.labelLarge.copyWith(
                    color: onGradient,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
    this.reassuranceText,
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
  /// Small reassurance line shown right above the primary CTA — tells the
  /// user this step's data isn't a one-shot commitment ("you can change
  /// this later"). Reduces commitment-anxiety during first-run setup.
  final String? reassuranceText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeColorsProvider);
    final onGradient = colors.textOnGradient;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          // Scrollable content area — guarantees the reminder step's
          // 5 frequency options + time picker fit on small screens, and
          // long content centers via IntrinsicHeight + Spacer.
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const Spacer(flex: 1),
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
                            color: onGradient,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (screen.subtitleAr != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            screen.subtitleAr!,
                            style: AppTypography.bodyLarge.copyWith(
                              color: onGradient.withValues(alpha: 0.85),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        if (bodyExtra != null) bodyExtra!,
                        const Spacer(flex: 2),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (reassuranceText != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: onGradient.withValues(alpha: 0.6),
                    size: 14,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      reassuranceText!,
                      style: AppTypography.labelMedium.copyWith(
                        color: onGradient.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            // OutlinedGradientButton instead of a plain TextButton so the
            // secondary "إضافة المزيد" CTA is visibly tappable on the
            // gradient background (WCAG contrast).
            OutlinedGradientButton(
              text: tertiaryLabel!,
              onPressed: () {
                HapticFeedback.lightImpact();
                onTertiary!();
              },
              icon: Icons.add_rounded,
            ),
          ],
          if (skipLabel != null && onSkip != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: onSkip,
              child: Text(
                skipLabel!,
                style: AppTypography.labelLarge.copyWith(
                  color: onGradient.withValues(alpha: 0.7),
                  decoration: TextDecoration.underline,
                  decorationColor: onGradient.withValues(alpha: 0.7),
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
      'confirm_gender' => Icons.wc_rounded,
      'add_relative_household' => Icons.home_rounded,
      'add_relative_extended' => Icons.people_alt_rounded,
      'set_reminder_pref_and_permission' => Icons.notifications_active_rounded,
      'finish' => Icons.auto_awesome_rounded,
      _ => Icons.arrow_forward_rounded,
    };
  }
}

// =============================================================================
// Step 2 — Confirm gender (mandatory)
//
// Two large tappable cards (ذكر / أنثى). Selection is required; the CTA
// stays disabled until the user picks one. On submit the parent's
// _saveGenderAndAdvance runs the dual write (auth metadata + personal
// self-node) and advances. If that throws, _saving resets so the user
// can retry.
// =============================================================================

class _ConfirmGenderStep extends ConsumerStatefulWidget {
  const _ConfirmGenderStep({
    required this.screen,
    required this.initialGender,
    required this.onContinue,
  });
  final OnboardingScreenConfig screen;
  final String? initialGender;
  final Future<void> Function(String gender) onContinue;

  @override
  ConsumerState<_ConfirmGenderStep> createState() =>
      _ConfirmGenderStepState();
}

class _ConfirmGenderStepState extends ConsumerState<_ConfirmGenderStep> {
  String? _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialGender;
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (_selected == null) {
      // Mirror _ConfirmNameStep's UX: show a snackbar instead of silently
      // ignoring the tap. The visible CTA stays so the user has something
      // to interact with from the start.
      UIHelpers.showSnackBar(
        context,
        'الرجاء اختيار الجنس قبل المتابعة',
        isError: true,
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onContinue(_selected!);
    } catch (_) {
      // Parent already surfaced the error via snackbar. Just unlock the
      // CTA so the user can retry without remounting the step.
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      screen: widget.screen,
      reassuranceText: 'يمكنك تغيير هذا لاحقاً من إعدادات حسابك',
      bodyExtra: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: _GenderCard(
                emoji: '👨',
                label: 'ذكر',
                selected: _selected == 'male',
                onTap: _saving
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        setState(() => _selected = 'male');
                      },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _GenderCard(
                emoji: '👩',
                label: 'أنثى',
                selected: _selected == 'female',
                onTap: _saving
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        setState(() => _selected = 'female');
                      },
              ),
            ),
          ],
        ),
      ),
      // Always show the CTA so the user has a clear next-step affordance;
      // _submit() itself gates on _selected != null and surfaces a snackbar
      // when the user taps before picking. _saving short-circuits to
      // prevent double-submit during the in-flight save.
      onContinue: _submit,
      continueLabel:
          _saving ? 'جارٍ الحفظ...' : widget.screen.buttonTextAr,
    );
  }
}

class _GenderCard extends ConsumerWidget {
  const _GenderCard({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeColorsProvider);
    final onGradient = colors.textOnGradient;
    final fillAlpha = selected ? 0.22 : 0.08;
    final borderAlpha = selected ? 1.0 : 0.30;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xl,
              horizontal: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: onGradient.withValues(alpha: fillAlpha),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: onGradient.withValues(alpha: borderAlpha),
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  label,
                  style: AppTypography.titleMedium.copyWith(
                    color: onGradient,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
