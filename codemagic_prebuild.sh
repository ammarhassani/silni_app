#!/bin/bash
set -e

echo "Creating .env file..."
cat > .env << EOF
FIREBASE_API_KEY=${FIREBASE_API_KEY}
FIREBASE_AUTH_DOMAIN=${FIREBASE_AUTH_DOMAIN}
FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID}
FIREBASE_STORAGE_BUCKET=${FIREBASE_STORAGE_BUCKET}
FIREBASE_MESSAGING_SENDER_ID=${FIREBASE_MESSAGING_SENDER_ID}
FIREBASE_APP_ID=${FIREBASE_APP_ID}
FIREBASE_MEASUREMENT_ID=${FIREBASE_MEASUREMENT_ID}
SUPABASE_STAGING_URL=${SUPABASE_STAGING_URL}
SUPABASE_STAGING_ANON_KEY=${SUPABASE_STAGING_ANON_KEY}
SUPABASE_PRODUCTION_URL=${SUPABASE_PRODUCTION_URL}
SUPABASE_PRODUCTION_ANON_KEY=${SUPABASE_PRODUCTION_ANON_KEY}
CLOUDINARY_CLOUD_NAME=${CLOUDINARY_CLOUD_NAME}
CLOUDINARY_UPLOAD_PRESET=${CLOUDINARY_UPLOAD_PRESET}
APP_ENV=${APP_ENV}
SENTRY_DSN=https://540a407e144e08e455f377ead56644a7@o4510476494241792.ingest.de.sentry.io/4510476495880272
IS_TESTFLIGHT=true
ENVIRONMENT=staging
EOF

echo "✅ .env file created"

echo ""
echo "📱 Verifying Firebase configuration files..."

# Verify GoogleService-Info.plist exists for iOS
if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo "✅ GoogleService-Info.plist found"

    # Make sure it has proper permissions
    chmod 644 ios/Runner/GoogleService-Info.plist
else
    echo "❌ ERROR: GoogleService-Info.plist not found at ios/Runner/GoogleService-Info.plist"
    echo "Current directory: $(pwd)"
    echo "Files in ios/Runner:"
    ls -la ios/Runner/ || true
    exit 1
fi

# Verify google-services.json exists for Android
if [ -f "android/app/google-services.json" ]; then
    echo "✅ google-services.json found"
    chmod 644 android/app/google-services.json
else
    echo "❌ ERROR: google-services.json not found at android/app/google-services.json"
    exit 1
fi

echo "✅ All Firebase configuration files verified"
