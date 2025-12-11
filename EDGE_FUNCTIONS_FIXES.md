# Edge Functions Deployment Fixes

## Issues Found from Test Results:

1. ❌ **reminder_schedules table missing** - Database relationship error
2. ❌ **Authentication errors** - "Invalid JWT" when functions call each other
3. ⚠️ **Cron jobs** - No UI for scheduling in your Supabase version

---

## Fix 1: Database Schema (reminder_schedules table)

**Error:** `Could not find a relationship between 'reminder_schedules' and 'relatives'`

### Solution:
1. Go to Supabase Dashboard → SQL Editor
2. Copy and paste the SQL from `supabase/sql/fix-reminder-schedules.sql`
3. Run the query
4. You should see: ✅ reminder_schedules table created successfully

This creates the missing table with proper foreign key relationships to the `relatives` table.

---

## Fix 2: Authentication Error

**Error:** `{"code":401,"message":"Invalid JWT"}`

This happens when Edge Functions try to call each other. The issue is that `SUPABASE_SERVICE_ROLE_KEY` might not be set correctly.

### Verify Your Secrets:

1. Go to Supabase Dashboard → Project Settings → Edge Functions → Secrets
2. Click on `SUPABASE_SERVICE_ROLE_KEY` to view/edit
3. Make sure it's set to this EXACT value:

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxcXlobXlkb2RqcHFib3lrem93Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NDA5NDUzNSwiZXhwIjoyMDc5NjcwNTM1fQ.8oJqcKGQ5RtsFfBXed49kR14TlEELnxaW5oDz1WCeDo
```

4. Save the secret
5. Restart all Edge Functions (or wait a few minutes for them to reload)

### Alternative: Check for duplicate/wrong secrets

In your screenshot, I see both:
- `SUPABASE_SERVICE_ROLE_KEY` ✅ (correct name)
- `SERVICE_ROLE_KEY` (duplicate?)
- `URL` (duplicate?)

Make sure the functions are using the correctly named secrets:
- `FIREBASE_SERVICE_ACCOUNT`
- `SUPABASE_SERVICE_ROLE_KEY` (not SERVICE_ROLE_KEY)
- `SUPABASE_URL` (not URL)

---

## Fix 3: Cron Jobs (No Dashboard UI)

Since your Supabase version doesn't have a cron job UI, you have **2 options**:

### Option A: Manual Invocation (Testing Only)
For now, you can manually invoke the functions to test them:

1. Go to Edge Functions → Select function
2. Click "Invoke" or "Test"
3. Click "Run"

This will trigger the function manually. Good for testing, but not for production.

### Option B: External Cron Service (Production)

Use a free service like **cron-job.org** or **EasyCron** to call your Edge Functions on schedule:

**For check-streak-alerts (daily at 9 PM Riyadh = 6 PM UTC):**
- URL: `https://dqqyhmydodjpqboykzow.supabase.co/functions/v1/check-streak-alerts`
- Method: POST
- Schedule: Daily at 18:00 UTC
- Headers:
  ```
  Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
  Content-Type: application/json
  ```

**For send-scheduled-reminders (every hour):**
- URL: `https://dqqyhmydodjpqboykzow.supabase.co/functions/v1/send-scheduled-reminders`
- Method: POST
- Schedule: Every hour
- Same headers as above

**For send-scheduled-announcements (every 15 minutes):**
- URL: `https://dqqyhmydodjpqboykzow.supabase.co/functions/v1/send-scheduled-announcements`
- Method: POST
- Schedule: Every 15 minutes
- Same headers as above

### Option C: Wait for Supabase Update

Supabase is rolling out native cron job support. You might get it in a future update. For now, use Option B for production.

---

## Testing After Fixes

### Step 1: Fix Database
```sql
-- Run the fix-reminder-schedules.sql file in SQL Editor
```

### Step 2: Verify Secrets
- Check SUPABASE_SERVICE_ROLE_KEY is correct
- Remove duplicate secrets if any

### Step 3: Test Each Function

**Test send-push-notification:**
1. Get a real user ID from your `users` table
2. Get a real FCM token from `notification_tokens` table
3. Test with this body:

```json
{
  "userId": "your-real-user-uuid",
  "notificationType": "announcement",
  "title": "اختبار الإشعارات",
  "body": "هذا إشعار تجريبي"
}
```

**Expected result:** ✅ 200 OK, notification sent to X device(s)

**Test check-streak-alerts:**
1. Make sure you have users with `current_streak > 0` in the `users` table
2. Invoke the function (no body needed)
3. Check logs for: "📊 Streak check complete: X alerts sent"

**Expected result:** ✅ 200 OK, if users haven't interacted today, they get alerts

**Test send-scheduled-reminders:**
1. First, create a test reminder schedule:

```sql
-- Get your user ID and a relative ID from the database
INSERT INTO reminder_schedules (user_id, relative_id, frequency, notification_hour, is_active)
VALUES (
  'your-user-uuid',
  'your-relative-uuid',
  'daily',
  20, -- Current hour in Riyadh (adjust to current time for testing)
  true
);
```

2. Invoke the function
3. Check logs for: "📊 Reminder check complete: X sent"

**Expected result:** ✅ 200 OK, reminders sent for matching hour

**Test send-scheduled-announcements:**
1. Create a test announcement:

```sql
INSERT INTO admin_announcements (title, body, status, scheduled_for, target_users)
VALUES (
  'إعلان تجريبي',
  'هذا إعلان للاختبار',
  'scheduled',
  now(), -- Send now
  'all'
);
```

2. Invoke the function
3. Check logs for: "📊 Announcement check complete: 1 sent"

**Expected result:** ✅ 200 OK, announcement sent

---

## Success Criteria

After applying all fixes:

- ✅ `reminder_schedules` table exists with foreign key to `relatives`
- ✅ All Edge Functions return 200 (no 401 or 500 errors)
- ✅ `send-push-notification` can be called by other functions
- ✅ Notifications logged in `notification_history` table
- ✅ Cron jobs scheduled (via external service if no Dashboard UI)

---

## Current Status

Based on your test results:
- ✅ `send-scheduled-announcements` - Working (no pending announcements)
- ✅ `check-streak-alerts` - Working but can't send notifications (401 error when calling send-push-notification)
- ❌ `send-scheduled-reminders` - Database error (table missing)
- ❌ `send-push-notification` - 401 auth errors when called by other functions

**Next Steps:**
1. Run the SQL fix for reminder_schedules
2. Verify SUPABASE_SERVICE_ROLE_KEY secret
3. Re-test all functions
4. Set up external cron service for production scheduling
