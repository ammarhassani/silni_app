# 🚀 Push Notifications Deployment Checklist

Complete this checklist to fully deploy the push notification system.

---

## ✅ Phase 1: Database Setup (COMPLETED)

- [x] Run SQL schema in Supabase Dashboard
- [x] Verify 3 tables created: `notification_tokens`, `notification_history`, `admin_announcements`
- [x] Test RLS policies

---

## ✅ Phase 2: Flutter App Integration (COMPLETED)

### Environment & Dependencies
- [x] Update `.env` with Firebase credentials
- [x] Add `firebase_core` and `firebase_messaging` to `pubspec.yaml`
- [x] Run `flutter pub get`

### Android Configuration
- [x] Update `android/settings.gradle.kts` - Add Google Services plugin
- [x] Update `android/app/build.gradle.kts` - Apply plugin, set minSdk=21
- [x] Update `AndroidManifest.xml` - Add FCM permissions and service
- [x] Add `google-services.json` to `android/app/`

### iOS Configuration
- [x] Create `ios/Podfile` with iOS 13.0+
- [x] Update `ios/Runner/Info.plist` - Add background modes
- [x] Update `ios/Runner/Runner.entitlements` - Add aps-environment
- [x] Update `ios/Runner/AppDelegate.swift` - Initialize Firebase
- [x] Add `GoogleService-Info.plist` to `ios/Runner/`

### Flutter Services
- [x] Create `lib/shared/services/fcm_notification_service.dart`
- [x] Create `lib/shared/services/unified_notification_service.dart`
- [x] Update `lib/main.dart` - Initialize Firebase and notifications
- [x] Update `lib/shared/services/auth_service.dart` - Deactivate token on logout

### Git & Security
- [x] Add `*firebase-adminsdk*.json` to `.gitignore`
- [x] Remove Firebase service account JSON from git history
- [x] Push to GitHub successfully

---

## 🔄 Phase 3: Supabase Edge Functions (COMPLETED - PENDING DEPLOYMENT)

### Edge Functions Created
- [x] `send-push-notification/index.ts` - Core FCM sender
- [x] `check-streak-alerts/index.ts` - Daily streak alerts cron
- [x] `send-scheduled-reminders/index.ts` - Hourly reminders cron
- [x] `send-scheduled-announcements/index.ts` - Admin announcements cron
- [x] `README.md` - Deployment documentation

---

## 📋 TODO: Deploy Edge Functions to Supabase

### Step 1: Go to Supabase Dashboard
1. Open https://supabase.com/dashboard
2. Select project: **Silni Staging** (`dqqyhmydodjpqboykzow`)
3. Go to **Edge Functions**

### Step 2: Deploy Functions (Do this for each function)

**For each function below, click "New Function" and paste the code:**

1. **send-push-notification**
   - Name: `send-push-notification`
   - Code: Copy from `supabase/functions/send-push-notification/index.ts`
   - Click "Deploy"

2. **check-streak-alerts**
   - Name: `check-streak-alerts`
   - Code: Copy from `supabase/functions/check-streak-alerts/index.ts`
   - Click "Deploy"

3. **send-scheduled-reminders**
   - Name: `send-scheduled-reminders`
   - Code: Copy from `supabase/functions/send-scheduled-reminders/index.ts`
   - Click "Deploy"

4. **send-scheduled-announcements**
   - Name: `send-scheduled-announcements`
   - Code: Copy from `supabase/functions/send-scheduled-announcements/index.ts`
   - Click "Deploy"

### Step 3: Configure Secrets

Go to: **Project Settings → Edge Functions → Secrets**

Add these 3 secrets (click "Add secret" for each):

```
Name: FIREBASE_SERVICE_ACCOUNT
Value: <paste_from_local_.env_line_37>

Name: SUPABASE_SERVICE_ROLE_KEY
Value: <paste_from_local_.env_line_41>

Name: SUPABASE_URL
Value: https://dqqyhmydodjpqboykzow.supabase.co
```

**To get FIREBASE_SERVICE_ACCOUNT:**
1. Open your local `.env` file (c:\Users\A\Desktop\silni-app\silni_app\.env)
2. Copy the entire JSON value from line 37 (starts with `{"type":"service_account"...`)
3. Paste as the secret value

**To get SUPABASE_SERVICE_ROLE_KEY:**
1. Open your local `.env` file
2. Copy the value from line 41
3. Paste as the secret value

### Step 4: Set Up Cron Jobs

For each cron function, go to **Edge Functions → [Function Name] → Cron Jobs**:

1. **check-streak-alerts**
   - Click "Add cron job"
   - Expression: `0 18 * * *`
   - Description: "Daily at 9 PM Riyadh (6 PM UTC)"
   - Save

2. **send-scheduled-reminders**
   - Click "Add cron job"
   - Expression: `0 * * * *`
   - Description: "Every hour"
   - Save

3. **send-scheduled-announcements**
   - Click "Add cron job"
   - Expression: `*/15 * * * *`
   - Description: "Every 15 minutes"
   - Save

---

## 🧪 Testing After Deployment

### Test 1: Manual Push Notification

In Supabase Dashboard → Edge Functions → `send-push-notification` → Test

Request body:
```json
{
  "userId": "your-user-uuid-from-users-table",
  "notificationType": "announcement",
  "title": "Test Notification",
  "body": "If you see this, FCM works! 🎉"
}
```

Click "Run" → Should see "Notification sent to X device(s)"

### Test 2: Check Database

Go to **Table Editor → notification_history**
- Should see the test notification logged

Go to **Table Editor → notification_tokens**
- Should see your device token with `is_active = true`

### Test 3: Cron Jobs (Manual Trigger)

Go to each cron function → Click "Invoke"
- Should see logs showing execution
- Check if notifications are sent based on data in database

---

## 📱 End-to-End Testing

Once TestFlight build is ready:

1. **Install on iPhone**
   - Grant notification permissions when prompted

2. **Verify Token Stored**
   - Go to Supabase → `notification_tokens` table
   - Should see new row with `platform='ios'`

3. **Send Test Notification**
   - Use send-push-notification Edge Function
   - Should receive notification on iPhone

4. **Test Navigation**
   - Tap notification
   - Should navigate to correct screen in app

---

## 🎯 Phase 4: Admin Panel (OPTIONAL - Can be done later)

Create Flutter admin screen for announcements:

- [ ] Create `lib/features/admin/screens/admin_announcements_screen.dart`
- [ ] Add navigation from Settings (conditional on user role)
- [ ] Implement announcement creation form
- [ ] Test scheduled announcements

---

## ✅ Final Verification

- [ ] iOS app receives FCM token on launch
- [ ] Token stored in Supabase with correct platform
- [ ] Manual test notification received on device
- [ ] Streak alerts working (test by simulating endangered streak)
- [ ] Scheduled reminders working (test with near-future schedule)
- [ ] Admin announcements working (create test announcement)
- [ ] Logout deactivates FCM token
- [ ] Re-login creates new active token

---

## 📊 Monitoring

### Check Logs:
- Supabase Dashboard → Edge Functions → [Function] → Logs
- Firebase Console → Cloud Messaging → Logs

### Check Tables:
- `notification_tokens` - Active device tokens
- `notification_history` - Sent notification records
- `admin_announcements` - Admin notifications

---

## 🎉 Success Criteria

✅ iOS TestFlight build installs successfully
✅ FCM token obtained and stored in Supabase
✅ Manual test notification received on device
✅ Notification tap navigates to correct screen
✅ All 4 Edge Functions deployed successfully
✅ Cron jobs scheduled and running
✅ No errors in Edge Function logs

---

**Current Status:** Phase 3 Complete - Ready for Deployment
**Next Action:** Deploy Edge Functions to Supabase Dashboard
**Estimated Time:** 15-20 minutes

---

## 📞 Need Help?

- Edge Functions not deploying? Check function code for syntax errors
- Secrets not working? Verify JSON is properly escaped (use online JSON validator)
- Cron not running? Wait up to 1 hour after deployment, or invoke manually
- Notifications not received? Check FCM token exists and Firebase Console logs
