import 'dart:async';
import '../../../shared/widgets/directional_icon.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:confetti/confetti.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:uuid/uuid.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/errors/app_errors.dart';
import '../../../core/services/error_reporter.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glass_pill_title.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/glass_dialog.dart';
import '../../../shared/models/relative_model.dart';
import '../../../core/providers/cache_provider.dart';
import '../../../shared/services/supabase_storage_service.dart';
import '../../../shared/services/contacts_import_service.dart';
import '../../../shared/widgets/health_status_picker.dart';
import '../../../shared/widgets/relative_category_picker.dart';
import '../../auth/providers/auth_provider.dart';
import '../../contacts/screens/contact_import_screen.dart';
import '../../family_groups/models/family_group_model.dart';
import '../../family_groups/providers/family_group_providers.dart';
import '../../family_groups/services/shared_tree_service.dart';
import '../../family_tree/models/family_graph.dart';
import '../../family_tree/providers/family_graph_providers.dart';
import '../../family_tree/services/family_graph_service.dart';
import '../../home/providers/home_providers.dart';
import '../../../shared/utils/family_name_formatter.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../services/relationship_inference_service.dart';
import '../../../shared/widgets/flat_relationship_picker.dart';

/// Mode flag for AddRelativeScreen.
///
/// When `null`, the screen is in normal mode (category picker interactive,
/// family-group toggle visible).
///
/// When set, the screen is launched from the onboarding wizard and:
///   • The relative_category is locked to the wizard step's value
///   • The "add to shared tree" toggle is hidden (wizard is solo-user setup)
///   • On save, `context.pop(createdRelativeId)` returns the new id so the
///     wizard can increment its count
enum WizardMode {
  householdOnly,
  extendedOnly;

  RelativeCategory get category => switch (this) {
        WizardMode.householdOnly => RelativeCategory.household,
        WizardMode.extendedOnly => RelativeCategory.extended,
      };
}

class AddRelativeScreen extends ConsumerStatefulWidget {
  const AddRelativeScreen({super.key, this.wizardMode});

  /// Phase 9.X.D.B Task B4 — locks the relative_category and pops with the
  /// created relative's id when set.
  final WizardMode? wizardMode;

  @override
  ConsumerState<AddRelativeScreen> createState() => _AddRelativeScreenState();
}

class _AddRelativeScreenState extends ConsumerState<AddRelativeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  RelationshipType _selectedRelationship = RelationshipType.brother;
  Gender? _selectedGender;
  XFile? _selectedImage;
  bool _isLoading = false;
  final bool _isFavorite = false;
  int _priority = 2; // Auto-set based on relationship
  String _phoneNumber = ''; // Store phone number separately
  String? _healthStatus; // Health status of the relative
  bool _addToSharedTree = false; // Whether to add to a shared family tree
  FamilyGroup? _selectedGroup; // The selected family group (if shared)
  FamilySide? _selectedFamilySide; // Paternal or maternal side for extended family
  // In wizard mode, the category is locked to the wizard step's value at
  // initState. In normal mode, defaults to extended and the picker is
  // interactive.
  late RelativeCategory _selectedCategory;
  // Tracks whether any user input has happened. PopScope below uses this
  // to decide whether to prompt before discarding a partially-filled form.
  bool _isFormDirty = false;

  void _markDirty() {
    if (!_isFormDirty) setState(() => _isFormDirty = true);
  }

  // Contact import state
  Contact? _selectedContact;
  bool _manualExpanded = false;
  Key _phoneFieldKey = UniqueKey();
  String _phoneInitial = '';

  final SupabaseStorageService _storageService = SupabaseStorageService();

  // Confetti controller for celebration animation
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _nameController.addListener(_onNameChanged);
    _selectedCategory =
        widget.wizardMode?.category ?? RelativeCategory.extended;

    // Default-scope decision: non-admin (or no-group) -> personal,
    // admin of an active group -> shared. Deferred to post-frame so
    // `ref` is fully available. Wizard mode keeps personal default since
    // the wizard is solo-user setup.
    if (widget.wizardMode == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final isAdmin = ref.read(isAdminOfActiveGroupProvider);
        if (!isAdmin) return;
        final groupInfo = ref.read(activeFamilyGroupProvider).valueOrNull;
        if (groupInfo == null) return;
        final user = ref.read(currentUserProvider);
        if (user == null) return;
        final groups =
            ref.read(userGroupsProvider(user.id)).valueOrNull ?? const [];
        FamilyGroup? activeGroup;
        for (final g in groups) {
          if (g.id == groupInfo.groupId) {
            activeGroup = g;
            break;
          }
        }
        if (activeGroup == null) return;
        setState(() {
          _addToSharedTree = true;
          _selectedGroup = activeGroup;
        });
      });
    }
  }

  /// When the name changes, try to infer gender from the Arabic name.
  /// Only auto-fills gender if the relationship type doesn't already imply one
  /// (i.e. for cousin/other where gender is null).
  void _onNameChanged() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    // Only infer if the relationship doesn't already dictate gender
    final fromRelationship =
        RelationshipInferenceService.genderFromRelationship(_selectedRelationship);
    if (fromRelationship != null) return;

    final resolved = RelationshipInferenceService.resolveGender(
      relationshipType: _selectedRelationship,
      fullName: name,
    );
    if (resolved != null && resolved != _selectedGender) {
      setState(() => _selectedGender = resolved);
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _notesController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _storageService.pickImage();
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _isFormDirty = true;
      });
    }
  }

  Future<void> _importFromContacts() async {
    if (kIsWeb) return;
    final contact = await Navigator.of(context).push<Contact>(
      MaterialPageRoute(
        builder: (_) => const ContactImportScreen(singleSelect: true),
      ),
    );
    if (contact == null || !mounted) return;
    _onContactSelected(contact);
  }

  void _onContactSelected(Contact contact) {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final suggested = ContactsImportService().createSuggestedRelative(
      userId: user.id,
      contact: contact,
    );

    final rawPhone = contact.phones.isNotEmpty
        ? contact.phones.first.number
        : '';

    setState(() {
      _selectedContact = contact;
      _nameController.text = contact.displayName;
      _phoneInitial = rawPhone;
      _phoneNumber = rawPhone;
      _phoneFieldKey = UniqueKey();
      if (suggested['relationship_type'] != null) {
        _selectedRelationship = suggested['relationship_type'] as RelationshipType;
      }
      if (suggested['gender'] != null) {
        _selectedGender = suggested['gender'] as Gender?;
      }
      if (suggested['priority'] != null) {
        _priority = suggested['priority'] as int;
      }
      _manualExpanded = true;
      _isFormDirty = true;
    });
  }

  Future<void> _saveRelative() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw const AuthError(
          type: AuthErrorType.sessionExpired,
          message: 'User not authenticated',
          arabicMessage: 'يرجى تسجيل الدخول أولاً',
        );
      }

      // Generate a UUID for the new relative (needed for photo upload path)
      final relativeId = const Uuid().v4();

      // Upload photo if selected
      String? photoUrl;
      if (_selectedImage != null) {
        photoUrl = await _storageService.uploadRelativePhoto(
          _selectedImage!,
          user.id,
          relativeId,
        );
      }

      // Auto-suggest avatar based on relationship
      final avatarType = AvatarType.suggestFromRelationship(_selectedRelationship, _selectedGender);

      // Create relative
      final relative = Relative(
        id: '', // Will be auto-generated
        userId: user.id,
        fullName: _nameController.text.trim(),
        relationshipType: _selectedRelationship,
        gender: _selectedGender,
        avatarType: avatarType,
        phoneNumber: _phoneNumber.trim().isEmpty
            ? null
            : _phoneNumber.trim(),
        email: null,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        photoUrl: photoUrl,
        priority: _priority,
        isFavorite: _isFavorite,
        healthStatus: _healthStatus,
        familySide: _selectedFamilySide,
        relativeCategory: _selectedCategory,
        createdAt: DateTime.now(),
      );

      final String createdRelativeId;
      if (_addToSharedTree && _selectedGroup != null) {
        // Add to shared family tree
        createdRelativeId = await SharedTreeService.addSharedRelative(
          relative: relative,
          familyGroupId: _selectedGroup!.id,
          userId: user.id,
        );
      } else {
        // Add as personal relative
        final repository = ref.read(relativesRepositoryProvider);
        createdRelativeId = await repository.createRelative(relative);
      }

      // Infer and persist family graph edges so the tree intelligence
      // (perspective-shifting labels, generation layout) activates.
      // In group mode, use the shared graph data for correct inference.
      final groupInfo = ref.read(activeFamilyGroupProvider).valueOrNull;
      final isShared = _addToSharedTree && _selectedGroup != null;

      final List<FamilyEdge> existingEdges;
      List<Relative> existingRelatives;
      final String edgeUserId;

      if (isShared && groupInfo != null) {
        existingEdges = ref
                .read(sharedFamilyEdgesStreamProvider(groupInfo.groupId))
                .valueOrNull ??
            <FamilyEdge>[];
        existingRelatives = ref
                .read(groupRelativesStreamProvider(groupInfo.groupId))
                .valueOrNull ??
            <Relative>[];
        edgeUserId = groupInfo.nodeId ?? user.id;

        // Remap relatives to the ADDER's perspective so inferEdges
        // auto-linking (e.g. spouse between parents) uses correct types.
        // Without this, a non-admin adding "father" would find the admin's
        // "mother" and create a wrong spouseOf edge.
        if (groupInfo.nodeId != null && existingEdges.isNotEmpty) {
          final tempGraph = FamilyGraphService.buildGraph(
            userId: groupInfo.nodeId!,
            edges: existingEdges,
          );
          final enriched =
              FamilyGraphService.enrichAllSiblingEdges(tempGraph);
          final relativesMap = {
            for (final r in existingRelatives) r.id: r
          };
          existingRelatives = FamilyGraphService.remapForViewer(
            viewerId: groupInfo.nodeId!,
            graph: enriched,
            relatives: existingRelatives,
            relativesMap: relativesMap,
          );
        }
      } else {
        existingEdges =
            ref.read(familyEdgesStreamProvider(user.id)).valueOrNull ??
                <FamilyEdge>[];
        existingRelatives =
            ref.read(relativesStreamProvider(user.id)).valueOrNull ??
                <Relative>[];
        edgeUserId = user.id;
      }

      final inferredEdges = FamilyGraphService.inferEdges(
        userId: edgeUserId,
        newRelativeId: createdRelativeId,
        relationshipType: _selectedRelationship,
        side: _selectedFamilySide,
        existingEdges: existingEdges,
        existingRelatives: existingRelatives,
      );

      if (inferredEdges.isNotEmpty) {
        // For shared edges, set family_group_id and ensure user_id is the
        // auth user ID (not the node ID used as edge anchor for inference).
        final edgesToPersist = isShared
            ? inferredEdges
                .map((e) => FamilyEdge(
                      id: e.id,
                      userId: user.id,
                      fromId: e.fromId,
                      toId: e.toId,
                      type: e.type,
                      createdAt: e.createdAt,
                      familyGroupId: _selectedGroup!.id,
                    ))
                .toList()
            : inferredEdges;

        await SupabaseConfig.client.from('family_edges').upsert(
          edgesToPersist.map((e) => e.toJson()).toList(),
          onConflict: 'user_id,from_id,to_id,edge_type',
        );
      }

      if (!mounted) return;

      // 🎉 Celebration! Trigger confetti and haptic feedback
      _confettiController.play();
      HapticFeedback.mediumImpact();

      // Show success message
      UIHelpers.showSnackBar(
        context,
        'تم إضافة ${relative.fullName} بنجاح',
        backgroundColor: AppColors.islamicGreenPrimary,
      );

      // Reset loading state before navigation
      setState(() => _isLoading = false);

      // Invalidate every list view that could surface this new relative.
      // Personal view always; shared views when the relative was added to
      // a group (the group's relatives list AND the inferred-edges stream
      // — both feed the family-tree screen and the family-group screen).
      ref.invalidate(relativesStreamProvider(user.id));
      if (isShared && groupInfo != null) {
        ref.invalidate(groupRelativesStreamProvider(groupInfo.groupId));
        ref.invalidate(sharedFamilyEdgesStreamProvider(groupInfo.groupId));
      }

      // The form is no longer "dirty" — flip the flag so the PopScope
      // confirmation doesn't trigger on the auto-pop below.
      _isFormDirty = false;

      // Brief pause for confetti.
      await Future.delayed(const Duration(milliseconds: 400));

      if (!mounted) return;

      // Return to whichever screen pushed Add Relative. In wizard mode,
      // pop with the created relative's id so the wizard can count adds.
      // Normal mode pops with no value (existing behavior preserved).
      if (widget.wizardMode != null) {
        context.pop(createdRelativeId);
      } else {
        context.pop();
      }
    } catch (e, stackTrace) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      // Use ErrorHandlerService for user-friendly Arabic messages
      final errorMessage = errorHandler.getArabicMessage(e);
      _showMessage(errorMessage);

      // Report error to Sentry
      errorHandler.reportError(
        e,
        stackTrace: stackTrace,
        tag: 'AddRelativeScreen',
        context: {'operation': 'createRelative'},
      );
    }
  }

  void _showMessage(String message) {
    UIHelpers.showSnackBar(
       context,
      message,
      backgroundColor: AppColors.islamicGreenPrimary,
    );
  }



  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);

    // Watch existing relatives for the flat relationship picker
    final user = ref.watch(currentUserProvider);
    final groupInfo = ref.watch(activeFamilyGroupProvider).valueOrNull;

    // For singleton-slot detection (mother/father/husband/wife): we need the
    // FULL visible tree from the viewer's perspective. In group context that's
    // the merged group + viewer-personal stream; in personal mode that's the
    // viewer's own relatives. The _addToSharedTree toggle no longer matters
    // here — the singleton check is about "what's already in your tree",
    // not where you're adding the new one.
    final relativesAsync = groupInfo != null
        ? ref.watch(groupTreeRelativesProvider(groupInfo.groupId))
        : (user != null ? ref.watch(relativesStreamProvider(user.id)) : null);
    // Phase 9.X.D.A.fix Bug 1: exclude self-node from duplicate-detection.
    // The user shouldn't trigger a "duplicate name" warning against themselves.
    final existingRelatives = (relativesAsync?.valueOrNull ?? <Relative>[])
        .where((r) => !r.isSelf)
        .toList();

    final showForm = _manualExpanded || _selectedContact != null;

    return PopScope(
      // Block the system pop when the user has filled anything in; the
      // onPopInvokedWithResult callback below pops manually after the user
      // confirms via the discard dialog.
      canPop: !_isFormDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldDiscard = await _confirmDiscardChanges();
        if (!shouldDiscard) return;
        if (!mounted) return;
        if (!context.mounted) return;
        context.pop();
      },
      child: Stack(
        children: [
          Scaffold(
          body: GradientBackground(
            animated: true,
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(themeColors),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Primary CTA: Contact import ──
                          if (!kIsWeb) ...[
                            _buildContactImportCard(themeColors),
                            const SizedBox(height: AppSpacing.md),

                            // OR divider
                            if (!showForm) ...[
                              Row(
                                children: [
                                  Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.2))),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                                    child: Text(
                                      'أو',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: Colors.white.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.2))),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),

                              // Manual toggle row
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() => _manualExpanded = true);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.07),
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit_rounded,
                                        color: Colors.white.withValues(alpha: 0.6),
                                        size: 20,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Text(
                                          'إضافة يدوياً',
                                          style: AppTypography.bodyMedium.copyWith(
                                            color: Colors.white.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: Colors.white.withValues(alpha: 0.5),
                                        size: 22,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],

                          // ── Expandable form ──
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: showForm
                                ? Form(
                                    key: _formKey,
                                    // Catches every TextFormField change so
                                    // PopScope below can prompt before
                                    // discarding partially-filled forms.
                                    // Non-FormField changes (image picker,
                                    // relationship picker, phone, bool
                                    // toggles, contact import) call
                                    // _markDirty() inline.
                                    onChanged: _markDirty,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        if (!kIsWeb) const SizedBox(height: AppSpacing.md),

                                        // Selected contact chip (if came from contacts)
                                        if (_selectedContact != null) ...[
                                          _buildContactChip(themeColors),
                                          const SizedBox(height: AppSpacing.md),
                                        ],

                                        // Photo picker
                                        _buildPhotoPicker(),
                                        const SizedBox(height: AppSpacing.md),

                                        // Name
                                        _buildTextField(
                                          controller: _nameController,
                                          label: 'الاسم الكامل',
                                          hint: 'مثال: محمد أحمد',
                                          icon: Icons.person,
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'الرجاء إدخال الاسم';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: AppSpacing.md),

                                        // Relationship picker
                                        FlatRelationshipPicker(
                                          selectedType: _selectedRelationship,
                                          selectedSide: _selectedFamilySide,
                                          selectedGender: _selectedGender,
                                          existingRelatives: existingRelatives,
                                          onSelectionChanged: (type, side, gender) {
                                            setState(() {
                                              _selectedRelationship = type;
                                              _selectedFamilySide = side;
                                              if (gender != null) _selectedGender = gender;
                                              _priority = AvatarType.suggestPriority(type);
                                              _isFormDirty = true;
                                            });
                                          },
                                        ),
                                        const SizedBox(height: AppSpacing.md),

                                        // Shared tree toggle
                                        _buildSharedTreeToggle(),

                                        // Category picker — hidden in wizard
                                        // mode (the wizard step pre-locks the
                                        // category, the picker would just be
                                        // a confusing read-only tile).
                                        if (widget.wizardMode == null) ...[
                                          RelativeCategoryPicker(
                                            selected: _selectedCategory,
                                            onChanged: (value) {
                                              setState(() {
                                                _selectedCategory = value;
                                                _isFormDirty = true;
                                              });
                                            },
                                          ),
                                          const SizedBox(height: AppSpacing.md),
                                        ],

                                        // Phone
                                        IntlPhoneField(
                                          key: _phoneFieldKey,
                                          initialValue: _phoneInitial,
                                          decoration: InputDecoration(
                                            labelText: 'رقم الهاتف (اختياري)',
                                            labelStyle: AppTypography.bodyMedium.copyWith(
                                              color: Colors.white.withValues(alpha: 0.9),
                                            ),
                                            hintText: '50 123 4567',
                                            hintStyle: AppTypography.bodyMedium.copyWith(
                                              color: Colors.white.withValues(alpha: 0.5),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white.withValues(alpha: 0.1),
                                            prefixIcon: const Icon(Icons.phone, color: Colors.white70),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                              borderSide: BorderSide.none,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                              borderSide: BorderSide(
                                                color: Colors.white.withValues(alpha: 0.2),
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                              borderSide: const BorderSide(
                                                color: AppColors.islamicGreenPrimary,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                          initialCountryCode: 'SA',
                                          style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                                          dropdownTextStyle: AppTypography.bodyMedium.copyWith(color: Colors.white),
                                          dropdownIcon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                                          flagsButtonPadding: const EdgeInsets.only(left: 8),
                                          onChanged: (phone) {
                                            _phoneNumber = phone.completeNumber;
                                            _markDirty();
                                          },
                                        ),
                                        const SizedBox(height: AppSpacing.md),

                                        // Health status
                                        HealthStatusPicker(
                                          selectedStatus: _healthStatus,
                                          onStatusChanged: (status) {
                                            setState(() {
                                              _healthStatus = status;
                                              _isFormDirty = true;
                                            });
                                          },
                                        ),
                                        const SizedBox(height: AppSpacing.md),

                                        // Notes
                                        _buildTextField(
                                          controller: _notesController,
                                          label: 'ملاحظات (اختياري)',
                                          hint: 'أي معلومات إضافية...',
                                          icon: Icons.note,
                                          maxLines: 3,
                                        ),
                                        const SizedBox(height: AppSpacing.xxxl),

                                        // Save button
                                        GradientButton(
                                          text: 'حفظ القريب',
                                          onPressed: _saveRelative,
                                          isLoading: _isLoading,
                                          icon: Icons.save_rounded,
                                        ),
                                        const SizedBox(height: AppSpacing.xl),
                                      ],
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Confetti widget positioned at the top center
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
              Colors.yellow,
            ],
            numberOfParticles: 30,
            gravity: 0.3,
          ),
        ),
        ],
      ),
    );
  }

  /// Show a "discard changes?" prompt when the user backs out of a dirty
  /// form. Returns true if the user chose to discard.
  Future<bool> _confirmDiscardChanges() async {
    final themeColors = ref.read(themeColorsProvider);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => GlassDialog(
        icon: Icons.edit_off_rounded,
        iconAccent: themeColors.statusWarning,
        title: 'هل تريد الخروج بدون حفظ؟',
        subtitle: 'ستفقد المعلومات التي أدخلتها.',
        content: const SizedBox.shrink(),
        actions: [
          GlassActionButton(
            text: 'تجاهل',
            isDestructive: true,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
          GradientButton(
            text: 'متابعة التعديل',
            icon: Icons.edit_rounded,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _buildHeader(dynamic themeColors) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Semantics(
            label: 'رجوع',
            button: true,
            child: IconButton(
              icon: DirectionalIcon(Icons.arrow_back_rounded, color: themeColors.textOnGradient),
              onPressed: () => context.pop(),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const GlassPillTitle(text: 'إضافة قريب'),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: AppAnimations.normal)
        .slideY(begin: -0.2, end: 0);
  }

  Widget _buildPhotoPicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.islamicGreenPrimary.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 3,
              ),
            ],
          ),
          child: _selectedImage != null
              ? ClipOval(
                  child: kIsWeb
                      ? Image.network(
                          _selectedImage!.path,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          _selectedImage!.path,
                          fit: BoxFit.cover,
                        ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_a_photo,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'إضافة صورة',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    )
        .animate()
        .scale(duration: const Duration(milliseconds: 600))
        .fadeIn();
  }

  Widget _buildContactImportCard(dynamic themeColors) {
    final hasContact = _selectedContact != null;
    return GestureDetector(
      onTap: _importFromContacts,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Colors.white.withValues(alpha: 0.13),
              Colors.white.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: hasContact
                ? AppColors.islamicGreenPrimary.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.2),
            width: hasContact ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: themeColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: themeColors.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.contacts_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'اختر من جهات الاتصال',
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasContact
                        ? 'اضغط لتغيير جهة الاتصال'
                        : 'أسرع طريقة لإضافة قريب',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withValues(alpha: 0.4),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactChip(dynamic themeColors) {
    final contact = _selectedContact!;
    final initials = contact.displayName.isNotEmpty
        ? contact.displayName.trim().split(' ').take(2).map((w) => w[0]).join()
        : '?';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.islamicGreenPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.islamicGreenPrimary.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.islamicGreenPrimary.withValues(alpha: 0.3),
            child: Text(
              initials,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.displayName,
                  style: AppTypography.labelMedium.copyWith(color: Colors.white),
                ),
                if (contact.phones.isNotEmpty)
                  Text(
                    contact.phones.first.number,
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle_rounded,
            color: AppColors.islamicGreenPrimary,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        // Dark keyboard variant matches the gradient backdrop on iOS.
        keyboardAppearance: Brightness.dark,
        style: AppTypography.bodyMedium.copyWith(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: AppTypography.bodyMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
          hintStyle: AppTypography.bodySmall.copyWith(
            color: Colors.white.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.7)),
          border: InputBorder.none,
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }



  /// Builds the scope picker for a new relative: personal vs shared-with-group.
  ///
  /// Visibility:
  /// - If the user has no family groups, nothing is rendered (relative is
  ///   personal by default — no choice needed).
  /// - If the user is NOT the admin of their active group, nothing is
  ///   rendered (only admins can add to the shared lineage; members are
  ///   silently constrained to personal scope).
  /// - Otherwise, two cards are shown. The selection drives
  ///   [_addToSharedTree] (and [_selectedGroup] when the user belongs to
  ///   exactly one group).
  ///
  /// Defaults are seeded in [initState]: admins of the active group default
  /// to "shared"; non-admins (and no-group users) default to "personal".
  Widget _buildSharedTreeToggle() {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    // Non-admins never see the scope picker — they can only add personal
    // relatives. The default value of `_addToSharedTree` (false) handles
    // the silent "personal scope" behaviour for them.
    final isAdmin = ref.watch(isAdminOfActiveGroupProvider);
    if (!isAdmin) return const SizedBox.shrink();

    final groupsAsync = ref.watch(userGroupsProvider(user.id));

    return groupsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (groups) {
        if (groups.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  right: AppSpacing.xs, bottom: AppSpacing.sm),
              child: Text(
                'نطاق هذا القريب',
                style: AppTypography.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _ScopeOptionCard(
              icon: Icons.person_rounded,
              title: 'خاص بي',
              subtitle:
                  'لن يظهر للأعضاء الآخرين. مناسب لزوجتي، عائلتها، أصدقائي.',
              selected: !_addToSharedTree,
              onTap: () {
                if (!_addToSharedTree) return;
                setState(() {
                  _addToSharedTree = false;
                  _selectedGroup = null;
                  _isFormDirty = true;
                });
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _ScopeOptionCard(
              icon: Icons.group_rounded,
              title: 'مشترك مع المجموعة',
              subtitle:
                  'سيظهر للجميع في الشجرة. مناسب لأقارب الدم في هذه السلالة.',
              selected: _addToSharedTree,
              onTap: () {
                if (_addToSharedTree) return;
                setState(() {
                  _addToSharedTree = true;
                  if (groups.length == 1) {
                    _selectedGroup = groups.first;
                  }
                  _isFormDirty = true;
                });
              },
            ),
            // Group dropdown — only relevant when user is in 2+ groups and
            // has chosen the shared scope. With a single group the auto-pick
            // above is sufficient.
            if (_addToSharedTree && groups.length > 1) ...[
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<FamilyGroup>(
                initialValue: _selectedGroup,
                decoration: InputDecoration(
                  labelText: 'اختر المجموعة',
                  labelStyle: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusLg),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusLg),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusLg),
                    borderSide: const BorderSide(
                      color: AppColors.islamicGreenPrimary,
                      width: 2,
                    ),
                  ),
                ),
                dropdownColor: const Color(0xFF1B3A2D),
                style: AppTypography.bodyMedium
                    .copyWith(color: Colors.white),
                icon: const Icon(Icons.arrow_drop_down,
                    color: Colors.white70),
                items: groups
                    .map((group) => DropdownMenuItem<FamilyGroup>(
                          value: group,
                          child: Text(formatFamilyGroupDisplayName(group.name)),
                        ))
                    .toList(),
                onChanged: (group) {
                  setState(() {
                    _selectedGroup = group;
                    _isFormDirty = true;
                  });
                },
                validator: (value) {
                  if (_addToSharedTree && value == null) {
                    return 'الرجاء اختيار مجموعة';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: AppSpacing.md),
          ],
        );
      },
    );
  }

}

/// Tappable scope card used by [_AddRelativeScreenState._buildSharedTreeToggle].
///
/// Renders a selectable card with an icon, title, and subtitle. The selected
/// state shows a tinted background and a check icon — matching the glass /
/// gradient aesthetic of the rest of the form.
class _ScopeOptionCard extends StatelessWidget {
  const _ScopeOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.islamicGreenPrimary;
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      hint: subtitle,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.15),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected
                      ? accent.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.7),
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.65),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? accent
                    : Colors.white.withValues(alpha: 0.4),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
