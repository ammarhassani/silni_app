#!/bin/bash
set -e

echo "🔧 Creating .env file for Flutter app..."

cat > .env << EOF
# ============================================
# FIREBASE CONFIGURATION
# Used for FCM push notifications (client-side)
# ============================================
FIREBASE_API_KEY=${FIREBASE_API_KEY}
FIREBASE_AUTH_DOMAIN=${FIREBASE_AUTH_DOMAIN}
FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID}
FIREBASE_STORAGE_BUCKET=${FIREBASE_STORAGE_BUCKET}
FIREBASE_MESSAGING_SENDER_ID=${FIREBASE_MESSAGING_SENDER_ID}
FIREBASE_APP_ID=${FIREBASE_APP_ID}
FIREBASE_MEASUREMENT_ID=${FIREBASE_MEASUREMENT_ID}

# ============================================
# SUPABASE CONFIGURATION
# Primary backend for auth, database, storage
# ============================================
SUPABASE_STAGING_URL=${SUPABASE_STAGING_URL}
SUPABASE_STAGING_ANON_KEY=${SUPABASE_STAGING_ANON_KEY}
SUPABASE_PRODUCTION_URL=${SUPABASE_PRODUCTION_URL}
SUPABASE_PRODUCTION_ANON_KEY=${SUPABASE_PRODUCTION_ANON_KEY}

# ============================================
# CLOUDINARY CONFIGURATION
# Image upload and CDN
# ============================================
CLOUDINARY_CLOUD_NAME=${CLOUDINARY_CLOUD_NAME}
CLOUDINARY_UPLOAD_PRESET=${CLOUDINARY_UPLOAD_PRESET}

# ============================================
# APP ENVIRONMENT
# ============================================
APP_ENV=${APP_ENV}
ENVIRONMENT=staging
IS_TESTFLIGHT=true

# ============================================
# ERROR TRACKING
# ============================================
SENTRY_DSN=https://540a407e144e08e455f377ead56644a7@o4510476494241792.ingest.de.sentry.io/4510476495880272

# ============================================
# NOTE: Server-side secrets NOT included here
# ============================================
# The following are ONLY needed for Supabase Edge Functions (server-side):
# - FIREBASE_SERVICE_ACCOUNT (for sending FCM from backend)
# - SUPABASE_SERVICE_ROLE_KEY (for admin operations from backend)
# 
# These should be added to:
# Supabase Dashboard → Project Settings → Edge Functions → Secrets
EOF

echo "✅ .env file created successfully"
echo "📋 Environment: ${APP_ENV}"
echo "🔒 Secrets loaded from Codemagic environment variables"
