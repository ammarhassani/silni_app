/**
 * SILNI APP
 *
 * Islamic app for managing family relationships (صلة الرحم)
 */

// Import reanimated first to initialize it properly
import 'react-native-reanimated';

import React, { useEffect } from 'react';
import { StatusBar } from 'expo-status-bar';
import { LogBox } from 'react-native';
import AppNavigator from './src/navigation/AppNavigator';
import { useAuthStore } from './src/store/authStore';

// Ignore specific warnings
LogBox.ignoreLogs([
  'Non-serializable values were found in the navigation state',
  // Firebase Analytics warnings (not needed in React Native)
  '@firebase/analytics',
  'Analytics: Firebase Analytics is not supported',
  'Analytics: IndexedDB unavailable',
  // Reanimated warnings (fixed by proper import order)
  'react-native-reanimated is not installed',
]);

export default function App() {
  const { checkOnboardingStatus } = useAuthStore();

  useEffect(() => {
    console.log('[App] Mounted, initializing...');
    // Initialize app
    checkOnboardingStatus();
  }, []);

  console.log('[App] Rendering...');

  return (
    <>
      <AppNavigator />
      <StatusBar style="auto" />
    </>
  );
}
