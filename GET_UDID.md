# How to Get Your iPhone UDID and Fix the Build

The "No matching profiles" error means Codemagic doesn't know about your iPhone 15 Pro yet.

## Get Your iPhone UDID (2 minutes):

### Option 1: Using iTunes/Finder (Easiest)
1. Connect iPhone to your PC via USB
2. Open iTunes (Windows) or Finder (Mac)
3. Click on your iPhone
4. Click on the text that shows "Serial Number"
5. It will change to show "UDID"
6. Right-click → Copy

### Option 2: Using a Website
1. On your iPhone, go to: https://get.udid.io/
2. Tap "Download Profile"
3. Install the profile
4. Your UDID will be shown - copy it

---

## Add UDID to Codemagic:

1. Go to Codemagic dashboard
2. Click on your app
3. Go to "Distribution" → "iOS code signing"
4. Click "Add device"
5. Paste your UDID
6. Give it a name: "My iPhone 15 Pro"
7. Save

---

## Then Rebuild:

1. Go back to your build
2. Click "Start new build"
3. Codemagic will now create a provisioning profile that includes your device

---

## Still Not Working?

**Honestly, just use Android for testing:**

```bash
# In Codemagic, run the "android-build" workflow instead
# You'll get an APK you can share with anyone
# No UDID, no provisioning profiles, no Apple BS
```

Share the APK via email/Drive/whatever. Way easier.

---

## OR: Just Pay Apple $99/Year

Seriously, if you need iOS testing, the $99 Apple Developer account removes ALL of these headaches:
- No 7-day expiry
- TestFlight for 10,000 testers
- Ad-Hoc distribution to 100 devices
- No UDID management pain

Free Apple account = pain for iOS distribution.
