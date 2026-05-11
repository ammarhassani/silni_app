import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:silni_app/core/constants/app_spacing.dart';
import 'package:silni_app/core/constants/app_typography.dart';
import 'package:silni_app/core/config/supabase_config.dart';
import 'package:silni_app/core/router/app_routes.dart';
import 'package:silni_app/core/theme/theme_provider.dart';
import 'package:silni_app/features/family_groups/providers/family_group_providers.dart';
import 'package:silni_app/features/family_groups/providers/node_invitation_providers.dart';
import 'package:silni_app/features/family_groups/services/node_invitation_service.dart';
import 'package:silni_app/features/family_tree/providers/family_graph_providers.dart';
import 'package:silni_app/shared/models/relative_model.dart';
import 'package:silni_app/shared/utils/ui_helpers.dart';
import 'package:silni_app/shared/widgets/glass_card.dart';

/// Phone-OTP fast-path admin CTA on the relative detail screen.
///
/// Surfaces ONLY when:
///   - The relative belongs to a family group (family_group_id != null)
///   - The relative is not already a real user (is_self == false)
///   - The viewer is admin of that group
///   - No member is already linked to this node (relative_id_in_tree)
///
/// If the relative has a phone number stored, taps create a node_invitation
/// (revives the system that was cut from v1 launch). If not, the card prompts
/// the admin to add a phone first.
class SendInvitationCard extends ConsumerWidget {
  final Relative relative;
  const SendInvitationCard({super.key, required this.relative});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hide if relative has no group or is already claimed.
    if (relative.familyGroupId == null || relative.isSelf) {
      return const SizedBox.shrink();
    }

    final groupInfo = ref.watch(activeFamilyGroupProvider).valueOrNull;
    if (groupInfo == null || groupInfo.groupId != relative.familyGroupId) {
      return const SizedBox.shrink();
    }

    // Admin check via the group's members stream — current user must have
    // role='admin' in this group. Skip rendering otherwise.
    final membersAsync = ref.watch(groupMembersProvider(groupInfo.groupId));
    final currentUid = SupabaseConfig.client.auth.currentUser?.id;
    final isAdmin = membersAsync.valueOrNull?.any(
          (m) => m.userId == currentUid && m.role == 'admin',
        ) ??
        false;
    if (!isAdmin) {
      return const SizedBox.shrink();
    }

    final invitationAsync = ref.watch(relativeInvitationProvider(
      (groupId: groupInfo.groupId, relativeId: relative.id),
    ));

    return invitationAsync.when(
      data: (invitation) {
        final hasPhone = (relative.phoneNumber ?? '').trim().isNotEmpty;

        // Already pending — show status badge only.
        if (invitation != null && invitation.isPending) {
          return _buildPendingBadge(context, ref, invitation.id);
        }

        return _buildInviteCta(
          context: context,
          ref: ref,
          themeColors: ref.watch(themeColorsProvider),
          hasPhone: hasPhone,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildInviteCta({
    required BuildContext context,
    required WidgetRef ref,
    required dynamic themeColors,
    required bool hasPhone,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.person_add_alt_1_rounded,
                  color: themeColors.accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  hasPhone ? 'دعوة مباشرة لـ ${relative.fullName}' : 'دعوة لـ ${relative.fullName}',
                  style: AppTypography.titleMedium.copyWith(
                    color: themeColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            hasPhone
                ? 'أرسل دعوة على الرقم المسجَّل ${_maskedPhone(relative.phoneNumber!)} لينضم مباشرةً لهذا المكان في الشجرة'
                : 'أضف رقم جوال لـ ${relative.fullName} لإرسال دعوة مباشرة',
            style: AppTypography.bodyMedium.copyWith(
              color: themeColors.onSurface.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (hasPhone)
            FilledButton.icon(
              onPressed: () => _sendInvitation(context, ref),
              icon: const Icon(Icons.send_rounded),
              label: const Text('أرسل الدعوة'),
            )
          else
            OutlinedButton.icon(
              onPressed: () => context.push(
                '${AppRoutes.editRelative}/${relative.id}',
              ),
              icon: const Icon(Icons.phone_outlined),
              label: const Text('أضف رقم الجوال'),
            ),
        ],
      ),
    );
  }

  Widget _buildPendingBadge(
      BuildContext context, WidgetRef ref, String invitationId) {
    final themeColors = ref.watch(themeColorsProvider);
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, color: themeColors.accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'دعوة معلقة لـ ${relative.fullName}',
              style: AppTypography.bodyLarge.copyWith(
                color: themeColors.onSurface,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _cancelInvitation(context, ref, invitationId),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendInvitation(BuildContext context, WidgetRef ref) async {
    final groupInfo = ref.read(activeFamilyGroupProvider).valueOrNull;
    if (groupInfo == null) return;

    final phone = relative.phoneNumber?.trim() ?? '';
    if (phone.isEmpty) return;

    try {
      final svc = NodeInvitationService();
      await svc.createInvitation(
        groupId: groupInfo.groupId,
        relativeId: relative.id,
        phoneNumber: phone,
      );
      ref.invalidate(relativeInvitationProvider(
        (groupId: groupInfo.groupId, relativeId: relative.id),
      ));
      if (context.mounted) {
        HapticFeedback.lightImpact();
        UIHelpers.showSnackBar(context, 'تم إرسال الدعوة');
      }
    } catch (e) {
      if (context.mounted) {
        UIHelpers.showSnackBar(
            context, 'تعذّر إرسال الدعوة: $e', isError: true);
      }
    }
  }

  Future<void> _cancelInvitation(
      BuildContext context, WidgetRef ref, String invitationId) async {
    try {
      final svc = NodeInvitationService();
      await svc.cancelInvitation(invitationId);
      final groupInfo = ref.read(activeFamilyGroupProvider).valueOrNull;
      if (groupInfo != null) {
        ref.invalidate(relativeInvitationProvider(
          (groupId: groupInfo.groupId, relativeId: relative.id),
        ));
      }
      if (context.mounted) {
        UIHelpers.showSnackBar(context, 'تم إلغاء الدعوة');
      }
    } catch (e) {
      if (context.mounted) {
        UIHelpers.showSnackBar(
            context, 'تعذّر إلغاء الدعوة: $e', isError: true);
      }
    }
  }

  /// `+966 *** 5678` — keep first 4 chars and last 4, mask middle.
  static String _maskedPhone(String phone) {
    final p = phone.replaceAll(RegExp(r'\s'), '');
    if (p.length < 8) return p;
    final prefix = p.substring(0, 4);
    final suffix = p.substring(p.length - 4);
    return '$prefix ••• $suffix';
  }
}
