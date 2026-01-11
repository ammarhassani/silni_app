// AI Models for Silni App
// Contains data structures for AI chat, responses, and context

/// Counseling mode enum
enum CounselingMode {
  general('general', 'محادثة عامة', 'General family guidance'),
  relationship('relationship', 'نصائح العلاقات', 'Tips for strengthening bonds'),
  conflict('conflict', 'حل الخلافات', 'Guidance for disputes'),
  communication('communication', 'التواصل الفعّال', 'Help with difficult conversations');

  final String value;
  final String arabicName;
  final String description;

  const CounselingMode(this.value, this.arabicName, this.description);

  static CounselingMode fromString(String value) {
    return CounselingMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => CounselingMode.general,
    );
  }
}

/// Message role in chat
enum MessageRole {
  user('user', 'المستخدم'),
  assistant('assistant', 'واصل'),
  system('system', 'النظام');

  final String value;
  final String arabicName;

  const MessageRole(this.value, this.arabicName);

  static MessageRole fromString(String value) {
    return MessageRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => MessageRole.user,
    );
  }
}

/// Chat message model
class ChatMessage {
  final String id;
  final String conversationId;
  final String userId;
  final MessageRole role;
  final String content;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.role,
    required this.content,
    this.metadata = const {},
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      conversationId: json['conversation_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      role: MessageRole.fromString(json['role'] as String? ?? 'user'),
      content: json['content'] as String? ?? '',
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversation_id': conversationId,
      'user_id': userId,
      'role': role.value,
      'content': content,
      'metadata': metadata,
    };
  }

  /// Format for API request
  Map<String, String> toApiFormat() {
    return {
      'role': role.value,
      'content': content,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? userId,
    MessageRole? role,
    String? content,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      content: content ?? this.content,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Chat conversation model
class ChatConversation {
  final String id;
  final String userId;
  final String? title;
  final CounselingMode mode;
  final String? relativeId;
  final bool isArchived;
  final int messageCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ChatConversation({
    required this.id,
    required this.userId,
    this.title,
    required this.mode,
    this.relativeId,
    this.isArchived = false,
    this.messageCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      title: json['title'] as String?,
      mode: CounselingMode.fromString(json['mode'] as String? ?? 'general'),
      relativeId: json['relative_id'] as String?,
      isArchived: json['is_archived'] as bool? ?? false,
      messageCount: json['message_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'title': title,
      'mode': mode.value,
      'relative_id': relativeId,
      'is_archived': isArchived,
    };
  }

  ChatConversation copyWith({
    String? id,
    String? userId,
    String? title,
    CounselingMode? mode,
    String? relativeId,
    bool? isArchived,
    int? messageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      mode: mode ?? this.mode,
      relativeId: relativeId ?? this.relativeId,
      isArchived: isArchived ?? this.isArchived,
      messageCount: messageCount ?? this.messageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// AI Response model for streaming
class AIStreamChunk {
  final String content;
  final bool isDone;
  final String? error;

  AIStreamChunk({
    required this.content,
    this.isDone = false,
    this.error,
  });
}

/// Communication script from AI
class CommunicationScript {
  final String opening;
  final List<String> keyPoints;
  final List<String> phrasesToUse;
  final List<String> phrasesToAvoid;
  final String closing;

  CommunicationScript({
    required this.opening,
    required this.keyPoints,
    required this.phrasesToUse,
    required this.phrasesToAvoid,
    required this.closing,
  });

  factory CommunicationScript.fromJson(Map<String, dynamic> json) {
    return CommunicationScript(
      opening: json['opening'] as String? ?? '',
      keyPoints: (json['key_points'] as List?)?.map((e) => e.toString()).toList() ?? [],
      phrasesToUse: (json['phrases_to_use'] as List?)?.map((e) => e.toString()).toList() ?? [],
      phrasesToAvoid: (json['phrases_to_avoid'] as List?)?.map((e) => e.toString()).toList() ?? [],
      closing: json['closing'] as String? ?? '',
    );
  }
}

/// AI Memory model - stores facts the AI learns about user/family
class AIMemory {
  final String id;
  final String userId;
  final AIMemoryCategory category;
  final String content;
  final String? relativeId;
  final int importance;
  final String? sourceConversationId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AIMemory({
    required this.id,
    required this.userId,
    required this.category,
    required this.content,
    this.relativeId,
    this.importance = 5,
    this.sourceConversationId,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory AIMemory.fromJson(Map<String, dynamic> json) {
    return AIMemory(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      category: AIMemoryCategory.fromString(json['category'] as String? ?? 'conversation_insight'),
      content: json['content'] as String? ?? '',
      relativeId: json['relative_id'] as String?,
      importance: json['importance'] as int? ?? 5,
      sourceConversationId: json['source_conversation_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'category': category.value,
      'content': content,
      'relative_id': relativeId,
      'importance': importance,
      'source_conversation_id': sourceConversationId,
      'is_active': isActive,
    };
  }
}

/// Memory category enum
enum AIMemoryCategory {
  userPreference('user_preference', 'تفضيلات المستخدم'),
  relativeFact('relative_fact', 'معلومة عن قريب'),
  familyDynamic('family_dynamic', 'ديناميكية عائلية'),
  importantDate('important_date', 'تاريخ مهم'),
  conversationInsight('conversation_insight', 'ملاحظة من محادثة');

  final String value;
  final String arabicName;

  const AIMemoryCategory(this.value, this.arabicName);

  static AIMemoryCategory fromString(String value) {
    return AIMemoryCategory.values.firstWhere(
      (cat) => cat.value == value,
      orElse: () => AIMemoryCategory.conversationInsight,
    );
  }
}

/// Weekly report data
class WeeklyReport {
  final int totalInteractions;
  final int relativesContacted;
  final int healthyRelatives;
  final int needsAttentionCount;
  final int atRiskCount;
  final List<String> upcomingOccasions;
  final List<String> actionItems;
  final String reflection;
  final DateTime generatedAt;

  WeeklyReport({
    required this.totalInteractions,
    required this.relativesContacted,
    required this.healthyRelatives,
    required this.needsAttentionCount,
    required this.atRiskCount,
    required this.upcomingOccasions,
    required this.actionItems,
    required this.reflection,
    required this.generatedAt,
  });

  factory WeeklyReport.fromJson(Map<String, dynamic> json) {
    return WeeklyReport(
      totalInteractions: json['total_interactions'] as int? ?? 0,
      relativesContacted: json['relatives_contacted'] as int? ?? 0,
      healthyRelatives: json['healthy_relatives'] as int? ?? 0,
      needsAttentionCount: json['needs_attention_count'] as int? ?? 0,
      atRiskCount: json['at_risk_count'] as int? ?? 0,
      upcomingOccasions: (json['upcoming_occasions'] as List?)?.map((e) => e.toString()).toList() ?? [],
      actionItems: (json['action_items'] as List?)?.map((e) => e.toString()).toList() ?? [],
      reflection: json['reflection'] as String? ?? '',
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'] as String)
          : DateTime.now(),
    );
  }
}

/// Relationship analysis result from AI
class RelationshipAnalysis {
  final String summary;
  final List<AnalysisInsight> insights;
  final List<AnalysisSuggestion> suggestions;
  final List<AnalysisAlert> alerts;

  RelationshipAnalysis({
    required this.summary,
    required this.insights,
    required this.suggestions,
    this.alerts = const [],
  });

  factory RelationshipAnalysis.fromJson(Map<String, dynamic> json) {
    return RelationshipAnalysis(
      summary: json['summary'] as String? ?? '',
      insights: (json['insights'] as List?)
              ?.map((e) => AnalysisInsight.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      suggestions: (json['suggestions'] as List?)
              ?.map((e) => AnalysisSuggestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      alerts: (json['alerts'] as List?)
              ?.map((e) => AnalysisAlert.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Insight from relationship analysis
class AnalysisInsight {
  final String icon;
  final String title;
  final String description;

  AnalysisInsight({
    required this.icon,
    required this.title,
    required this.description,
  });

  factory AnalysisInsight.fromJson(Map<String, dynamic> json) {
    return AnalysisInsight(
      icon: json['icon'] as String? ?? '💡',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

/// Suggestion from relationship analysis
class AnalysisSuggestion {
  final String icon;
  final String title;
  final String description;
  final String priority; // high, medium, low

  AnalysisSuggestion({
    required this.icon,
    required this.title,
    required this.description,
    this.priority = 'medium',
  });

  factory AnalysisSuggestion.fromJson(Map<String, dynamic> json) {
    return AnalysisSuggestion(
      icon: json['icon'] as String? ?? '✨',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      priority: json['priority'] as String? ?? 'medium',
    );
  }
}

/// Alert from relationship analysis
class AnalysisAlert {
  final String icon;
  final String message;

  AnalysisAlert({
    required this.icon,
    required this.message,
  });

  factory AnalysisAlert.fromJson(Map<String, dynamic> json) {
    return AnalysisAlert(
      icon: json['icon'] as String? ?? '⚠️',
      message: json['message'] as String? ?? '',
    );
  }
}

/// Smart reminder suggestion from AI
class SmartReminderSuggestion {
  final String relativeName;
  final String reason;
  final String urgency; // high, medium, low
  final String suggestedAction;
  final String suggestedMessage;

  SmartReminderSuggestion({
    required this.relativeName,
    required this.reason,
    required this.urgency,
    required this.suggestedAction,
    required this.suggestedMessage,
  });

  factory SmartReminderSuggestion.fromJson(Map<String, dynamic> json) {
    return SmartReminderSuggestion(
      relativeName: json['relative_name'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      urgency: json['urgency'] as String? ?? 'medium',
      suggestedAction: json['suggested_action'] as String? ?? 'رسالة',
      suggestedMessage: json['suggested_message'] as String? ?? '',
    );
  }
}
