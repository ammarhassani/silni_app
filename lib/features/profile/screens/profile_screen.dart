import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../family_groups/providers/family_group_providers.dart';
import '../../family_tree/providers/family_graph_providers.dart';
import '../../family_tree/widgets/group_switcher_chip.dart';
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

              // Gender editor — lets users fix a wrong wizard choice without
              // re-running setup. Persists to BOTH auth metadata and the
              // personal NULL-scope self-node (same dual write as the wizard).
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: _buildGenderTile(context, themeColors),
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

              // Shared family section — renders the user's active group
              // (if any) plus the "create new group" CTA. The CTA always
              // shows so users with 0 groups have an obvious entry point,
              // and users with a group can spin up additional ones (e.g.
              // for an uncle's branch).
              SliverToBoxAdapter(
                child: Padding(
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
                      Consumer(
                        builder: (context, ref, _) {
                          final groupInfo = ref
                              .watch(activeFamilyGroupProvider)
                              .valueOrNull;
                          if (groupInfo == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: GlassCard(
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
                          );
                        },
                      ),
                      _buildCreateFamilyGroupTile(context, ref, themeColors),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
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

  /// Gender editor tile — siblings the change-password tile in look but uses
  /// the primaryLight accent so the two read as distinct account-level
  /// utilities. Subtitle reactively shows the current value by watching
  /// `currentUserProvider` (Supabase pushes updated User to listeners after
  /// `auth.updateUser`, so the row refreshes immediately on save).
  Widget _buildGenderTile(BuildContext context, dynamic themeColors) {
    final user = ref.watch(currentUserProvider);
    final gender = user?.userMetadata?['gender'] as String?;
    final genderLabel = switch (gender) {
      'male' => 'ذكر',
      'female' => 'أنثى',
      _ => 'غير محدد',
    };

    return Semantics(
      label: 'الجنس - $genderLabel',
      button: true,
      child: GlassCard(
        onTap: () => _showGenderEditDialog(context, ref, gender),
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
                Icons.wc_rounded,
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
                    'الجنس',
                    style: AppTypography.titleMedium.copyWith(
                      color: themeColors.textOnGradient,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    genderLabel,
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

  /// Dual-write gender update — mirrors `_saveGenderAndAdvance` in the
  /// onboarding wizard. Updates auth metadata (merged into existing keys
  /// so we don't clobber full_name etc.) AND the personal NULL-scope
  /// self-node's `gender` column. The dialog disables both option cards
  /// while saving to prevent double-submit.
  Future<void> _showGenderEditDialog(
    BuildContext context,
    WidgetRef ref,
    String? currentGender,
  ) async {
    String? selected = currentGender;
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          Future<void> save(String picked) async {
            if (isSaving) return;
            setState(() {
              selected = picked;
              isSaving = true;
            });
            try {
              final client = SupabaseConfig.client;
              final user = client.auth.currentUser;
              if (user == null) throw Exception('No authenticated user');

              final existingMeta =
                  Map<String, dynamic>.from(user.userMetadata ?? const {});
              await client.auth.updateUser(
                UserAttributes(data: {
                  ...existingMeta,
                  'gender': picked,
                }),
              );

              await client
                  .from('relatives')
                  .update({'gender': picked})
                  .eq('user_id', user.id)
                  .eq('is_self', true)
                  .isFilter('family_group_id', null);

              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              if (context.mounted) {
                UIHelpers.showSnackBar(context, 'تم تحديث الجنس');
              }
            } catch (e, stack) {
              errorHandler.reportError(
                e,
                stackTrace: stack,
                tag: 'ProfileGenderSave',
              );
              if (mounted) setState(() => isSaving = false);
              if (context.mounted) {
                UIHelpers.showSnackBar(
                  context,
                  'تعذّر حفظ الجنس: ${errorHandler.getArabicMessage(e)}',
                  isError: true,
                );
              }
            }
          }

          return GlassDialog(
            icon: Icons.wc_rounded,
            title: 'الجنس',
            subtitle: 'اختر الجنس لتحديث ملفك الشخصي',
            content: Row(
              children: [
                Expanded(
                  child: _GenderOptionCard(
                    emoji: '👨',
                    label: 'ذكر',
                    selected: selected == 'male',
                    onTap: isSaving
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            save('male');
                          },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _GenderOptionCard(
                    emoji: '👩',
                    label: 'أنثى',
                    selected: selected == 'female',
                    onTap: isSaving
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            save('female');
                          },
                  ),
                ),
              ],
            ),
            actions: [
              GlassActionButton(
                text: 'إلغاء',
                onPressed: isSaving
                    ? () {}
                    : () => Navigator.of(dialogContext).pop(),
              ),
            ],
          );
        },
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

  /// Create-family-group tile — accent-tinted CTA that lives under the
  /// shared family section. Always visible so users without a group have
  /// an obvious entry point, and users with a group can spin up another
  /// (e.g. for a different branch of the extended family).
  ///
  /// Quota gate: when the user's single admin slot is already filled, the
  /// tile becomes a "replace" entry point — tapping fires the same
  /// destructive-warning confirm dialog used by the group-switcher chip,
  /// then on confirm leaves (deletes) the current admin group and pushes
  /// to the create-group screen.
  Widget _buildCreateFamilyGroupTile(
    BuildContext context,
    WidgetRef ref,
    dynamic themeColors,
  ) {
    final slots = ref.watch(myMembershipSlotsProvider).valueOrNull;
    final adminSlotFull = slots?.adminSlotFull ?? false;
    final adminGroup = slots?.admin;
    final isReplaceMode = adminSlotFull && adminGroup != null;
    final subtitle = isReplaceMode
        ? 'سيتم حذف بيانات ${adminGroup.name} الحالية'
        : 'ابدأ شجرة عائلة منفصلة';
    final semanticsLabel = isReplaceMode
        ? 'حذف عائلتك وإنشاء جديدة - سيتم حذف بيانات ${adminGroup.name} الحالية'
        : 'إنشاء مجموعة عائلية جديدة - ابدأ شجرة عائلة منفصلة';
    final title = isReplaceMode
        ? 'حذف عائلتك وإنشاء جديدة'
        : 'إنشاء مجموعة عائلية جديدة';
    final iconData = isReplaceMode
        ? Icons.swap_horizontal_circle_rounded
        : Icons.group_add_rounded;

    return Semantics(
      label: semanticsLabel,
      button: true,
      child: GlassCard(
        onTap: isReplaceMode
            ? () => confirmAndReplaceAdminGroup(
                  context: context,
                  ref: ref,
                  adminGroup: adminGroup,
                )
            : () => context.push(AppRoutes.createFamilyGroup),
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
                iconData,
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
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      color: themeColors.textOnGradient,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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

/// Tappable gender option card used inside the gender-edit dialog. Mirrors
/// the wizard's `_GenderCard` (emoji + Arabic label, theme-aware glass fill)
/// so the two screens feel like the same control. `onTap == null` disables
/// the card while a save is in flight.
class _GenderOptionCard extends ConsumerWidget {
  const _GenderOptionCard({
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
              vertical: AppSpacing.lg,
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
                Text(emoji, style: const TextStyle(fontSize: 40)),
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
