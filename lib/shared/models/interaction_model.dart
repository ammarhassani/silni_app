/// Types of interactions with relatives
enum InteractionType {
  call('call', 'اتصال', '📞'),
  visit('visit', 'زيارة', '🏠'),
  message('message', 'رسالة', '💬'),
  gift('gift', 'هدية', '🎁'),
  event('event', 'مناسبة', '🎉'),
  other('other', 'أخرى', '📝');

  final String value;
  final String arabicName;
  final String emoji;

  const InteractionType(this.value, this.arabicName, this.emoji);

  static InteractionType fromString(String value) {
    return InteractionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => InteractionType.other,
    );
  }
}

/// Model for an interaction with a relative
class Interaction {
  final String id;
  final String userId;
  final String relativeId;
  final InteractionType type;
  final DateTime date;
  final int? duration; // in minutes
  final String? location;
  final String? notes;
  final String? mood;
  final List<String> photoUrls;
  final String? audioNoteUrl;
  final int? rating; // 1-5
  final bool isRecurring;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Interaction({
    required this.id,
    required this.userId,
    required this.relativeId,
    required this.type,
    required this.date,
    this.duration,
    this.location,
    this.notes,
    this.mood,
    this.photoUrls = const [],
    this.audioNoteUrl,
    this.rating,
    this.isRecurring = false,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create from Supabase JSON
  factory Interaction.fromJson(Map<String, dynamic> json) {
    // Handle potentially null required fields (for offline queue compatibility)
    final id = json['id'] as String? ?? '';
    final userId = json['user_id'] as String? ?? '';
    final relativeId = json['relative_id'] as String? ?? '';
    final typeStr = json['type'] as String? ?? 'other';
    final dateStr = json['date'] as String?;
    final createdAtStr = json['created_at'] as String?;

    return Interaction(
      id: id,
      userId: userId,
      relativeId: relativeId,
      type: InteractionType.fromString(typeStr),
      date: dateStr != null ? DateTime.parse(dateStr) : DateTime.now(),
      duration: json['duration'] as int?,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      mood: json['mood'] as String?,
      photoUrls: json['photo_urls'] != null
          ? List<String>.from(json['photo_urls'] as List)
          : [],
      audioNoteUrl: json['audio_note_url'] as String?,
      rating: json['rating'] as int?,
      isRecurring: json['is_recurring'] as bool? ?? false,
      createdAt: createdAtStr != null ? DateTime.parse(createdAtStr) : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'relative_id': relativeId,
      'type': type.value,
      'date': date.toUtc().toIso8601String(),
      'duration': duration,
      'location': location,
      'notes': notes,
      'mood': mood,
      'photo_urls': photoUrls,
      'audio_note_url': audioNoteUrl,
      'rating': rating,
      'is_recurring': isRecurring,
      // Don't include id, created_at, updated_at - managed by database
    };
  }

  /// Copy with method for immutability
  Interaction copyWith({
    String? id,
    String? userId,
    String? relativeId,
    InteractionType? type,
    DateTime? date,
    int? duration,
    String? location,
    String? notes,
    String? mood,
    List<String>? photoUrls,
    String? audioNoteUrl,
    int? rating,
    bool? isRecurring,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Interaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      relativeId: relativeId ?? this.relativeId,
      type: type ?? this.type,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      mood: mood ?? this.mood,
      photoUrls: photoUrls ?? this.photoUrls,
      audioNoteUrl: audioNoteUrl ?? this.audioNoteUrl,
      rating: rating ?? this.rating,
      isRecurring: isRecurring ?? this.isRecurring,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Format duration as human-readable string
  String get formattedDuration {
    if (duration == null) return '';
    final hours = duration! ~/ 60;
    final minutes = duration! % 60;

    if (hours > 0 && minutes > 0) {
      return '$hours ساعة و $minutes دقيقة';
    } else if (hours > 0) {
      return '$hours ساعة';
    } else {
      return '$minutes دقيقة';
    }
  }

  /// Get relative time (e.g., "منذ يومين")
  String get relativeTime {
    final now = DateTime.now();
    // Convert date to local timezone for accurate comparison
    final localDate = date.toLocal();
    final difference = now.difference(localDate);

    // Handle edge case where date might be slightly in the future
    if (difference.isNegative) {
      return 'الآن';
    }

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'منذ ${difference.inMinutes} دقيقة';
      }
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays == 1) {
      return 'منذ يوم واحد';
    } else if (difference.inDays == 2) {
      return 'منذ يومين';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else if (difference.inDays < 30) {
      final weeks = difference.inDays ~/ 7;
      return weeks == 1 ? 'منذ أسبوع' : 'منذ $weeks أسابيع';
    } else if (difference.inDays < 365) {
      final months = difference.inDays ~/ 30;
      return months == 1 ? 'منذ شهر' : 'منذ $months أشهر';
    } else {
      final years = difference.inDays ~/ 365;
      return years == 1 ? 'منذ سنة' : 'منذ $years سنوات';
    }
  }
}
