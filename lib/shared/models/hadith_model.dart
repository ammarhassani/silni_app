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

  /// Create from Supabase JSON
  factory Hadith.fromJson(Map<String, dynamic> json) {
    return Hadith(
      id: json['id'] as String,
      arabicText: json['arabic_text'] as String,
      englishTranslation: json['english_translation'] as String? ?? '',
      source: json['source'] as String,
      reference: json['reference'] as String? ?? '',
      topic: json['topic'] as String? ?? 'silat_rahim',
      type: HadithType.fromString(json['type'] as String? ?? 'hadith'),
      narrator: json['narrator'] as String? ?? '',
      scholar: json['scholar'] as String? ?? '',
      isAuthentic: json['is_authentic'] as bool? ?? true,
      displayOrder: json['display_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
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
      createdAt: data['createdAt'] is DateTime
          ? data['createdAt'] as DateTime
          : DateTime.now(),
      updatedAt: data['updatedAt'] is DateTime
          ? data['updatedAt'] as DateTime
          : null,
    );
  }

  /// Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'arabic_text': arabicText,
      'english_translation': englishTranslation,
      'source': source,
      'reference': reference,
      'topic': topic,
      'type': type.value,
      'narrator': narrator,
      'scholar': scholar,
      'is_authentic': isAuthentic,
      'display_order': displayOrder,
      // Don't include id, created_at, updated_at - managed by database
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
