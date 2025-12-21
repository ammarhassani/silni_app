import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';

/// Mood options for interactions
enum MoodOption {
  excellent('excellent', 'ممتاز', '😄', Color(0xFF4CAF50)),
  good('good', 'جيد', '🙂', Color(0xFF8BC34A)),
  neutral('neutral', 'عادي', '😐', Color(0xFFFFC107)),
  concerned('concerned', 'قلق', '😟', Color(0xFFFF9800)),
  sad('sad', 'حزين', '😢', Color(0xFF2196F3)),
  worried('worried', 'مهموم', '😰', Color(0xFF9C27B0));

  final String value;
  final String arabicName;
  final String emoji;
  final Color color;

  const MoodOption(this.value, this.arabicName, this.emoji, this.color);

  static MoodOption? fromString(String? value) {
    if (value == null) return null;
    return MoodOption.values.firstWhere(
      (mood) => mood.value == value,
      orElse: () => MoodOption.neutral,
    );
  }
}

/// A mood selector widget for recording emotional state during interactions
class MoodSelector extends StatelessWidget {
  final String? selectedMood;
  final ValueChanged<String?> onMoodChanged;
  final bool showLabel;
  final bool compact;

  const MoodSelector({
    super.key,
    this.selectedMood,
    required this.onMoodChanged,
    this.showLabel = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactSelector();
    }
    return _buildFullSelector();
  }

  Widget _buildFullSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Row(
            children: [
              Icon(
                Icons.mood_rounded,
                color: Colors.white.withValues(alpha: 0.7),
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'كيف كان شعورك؟',
                style: AppTypography.titleMedium.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'اختياري - سجل شعورك خلال هذا التواصل',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: MoodOption.values.map((mood) {
            final isSelected = selectedMood == mood.value;
            return _buildMoodChip(mood, isSelected);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCompactSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: MoodOption.values.map((mood) {
        final isSelected = selectedMood == mood.value;
        return _buildCompactMoodChip(mood, isSelected);
      }).toList(),
    );
  }

  Widget _buildMoodChip(MoodOption mood, bool isSelected) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // Toggle: if already selected, deselect
        onMoodChanged(isSelected ? null : mood.value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    mood.color.withValues(alpha: 0.8),
                    mood.color,
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isSelected ? mood.color : Colors.white.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: mood.color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mood.emoji,
              style: TextStyle(fontSize: isSelected ? 22 : 18),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              mood.arabicName,
              style: AppTypography.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactMoodChip(MoodOption mood, bool isSelected) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onMoodChanged(isSelected ? null : mood.value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    mood.color.withValues(alpha: 0.8),
                    mood.color,
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.1),
          border: Border.all(
            color: isSelected ? mood.color : Colors.white.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: mood.color.withValues(alpha: 0.4),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            mood.emoji,
            style: TextStyle(fontSize: isSelected ? 22 : 18),
          ),
        ),
      ),
    );
  }
}

/// A dialog for logging an interaction with full details including mood
class LogInteractionDialog extends StatefulWidget {
  final String relativeName;
  final Function(String type, String? notes, String? mood, int? duration)
      onSave;

  const LogInteractionDialog({
    super.key,
    required this.relativeName,
    required this.onSave,
  });

  @override
  State<LogInteractionDialog> createState() => _LogInteractionDialogState();
}

class _LogInteractionDialogState extends State<LogInteractionDialog> {
  String _selectedType = 'call';
  String? _selectedMood;
  final _notesController = TextEditingController();
  int? _duration;

  final List<Map<String, dynamic>> _interactionTypes = [
    {'value': 'call', 'label': 'اتصال', 'emoji': '📞'},
    {'value': 'visit', 'label': 'زيارة', 'emoji': '🏠'},
    {'value': 'message', 'label': 'رسالة', 'emoji': '💬'},
    {'value': 'gift', 'label': 'هدية', 'emoji': '🎁'},
    {'value': 'event', 'label': 'مناسبة', 'emoji': '🎉'},
    {'value': 'other', 'label': 'أخرى', 'emoji': '📝'},
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadiusLarge),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add_comment_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تسجيل تواصل',
                          style: AppTypography.titleLarge.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'مع ${widget.relativeName}',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Interaction type selector
              Text(
                'نوع التواصل',
                style: AppTypography.titleMedium.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _interactionTypes.map((type) {
                  final isSelected = _selectedType == type['value'];
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedType = type['value']);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        gradient:
                            isSelected ? AppColors.primaryGradient : null,
                        color:
                            isSelected ? null : Colors.white.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            type['emoji'],
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            type['label'],
                            style: AppTypography.labelMedium.copyWith(
                              color: Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Mood selector
              MoodSelector(
                selectedMood: _selectedMood,
                onMoodChanged: (mood) => setState(() => _selectedMood = mood),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Duration (optional)
              Text(
                'المدة (اختياري)',
                style: AppTypography.titleMedium.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _buildDurationChip(5),
                  const SizedBox(width: AppSpacing.sm),
                  _buildDurationChip(15),
                  const SizedBox(width: AppSpacing.sm),
                  _buildDurationChip(30),
                  const SizedBox(width: AppSpacing.sm),
                  _buildDurationChip(60),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Notes
              Text(
                'ملاحظات (اختياري)',
                style: AppTypography.titleMedium.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _notesController,
                maxLines: 3,
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'أضف ملاحظات عن هذا التواصل...',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    borderSide: const BorderSide(
                      color: AppColors.islamicGreenPrimary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    widget.onSave(
                      _selectedType,
                      _notesController.text.trim().isEmpty
                          ? null
                          : _notesController.text.trim(),
                      _selectedMood,
                      _duration,
                    );
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.islamicGreenPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                  ),
                  child: Text(
                    'حفظ التواصل',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationChip(int minutes) {
    final isSelected = _duration == minutes;
    final label = minutes >= 60 ? '${minutes ~/ 60} ساعة' : '$minutes دقيقة';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _duration = isSelected ? null : minutes);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.goldenGradient : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
