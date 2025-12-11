#!/bin/bash
set -e

echo "📱 Copying Firebase configuration files..."

# Ensure GoogleService-Info.plist exists in Runner directory
if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo "✅ GoogleService-Info.plist found"
else
    echo "❌ GoogleService-Info.plist NOT found!"
    exit 1
fi

# Ensure google-services.json exists for Android
if [ -f "android/app/google-services.json" ]; then
    echo "✅ google-services.json found"
else
    echo "❌ google-services.json NOT found!"
    exit 1
fi

echo "✅ Firebase files verified"
