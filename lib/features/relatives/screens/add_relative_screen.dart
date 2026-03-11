import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/errors/app_errors.dart';
import '../../../core/services/auto_reminder_service.dart';
import '../../../core/services/error_handler_service.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glass_pill_title.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/models/relative_model.dart';
import '../../../core/providers/cache_provider.dart';
import '../../../shared/services/supabase_storage_service.dart';
import '../../../shared/widgets/health_status_picker.dart';
import '../../../shared/widgets/relative_category_picker.dart';
import '../../auth/providers/auth_provider.dart';
import '../../family_groups/models/family_group_model.dart';
import '../../family_groups/providers/family_group_providers.dart';
import '../../family_groups/services/shared_tree_service.dart';
import '../../family_tree/models/family_graph.dart';
import '../../family_tree/providers/family_graph_providers.dart';
import '../../family_tree/services/family_graph_service.dart';
import '../../home/providers/home_providers.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../services/relationship_inference_service.dart';
import '../../../shared/widgets/flat_relationship_picker.dart';

class AddRelativeScreen extends ConsumerStatefulWidget {
  const AddRelativeScreen({super.key});

  @override
  ConsumerState<AddRelativeScreen> createState() => _AddRelativeScreenState();
}

class _AddRelativeScreenState extends ConsumerState<AddRelativeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();

  RelationshipType _selectedRelationship = RelationshipType.brother;
  Gender? _selectedGender;
  XFile? _selectedImage;
  bool _isLoading = false;
  bool _isFavorite = false;
  int _priority = 2; // Auto-set based on relationship
  String _phoneNumber = ''; // Store phone number separately
  String? _healthStatus; // Health status of the relative
  bool _addToSharedTree = false; // Whether to add to a shared family tree
  FamilyGroup? _selectedGroup; // The selected family group (if shared)
  FamilySide? _selectedFamilySide; // Paternal or maternal side for extended family
  RelativeCategory _selectedCategory = RelativeCategory.extended;

  final SupabaseStorageService _storageService = SupabaseStorageService();

  // Confetti controller for celebration animation
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _nameController.addListener(_onNameChanged);
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
    _emailController.dispose();
    _notesController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _storageService.pickImage();
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _importFromContacts() async {
    if (kIsWeb) {
      _showMessage('Contact import is only available on mobile devices');
      return;
    }

    // Navigate to contact import screen
    if (!mounted) return;
    context.push(AppRoutes.importContacts);
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
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
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
      final groupInfo = ref.read(userFamilyGroupProvider).valueOrNull;
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

      // Fire-and-forget: auto-create a reminder based on relationship type.
      // This runs in the background and never blocks the UI or throws.
      unawaited(AutoReminderService.createAutoReminder(
        userId: user.id,
        relativeId: createdRelativeId,
        relationshipType: _selectedRelationship,
        remindersRepository: ref.read(reminderSchedulesRepositoryProvider),
      ));

      if (!mounted) return;

      // 🎉 Celebration! Trigger confetti and haptic feedback
      _confettiController.play();
      HapticFeedback.mediumImpact();

      // Show success message
      UIHelpers.showSnackBar(
        context,
        'تم حفظ ${relative.fullName} بنجاح! 🎉',
        backgroundColor: AppColors.islamicGreenPrimary,
      );

      // Reset loading state before navigation
      setState(() => _isLoading = false);

      // Invalidate relatives provider so the list refreshes immediately
      ref.invalidate(relativesStreamProvider(user.id));

      // Wait a moment for confetti, then navigate
      await Future.delayed(const Duration(milliseconds: 400));

      if (!mounted) return;

      // Navigate back to home
      context.go(AppRoutes.home);
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
    // Use shared relatives when adding to shared tree, personal otherwise
    final user = ref.watch(currentUserProvider);
    final groupInfo = ref.watch(userFamilyGroupProvider).valueOrNull;
    final relativesAsync = (_addToSharedTree && groupInfo != null)
        ? ref.watch(groupRelativesStreamProvider(groupInfo.groupId))
        : (user != null ? ref.watch(relativesStreamProvider(user.id)) : null);
    final existingRelatives = relativesAsync?.valueOrNull ?? <Relative>[];

    return Stack(
      children: [
        Scaffold(
          body: GradientBackground(
            animated: true,
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(themeColors),

                  // Form
                  Expanded(
                    child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Photo picker
                        _buildPhotoPicker(),
                        const SizedBox(height: AppSpacing.xl),


                        // Import from contacts button (mobile only)
                        if (!kIsWeb) ...[
                          OutlinedGradientButton(
                            text: 'استيراد من جهات الاتصال',
                            onPressed: _importFromContacts,
                            icon: Icons.contacts_rounded,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.3))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                                child: Text(
                                  'أو أدخل يدوياً',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.3))),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

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

                        // Relationship Type - Flat Picker
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
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Shared family tree toggle
                        _buildSharedTreeToggle(),

                        // Category picker
                        RelativeCategoryPicker(
                          selected: _selectedCategory,
                          onChanged: (value) {
                            setState(() => _selectedCategory = value);
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Phone with international format
                        IntlPhoneField(
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
                          initialCountryCode: 'SA', // Saudi Arabia as default
                          style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                          dropdownTextStyle: AppTypography.bodyMedium.copyWith(color: Colors.white),
                          dropdownIcon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                          flagsButtonPadding: const EdgeInsets.only(left: 8),
                          onChanged: (phone) {
                            setState(() {
                              _phoneNumber = phone.completeNumber;
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Email
                        _buildTextField(
                          controller: _emailController,
                          label: 'البريد الإلكتروني (اختياري)',
                          hint: 'example@email.com',
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Priority
                        _buildPriorityPicker(),
                        const SizedBox(height: AppSpacing.md),

                        // Favorite toggle
                        _buildFavoriteToggle(),
                        const SizedBox(height: AppSpacing.md),

                        // Health status
                        HealthStatusPicker(
                          selectedStatus: _healthStatus,
                          onStatusChanged: (status) {
                            setState(() => _healthStatus = status);
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
    );
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
              icon: Icon(Icons.arrow_back_rounded, color: themeColors.textOnGradient),
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

  Widget _buildPriorityPicker() {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.priority_high, color: Colors.white.withValues(alpha: 0.7)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الأولوية',
                      style: AppTypography.titleMedium.copyWith(color: Colors.white),
                    ),
                    Text(
                      'تم ضبطها تلقائياً حسب صلة القرابة',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildPriorityOption(1, 'عالية', '🔥'),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildPriorityOption(2, 'متوسطة', '⭐'),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildPriorityOption(3, 'منخفضة', '📌'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityOption(int priority, String label, String emoji) {
    final isSelected = priority == _priority;
    return GestureDetector(
      onTap: () => setState(() => _priority = priority),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: Colors.white.withValues(alpha: isSelected ? 0.5 : 0.3),
          ),
        ),
        child: Column(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteToggle() {
    return GlassCard(
      child: Row(
        children: [
          Icon(Icons.star, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'إضافة للمفضلة',
            style: AppTypography.titleMedium.copyWith(color: Colors.white),
          ),
          const Spacer(),
          Switch(
            value: _isFavorite,
            onChanged: (value) => setState(() => _isFavorite = value),
            activeTrackColor: AppColors.premiumGold.withValues(alpha: 0.5),
            activeThumbColor: AppColors.premiumGold,
          ),
        ],
      ),
    );
  }

  /// Builds the shared family tree toggle + group dropdown.
  ///
  /// Only renders content when the user belongs to at least one family group.
  Widget _buildSharedTreeToggle() {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final groupsAsync = ref.watch(userGroupsProvider(user.id));

    return groupsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (groups) {
        if (groups.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            GlassCard(
              child: Column(
                children: [
                  // Toggle row
                  Row(
                    children: [
                      Icon(Icons.group_rounded,
                          color: Colors.white.withValues(alpha: 0.7)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'ضيفه للعائلة المشتركة؟',
                          style: AppTypography.titleMedium
                              .copyWith(color: Colors.white),
                        ),
                      ),
                      Switch(
                        value: _addToSharedTree,
                        onChanged: (value) {
                          setState(() {
                            _addToSharedTree = value;
                            if (!value) _selectedGroup = null;
                            if (value && groups.length == 1) {
                              _selectedGroup = groups.first;
                            }
                          });
                        },
                        activeTrackColor:
                            AppColors.islamicGreenPrimary.withValues(alpha: 0.5),
                        activeThumbColor: AppColors.islamicGreenPrimary,
                      ),
                    ],
                  ),
                  // Group dropdown (shown when toggle is on)
                  if (_addToSharedTree) ...[
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
                                child: Text(group.name),
                              ))
                          .toList(),
                      onChanged: (group) {
                        setState(() => _selectedGroup = group);
                      },
                      validator: (value) {
                        if (_addToSharedTree && value == null) {
                          return 'الرجاء اختيار مجموعة';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        );
      },
    );
  }

}
