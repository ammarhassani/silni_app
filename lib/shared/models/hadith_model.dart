import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for authentic hadith and scholarly quotes about family ties (صلة الرحم)
class Hadith {
  final String id;
  final String arabicText;
  final String englishTranslation;
  final String source; // e.g., "صحيح البخاري", "الإمام أحمد بن حنبل"
  final String reference; // Book and hadith number
  final String topic; // e.g., "silat_rahim", "family_bonds", "parents_rights"
  final HadithType type; // hadith, quote, verse
  final String narrator; // For hadith: who narrated it
  final String scholar; // For quotes: which scholar said it
  final bool isAuthentic; // Sahih verification
  final int displayOrder; // For rotation order
  final DateTime createdAt;
  final DateTime? updatedAt;

  Hadith({
    required this.id,
    required this.arabicText,
    required this.englishTranslation,
    required this.source,
    required this.reference,
    required this.topic,
    this.type = HadithType.hadith,
    this.narrator = '',
    this.scholar = '',
    this.isAuthentic = true,
    this.displayOrder = 0,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create from Firestore document
  factory Hadith.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Hadith(
      id: doc.id,
      arabicText: data['arabicText'] as String,
      englishTranslation: data['englishTranslation'] as String? ?? '',
      source: data['source'] as String,
      reference: data['reference'] as String? ?? '',
      topic: data['topic'] as String? ?? 'silat_rahim',
      type: HadithType.fromString(data['type'] as String? ?? 'hadith'),
      narrator: data['narrator'] as String? ?? '',
      scholar: data['scholar'] as String? ?? '',
      isAuthentic: data['isAuthentic'] as bool? ?? true,
      displayOrder: data['displayOrder'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Create from Map (for fallback hadith from local data)
  factory Hadith.fromMap(Map<String, dynamic> data) {
    return Hadith(
      id: data['id'] as String? ?? '',
      arabicText: data['arabicText'] as String,
      englishTranslation: data['englishTranslation'] as String? ?? '',
      source: data['source'] as String,
      reference: data['reference'] as String? ?? '',
      topic: data['topic'] as String? ?? 'silat_rahim',
      type: HadithType.fromString(data['type'] as String? ?? 'hadith'),
      narrator: data['narrator'] as String? ?? '',
      scholar: data['scholar'] as String? ?? '',
      isAuthentic: data['isAuthentic'] as bool? ?? true,
      displayOrder: data['displayOrder'] as int? ?? 0,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'arabicText': arabicText,
      'englishTranslation': englishTranslation,
      'source': source,
      'reference': reference,
      'topic': topic,
      'type': type.value,
      'narrator': narrator,
      'scholar': scholar,
      'isAuthentic': isAuthentic,
      'displayOrder': displayOrder,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  /// Get formatted source text
  String get formattedSource {
    if (type == HadithType.quote && scholar.isNotEmpty) {
      return 'الإمام $scholar';
    }
    if (type == HadithType.hadith && source.isNotEmpty) {
      return source;
    }
    return source;
  }
}

/// Types of Islamic texts
enum HadithType {
  hadith('hadith', 'حديث'),
  quote('quote', 'قول'),
  verse('verse', 'آية');

  final String value;
  final String arabicName;

  const HadithType(this.value, this.arabicName);

  static HadithType fromString(String value) {
    return HadithType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => HadithType.hadith,
    );
  }
}
