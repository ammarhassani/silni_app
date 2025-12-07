import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../models/relative_model.dart';

class ContactsImportService {
  /// Request contacts permission
  Future<bool> requestPermission() async {
    try {
      final permission = await FlutterContacts.requestPermission();
      if (kDebugMode) {
        print('📇 [CONTACTS] Permission: $permission');
      }
      return permission;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [CONTACTS] Permission error: $e');
      }
      return false;
    }
  }

  /// Get all contacts from device
  Future<List<Contact>> getAllContacts() async {
    try {
      if (kDebugMode) {
        print('📇 [CONTACTS] Fetching all contacts...');
      }

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );

      if (kDebugMode) {
        print('✅ [CONTACTS] Found ${contacts.length} contacts');
      }

      return contacts;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [CONTACTS] Error fetching contacts: $e');
      }
      return [];
    }
  }

  /// Search contacts by name
  Future<List<Contact>> searchContacts(String query) async {
    try {
      final allContacts = await getAllContacts();
      final filtered = allContacts.where((contact) {
        final name = contact.displayName.toLowerCase();
        return name.contains(query.toLowerCase());
      }).toList();

      if (kDebugMode) {
        print('🔍 [CONTACTS] Found ${filtered.length} matches for "$query"');
      }

      return filtered;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [CONTACTS] Search error: $e');
      }
      return [];
    }
  }

  /// Auto-detect relationship type from contact name
  RelationshipType detectRelationship(String name) {
    final lowerName = name.toLowerCase();

    // Arabic relationship keywords
    if (lowerName.contains('أب') ||
        lowerName.contains('والد') ||
        lowerName.contains('أبي') ||
        lowerName == 'dad' ||
        lowerName == 'father' ||
        lowerName == 'papa' ||
        lowerName == 'baba') {
      return RelationshipType.father;
    }

    if (lowerName.contains('أم') ||
        lowerName.contains('والدة') ||
        lowerName.contains('أمي') ||
        lowerName == 'mom' ||
        lowerName == 'mother' ||
        lowerName == 'mama' ||
        lowerName == 'mommy') {
      return RelationshipType.mother;
    }

    if (lowerName.contains('جد') ||
        lowerName.contains('grandfather') ||
        lowerName.contains('grandpa')) {
      return RelationshipType.grandfather;
    }

    if (lowerName.contains('جدة') ||
        lowerName.contains('grandmother') ||
        lowerName.contains('grandma')) {
      return RelationshipType.grandmother;
    }

    if (lowerName.contains('أخ') ||
        lowerName.contains('brother') ||
        lowerName.contains('bro')) {
      return RelationshipType.brother;
    }

    if (lowerName.contains('أخت') ||
        lowerName.contains('sister') ||
        lowerName.contains('sis')) {
      return RelationshipType.sister;
    }

    if (lowerName.contains('عم') || lowerName.contains('uncle')) {
      return RelationshipType.uncle;
    }

    if (lowerName.contains('عمة') ||
        lowerName.contains('خالة') ||
        lowerName.contains('aunt')) {
      return RelationshipType.aunt;
    }

    if (lowerName.contains('ابن') || lowerName.contains('son')) {
      return RelationshipType.son;
    }

    if (lowerName.contains('ابنة') ||
        lowerName.contains('بنت') ||
        lowerName.contains('daughter')) {
      return RelationshipType.daughter;
    }

    if (lowerName.contains('زوج') || lowerName.contains('husband')) {
      return RelationshipType.husband;
    }

    if (lowerName.contains('زوجة') || lowerName.contains('wife')) {
      return RelationshipType.wife;
    }

    // Default to other if no relationship detected
    return RelationshipType.other;
  }

  /// Detect gender from name (basic heuristic)
  Gender? detectGender(String name) {
    final lowerName = name.toLowerCase();

    // Common Arabic female indicators
    if (lowerName.endsWith('ة') ||
        lowerName.endsWith('اء') ||
        lowerName.contains('فاطمة') ||
        lowerName.contains('عائشة') ||
        lowerName.contains('خديجة') ||
        lowerName.contains('مريم') ||
        lowerName.contains('زينب')) {
      return Gender.female;
    }

    // Common male indicators
    if (lowerName.contains('محمد') ||
        lowerName.contains('أحمد') ||
        lowerName.contains('علي') ||
        lowerName.contains('حسن') ||
        lowerName.contains('حسين')) {
      return Gender.male;
    }

    return null; // Unknown
  }

  /// Create suggested relative from contact
  Map<String, dynamic> createSuggestedRelative({
    required String userId,
    required Contact contact,
  }) {
    final name = contact.displayName;
    final relationship = detectRelationship(name);
    final gender = detectGender(name);

    // Get phone number
    String? phoneNumber;
    if (contact.phones.isNotEmpty) {
      phoneNumber = contact.phones.first.number;
    }

    // Get email
    String? email;
    if (contact.emails.isNotEmpty) {
      email = contact.emails.first.address;
    }

    // Auto-determine priority based on relationship
    int priority = 2; // Medium by default
    if (relationship == RelationshipType.father ||
        relationship == RelationshipType.mother ||
        relationship == RelationshipType.husband ||
        relationship == RelationshipType.wife) {
      priority = 1; // High priority
    } else if (relationship == RelationshipType.cousin ||
        relationship == RelationshipType.nephew ||
        relationship == RelationshipType.niece) {
      priority = 3; // Low priority
    }

    return {
      'user_id': userId,
      'full_name': name,
      'relationship_type': relationship,
      'gender': gender,
      'phone_number': phoneNumber,
      'email': email,
      'priority': priority,
      'contactId': contact.id, // Store original contact ID
      'avatar_type': AvatarType.suggestFromRelationship(relationship, gender),
    };
  }

  /// Batch import contacts
  Future<List<Map<String, dynamic>>> batchImportContacts({
    required String userId,
    required List<Contact> contacts,
  }) async {
    try {
      if (kDebugMode) {
        print('📦 [CONTACTS] Batch importing ${contacts.length} contacts...');
      }

      final suggestions = contacts.map((contact) {
        return createSuggestedRelative(userId: userId, contact: contact);
      }).toList();

      if (kDebugMode) {
        print(
          '✅ [CONTACTS] Created ${suggestions.length} relative suggestions',
        );
      }

      return suggestions;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [CONTACTS] Batch import error: $e');
      }
      return [];
    }
  }

  /// Get family-related contacts only
  Future<List<Contact>> getFamilyContacts() async {
    try {
      final allContacts = await getAllContacts();

      // Filter for potential family members based on name keywords
      final familyContacts = allContacts.where((contact) {
        final relationship = detectRelationship(contact.displayName);
        return relationship != RelationshipType.other;
      }).toList();

      if (kDebugMode) {
        print(
          '👨‍👩‍👧‍👦 [CONTACTS] Found ${familyContacts.length} potential family members',
        );
      }

      return familyContacts;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [CONTACTS] Family filter error: $e');
      }
      return [];
    }
  }
}
