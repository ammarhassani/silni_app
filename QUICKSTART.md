# Quick Start - iOS Build on iPhone 15 Pro

## What I Fixed:
1. Bundle ID changed from `com.example.silniApp` → `com.silni.app`
2. All your real env values are in the YAML (no placeholders)
3. Simplified config - just 2 workflows (iOS + Android)

---

## Steps to Build:

### 1. Sign up for Codemagic
- Go to https://codemagic.io/signup
- Sign up (free account)

### 2. Connect Your Repo
- Click "Add application"
- Connect your Git repo
- Select this project

### 3. Connect Apple Account
- Go to your app in Codemagic
- Click "Teams" → "Team integrations"
- Click "Connect" next to App Store Connect
- Choose "Apple ID and app-specific password"
- Enter your Apple ID email
- For password: Go to https://appleid.apple.com → Security → App-Specific Passwords → Generate
- Save it in Codemagic

### 4. Start Build
- In Codemagic, select workflow: `ios-development-build`
- Click "Start new build"
- Wait 15-20 minutes

### 5. Install on iPhone
- Check your email for build link
- Open link on your iPhone
- Tap "Install"
- Go to Settings → General → VPN & Device Management
- Trust your developer certificate
- Open app!

---

## For Multi-User Testing:

Run the `android-build` workflow instead - way easier!
- Builds Android APK
- Share the APK file with anyone
- No Apple restrictions

---

## Troubleshooting:

**"No matching profiles"** - Make sure you connected your Apple ID in Step 3

**"Untrusted developer"** - Trust certificate in iPhone Settings → General → VPN & Device Management

**Build fails** - Check the build logs, usually it's CocoaPods or env vars

---

## Bundle ID Changed:

Your iOS bundle identifier is now: **com.silni.app**

This matches your Android package: **com.silni.app**

---

That's it! Push to git and start your build in Codemagic.
