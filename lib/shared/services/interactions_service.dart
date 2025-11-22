import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/interaction_model.dart';
import 'relatives_service.dart';

class InteractionsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RelativesService _relativesService = RelativesService();
  static const String _collection = 'interactions';

  /// Get interactions collection reference
  CollectionReference<Map<String, dynamic>> get _interactionsRef =>
      _firestore.collection(_collection);

  /// Create a new interaction
  Future<String> createInteraction(Interaction interaction) async {
    try {
      if (kDebugMode) {
        print('📝 [INTERACTIONS] Creating ${interaction.type.arabicName} interaction');
      }

      // Create the interaction document
      final docRef = await _interactionsRef.add(interaction.toFirestore());

      // Update the relative's interaction count and last contact date
      await _relativesService.recordInteraction(interaction.relativeId);

      if (kDebugMode) {
        print('✅ [INTERACTIONS] Created interaction with ID: ${docRef.id}');
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [INTERACTIONS] Error creating interaction: $e');
      }
      rethrow;
    }
  }

  /// Get all interactions for a user
  Stream<List<Interaction>> getInteractionsStream(String userId) {
    try {
      if (kDebugMode) {
        print('📡 [INTERACTIONS] Streaming interactions for user: $userId');
      }

      return _interactionsRef
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return Interaction.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
        }).toList();
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ [INTERACTIONS] Error streaming interactions: $e');
      }
      rethrow;
    }
  }

  /// Get interactions for a specific relative
  Stream<List<Interaction>> getRelativeInteractionsStream(String relativeId) {
    try {
      return _interactionsRef
          .where('relativeId', isEqualTo: relativeId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return Interaction.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
        }).toList();
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ [INTERACTIONS] Error streaming relative interactions: $e');
      }
      rethrow;
    }
  }

  /// Get recent interactions (last N)
  Future<List<Interaction>> getRecentInteractions(String userId, {int limit = 10}) async {
    try {
      final snapshot = await _interactionsRef
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return Interaction.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ [INTERACTIONS] Error getting recent interactions: $e');
      }
      return [];
    }
  }

  /// Get interactions for today
  Stream<List<Interaction>> getTodayInteractionsStream(String userId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _interactionsRef
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Interaction.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
      }).toList();
    });
  }

  /// Get interactions count for a date range
  Future<int> getInteractionsCount(String userId, DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await _interactionsRef
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [INTERACTIONS] Error counting interactions: $e');
      }
      return 0;
    }
  }

  /// Get interactions count by type for a user
  Future<Map<InteractionType, int>> getInteractionCountsByType(String userId) async {
    try {
      final snapshot = await _interactionsRef
          .where('userId', isEqualTo: userId)
          .get();

      final Map<InteractionType, int> counts = {};

      for (final doc in snapshot.docs) {
        final interaction = Interaction.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
        counts[interaction.type] = (counts[interaction.type] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [INTERACTIONS] Error counting by type: $e');
      }
      return {};
    }
  }

  /// Update an interaction
  Future<void> updateInteraction(String interactionId, Map<String, dynamic> updates) async {
    try {
      if (kDebugMode) {
        print('📝 [INTERACTIONS] Updating interaction: $interactionId');
      }

      updates['updatedAt'] = Timestamp.now();
      await _interactionsRef.doc(interactionId).update(updates);

      if (kDebugMode) {
        print('✅ [INTERACTIONS] Updated interaction: $interactionId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [INTERACTIONS] Error updating interaction: $e');
      }
      rethrow;
    }
  }

  /// Delete an interaction
  Future<void> deleteInteraction(String interactionId) async {
    try {
      if (kDebugMode) {
        print('🗑️ [INTERACTIONS] Deleting interaction: $interactionId');
      }

      await _interactionsRef.doc(interactionId).delete();

      if (kDebugMode) {
        print('✅ [INTERACTIONS] Deleted interaction: $interactionId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [INTERACTIONS] Error deleting interaction: $e');
      }
      rethrow;
    }
  }

  /// Check if user has interacted today (for streak calculation)
  Future<bool> hasInteractedToday(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final snapshot = await _interactionsRef
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [INTERACTIONS] Error checking today interaction: $e');
      }
      return false;
    }
  }

  /// Get total interactions count for a user
  Future<int> getTotalInteractionsCount(String userId) async {
    try {
      final snapshot = await _interactionsRef
          .where('userId', isEqualTo: userId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [INTERACTIONS] Error getting total count: $e');
      }
      return 0;
    }
  }
}
