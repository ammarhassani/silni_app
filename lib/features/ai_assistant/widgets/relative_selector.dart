import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/widgets/relative_avatar.dart';
import '../providers/ai_chat_provider.dart';

/// Reusable relative selector dropdown for AI features
/// Shows list of relatives with avatars and allows selection
class RelativeSelector extends ConsumerStatefulWidget {
  final String? selectedRelativeId;
  final ValueChanged<Relative?> onChanged;
  final String hintText;
  final bool showClearButton;

  const RelativeSelector({
    super.key,
    this.selectedRelativeId,
    required this.onChanged,
    this.hintText = 'اختر قريباً',
    this.showClearButton = true,
  });

  @override
  ConsumerState<RelativeSelector> createState() => _RelativeSelectorState();
}

class _RelativeSelectorState extends ConsumerState<RelativeSelector> {
  bool _isExpanded = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final relativesAsync = ref.watch(aiRelativesProvider);

    return relativesAsync.when(
      data: (relatives) => _buildSelector(relatives),
      loading: () => _buildLoadingState(),
      error: (_, __) => _buildErrorState(),
    );
  }

  Widget _buildSelector(List<Relative> relatives) {
    // Safely find selected relative - return null if not found or list is empty
    Relative? selectedRelative;
    if (widget.selectedRelativeId != null && relatives.isNotEmpty) {
      selectedRelative = relatives.cast<Relative?>().firstWhere(
            (r) => r?.id == widget.selectedRelativeId,
            orElse: () => null,
          );
    }

    // Filter relatives by search query
    final filteredRelatives = _searchQuery.isEmpty
        ? relatives
        : relatives
            .where((r) =>
                r.fullName.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Selected relative display / Dropdown trigger
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _isExpanded = !_isExpanded);
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: _isExpanded
                    ? AppColors.islamicGreenPrimary.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                if (selectedRelative != null) ...[
                  RelativeAvatar(
                    relative: selectedRelative,
                    size: 36,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedRelative.fullName,
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          selectedRelative.relationshipType.arabicName,
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.showClearButton)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        widget.onChanged(null);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ] else ...[
                  Icon(
                    Icons.person_search_rounded,
                    color: Colors.white54,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.hintText,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ],
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.white54,
                ),
              ],
            ),
          ),
        ),

        // Expandable list
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.only(top: AppSpacing.xs),
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search field
                if (relatives.length > 5)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'ابحث...',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: Colors.white38,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white38,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),

                // Relatives list
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    itemCount: filteredRelatives.length,
                    itemBuilder: (context, index) {
                      final relative = filteredRelatives[index];
                      final isSelected = relative.id == widget.selectedRelativeId;

                      return ListTile(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          widget.onChanged(relative);
                          setState(() {
                            _isExpanded = false;
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                        leading: RelativeAvatar(
                          relative: relative,
                          size: 40,
                        ),
                        title: Text(
                          relative.fullName,
                          style: AppTypography.bodyMedium.copyWith(
                            color: isSelected
                                ? AppColors.islamicGreenLight
                                : Colors.white,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          relative.relationshipType.arabicName,
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white54,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: AppColors.islamicGreenLight,
                                size: 20,
                              )
                            : null,
                        dense: true,
                        visualDensity: VisualDensity.compact,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          crossFadeState:
              _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.islamicGreenLight,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'جاري تحميل الأقارب...',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'تعذر تحميل الأقارب',
              style: AppTypography.bodyMedium.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
