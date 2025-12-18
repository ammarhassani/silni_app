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
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/services/error_handler_service.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/services/relatives_service.dart';
import '../../../shared/services/supabase_storage_service.dart';
import '../../../shared/services/contacts_import_service.dart';
import '../../../shared/widgets/health_status_picker.dart';
import '../../auth/providers/auth_provider.dart';

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
  AvatarType? _selectedAvatar; // User-selected avatar
  String? _healthStatus; // Health status of the relative

  final RelativesService _relativesService = RelativesService();
  final SupabaseStorageService _storageService = SupabaseStorageService();
  final ContactsImportService _contactsService = ContactsImportService();

  // Confetti controller for celebration animation
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
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
      if (user == null) throw Exception('User not authenticated');

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

      // Use selected avatar or auto-suggest based on relationship
      final avatarType = _selectedAvatar ??
          AvatarType.suggestFromRelationship(_selectedRelationship, _selectedGender);

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
        createdAt: DateTime.now(),
      );

      await _relativesService.createRelative(relative);

      if (!mounted) return;

      // 🎉 Celebration! Trigger confetti and haptic feedback
      _confettiController.play();
      HapticFeedback.mediumImpact();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ ${relative.fullName} بنجاح! 🎉'),
          backgroundColor: AppColors.islamicGreenPrimary,
          duration: const Duration(seconds: 1),
        ),
      );

      // Reset loading state before navigation
      setState(() => _isLoading = false);

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.islamicGreenPrimary,
      ),
    );
  }

  Gender? _getGenderFromRelationship(RelationshipType relationship) {
    switch (relationship) {
      case RelationshipType.father:
      case RelationshipType.brother:
      case RelationshipType.son:
      case RelationshipType.grandfather:
      case RelationshipType.uncle:
      case RelationshipType.nephew:
      case RelationshipType.husband:
        return Gender.male;
      case RelationshipType.mother:
      case RelationshipType.sister:
      case RelationshipType.daughter:
      case RelationshipType.grandmother:
      case RelationshipType.aunt:
      case RelationshipType.niece:
      case RelationshipType.wife:
        return Gender.female;
      case RelationshipType.cousin:
      case RelationshipType.other:
        return null; // User needs to select
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: GradientBackground(
            animated: true,
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(),

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

                        // Avatar picker
                        _buildAvatarPicker(),
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

                        // Relationship Type
                        _buildRelationshipPicker(),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'إضافة قريب',
            style: AppTypography.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 400))
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

  Widget _buildRelationshipPicker() {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.family_restroom, color: Colors.white.withValues(alpha: 0.7)),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'صلة القرابة',
                style: AppTypography.titleMedium.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<RelationshipType>(
            value: _selectedRelationship,
            dropdownColor: const Color(0xFF1A1A1A),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                borderSide: BorderSide(color: AppColors.islamicGreenPrimary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
            ),
            style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            icon: Icon(Icons.arrow_drop_down, color: Colors.white.withValues(alpha: 0.7)),
            items: RelationshipType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(
                  type.arabicName,
                  style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedRelationship = value;
                  // Auto-detect gender based on relationship
                  _selectedGender = _getGenderFromRelationship(value);
                  // Auto-set priority based on relationship closeness
                  _priority = AvatarType.suggestPriority(value);
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGenderPicker() {
    return GlassCard(
      child: Row(
        children: [
          Icon(Icons.wc, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'الجنس',
            style: AppTypography.titleMedium.copyWith(color: Colors.white),
          ),
          const Spacer(),
          ...Gender.values.map((gender) {
            final isSelected = gender == _selectedGender;
            return Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: GestureDetector(
                onTap: () => setState(() => _selectedGender = gender),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.primaryGradient : null,
                    color: isSelected ? null : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Text(
                    gender.arabicName,
                    style: AppTypography.bodySmall.copyWith(color: Colors.white),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPriorityPicker() {
    String priorityLabel = _priority == 1 ? 'عالية 🔥' : _priority == 2 ? 'متوسطة ⭐' : 'منخفضة 📌';

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
            activeColor: AppColors.premiumGold,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPicker() {
    // Get auto-suggested avatar
    final suggestedAvatar = AvatarType.suggestFromRelationship(_selectedRelationship, _selectedGender);

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.face_rounded, color: Colors.white.withValues(alpha: 0.7)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'اختر الأفاتار',
                      style: AppTypography.titleMedium.copyWith(color: Colors.white),
                    ),
                    Text(
                      'اختياري - سيتم اقتراح أفاتار تلقائياً',
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
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 60,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 0.85,
            ),
            itemCount: AvatarType.values.length,
            itemBuilder: (context, index) {
              final avatar = AvatarType.values[index];
              final isSelected = _selectedAvatar == avatar;
              final isSuggested = avatar == suggestedAvatar && _selectedAvatar == null;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    // Toggle: if already selected, deselect to use auto-suggest
                    _selectedAvatar = isSelected ? null : avatar;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isSelected || isSuggested ? AppColors.primaryGradient : null,
                    color: isSelected || isSuggested ? null : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: isSuggested && !isSelected
                          ? AppColors.premiumGold
                          : Colors.white.withValues(alpha: isSelected ? 0.6 : 0.2),
                      width: isSuggested && !isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.islamicGreenPrimary.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        avatar.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                      if (isSuggested && !isSelected)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.premiumGold,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'مقترح',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ).animate(delay: Duration(milliseconds: 50 * index))
                .fadeIn(duration: const Duration(milliseconds: 300))
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _selectedAvatar != null
                ? 'الأفاتار المختار: ${_selectedAvatar!.arabicName}'
                : 'الأفاتار المقترح: ${suggestedAvatar.arabicName}',
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: const Duration(milliseconds: 400))
      .slideY(begin: 0.1, end: 0);
  }
}
