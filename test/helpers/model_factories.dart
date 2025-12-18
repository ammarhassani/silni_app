import 'package:silni_app/shared/models/relative_model.dart';
import 'package:silni_app/shared/models/interaction_model.dart';
import 'package:silni_app/shared/models/reminder_schedule_model.dart';
import 'package:silni_app/shared/models/hadith_model.dart';
import 'package:silni_app/core/models/gamification_event.dart';

/// Test data factories for creating model instances in tests
///
/// These factories provide sensible defaults while allowing
/// customization of specific fields for targeted testing.

// ========================================
// Relative Model Factories
// ========================================

/// Create a test Relative object
Relative createTestRelative({
  String? id,
  String? userId,
  String? fullName,
  RelationshipType? relationshipType,
  Gender? gender,
  AvatarType? avatarType,
  DateTime? dateOfBirth,
  String? phoneNumber,
  String? email,
  String? address,
  String? city,
  String? country,
  String? photoUrl,
  String? notes,
  List<String>? tags,
  int? priority,
  String? islamicImportance,
  String? preferredContactMethod,
  String? bestTimeToContact,
  int? interactionCount,
  DateTime? lastContactDate,
  String? healthStatus,
  bool? isArchived,
  bool? isFavorite,
  String? contactId,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return Relative(
    id: id ?? 'test-relative-id',
    userId: userId ?? 'test-user-id',
    fullName: fullName ?? 'محمد أحمد',
    relationshipType: relationshipType ?? RelationshipType.brother,
    gender: gender ?? Gender.male,
    avatarType: avatarType ?? AvatarType.adultMan,
    dateOfBirth: dateOfBirth,
    phoneNumber: phoneNumber ?? '+966501234567',
    email: email ?? 'test@example.com',
    address: address,
    city: city,
    country: country,
    photoUrl: photoUrl,
    notes: notes,
    tags: tags ?? [],
    priority: priority ?? 2,
    islamicImportance: islamicImportance,
    preferredContactMethod: preferredContactMethod,
    bestTimeToContact: bestTimeToContact,
    interactionCount: interactionCount ?? 0,
    lastContactDate: lastContactDate,
    healthStatus: healthStatus,
    isArchived: isArchived ?? false,
    isFavorite: isFavorite ?? false,
    contactId: contactId,
    createdAt: createdAt ?? DateTime.now(),
    updatedAt: updatedAt,
  );
}

/// Create a test Relative JSON map (as received from Supabase)
Map<String, dynamic> createTestRelativeJson({
  String? id,
  String? userId,
  String? fullName,
  String? relationshipType,
  String? gender,
  String? avatarType,
  String? dateOfBirth,
  String? phoneNumber,
  String? email,
  String? address,
  String? city,
  String? country,
  String? photoUrl,
  String? notes,
  List<String>? tags,
  int? priority,
  String? islamicImportance,
  String? preferredContactMethod,
  String? bestTimeToContact,
  int? interactionCount,
  String? lastContactDate,
  String? healthStatus,
  bool? isArchived,
  bool? isFavorite,
  String? contactId,
  String? createdAt,
  String? updatedAt,
}) {
  return {
    'id': id ?? 'test-relative-id',
    'user_id': userId ?? 'test-user-id',
    'full_name': fullName ?? 'محمد أحمد',
    'relationship_type': relationshipType ?? 'brother',
    'gender': gender ?? 'male',
    'avatar_type': avatarType ?? 'adult_man',
    'date_of_birth': dateOfBirth,
    'phone_number': phoneNumber ?? '+966501234567',
    'email': email ?? 'test@example.com',
    'address': address,
    'city': city,
    'country': country,
    'photo_url': photoUrl,
    'notes': notes,
    'tags': tags ?? [],
    'priority': priority ?? 2,
    'islamic_importance': islamicImportance,
    'preferred_contact_method': preferredContactMethod,
    'best_time_to_contact': bestTimeToContact,
    'interaction_count': interactionCount ?? 0,
    'last_contact_date': lastContactDate,
    'health_status': healthStatus,
    'is_archived': isArchived ?? false,
    'is_favorite': isFavorite ?? false,
    'contact_id': contactId,
    'created_at': createdAt ?? DateTime.now().toIso8601String(),
    'updated_at': updatedAt,
  };
}

// ========================================
// Interaction Model Factories
// ========================================

/// Create a test Interaction object
Interaction createTestInteraction({
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
    id: id ?? 'test-interaction-id',
    userId: userId ?? 'test-user-id',
    relativeId: relativeId ?? 'test-relative-id',
    type: type ?? InteractionType.call,
    date: date ?? DateTime.now(),
    duration: duration,
    location: location,
    notes: notes,
    mood: mood,
    photoUrls: photoUrls ?? [],
    audioNoteUrl: audioNoteUrl,
    tags: tags ?? [],
    rating: rating,
    isRecurring: isRecurring ?? false,
    createdAt: createdAt ?? DateTime.now(),
    updatedAt: updatedAt,
  );
}

/// Create a test Interaction JSON map (as received from Supabase)
Map<String, dynamic> createTestInteractionJson({
  String? id,
  String? userId,
  String? relativeId,
  String? type,
  String? date,
  int? duration,
  String? location,
  String? notes,
  String? mood,
  List<String>? photoUrls,
  String? audioNoteUrl,
  List<String>? tags,
  int? rating,
  bool? isRecurring,
  String? createdAt,
  String? updatedAt,
}) {
  return {
    'id': id ?? 'test-interaction-id',
    'user_id': userId ?? 'test-user-id',
    'relative_id': relativeId ?? 'test-relative-id',
    'type': type ?? 'call',
    'date': date ?? DateTime.now().toIso8601String(),
    'duration': duration,
    'location': location,
    'notes': notes,
    'mood': mood,
    'photo_urls': photoUrls ?? [],
    'audio_note_url': audioNoteUrl,
    'tags': tags ?? [],
    'rating': rating,
    'is_recurring': isRecurring ?? false,
    'created_at': createdAt ?? DateTime.now().toIso8601String(),
    'updated_at': updatedAt,
  };
}

// ========================================
// ReminderSchedule Model Factories
// ========================================

/// Create a test ReminderSchedule object
ReminderSchedule createTestReminderSchedule({
  String? id,
  String? userId,
  ReminderFrequency? frequency,
  List<String>? relativeIds,
  String? time,
  bool? isActive,
  List<int>? customDays,
  int? dayOfMonth,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return ReminderSchedule(
    id: id ?? 'test-schedule-id',
    userId: userId ?? 'test-user-id',
    frequency: frequency ?? ReminderFrequency.daily,
    relativeIds: relativeIds ?? ['relative-1'],
    time: time ?? '09:00',
    isActive: isActive ?? true,
    customDays: customDays,
    dayOfMonth: dayOfMonth,
    createdAt: createdAt ?? DateTime.now(),
    updatedAt: updatedAt,
  );
}

/// Create a test ReminderSchedule JSON map (as received from Supabase)
Map<String, dynamic> createTestReminderScheduleJson({
  String? id,
  String? userId,
  String? frequency,
  List<String>? relativeIds,
  String? time,
  bool? isActive,
  List<int>? customDays,
  int? dayOfMonth,
  String? createdAt,
  String? updatedAt,
}) {
  return {
    'id': id ?? 'test-schedule-id',
    'user_id': userId ?? 'test-user-id',
    'frequency': frequency ?? 'daily',
    'relative_ids': relativeIds ?? ['relative-1'],
    'time': time ?? '09:00',
    'is_active': isActive ?? true,
    'custom_days': customDays,
    'day_of_month': dayOfMonth,
    'created_at': createdAt ?? DateTime.now().toIso8601String(),
    'updated_at': updatedAt,
  };
}

// ========================================
// Hadith Model Factories
// ========================================

/// Create a test Hadith object
Hadith createTestHadith({
  String? id,
  String? arabicText,
  String? englishTranslation,
  String? source,
  String? reference,
  String? topic,
  HadithType? type,
  String? narrator,
  String? scholar,
  bool? isAuthentic,
  int? displayOrder,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return Hadith(
    id: id ?? 'test-hadith-id',
    arabicText: arabicText ?? 'من وصل رحمه وصله الله',
    englishTranslation: englishTranslation ?? 'Whoever maintains ties of kinship, Allah will maintain ties with him',
    source: source ?? 'صحيح البخاري',
    reference: reference ?? '5990',
    topic: topic ?? 'silat_rahim',
    type: type ?? HadithType.hadith,
    narrator: narrator ?? 'أبو هريرة',
    scholar: scholar ?? '',
    isAuthentic: isAuthentic ?? true,
    displayOrder: displayOrder ?? 0,
    createdAt: createdAt ?? DateTime.now(),
    updatedAt: updatedAt,
  );
}

/// Create a test Hadith JSON map (as received from Supabase)
Map<String, dynamic> createTestHadithJson({
  String? id,
  String? arabicText,
  String? englishTranslation,
  String? source,
  String? reference,
  String? topic,
  String? type,
  String? narrator,
  String? scholar,
  bool? isAuthentic,
  int? displayOrder,
  String? createdAt,
  String? updatedAt,
}) {
  return {
    'id': id ?? 'test-hadith-id',
    'arabic_text': arabicText ?? 'من وصل رحمه وصله الله',
    'english_translation': englishTranslation ?? 'Whoever maintains ties of kinship, Allah will maintain ties with him',
    'source': source ?? 'صحيح البخاري',
    'reference': reference ?? '5990',
    'topic': topic ?? 'silat_rahim',
    'type': type ?? 'hadith',
    'narrator': narrator ?? 'أبو هريرة',
    'scholar': scholar ?? '',
    'is_authentic': isAuthentic ?? true,
    'display_order': displayOrder ?? 0,
    'created_at': createdAt ?? DateTime.now().toIso8601String(),
    'updated_at': updatedAt,
  };
}

/// Create a test Hadith from local Map format (fallback format)
Map<String, dynamic> createTestHadithMap({
  String? id,
  String? arabicText,
  String? englishTranslation,
  String? source,
  String? reference,
  String? topic,
  String? type,
  String? narrator,
  String? scholar,
  bool? isAuthentic,
  int? displayOrder,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return {
    'id': id ?? 'test-hadith-id',
    'arabicText': arabicText ?? 'من وصل رحمه وصله الله',
    'englishTranslation': englishTranslation ?? 'Whoever maintains ties of kinship, Allah will maintain ties with him',
    'source': source ?? 'صحيح البخاري',
    'reference': reference ?? '5990',
    'topic': topic ?? 'silat_rahim',
    'type': type ?? 'hadith',
    'narrator': narrator ?? 'أبو هريرة',
    'scholar': scholar ?? '',
    'isAuthentic': isAuthentic ?? true,
    'displayOrder': displayOrder ?? 0,
    'createdAt': createdAt ?? DateTime.now(),
    'updatedAt': updatedAt,
  };
}

// ========================================
// GamificationEvent Factories
// ========================================

/// Create a test GamificationEvent for points earned
GamificationEvent createTestPointsEarnedEvent({
  String? userId,
  int? points,
  String? source,
  DateTime? timestamp,
}) {
  return GamificationEvent(
    type: GamificationEventType.pointsEarned,
    userId: userId ?? 'test-user-id',
    data: {
      'points': points ?? 10,
      'source': source ?? 'call',
    },
    timestamp: timestamp,
  );
}

/// Create a test GamificationEvent for badge unlocked
GamificationEvent createTestBadgeUnlockedEvent({
  String? userId,
  String? badgeId,
  String? badgeName,
  String? badgeDescription,
  DateTime? timestamp,
}) {
  return GamificationEvent(
    type: GamificationEventType.badgeUnlocked,
    userId: userId ?? 'test-user-id',
    data: {
      'badge_id': badgeId ?? 'first_interaction',
      'badge_name': badgeName ?? 'أول تفاعل',
      'badge_description': badgeDescription ?? 'سجلت أول تفاعل لك',
    },
    timestamp: timestamp,
  );
}

/// Create a test GamificationEvent for level up
GamificationEvent createTestLevelUpEvent({
  String? userId,
  int? oldLevel,
  int? newLevel,
  int? currentXP,
  int? xpToNextLevel,
  DateTime? timestamp,
}) {
  return GamificationEvent(
    type: GamificationEventType.levelUp,
    userId: userId ?? 'test-user-id',
    data: {
      'old_level': oldLevel ?? 1,
      'new_level': newLevel ?? 2,
      'current_xp': currentXP ?? 100,
      'xp_to_next_level': xpToNextLevel ?? 150,
    },
    timestamp: timestamp,
  );
}

/// Create a test GamificationEvent for streak increased
GamificationEvent createTestStreakIncreasedEvent({
  String? userId,
  int? currentStreak,
  int? longestStreak,
  DateTime? timestamp,
}) {
  return GamificationEvent(
    type: GamificationEventType.streakIncreased,
    userId: userId ?? 'test-user-id',
    data: {
      'current_streak': currentStreak ?? 5,
      'longest_streak': longestStreak ?? 10,
    },
    timestamp: timestamp,
  );
}

/// Create a test GamificationEvent for streak milestone
GamificationEvent createTestStreakMilestoneEvent({
  String? userId,
  int? streak,
  DateTime? timestamp,
}) {
  return GamificationEvent(
    type: GamificationEventType.streakMilestone,
    userId: userId ?? 'test-user-id',
    data: {
      'streak': streak ?? 7,
    },
    timestamp: timestamp,
  );
}

// ========================================
// User Data Factories (for Supabase user table)
// ========================================

/// Create a test user data map (as stored in users table)
Map<String, dynamic> createTestUserData({
  String? id,
  String? email,
  String? displayName,
  int? level,
  int? points,
  int? currentStreak,
  int? longestStreak,
  String? lastStreakDate,
  int? totalInteractions,
  List<String>? badges,
  String? createdAt,
  String? updatedAt,
}) {
  return {
    'id': id ?? 'test-user-id',
    'email': email ?? 'test@example.com',
    'display_name': displayName ?? 'Test User',
    'level': level ?? 1,
    'points': points ?? 0,
    'current_streak': currentStreak ?? 0,
    'longest_streak': longestStreak ?? 0,
    'last_streak_date': lastStreakDate,
    'total_interactions': totalInteractions ?? 0,
    'badges': badges ?? [],
    'created_at': createdAt ?? DateTime.now().toIso8601String(),
    'updated_at': updatedAt,
  };
}
