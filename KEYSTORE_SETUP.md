# Android Release Signing Setup Guide

## Overview

For production releases on Google Play Store, you **must** sign your app with a release keystore. This guide walks you through creating and configuring your Android release signing.

---

##   CRITICAL: Keystore Security

**Your keystore is the ONLY way to update your app on Google Play!**

- **If you lose it:** You can NEVER update your app (must create new app listing)
- **If it's stolen:** Someone can impersonate your app
- **Store it securely:** Multiple encrypted backups in different locations
- **Passwords in password manager:** Never write them down in plain text

---

## Step 1: Create a Keystore

### Option A: Using keytool (Recommended)

Navigate to the `android` directory and run:

```bash
cd android

keytool -genkey -v -keystore silni-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias silni-key-alias
```

### Option B: Using Android Studio

1. Open the Android project in Android Studio
2. Go to **Build ’ Generate Signed Bundle / APK**
3. Click **Create new** under Key store path
4. Fill in the details and click **OK**

---

## Step 2: Answer the Prompts

You'll be asked for:

1. **Keystore password:** Choose a strong password (min 12 characters)
   - Example: `S1ln!Str0ng@P@ssw0rd2025!`
   - **SAVE THIS IN A PASSWORD MANAGER!**

2. **Key password:** Can be the same or different from keystore password
   - **SAVE THIS IN A PASSWORD MANAGER!**

3. **Your details:**
   ```
   What is your first and last name?
     [Your name or company name]
   What is the name of your organizational unit?
     [Your team/department or leave blank]
   What is the name of your organization?
     [Your company/organization name]
   What is the name of your City or Locality?
     [Your city]
   What is the name of your State or Province?
     [Your state/province]
   What is the two-letter country code for this unit?
     [Your country code, e.g., US, GB, etc.]
   ```

4. **Confirm:** Type `yes` when asked "Is ... correct?"

---

## Step 3: Create key.properties File

1. **Copy the template:**
   ```bash
   cd android
   cp key.properties.example key.properties
   ```

2. **Edit key.properties:**
   ```properties
   storeFile=../silni-release-key.jks
   storePassword=YOUR_KEYSTORE_PASSWORD_HERE
   keyAlias=silni-key-alias
   keyPassword=YOUR_KEY_PASSWORD_HERE
   ```

3. **Replace the placeholders:**
   - `YOUR_KEYSTORE_PASSWORD_HERE` ’ Your keystore password
   - `YOUR_KEY_PASSWORD_HERE` ’ Your key password

---

## Step 4: Verify Setup

Run this command to test the release build:

```bash
flutter build apk --release
```

Expected output:
```
 Built build/app/outputs/flutter-apk/app-release.apk (XX.XMB)
```

If you see this, your signing is configured correctly! 

---

## Step 5: Backup Your Keystore

**IMMEDIATELY backup your keystore to multiple secure locations:**

### Recommended Backup Strategy:

1. **Local encrypted backup:**
   ```bash
   # Create encrypted archive
   7z a -p -mhe=on silni-keystore-backup.7z android/silni-release-key.jks
   ```
   - Store in secure location (encrypted USB drive, encrypted folder)

2. **Cloud backup (encrypted):**
   - Upload to Google Drive / Dropbox in encrypted format
   - Use a strong encryption password (different from keystore password)

3. **Password manager:**
   - Store all passwords in 1Password / Bitwarden / LastPass
   - Include:
     - Keystore password
     - Key password
     - Location of keystore backups

4. **Team access (if applicable):**
   - Share with trusted team members via secure method
   - Consider using Google Play App Signing (Google manages your key)

---

## Google Play App Signing (Recommended)

Google offers to manage your app signing key for you. Benefits:

 **No risk of losing your key** - Google keeps it safe
 **Key rotation** - If compromised, Google can rotate it
 **Optimized APKs** - Google re-signs with device-specific keys

### How to enable:

1. Generate your upload key (steps above)
2. When uploading first release to Play Console:
   - Choose "Let Google manage and protect your app signing key"
   - Google generates a separate signing key
   - You keep the upload key

3. Future updates:
   - Sign with your upload key (the one you created)
   - Google re-signs with the actual signing key before distribution

**Note:** This is opt-in during first upload. Highly recommended for new apps!

---

## Keystore Information

After creating your keystore, save this information:

```
Keystore file: android/silni-release-key.jks
Key alias: silni-key-alias
Key algorithm: RSA
Key size: 2048 bits
Validity: 10000 days (~27 years)
Created on: [DATE]
```

---

## Troubleshooting

### Error: "keystore not found"

**Solution:** Make sure `key.properties` has the correct path:
```properties
storeFile=../silni-release-key.jks
```
The path is relative to `android/app/`, so `../` goes up to `android/`

### Error: "keystore password was incorrect"

**Solution:** Double-check your `key.properties` file. Passwords are case-sensitive.

### Error: "key.properties does not exist"

**Solution:**
1. Copy `key.properties.example` to `key.properties`
2. Fill in your actual credentials

### Build works without key.properties

**Note:** This is intentional! If `key.properties` doesn't exist, the build falls back to debug signing so development builds work. For production, you MUST create `key.properties`.

---

## Security Checklist

Before committing any code:

- [ ] `key.properties` is in `.gitignore`
- [ ] `*.jks` and `*.keystore` are in `.gitignore`
- [ ] Keystore file is NOT in git repository
- [ ] Keystore backed up in 3+ secure locations
- [ ] Passwords saved in password manager
- [ ] Team members informed of backup locations (if applicable)

Run this to verify:
```bash
git status --ignored
```

You should see:
```
# Ignored files:
#   android/key.properties
#   android/silni-release-key.jks
```

---

## CI/CD Integration

For automated builds (GitHub Actions, GitLab CI, etc.):

1. **Store keystore as base64 secret:**
   ```bash
   base64 android/silni-release-key.jks > keystore.b64
   ```

2. **Add to CI secrets:**
   - `KEYSTORE_BASE64` - Contents of keystore.b64
   - `KEYSTORE_PASSWORD` - Your keystore password
   - `KEY_ALIAS` - silni-key-alias
   - `KEY_PASSWORD` - Your key password

3. **Decode in CI script:**
   ```bash
   echo $KEYSTORE_BASE64 | base64 -d > android/silni-release-key.jks
   echo "storeFile=../silni-release-key.jks" > android/key.properties
   echo "storePassword=$KEYSTORE_PASSWORD" >> android/key.properties
   echo "keyAlias=$KEY_ALIAS" >> android/key.properties
   echo "keyPassword=$KEY_PASSWORD" >> android/key.properties
   ```

---

## iOS Signing (Future Reference)

For iOS app store releases, you'll need:
- Apple Developer Account ($99/year)
- Provisioning profiles
- Distribution certificates

We'll set this up when ready for iOS deployment.

---

## Quick Reference

| File | Location | Purpose | In Git? |
|------|----------|---------|---------|
| `silni-release-key.jks` | `android/` | Release signing key | L NO |
| `key.properties` | `android/` | Signing credentials | L NO |
| `key.properties.example` | `android/` | Template file |  YES |
| `build.gradle.kts` | `android/app/` | Build configuration |  YES |
| `.gitignore` | `/` | Excludes secrets |  YES |

---

## Additional Resources

- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [Google Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756)
- [Flutter Release Builds](https://docs.flutter.dev/deployment/android#signing-the-app)

---

**Last Updated:** 2025-11-30
**App ID:** com.silni.app
**Key Alias:** silni-key-alias
