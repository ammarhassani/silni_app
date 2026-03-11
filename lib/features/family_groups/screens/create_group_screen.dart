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

/// Screen for creating a new family group with a 3-step flow:
/// 1. Name — enter group name
/// 2. Review — review relatives that will be shared
/// 3. Done — success confirmation with next actions
class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  FamilyGroup? _createdGroup;

  @override
  void initState() {
    super.initState();
    _prefillGroupName();
  }

  void _prefillGroupName() {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final familyName = user.userMetadata?['family_name'] as String?;
    final fullName = user.userMetadata?['full_name'] as String?;
    if (familyName != null && familyName.isNotEmpty) {
      _nameController.text = familyName;
    } else if (fullName != null && fullName.isNotEmpty) {
      _nameController.text = 'عائلة $fullName';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!(_formKey.currentState?.validate() ?? false)) return;
      _goToStep(1);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    }
  }

  Future<void> _createGroup() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
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
        _goToStep(2);
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
                      if (_currentStep < 2)
                        IconButton(
                          onPressed: () {
                            if (_currentStep > 0) {
                              _previousStep();
                            } else if (context.canPop()) {
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
                        )
                      else
                        const SizedBox(width: AppSpacing.iconXl),
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

                // Step indicator
                if (_currentStep < 2)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.sm,
                    ),
                    child: _buildStepIndicator(themeColors),
                  ),

                // Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildNameStep(themeColors),
                      _buildReviewStep(themeColors),
                      _buildDoneStep(themeColors),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(ThemeColors themeColors) {
    return Row(
      children: List.generate(2, (index) {
        final isActive = index <= _currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              left: index > 0 ? AppSpacing.xs : 0,
              right: index < 1 ? AppSpacing.xs : 0,
            ),
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isActive
                  ? themeColors.onSurface
                  : themeColors.onSurface.withValues(alpha: 0.2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNameStep(ThemeColors themeColors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.xl),

            // Icon
            Icon(
              Icons.family_restroom_rounded,
              size: AppSpacing.iconXxl,
              color: themeColors.onSurface,
            ),
            const SizedBox(height: AppSpacing.md),

            // Title
            Text(
              'سمّ مجموعتك العائلية',
              style: AppTypography.headlineSmall.copyWith(
                color: themeColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),

            // Subtitle
            Text(
              'اختر اسمًا لمجموعتك العائلية',
              style: AppTypography.bodyLarge.copyWith(
                color: themeColors.onSurface.withValues(alpha: 0.7),
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
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: 'مثال: عائلة الأحمد',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Colors.transparent,
                  prefixIcon: Icon(
                    Icons.group_rounded,
                    color: Colors.white.withValues(alpha: 0.7),
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
                onFieldSubmitted: (_) => _nextStep(),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Next button
            GradientButton(
              text: 'التالي',
              onPressed: _nextStep,
              icon: Icons.arrow_back_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewStep(ThemeColors themeColors) {
    final user = ref.watch(currentUserProvider);
    final relativesAsync = user != null
        ? ref.watch(relativesStreamProvider(user.id))
        : null;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),

          // Title
          Text(
            'مراجعة الأقارب',
            style: AppTypography.headlineSmall.copyWith(
              color: themeColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),

          // Relatives list
          Expanded(
            child: relativesAsync == null
                ? _buildNoRelativesMessage(themeColors)
                : relativesAsync.when(
                    data: (relatives) {
                      if (relatives.isEmpty) {
                        return _buildNoRelativesMessage(themeColors);
                      }
                      return Column(
                        children: [
                          // Count
                          GlassCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_rounded,
                                  color: themeColors.onSurface,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'سيتم مشاركة ${relatives.length} من أقاربك',
                                  style: AppTypography.bodyLarge.copyWith(
                                    color: themeColors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Scrollable list
                          Expanded(
                            child: GlassCard(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sm,
                              ),
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                ),
                                itemCount: relatives.length,
                                separatorBuilder: (_, __) => Divider(
                                  color: themeColors.onSurface
                                      .withValues(alpha: 0.1),
                                  height: 1,
                                ),
                                itemBuilder: (context, index) {
                                  final relative = relatives[index];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: themeColors.onSurface
                                          .withValues(alpha: 0.1),
                                      child: Text(
                                        relative.fullName.isNotEmpty
                                            ? relative.fullName[0]
                                            : '?',
                                        style:
                                            AppTypography.titleMedium.copyWith(
                                          color: themeColors.onSurface,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      relative.fullName,
                                      style: AppTypography.bodyLarge.copyWith(
                                        color: themeColors.onSurface,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => Center(
                      child: CircularProgressIndicator(
                        color: themeColors.onSurface,
                      ),
                    ),
                    error: (_, __) => _buildNoRelativesMessage(themeColors),
                  ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Create button
          GradientButton(
            text: 'إنشاء المجموعة',
            onPressed: _createGroup,
            isLoading: _isLoading,
            icon: Icons.add_rounded,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Back button
          TextButton(
            onPressed: _previousStep,
            child: Text(
              'السابق',
              style: AppTypography.bodyLarge.copyWith(
                color: themeColors.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoRelativesMessage(ThemeColors themeColors) {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_add_rounded,
              size: AppSpacing.iconXl,
              color: themeColors.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'لا يوجد أقارب حالياً. يمكنك إضافتهم لاحقاً',
              style: AppTypography.bodyLarge.copyWith(
                color: themeColors.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoneStep(ThemeColors themeColors) {
    final group = _createdGroup;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl * 2),

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

          // Group name
          if (group != null)
            Text(
              group.name,
              style: AppTypography.titleLarge.copyWith(
                color: themeColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: AppSpacing.xl * 2),

          // Invite family button
          if (group != null)
            GradientButton(
              text: 'دعوة أفراد العائلة',
              onPressed: () {
                context.go('${AppRoutes.familyGroupDetail}/${group.id}');
              },
              icon: Icons.person_add_rounded,
            ),
          const SizedBox(height: AppSpacing.md),

          // View family tree button
          TextButton.icon(
            onPressed: () {
              context.go(AppRoutes.familyTree);
            },
            icon: Icon(
              Icons.account_tree_rounded,
              color: themeColors.onSurface,
            ),
            label: Text(
              'عرض شجرة العائلة',
              style: AppTypography.bodyLarge.copyWith(
                color: themeColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
