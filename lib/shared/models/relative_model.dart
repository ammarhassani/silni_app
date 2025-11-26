/// Relationship types for relatives
enum RelationshipType {
  father('father', 'أب', 1),
  mother('mother', 'أم', 1),
  brother('brother', 'أخ', 2),
  sister('sister', 'أخت', 2),
  son('son', 'ابن', 3),
  daughter('daughter', 'ابنة', 3),
  grandfather('grandfather', 'جد', 1),
  grandmother('grandmother', 'جدة', 1),
  uncle('uncle', 'عم/خال', 2),
  aunt('aunt', 'عمة/خالة', 2),
  nephew('nephew', 'ابن الأخ', 3),
  niece('niece', 'بنت الأخت', 3),
  cousin('cousin', 'ابن/بنت العم', 3),
  husband('husband', 'زوج', 1),
  wife('wife', 'زوجة', 1),
  other('other', 'أخرى', 3);

  final String value;
  final String arabicName;
  final int priority; // 1 = high, 2 = medium, 3 = low

  const RelationshipType(this.value, this.arabicName, this.priority);

  static RelationshipType fromString(String value) {
    return RelationshipType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => RelationshipType.other,
    );
  }
}

/// Gender enum
enum Gender {
  male('male', 'ذكر'),
  female('female', 'أنثى');

  final String value;
  final String arabicName;

  const Gender(this.value, this.arabicName);

  static Gender? fromString(String? value) {
    if (value == null) return null;
    return Gender.values.firstWhere(
      (gender) => gender.value == value,
      orElse: () => Gender.male,
    );
  }
}

/// Avatar types for visual representation
enum AvatarType {
  youngBoy('young_boy', 'ولد صغير', '👦'),
  youngGirl('young_girl', 'بنت صغيرة', '👧'),
  teenBoy('teen_boy', 'شاب مراهق', '🧑'),
  teenGirl('teen_girl', 'فتاة مراهقة', '👧'),
  adultMan('adult_man', 'رجل', '👨'),
  adultWoman('adult_woman', 'امرأة', '👩'),
  womanWithHijab('woman_hijab', 'امرأة بحجاب', '🧕'),
  beardedMan('bearded_man', 'رجل بلحية', '🧔'),
  elderlyMan('elderly_man', 'رجل مسن', '👴'),
  elderlyWoman('elderly_woman', 'امرأة مسنة', '👵');

  final String value;
  final String arabicName;
  final String emoji;

  const AvatarType(this.value, this.arabicName, this.emoji);

  static AvatarType fromString(String? value) {
    if (value == null) return AvatarType.adultMan;
    return AvatarType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => AvatarType.adultMan,
    );
  }

  /// Auto-suggest avatar type based on relationship and gender
  static AvatarType suggestFromRelationship(RelationshipType relationship, Gender? gender) {
    switch (relationship) {
      case RelationshipType.father:
        return AvatarType.beardedMan;
      case RelationshipType.mother:
        return AvatarType.womanWithHijab;
      case RelationshipType.grandfather:
        return AvatarType.elderlyMan;
      case RelationshipType.grandmother:
        return AvatarType.elderlyWoman;
      case RelationshipType.son:
        return AvatarType.youngBoy;
      case RelationshipType.daughter:
        return AvatarType.youngGirl;
      case RelationshipType.brother:
        return AvatarType.adultMan;
      case RelationshipType.sister:
        return AvatarType.womanWithHijab;
      case RelationshipType.uncle:
        return AvatarType.beardedMan;
      case RelationshipType.aunt:
        return AvatarType.womanWithHijab;
      case RelationshipType.nephew:
        return AvatarType.teenBoy;
      case RelationshipType.niece:
        return AvatarType.teenGirl;
      case RelationshipType.husband:
        return AvatarType.beardedMan;
      case RelationshipType.wife:
        return AvatarType.womanWithHijab;
      case RelationshipType.cousin:
        return gender == Gender.male ? AvatarType.adultMan : AvatarType.adultWoman;
      case RelationshipType.other:
        return gender == Gender.male ? AvatarType.adultMan : AvatarType.adultWoman;
    }
  }

  /// Auto-suggest priority based on relationship closeness
  static int suggestPriority(RelationshipType relationship) {
    switch (relationship) {
      // High priority - immediate family
      case RelationshipType.father:
      case RelationshipType.mother:
      case RelationshipType.husband:
      case RelationshipType.wife:
      case RelationshipType.son:
      case RelationshipType.daughter:
        return 1; // High priority

      // Medium priority - close family
      case RelationshipType.brother:
      case RelationshipType.sister:
      case RelationshipType.grandfather:
      case RelationshipType.grandmother:
        return 2; // Medium priority

      // Low priority - extended family
      case RelationshipType.uncle:
      case RelationshipType.aunt:
      case RelationshipType.nephew:
      case RelationshipType.niece:
      case RelationshipType.cousin:
      case RelationshipType.other:
        return 3; // Low priority
    }
  }
}

/// Model for a relative/family member
class Relative {
  final String id;
  final String userId;
  final String fullName;
  final RelationshipType relationshipType;
  final Gender? gender;
  final AvatarType? avatarType;
  final DateTime? dateOfBirth;
  final String? phoneNumber;
  final String? email;
  final String? address;
  final String? city;
  final String? country;
  final String? photoUrl;
  final String? notes;
  final List<String> tags;
  final int priority; // 1 = high, 2 = medium, 3 = low
  final String? islamicImportance;
  final String? preferredContactMethod;
  final String? bestTimeToContact;
  final int interactionCount;
  final DateTime? lastContactDate;
  final String? healthStatus;
  final bool isArchived;
  final bool isFavorite;
  final String? contactId; // Device contact ID for syncing
  final DateTime createdAt;
  final DateTime? updatedAt;

  Relative({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.relationshipType,
    this.gender,
    this.avatarType,
    this.dateOfBirth,
    this.phoneNumber,
    this.email,
    this.address,
    this.city,
    this.country,
    this.photoUrl,
    this.notes,
    this.tags = const [],
    this.priority = 2,
    this.islamicImportance,
    this.preferredContactMethod,
    this.bestTimeToContact,
    this.interactionCount = 0,
    this.lastContactDate,
    this.healthStatus,
    this.isArchived = false,
    this.isFavorite = false,
    this.contactId,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create from Supabase JSON
  factory Relative.fromJson(Map<String, dynamic> json) {
    return Relative(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      relationshipType: RelationshipType.fromString(json['relationship_type'] as String),
      gender: Gender.fromString(json['gender'] as String?),
      avatarType: AvatarType.fromString(json['avatar_type'] as String?),
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      phoneNumber: json['phone_number'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      photoUrl: json['photo_url'] as String?,
      notes: json['notes'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
      priority: json['priority'] as int? ?? 2,
      islamicImportance: json['islamic_importance'] as String?,
      preferredContactMethod: json['preferred_contact_method'] as String?,
      bestTimeToContact: json['best_time_to_contact'] as String?,
      interactionCount: json['interaction_count'] as int? ?? 0,
      lastContactDate: json['last_contact_date'] != null
          ? DateTime.parse(json['last_contact_date'] as String)
          : null,
      healthStatus: json['health_status'] as String?,
      isArchived: json['is_archived'] as bool? ?? false,
      isFavorite: json['is_favorite'] as bool? ?? false,
      contactId: json['contact_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'relationship_type': relationshipType.value,
      'gender': gender?.value,
      'avatar_type': avatarType?.value,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'phone_number': phoneNumber,
      'email': email,
      'address': address,
      'city': city,
      'country': country,
      'photo_url': photoUrl,
      'notes': notes,
      'tags': tags,
      'priority': priority,
      'islamic_importance': islamicImportance,
      'preferred_contact_method': preferredContactMethod,
      'best_time_to_contact': bestTimeToContact,
      'interaction_count': interactionCount,
      'last_contact_date': lastContactDate?.toIso8601String(),
      'health_status': healthStatus,
      'is_archived': isArchived,
      'is_favorite': isFavorite,
      'contact_id': contactId,
      // Don't include id, created_at, updated_at - managed by database
    };
  }

  /// Copy with method for immutability
  Relative copyWith({
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
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      relationshipType: relationshipType ?? this.relationshipType,
      gender: gender ?? this.gender,
      avatarType: avatarType ?? this.avatarType,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      photoUrl: photoUrl ?? this.photoUrl,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      priority: priority ?? this.priority,
      islamicImportance: islamicImportance ?? this.islamicImportance,
      preferredContactMethod: preferredContactMethod ?? this.preferredContactMethod,
      bestTimeToContact: bestTimeToContact ?? this.bestTimeToContact,
      interactionCount: interactionCount ?? this.interactionCount,
      lastContactDate: lastContactDate ?? this.lastContactDate,
      healthStatus: healthStatus ?? this.healthStatus,
      isArchived: isArchived ?? this.isArchived,
      isFavorite: isFavorite ?? this.isFavorite,
      contactId: contactId ?? this.contactId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get the display avatar emoji
  String get displayEmoji {
    if (avatarType != null) {
      return avatarType!.emoji;
    }
    // Fallback to auto-suggest based on relationship and gender
    return AvatarType.suggestFromRelationship(relationshipType, gender).emoji;
  }

  /// Get days since last contact
  int? get daysSinceLastContact {
    if (lastContactDate == null) return null;
    return DateTime.now().difference(lastContactDate!).inDays;
  }

  /// Check if needs contact (based on priority)
  bool get needsContact {
    if (lastContactDate == null) return true;
    final days = daysSinceLastContact!;

    // High priority (parents, spouse): every 2 days
    if (priority == 1) return days >= 2;
    // Medium priority (siblings, grandparents): every week
    if (priority == 2) return days >= 7;
    // Low priority (cousins, others): every 2 weeks
    return days >= 14;
  }
}
