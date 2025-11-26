# 🔧 FIX SIGNUP ERROR - INSTRUCTIONS

## What This Fixes
The RLS error when signing up: `new row violates row-level security policy for table "users"`

## How To Fix It

### Step 1: Go to Supabase Dashboard
1. Open: https://supabase.com/dashboard/project/dqqyhmydodjpqboykzow (STAGING)
2. Click **SQL Editor** in the left sidebar

### Step 2: Run the SQL Script
1. Click **"New query"**
2. Open the file: `fix_user_signup_trigger.sql`
3. **Copy the ENTIRE contents** and paste into the SQL editor
4. Click **"Run"** (or press Ctrl+Enter)

### Step 3: Verify Success
You should see output like:
```
✅ Created trigger function: handle_new_user()
✅ Created trigger: on_auth_user_created
✅ Cleaned up conflicting policies
✅ Created 3 new policies (SELECT, UPDATE, DELETE)
✅ Cleaned up test users
```

And a table showing 3 policies:
- users_can_view_own_profile (SELECT)
- users_can_update_own_profile (UPDATE)
- users_can_delete_own_profile (DELETE)

### Step 4: Test Signup
1. **Restart your Flutter app** (hot reload won't work, need full restart)
2. Try signing up with **any email** (even ones you used before - they were deleted)
3. It should work instantly! ✅

## What Changed

**Before:**
- App manually inserted user profile → RLS blocked it

**After:**
- Database trigger automatically creates profile when auth user is created
- Trigger uses `SECURITY DEFINER` → bypasses RLS
- App just calls `signUp()` → everything works

## Troubleshooting

### If you still get RLS error:
1. Check you ran the SQL in **STAGING** database (not production)
2. Restart the Flutter app completely (stop and run again)
3. Try a fresh email address

### If signup succeeds but user not in database:
1. Go to Supabase Dashboard → Authentication → Users
2. Check if user exists there
3. Go to Table Editor → users table
4. You should see the user profile automatically created
