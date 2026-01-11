// Abstract AI Service Interface
// Defines the contract for AI service implementations

import '../../../shared/models/relative_model.dart';
import 'ai_models.dart';

/// Abstract interface for AI service
/// Allows swapping between different AI providers (DeepSeek, OpenAI, etc.)
abstract class AIService {
  /// Stream chat completion for real-time response
  Stream<AIStreamChunk> streamChatCompletion({
    required List<ChatMessage> messages,
    required String systemPrompt,
    double temperature = 0.7,
    int maxTokens = 2048,
  });

  /// Get single chat completion (non-streaming)
  Future<String> getChatCompletion({
    required List<ChatMessage> messages,
    required String systemPrompt,
    double temperature = 0.7,
    int maxTokens = 2048,
    int? timeoutSeconds,
  });

  /// Generate communication script for a scenario
  Future<CommunicationScript> getCommunicationScript({
    required String scenario,
    required Relative? relative,
    String? additionalContext,
  });

  /// Generate a personalized message
  Future<List<String>> generateMessages({
    required Relative relative,
    required String occasionType,
    required String tone,
    int count = 3,
  });

  /// Analyze relationship health and provide AI-powered suggestions
  Future<RelationshipAnalysis> analyzeRelationship({
    required Relative relative,
  });

  /// Get smart reminder suggestions for relatives
  Future<List<SmartReminderSuggestion>> getSmartReminderSuggestions({
    required List<Relative> relatives,
  });

  /// Extract memories/facts from a conversation
  Future<List<Map<String, dynamic>>> extractMemories(String conversation);

  /// Check if the service is available
  Future<bool> isAvailable();

  /// Dispose resources
  void dispose();
}

/// AI Service Exception
class AIServiceException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AIServiceException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AIServiceException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Rate limit exception
class AIRateLimitException extends AIServiceException {
  final Duration? retryAfter;

  AIRateLimitException(super.message, {this.retryAfter})
      : super(code: 'RATE_LIMIT');
}

/// Network exception
class AINetworkException extends AIServiceException {
  AINetworkException(super.message) : super(code: 'NETWORK_ERROR');
}
