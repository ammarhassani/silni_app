import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../family_groups/models/family_group_model.dart';
import '../../family_groups/providers/family_group_providers.dart';
import '../providers/family_graph_providers.dart';

/// Small chip that surfaces the user's current active family-group context
/// and opens a bottom-sheet picker letting them switch between groups, fall
/// back to personal mode, or create a new group.
///
/// Hidden entirely when the user belongs to zero groups (no choice to make).
/// Tapping always opens the picker — even with a single group — because
/// "create a new group" is one of the offered actions.
class GroupSwitcherChip extends ConsumerWidget {
  const GroupSwitcherChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final groupsAsync = ref.watch(userGroupsProvider(user.id));
    // Derive label/state from the resolved active group rather than the raw
    // pref — this correctly handles the "unset → default to first" fallback
    // and the personal-sentinel case in one shot.
    final resolvedGroupInfo = ref.watch(activeFamilyGroupProvider).valueOrNull;

    return groupsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (groups) {
        if (groups.isEmpty) return const SizedBox.shrink();

        // Find the group matching the resolved active group id. If
        // resolvedGroupInfo is null the user is in explicit-personal mode
        // (or has no memberships — but we returned above in that case).
        FamilyGroup? activeGroup;
        if (resolvedGroupInfo != null) {
          for (final g in groups) {
            if (g.id == resolvedGroupInfo.groupId) {
              activeGroup = g;
              break;
            }
          }
        }
        final isPersonal = activeGroup == null;
        final label = activeGroup?.name ?? 'شخصي';

        return Semantics(
          label: 'تبديل المجموعة النشطة',
          button: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              onTap: () => _showPicker(
                context,
                ref,
                groups,
                resolvedGroupInfo?.groupId,
              ),
              child: Ink(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.30),
                    width: 1.2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPersonal
                            ? Icons.person_rounded
                            : Icons.groups_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          label,
                          style: AppTypography.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.swap_horiz_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPicker(
    BuildContext context,
    WidgetRef ref,
    List<FamilyGroup> groups,
    String? resolvedActiveGroupId,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => _GroupPickerSheet(
        groups: groups,
        // Pass the *resolved* group id so checkmarks reflect what's
        // actually active (including the unset → default-to-first case
        // where no id is persisted yet but a group is effectively in use).
        resolvedActiveGroupId: resolvedActiveGroupId,
        onSelect: (groupId) {
          ref.read(activeGroupIdProvider.notifier).setActive(groupId);
          Navigator.pop(sheetCtx);
        },
        onCreate: () {
          Navigator.pop(sheetCtx);
          context.push(AppRoutes.createFamilyGroup);
        },
      ),
    );
  }
}

/// Bottom-sheet body for the group switcher.
///
/// Kept as a small private widget so it can `ref.watch(themeColorsProvider)`
/// inside its own build — matches the rest of the app's glass aesthetic
/// rather than rendering as a flat default Material sheet.
class _GroupPickerSheet extends ConsumerWidget {
  final List<FamilyGroup> groups;
  /// The id of the group that is *currently effectively active*. May be null
  /// when the user is in explicit personal mode (or has no memberships).
  /// Drives which tile gets the checkmark.
  final String? resolvedActiveGroupId;
  final ValueChanged<String?> onSelect;
  final VoidCallback onCreate;

  const _GroupPickerSheet({
    required this.groups,
    required this.resolvedActiveGroupId,
    required this.onSelect,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              themeColors.background1.withValues(alpha: 0.97),
              themeColors.background2.withValues(alpha: 0.99),
            ],
          ),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Text(
                  'اختر المجموعة النشطة',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Personal option (always first). Checked when the resolved
              // active group is null — i.e. user is effectively in personal
              // mode (explicit sentinel, or no memberships at all).
              _PickerTile(
                icon: Icons.person_rounded,
                label: 'شخصي',
                selected: resolvedActiveGroupId == null,
                onTap: () => onSelect(null),
              ),
              for (final g in groups)
                _PickerTile(
                  icon: Icons.groups_rounded,
                  label: g.name,
                  // Check against the *resolved* id so the first-group
                  // default-fallback (when nothing is persisted) is also
                  // reflected with a checkmark.
                  selected: g.id == resolvedActiveGroupId,
                  onTap: () => onSelect(g.id),
                ),
              Divider(
                color: Colors.white.withValues(alpha: 0.15),
                height: 1,
              ),
              _PickerTile(
                icon: Icons.add_rounded,
                label: 'إنشاء مجموعة جديدة',
                selected: false,
                onTap: onCreate,
              ),
              SizedBox(height: bottomPad + AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        label,
        style: AppTypography.bodyLarge.copyWith(
          color: Colors.white,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_rounded, color: Colors.white)
          : null,
      onTap: onTap,
    );
  }
}
