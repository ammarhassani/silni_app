# 🔧 Troubleshooting Guide - Data Persistence Issues

## 🚨 Critical Issues Identified

### Issue 1: Firestore Indexes Not Deployed

**Symptom**: Slow queries, query timeouts, empty data after login

**Root Cause**: Firestore composite indexes haven't been deployed to Firebase

**Solution**:

#### Option A: Using Firebase CLI (Recommended)

1. **Install Firebase CLI**:
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**:
   ```bash
   firebase login
   ```

3. **Initialize Firebase (if not done)**:
   ```bash
   cd c:\Users\A\Desktop\silni-app\silni_app
   firebase init
   ```
   - Select "Firestore" when prompted
   - Use existing project: `silni-31811`
   - Keep default files

4. **Deploy indexes**:
   ```bash
   firebase deploy --only firestore:indexes
   ```

5. **Wait for indexes to build** (5-10 minutes):
   - Check status: https://console.firebase.google.com/project/silni-31811/firestore/indexes
   - All indexes should show "Enabled" status

#### Option B: Manual Index Creation via Firebase Console

If you can't install Firebase CLI, create indexes manually:

1. Go to: https://console.firebase.google.com/project/silni-31811/firestore/indexes

2. **Create Index #1** (Relatives - Main Query):
   - Collection ID: `relatives`
   - Fields:
     - `userId` - Ascending
     - `isArchived` - Ascending
     - `priority` - Ascending
     - `fullName` - Ascending
   - Query scope: Collection
   - Click "Create Index"

3. **Create Index #2** (Relatives - Favorites):
   - Collection ID: `relatives`
   - Fields:
     - `userId` - Ascending
     - `isArchived` - Ascending
     - `isFavorite` - Descending
     - `lastContactDate` - Descending
   - Click "Create Index"

4. **Create Index #3** (Interactions by User):
   - Collection ID: `interactions`
   - Fields:
     - `userId` - Ascending
     - `date` - Descending
   - Click "Create Index"

5. **Create Index #4** (Interactions by Relative):
   - Collection ID: `interactions`
   - Fields:
     - `relativeId` - Ascending
     - `date` - Descending
   - Click "Create Index"

6. **Create Index #5** (Interactions by Type):
   - Collection ID: `interactions`
   - Fields:
     - `userId` - Ascending
     - `type` - Ascending
     - `date` - Descending
   - Click "Create Index"

7. **Create Index #6** (Reminders by User):
   - Collection ID: `reminders`
   - Fields:
     - `userId` - Ascending
     - `isActive` - Ascending
     - `nextReminderDate` - Ascending
   - Click "Create Index"

8. **Create Index #7** (Reminders by Relative):
   - Collection ID: `reminders`
   - Fields:
     - `relativeId` - Ascending
     - `isActive` - Ascending
     - `nextReminderDate` - Ascending
   - Click "Create Index"

**Wait 5-10 minutes for all indexes to build before testing the app again.**

---

### Issue 2: Firestore Security Rules Not Deployed

**Symptom**: Permission denied errors, can't read/write data

**Root Cause**: Default Firestore rules block all access after 30 days

**Solution**:

#### Option A: Using Firebase CLI

```bash
firebase deploy --only firestore:rules
```

#### Option B: Manual Rule Update via Firebase Console

1. Go to: https://console.firebase.google.com/project/silni-31811/firestore/rules

2. Click "Edit Rules"

3. Copy the entire content from `firestore.rules` file in your project

4. Paste into the editor

5. Click "Publish"

6. Verify rules are published successfully

---

### Issue 3: Theme Not Persisting Across Sessions

**Current Behavior**: Theme preference uses SharedPreferences (local browser storage only)

**Issue**: Theme is not synced to Firestore user document

**Temporary Workaround**: Theme will persist per device, but not across devices

**Future Fix Needed**: Sync theme to Firestore user document for cross-device consistency

---

### Issue 4: User Document Creation May Fail Silently

**Symptom**: Login works but no relatives/data loads

**Root Cause**: If Firestore rules aren't deployed, user document creation fails during signup

**Solution**:

1. **Deploy Firestore rules** (see Issue 2 above)

2. **Check if your user document exists**:
   - Go to: https://console.firebase.google.com/project/silni-31811/firestore/data
   - Navigate to `users` collection
   - Look for document with your user ID
   - If missing, you need to recreate it

3. **Manually create missing user document**:
   - Click "Add document"
   - Document ID: (your Firebase Auth UID)
   - Add fields:
     ```
     id: (your UID)
     email: (your email)
     fullName: (your name)
     phoneNumber: null
     profilePictureUrl: null
     createdAt: (timestamp - now)
     lastLoginAt: (timestamp - now)
     emailVerified: false
     subscriptionStatus: "free"
     language: "ar"
     notificationsEnabled: true
     reminderTime: "09:00"
     theme: "light"
     totalInteractions: 0
     currentStreak: 0
     longestStreak: 0
     points: 0
     level: 1
     badges: []
     dataExportRequested: false
     accountDeletionRequested: false
     ```

---

### Issue 5: Relatives Not Loading

**Symptom**: Added relatives don't appear after page refresh

**Possible Causes**:
1. Missing Firestore indexes (see Issue 1)
2. Security rules blocking access (see Issue 2)
3. Query error in console

**Debug Steps**:

1. **Open browser console** (F12)

2. **Look for these messages**:
   - ✅ Good: `📊 [RELATIVES] Received X relatives from Firestore`
   - ❌ Bad: `❌ [RELATIVES] Error streaming relatives: [error]`
   - ⚠️ Warning: `Missing index` error

3. **Check Firestore data directly**:
   - Go to: https://console.firebase.google.com/project/silni-31811/firestore/data
   - Navigate to `relatives` collection
   - Verify documents exist with your `userId`
   - Check `isArchived` field is `false`

4. **Verify query is working**:
   - In Firestore console, try filtering:
     - Collection: `relatives`
     - Where: `userId == (your UID)`
     - Where: `isArchived == false`
   - If no results, data wasn't saved properly

---

## 🔍 Step-by-Step Testing Procedure

After deploying indexes and rules:

### 1. Clear All Data (Fresh Start)

```bash
# In browser console (F12)
localStorage.clear();
sessionStorage.clear();
# Then refresh page
```

### 2. Sign Out and Sign In Again

This ensures fresh authentication tokens and proper data loading

### 3. Check Console Output

Look for these success messages:
- `✅ Firebase user created` or `✅ Firebase auth successful`
- `✅ User document created successfully`
- `📡 [RELATIVES] Streaming relatives for user: [UID]`
- `📊 [RELATIVES] Received X relatives from Firestore`

### 4. Test Adding a Relative

1. Add a new relative
2. Check console for: `✅ [RELATIVES] Created relative with ID: [ID]`
3. Verify it appears in the UI immediately
4. Refresh the page
5. Verify it still appears (this tests persistence)

### 5. Test Theme Change

1. Go to Profile → Theme Settings
2. Change theme
3. Refresh page
4. Theme should persist (for current device)

---

## 🎯 Quick Fix Commands

Run these commands to fix the most common issues:

```bash
# Navigate to project directory
cd c:\Users\A\Desktop\silni-app\silni_app

# Deploy everything at once
firebase deploy --only firestore

# Or deploy individually
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes

# Check deployment status
firebase deploy --only firestore:indexes --debug
```

---

## 📞 Still Having Issues?

### Check Firebase Console Logs

1. Go to: https://console.firebase.google.com/project/silni-31811/overview
2. Click "Functions" (if you have any) or "Firestore" → "Usage"
3. Look for error messages or failed requests

### Enable Firestore Debug Mode

Add this to your browser console:
```javascript
firebase.firestore.setLogLevel('debug');
```

### Check Network Tab

1. Open DevTools (F12) → Network tab
2. Filter by "firestore.googleapis.com"
3. Look for failed requests (red)
4. Click on them to see error details

### Verify User Authentication

In browser console:
```javascript
firebase.auth().currentUser
```

Should return user object with `uid`, `email`, `displayName`

---

## ✅ Final Checklist

Before considering the issues resolved, verify:

- [ ] Firebase CLI installed and logged in
- [ ] Firestore indexes deployed and showing "Enabled" in console
- [ ] Firestore security rules deployed successfully
- [ ] User document exists in Firestore `users` collection
- [ ] Can add relatives and they persist after refresh
- [ ] Console shows no "Missing index" or "Permission denied" errors
- [ ] Theme preference persists across sessions (same device)
- [ ] All queries complete in <100ms (check Network tab)

---

## 🆘 Emergency Recovery

If all else fails:

1. **Backup any important data** from Firestore console

2. **Delete and recreate user account**:
   - Delete user from Firebase Console → Authentication
   - Sign up again with same email
   - Check console for "✅ User document created successfully"

3. **Manually verify indexes exist**:
   - Firestore Console → Indexes
   - Should see 7 composite indexes all showing "Enabled"

4. **Contact Firebase Support**:
   - https://firebase.google.com/support
   - Provide project ID: `silni-31811`
   - Share console error messages
