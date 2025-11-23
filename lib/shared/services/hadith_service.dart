import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hadith_model.dart';

class HadithService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'hadith';
  static const String _lastIndexKey = 'last_hadith_index';

  /// Get hadith collection reference
  CollectionReference<Map<String, dynamic>> get _hadithRef =>
      _firestore.collection(_collection);

  /// Default authentic hadith about family ties (صلة الرحم)
  /// These are pre-loaded if Firestore collection is empty
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
      // Add 10-second timeout to prevent infinite loading
      final snapshot = await _hadithRef
          .where('topic', isEqualTo: 'silat_rahim')
          .where('isAuthentic', isEqualTo: true)
          .orderBy('displayOrder')
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              if (kDebugMode) {
                print('⏱️ [HADITH] Query timed out, using fallback hadith');
              }
              // Return fallback: use default hadith directly
              throw TimeoutException('Firestore query timed out');
            },
          );

      if (snapshot.docs.isEmpty) {
        // Seed default hadith if collection is empty
        if (kDebugMode) {
          print('📿 [HADITH] Collection empty, seeding defaults...');
        }
        await _seedDefaultHadith();

        // After seeding, return a default hadith from local cache instead of retrying
        // This prevents infinite recursion if seeding fails
        return _getDefaultHadithFallback();
      }

      final hadithList = snapshot.docs
          .map((doc) => Hadith.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
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
      // Return a default hadith from local cache
      return _getDefaultHadithFallback();
    } catch (e) {
      if (kDebugMode) {
        print('❌ [HADITH] Error getting daily hadith: $e');
        print('📿 [HADITH] Using fallback hadith');
      }
      // Return a default hadith from local cache as fallback
      return _getDefaultHadithFallback();
    }
  }

  /// Get a fallback hadith from local default data (no Firestore needed)
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
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ [HADITH] Error creating fallback hadith: $e');
      }
      return null;
    }
  }

  /// Seed default hadith into Firestore
  Future<void> _seedDefaultHadith() async {
    try {
      if (kDebugMode) {
        print('📿 [HADITH] Seeding default hadith collection...');
      }

      final batch = _firestore.batch();
      for (final hadithData in defaultHadith) {
        final docRef = _hadithRef.doc();
        final hadith = {
          ...hadithData,
          'createdAt': Timestamp.now(),
        };
        batch.set(docRef, hadith);
      }

      await batch.commit();

      if (kDebugMode) {
        print('✅ [HADITH] Seeded ${defaultHadith.length} default hadith');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [HADITH] Error seeding hadith: $e');
      }
    }
  }

  /// Get all hadith (for admin/management)
  Stream<List<Hadith>> getAllHadithStream() {
    try {
      return _hadithRef
          .where('topic', isEqualTo: 'silat_rahim')
          .orderBy('displayOrder')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => Hadith.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList();
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
      final docRef = await _hadithRef.add(hadith.toFirestore());
      if (kDebugMode) {
        print('✅ [HADITH] Added new hadith: ${docRef.id}');
      }
      return docRef.id;
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
      updates['updatedAt'] = Timestamp.now();
      await _hadithRef.doc(hadithId).update(updates);
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
      await _hadithRef.doc(hadithId).delete();
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
