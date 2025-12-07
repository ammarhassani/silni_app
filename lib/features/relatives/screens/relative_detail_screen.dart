import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/models/interaction_model.dart';
import '../../../shared/services/relatives_service.dart';
import '../../../shared/providers/interactions_provider.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/call_verification_service.dart';

class RelativeDetailScreen extends ConsumerStatefulWidget {
  final String relativeId;

  const RelativeDetailScreen({super.key, required this.relativeId});

  @override
  ConsumerState<RelativeDetailScreen> createState() =>
      _RelativeDetailScreenState();
}

class _RelativeDetailScreenState extends ConsumerState<RelativeDetailScreen> {
  final RelativesService _relativesService = RelativesService();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isLoggingInteraction = false; // Prevent duplicate logs

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);

    return Scaffold(
      body: GradientBackground(
        animated: true,
        child: SafeArea(
          child: StreamBuilder<Relative?>(
            stream: _relativesService.getRelativeStream(widget.relativeId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: themeColors.primary),
                );
              }

              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.white70,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'لم يتم العثور على القريب',
                        style: AppTypography.headlineMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton(
                        onPressed: () => context.pop(),
                        child: const Text('رجوع'),
                      ),
                    ],
                  ),
                );
              }

              final relative = snapshot.data!;

              return CustomScrollView(
                slivers: [
                  // Header with avatar and name
                  SliverToBoxAdapter(child: _buildHeader(relative)),

                  // Contact actions
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: _buildContactActions(relative),
                    ),
                  ),

                  // Stats card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: _buildStatsCard(relative),
                    ),
                  ),

                  // Details card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: _buildDetailsCard(relative),
                    ),
                  ),

                  // Recent interactions
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Text(
                        'التفاعلات الأخيرة',
                        style: AppTypography.headlineSmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: _buildRecentInteractions(relative.id),
                  ),

                  // Bottom spacing
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xxl),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : () => _markAsContacted(),
        backgroundColor: themeColors.primary,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.check_circle_outline),
        label: Text(
          'تسجيل تواصل',
          style: AppTypography.labelLarge.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeader(Relative relative) {
    final themeColors = ref.watch(themeColorsProvider);
    final priorityColor = relative.priority == 1
        ? Colors.red
        : relative.priority == 2
        ? Colors.orange
        : Colors.blue;
    final priorityLabel = relative.priority == 1
        ? 'عالية'
        : relative.priority == 2
        ? 'متوسطة'
        : 'منخفضة';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // Back button and action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                ),
                onPressed: () => context.pop(),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: Colors.white),
                    onPressed: () {
                      context.push('${AppRoutes.editRelative}/${relative.id}');
                    },
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    icon: const Icon(Icons.delete_rounded, color: Colors.red),
                    onPressed: () => _showDeleteConfirmation(relative),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Avatar with Hero animation
          Hero(
            tag: 'avatar-${relative.id}',
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: themeColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: themeColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  relative.displayEmoji,
                  style: const TextStyle(fontSize: 64),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Name
          Text(
            relative.fullName,
            style: AppTypography.headlineLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: AppSpacing.xs),

          // Relationship
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              gradient: themeColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Text(
              relative.relationshipType.arabicName,
              style: AppTypography.titleMedium.copyWith(color: Colors.white),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Priority badge
          if (relative.isFavorite)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                border: Border.all(color: Colors.amber),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'مفضل',
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: AppSpacing.sm),

          // Priority indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.priority_high, color: priorityColor, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'أولوية $priorityLabel',
                style: AppTypography.labelMedium.copyWith(color: priorityColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactActions(Relative relative) {
    final themeColors = ref.watch(themeColorsProvider);
    final hasPhone = relative.phoneNumber != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use grid layout for better organization
        final crossAxisCount = constraints.maxWidth > 600
            ? 4
            : constraints.maxWidth > 400
            ? 3
            : 2;
        final childAspectRatio = constraints.maxWidth > 600 ? 1.2 : 1.0;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          children: [
            // Call button
            _buildActionCard(
              icon: Icons.phone,
              label: 'اتصال',
              color: Colors.green.shade600,
              onTap: () => _makeCall(relative.phoneNumber!),
              isEnabled: hasPhone,
            ),

            // WhatsApp button
            _buildActionCard(
              icon: FontAwesomeIcons.whatsapp,
              label: 'واتساب',
              color: Colors.green.shade400,
              onTap: () => _openWhatsApp(relative.phoneNumber!),
              isEnabled: hasPhone,
            ),

            // Message button
            _buildActionCard(
              icon: Icons.message,
              label: 'رسالة',
              color: Colors.blue.shade600,
              onTap: () => _sendMessage(relative.phoneNumber!),
              isEnabled: hasPhone,
            ),

            // Favorite toggle button
            _buildActionCard(
              icon: relative.isFavorite ? Icons.star : Icons.star_border,
              label: relative.isFavorite ? 'مفضل' : 'تفضيل',
              color: relative.isFavorite
                  ? AppColors.premiumGold
                  : Colors.grey.shade600,
              onTap: () => _toggleFavorite(relative),
              isEnabled: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(Relative relative) {
    final themeColors = ref.watch(themeColorsProvider);
    final daysSince = relative.daysSinceLastContact;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Flexible(
            child: _buildStatItem(
              icon: Icons.calendar_today,
              label: 'آخر تواصل',
              value: daysSince == null
                  ? 'لم يتم'
                  : daysSince == 0
                  ? 'اليوم'
                  : 'منذ $daysSince يوم',
              color: relative.needsContact ? Colors.red : themeColors.primary,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
          Flexible(
            child: _buildStatItem(
              icon: Icons.timeline,
              label: 'التفاعلات',
              value: '${relative.interactionCount}',
              color: AppColors.premiumGold,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
          Flexible(
            child: _buildStatItem(
              icon: Icons.access_time,
              label: 'الحالة',
              value: relative.needsContact ? 'يحتاج تواصل' : 'تم التواصل',
              color: relative.needsContact ? Colors.orange : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(color: Colors.white70),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDetailsCard(Relative relative) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.premiumGold),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'التفاصيل',
                style: AppTypography.titleLarge.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Phone
          if (relative.phoneNumber != null)
            _buildDetailRow(
              icon: Icons.phone,
              label: 'رقم الهاتف',
              value: relative.phoneNumber!,
            ),

          // Email
          if (relative.email != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildDetailRow(
              icon: Icons.email,
              label: 'البريد الإلكتروني',
              value: relative.email!,
            ),
          ],

          // Address
          if (relative.address != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildDetailRow(
              icon: Icons.location_on,
              label: 'العنوان',
              value: relative.address!,
            ),
          ],

          // City
          if (relative.city != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildDetailRow(
              icon: Icons.location_city,
              label: 'المدينة',
              value: relative.city!,
            ),
          ],

          // Notes
          if (relative.notes != null && relative.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _buildDetailRow(
              icon: Icons.note,
              label: 'ملاحظات',
              value: relative.notes!,
            ),
          ],

          // Best time to contact
          if (relative.bestTimeToContact != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildDetailRow(
              icon: Icons.schedule,
              label: 'أفضل وقت للتواصل',
              value: relative.bestTimeToContact!,
            ),
          ],

          // Gender
          if (relative.gender != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildDetailRow(
              icon: Icons.person,
              label: 'الجنس',
              value: relative.gender!.arabicName,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final themeColors = ref.watch(themeColorsProvider);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: themeColors.primary, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(color: Colors.white70),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentInteractions(String relativeId) {
    final themeColors = ref.watch(themeColorsProvider);
    return StreamBuilder<List<Interaction>>(
      stream: ref
          .read(interactionsServiceProvider)
          .getRelativeInteractionsStream(relativeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: CircularProgressIndicator(color: themeColors.primary),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: GlassCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  Icon(
                    Icons.history,
                    size: 48,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'لا توجد تفاعلات بعد',
                    style: AppTypography.bodyLarge.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'ابدأ بتسجيل تواصلك مع ${snapshot.data != null ? 'هذا القريب' : ''}',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white60,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final interactions = snapshot.data!.take(5).toList();

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: interactions.map((interaction) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: themeColors.primaryGradient,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            interaction.type.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              interaction.type.arabicName,
                              style: AppTypography.titleMedium.copyWith(
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              interaction.relativeTime,
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white70,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (interaction.notes != null &&
                                interaction.notes!.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                interaction.notes!,
                                style: AppTypography.bodySmall.copyWith(
                                  color: Colors.white60,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (interaction.duration != null)
                        Column(
                          children: [
                            const Icon(
                              Icons.timer,
                              color: AppColors.premiumGold,
                              size: 16,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              interaction.formattedDuration,
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // Actions
  Future<void> _makeCall(String phoneNumber) async {
    // Haptic feedback for better UX
    HapticFeedback.mediumImpact();

    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      // Auto-log the interaction
      await _logInteraction(InteractionType.call, 'مكالمة هاتفية');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('لا يمكن إجراء المكالمة')));
      }
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    // Haptic feedback for better UX
    HapticFeedback.mediumImpact();

    // Remove any non-digit characters
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('https://wa.me/$cleanNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      // Auto-log the interaction
      await _logInteraction(InteractionType.message, 'رسالة واتساب');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('لا يمكن فتح واتساب')));
      }
    }
  }

  Future<void> _sendMessage(String phoneNumber) async {
    final uri = Uri.parse('sms:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      // Auto-log the interaction
      await _logInteraction(InteractionType.message, 'رسالة نصية');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('لا يمكن إرسال رسالة')));
      }
    }
  }

  // Helper method to log interactions automatically
  Future<void> _logInteraction(InteractionType type, String notes) async {
    // Prevent duplicate interactions from rapid clicks
    if (_isLoggingInteraction) return;

    _isLoggingInteraction = true;

    try {
      final user = _authService.currentUser;
      if (user == null) {
        _isLoggingInteraction = false;
        return;
      }

      final interaction = Interaction(
        id: '',
        userId: user.id,
        relativeId: widget.relativeId,
        type: type,
        date: DateTime.now(),
        notes: notes,
        createdAt: DateTime.now(),
      );

      final interactionsService = ref.read(interactionsServiceProvider);
      await interactionsService.createInteraction(interaction);

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تسجيل التواصل: ${type.arabicName}'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.islamicGreenPrimary,
          ),
        );
      }
    } catch (e) {
      // Silently fail - don't interrupt user flow
      if (mounted) {
        debugPrint('Error logging interaction: $e');
      }
    } finally {
      // Allow new interactions after a short delay
      await Future.delayed(const Duration(seconds: 2));
      _isLoggingInteraction = false;
    }
  }

  Future<void> _markAsContacted() async {
    if (_isLoading) return; // Prevent multiple calls

    final themeColors = ref.read(themeColorsProvider);
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create a quick interaction
      final interaction = Interaction(
        id: '', // Will be generated by Firestore
        userId: user.id,
        relativeId: widget.relativeId,
        type:
            InteractionType.call, // Default to call, user can add details later
        date: DateTime.now(),
        notes: 'تواصل سريع',
        createdAt: DateTime.now(),
      );

      final interactionsService = ref.read(interactionsServiceProvider);
      await interactionsService.createInteraction(interaction);

      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم تسجيل التواصل بنجاح! 🎉'),
          backgroundColor: themeColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Show delete confirmation dialog
  Future<void> _showDeleteConfirmation(Relative relative) async {
    final themeColors = ref.read(themeColorsProvider);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: Colors.red),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'تأكيد الحذف',
              style: AppTypography.titleLarge.copyWith(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل أنت متأكد من حذف هذا القريب؟',
              style: AppTypography.bodyLarge.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'اسم: ${relative.fullName}',
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'صلة القرابة: ${relative.relationshipType.arabicName}',
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Text(
                'هذا الإجراء لا يمكن التراجع عنه',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'إلغاء',
              style: AppTypography.labelLarge.copyWith(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'حذف',
              style: AppTypography.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteRelative(relative);
    }
  }

  /// Delete relative with proper error handling
  Future<void> _deleteRelative(Relative relative) async {
    try {
      setState(() => _isLoading = true);

      // Use the permanently delete method from RelativesService
      await _relativesService.permanentlyDeleteRelative(relative.id);

      if (!mounted) return;

      setState(() => _isLoading = false);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حذف ${relative.fullName} بنجاح'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Navigate back to relatives list
      context.pop();
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل حذف القريب: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Build improved action card for better layout
  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isEnabled,
  }) {
    final themeColors = ref.watch(themeColorsProvider);

    return Container(
      height: isEnabled ? 80 : 70,
      decoration: BoxDecoration(
        gradient: isEnabled
            ? LinearGradient(
                colors: [color.withOpacity(0.8), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isEnabled ? null : Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: isEnabled ? Border.all(color: color.withOpacity(0.3)) : null,
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isEnabled ? Colors.white : Colors.grey,
                  size: 28,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: isEnabled ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Toggle favorite status
  Future<void> _toggleFavorite(Relative relative) async {
    try {
      await _relativesService.toggleFavorite(relative.id, !relative.isFavorite);

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              relative.isFavorite ? 'تم إلغاء التفضيل' : 'تمت الإضافة للمفضلة',
            ),
            backgroundColor: AppColors.premiumGold,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
