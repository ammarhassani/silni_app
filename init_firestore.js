#!/usr/bin/env node

/**
 * Initialize Firestore with user document
 * Run this script to create your user document and sample data
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = {
  projectId: 'silni-31811',
};

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: 'silni-31811'
});

const db = admin.firestore();

async function initializeFirestore() {
  try {
    console.log('🚀 Initializing Firestore...');

    // Your user ID from the logs
    const userId = 'hiwuF6WUIObb2Y2koFtGJnCBVNs2';

    // Create user document
    console.log('📝 Creating user document...');
    await db.collection('users').doc(userId).set({
      id: userId,
      email: 'azahrani337@gmail.com',
      fullName: 'Abdulaziz Alzahrani', // Update with your actual name
      phoneNumber: null,
      profilePictureUrl: null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
      emailVerified: false,
      subscriptionStatus: 'free',
      language: 'ar',
      notificationsEnabled: true,
      reminderTime: '09:00',
      theme: 'light',
      totalInteractions: 0,
      currentStreak: 0,
      longestStreak: 0,
      points: 0,
      level: 1,
      badges: [],
      dataExportRequested: false,
      accountDeletionRequested: false,
    });
    console.log('✅ User document created successfully!');

    // Create a sample hadith (optional - for testing)
    console.log('📖 Creating sample hadith...');
    await db.collection('hadiths').doc('sample1').set({
      id: 'sample1',
      arabicText: 'صِلَة الرَّحِمِ تزيد في العمر وتوسع في الرزق',
      englishText: 'Maintaining family ties increases lifespan and expands sustenance',
      reference: 'Sahih Bukhari',
      category: 'family',
      order: 1,
    });
    console.log('✅ Sample hadith created!');

    console.log('\n🎉 Firestore initialization complete!');
    console.log('\nNext steps:');
    console.log('1. Run your Flutter app: flutter run -d chrome');
    console.log('2. Sign in with: azahrani337@gmail.com');
    console.log('3. Try adding a relative - it should now persist!');
    console.log('\nCheck Firestore Console:');
    console.log('https://console.firebase.google.com/project/silni-31811/firestore/data');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error initializing Firestore:', error);
    process.exit(1);
  }
}

initializeFirestore();
