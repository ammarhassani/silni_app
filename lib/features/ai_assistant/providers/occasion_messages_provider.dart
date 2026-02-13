import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:silni_app/core/ai/deepseek_ai_service.dart';
import 'package:silni_app/features/ai_assistant/services/occasion_message_service.dart';
import 'package:silni_app/shared/models/relative_model.dart';

/// State for AI-generated occasion messages.
class OccasionMessagesState {
  final bool isLoading;
  final List<OccasionMessage>? messages;
  final String? error;

  const OccasionMessagesState({
    this.isLoading = false,
    this.messages,
    this.error,
  });

  OccasionMessagesState copyWith({
    bool? isLoading,
    List<OccasionMessage>? messages,
    String? error,
  }) {
    return OccasionMessagesState(
      isLoading: isLoading ?? this.isLoading,
      messages: messages ?? this.messages,
      error: error,
    );
  }
}

/// Provider that manages AI-generated occasion messages.
/// Caches in memory — navigating back won't re-trigger generation.
class OccasionMessagesNotifier extends StateNotifier<OccasionMessagesState> {
  OccasionMessagesNotifier() : super(const OccasionMessagesState());

  final _aiService = DeepSeekAIService();

  /// Generate AI messages for all relatives for the given occasion.
  /// Falls back to templates if AI fails.
  Future<void> generate({
    required OccasionType occasion,
    required List<Relative> relatives,
  }) async {
    // Already generated — skip
    if (state.messages != null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final aiMessages = await _aiService.generateOccasionMessages(
        relatives: relatives,
        occasionType: occasion.key,
      );

      final messages = relatives.map((relative) {
        final aiMessage = aiMessages[relative.id];
        // If AI didn't return a message for this relative, use template fallback
        final message = aiMessage ??
            OccasionMessageService.generateMessages(
              occasion: occasion,
              relatives: [relative],
            ).first.message;

        return OccasionMessage(
          relativeId: relative.id,
          relativeName: relative.fullName,
          relationshipType: relative.relationshipType.arabicName,
          occasion: occasion,
          message: message,
          generatedAt: DateTime.now(),
        );
      }).toList();

      state = OccasionMessagesState(messages: messages);
    } catch (e) {
      // Fallback to templates on error
      final templateMessages = OccasionMessageService.generateMessages(
        occasion: occasion,
        relatives: relatives,
      );
      state = OccasionMessagesState(
        messages: templateMessages,
        error: e.toString(),
      );
    }
  }

  /// Reset state (e.g., for retry).
  void reset() {
    state = const OccasionMessagesState();
  }
}

/// Keyed by occasion type so each occasion has its own cached state.
final occasionMessagesProvider = StateNotifierProvider.family<
    OccasionMessagesNotifier, OccasionMessagesState, OccasionType>(
  (ref, occasion) => OccasionMessagesNotifier(),
);
