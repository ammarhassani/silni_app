import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/services/app_logger_service.dart';
import '../../core/services/content_config_service.dart';
import '../models/hadith_model.dart';

class HadithService {
  // Use lazy initialization to avoid accessing Supabase before it's initialized
  SupabaseClient get _supabase => SupabaseConfig.client;
  final AppLoggerService _logger = AppLoggerService();
  static const String _table = 'hadith';
  static const String _lastIndexKey = 'last_hadith_index';

  /// Reference to ContentConfigService for admin-configured hadith
  ContentConfigService get _contentConfig => ContentConfigService.instance;

  /// Default authentic hadith about family ties (صلة الرحم)
  /// These are used as fallback if database is unavailable
  static final List<Map<String, dynamic>> defaultHadith = [
    {
      'arabicText': 'قال رسول الله ﷺ: "مَن أَحَبَّ أَنْ يُبْسَطَ له في رِزْقِهِ، وَيُنْسَأَ له في أَثَرِهِ، فَلْيَصِلْ رَحِمَهُ"',
      'englishTranslation': 'The Prophet ﷺ said: "Whoever wishes to have his provision expanded and his lifespan extended, let him maintain family ties"',
      'source': 'صحيح البخاري',
      'reference': '٥٩٨٦',
      'topic': 'silat_rahim',
      'type': 'hadith',
      'narrator': 'أنس بن مالك',
      'isAuthentic': true,
      'displayOrder': 1,
    },
    {
      'arabicText': 'قال الإمام أحمد بن حنبل رحمه الله: "صلة الرحم تزيد في العمر وتوسع في الرزق وتدفع ميتة السوء"',
      'englishTranslation': 'Imam Ahmad ibn Hanbal said: "Maintaining family ties increases lifespan, expands provision, and prevents bad death"',
      'source': 'مسند الإمام أحمد',
      'reference': '',
      'topic': 'silat_rahim',
      'type': 'quote',
      'scholar': 'أحمد بن حنبل',
      'isAuthentic': true,
      'displayOrder': 2,
    },
    {
      'arabicText': 'قال رسول الله ﷺ: "الرَّحِمُ مُعَلَّقَةٌ بالعَرْشِ تَقُولُ: مَن وصَلَنِي وصَلَهُ اللَّهُ، ومَن قَطَعَنِي قَطَعَهُ اللَّهُ"',
      'englishTranslation': 'The Prophet ﷺ said: "The family ties (womb relations) are hanging onto the Throne, saying: Whoever maintains me, Allah will maintain ties with him, and whoever cuts me off, Allah will cut him off"',
      'source': 'صحيح البخاري',
      'reference': '٥٩٨٨',
      'topic': 'silat_rahim',
      'type': 'hadith',
      'narrator': 'عبد الرحمن بن عوف',
      'isAuthentic': true,
      'displayOrder': 3,
    },
    {
      'arabicText': 'قال الإمام ابن قدامة المقدسي: "وصلة الرحم من أعظم القربات وأجل الطاعات، وقطيعتها من أكبر الكبائر"',
      'englishTranslation': 'Imam Ibn Qudamah al-Maqdisi said: "Maintaining family ties is among the greatest acts of devotion and noblest obedience, and severing them is among the gravest sins"',
      'source': 'المغني',
      'reference': 'كتاب الآداب',
      'topic': 'silat_rahim',
      'type': 'quote',
      'scholar': 'ابن قدامة المقدسي',
      'isAuthentic': true,
      'displayOrder': 4,
    },
    {
      'arabicText': 'قال رسول الله ﷺ: "لا يَدْخُلُ الجَنَّةَ قاطِعُ رَحِمٍ"',
      'englishTranslation': 'The Prophet ﷺ said: "The one who severs family ties will not enter Paradise"',
      'source': 'صحيح البخاري',
      'reference': '٥٩٨٤',
      'topic': 'silat_rahim',
      'type': 'hadith',
      'narrator': 'جبير بن مطعم',
      'isAuthentic': true,
      'displayOrder': 5,
    },
    {
      'arabicText': 'قال الإمام البهوتي: "صلة الرحم واجبة، وهي الإحسان إلى الأقارب على حسب حال الواصل والموصول"',
      'englishTranslation': 'Imam al-Bahuti said: "Maintaining family ties is obligatory, and it means being good to relatives according to the condition of both the one maintaining ties and those being connected with"',
      'source': 'كشاف القناع',
      'reference': '',
      'topic': 'silat_rahim',
      'type': 'quote',
      'scholar': 'البهوتي',
      'isAuthentic': true,
      'displayOrder': 6,
    },
    {
      'arabicText': 'قال رسول الله ﷺ: "ليس الواصِلُ بالمُكافِئِ، ولكنَّ الواصِلَ الذي إذا قُطِعَتْ رَحِمُهُ وصَلَها"',
      'englishTranslation': 'The Prophet ﷺ said: "The one who truly maintains family ties is not the one who reciprocates, but the one who maintains ties even when they are cut off from him"',
      'source': 'صحيح البخاري',
      'reference': '٥٩٩١',
      'topic': 'silat_rahim',
      'type': 'hadith',
      'narrator': 'عبد الله بن عمرو',
      'isAuthentic': true,
      'displayOrder': 7,
    },
    {
      'arabicText': 'قال الإمام المرداوي: "صلة الرحم من أفضل الأعمال وأحبها إلى الله تعالى، وهي سبب لزيادة العمر والبركة في الرزق"',
      'englishTranslation': 'Imam al-Mardawi said: "Maintaining family ties is among the best deeds and most beloved to Allah, and it is a cause for increased lifespan and blessings in provision"',
      'source': 'الإنصاف',
      'reference': '',
      'topic': 'silat_rahim',
      'type': 'quote',
      'scholar': 'المرداوي',
      'isAuthentic': true,
      'displayOrder': 8,
    },
  ];

  /// Get daily Islamic content (hadith or scholar quote)
  /// Priority: 1) admin tables via ContentConfigService (alternates hadith/quotes)
  ///           2) hardcoded fallback
  Future<Hadith?> getDailyHadith() async {
    // Try admin-configured content first (from ContentConfigService)
    // This alternates between hadith and quotes for variety
    final content = _contentConfig.getDailyIslamicContent();

    if (content != null) {
      // Check if it's a hadith or a quote
      if (content is AdminHadith) {
        _logger.info(
          'Using admin-configured hadith',
          category: LogCategory.database,
          tag: 'HadithService',
        );
        return Hadith.fromMap({
          'id': content.id,
          'arabicText': content.hadithText,
          'source': content.source,
          'narrator': content.narrator,
          'topic': content.category,
          'type': 'hadith',
          'isAuthentic': content.grade == 'صحيح',
          'displayOrder': content.displayPriority,
          'createdAt': DateTime.now(),
        });
      } else if (content is AdminQuote) {
        _logger.info(
          'Using admin-configured quote',
          category: LogCategory.database,
          tag: 'HadithService',
        );
        return Hadith.fromMap({
          'id': content.id,
          'arabicText': content.quoteText,
          'source': content.source ?? '',
          'scholar': content.author,
          'topic': content.category,
          'type': 'quote',
          'isAuthentic': true,
          'displayOrder': content.displayPriority,
          'createdAt': DateTime.now(),
        });
      }
    }

    // Fallback to hardcoded content
    _logger.warning(
      'Admin content not available, using hardcoded fallback',
      category: LogCategory.database,
      tag: 'HadithService',
    );
    return _getDefaultHadithFallback();
  }

  /// Get a fallback hadith from local default data (no database needed)
  Hadith? _getDefaultHadithFallback() {
    try {
      if (defaultHadith.isEmpty) return null;

      // Rotate through default hadith based on current date
      final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
      final index = dayOfYear % defaultHadith.length;

      final hadithData = defaultHadith[index];

      // Create Hadith object from default data
      return Hadith.fromMap({
        ...hadithData,
        'id': 'fallback_$index',
        'createdAt': DateTime.now(),
      });
    } catch (e) {
      _logger.warning(
        'Failed to get default hadith fallback',
        category: LogCategory.database,
        tag: 'HadithService',
        metadata: {'error': e.toString()},
      );
      return null;
    }
  }

  /// Get all hadith stream (for admin/management)
  Stream<List<Hadith>> getAllHadithStream() {
    return _supabase
        .from(_table)
        .stream(primaryKey: ['id'])
        .map((data) {
      // Filter for silat_rahim topic and sort by display order
      final filtered = data
          .where((json) => json['topic'] == 'silat_rahim')
          .map((json) => Hadith.fromJson(json))
          .toList();

      // Sort by display order
      filtered.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

      return filtered;
    });
  }

  /// Add new hadith (for future admin functionality)
  Future<String> addHadith(Hadith hadith) async {
    try {
      final response = await _supabase
          .from(_table)
          .insert(hadith.toJson())
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      _logger.error(
        'Failed to add hadith',
        category: LogCategory.database,
        tag: 'HadithService',
        metadata: {'error': e.toString()},
      );
      rethrow;
    }
  }

  /// Update hadith
  Future<void> updateHadith(String hadithId, Map<String, dynamic> updates) async {
    try {
      // Note: updated_at is automatically set by database trigger
      await _supabase
          .from(_table)
          .update(updates)
          .eq('id', hadithId);
    } catch (e) {
      _logger.error(
        'Failed to update hadith',
        category: LogCategory.database,
        tag: 'HadithService',
        metadata: {'hadithId': hadithId, 'error': e.toString()},
      );
      rethrow;
    }
  }

  /// Delete hadith
  Future<void> deleteHadith(String hadithId) async {
    try {
      await _supabase
          .from(_table)
          .delete()
          .eq('id', hadithId);
    } catch (e) {
      _logger.error(
        'Failed to delete hadith',
        category: LogCategory.database,
        tag: 'HadithService',
        metadata: {'hadithId': hadithId, 'error': e.toString()},
      );
      rethrow;
    }
  }

  /// Reset rotation (start from beginning)
  Future<void> resetRotation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastIndexKey);
  }
}
