/**
 * SPLASH SCREEN
 *
 * Initial loading screen shown while:
 * - Checking authentication status
 * - Loading user data
 * - Checking onboarding status
 */

import React, { useEffect } from 'react';
import { View, StyleSheet, Image, ActivityIndicator } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useAuthStore } from '@/store/authStore';
import { authService } from '@/services';
import { Colors } from '@/constants/colors';

export default function SplashScreen() {
  const navigation = useNavigation<any>();
  const { setHasCompletedOnboarding, checkOnboardingStatus } = useAuthStore();

  useEffect(() => {
    initializeApp();
  }, []);

  const initializeApp = async () => {
    try {
      console.log('[SplashScreen] Starting initialization...');

      // Check onboarding status
      console.log('[SplashScreen] Checking onboarding status...');
      await checkOnboardingStatus();
      const hasCompletedOnboarding = useAuthStore.getState().hasCompletedOnboarding;
      console.log('[SplashScreen] Onboarding completed:', hasCompletedOnboarding);

      // Check if user is already signed in
      console.log('[SplashScreen] Checking current user...');
      const currentUser = authService.getCurrentUser();
      console.log('[SplashScreen] Current user:', currentUser ? 'Logged in' : 'Not logged in');

      // Wait minimum 2 seconds for splash screen
      await new Promise((resolve) => setTimeout(resolve, 2000));

      // Navigate based on auth status
      if (currentUser) {
        // User is signed in - go to main app
        console.log('[SplashScreen] Navigating to MainTabs');
        navigation.replace('MainTabs');
      } else if (hasCompletedOnboarding) {
        // User has seen onboarding - go to login
        console.log('[SplashScreen] Navigating to Login');
        navigation.replace('Login');
      } else {
        // First time user - show onboarding
        console.log('[SplashScreen] Navigating to Onboarding');
        navigation.replace('Onboarding');
      }
    } catch (error) {
      console.error('[SplashScreen] Error during initialization:', error);
      // On error, show onboarding as fallback
      console.log('[SplashScreen] Navigating to Onboarding (fallback)');
      navigation.replace('Onboarding');
    }
  };

  return (
    <View style={styles.container}>
      {/* App Logo/Icon */}
      <View style={styles.logoContainer}>
        <View style={styles.logoPlaceholder}>
          {/* TODO: Replace with actual app logo */}
          <View style={styles.logoCircle} />
        </View>
      </View>

      {/* App Name */}
      <View style={styles.titleContainer}>
        {/* TODO: Replace with app logo image or custom text */}
      </View>

      {/* Loading Indicator */}
      <ActivityIndicator
        size="large"
        color={Colors.primary.main}
        style={styles.loader}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background.light,
    alignItems: 'center',
    justifyContent: 'center',
  },
  logoContainer: {
    marginBottom: 32,
  },
  logoPlaceholder: {
    width: 120,
    height: 120,
    alignItems: 'center',
    justifyContent: 'center',
  },
  logoCircle: {
    width: 100,
    height: 100,
    borderRadius: 50,
    backgroundColor: Colors.primary.main,
  },
  titleContainer: {
    marginBottom: 48,
  },
  loader: {
    marginTop: 24,
  },
});
