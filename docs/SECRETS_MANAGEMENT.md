# Secrets Management Guide

## Overview

Silni uses the `envied` package for compile-time, type-safe environment variable management. This approach provides:

- **Type Safety**: Variables are checked at compile time, not runtime
- **Obfuscation**: Sensitive values are XOR-encrypted in the binary
- **Security**: `.env` file is NOT bundled with the app
- **CI/CD Ready**: Supports `--dart-define` for build-time injection

## Quick Start

### 1. Initial Setup (First Time)

```bash
# Copy the example file
cp .env.example .env

# Fill in your values (get from Supabase/Sentry dashboards)
# Edit .env with your credentials

# Generate the configuration
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. After Modifying .env

Whenever you change environment variables:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Building for Production

#### Option A: Using .env file (local builds)
```bash
# Ensure .env has production values or APP_ENV=production
flutter pub run build_runner build
flutter build ios --release
```

#### Option B: Using dart-define (CI/CD)
```bash
flutter build ios --release \
  --dart-define=SUPABASE_URL=$SUPABASE_PRODUCTION_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_PRODUCTION_ANON_KEY \
  --dart-define=SENTRY_DSN=$SENTRY_DSN \
  --dart-define=APP_ENV=production \
  --dart-define=ENVIRONMENT=production
```

## Environment Variables

### Required Variables

| Variable | Description | Where to Get |
|----------|-------------|--------------|
| `SUPABASE_STAGING_URL` | Staging Supabase URL | Supabase Dashboard > Settings > API |
| `SUPABASE_STAGING_ANON_KEY` | Staging anon key | Same location |
| `SUPABASE_PRODUCTION_URL` | Production Supabase URL | Production project dashboard |
| `SUPABASE_PRODUCTION_ANON_KEY` | Production anon key | Same location |
| `SENTRY_DSN` | Error tracking DSN | Sentry > Project Settings > Client Keys |

### Optional Variables

| Variable | Description |
|----------|-------------|
| `APP_ENV` | `staging` or `production` - selects Supabase instance |
| `ENVIRONMENT` | `development`, `staging`, or `production` - Sentry environment |
| `IS_TESTFLIGHT` | `true` or `false` - enables error logging for TestFlight |
| `CLOUDINARY_*` | Image processing (not currently used) |
| `FIREBASE_*` | Legacy web configuration (for future web support) |

## Architecture

### File Structure

```
lib/core/config/env/
├── env.dart              # Base config (APP_ENV, ENVIRONMENT)
├── env.g.dart            # Generated (gitignored)
├── env_staging.dart      # Staging Supabase credentials
├── env_staging.g.dart    # Generated (gitignored)
├── env_production.dart   # Production Supabase credentials
├── env_production.g.dart # Generated (gitignored)
├── env_services.dart     # Sentry, Cloudinary
├── env_services.g.dart   # Generated (gitignored)
├── env_firebase.dart     # Legacy Firebase web config
├── env_firebase.g.dart   # Generated (gitignored)
├── app_environment.dart  # Unified accessor class
└── env_validator.dart    # Startup validation
```

### How It Works

1. **Compile Time**: `envied_generator` reads `.env` and generates `*.g.dart` files
2. **Obfuscation**: Sensitive values are XOR-encrypted in the generated code
3. **Runtime**: `AppEnvironment` class provides type-safe access to all values
4. **Validation**: `EnvValidator` checks required values at app startup
5. **Priority**: `--dart-define` values override `.env` values (for CI/CD)

### Usage in Code

```dart
import 'package:silni_app/core/config/env/app_environment.dart';

// Get Supabase URL (automatically selects staging/production)
final url = AppEnvironment.supabaseUrl;

// Check environment
if (AppEnvironment.isProduction) {
  // Production-specific logic
}

// Get Sentry DSN
final dsn = AppEnvironment.sentryDsn;
```

## Secret Rotation

### Rotating Supabase Keys

1. Generate new key in Supabase Dashboard
2. Update `.env` with new key
3. Run `flutter pub run build_runner build --delete-conflicting-outputs`
4. Deploy new build
5. (Optional) Revoke old key after all users update

### Rotating Sentry DSN

1. Create new DSN in Sentry Dashboard
2. Update `.env`
3. Regenerate and deploy
4. Delete old DSN after confirming data flow

### Rotating Edge Function Secrets

Edge function secrets are managed separately via Supabase CLI:

```bash
# Update secret
supabase secrets set SERVICE_ROLE_JWT='new_jwt_token'
supabase secrets set FIREBASE_SERVICE_ACCOUNT='{"type":"service_account",...}'

# Redeploy functions
supabase functions deploy
```

## CI/CD Integration

### GitHub Actions Example

```yaml
# .github/workflows/build.yml
name: Build iOS

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.0'

      - name: Install dependencies
        run: flutter pub get

      - name: Build iOS
        run: |
          flutter build ios --release --no-codesign \
            --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_PRODUCTION_URL }} \
            --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_PRODUCTION_ANON_KEY }} \
            --dart-define=SENTRY_DSN=${{ secrets.SENTRY_DSN }} \
            --dart-define=APP_ENV=production \
            --dart-define=ENVIRONMENT=production
```

### Required GitHub Secrets

Add these secrets to your repository (Settings > Secrets and variables > Actions):

- `SUPABASE_PRODUCTION_URL`
- `SUPABASE_PRODUCTION_ANON_KEY`
- `SENTRY_DSN`

## Security Notes

1. **Never commit `.env`** - It's in .gitignore
2. **Never commit `*.g.dart` env files** - They contain obfuscated but extractable secrets
3. **Obfuscation is not encryption** - Determined attackers can still extract values from the binary
4. **Use dart-define for CI/CD** - Don't store secrets in repository
5. **Rotate secrets periodically** - At minimum after team member leaves
6. **Edge function secrets are safe** - They never leave the server

## Troubleshooting

### "Missing required configuration" error

```bash
# Regenerate configuration
flutter pub run build_runner build --delete-conflicting-outputs
```

### Variables not updating

```bash
# Force full regeneration
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Build fails with "Cannot find .env"

Ensure `.env` file exists in project root:
```bash
cp .env.example .env
# Then edit .env with your values
```

### IDE shows errors in env files

The `*.g.dart` files are generated. Run build_runner:
```bash
flutter pub run build_runner build
```

### "Undefined name '_Env'" errors

This means the generated files don't exist yet:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```
