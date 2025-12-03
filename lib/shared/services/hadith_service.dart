import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../models/hadith_model.dart';

class HadithService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  static const String _table = 'hadith';
  static const String _lastIndexKey = 'last_hadith_index';

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

  /// Get daily hadith (rotates on each call)
  Future<Hadith?> getDailyHadith() async {
    try {
      // Query hadith from Supabase (already seeded during setup)
      final response = await _supabase
          .from(_table)
          .select()
          .eq('topic', 'silat_rahim')
          .eq('is_authentic', true)
          .order('display_order')
          .timeout(
            const Duration(seconds: 20),  // Increased from 10s for iOS
            onTimeout: () {
              if (kDebugMode) {
                print('⏱️ [HADITH] Query timed out, using fallback hadith');
              }
              throw TimeoutException('Supabase query timed out');
            },
          );

      final hadithData = response as List;

      if (hadithData.isEmpty) {
        if (kDebugMode) {
          print('📿 [HADITH] Collection empty, using fallback hadith');
        }
        return _getDefaultHadithFallback();
      }

      final hadithList = hadithData
          .map((json) => Hadith.fromJson(json))
          .toList();

      // Get the last shown index from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final lastIndex = prefs.getInt(_lastIndexKey) ?? -1;

      // Calculate next index (rotate through list)
      final nextIndex = (lastIndex + 1) % hadithList.length;

      // Save the new index
      await prefs.setInt(_lastIndexKey, nextIndex);

      if (kDebugMode) {
        print('📿 [HADITH] Showing hadith ${nextIndex + 1} of ${hadithList.length}');
      }

      return hadithList[nextIndex];
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        print('⏱️ [HADITH] Timeout: $e - Using fallback hadith');
      }
      return _getDefaultHadithFallback();
    } catch (e) {
      if (kDebugMode) {
        print('❌ [HADITH] Error getting daily hadith: $e');
        print('📿 [HADITH] Using fallback hadith');
      }
      return _getDefaultHadithFallback();
    }
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
      if (kDebugMode) {
        print('❌ [HADITH] Error creating fallback hadith: $e');
      }
      return null;
    }
  }

  /// Get all hadith stream (for admin/management)
  Stream<List<Hadith>> getAllHadithStream() {
    try {
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
    } catch (e) {
      if (kDebugMode) {
        print('❌ [HADITH] Error streaming hadith: $e');
      }
      rethrow;
    }
  }

  /// Add new hadith (for future admin functionality)
  Future<String> addHadith(Hadith hadith) async {
    try {
      final response = await _supabase
          .from(_table)
          .insert(hadith.toJson())
          .select('id')
          .single();

      final id = response['id'] as String;

      if (kDebugMode) {
        print('✅ [HADITH] Added new hadith: $id');
      }
      return id;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [HADITH] Error adding hadith: $e');
      }
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

      if (kDebugMode) {
        print('✅ [HADITH] Updated hadith: $hadithId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [HADITH] Error updating hadith: $e');
      }
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

      if (kDebugMode) {
        print('✅ [HADITH] Deleted hadith: $hadithId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [HADITH] Error deleting hadith: $e');
      }
      rethrow;
    }
  }

  /// Reset rotation (start from beginning)
  Future<void> resetRotation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastIndexKey);
    if (kDebugMode) {
      print('🔄 [HADITH] Rotation reset');
    }
  }
}
