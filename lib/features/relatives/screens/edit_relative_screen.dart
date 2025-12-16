import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/services/relatives_service.dart';
import '../../../shared/services/supabase_storage_service.dart';

class EditRelativeScreen extends ConsumerStatefulWidget {
  final String relativeId;

  const EditRelativeScreen({super.key, required this.relativeId});

  @override
  ConsumerState<EditRelativeScreen> createState() => _EditRelativeScreenState();
}

class _EditRelativeScreenState extends ConsumerState<EditRelativeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _notesController = TextEditingController();

  RelationshipType _selectedRelationship = RelationshipType.brother;
  Gender? _selectedGender;
  AvatarType? _selectedAvatar;
  XFile? _selectedImage;
  bool _isLoading = false;
  bool _isFavorite = false;
  int _priority = 2;
  Relative? _relative;

  final RelativesService _relativesService = RelativesService();
  final SupabaseStorageService _storageService = SupabaseStorageService();

  @override
  void initState() {
    super.initState();
    _loadRelative();
  }

  Future<void> _loadRelative() async {
    final relative = await _relativesService.getRelative(widget.relativeId);
    if (relative != null && mounted) {
      setState(() {
        _relative = relative;
        _nameController.text = relative.fullName;
        _phoneController.text = relative.phoneNumber ?? '';
        _emailController.text = relative.email ?? '';
        _addressController.text = relative.address ?? '';
        _cityController.text = relative.city ?? '';
        _notesController.text = relative.notes ?? '';
        _selectedRelationship = relative.relationshipType;
        _selectedGender = relative.gender;
        _selectedAvatar = relative.avatarType;
        _priority = relative.priority;
        _isFavorite = relative.isFavorite;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _notesController.dispose();
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
        return null;
    }
  }

  Future<void> _updateRelative() async {
    if (!_formKey.currentState!.validate()) return;
    if (_relative == null) return;

    setState(() => _isLoading = true);

    try {
      // Upload photo if selected
      String? photoUrl = _relative!.photoUrl;
      if (_selectedImage != null) {
        final userId = SupabaseConfig.currentUserId;
        if (userId != null) {
          photoUrl = await _storageService.uploadRelativePhoto(
            _selectedImage!,
            userId,
            widget.relativeId,
          );
        }
      }

      // Use selected avatar or auto-suggest based on relationship
      final avatarType =
          _selectedAvatar ??
          AvatarType.suggestFromRelationship(
            _selectedRelationship,
            _selectedGender,
          );

      // Update relative
      await _relativesService.updateRelative(widget.relativeId, {
        'full_name': _nameController.text.trim(),
        'relationship_type': _selectedRelationship.value,
        'gender': _selectedGender?.value,
        'avatar_type': avatarType.value,
        'phone_number': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        'email': _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        'address': _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        'city': _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        if (photoUrl != null) 'photo_url': photoUrl,
        'priority': _priority,
        'is_favorite': _isFavorite,
      });

      if (!mounted) return;

      // Show success message
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث ${_nameController.text.trim()} بنجاح! ✅'),
          backgroundColor: AppColors.islamicGreenPrimary,
          duration: const Duration(seconds: 1),
        ),
      );

      // Reset loading state before navigation
      setState(() => _isLoading = false);

      // Navigate back immediately
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_relative == null) {
      return Scaffold(
        body: GradientBackground(
          animated: true,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.islamicGreenPrimary,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: GradientBackground(
        animated: true,
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => context.pop(),
                      ),
                      const Spacer(),
                      Text(
                        'تعديل بيانات القريب',
                        style: AppTypography.headlineSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48), // Balance the back button
                    ],
                  ),
                ),

                // Form content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Profile photo
                        _buildProfilePhoto(),
                        const SizedBox(height: AppSpacing.lg),

                        // Avatar picker
                        _buildAvatarPicker(),
                        const SizedBox(height: AppSpacing.lg),

                        // Name field
                        _buildTextField(
                          controller: _nameController,
                          label: 'الاسم الكامل',
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
                        _buildRelationshipPicker(),
                        const SizedBox(height: AppSpacing.md),

                        // Phone field
                        _buildTextField(
                          controller: _phoneController,
                          label: 'رقم الهاتف',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Email field
                        _buildTextField(
                          controller: _emailController,
                          label: 'البريد الإلكتروني',
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Address field
                        _buildTextField(
                          controller: _addressController,
                          label: 'العنوان',
                          icon: Icons.location_on,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // City field
                        _buildTextField(
                          controller: _cityController,
                          label: 'المدينة',
                          icon: Icons.location_city,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Priority picker
                        _buildPriorityPicker(),
                        const SizedBox(height: AppSpacing.md),

                        // Notes field
                        _buildTextField(
                          controller: _notesController,
                          label: 'ملاحظات',
                          icon: Icons.note,
                          maxLines: 3,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Favorite toggle
                        _buildFavoriteToggle(),
                        const SizedBox(height: AppSpacing.xl),

                        // Save button
                        GradientButton(
                          text: 'حفظ التعديلات',
                          onPressed: _updateRelative,
                          isLoading: _isLoading,
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
    );
  }

  Widget _buildProfilePhoto() {
    // Determine what to show: selected image, existing photo, or emoji
    final hasSelectedImage = _selectedImage != null;
    final hasExistingPhoto = _relative!.photoUrl != null && _relative!.photoUrl!.isNotEmpty;

    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.islamicGreenPrimary.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipOval(
              child: hasSelectedImage
                  ? FutureBuilder<Widget>(
                      future: _buildSelectedImagePreview(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return snapshot.data!;
                        }
                        return _buildEmojiAvatar();
                      },
                    )
                  : hasExistingPhoto
                      ? CachedNetworkImage(
                          imageUrl: _relative!.photoUrl!,
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                          placeholder: (context, url) => _buildEmojiAvatar(),
                          errorWidget: (context, url, error) => _buildEmojiAvatar(),
                        )
                      : _buildEmojiAvatar(),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.goldenGradient,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiAvatar() {
    return Center(
      child: Text(
        _relative!.displayEmoji,
        style: const TextStyle(fontSize: 64),
      ),
    );
  }

  Future<Widget> _buildSelectedImagePreview() async {
    final bytes = await _selectedImage!.readAsBytes();
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      width: 120,
      height: 120,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.7), size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTypography.titleMedium.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: controller,
            style: AppTypography.bodyLarge.copyWith(color: Colors.white),
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            decoration: InputDecoration(
              hintText: label,
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.5),
              ),
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                borderSide: const BorderSide(
                  color: AppColors.islamicGreenPrimary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
            ),
          ),
        ],
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
              Icon(Icons.family_restroom, color: Colors.white.withOpacity(0.7)),
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
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                borderSide: const BorderSide(
                  color: AppColors.islamicGreenPrimary,
                  width: 2,
                ),
              ),
            ),
            items: RelationshipType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(
                  type.arabicName,
                  style: AppTypography.bodyLarge.copyWith(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedRelationship = value;
                  _selectedGender = _getGenderFromRelationship(value);
                  _priority = AvatarType.suggestPriority(value);
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityPicker() {
    String priorityLabel = _priority == 1
        ? 'عالية 🔥'
        : _priority == 2
        ? 'متوسطة ⭐'
        : 'منخفضة 📌';

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.priority_high, color: AppColors.premiumGold),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'الأولوية',
                style: AppTypography.titleMedium.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'تم تعيين الأولوية تلقائياً بناءً على صلة القرابة',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _buildPriorityButton(1, 'عالية 🔥', Colors.red)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildPriorityButton(2, 'متوسطة ⭐', Colors.orange),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildPriorityButton(3, 'منخفضة 📌', Colors.blue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityButton(int value, String label, Color color) {
    final isSelected = _priority == value;

    return GestureDetector(
      onTap: () => setState(() => _priority = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected ? color : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildFavoriteToggle() {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(
            Icons.star,
            color: _isFavorite ? Colors.amber : Colors.white.withOpacity(0.7),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'إضافة للمفضلة',
              style: AppTypography.titleMedium.copyWith(color: Colors.white),
            ),
          ),
          Switch(
            value: _isFavorite,
            onChanged: (value) => setState(() => _isFavorite = value),
            activeColor: AppColors.islamicGreenPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPicker() {
    // Get auto-suggested avatar
    final suggestedAvatar = AvatarType.suggestFromRelationship(
      _selectedRelationship,
      _selectedGender,
    );

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.face_rounded, color: Colors.white.withOpacity(0.7)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'اختر الأفاتار',
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'اختياري - سيتم اقتراح أفاتار تلقائياً',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Use a more flexible layout to prevent overflow
          LayoutBuilder(
            builder: (context, constraints) {
              // Calculate optimal crossAxisCount based on available width
              int crossAxisCount = (constraints.maxWidth / 60).floor();
              crossAxisCount = crossAxisCount.clamp(
                3,
                8,
              ); // Between 3 and 8 items per row

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: AppSpacing.xs,
                  mainAxisSpacing: AppSpacing.xs,
                  childAspectRatio: 1,
                ),
                itemCount: AvatarType.values.length,
                itemBuilder: (context, index) {
                  final avatar = AvatarType.values[index];
                  final isSelected = _selectedAvatar == avatar;
                  final isSuggested =
                      avatar == suggestedAvatar && _selectedAvatar == null;

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
                        gradient: isSelected || isSuggested
                            ? AppColors.primaryGradient
                            : null,
                        color: isSelected || isSuggested
                            ? null
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        border: Border.all(
                          color: isSuggested && !isSelected
                              ? AppColors.premiumGold
                              : Colors.white.withOpacity(
                                  isSelected ? 0.6 : 0.2,
                                ),
                          width: isSuggested && !isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.islamicGreenPrimary
                                      .withOpacity(0.4),
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
                            style: const TextStyle(
                              fontSize: 24,
                            ), // Slightly smaller to fit better
                          ),
                          if (isSuggested && !isSelected)
                            Container(
                              margin: const EdgeInsets.only(top: 1),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.premiumGold,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                'مقترح',
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _selectedAvatar != null
                ? 'الأفاتار المختار: ${_selectedAvatar!.arabicName}'
                : 'الأفاتار المقترح: ${suggestedAvatar.arabicName}',
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white.withOpacity(0.8),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
            maxLines: 2, // Allow text to wrap if needed
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
