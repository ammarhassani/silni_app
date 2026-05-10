import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/services/supabase_storage_service.dart';
import '../../../shared/services/session_persistence_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/widgets/glass_dialog.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../core/services/error_reporter.dart';
import '../../../shared/widgets/persistent_bottom_nav.dart';
import '../../family_tree/providers/family_graph_providers.dart';
import '../widgets/widgets.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../../shared/widgets/message_widget.dart';

final supabaseStorageServiceProvider = Provider((ref) => SupabaseStorageService());

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isEditingName = false;
  bool _isUploadingPicture = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final themeColors = ref.watch(themeColorsProvider);

    return Scaffold(
      body: Semantics(
        label: 'الملف الشخصي',
        child: GradientBackground(
          animated: true,
          child: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
              // Header with avatar
              SliverToBoxAdapter(
                child: ProfileHeaderWidget(
                  user: user,
                  themeColors: themeColors,
                  isEditingName: _isEditingName,
                  isUploadingPicture: _isUploadingPicture,
                  nameController: _nameController,
                  onEditImage: () => showImageSourceDialog(
                    context: context,
                    themeColors: themeColors,
                    onSourceSelected: _pickImageFromSource,
                  ),
                  onEditNameToggle: _handleNameEditToggle,
                ),
              ),

              // Messages (unified: banners + in-app messages)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: MessageWidget(screenPath: '/profile'),
                ),
              ),

              // Change password tile — security action, scoped to the
              // user's account (lives here, not on settings).
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: _buildChangePasswordTile(context, themeColors),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),

              // Export-data tile — data portability, paired with the
              // change-password tile as the two account-level utilities.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: _buildExportDataTile(context, themeColors),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

              // Shared family section — only renders when user is in a
              // group. Group creation now happens implicitly via the share
              // flow on the family tree screen, so there's no in-profile
              // CTA here when the user has no group yet.
              SliverToBoxAdapter(
                child: Consumer(
                  builder: (context, ref, _) {
                    final groupInfo = ref
                        .watch(userFamilyGroupProvider)
                        .valueOrNull;
                    if (groupInfo == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '👨‍👩‍👧 العائلة المشتركة',
                            style: AppTypography.headlineMedium.copyWith(
                              color: themeColors.textOnGradient,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          GlassCard(
                            child: ListTile(
                              leading: Icon(
                                Icons.diversity_3_rounded,
                                color: themeColors.accent,
                              ),
                              title: Text(
                                'مجموعتي العائلية',
                                style: AppTypography.titleMedium.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              subtitle: Text(
                                'إدارة الأعضاء والدعوات',
                                style: AppTypography.bodySmall.copyWith(
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white.withValues(alpha: 0.5),
                                size: 20,
                              ),
                              onTap: () => context.push(
                                '${AppRoutes.familyGroupDetail}/${groupInfo.groupId}',
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Danger zone — delete account. Lives on profile (your account
              // identity) rather than settings (app-level config).
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: _buildDeleteAccountTile(context, ref, themeColors),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: PersistentBottomNav.totalHeight)),
            ],
          ),
        ),
      ),
      ),
    );
  }

  void _handleNameEditToggle() {
    final user = ref.read(currentUserProvider);
    final displayName =
        user?.userMetadata?['full_name'] ??
        user?.email?.split('@')[0] ??
        'المستخدم';

    setState(() {
      if (_isEditingName) {
        _saveName();
      } else {
        _nameController.text = displayName;
        _isEditingName = true;
      }
    });
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      final storageService = ref.read(supabaseStorageServiceProvider);
      final XFile? image = await storageService.pickImage(source: source);

      if (image != null) {
        setState(() => _isUploadingPicture = true);

        try {
          final user = SupabaseConfig.client.auth.currentUser;
          if (user != null) {
            final imageUrl = await storageService.uploadUserProfilePicture(
              image,
              user.id,
            );

            await SupabaseConfig.client
                .from('users')
                .update({'profile_picture_url': imageUrl})
                .eq('id', user.id);

            await SupabaseConfig.client.auth.updateUser(
              UserAttributes(data: {'profile_picture_url': imageUrl}),
            );

            // Cache for login screen
            SessionPersistenceService().saveProfilePictureUrl(imageUrl);

            if (mounted) {
              setState(() {});
              UIHelpers.showSnackBar(
                context,
                'تم تحديث الصورة الشخصية بنجاح! ✅',
              );
            }
          }
        } catch (e) {
          if (mounted) {
            UIHelpers.showSnackBar(
              context,
              errorHandler.getArabicMessage(e),
              isError: true,
            );
          }
        } finally {
          if (mounted) {
            setState(() => _isUploadingPicture = false);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          errorHandler.getArabicMessage(e),
          isError: true,
        );
      }
    }
  }

  Future<void> _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      UIHelpers.showSnackBar(
        context,
        'الاسم لا يمكن أن يكون فارغاً',
        isError: true,
      );
      return;
    }

    if (newName.length < 2) {
      UIHelpers.showSnackBar(
        context,
        'الاسم يجب أن يكون حرفين على الأقل',
        isError: true,
      );
      return;
    }

    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;

      await SupabaseConfig.client
          .from('users')
          .update({'full_name': newName})
          .eq('id', user.id);

      await SupabaseConfig.client.auth.updateUser(
        UserAttributes(data: {
          'full_name': newName,
          'display_name': newName,
        }),
      );

      if (mounted) {
        setState(() => _isEditingName = false);
        UIHelpers.showSnackBar(
          context,
          'تم حفظ الاسم بنجاح',
        );
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          errorHandler.getArabicMessage(e),
          isError: true,
        );
      }
    }
  }

  /// Change-password tile — squircle leading shape, theme-accent tint.
  /// Distinct from the my-family-group GlassCard (round leading) so the two
  /// tiles read as hand-crafted rather than a uniform list.
  Widget _buildChangePasswordTile(BuildContext context, dynamic themeColors) {
    return Semantics(
      label: 'تغيير كلمة المرور - حماية حسابك',
      button: true,
      child: GlassCard(
        onTap: () => _showChangePasswordDialog(context, ref),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: themeColors.accent.withValues(alpha: 0.18),
                border: Border.all(
                  color: themeColors.accent.withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.shield_outlined,
                color: themeColors.accent,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'تغيير كلمة المرور',
                    style: AppTypography.titleMedium.copyWith(
                      color: themeColors.textOnGradient,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'حماية حسابك',
                    style: AppTypography.bodySmall.copyWith(
                      color: themeColors.textOnGradient.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: themeColors.textOnGradient.withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// Export-data tile — same compact glass-tile shape as change-password,
  /// but with a download/squircle accent so the two read as siblings.
  Widget _buildExportDataTile(BuildContext context, dynamic themeColors) {
    return Semantics(
      label: 'تصدير بياناتي - احفظ نسخة من بياناتك',
      button: true,
      child: GlassCard(
        onTap: () => showExportDataDialogFlow(
          context: context,
          ref: ref,
          themeColors: themeColors,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: themeColors.primaryLight.withValues(alpha: 0.18),
                border: Border.all(
                  color: themeColors.primaryLight.withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.file_download_outlined,
                color: themeColors.primaryLight,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'تصدير بياناتي',
                    style: AppTypography.titleMedium.copyWith(
                      color: themeColors.textOnGradient,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'احفظ نسخة من بياناتك',
                    style: AppTypography.bodySmall.copyWith(
                      color: themeColors.textOnGradient.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: themeColors.textOnGradient.withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          final themeColors = ref.watch(themeColorsProvider);

          return GlassDialog(
            icon: Icons.lock_reset_rounded,
            title: 'تغيير كلمة المرور',
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildThemedPasswordField(
                    controller: currentPasswordController,
                    label: 'كلمة المرور الحالية',
                    obscureText: obscureCurrentPassword,
                    onToggleVisibility: () => setState(
                      () =>
                          obscureCurrentPassword = !obscureCurrentPassword,
                    ),
                    themeColors: themeColors,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال كلمة المرور الحالية';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildThemedPasswordField(
                    controller: newPasswordController,
                    label: 'كلمة المرور الجديدة',
                    obscureText: obscureNewPassword,
                    onToggleVisibility: () => setState(
                      () => obscureNewPassword = !obscureNewPassword,
                    ),
                    themeColors: themeColors,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال كلمة المرور الجديدة';
                      }
                      if (value.length < 8) {
                        return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
                      }
                      if (!RegExp(r'[A-Z]').hasMatch(value)) {
                        return 'يجب أن تحتوي على حرف كبير واحد على الأقل';
                      }
                      if (!RegExp(r'[a-z]').hasMatch(value)) {
                        return 'يجب أن تحتوي على حرف صغير واحد على الأقل';
                      }
                      if (!RegExp(r'[0-9]').hasMatch(value)) {
                        return 'يجب أن تحتوي على رقم واحد على الأقل';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildThemedPasswordField(
                    controller: confirmPasswordController,
                    label: 'تأكيد كلمة المرور الجديدة',
                    obscureText: obscureConfirmPassword,
                    onToggleVisibility: () => setState(
                      () =>
                          obscureConfirmPassword = !obscureConfirmPassword,
                    ),
                    themeColors: themeColors,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء تأكيد كلمة المرور الجديدة';
                      }
                      if (value != newPasswordController.text) {
                        return 'كلمة المرور غير متطابقة';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              GlassActionButton(
                text: 'إلغاء',
                onPressed: isLoading
                    ? () {}
                    : () => Navigator.of(dialogContext).pop(),
              ),
              GradientButton(
                text: 'تغيير',
                icon: Icons.check_rounded,
                isLoading: isLoading,
                onPressed: isLoading
                    ? () {}
                    : () async {
                        if (!formKey.currentState!.validate()) return;

                        setState(() => isLoading = true);

                        try {
                          final authService = ref.read(authServiceProvider);
                          final user = authService.currentUser;

                          if (user?.email == null) {
                            throw Exception('المستخدم غير موجود');
                          }

                          await authService.signInWithEmail(
                            email: user!.email!,
                            password: currentPasswordController.text,
                          );

                          await authService.updatePassword(
                            newPasswordController.text,
                          );

                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }

                          if (context.mounted) {
                            UIHelpers.showSnackBar(
                              context,
                              'تم تغيير كلمة المرور بنجاح',
                              backgroundColor: themeColors.statusSuccess,
                            );
                          }
                        } on AuthException catch (e) {
                          setState(() => isLoading = false);
                          if (context.mounted) {
                            UIHelpers.showSnackBar(
                              context,
                              AuthService.getErrorMessage(e.message),
                              isError: true,
                            );
                          }
                        } catch (e) {
                          setState(() => isLoading = false);
                          if (context.mounted) {
                            UIHelpers.showSnackBar(
                              context,
                              'حدث خطأ أثناء تغيير كلمة المرور',
                              isError: true,
                            );
                          }
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThemedPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required dynamic themeColors,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 14,
        ),
        prefixIcon: Icon(
          Icons.lock_outline,
          color: Colors.white.withValues(alpha: 0.7),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility : Icons.visibility_off,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          onPressed: onToggleVisibility,
        ),
        filled: true,
        fillColor: themeColors.background2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color: themeColors.primary.withValues(alpha: 0.3),
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color: themeColors.primary.withValues(alpha: 0.3),
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: themeColors.primary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: Colors.red, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: Colors.red, width: 2.0),
        ),
        errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
      validator: validator,
    );
  }

  /// Danger tile — solid deep-red fill, white content. Theme-independent
  /// because red == danger universally; faded-red tints would blend into
  /// the orange theme's background.
  Widget _buildDeleteAccountTile(
    BuildContext context,
    WidgetRef ref,
    dynamic themeColors,
  ) {
    const dangerStrong = Color(0xFFD32F2F);
    const dangerDeep = Color(0xFF8B1F1F);
    return Semantics(
      label: 'حذف الحساب - إجراء لا يمكن التراجع عنه - تحذير',
      button: true,
      child: GlassCard(
        onTap: () => showDeleteAccountDialog(
          context: context,
          ref: ref,
          themeColors: themeColors,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [dangerStrong, dangerDeep],
        ),
        border: Border.all(color: const Color(0xFF5C0E0E), width: 1.5),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.85),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'حذف الحساب',
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'إجراء لا يمكن التراجع عنه',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
