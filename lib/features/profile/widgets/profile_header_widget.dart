import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/app_themes.dart';

/// Profile header widget with avatar and editable name
class ProfileHeaderWidget extends StatelessWidget {
  const ProfileHeaderWidget({
    super.key,
    required this.user,
    required this.themeColors,
    required this.isEditingName,
    required this.isUploadingPicture,
    required this.nameController,
    required this.onEditImage,
    required this.onEditNameToggle,
  });

  final dynamic user;
  final ThemeColors themeColors;
  final bool isEditingName;
  final bool isUploadingPicture;
  final TextEditingController nameController;
  final VoidCallback onEditImage;
  final VoidCallback onEditNameToggle;

  String get displayName =>
      user?.userMetadata?['full_name'] ??
      user?.email?.split('@')[0] ??
      'المستخدم';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: AppSpacing.lg,
      ),
      child: Column(
        children: [
          // Back button
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Avatar with edit button
          Stack(
            children: [
              Hero(
                tag: 'profile-avatar',
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: themeColors.goldenGradient,
                    boxShadow: [
                      BoxShadow(
                        color: themeColors.accent.withValues(alpha: 0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: user?.userMetadata?['profile_picture_url'] != null
                      ? ClipOval(
                          child: Image.network(
                            user!.userMetadata!['profile_picture_url'] as String,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildDefaultAvatar(),
                          ),
                        )
                      : _buildDefaultAvatar(),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onEditImage();
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: themeColors.primaryGradient,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: isUploadingPicture
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Name with edit button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isEditingName)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: 120,
                    maxWidth: MediaQuery.of(context).size.width * 0.6,
                  ),
                  child: TextField(
                    controller: nameController,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        borderSide: const BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                )
              else
                Text(
                  displayName,
                  style: AppTypography.headlineLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onEditNameToggle();
                },
                icon: Icon(
                  isEditingName ? Icons.check_circle : Icons.edit_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xs),

          // Email
          Text(
            user?.email ?? '',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 600))
        .slideY(begin: -0.1, end: 0);
  }

  Widget _buildDefaultAvatar() {
    return Center(
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '؟',
        style: const TextStyle(
          fontSize: 48,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
