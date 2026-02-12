import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../family_tree/providers/family_graph_providers.dart';
import '../../home/providers/home_providers.dart';
import '../../relatives/services/relationship_inference_service.dart';
import '../models/family_group_model.dart';
import '../providers/family_group_providers.dart';
import '../services/family_sharing_service.dart';
import '../widgets/invite_link_card.dart';

/// Screen for creating a new family group.
///
/// Shows a simple form with a group name field. After creation,
/// displays the invite link for sharing.
class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  FamilyGroup? _createdGroup;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Use initializeSharedTree to create group + migrate relatives + generate edges
      final displayName = user.userMetadata?['full_name'] as String? ?? 'أنا';
      final userGender = RelationshipInferenceService.inferGender(displayName);

      final group = await FamilySharingService.initializeSharedTree(
        userId: user.id,
        familyName: _nameController.text.trim(),
        userDisplayName: displayName,
        userGender: userGender,
      );

      if (mounted) {
        HapticFeedback.heavyImpact();
        ref.invalidate(userFamilyGroupProvider);
        ref.invalidate(userGroupsProvider(user.id));
        ref.invalidate(relativesStreamProvider(user.id));
        setState(() {
          _createdGroup = group;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء إنشاء المجموعة: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);

    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(animated: true, child: SizedBox.expand()),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.sm,
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(AppRoutes.home);
                          }
                        },
                        tooltip: 'العودة',
                        icon: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: themeColors.onSurface,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'إنشاء مجموعة عائلية',
                          style: AppTypography.headlineSmall.copyWith(
                            color: themeColors.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.iconXl),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: _createdGroup != null
                        ? _buildSuccessView(themeColors)
                        : _buildFormView(themeColors),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView(ThemeColors themeColors) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),

          // Group icon
          Icon(
            Icons.family_restroom_rounded,
            size: AppSpacing.iconXxl,
            color: themeColors.onSurface,
          ),
          const SizedBox(height: AppSpacing.md),

          // Description
          Text(
            'أنشئ مجموعة عائلية وشارك رابط الدعوة مع أفراد عائلتك',
            style: AppTypography.bodyLarge.copyWith(
              color: themeColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Name field
          GlassCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: TextFormField(
              controller: _nameController,
              style: AppTypography.bodyLarge.copyWith(
                color: themeColors.onSurface,
              ),
              decoration: InputDecoration(
                labelText: 'اسم المجموعة',
                labelStyle: AppTypography.bodyMedium.copyWith(
                  color: themeColors.onSurface.withValues(alpha: 0.6),
                ),
                hintText: 'مثال: عائلة الأحمد',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: themeColors.onSurface.withValues(alpha: 0.4),
                ),
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.group_rounded,
                  color: themeColors.onSurface,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال اسم المجموعة';
                }
                if (value.trim().length < 2) {
                  return 'اسم المجموعة يجب أن يكون حرفين على الأقل';
                }
                if (value.trim().length > 50) {
                  return 'اسم المجموعة يجب أن لا يتجاوز 50 حرف';
                }
                return null;
              },
              inputFormatters: [LengthLimitingTextInputFormatter(50)],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _createGroup(),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Create button
          GradientButton(
            text: 'إنشاء مجموعة',
            onPressed: _createGroup,
            isLoading: _isLoading,
            icon: Icons.add_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(ThemeColors themeColors) {
    final group = _createdGroup;
    if (group == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),

        // Success icon
        Icon(
          Icons.check_circle_rounded,
          size: AppSpacing.iconXxl,
          color: themeColors.onSurface,
          semanticLabel: 'تم بنجاح',
        ),
        const SizedBox(height: AppSpacing.md),

        // Success message
        Text(
          'تم إنشاء المجموعة بنجاح!',
          style: AppTypography.headlineSmall.copyWith(
            color: themeColors.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          group.name,
          style: AppTypography.titleLarge.copyWith(
            color: themeColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),

        // Invite link card
        InviteLinkCard(inviteCode: group.inviteCode),
        const SizedBox(height: AppSpacing.xl),

        // Go to group button
        GradientButton(
          text: 'عرض المجموعة',
          onPressed: () {
            context.go('${AppRoutes.familyGroupDetail}/${group.id}');
          },
          icon: Icons.arrow_forward_rounded,
        ),
      ],
    );
  }
}
