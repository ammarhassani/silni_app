import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/app_themes.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glass_dialog.dart';
import '../../../shared/widgets/directional_icon.dart';

/// Compact horizontal identity card — small avatar with edit overlay,
/// name + inline edit affordance, email subtitle. Mirrors the home-bar's
/// horizontal-strip aesthetic so the profile screen no longer leads with
/// a 120px portrait. Back button sits in its own glass circle above.
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top row — back button only. Keeps the identity card from
          // having to host navigation chrome.
          Row(
            children: [
              GlassIconButton(
                tooltip: 'رجوع',
                icon: DirectionalIcon(
                  Icons.arrow_back_ios_rounded,
                  color: themeColors.textOnGradient,
                  size: 18,
                ),
                onPressed: () => context.pop(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Combined identity + account-info card. Top half is the
          // avatar/name/email strip; bottom half packs verification status
          // and join date side-by-side, separated by a glass divider.
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                themeColors.primary.withValues(alpha: 0.22),
                themeColors.primaryDark.withValues(alpha: 0.14),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _buildAvatar(),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: _buildIdentityText(context)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.14),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildAccountMeta(),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 500))
        .slideY(begin: -0.05, end: 0);
  }

  Widget _buildAvatar() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Hero(
          tag: 'profile-avatar',
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: themeColors.goldenGradient,
              boxShadow: [
                BoxShadow(
                  color: themeColors.accent.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 1,
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
          bottom: -2,
          right: -2,
          child: Semantics(
            label: 'تغيير الصورة الشخصية',
            button: true,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                onEditImage();
              },
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: themeColors.primaryGradient,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: isUploadingPicture
                    ? const Padding(
                        padding: EdgeInsets.all(5),
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdentityText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: isEditingName
                  ? TextField(
                      controller: nameController,
                      autofocus: true,
                      style: AppTypography.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide:
                              const BorderSide(color: Colors.white, width: 1.5),
                        ),
                      ),
                    )
                  : Text(
                      displayName,
                      style: AppTypography.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            const SizedBox(width: AppSpacing.xs),
            // Inline edit affordance — small glass tap target so the
            // pencil doesn't visually compete with the name itself.
            Semantics(
              label: isEditingName ? 'حفظ الاسم' : 'تعديل الاسم',
              button: true,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onEditNameToggle();
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    isEditingName
                        ? Icons.check_rounded
                        : Icons.edit_rounded,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        if ((user?.email as String?)?.isNotEmpty == true) ...[
          const SizedBox(height: 4),
          Text(
            user!.email as String,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  /// Verification + join-date row. Sits beneath the identity strip
  /// inside the same card. Email isn't repeated here — it's already
  /// shown in the identity strip above.
  Widget _buildAccountMeta() {
    final isVerified = user?.emailConfirmedAt != null;
    final joinDate = user?.createdAt != null
        ? _formatDate(_parseDateTime(user!.createdAt))
        : 'غير متوفر';

    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _MetaChip(
              icon: isVerified
                  ? Icons.verified_rounded
                  : Icons.gpp_maybe_rounded,
              value: isVerified ? 'تم التحقق' : 'لم يتم التحقق',
              tooltip: 'حالة التحقق',
              accent: isVerified
                  ? themeColors.statusSuccess
                  : themeColors.statusWarning,
            ),
          ),
          Container(
            width: 1,
            color: Colors.white.withValues(alpha: 0.14),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: _MetaChip(
                icon: Icons.calendar_today_rounded,
                value: joinDate,
                tooltip: 'تاريخ الانضمام',
                accent: themeColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  DateTime _parseDateTime(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is DateTime) return date;
    if (date is String) {
      try {
        return DateTime.parse(date);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  String _formatDate(DateTime date) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildDefaultAvatar() {
    return Center(
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '؟',
        style: const TextStyle(
          fontSize: 28,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Small icon + value chip used inside the merged identity card for the
/// verification + join-date row.
class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.value,
    required this.tooltip,
    required this.accent,
  });

  final IconData icon;
  final String value;
  final String tooltip;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Row(
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

