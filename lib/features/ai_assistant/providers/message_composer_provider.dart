import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/deepseek_ai_service.dart';
import '../../../core/services/ai_config_service.dart';
import '../../../shared/models/relative_model.dart';

/// State for message composer
class MessageComposerState {
  final List<String> generatedMessages;
  final bool isLoading;
  final String? error;
  final Relative? selectedRelative;
  final String? selectedOccasion;
  final String? selectedTone;

  const MessageComposerState({
    this.generatedMessages = const [],
    this.isLoading = false,
    this.error,
    this.selectedRelative,
    this.selectedOccasion,
    this.selectedTone,
  });

  MessageComposerState copyWith({
    List<String>? generatedMessages,
    bool? isLoading,
    String? error,
    Relative? selectedRelative,
    String? selectedOccasion,
    String? selectedTone,
    bool clearError = false,
    bool clearRelative = false,
  }) {
    return MessageComposerState(
      generatedMessages: generatedMessages ?? this.generatedMessages,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedRelative: clearRelative ? null : (selectedRelative ?? this.selectedRelative),
      selectedOccasion: selectedOccasion ?? this.selectedOccasion,
      selectedTone: selectedTone ?? this.selectedTone,
    );
  }
}

/// Message composer provider
class MessageComposerNotifier extends StateNotifier<MessageComposerState> {
  final DeepSeekAIService _aiService;

  MessageComposerNotifier(this._aiService) : super(const MessageComposerState());

  /// Select a relative
  void selectRelative(Relative? relative) {
    state = state.copyWith(
      selectedRelative: relative,
      clearRelative: relative == null,
      generatedMessages: [],
      clearError: true,
    );
  }

  /// Select occasion type
  void selectOccasion(String? occasion) {
    state = state.copyWith(
      selectedOccasion: occasion,
      generatedMessages: [],
      clearError: true,
    );
  }

  /// Select tone
  void selectTone(String? tone) {
    state = state.copyWith(
      selectedTone: tone,
      generatedMessages: [],
      clearError: true,
    );
  }

  /// Generate messages
  Future<void> generateMessages() async {
    if (state.selectedRelative == null) {
      state = state.copyWith(error: 'يرجى اختيار أحد الأقارب أولاً');
      return;
    }

    if (state.selectedOccasion == null) {
      state = state.copyWith(error: 'يرجى اختيار المناسبة');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final messages = await _aiService.generateMessages(
        relative: state.selectedRelative!,
        occasionType: state.selectedOccasion!,
        tone: state.selectedTone ?? 'warm',
        count: 3,
      );

      if (!mounted) return;

      state = state.copyWith(
        generatedMessages: messages,
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'حدث خطأ في كتابة الرسائل: ${e.toString()}',
      );
    }
  }

  /// Regenerate a single message at a specific index
  Future<void> regenerateSingleMessage(int index) async {
    if (state.selectedRelative == null || state.selectedOccasion == null) {
      return;
    }

    if (index < 0 || index >= state.generatedMessages.length) {
      return;
    }

    // Mark the specific message as loading (replace with loading placeholder)
    final updatedMessages = List<String>.from(state.generatedMessages);
    updatedMessages[index] = '___LOADING___';
    state = state.copyWith(generatedMessages: updatedMessages);

    try {
      // Generate one new message
      final messages = await _aiService.generateMessages(
        relative: state.selectedRelative!,
        occasionType: state.selectedOccasion!,
        tone: state.selectedTone ?? 'warm',
        count: 1,
      );

      if (!mounted) return;

      if (messages.isNotEmpty) {
        final finalMessages = List<String>.from(state.generatedMessages);
        finalMessages[index] = messages.first;
        state = state.copyWith(generatedMessages: finalMessages);
      }
    } catch (e) {
      if (!mounted) return;
      // Restore original message on error
      state = state.copyWith(
        error: 'حدث خطأ في إعادة كتابة الرسالة',
      );
    }
  }

  /// Update a message with edited content
  void updateMessage(int index, String newContent) {
    if (index < 0 || index >= state.generatedMessages.length) {
      return;
    }
    final updatedMessages = List<String>.from(state.generatedMessages);
    updatedMessages[index] = newContent;
    state = state.copyWith(generatedMessages: updatedMessages);
  }

  /// Clear all selections
  void reset() {
    state = const MessageComposerState();
  }
}

/// Provider for message composer
final messageComposerProvider =
    StateNotifierProvider.autoDispose<MessageComposerNotifier, MessageComposerState>((ref) {
  final aiService = DeepSeekAIService();
  return MessageComposerNotifier(aiService);
});

/// Message occasion options - FALLBACK (used when admin config not loaded)
const List<Map<String, String>> _fallbackMessageOccasions = [
  {'id': 'eid', 'label': 'تهنئة عيد', 'emoji': '🎉'},
  {'id': 'ramadan', 'label': 'تهنئة رمضان', 'emoji': '🌙'},
  {'id': 'birthday', 'label': 'عيد ميلاد', 'emoji': '🎂'},
  {'id': 'wedding', 'label': 'تهنئة زواج', 'emoji': '💒'},
  {'id': 'graduation', 'label': 'تهنئة تخرج', 'emoji': '🎓'},
  {'id': 'newborn', 'label': 'تهنئة مولود', 'emoji': '👶'},
  {'id': 'condolence', 'label': 'تعزية', 'emoji': '💐'},
  {'id': 'recovery', 'label': 'سلامة', 'emoji': '🏥'},
  {'id': 'missing', 'label': 'اشتياق', 'emoji': '💕'},
  {'id': 'checkin', 'label': 'اطمئنان', 'emoji': '👋'},
  {'id': 'apology', 'label': 'اعتذار', 'emoji': '🙏'},
  {'id': 'thanks', 'label': 'شكر', 'emoji': '🙌'},
];

/// Tone options - FALLBACK (used when admin config not loaded)
const List<Map<String, String>> _fallbackToneOptions = [
  {'id': 'formal', 'label': 'رسمي', 'emoji': '👔'},
  {'id': 'warm', 'label': 'دافئ', 'emoji': '❤️'},
  {'id': 'humorous', 'label': 'مرح', 'emoji': '😊'},
  {'id': 'religious', 'label': 'ديني', 'emoji': '🕌'},
];

/// Dynamic message occasions from admin config (with fallback)
List<Map<String, String>> get messageOccasions {
  final config = AIConfigService.instance;
  if (config.isLoaded && config.messageOccasions.isNotEmpty) {
    return config.messageOccasions
        .map((o) => {
              'id': o.occasionKey,
              'label': o.displayNameAr,
              'emoji': o.emoji,
            })
        .toList();
  }
  return _fallbackMessageOccasions;
}

/// Dynamic tone options from admin config (with fallback)
List<Map<String, String>> get toneOptions {
  final config = AIConfigService.instance;
  if (config.isLoaded && config.messageTones.isNotEmpty) {
    return config.messageTones
        .map((t) => {
              'id': t.toneKey,
              'label': t.displayNameAr,
              'emoji': t.emoji,
            })
        .toList();
  }
  return _fallbackToneOptions;
}
