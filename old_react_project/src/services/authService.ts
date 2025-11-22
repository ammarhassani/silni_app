/**
 * AUTHENTICATION SERVICE
 *
 * Handles all Firebase Authentication operations:
 * - Email/Password sign up and sign in
 * - Phone authentication
 * - Password reset
 * - User session management
 * - Profile updates
 */

import {
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  signOut as firebaseSignOut,
  sendPasswordResetEmail,
  updateProfile,
  updateEmail,
  updatePassword,
  deleteUser,
  sendEmailVerification,
  User as FirebaseUser,
  AuthError,
  PhoneAuthProvider,
  signInWithCredential,
  RecaptchaVerifier,
} from 'firebase/auth';
import { auth, db } from '@/config/firebase';
import {
  doc,
  setDoc,
  getDoc,
  updateDoc,
  serverTimestamp,
  Timestamp,
} from 'firebase/firestore';
import { User } from '@/types';

export interface AuthResponse {
  success: boolean;
  user?: User;
  error?: string;
}

export interface SignUpData {
  email: string;
  password: string;
  fullName: string;
  phoneNumber?: string;
}

export interface SignInData {
  email: string;
  password: string;
}

class AuthService {
  /**
   * Sign up a new user with email and password
   */
  async signUp(data: SignUpData): Promise<AuthResponse> {
    try {
      console.log('🔐 [SignUp] Starting signup process...');
      console.log('🔐 [SignUp] Email:', data.email);

      // Create Firebase Auth user
      console.log('🔐 [SignUp] Creating Firebase Auth user...');
      const userCredential = await createUserWithEmailAndPassword(
        auth,
        data.email,
        data.password
      );

      const firebaseUser = userCredential.user;
      console.log('✅ [SignUp] Firebase Auth user created:', firebaseUser.uid);

      // Update Firebase Auth profile
      console.log('🔐 [SignUp] Updating profile...');
      await updateProfile(firebaseUser, {
        displayName: data.fullName,
      });
      console.log('✅ [SignUp] Profile updated');

      // Send email verification (non-blocking, might fail on web)
      try {
        console.log('📧 [SignUp] Sending verification email...');
        await sendEmailVerification(firebaseUser);
        console.log('✅ [SignUp] Verification email sent');
      } catch (emailError) {
        console.warn('⚠️ [SignUp] Could not send verification email:', emailError);
        // Continue anyway - email verification is optional for development
      }

      // Create user document in Firestore
      console.log('🔐 [SignUp] Creating Firestore document...');
      const newUser: User = {
        id: firebaseUser.uid,
        email: data.email,
        fullName: data.fullName,
        phoneNumber: data.phoneNumber || null,
        profilePictureUrl: null,
        createdAt: new Date(),
        lastLoginAt: new Date(),
        emailVerified: false,

        // Subscription
        subscriptionStatus: 'free',
        subscriptionStartDate: null,
        subscriptionEndDate: null,

        // Settings
        language: 'ar',
        notificationsEnabled: true,
        reminderTime: '09:00',
        theme: 'light',

        // Statistics
        totalInteractions: 0,
        currentStreak: 0,
        longestStreak: 0,
        lastInteractionDate: null,

        // Gamification
        points: 0,
        level: 1,
        badges: [],

        // Privacy
        dataExportRequested: false,
        accountDeletionRequested: false,
      };

      await setDoc(doc(db, 'users', firebaseUser.uid), {
        ...newUser,
        createdAt: serverTimestamp(),
        lastLoginAt: serverTimestamp(),
      });

      console.log('✅ [SignUp] Firestore document created');
      console.log('✅ [SignUp] User account created successfully');

      return {
        success: true,
        user: newUser,
      };
    } catch (error: any) {
      console.error('❌ [SignUp] Sign up error:', error);
      return {
        success: false,
        error: this.getErrorMessage(error),
      };
    }
  }

  /**
   * Sign in an existing user with email and password
   */
  async signIn(data: SignInData): Promise<AuthResponse> {
    try {
      console.log('🔐 [SignIn] Starting signin process...');
      console.log('🔐 [SignIn] Email:', data.email);

      // Sign in with Firebase Auth
      console.log('🔐 [SignIn] Authenticating with Firebase...');
      const userCredential = await signInWithEmailAndPassword(
        auth,
        data.email,
        data.password
      );

      const firebaseUser = userCredential.user;
      console.log('✅ [SignIn] Authentication successful:', firebaseUser.uid);

      // Update last login time
      console.log('🔐 [SignIn] Updating last login time...');
      await updateDoc(doc(db, 'users', firebaseUser.uid), {
        lastLoginAt: serverTimestamp(),
      });
      console.log('✅ [SignIn] Last login time updated');

      // Fetch user document
      console.log('🔐 [SignIn] Fetching user document...');
      const userDoc = await getDoc(doc(db, 'users', firebaseUser.uid));

      if (!userDoc.exists()) {
        console.error('❌ [SignIn] User document not found in Firestore');
        throw new Error('User document not found');
      }

      console.log('✅ [SignIn] User document fetched');

      const userData = userDoc.data() as User;
      const user: User = {
        ...userData,
        id: firebaseUser.uid,
        emailVerified: firebaseUser.emailVerified,
        createdAt:
          userData.createdAt instanceof Timestamp
            ? userData.createdAt.toDate()
            : new Date(userData.createdAt),
        lastLoginAt: new Date(),
      };

      console.log('✅ [SignIn] Sign in successful');

      return {
        success: true,
        user,
      };
    } catch (error: any) {
      console.error('❌ [SignIn] Sign in error:', error);
      return {
        success: false,
        error: this.getErrorMessage(error),
      };
    }
  }

  /**
   * Sign out the current user
   */
  async signOut(): Promise<AuthResponse> {
    try {
      console.log('🔐 Signing out user...');
      await firebaseSignOut(auth);
      console.log('✅ Sign out successful');

      return { success: true };
    } catch (error: any) {
      console.error('❌ Sign out error:', error);
      return {
        success: false,
        error: this.getErrorMessage(error),
      };
    }
  }

  /**
   * Send password reset email
   */
  async resetPassword(email: string): Promise<AuthResponse> {
    try {
      console.log('📧 Sending password reset email...');
      await sendPasswordResetEmail(auth, email);
      console.log('✅ Password reset email sent');

      return { success: true };
    } catch (error: any) {
      console.error('❌ Password reset error:', error);
      return {
        success: false,
        error: this.getErrorMessage(error),
      };
    }
  }

  /**
   * Update user profile
   */
  async updateProfile(
    userId: string,
    updates: Partial<User>
  ): Promise<AuthResponse> {
    try {
      console.log('👤 Updating user profile...');

      // Update Firestore document
      await updateDoc(doc(db, 'users', userId), {
        ...updates,
        updatedAt: serverTimestamp(),
      });

      // Update Firebase Auth profile if displayName changed
      if (updates.fullName && auth.currentUser) {
        await updateProfile(auth.currentUser, {
          displayName: updates.fullName,
        });
      }

      console.log('✅ Profile updated successfully');

      return { success: true };
    } catch (error: any) {
      console.error('❌ Profile update error:', error);
      return {
        success: false,
        error: this.getErrorMessage(error),
      };
    }
  }

  /**
   * Update user email
   */
  async updateUserEmail(newEmail: string): Promise<AuthResponse> {
    try {
      if (!auth.currentUser) {
        throw new Error('No user signed in');
      }

      console.log('📧 Updating email address...');
      await updateEmail(auth.currentUser, newEmail);

      // Update Firestore document
      await updateDoc(doc(db, 'users', auth.currentUser.uid), {
        email: newEmail,
        emailVerified: false,
        updatedAt: serverTimestamp(),
      });

      // Send verification email
      await sendEmailVerification(auth.currentUser);

      console.log('✅ Email updated successfully');

      return { success: true };
    } catch (error: any) {
      console.error('❌ Email update error:', error);
      return {
        success: false,
        error: this.getErrorMessage(error),
      };
    }
  }

  /**
   * Update user password
   */
  async updateUserPassword(newPassword: string): Promise<AuthResponse> {
    try {
      if (!auth.currentUser) {
        throw new Error('No user signed in');
      }

      console.log('🔐 Updating password...');
      await updatePassword(auth.currentUser, newPassword);
      console.log('✅ Password updated successfully');

      return { success: true };
    } catch (error: any) {
      console.error('❌ Password update error:', error);
      return {
        success: false,
        error: this.getErrorMessage(error),
      };
    }
  }

  /**
   * Resend email verification
   */
  async resendVerificationEmail(): Promise<AuthResponse> {
    try {
      if (!auth.currentUser) {
        throw new Error('No user signed in');
      }

      console.log('📧 Resending verification email...');
      await sendEmailVerification(auth.currentUser);
      console.log('✅ Verification email sent');

      return { success: true };
    } catch (error: any) {
      console.error('❌ Verification email error:', error);
      return {
        success: false,
        error: this.getErrorMessage(error),
      };
    }
  }

  /**
   * Delete user account
   */
  async deleteAccount(userId: string): Promise<AuthResponse> {
    try {
      if (!auth.currentUser) {
        throw new Error('No user signed in');
      }

      console.log('🗑️ Deleting user account...');

      // Delete Firestore document
      // Note: We'll keep the document and mark it as deleted for GDPR compliance
      await updateDoc(doc(db, 'users', userId), {
        accountDeletionRequested: true,
        accountDeletionDate: serverTimestamp(),
      });

      // Delete Firebase Auth user
      await deleteUser(auth.currentUser);

      console.log('✅ Account deleted successfully');

      return { success: true };
    } catch (error: any) {
      console.error('❌ Account deletion error:', error);
      return {
        success: false,
        error: this.getErrorMessage(error),
      };
    }
  }

  /**
   * Get current user
   */
  getCurrentUser(): FirebaseUser | null {
    return auth.currentUser;
  }

  /**
   * Get current user ID
   */
  getCurrentUserId(): string | null {
    return auth.currentUser?.uid || null;
  }

  /**
   * Check if user is signed in
   */
  isSignedIn(): boolean {
    return auth.currentUser !== null;
  }

  /**
   * Listen to auth state changes
   */
  onAuthStateChanged(callback: (user: FirebaseUser | null) => void) {
    return auth.onAuthStateChanged(callback);
  }

  /**
   * Convert Firebase error to user-friendly message
   */
  private getErrorMessage(error: AuthError | any): string {
    const errorCode = error.code || '';

    switch (errorCode) {
      case 'auth/email-already-in-use':
        return 'هذا البريد الإلكتروني مستخدم بالفعل';
      case 'auth/invalid-email':
        return 'البريد الإلكتروني غير صالح';
      case 'auth/operation-not-allowed':
        return 'العملية غير مسموح بها';
      case 'auth/weak-password':
        return 'كلمة المرور ضعيفة جداً (يجب أن تكون 6 أحرف على الأقل)';
      case 'auth/user-disabled':
        return 'هذا الحساب معطل';
      case 'auth/user-not-found':
        return 'لم يتم العثور على مستخدم بهذا البريد الإلكتروني';
      case 'auth/wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'auth/too-many-requests':
        return 'تم تجاوز عدد المحاولات. يرجى المحاولة لاحقاً';
      case 'auth/network-request-failed':
        return 'خطأ في الاتصال بالإنترنت';
      case 'auth/requires-recent-login':
        return 'يرجى تسجيل الدخول مرة أخرى لإتمام هذه العملية';
      default:
        return error.message || 'حدث خطأ غير متوقع';
    }
  }
}

// Export singleton instance
export const authService = new AuthService();

// Export convenience functions
export const signUp = (data: SignUpData) => authService.signUp(data);
export const signIn = (data: SignInData) => authService.signIn(data);
export const signOut = () => authService.signOut();
export const resetPassword = (email: string) =>
  authService.resetPassword(email);
export const getCurrentUser = () => authService.getCurrentUser();
export const getCurrentUserId = () => authService.getCurrentUserId();
export const isSignedIn = () => authService.isSignedIn();
