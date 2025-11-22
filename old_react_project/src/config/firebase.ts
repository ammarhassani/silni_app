/**
 * FIREBASE CONFIGURATION
 *
 * This file initializes Firebase services for the Silni app.
 * Configuration values are loaded from environment variables for security.
 */

import { initializeApp, getApps, FirebaseApp } from 'firebase/app';
import {
  initializeAuth,
  getReactNativePersistence,
  browserLocalPersistence,
  Auth,
} from 'firebase/auth';
import { getFirestore, Firestore } from 'firebase/firestore';
import { getStorage, FirebaseStorage } from 'firebase/storage';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Platform } from 'react-native';

// Firebase configuration from environment variables
const firebaseConfig = {
  apiKey: process.env.FIREBASE_API_KEY || 'AIzaSyBuS1snryQ_DWxhcEUtj0Lu_HDrdIvASDY',
  authDomain:
    process.env.FIREBASE_AUTH_DOMAIN || 'silni-31811.firebaseapp.com',
  projectId: process.env.FIREBASE_PROJECT_ID || 'silni-31811',
  storageBucket:
    process.env.FIREBASE_STORAGE_BUCKET || 'silni-31811.firebasestorage.app',
  messagingSenderId:
    process.env.FIREBASE_MESSAGING_SENDER_ID || '1049917341546',
  appId:
    process.env.FIREBASE_APP_ID ||
    '1:1049917341546:web:baa2792c28877379412f13',
  measurementId: process.env.FIREBASE_MEASUREMENT_ID || 'G-1MR4GW3PR4',
};

// Initialize Firebase (only once)
let app: FirebaseApp;
if (getApps().length === 0) {
  app = initializeApp(firebaseConfig);
  console.log('✅ Firebase initialized successfully');
} else {
  app = getApps()[0];
  console.log('✅ Firebase already initialized');
}

// Initialize Firebase services
// Configure Auth with platform-specific persistence
export const auth: Auth = initializeAuth(app, {
  persistence:
    Platform.OS === 'web'
      ? browserLocalPersistence
      : getReactNativePersistence(AsyncStorage),
});
console.log(
  `✅ Firebase Auth configured with ${Platform.OS === 'web' ? 'browser' : 'AsyncStorage'} persistence`
);

export const db: Firestore = getFirestore(app);
export const storage: FirebaseStorage = getStorage(app);

// Analytics is NOT available in React Native - only for web
// We'll use Firebase Analytics for React Native separately if needed
console.log(`ℹ️ Running on ${Platform.OS} - Analytics disabled for native apps`);

export default app;
