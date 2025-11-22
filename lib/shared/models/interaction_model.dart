import 'package:cloud_firestore/cloud_firestore.dart';

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
  final List<String> tags;
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
    this.tags = const [],
    this.rating,
    this.isRecurring = false,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create from Firestore document
  factory Interaction.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Interaction(
      id: doc.id,
      userId: data['userId'] as String,
      relativeId: data['relativeId'] as String,
      type: InteractionType.fromString(data['type'] as String),
      date: (data['date'] as Timestamp).toDate(),
      duration: data['duration'] as int?,
      location: data['location'] as String?,
      notes: data['notes'] as String?,
      mood: data['mood'] as String?,
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      audioNoteUrl: data['audioNoteUrl'] as String?,
      tags: List<String>.from(data['tags'] ?? []),
      rating: data['rating'] as int?,
      isRecurring: data['isRecurring'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'relativeId': relativeId,
      'type': type.value,
      'date': Timestamp.fromDate(date),
      'duration': duration,
      'location': location,
      'notes': notes,
      'mood': mood,
      'photoUrls': photoUrls,
      'audioNoteUrl': audioNoteUrl,
      'tags': tags,
      'rating': rating,
      'isRecurring': isRecurring,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
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
    List<String>? tags,
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
      tags: tags ?? this.tags,
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
    final difference = now.difference(date);

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
