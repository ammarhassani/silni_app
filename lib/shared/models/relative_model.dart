import 'package:cloud_firestore/cloud_firestore.dart';

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
  adultMan('adult_man', 'رجل بالغ', '👨'),
  adultWoman('adult_woman', 'امرأة بالغة', '👩'),
  womanWithHijab('woman_hijab', 'امرأة بحجاب', '🧕'),
  beardedMan('bearded_man', 'رجل بلحية', '🧔'),
  elderlyMan('elderly_man', 'رجل مسن', '👴'),
  elderlyWoman('elderly_woman', 'امرأة مسنة', '👵'),
  father('father', 'أب', '👨‍💼'),
  mother('mother', 'أم', '👩‍👧'),
  grandfather('grandfather', 'جد', '👴'),
  grandmother('grandmother', 'جدة', '👵');

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
        return AvatarType.father;
      case RelationshipType.mother:
        return AvatarType.mother;
      case RelationshipType.grandfather:
        return AvatarType.grandfather;
      case RelationshipType.grandmother:
        return AvatarType.grandmother;
      case RelationshipType.son:
        return AvatarType.youngBoy;
      case RelationshipType.daughter:
        return AvatarType.youngGirl;
      case RelationshipType.brother:
      case RelationshipType.uncle:
      case RelationshipType.nephew:
      case RelationshipType.cousin:
      case RelationshipType.husband:
        return gender == Gender.male ? AvatarType.adultMan : AvatarType.adultWoman;
      case RelationshipType.sister:
      case RelationshipType.aunt:
      case RelationshipType.niece:
      case RelationshipType.wife:
        return AvatarType.womanWithHijab;
      case RelationshipType.other:
        return gender == Gender.male ? AvatarType.adultMan : AvatarType.adultWoman;
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

  /// Create from Firestore document
  factory Relative.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Relative(
      id: doc.id,
      userId: data['userId'] as String,
      fullName: data['fullName'] as String,
      relationshipType: RelationshipType.fromString(data['relationshipType'] as String),
      gender: Gender.fromString(data['gender'] as String?),
      avatarType: AvatarType.fromString(data['avatarType'] as String?),
      dateOfBirth: (data['dateOfBirth'] as Timestamp?)?.toDate(),
      phoneNumber: data['phoneNumber'] as String?,
      email: data['email'] as String?,
      address: data['address'] as String?,
      city: data['city'] as String?,
      country: data['country'] as String?,
      photoUrl: data['photoUrl'] as String?,
      notes: data['notes'] as String?,
      tags: List<String>.from(data['tags'] ?? []),
      priority: data['priority'] as int? ?? 2,
      islamicImportance: data['islamicImportance'] as String?,
      preferredContactMethod: data['preferredContactMethod'] as String?,
      bestTimeToContact: data['bestTimeToContact'] as String?,
      interactionCount: data['interactionCount'] as int? ?? 0,
      lastContactDate: (data['lastContactDate'] as Timestamp?)?.toDate(),
      healthStatus: data['healthStatus'] as String?,
      isArchived: data['isArchived'] as bool? ?? false,
      isFavorite: data['isFavorite'] as bool? ?? false,
      contactId: data['contactId'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'fullName': fullName,
      'relationshipType': relationshipType.value,
      'gender': gender?.value,
      'avatarType': avatarType?.value,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'city': city,
      'country': country,
      'photoUrl': photoUrl,
      'notes': notes,
      'tags': tags,
      'priority': priority,
      'islamicImportance': islamicImportance,
      'preferredContactMethod': preferredContactMethod,
      'bestTimeToContact': bestTimeToContact,
      'interactionCount': interactionCount,
      'lastContactDate': lastContactDate != null ? Timestamp.fromDate(lastContactDate!) : null,
      'healthStatus': healthStatus,
      'isArchived': isArchived,
      'isFavorite': isFavorite,
      'contactId': contactId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
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
