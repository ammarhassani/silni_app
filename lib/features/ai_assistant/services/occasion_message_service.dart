import 'package:silni_app/shared/models/relative_model.dart';

/// Types of occasions the service can detect
enum OccasionType {
  eidAlFitr('eid_al_fitr', 'عيد الفطر'),
  eidAlAdha('eid_al_adha', 'عيد الأضحى'),
  ramadan('ramadan', 'رمضان'),
  nationalDay('national_day', 'اليوم الوطني');

  final String key;
  final String arabicName;
  const OccasionType(this.key, this.arabicName);
}

/// A pre-generated occasion message for a specific relative
class OccasionMessage {
  final String relativeId;
  final String relativeName;
  final String relationshipType;
  final String? phoneNumber;
  final OccasionType occasion;
  final String message;
  final DateTime generatedAt;

  const OccasionMessage({
    required this.relativeId,
    required this.relativeName,
    required this.relationshipType,
    this.phoneNumber,
    required this.occasion,
    required this.message,
    required this.generatedAt,
  });
}

/// Service that detects upcoming occasions and provides pre-generated
/// template-based messages for relatives.
///
/// Messages are **not** AI-generated; they use localized Saudi Arabic
/// templates with name substitution.
class OccasionMessageService {
  OccasionMessageService._();

  /// Check if an occasion is coming within the next [daysAhead] days.
  /// Returns the upcoming occasion or null.
  static OccasionType? getUpcomingOccasion({int daysAhead = 7}) {
    final now = DateTime.now();

    // Approximate Hijri calendar dates for 2026 & 2027
    // Eid al-Fitr 2026: ~March 20
    // Eid al-Adha 2026: ~May 27
    // Ramadan 2026: ~Feb 18 - March 19
    // National Day: September 23 (fixed Gregorian)
    final occasions = <OccasionType, List<DateTime>>{
      OccasionType.eidAlFitr: [DateTime(2026, 3, 20), DateTime(2027, 3, 10)],
      OccasionType.eidAlAdha: [DateTime(2026, 5, 27), DateTime(2027, 5, 17)],
      OccasionType.ramadan: [DateTime(2026, 2, 18), DateTime(2027, 2, 8)],
      OccasionType.nationalDay: [
        DateTime(2026, 9, 23),
        DateTime(2027, 9, 23),
      ],
    };

    for (final entry in occasions.entries) {
      for (final date in entry.value) {
        final diff = date.difference(now).inDays;
        if (diff >= 0 && diff <= daysAhead) {
          return entry.key;
        }
      }
    }
    return null;
  }

  /// Generate personalized messages for all relatives for the given occasion.
  ///
  /// Returns a list of pre-generated messages using template patterns.
  /// These are **not** AI-generated -- just localized templates with
  /// relative names substituted in.
  static List<OccasionMessage> generateMessages({
    required OccasionType occasion,
    required List<Relative> relatives,
  }) {
    return relatives.map((relative) {
      final message = _buildMessage(occasion, relative);
      return OccasionMessage(
        relativeId: relative.id,
        relativeName: relative.fullName,
        relationshipType: relative.relationshipType.arabicName,
        occasion: occasion,
        message: message,
        generatedAt: DateTime.now(),
      );
    }).toList();
  }

  /// Build a message from templates.
  ///
  /// Uses a deterministic hash of the relative's name to pick a template
  /// so the same relative always gets the same message for a given occasion.
  static String _buildMessage(OccasionType occasion, Relative relative) {
    final name = relative.fullName;
    final templates =
        _templates[occasion] ?? _templates[OccasionType.eidAlFitr]!;
    // Use a simple hash to pick a template deterministically per relative
    final index = name.hashCode.abs() % templates.length;
    return templates[index].replaceAll('{name}', name);
  }

  static const Map<OccasionType, List<String>> _templates = {
    OccasionType.eidAlFitr: [
      'كل عام وأنت بخير يا {name}، عساك من عوّاده 🌙',
      'عيد مبارك يا {name}! الله يعيده عليك بالصحة والسعادة 🎉',
      '{name}، عيدك مبارك وعساك من العايدين والفايزين ✨',
      'تقبّل الله طاعتك يا {name}، وكل عام وأنت بألف خير 🤲',
    ],
    OccasionType.eidAlAdha: [
      'عيد أضحى مبارك يا {name}! عساك من عوّاده 🐑',
      '{name}، كل عام وأنت بخير بمناسبة عيد الأضحى المبارك 🌟',
      'تقبّل الله ضحيتك يا {name}، عيد مبارك عليك وعلى أهلك 🤲',
      '{name}، عيدك مبارك! الله يجعل أيامك كلها أعياد 🎊',
    ],
    OccasionType.ramadan: [
      'رمضان كريم يا {name}! الله يبلّغك ويبلّغنا 🌙',
      '{name}، مبارك عليك الشهر! الله يتقبل صيامك وقيامك 🤲',
      'كل عام وأنت بخير يا {name}، رمضان مبارك عليك 🕌',
      '{name}، شهر مبارك عليك وعلى عائلتك، الله يعينك على الصيام ✨',
    ],
    OccasionType.nationalDay: [
      'يوم وطني مجيد يا {name}! دام عزك يا وطن 🇸🇦',
      '{name}، كل عام والوطن بخير! اليوم الوطني مبارك 💚',
      'عاشت المملكة! يوم وطني سعيد يا {name} 🇸🇦✨',
    ],
  };
}
