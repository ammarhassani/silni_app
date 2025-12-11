# Supabase Edge Functions for Push Notifications

This directory contains Supabase Edge Functions that power the server-side push notification system using Firebase Cloud Messaging (FCM).

## 📋 Functions Overview

### 1. `send-push-notification`
**Type:** HTTP Function (callable from app/other functions)
**Purpose:** Core FCM sender - sends push notifications to user's devices

**Usage:**
```typescript
const response = await fetch(`${SUPABASE_URL}/functions/v1/send-push-notification`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${SUPABASE_ANON_KEY}`
  },
  body: JSON.stringify({
    userId: 'user-uuid',
    notificationType: 'reminder', // reminder | streak | achievement | announcement
    title: 'Notification title',
    body: 'Notification body',
    data: { key: 'value' } // optional
  })
});
```

### 2. `check-streak-alerts`
**Type:** Cron Job
**Schedule:** Daily at 9 PM Riyadh time (6 PM UTC)
**Purpose:** Checks for users with endangered streaks and sends alerts

**Cron expression:** `0 18 * * *`

### 3. `send-scheduled-reminders`
**Type:** Cron Job
**Schedule:** Every hour
**Purpose:** Sends reminders based on `reminder_schedules` table

**Cron expression:** `0 * * * *`

### 4. `send-scheduled-announcements`
**Type:** Cron Job
**Schedule:** Every 15 minutes
**Purpose:** Sends scheduled admin announcements from `admin_announcements` table

**Cron expression:** `*/15 * * * *`

---

## 🚀 Deployment Instructions

### Option 1: Deploy via Supabase Dashboard (Recommended if no CLI)

1. **Go to Supabase Dashboard:**
   - Navigate to https://supabase.com/dashboard
   - Select your project (staging)

2. **Create Each Function:**

   **For `send-push-notification`:**
   - Go to Edge Functions → New Function
   - Name: `send-push-notification`
   - Copy contents of `send-push-notification/index.ts`
   - Paste into editor
   - Click "Deploy"

   **Repeat for:**
   - `check-streak-alerts`
   - `send-scheduled-reminders`
   - `send-scheduled-announcements`

3. **Configure Environment Secrets:**

   Go to Project Settings → Edge Functions → Secrets

   Add these secrets:
   ```
   FIREBASE_SERVICE_ACCOUNT=<paste_firebase_service_account_json>
   SUPABASE_SERVICE_ROLE_KEY=<paste_service_role_key>
   SUPABASE_URL=https://dqqyhmydodjpqboykzow.supabase.co
   ```

4. **Set Up Cron Jobs:**

   Go to Dashboard → Edge Functions → Select function → Cron Jobs

   - `check-streak-alerts`: `0 18 * * *` (daily at 6 PM UTC = 9 PM Riyadh)
   - `send-scheduled-reminders`: `0 * * * *` (every hour)
   - `send-scheduled-announcements`: `*/15 * * * *` (every 15 minutes)

### Option 2: Deploy via Supabase CLI

```bash
# Install Supabase CLI
npm install -g supabase

# Login
supabase login

# Link to your project
supabase link --project-ref dqqyhmydodjpqboykzow

# Set secrets
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat path/to/firebase-service-account.json)"
supabase secrets set SUPABASE_SERVICE_ROLE_KEY="your-service-role-key"
supabase secrets set SUPABASE_URL="https://dqqyhmydodjpqboykzow.supabase.co"

# Deploy all functions
supabase functions deploy

# Or deploy individually
supabase functions deploy send-push-notification
supabase functions deploy check-streak-alerts
supabase functions deploy send-scheduled-reminders
supabase functions deploy send-scheduled-announcements
```

---

## 🔐 Required Secrets

These must be configured in Supabase Dashboard → Edge Functions → Secrets:

| Secret Name | Description | Where to Get |
|-------------|-------------|--------------|
| `FIREBASE_SERVICE_ACCOUNT` | Firebase service account JSON (minified) | From your local `.env` file |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service role key | Supabase Dashboard → Settings → API → service_role (secret) |
| `SUPABASE_URL` | Your Supabase project URL | `https://dqqyhmydodjpqboykzow.supabase.co` |

**To get FIREBASE_SERVICE_ACCOUNT from .env:**
```bash
# From your .env file, copy the value of FIREBASE_SERVICE_ACCOUNT
# It should be a minified JSON string (no newlines)
```

---

## 📊 Testing Edge Functions

### Test via Dashboard:
1. Go to Edge Functions → Select function
2. Click "Test"
3. Enter request body (for HTTP functions)
4. Click "Run"

### Test via API:
```bash
# Test send-push-notification
curl -X POST https://dqqyhmydodjpqboykzow.supabase.co/functions/v1/send-push-notification \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -d '{
    "userId": "user-uuid",
    "notificationType": "announcement",
    "title": "Test Notification",
    "body": "This is a test"
  }'

# Test cron jobs (invoke manually)
curl -X POST https://dqqyhmydodjpqboykzow.supabase.co/functions/v1/check-streak-alerts \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY"
```

---

## 📝 Notification Types

| Type | Description | Data Fields |
|------|-------------|-------------|
| `reminder` | Relative reminder | `relative_id`, `schedule_id`, `frequency` |
| `streak` | Endangered streak alert | `streak_count` |
| `achievement` | Badge/achievement unlock | `badge_id`, `badge_name` |
| `announcement` | Admin announcement | `announcement_id`, custom fields |

---

## 🔧 Troubleshooting

### Function not receiving requests:
- Check secrets are configured correctly
- Verify CORS settings if calling from web
- Check function logs in Dashboard → Edge Functions → Logs

### FCM notifications not sending:
- Verify Firebase service account JSON is correct
- Check FCM tokens exist in `notification_tokens` table
- Verify APNs key is uploaded to Firebase Console (for iOS)
- Check Firebase Console → Cloud Messaging → Logs

### Cron jobs not running:
- Verify cron expression is correct
- Check function logs for errors
- Ensure function is deployed successfully
- Cron jobs may take up to 1 hour to start after deployment

---

## 📖 Additional Resources

- [Supabase Edge Functions Docs](https://supabase.com/docs/guides/functions)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Cron Expression Syntax](https://crontab.guru/)

---

## 🎯 Next Steps After Deployment

1. ✅ Deploy all 4 functions
2. ✅ Configure secrets
3. ✅ Set up cron jobs
4. ✅ Test send-push-notification manually
5. ✅ Verify tokens are being stored in `notification_tokens` table
6. ✅ Wait for cron jobs to run (or invoke manually to test)
7. ✅ Check notification_history table for sent notifications
8. ✅ Implement admin panel in Flutter app (Phase 4)

---

**Deployment Status:** 🟡 Pending Deployment
**Last Updated:** 2025-12-10
