import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/services/relatives_service.dart';
import '../../../shared/services/cloudinary_service.dart';
import '../../../shared/services/contacts_import_service.dart';
import '../../auth/providers/auth_provider.dart';

class AddRelativeScreen extends ConsumerStatefulWidget {
  const AddRelativeScreen({super.key});

  @override
  ConsumerState<AddRelativeScreen> createState() => _AddRelativeScreenState();
}

class _AddRelativeScreenState extends ConsumerState<AddRelativeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();

  RelationshipType _selectedRelationship = RelationshipType.brother;
  Gender? _selectedGender;
  AvatarType? _selectedAvatar;
  XFile? _selectedImage;
  bool _isLoading = false;
  bool _isFavorite = false;
  int _priority = 2; // Medium by default

  final RelativesService _relativesService = RelativesService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ContactsImportService _contactsService = ContactsImportService();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _cloudinaryService.pickImage();
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

    // Request permission
    final hasPermission = await _contactsService.requestPermission();
    if (!hasPermission) {
      _showMessage('Contacts permission is required');
      return;
    }

    // Get family contacts
    final contacts = await _contactsService.getFamilyContacts();
    if (contacts.isEmpty) {
      _showMessage('No family contacts found');
      return;
    }

    // Show contact picker dialog
    if (!mounted) return;
    // TODO: Show contact picker dialog
    _showMessage('Contact import coming soon!');
  }

  Future<void> _saveRelative() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('User not authenticated');

      // Upload photo if selected
      String? photoUrl;
      if (_selectedImage != null) {
        photoUrl = await _cloudinaryService.uploadProfilePicture(_selectedImage!);
      }

      // Auto-suggest avatar if not manually selected
      final avatarType = _selectedAvatar ??
          AvatarType.suggestFromRelationship(_selectedRelationship, _selectedGender);

      // Create relative
      final relative = Relative(
        id: '', // Will be auto-generated
        userId: user.uid,
        fullName: _nameController.text.trim(),
        relationshipType: _selectedRelationship,
        gender: _selectedGender,
        avatarType: avatarType,
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        photoUrl: photoUrl,
        priority: _priority,
        isFavorite: _isFavorite,
        createdAt: DateTime.now(),
      );

      await _relativesService.createRelative(relative);

      if (!mounted) return;
      _showMessage('تمت إضافة ${relative.fullName} بنجاح! ✅');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      _showMessage('خطأ: $e');
      setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                              Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                                child: Text(
                                  'أو أدخل يدوياً',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
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

                        // Gender
                        _buildGenderPicker(),
                        const SizedBox(height: AppSpacing.md),

                        // Avatar Type
                        _buildAvatarPicker(),
                        const SizedBox(height: AppSpacing.md),

                        // Phone
                        _buildTextField(
                          controller: _phoneController,
                          label: 'رقم الهاتف (اختياري)',
                          hint: '+966 50 123 4567',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
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
                color: AppColors.islamicGreenPrimary.withOpacity(0.5),
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
            color: Colors.white.withOpacity(0.8),
          ),
          hintStyle: AppTypography.bodySmall.copyWith(
            color: Colors.white.withOpacity(0.5),
          ),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildRelationshipPicker() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.family_restroom, color: Colors.white.withOpacity(0.7)),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'صلة القرابة',
                style: AppTypography.titleMedium.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: RelationshipType.values.map((type) {
              final isSelected = type == _selectedRelationship;
              return GestureDetector(
                onTap: () => setState(() => _selectedRelationship = type),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.primaryGradient : null,
                    color: isSelected ? null : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(
                      color: Colors.white.withOpacity(isSelected ? 0.5 : 0.3),
                    ),
                  ),
                  child: Text(
                    type.arabicName,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderPicker() {
    return GlassCard(
      child: Row(
        children: [
          Icon(Icons.wc, color: Colors.white.withOpacity(0.7)),
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
                    color: isSelected ? null : Colors.white.withOpacity(0.1),
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

  Widget _buildAvatarPicker() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_people, color: Colors.white.withOpacity(0.7)),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'نوع الأفاتار',
                style: AppTypography.titleMedium.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: AvatarType.values.map((type) {
              final isSelected = type == _selectedAvatar;
              return GestureDetector(
                onTap: () => setState(() => _selectedAvatar = type),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.primaryGradient : null,
                    color: isSelected ? null : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: Colors.white.withOpacity(isSelected ? 0.5 : 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      type.emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityPicker() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.priority_high, color: Colors.white.withOpacity(0.7)),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'الأولوية',
                style: AppTypography.titleMedium.copyWith(color: Colors.white),
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
          color: isSelected ? null : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: Colors.white.withOpacity(isSelected ? 0.5 : 0.3),
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
          Icon(Icons.star, color: Colors.white.withOpacity(0.7)),
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
}
