import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/relative_model.dart';

class RelativesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'relatives';

  /// Get relatives collection reference
  CollectionReference<Map<String, dynamic>> get _relativesRef =>
      _firestore.collection(_collection);

  /// Create a new relative
  Future<String> createRelative(Relative relative) async {
    try {
      if (kDebugMode) {
        print('📝 [RELATIVES] Creating relative: ${relative.fullName}');
      }

      final docRef = await _relativesRef.add(relative.toFirestore());

      if (kDebugMode) {
        print('✅ [RELATIVES] Created relative with ID: ${docRef.id}');
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [RELATIVES] Error creating relative: $e');
      }
      rethrow;
    }
  }

  /// Get all relatives for a user
  Stream<List<Relative>> getRelativesStream(String userId) {
    try {
      if (kDebugMode) {
        print('📡 [RELATIVES] Streaming relatives for user: $userId');
      }

      return _relativesRef
          .where('userId', isEqualTo: userId)
          .where('isArchived', isEqualTo: false)
          .orderBy('priority', descending: false)
          .orderBy('fullName', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return Relative.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
        }).toList();
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ [RELATIVES] Error streaming relatives: $e');
      }
      rethrow;
    }
  }

  /// Get a single relative by ID
  Future<Relative?> getRelative(String relativeId) async {
    try {
      if (kDebugMode) {
        print('📖 [RELATIVES] Fetching relative: $relativeId');
      }

      final doc = await _relativesRef.doc(relativeId).get();
      if (!doc.exists) {
        if (kDebugMode) {
          print('⚠️ [RELATIVES] Relative not found: $relativeId');
        }
        return null;
      }

      return Relative.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
    } catch (e) {
      if (kDebugMode) {
        print('❌ [RELATIVES] Error fetching relative: $e');
      }
      rethrow;
    }
  }

  /// Update a relative
  Future<void> updateRelative(String relativeId, Map<String, dynamic> updates) async {
    try {
      if (kDebugMode) {
        print('📝 [RELATIVES] Updating relative: $relativeId');
      }

      // Add updatedAt timestamp
      updates['updatedAt'] = Timestamp.now();

      await _relativesRef.doc(relativeId).update(updates);

      if (kDebugMode) {
        print('✅ [RELATIVES] Updated relative: $relativeId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [RELATIVES] Error updating relative: $e');
      }
      rethrow;
    }
  }

  /// Delete (archive) a relative
  Future<void> deleteRelative(String relativeId) async {
    try {
      if (kDebugMode) {
        print('🗑️ [RELATIVES] Archiving relative: $relativeId');
      }

      await _relativesRef.doc(relativeId).update({
        'isArchived': true,
        'updatedAt': Timestamp.now(),
      });

      if (kDebugMode) {
        print('✅ [RELATIVES] Archived relative: $relativeId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [RELATIVES] Error archiving relative: $e');
      }
      rethrow;
    }
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String relativeId, bool isFavorite) async {
    try {
      await _relativesRef.doc(relativeId).update({
        'isFavorite': isFavorite,
        'updatedAt': Timestamp.now(),
      });

      if (kDebugMode) {
        print('⭐ [RELATIVES] Toggled favorite for $relativeId: $isFavorite');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [RELATIVES] Error toggling favorite: $e');
      }
      rethrow;
    }
  }

  /// Increment interaction count and update last contact date
  Future<void> recordInteraction(String relativeId) async {
    try {
      await _relativesRef.doc(relativeId).update({
        'interactionCount': FieldValue.increment(1),
        'lastContactDate': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      if (kDebugMode) {
        print('📊 [RELATIVES] Recorded interaction for: $relativeId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [RELATIVES] Error recording interaction: $e');
      }
      rethrow;
    }
  }

  /// Get relatives that need contact (based on priority)
  Stream<List<Relative>> getRelativesNeedingContact(String userId) {
    return getRelativesStream(userId).map((relatives) {
      return relatives.where((relative) => relative.needsContact).toList();
    });
  }

  /// Get favorite relatives
  Stream<List<Relative>> getFavoriteRelatives(String userId) {
    return _relativesRef
        .where('userId', isEqualTo: userId)
        .where('isFavorite', isEqualTo: true)
        .where('isArchived', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Relative.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
      }).toList();
    });
  }

  /// Search relatives by name
  Stream<List<Relative>> searchRelatives(String userId, String query) {
    return getRelativesStream(userId).map((relatives) {
      if (query.isEmpty) return relatives;
      return relatives.where((relative) {
        return relative.fullName.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  /// Get relatives count
  Future<int> getRelativesCount(String userId) async {
    try {
      final snapshot = await _relativesRef
          .where('userId', isEqualTo: userId)
          .where('isArchived', isEqualTo: false)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [RELATIVES] Error counting relatives: $e');
      }
      return 0;
    }
  }
}
