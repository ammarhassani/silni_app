# 📱 Codemagic iOS Build Setup Guide

## 🎯 Your Situation
- ✅ Windows development machine
- ✅ iPhone 15 Pro for testing
- ❌ No paid Apple Developer account ($99/year)
- 🎯 Want to test with multiple users

## ⚠️ Important Limitations

### With FREE Apple Account:
- ✅ Can install on YOUR iPhone 15 Pro only
- ⏰ App expires after 7 days (need to rebuild)
- ❌ Cannot distribute to other testers
- ❌ No TestFlight access

### With PAID Apple Account ($99/year):
- ✅ Ad-Hoc distribution to 100 devices
- ✅ TestFlight for 10,000 testers
- ✅ Apps don't expire after 7 days
- ✅ App Store distribution

---

## 🚀 Step-by-Step Setup

### Step 1: Prepare Your Apple Account

1. **Create/Verify Apple ID**
   - Go to https://appleid.apple.com
   - Enable Two-Factor Authentication (REQUIRED)

2. **Get App-Specific Password**
   - Go to https://appleid.apple.com
   - Sign in → Security → App-Specific Passwords
   - Generate a new password for "Codemagic"
   - **Save this password** - you'll need it!

---

### Step 2: Sign Up for Codemagic

1. **Create Account**
   - Go to https://codemagic.io
   - Sign up with GitHub/GitLab/Bitbucket or email
   - Free tier: 500 build minutes/month

2. **Connect Your Repository**
   - Click "Add application"
   - Connect to your Git provider
   - Select `silni-app/silni_app` repository

---

### Step 3: Configure iOS Code Signing

1. **In Codemagic Dashboard:**
   - Go to your app → Teams → Team integrations
   - Click "Connect" next to App Store Connect

2. **Add Apple Account:**
   - Select "Apple ID and app-specific password"
   - Enter your Apple ID email
   - Enter the app-specific password from Step 1
   - Click "Save"

3. **Automatic Code Signing:**
   - Codemagic will generate provisioning profiles automatically
   - For FREE account: Select "Development" distribution type
   - For PAID account: Select "Ad-Hoc" for multiple testers

---

### Step 4: Set Up Environment Variables

1. **Check Your `.env` File:**
   ```bash
   cat .env
   ```

2. **In Codemagic:**
   - Go to your app → Environment variables
   - Click "Add variable"
   - Add each variable from your `.env` file:
     - `SUPABASE_URL` = your Supabase URL
     - `SUPABASE_ANON_KEY` = your Supabase anon key
     - Any other secrets (Firebase keys, etc.)
   - ✅ Check "Secure" for sensitive values

---

### Step 5: Update the YAML Configuration

1. **Edit `codemagic.yaml`:**
   - Replace `YOUR_EMAIL_HERE@example.com` with your email
   - Replace `YOUR_API_KEY_NAME_HERE` with the name you gave in Step 3
   - Replace `YOUR_SUPABASE_URL` and `YOUR_SUPABASE_ANON_KEY` with variable names

2. **Commit and Push:**
   ```bash
   git add codemagic.yaml
   git commit -m "Add Codemagic iOS build configuration"
   git push
   ```

---

### Step 6: Start Your First Build

1. **In Codemagic:**
   - Go to your app
   - Select workflow: `ios-development-build`
   - Click "Start new build"
   - Select branch: `main` (or your current branch)
   - Click "Start build"

2. **Wait for Build (10-20 minutes):**
   - ☕ Grab a coffee
   - Watch the build logs in real-time
   - You'll get an email when it's done

---

### Step 7: Install on Your iPhone 15 Pro

#### Method A: Direct Install Link (Easiest)
1. **After build completes:**
   - Check your email for the build notification
   - Click "Install on device" link
   - **Open on your iPhone**
   - Tap "Install"

2. **Trust Developer Certificate:**
   - iPhone: Settings → General → VPN & Device Management
   - Find your Apple ID under "Developer App"
   - Tap → Trust

3. **Open the app!** 🎉

#### Method B: Download IPA and Install via Cable
1. **Download IPA:**
   - In Codemagic, go to Builds → Artifacts
   - Download the `.ipa` file

2. **Install with 3uTools or similar:**
   - Download 3uTools (free)
   - Connect iPhone via USB
   - Go to Apps → Import & Install
   - Select the `.ipa` file

---

## 🧪 Multi-User Testing Options

### Option 1: Build Android Version (EASIEST!)
- Android APKs can be shared freely
- No Apple Developer account needed
- Users just install the APK

**Run the Android workflow:**
```yaml
# Already included in your codemagic.yaml!
# Just run the "android-build" workflow
```

### Option 2: Each Tester Uses Their Own Apple ID (FREE)
- Each person signs up for Codemagic free account
- Each person builds with their own Apple ID
- Each installs on their own device
- ⚠️ Complex, not recommended

### Option 3: Upgrade to Paid Apple Developer ($99/year)
- Unlock Ad-Hoc distribution (100 devices)
- Unlock TestFlight (10,000 testers)
- Edit `codemagic.yaml` → use `ios-ad-hoc-build` workflow

---

## 🔧 Troubleshooting

### Build Fails: "No provisioning profile found"
- Go to Codemagic → Code signing
- Verify your Apple ID is connected
- Re-generate provisioning profiles

### App Won't Install: "Untrusted Developer"
- iPhone: Settings → General → VPN & Device Management
- Trust your developer certificate

### App Crashes on Launch
- Check environment variables are set correctly
- Check build logs for errors
- Verify `.env` file is properly created in build

### Build Times Out
- Free tier gets 500 minutes/month
- Each iOS build takes ~15-20 minutes
- ~25 builds per month on free tier

---

## 💰 Cost Breakdown

| Service | Cost | What You Get |
|---------|------|--------------|
| **Codemagic Free** | $0 | 500 min/month (~25 iOS builds) |
| **Codemagic Hobby** | $49/mo | 1000 min/month |
| **Apple Dev Free** | $0 | 1 device, 7-day expiry |
| **Apple Dev Paid** | $99/year | 100 devices, TestFlight, App Store |

---

## 🎯 Recommended Path for Multi-User Testing

1. **Today (FREE):**
   - Build iOS for your iPhone 15 Pro
   - Build Android APK for other testers
   - Share Android APK via Drive/email

2. **Later (When ready to scale):**
   - Upgrade to paid Apple Developer account ($99/year)
   - Use TestFlight for iOS distribution
   - Continue using Android for quick testing

---

## 📚 Useful Links

- [Codemagic Docs](https://docs.codemagic.io)
- [Flutter iOS Setup](https://docs.flutter.dev/deployment/ios)
- [Apple Developer Program](https://developer.apple.com/programs/)
- [TestFlight Guide](https://developer.apple.com/testflight/)

---

## 🆘 Need Help?

1. **Codemagic Support:**
   - In-app chat (bottom right)
   - support@codemagic.io

2. **Check Build Logs:**
   - Every error message is in the logs
   - Look for red text in the build output

3. **Common Issues:**
   - 90% of problems are environment variables
   - Check `.env` file is created correctly
   - Verify all secrets are added to Codemagic

---

## ✅ Success Checklist

- [ ] Apple account has two-factor auth enabled
- [ ] App-specific password generated
- [ ] Codemagic account created
- [ ] Repository connected to Codemagic
- [ ] Apple account connected in Codemagic
- [ ] Environment variables added
- [ ] `codemagic.yaml` updated with your info
- [ ] First build started
- [ ] IPA downloaded/install link received
- [ ] App installed on iPhone 15 Pro
- [ ] Developer certificate trusted
- [ ] App opens successfully!

---

**Good luck! 🚀 Your app will be on your iPhone 15 Pro soon!**
