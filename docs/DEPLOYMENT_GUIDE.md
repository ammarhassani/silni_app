# Silni App - Deployment and Environment Setup Guide

## Overview

This comprehensive guide covers the complete deployment process for Silni app across different environments, including development setup, staging deployment, and production release.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Environment Setup](#environment-setup)
3. [Development Environment](#development-environment)
4. [Staging Environment](#staging-environment)
5. [Production Environment](#production-environment)
6. [CI/CD Pipeline](#cicd-pipeline)
7. [Environment Variables](#environment-variables)
8. [Database Setup](#database-setup)
9. [Firebase Configuration](#firebase-configuration)
10. [Supabase Configuration](#supabase-configuration)
11. [Deployment Scripts](#deployment-scripts)
12. [Monitoring and Logging](#monitoring-and-logging)

---

## Prerequisites

### Required Software

| Tool | Minimum Version | Installation |
|------|----------------|---------------|
| **Flutter SDK** | 3.10.1 | [Flutter Install Guide](https://docs.flutter.dev/get-started/install) |
| **Dart SDK** | 3.10.1 | Included with Flutter |
| **Git** | 2.30.0 | [Git Install Guide](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) |
| **Node.js** | 16.0.0 | [Node.js Install](https://nodejs.org/) |
| **Supabase CLI** | 1.50.0 | `npm install -g supabase` |
| **Firebase CLI** | 12.0.0 | `npm install -g firebase-tools` |

### Development Tools

- **IDE**: VS Code with Flutter extension or Android Studio
- **Device**: iOS Simulator, Android Emulator, or physical devices
- **Browser**: Chrome for web development

### Platform-Specific Requirements

#### iOS Development
- **Xcode**: 14.0+ with iOS Simulator
- **CocoaPods**: 1.11.0+
- **Apple Developer Account**: For testing and deployment

#### Android Development
- **Android Studio**: Latest stable version
- **Android SDK**: API level 33+
- **Java Development Kit**: JDK 11+

---

## Environment Setup

### 1. Clone Repository

```bash
git clone https://github.com/your-org/silni_app.git
cd silni_app
```

### 2. Install Flutter Dependencies

```bash
# Get Flutter packages
flutter pub get

# Install build runner for code generation
flutter pub run build_runner build
```

### 3. Environment Configuration

```bash
# Copy environment template
cp .env.example .env

# Edit with your configuration
nano .env
```

### 4. Verify Setup

```bash
# Check Flutter environment
flutter doctor -v

# Check connected devices
flutter devices

# Run tests to verify setup
flutter test
```

---

## Development Environment

### Local Development Setup

#### 1. Supabase Local Development

```bash
# Start local Supabase stack
supabase start

# This starts:
# - PostgreSQL database
# - Supabase Studio (http://localhost:54323)
# - Auth service
# - Storage service
# - Realtime service
```

#### 2. Environment Variables

Create `.env` file for development:

```bash
# Development Environment
APP_ENV=development
ENVIRONMENT=development

# Supabase Development
SUPABASE_STAGING_URL=http://localhost:54321
SUPABASE_STAGING_ANON_KEY=your_local_anon_key

# Firebase Development (optional)
FIREBASE_PROJECT_ID=silni-dev
SENTRY_DSN=your_dev_sentry_dsn

# Development Flags
ENABLE_LOGGER=true
ENABLE_DEBUG_MODE=true
```

#### 3. Run Development Server

```bash
# Run on connected device/emulator
flutter run

# Run on specific platform
flutter run -d chrome
flutter run -d ios
flutter run -d android

# Run with hot reload disabled (for debugging)
flutter run --no-hot-reload
```

#### 4. Development Tools

```bash
# Watch for code generation changes
flutter pub run build_runner watch

# Run integration tests
flutter test integration_test/

# Generate app icons
flutter pub run flutter_launcher_icons:main

# Generate app splash screen
flutter pub run flutter_native_splash:create
```

---

## Staging Environment

### Staging Infrastructure

Staging environment mirrors production with:

- **Supabase**: Staging project
- **Firebase**: Staging project
- **Sentry**: Staging environment
- **Domain**: staging.silni.app

### 1. Supabase Staging Setup

```bash
# Link to staging project
supabase link --project-ref your-staging-project-ref

# Push local schema to staging
supabase db push

# Seed test data
supabase db seed
```

### 2. Firebase Staging Setup

```bash
# Use staging Firebase project
firebase use staging

# Deploy Firebase services
firebase deploy --only functions,hosting
```

### 3. Environment Configuration

```bash
# Staging Environment
APP_ENV=staging
ENVIRONMENT=staging

# Supabase Staging
SUPABASE_STAGING_URL=https://your-staging-project.supabase.co
SUPABASE_STAGING_ANON_KEY=your_staging_anon_key

# Firebase Staging
FIREBASE_PROJECT_ID=silni-staging
FCM_SERVER_KEY=your_staging_fcm_key

# Sentry Staging
SENTRY_DSN=your_staging_sentry_dsn

# Feature Flags
ENABLE_AI_FEATURES=true
ENABLE_PREMIUM_FEATURES=true
```

### 4. Build for Staging

```bash
# Build iOS for staging
flutter build ios --release --dart-define=ENVIRONMENT=staging

# Build Android for staging
flutter build appbundle --release --dart-define=ENVIRONMENT=staging

# Build Web for staging
flutter build web --release --dart-define=ENVIRONMENT=staging
```

### 5. Deploy to Staging

#### iOS Staging (TestFlight)

```bash
# Build and upload to TestFlight
flutter build ios --release --dart-define=ENVIRONMENT=staging
xcodebuild -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -destination generic/platform=iOS \
  -archivePath build/Runner.xcarchive \
  archive

# Upload to App Store Connect
xcrun altool --upload-app \
  --type ios \
  --file build/Runner.ipa \
  --username "your-apple-id@example.com" \
  --password "your-app-specific-password"
```

#### Android Staging (Internal Testing)

```bash
# Build AAB for internal testing
flutter build appbundle --release --dart-define=ENVIRONMENT=staging

# Upload to Google Play Console Internal Testing
# Use Google Play Console web interface for upload
```

---

## Production Environment

### Production Infrastructure

Production environment includes:

- **Supabase**: Production project with enterprise features
- **Firebase**: Production project with all services
- **Sentry**: Production environment with alerts
- **Domain**: silni.app
- **CDN**: CloudFlare for static assets

### 1. Supabase Production Setup

```bash
# Link to production project
supabase link --project-ref your-production-project-ref

# Deploy database migrations
supabase db push

# Set up production RLS policies
supabase db push --include-rls

# Configure production secrets
supabase secrets set SERVICE_ROLE_JWT=your_service_role_jwt
supabase secrets set DEEPSEEK_API_KEY=your_deepseek_key
```

### 2. Firebase Production Setup

```bash
# Use production Firebase project
firebase use production

# Deploy all Firebase services
firebase deploy

# Configure production indexes
firebase deploy --only firestore:indexes
```

### 3. Environment Configuration

```bash
# Production Environment
APP_ENV=production
ENVIRONMENT=production

# Supabase Production
SUPABASE_PRODUCTION_URL=https://your-production-project.supabase.co
SUPABASE_PRODUCTION_ANON_KEY=your_production_anon_key

# Firebase Production
FIREBASE_PROJECT_ID=silni-production
FCM_SERVER_KEY=your_production_fcm_key

# Sentry Production
SENTRY_DSN=your_production_sentry_dsn

# Production Flags
ENABLE_AI_FEATURES=true
ENABLE_PREMIUM_FEATURES=true
ENABLE_ANALYTICS=true
```

### 4. Build for Production

```bash
# Generate production environment files
flutter pub run build_runner build --delete-conflicting-outputs

# Build iOS for production
flutter build ios --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=APP_ENV=production

# Build Android for production
flutter build appbundle --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=APP_ENV=production

# Build Web for production
flutter build web --release \
  --web-renderer canvaskit \
  --dart-define=ENVIRONMENT=production \
  --dart-define=APP_ENV=production
```

### 5. Deploy to Production

#### iOS Production (App Store)

```bash
# Build for App Store
flutter build ios --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=APP_ENV=production

# Create archive
xcodebuild -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -destination generic/platform=iOS \
  -archivePath build/Runner.xcarchive \
  archive

# Export for App Store
xcodebuild -exportArchive \
  -archivePath build/Runner.xcarchive \
  -exportPath build/ios \
  -exportOptionsPlist ios/ExportOptions.plist

# Upload to App Store Connect
xcrun altool --upload-app \
  --type ios \
  --file build/ios/Runner.ipa \
  --username "your-apple-id@example.com" \
  --password "your-app-specific-password"
```

#### Android Production (Google Play Store)

```bash
# Build AAB for production
flutter build appbundle --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=APP_ENV=production

# Sign AAB (if not using Play App Signing)
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 \
  -keystore your-keystore.jks \
  build/app/outputs/bundle/release/app-release.aab \
  your-key-alias

# Upload to Google Play Console
# Use Google Play Console web interface for upload
```

#### Web Production (Firebase Hosting)

```bash
# Build for production
flutter build web --release \
  --web-renderer canvaskit \
  --dart-define=ENVIRONMENT=production

# Deploy to Firebase Hosting
firebase deploy --only hosting

# Configure custom domain
firebase hosting:main:channel:create live silni.app
```

---

## CI/CD Pipeline

### GitHub Actions Workflow

Create `.github/workflows/deploy.yml`:

```yaml
name: Build and Deploy

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  FLUTTER_VERSION: '3.10.1'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          
      - name: Install dependencies
        run: flutter pub get
        
      - name: Run tests
        run: flutter test
        
      - name: Run integration tests
        run: flutter test integration_test/

  build-ios:
    needs: test
    runs-on: macos-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          
      - name: Setup Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: latest-stable
          
      - name: Install dependencies
        run: |
          flutter pub get
          flutter pub run build_runner build
          
      - name: Build iOS
        run: |
          flutter build ios --release \
            --dart-define=ENVIRONMENT=production \
            --dart-define=APP_ENV=production \
            --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_PRODUCTION_URL }} \
            --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_PRODUCTION_ANON_KEY }} \
            --dart-define=SENTRY_DSN=${{ secrets.SENTRY_DSN }}
            
      - name: Upload to TestFlight
        uses: apple-actions/upload-testflight-build@v1
        with:
          app-path: build/ios/Runner.ipa
          apple-id: ${{ secrets.APPLE_ID }}
          issuer-id: ${{ secrets.APPLE_ISSUER_ID }}
          key-id: ${{ secrets.APPLE_KEY_ID }}
          key-base64: ${{ secrets.APPLE_KEY_BASE64 }}

  build-android:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          
      - name: Setup Java
        uses: actions/setup-java@v3
        with:
          distribution: 'temurin'
          java-version: '11'
          
      - name: Install dependencies
        run: |
          flutter pub get
          flutter pub run build_runner build
          
      - name: Build Android
        run: |
          flutter build appbundle --release \
            --dart-define=ENVIRONMENT=production \
            --dart-define=APP_ENV=production \
            --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_PRODUCTION_URL }} \
            --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_PRODUCTION_ANON_KEY }} \
            --dart-define=SENTRY_DSN=${{ secrets.SENTRY_DSN }}
            
      - name: Upload to Google Play
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT }}
          packageName: com.silni.app
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: production
```

### Environment-Specific Workflows

#### Staging Deployment

```yaml
name: Deploy to Staging

on:
  push:
    branches: [develop]

jobs:
  deploy-staging:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        
      - name: Build and Deploy
        run: |
          flutter build ios --release --dart-define=ENVIRONMENT=staging
          # Deploy to TestFlight with staging config
```

---

## Environment Variables

### Required Variables

| Variable | Description | Development | Staging | Production |
|-----------|-------------|-------------|----------|------------|
| `APP_ENV` | Application environment | `development` | `staging` | `production` |
| `ENVIRONMENT` | Sentry environment | `development` | `staging` | `production` |
| `SUPABASE_URL` | Supabase project URL | Local | Staging URL | Production URL |
| `SUPABASE_ANON_KEY` | Supabase anon key | Local | Staging key | Production key |
| `SENTRY_DSN` | Sentry error tracking DSN | Dev DSN | Staging DSN | Production DSN |

### Optional Variables

| Variable | Description | Default |
|-----------|-------------|---------|
| `ENABLE_LOGGER` | Enable debug logging | `false` |
| `ENABLE_ANALYTICS` | Enable analytics collection | `true` |
| `ENABLE_AI_FEATURES` | Enable AI-powered features | `true` |
| `IS_TESTFLIGHT` | TestFlight build flag | `false` |

### Secret Management

Using `envied` for type-safe environment variables:

```dart
// lib/core/config/env/app_environment.dart
import 'package:envied/envied.dart';

part 'app_environment.g.dart';

@Envied(path: '.env')
abstract class AppEnvironment {
  @EnviedField(varName: 'SUPABASE_URL', obfuscate: true)
  static const String supabaseUrl = _AppEnvironment.supabaseUrl;
  
  @EnviedField(varName: 'SUPABASE_ANON_KEY', obfuscate: true)
  static const String supabaseAnonKey = _AppEnvironment.supabaseAnonKey;
  
  @EnviedField(varName: 'SENTRY_DSN', obfuscate: true)
  static const String sentryDsn = _AppEnvironment.sentryDsn;
}
```

---

## Database Setup

### Supabase Database Initialization

#### 1. Create Project

```bash
# Create new Supabase project
supabase projects create

# Get project details
supabase projects list
```

#### 2. Database Schema

```sql
-- Create tables
CREATE TABLE users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created_at ON users(created_at);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (auth.uid() = id);
```

#### 3. Database Functions

```sql
-- Award points function
CREATE OR REPLACE FUNCTION award_points(
  p_user_id UUID,
  p_points INTEGER,
  p_reason TEXT
) RETURNS VOID AS $$
BEGIN
  UPDATE users 
  SET 
    total_points = total_points + p_points,
    updated_at = NOW()
  WHERE id = p_user_id;
  
  -- Log point award
  INSERT INTO point_transactions (user_id, points, reason)
  VALUES (p_user_id, p_points, p_reason);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

#### 4. Database Triggers

```sql
-- Update timestamp trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

#### 5. Recent Migrations

##### 20251227200000_subscription_tracking.sql

**Purpose**: RevenueCat subscription integration

**Changes**:
- Updates `users.subscription_status` constraint (free/premium only)
- Adds new columns to users table:
  - `subscription_product_id` (TEXT) - RevenueCat product ID
  - `subscription_expires_at` (TIMESTAMPTZ) - Subscription expiration date
  - `trial_started_at` (TIMESTAMPTZ) - Trial start timestamp
  - `trial_used` (BOOLEAN) - Whether trial has been used
- Creates `subscription_events` table for analytics:
  - Tracks purchase, renewal, upgrade, trial_start, trial_end, cancellation events
  - Includes revenue_amount and metadata columns
- Adds RLS policies for subscription events
- Creates helper functions:
  - `log_subscription_event()` - Log subscription analytics
  - `update_user_subscription()` - Update subscription status
  - `start_user_trial()` - Start free trial
  - `end_user_trial()` - End trial and mark as used

**Deployment**:
```bash
# Apply migration
supabase db push

# Verify tables exist
supabase db query "SELECT COUNT(*) FROM subscription_events"
```

##### 20251229_premium_onboarding.sql

**Purpose**: Premium onboarding tracking and analytics

**Changes**:
- Adds `users.onboarding_metadata` (JSONB) column for progress tracking
- Creates `onboarding_events` table:
  - Tracks step_viewed, step_completed, step_skipped, onboarding_completed events
  - Includes step_id, step_index, and metadata columns
- Adds indexes for efficient analytics queries
- Creates RLS policies (users can view/insert own events)
- Creates analytics functions:
  - `get_onboarding_analytics()` - Overall onboarding metrics
  - `get_step_analytics()` - Per-step completion rates

**Deployment**:
```bash
# Apply migration
supabase db push

# Verify table and column exist
supabase db query "SELECT onboarding_metadata FROM users LIMIT 1"
supabase db query "SELECT COUNT(*) FROM onboarding_events"
```

##### Running All Migrations

```bash
# List pending migrations
supabase migration list

# Apply all pending migrations
supabase db push

# If there are issues, repair migration state
supabase migration repair --status applied 20251227200000
```

---

## Firebase Configuration

### 1. Project Setup

```bash
# Create Firebase project
firebase projects create silni-app

# Add iOS app
firebase apps:create ios com.silni.app

# Add Android app
firebase apps:create android com.silni.app

# Add Web app
firebase apps:create web silni-app
```

### 2. Configuration Files

#### iOS Configuration

```xml
<!-- ios/Runner/GoogleService-Info.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CLIENT_ID</key>
  <string>your-ios-client-id</string>
  <key>REVERSED_CLIENT_ID</key>
  <string>your-reversed-client-id</string>
  <key>API_KEY</key>
  <string>your-api-key</string>
  <key>GCM_SENDER_ID</key>
  <string>your-gcm-sender-id</string>
  <key>PLIST_VERSION</key>
  <string>1</string>
  <key>BUNDLE_ID</key>
  <string>com.silni.app</string>
  <key>PROJECT_ID</key>
  <string>silni-app</string>
</dict>
</plist>
```

#### Android Configuration

```xml
<!-- android/app/google-services.json -->
{
  "project_info": {
    "project_number": "123456789",
    "project_id": "silni-app",
    "storage_bucket": "silni-app.appspot.com"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:123456789:android:abcdef",
        "android_client_info": {
          "package_name": "com.silni.app"
        }
      }
    }
  ]
}
```

### 3. Firebase Services Setup

#### Cloud Functions

```javascript
// functions/src/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Send push notification
exports.sendPushNotification = functions.https.onCall(async (data, context) => {
  const { token, title, body } = data;
  
  const message = {
    notification: {
      title,
      body,
    },
    token,
  };
  
  return admin.messaging().send(message);
});
```

#### Firestore Rules

```javascript
// firestore.rules
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
  }
}
```

---

## Supabase Configuration

### 1. Project Configuration

```bash
# Initialize Supabase project
supabase init

# Link to existing project
supabase link --project-ref your-project-ref

# Start local development
supabase start
```

### 2. Authentication Configuration

```sql
-- Enable auth providers
INSERT INTO auth.providers (id, name, enabled) VALUES
  ('email', 'Email', true),
  ('google', 'Google', true),
  ('apple', 'Apple', true);

-- Configure JWT settings
UPDATE auth.config SET value = '24h' WHERE key = 'jwt_expiry';
```

### 3. Storage Configuration

```sql
-- Create storage buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
  ('avatars', 'avatars', false, 5242880, ARRAY['image/jpeg', 'image/png']),
  ('relatives', 'relatives', false, 10485760, ARRAY['image/jpeg', 'image/png']),
  ('interactions', 'interactions', false, 10485760, ARRAY['image/*', 'video/*']);

-- Create storage policies
CREATE POLICY "Users can upload own avatar" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'avatars' AND 
    auth.uid()::text = (storage.foldername(name))[1]
  );
```

---

## Deployment Scripts

### Build Script

Create `scripts/build.sh`:

```bash
#!/bin/bash

set -e

ENVIRONMENT=${1:-development}
PLATFORM=${2:-all}

echo "Building Silni app for environment: $ENVIRONMENT, platform: $PLATFORM"

# Generate environment files
flutter pub run build_runner build --delete-conflicting-outputs

# Build based on platform
case $PLATFORM in
  "ios")
    echo "Building iOS..."
    flutter build ios --release \
      --dart-define=ENVIRONMENT=$ENVIRONMENT \
      --dart-define=APP_ENV=$ENVIRONMENT
    ;;
  "android")
    echo "Building Android..."
    flutter build appbundle --release \
      --dart-define=ENVIRONMENT=$ENVIRONMENT \
      --dart-define=APP_ENV=$ENVIRONMENT
    ;;
  "web")
    echo "Building Web..."
    flutter build web --release \
      --web-renderer canvaskit \
      --dart-define=ENVIRONMENT=$ENVIRONMENT \
      --dart-define=APP_ENV=$ENVIRONMENT
    ;;
  "all")
    echo "Building all platforms..."
    flutter build ios --release --dart-define=ENVIRONMENT=$ENVIRONMENT
    flutter build appbundle --release --dart-define=ENVIRONMENT=$ENVIRONMENT
    flutter build web --release --dart-define=ENVIRONMENT=$ENVIRONMENT
    ;;
esac

echo "Build completed successfully!"
```

### Deploy Script

Create `scripts/deploy.sh`:

```bash
#!/bin/bash

set -e

ENVIRONMENT=${1:-staging}
PLATFORM=${2:-all}

echo "Deploying Silni app to environment: $ENVIRONMENT, platform: $PLATFORM"

# Build first
./scripts/build.sh $ENVIRONMENT $PLATFORM

# Deploy based on environment
case $ENVIRONMENT in
  "staging")
    echo "Deploying to staging..."
    # Upload to TestFlight
    if [[ $PLATFORM == "ios" || $PLATFORM == "all" ]]; then
      echo "Uploading iOS to TestFlight..."
      xcrun altool --upload-app --type ios --file build/ios/Runner.ipa
    fi
    
    # Upload to Google Play Internal Testing
    if [[ $PLATFORM == "android" || $PLATFORM == "all" ]]; then
      echo "Uploading Android to Google Play Internal Testing..."
      # Use Google Play Console API or manual upload
    fi
    ;;
  "production")
    echo "Deploying to production..."
    # Production deployment with additional checks
    read -p "Are you sure you want to deploy to production? (yes/no) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
      # Deploy to App Store and Google Play
      echo "Deploying to production stores..."
    else
      echo "Production deployment cancelled."
      exit 1
    fi
    ;;
esac

echo "Deployment completed successfully!"
```

### Make Scripts Executable

```bash
chmod +x scripts/build.sh
chmod +x scripts/deploy.sh
```

---

## Monitoring and Logging

### Sentry Configuration

```dart
// lib/main.dart
await SentryFlutter.init(
  (options) {
    options.dsn = AppEnvironment.sentryDsn;
    options.tracesSampleRate = 1.0;
    options.environment = AppEnvironment.sentryEnvironment;
  },
);
```

### Custom Monitoring

```dart
// lib/core/services/monitoring_service.dart
class MonitoringService {
  static void trackDeployment(String environment, String version) {
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: 'App deployed',
        category: 'deployment',
        data: {
          'environment': environment,
          'version': version,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ),
    );
  }
  
  static void trackError(Exception error, StackTrace stackTrace) {
    Sentry.captureException(error, stackTrace: stackTrace);
  }
}
```

### Health Check Endpoint

```dart
// lib/core/services/health_service.dart
class HealthService {
  static Future<Map<String, dynamic>> checkHealth() async {
    final health = {
      'status': 'healthy',
      'timestamp': DateTime.now().toIso8601String(),
      'version': PackageInfo.fromPlatform().version,
      'services': {},
    };
    
    // Check Supabase
    try {
      await SupabaseConfig.client.from('users').select('id').limit(1);
      health['services']['supabase'] = 'healthy';
    } catch (e) {
      health['services']['supabase'] = 'unhealthy';
      health['status'] = 'degraded';
    }
    
    // Check Firebase
    try {
      await Firebase.initializeApp();
      health['services']['firebase'] = 'healthy';
    } catch (e) {
      health['services']['firebase'] = 'unhealthy';
      health['status'] = 'degraded';
    }
    
    return health;
  }
}
```

---

## Troubleshooting

### Common Issues

#### Build Failures

```bash
# Clean build cache
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Check for conflicting dependencies
flutter pub deps
```

#### Environment Issues

```bash
# Verify environment variables
flutter pub run build_runner build
echo $SUPABASE_URL

# Check environment configuration
flutter pub run envied:generate
```

#### Deployment Issues

```bash
# Check Firebase configuration
firebase projects:list
firebase use --project your-project

# Check Supabase connection
supabase status
supabase db push
```

### Debug Commands

```bash
# Verbose build output
flutter build ios --release --verbose

# Check device connectivity
flutter devices

# Run with debugging
flutter run --debug
```

---

## Security Considerations

### Production Deployment Checklist

- [ ] Environment variables are set correctly
- [ ] API keys are secured and not hardcoded
- [ ] SSL certificates are valid
- [ ] Database backups are configured
- [ ] Error tracking is enabled
- [ ] Rate limiting is configured
- [ ] Security policies are in place
- [ ] Access controls are implemented

### Post-Deployment Verification

1. **Functionality Testing**: All features work correctly
2. **Performance Testing**: App performs within acceptable limits
3. **Security Testing**: No vulnerabilities exposed
4. **Monitoring**: All monitoring systems are active
5. **Backup Verification**: Data can be restored if needed

---

## Conclusion

This deployment guide provides comprehensive instructions for deploying Silni across all environments. Following these guidelines ensures:

1. **Consistent Deployments**: Standardized process across environments
2. **Security**: Proper handling of secrets and access controls
3. **Reliability**: Comprehensive testing and monitoring
4. **Scalability**: Infrastructure ready for production load
5. **Maintainability**: Clear processes for updates and fixes

For additional support or questions, refer to the [troubleshooting guide](TROUBLESHOOTING.md) or contact the development team.