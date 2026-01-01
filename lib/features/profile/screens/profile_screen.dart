import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/gamification_stats_card.dart';
import '../../../shared/models/interaction_model.dart';
import '../../../shared/services/supabase_storage_service.dart';
import '../../../core/providers/cache_provider.dart';
import '../../home/providers/home_providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/error_handler_service.dart';
import '../widgets/widgets.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../home/widgets/banner_widget.dart';

// Provider for all user interactions (uses cache-first repository pattern)
final userInteractionsProvider =
    StreamProvider.family<List<Interaction>, String>((ref, userId) {
      final repository = ref.watch(interactionsRepositoryProvider);
      return repository.watchUserInteractions(userId);
    });

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
    final userId = user?.id ?? '';
    final themeColors = ref.watch(themeColorsProvider);

    final relativesAsync = ref.watch(relativesStreamProvider(userId));
    final interactionsAsync = ref.watch(userInteractionsProvider(userId));

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

              // Banner (from admin CMS)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: BannerWidget(position: 'profile'),
                ),
              ),

              // User info card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: ProfileInfoCard(user: user, themeColors: themeColors),
                ),
              ),

              // Statistics header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(
                    '📊 إحصائياتي',
                    style: AppTypography.headlineMedium.copyWith(
                      color: themeColors.textOnGradient,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

              // Gamification Stats
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: GamificationStatsCard(userId: userId, compact: false),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

              // Statistics
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(
                    '📊 إحصائياتي',
                    style: AppTypography.headlineMedium.copyWith(
                      color: themeColors.textOnGradient,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: relativesAsync.when(
                    data: (relatives) => interactionsAsync.when(
                      data: (interactions) => ProfileStatsWidget(
                        relatives: relatives,
                        interactions: interactions,
                        themeColors: themeColors,
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

              // Account actions header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(
                    '⚙️ إعدادات الحساب',
                    style: AppTypography.headlineMedium.copyWith(
                      color: themeColors.textOnGradient,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: ProfileActionsWidget(
                    themeColors: themeColors,
                    onChangePassword: () => showChangePasswordDialog(
                      context: context,
                      ref: ref,
                    ),
                    onPrivacySettings: () {
                      UIHelpers.showSnackBar(
                        context,
                        'إعدادات الخصوصية قريباً',
                      );
                    },
                    onExportData: () => showExportDataDialogFlow(
                      context: context,
                      ref: ref,
                      themeColors: themeColors,
                    ),
                    onDeleteAccount: () => showDeleteAccountDialog(
                      context: context,
                      ref: ref,
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
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
}
