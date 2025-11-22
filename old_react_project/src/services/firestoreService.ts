/**
 * FIRESTORE SERVICE
 *
 * Handles all Firestore database operations for:
 * - Users
 * - Relatives
 * - Interactions
 * - Reminders
 * - Achievements
 * - Statistics
 */

import {
  collection,
  doc,
  getDoc,
  getDocs,
  setDoc,
  addDoc,
  updateDoc,
  deleteDoc,
  query,
  where,
  orderBy,
  limit,
  startAfter,
  Timestamp,
  serverTimestamp,
  DocumentSnapshot,
  QueryConstraint,
  writeBatch,
  increment,
} from 'firebase/firestore';
import { db } from '@/config/firebase';
import {
  User,
  Relative,
  Interaction,
  Reminder,
  Achievement,
  Statistics,
} from '@/types';

export interface FirestoreResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
}

export interface PaginatedResponse<T> {
  success: boolean;
  data: T[];
  lastDoc?: DocumentSnapshot;
  hasMore: boolean;
  error?: string;
}

class FirestoreService {
  // ==================== USERS ====================

  /**
   * Get user by ID
   */
  async getUser(userId: string): Promise<FirestoreResponse<User>> {
    try {
      const userDoc = await getDoc(doc(db, 'users', userId));

      if (!userDoc.exists()) {
        return { success: false, error: 'User not found' };
      }

      const userData = userDoc.data() as User;
      const user: User = {
        ...userData,
        id: userDoc.id,
        createdAt:
          userData.createdAt instanceof Timestamp
            ? userData.createdAt.toDate()
            : new Date(userData.createdAt),
        lastLoginAt:
          userData.lastLoginAt instanceof Timestamp
            ? userData.lastLoginAt.toDate()
            : new Date(userData.lastLoginAt),
      };

      return { success: true, data: user };
    } catch (error: any) {
      console.error('❌ Get user error:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Update user
   */
  async updateUser(
    userId: string,
    updates: Partial<User>
  ): Promise<FirestoreResponse> {
    try {
      await updateDoc(doc(db, 'users', userId), {
        ...updates,
        updatedAt: serverTimestamp(),
      });

      return { success: true };
    } catch (error: any) {
      console.error('❌ Update user error:', error);
      return { success: false, error: error.message };
    }
  }

  // ==================== RELATIVES ====================

  /**
   * Get all relatives for a user
   */
  async getRelatives(userId: string): Promise<FirestoreResponse<Relative[]>> {
    try {
      const q = query(
        collection(db, 'relatives'),
        where('userId', '==', userId),
        where('isArchived', '==', false),
        orderBy('priority', 'desc'),
        orderBy('fullName', 'asc')
      );

      const snapshot = await getDocs(q);
      const relatives = snapshot.docs.map((doc) => {
        const data = doc.data() as Relative;
        return {
          ...data,
          id: doc.id,
          dateOfBirth: data.dateOfBirth
            ? data.dateOfBirth instanceof Timestamp
              ? data.dateOfBirth.toDate()
              : new Date(data.dateOfBirth)
            : null,
          lastContactDate:
            data.lastContactDate instanceof Timestamp
              ? data.lastContactDate.toDate()
              : data.lastContactDate
                ? new Date(data.lastContactDate)
                : null,
          createdAt:
            data.createdAt instanceof Timestamp
              ? data.createdAt.toDate()
              : new Date(data.createdAt),
        } as Relative;
      });

      return { success: true, data: relatives };
    } catch (error: any) {
      console.error('❌ Get relatives error:', error);
      return { success: false, error: error.message, data: [] };
    }
  }

  /**
   * Get a single relative by ID
   */
  async getRelative(relativeId: string): Promise<FirestoreResponse<Relative>> {
    try {
      const relativeDoc = await getDoc(doc(db, 'relatives', relativeId));

      if (!relativeDoc.exists()) {
        return { success: false, error: 'Relative not found' };
      }

      const data = relativeDoc.data() as Relative;
      const relative: Relative = {
        ...data,
        id: relativeDoc.id,
        dateOfBirth: data.dateOfBirth
          ? data.dateOfBirth instanceof Timestamp
            ? data.dateOfBirth.toDate()
            : new Date(data.dateOfBirth)
          : null,
        lastContactDate:
          data.lastContactDate instanceof Timestamp
            ? data.lastContactDate.toDate()
            : data.lastContactDate
              ? new Date(data.lastContactDate)
              : null,
        createdAt:
          data.createdAt instanceof Timestamp
            ? data.createdAt.toDate()
            : new Date(data.createdAt),
      };

      return { success: true, data: relative };
    } catch (error: any) {
      console.error('❌ Get relative error:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Add a new relative
   */
  async addRelative(
    relative: Omit<Relative, 'id' | 'createdAt'>
  ): Promise<FirestoreResponse<string>> {
    try {
      const docRef = await addDoc(collection(db, 'relatives'), {
        ...relative,
        createdAt: serverTimestamp(),
      });

      console.log('✅ Relative added:', docRef.id);
      return { success: true, data: docRef.id };
    } catch (error: any) {
      console.error('❌ Add relative error:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Update a relative
   */
  async updateRelative(
    relativeId: string,
    updates: Partial<Relative>
  ): Promise<FirestoreResponse> {
    try {
      await updateDoc(doc(db, 'relatives', relativeId), {
        ...updates,
        updatedAt: serverTimestamp(),
      });

      return { success: true };
    } catch (error: any) {
      console.error('❌ Update relative error:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Delete a relative (soft delete)
   */
  async deleteRelative(relativeId: string): Promise<FirestoreResponse> {
    try {
      await updateDoc(doc(db, 'relatives', relativeId), {
        isArchived: true,
        archivedAt: serverTimestamp(),
      });

      return { success: true };
    } catch (error: any) {
      console.error('❌ Delete relative error:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Permanently delete a relative
   */
  async permanentlyDeleteRelative(
    relativeId: string
  ): Promise<FirestoreResponse> {
    try {
      await deleteDoc(doc(db, 'relatives', relativeId));
      return { success: true };
    } catch (error: any) {
      console.error('❌ Permanently delete relative error:', error);
      return { success: false, error: error.message };
    }
  }

  // ==================== INTERACTIONS ====================

  /**
   * Get interactions for a relative
   */
  async getInteractions(
    relativeId: string,
    limitCount: number = 50
  ): Promise<FirestoreResponse<Interaction[]>> {
    try {
      const q = query(
        collection(db, 'interactions'),
        where('relativeId', '==', relativeId),
        orderBy('date', 'desc'),
        limit(limitCount)
      );

      const snapshot = await getDocs(q);
      const interactions = snapshot.docs.map((doc) => {
        const data = doc.data() as Interaction;
        return {
          ...data,
          id: doc.id,
          date:
            data.date instanceof Timestamp
              ? data.date.toDate()
              : new Date(data.date),
          createdAt:
            data.createdAt instanceof Timestamp
              ? data.createdAt.toDate()
              : new Date(data.createdAt),
        } as Interaction;
      });

      return { success: true, data: interactions };
    } catch (error: any) {
      console.error('❌ Get interactions error:', error);
      return { success: false, error: error.message, data: [] };
    }
  }

  /**
   * Add a new interaction
   */
  async addInteraction(
    interaction: Omit<Interaction, 'id' | 'createdAt'>
  ): Promise<FirestoreResponse<string>> {
    try {
      // Add interaction
      const docRef = await addDoc(collection(db, 'interactions'), {
        ...interaction,
        createdAt: serverTimestamp(),
      });

      // Update relative's last contact date and interaction count
      await updateDoc(doc(db, 'relatives', interaction.relativeId), {
        lastContactDate: interaction.date,
        interactionCount: increment(1),
        updatedAt: serverTimestamp(),
      });

      // Update user's total interactions and streak
      await this.updateUserInteractionStats(interaction.userId);

      console.log('✅ Interaction added:', docRef.id);
      return { success: true, data: docRef.id };
    } catch (error: any) {
      console.error('❌ Add interaction error:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Update an interaction
   */
  async updateInteraction(
    interactionId: string,
    updates: Partial<Interaction>
  ): Promise<FirestoreResponse> {
    try {
      await updateDoc(doc(db, 'interactions', interactionId), {
        ...updates,
        updatedAt: serverTimestamp(),
      });

      return { success: true };
    } catch (error: any) {
      console.error('❌ Update interaction error:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Delete an interaction
   */
  async deleteInteraction(
    interactionId: string,
    userId: string,
    relativeId: string
  ): Promise<FirestoreResponse> {
    try {
      await deleteDoc(doc(db, 'interactions', interactionId));

      // Decrement relative's interaction count
      await updateDoc(doc(db, 'relatives', relativeId), {
        interactionCount: increment(-1),
        updatedAt: serverTimestamp(),
      });

      // Update user's total interactions
      await updateDoc(doc(db, 'users', userId), {
        totalInteractions: increment(-1),
        updatedAt: serverTimestamp(),
      });

      return { success: true };
    } catch (error: any) {
      console.error('❌ Delete interaction error:', error);
      return { success: false, error: error.message };
    }
  }

  // ==================== REMINDERS ====================

  /**
   * Get reminders for a user
   */
  async getReminders(userId: string): Promise<FirestoreResponse<Reminder[]>> {
    try {
      const q = query(
        collection(db, 'reminders'),
        where('userId', '==', userId),
        where('isActive', '==', true),
        orderBy('nextReminderDate', 'asc')
      );

      const snapshot = await getDocs(q);
      const reminders = snapshot.docs.map((doc) => {
        const data = doc.data() as Reminder;
        return {
          ...data,
          id: doc.id,
          nextReminderDate:
            data.nextReminderDate instanceof Timestamp
              ? data.nextReminderDate.toDate()
              : new Date(data.nextReminderDate),
          lastReminderDate: data.lastReminderDate
            ? data.lastReminderDate instanceof Timestamp
              ? data.lastReminderDate.toDate()
              : new Date(data.lastReminderDate)
            : null,
          createdAt:
            data.createdAt instanceof Timestamp
              ? data.createdAt.toDate()
              : new Date(data.createdAt),
        } as Reminder;
      });

      return { success: true, data: reminders };
    } catch (error: any) {
      console.error('❌ Get reminders error:', error);
      return { success: false, error: error.message, data: [] };
    }
  }

  /**
   * Add a new reminder
   */
  async addReminder(
    reminder: Omit<Reminder, 'id' | 'createdAt'>
  ): Promise<FirestoreResponse<string>> {
    try {
      const docRef = await addDoc(collection(db, 'reminders'), {
        ...reminder,
        createdAt: serverTimestamp(),
      });

      console.log('✅ Reminder added:', docRef.id);
      return { success: true, data: docRef.id };
    } catch (error: any) {
      console.error('❌ Add reminder error:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Update a reminder
   */
  async updateReminder(
    reminderId: string,
    updates: Partial<Reminder>
  ): Promise<FirestoreResponse> {
    try {
      await updateDoc(doc(db, 'reminders', reminderId), {
        ...updates,
        updatedAt: serverTimestamp(),
      });

      return { success: true };
    } catch (error: any) {
      console.error('❌ Update reminder error:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Delete a reminder
   */
  async deleteReminder(reminderId: string): Promise<FirestoreResponse> {
    try {
      await deleteDoc(doc(db, 'reminders', reminderId));
      return { success: true };
    } catch (error: any) {
      console.error('❌ Delete reminder error:', error);
      return { success: false, error: error.message };
    }
  }

  // ==================== STATISTICS ====================

  /**
   * Update user interaction statistics (streak, total interactions)
   */
  private async updateUserInteractionStats(userId: string): Promise<void> {
    try {
      const userDoc = await getDoc(doc(db, 'users', userId));
      if (!userDoc.exists()) return;

      const userData = userDoc.data() as User;
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      const lastInteractionDate = userData.lastInteractionDate
        ? userData.lastInteractionDate instanceof Timestamp
          ? userData.lastInteractionDate.toDate()
          : new Date(userData.lastInteractionDate)
        : null;

      let currentStreak = userData.currentStreak || 0;
      let longestStreak = userData.longestStreak || 0;

      if (lastInteractionDate) {
        const lastDate = new Date(lastInteractionDate);
        lastDate.setHours(0, 0, 0, 0);

        const daysDifference = Math.floor(
          (today.getTime() - lastDate.getTime()) / (1000 * 60 * 60 * 24)
        );

        if (daysDifference === 0) {
          // Same day - no change to streak
        } else if (daysDifference === 1) {
          // Next day - increment streak
          currentStreak++;
        } else {
          // Streak broken - reset to 1
          currentStreak = 1;
        }
      } else {
        // First interaction
        currentStreak = 1;
      }

      // Update longest streak
      if (currentStreak > longestStreak) {
        longestStreak = currentStreak;
      }

      await updateDoc(doc(db, 'users', userId), {
        totalInteractions: increment(1),
        currentStreak,
        longestStreak,
        lastInteractionDate: today,
        updatedAt: serverTimestamp(),
      });
    } catch (error) {
      console.error('❌ Update user stats error:', error);
    }
  }

  // ==================== BATCH OPERATIONS ====================

  /**
   * Batch update multiple documents
   */
  async batchUpdate(
    updates: Array<{ collection: string; id: string; data: any }>
  ): Promise<FirestoreResponse> {
    try {
      const batch = writeBatch(db);

      updates.forEach(({ collection: collectionName, id, data }) => {
        const docRef = doc(db, collectionName, id);
        batch.update(docRef, {
          ...data,
          updatedAt: serverTimestamp(),
        });
      });

      await batch.commit();
      return { success: true };
    } catch (error: any) {
      console.error('❌ Batch update error:', error);
      return { success: false, error: error.message };
    }
  }
}

// Export singleton instance
export const firestoreService = new FirestoreService();

// Export convenience functions
export const getUser = (userId: string) => firestoreService.getUser(userId);
export const updateUser = (userId: string, updates: Partial<User>) =>
  firestoreService.updateUser(userId, updates);

export const getRelatives = (userId: string) =>
  firestoreService.getRelatives(userId);
export const getRelative = (relativeId: string) =>
  firestoreService.getRelative(relativeId);
export const addRelative = (relative: Omit<Relative, 'id' | 'createdAt'>) =>
  firestoreService.addRelative(relative);
export const updateRelative = (
  relativeId: string,
  updates: Partial<Relative>
) => firestoreService.updateRelative(relativeId, updates);
export const deleteRelative = (relativeId: string) =>
  firestoreService.deleteRelative(relativeId);

export const getInteractions = (relativeId: string, limitCount?: number) =>
  firestoreService.getInteractions(relativeId, limitCount);
export const addInteraction = (
  interaction: Omit<Interaction, 'id' | 'createdAt'>
) => firestoreService.addInteraction(interaction);
export const updateInteraction = (
  interactionId: string,
  updates: Partial<Interaction>
) => firestoreService.updateInteraction(interactionId, updates);
export const deleteInteraction = (
  interactionId: string,
  userId: string,
  relativeId: string
) => firestoreService.deleteInteraction(interactionId, userId, relativeId);

export const getReminders = (userId: string) =>
  firestoreService.getReminders(userId);
export const addReminder = (reminder: Omit<Reminder, 'id' | 'createdAt'>) =>
  firestoreService.addReminder(reminder);
export const updateReminder = (reminderId: string, updates: Partial<Reminder>) =>
  firestoreService.updateReminder(reminderId, updates);
export const deleteReminder = (reminderId: string) =>
  firestoreService.deleteReminder(reminderId);
