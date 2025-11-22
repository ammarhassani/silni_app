import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign up with email and password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // Create user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(fullName);

      // Create user document in Firestore
      await _createUserDocument(
        uid: credential.user!.uid,
        email: email,
        fullName: fullName,
      );

      if (kDebugMode) {
        print('✅ User created successfully: ${credential.user?.uid}');
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('❌ Sign up error: ${e.code} - ${e.message}');
      }
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login
      await _updateLastLogin(credential.user!.uid);

      if (kDebugMode) {
        print('✅ User signed in: ${credential.user?.uid}');
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('❌ Sign in error: ${e.code} - ${e.message}');
      }
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      if (kDebugMode) {
        print('✅ User signed out');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Sign out error: $e');
      }
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (kDebugMode) {
        print('✅ Password reset email sent to: $email');
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('❌ Password reset error: ${e.code} - ${e.message}');
      }
      rethrow;
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user document from Firestore
        await _firestore.collection('users').doc(user.uid).delete();

        // Delete Firebase Auth account
        await user.delete();

        if (kDebugMode) {
          print('✅ Account deleted successfully');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Delete account error: $e');
      }
      rethrow;
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument({
    required String uid,
    required String email,
    required String fullName,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'id': uid,
      'email': email,
      'fullName': fullName,
      'phoneNumber': null,
      'profilePictureUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'emailVerified': false,
      'subscriptionStatus': 'free',
      'language': 'ar',
      'notificationsEnabled': true,
      'reminderTime': '09:00',
      'theme': 'light',
      'totalInteractions': 0,
      'currentStreak': 0,
      'longestStreak': 0,
      'points': 0,
      'level': 1,
      'badges': [],
      'dataExportRequested': false,
      'accountDeletionRequested': false,
    });
  }

  // Update last login timestamp
  Future<void> _updateLastLogin(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }

  // Get auth error message
  static String getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'لا يوجد حساب بهذا البريد الإلكتروني';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً';
      case 'operation-not-allowed':
        return 'هذه العملية غير مسموحة';
      case 'user-disabled':
        return 'هذا الحساب معطل';
      case 'too-many-requests':
        return 'تم إجراء الكثير من المحاولات. يرجى المحاولة لاحقاً';
      default:
        return 'حدث خطأ ما. يرجى المحاولة مرة أخرى';
    }
  }
}
