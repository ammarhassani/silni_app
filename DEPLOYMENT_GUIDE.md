# 🚀 Silni App - Deployment Guide

This guide will walk you through deploying Firebase security rules, indexes, and the Flutter app.

## ⚠️ CRITICAL: Deploy Indexes FIRST!

**Before running the app in production, you MUST deploy Firestore indexes!**

Without indexes deployed:
- ❌ Queries will be extremely slow or timeout
- ❌ Relatives data won't load properly
- ❌ App will appear broken to users

**Quick fix**: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed instructions.

```bash
# Deploy indexes immediately
firebase deploy --only firestore:indexes

# Deploy security rules
firebase deploy --only firestore:rules
```

**Wait 5-10 minutes for indexes to build before testing the app.**

## 📋 Prerequisites

Before deploying, make sure you have:

1. **Firebase CLI** installed
   ```bash
   npm install -g firebase-tools
   ```

2. **Firebase Project** set up
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create or select your project (`silni-31811`)

3. **Environment Variables** configured
   - Copy `.env.example` to `.env`
   - Fill in all required credentials (Firebase, Cloudinary)

## 🔐 Step 1: Deploy Firestore Security Rules

Security rules protect your database from unauthorized access.

```bash
# Login to Firebase (if not already logged in)
firebase login

# Initialize Firebase in your project (if not already done)
firebase init

# Deploy only Firestore rules
firebase deploy --only firestore:rules

# Deploy both rules and indexes
firebase deploy --only firestore
```

### ✅ Verify Deployment

1. Go to Firebase Console → Firestore Database → Rules
2. You should see the rules deployed with timestamp
3. Click "Test rules" to verify they're working

## 📊 Step 2: Deploy Firestore Indexes

Indexes are required for complex queries to work efficiently.

```bash
# Deploy Firestore indexes
firebase deploy --only firestore:indexes
```

This will create indexes for:
- Relatives queries (by userId, isArchived, priority, fullName)
- Interactions queries (by userId, date, type)
- Reminders queries (by userId, isActive, nextReminderDate)

### ⏱️ Index Creation Time

- Indexes may take 5-10 minutes to build
- Check progress: Firebase Console → Firestore → Indexes
- App will work but may be slow until indexes are ready

## 🗄️ Step 3: Deploy Storage Rules

Storage rules protect your uploaded files.

```bash
# Deploy Storage rules
firebase deploy --only storage
```

### ✅ Verify Storage Rules

1. Go to Firebase Console → Storage → Rules
2. Verify rules are deployed
3. Test uploading a file from the app

## 🌐 Step 4: Build & Deploy Web App (Optional)

If you want to deploy the web version to Firebase Hosting:

```bash
# Build the Flutter web app
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

Your app will be available at: `https://silni-31811.web.app`

## 📱 Step 5: Build Mobile Apps

### Android

```bash
# Build APK for testing
flutter build apk --release

# Or build App Bundle for Play Store
flutter build appbundle --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### iOS

```bash
# Build iOS app (requires macOS)
flutter build ios --release
```

Then open `ios/Runner.xcworkspace` in Xcode to archive and upload to App Store.

## 🔔 Step 6: Configure Firebase Cloud Messaging (FCM)

For push notifications to work:

### Android
1. Download `google-services.json` from Firebase Console
2. Place it in `android/app/`
3. Already configured in `android/app/build.gradle`

### iOS
1. Download `GoogleService-Info.plist` from Firebase Console
2. Place it in `ios/Runner/`
3. Open Xcode and add to project

### Web
1. Get your VAPID key from Firebase Console → Project Settings → Cloud Messaging
2. Add to `web/index.html` in the Firebase config

## 🧪 Step 7: Test Deployment

### Test Security Rules

Try these scenarios to verify rules are working:

1. **Authenticated Access**: User can read their own data ✅
2. **Unauthorized Access**: User cannot read other users' data ❌
3. **Data Validation**: Invalid data is rejected ❌
4. **Anonymous Access**: Unauthenticated requests fail ❌

### Test Indexes

Monitor Firestore queries in Firebase Console:
- Go to Firestore → Usage
- Check for "Missing Index" errors
- All queries should complete quickly (<100ms)

### Test Notifications

1. Enable notifications in app settings
2. Create a reminder
3. Verify notification appears at scheduled time
4. Test notification tap navigation

## 🐛 Troubleshooting

### Issue: "Missing Index" Error

**Solution**: Deploy indexes with `firebase deploy --only firestore:indexes`

### Issue: "Permission Denied" Error

**Solution**:
1. Check Firestore rules are deployed
2. Verify user is authenticated
3. Check userId matches in rules

### Issue: Notifications Not Working

**Solution**:
1. Verify FCM token is saved to Firestore
2. Check notification permissions are granted
3. Ensure `google-services.json` is in place
4. Test with Firebase Console → Cloud Messaging → Send test message

### Issue: Images Not Uploading

**Solution**:
1. Deploy storage rules
2. Verify Cloudinary credentials in `.env`
3. Check network permissions in `AndroidManifest.xml`

## 📊 Monitoring & Analytics

### Firebase Analytics

Already configured! View analytics at:
- Firebase Console → Analytics → Dashboard

Track:
- User engagement
- Screen views
- Custom events (interactions, reminders created, etc.)

### Crashlytics

To enable crash reporting:
1. Add Firebase Crashlytics to pubspec.yaml
2. Initialize in `main.dart`
3. View crashes in Firebase Console → Crashlytics

## 🔄 Continuous Deployment

### Using GitHub Actions (Recommended)

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Firebase

on:
  push:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.0'

      - name: Install dependencies
        run: flutter pub get

      - name: Build web
        run: flutter build web --release

      - name: Deploy to Firebase
        uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          channelId: live
          projectId: silni-31811
```

## 🎉 Deployment Checklist

Before going live, verify:

- [ ] `.env` file configured with production credentials
- [ ] Firestore security rules deployed and tested
- [ ] Firestore indexes created and built
- [ ] Storage rules deployed
- [ ] FCM configured for all platforms
- [ ] App built and tested on real devices
- [ ] Analytics tracking verified
- [ ] All TODO items completed (see codebase)
- [ ] Privacy policy and terms of service added
- [ ] GDPR compliance features implemented (data export, account deletion)

## 🔒 Security Checklist

- [ ] Firebase API keys moved to environment variables
- [ ] Cloudinary credentials secured
- [ ] Firestore rules block unauthorized access
- [ ] Storage rules enforce file size limits
- [ ] No sensitive data in logs
- [ ] All user inputs validated

## 📱 App Store Submission

### Android (Play Store)

1. Build app bundle: `flutter build appbundle --release`
2. Sign APK with release keystore
3. Create Play Store listing
4. Submit for review

### iOS (App Store)

1. Build iOS app: `flutter build ios --release`
2. Archive in Xcode
3. Submit to App Store Connect
4. Create App Store listing
5. Submit for review

## 🆘 Need Help?

- **Firebase Documentation**: https://firebase.google.com/docs
- **Flutter Documentation**: https://docs.flutter.dev
- **Issue Tracker**: Create an issue in your repository
- **Firebase Support**: https://firebase.google.com/support

---

**Good luck with your deployment! 🚀**
