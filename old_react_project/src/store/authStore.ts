/**
 * AUTHENTICATION STORE (Zustand)
 *
 * Manages global authentication state:
 * - Current user
 * - Loading states
 * - Authentication actions
 */

import { create } from 'zustand';
import { User } from '@/types';
import { authService, firestoreService } from '@/services';
import AsyncStorage from '@react-native-async-storage/async-storage';

interface AuthState {
  // State
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  hasCompletedOnboarding: boolean;
  error: string | null;

  // Actions
  signUp: (email: string, password: string, fullName: string) => Promise<boolean>;
  signIn: (email: string, password: string) => Promise<boolean>;
  signOut: () => Promise<void>;
  updateUser: (updates: Partial<User>) => Promise<boolean>;
  refreshUser: () => Promise<void>;
  setHasCompletedOnboarding: (value: boolean) => Promise<void>;
  checkOnboardingStatus: () => Promise<void>;
  clearError: () => void;
}

export const useAuthStore = create<AuthState>((set, get) => ({
  // Initial State
  user: null,
  isAuthenticated: false,
  isLoading: false,
  hasCompletedOnboarding: false,
  error: null,

  // Sign Up
  signUp: async (email: string, password: string, fullName: string) => {
    set({ isLoading: true, error: null });

    try {
      const response = await authService.signUp({
        email,
        password,
        fullName,
      });

      if (response.success && response.user) {
        set({
          user: response.user,
          isAuthenticated: true,
          isLoading: false,
          error: null,
        });
        return true;
      } else {
        set({
          isLoading: false,
          error: response.error || 'فشل إنشاء الحساب',
        });
        return false;
      }
    } catch (error: any) {
      set({
        isLoading: false,
        error: error.message || 'حدث خطأ غير متوقع',
      });
      return false;
    }
  },

  // Sign In
  signIn: async (email: string, password: string) => {
    set({ isLoading: true, error: null });

    try {
      const response = await authService.signIn({ email, password });

      if (response.success && response.user) {
        set({
          user: response.user,
          isAuthenticated: true,
          isLoading: false,
          error: null,
        });
        return true;
      } else {
        set({
          isLoading: false,
          error: response.error || 'فشل تسجيل الدخول',
        });
        return false;
      }
    } catch (error: any) {
      set({
        isLoading: false,
        error: error.message || 'حدث خطأ غير متوقع',
      });
      return false;
    }
  },

  // Sign Out
  signOut: async () => {
    set({ isLoading: true });

    try {
      await authService.signOut();
      set({
        user: null,
        isAuthenticated: false,
        isLoading: false,
        error: null,
      });
    } catch (error: any) {
      set({
        isLoading: false,
        error: error.message || 'فشل تسجيل الخروج',
      });
    }
  },

  // Update User
  updateUser: async (updates: Partial<User>) => {
    const currentUser = get().user;
    if (!currentUser) return false;

    set({ isLoading: true, error: null });

    try {
      const response = await authService.updateProfile(currentUser.id, updates);

      if (response.success) {
        // Refresh user data from Firestore
        const userResponse = await firestoreService.getUser(currentUser.id);
        if (userResponse.success && userResponse.data) {
          set({
            user: userResponse.data,
            isLoading: false,
            error: null,
          });
          return true;
        }
      }

      set({
        isLoading: false,
        error: 'فشل تحديث الملف الشخصي',
      });
      return false;
    } catch (error: any) {
      set({
        isLoading: false,
        error: error.message || 'حدث خطأ غير متوقع',
      });
      return false;
    }
  },

  // Refresh User Data
  refreshUser: async () => {
    const currentUser = get().user;
    if (!currentUser) return;

    try {
      const response = await firestoreService.getUser(currentUser.id);
      if (response.success && response.data) {
        set({ user: response.data });
      }
    } catch (error) {
      console.error('Failed to refresh user:', error);
    }
  },

  // Set Onboarding Completed
  setHasCompletedOnboarding: async (value: boolean) => {
    try {
      await AsyncStorage.setItem('hasCompletedOnboarding', JSON.stringify(value));
      set({ hasCompletedOnboarding: value });
    } catch (error) {
      console.error('Failed to save onboarding status:', error);
    }
  },

  // Check Onboarding Status
  checkOnboardingStatus: async () => {
    try {
      const value = await AsyncStorage.getItem('hasCompletedOnboarding');
      set({ hasCompletedOnboarding: value === 'true' });
    } catch (error) {
      console.error('Failed to check onboarding status:', error);
    }
  },

  // Clear Error
  clearError: () => set({ error: null }),
}));
