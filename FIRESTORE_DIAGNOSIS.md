# 🔍 Firestore Connection Diagnosis

The app cannot write to Firestore. Let's diagnose the issue.

## Step 1: Check Browser Console for Errors

1. **Open the app** in Chrome with: `flutter run -d chrome`

2. **Open Developer Tools**: Press `F12`

3. **Go to Console tab**

4. **Look for RED errors** containing:
   - `@firebase/firestore`
   - `PERMISSION_DENIED`
   - `Missing or insufficient permissions`
   - `Failed to get document`
   - `Network error`

5. **Take a screenshot** of any errors

## Step 2: Check Network Tab

1. In Developer Tools, click **Network** tab

2. **Filter by**: `firestore.googleapis.com`

3. **Try signing up** with a new account

4. **Look for requests** to:
   - `firestore.googleapis.com/google.firestore.v1.Firestore/Write`
   - `firestore.googleapis.com/google.firestore.v1.Firestore/Commit`

5. **Click on the request** and check:
   - **Status**: Should be `200 OK` (NOT `403 Forbidden` or `400 Bad Request`)
   - **Response** tab: Look for error messages

## Step 3: Test Direct Firestore Write via Console

Run this in the browser console (F12 → Console tab):

```javascript
// Test Firestore connection
firebase.firestore().collection('test').add({
  message: 'Hello from console',
  timestamp: firebase.firestore.FieldValue.serverTimestamp()
}).then((docRef) => {
  console.log('✅ Firestore write SUCCESS! Document ID:', docRef.id);
}).catch((error) => {
  console.error('❌ Firestore write FAILED:', error);
  console.error('Error code:', error.code);
  console.error('Error message:', error.message);
});
```

**Expected results:**
- ✅ SUCCESS: `✅ Firestore write SUCCESS! Document ID: [some-id]`
- ❌ FAILURE: Check the error code:
  - `permission-denied` → Security rules are blocking
  - `unavailable` → Network/connection issue
  - `failed-precondition` → Firestore not properly initialized

## Step 4: Verify Security Rules in Firebase Console

1. Go to: https://console.firebase.google.com/project/silni-31811/firestore/rules

2. **Check if rules are published**:
   - Look for green checkmark and "Published" timestamp at top
   - If you see "Not published" warning, click **Publish**

3. **Verify rules match** this:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    match /users/{userId} {
      allow read: if isOwner(userId);
      allow create: if isAuthenticated() && request.auth.uid == userId;
      allow update: if isOwner(userId);
      allow delete: if false;
    }

    match /relatives/{relativeId} {
      allow read: if isAuthenticated() && resource.data.userId == request.auth.uid;
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      allow update: if isAuthenticated() && resource.data.userId == request.auth.uid;
      allow delete: if isAuthenticated() && resource.data.userId == request.auth.uid;
    }

    // ... other collections ...

    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

## Step 5: Check Firebase Project Settings

1. Go to: https://console.firebase.google.com/project/silni-31811/settings/general

2. **Verify**:
   - Project ID: `silni-31811` ✓
   - Web API Key exists
   - Firestore is listed under "Your apps"

3. Go to: https://console.firebase.google.com/project/silni-31811/firestore

4. **Verify database exists**:
   - Should show "Your database is ready to go"
   - Database location: `nam5` (North America)
   - NOT showing "Create database" button

## Step 6: Test with Temporary Open Rules

**WARNING**: This is ONLY for testing! Do NOT leave these rules deployed!

1. Go to Firestore Rules editor

2. **Temporarily replace** all rules with:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;  // ⚠️ INSECURE - FOR TESTING ONLY!
    }
  }
}
```

3. Click **Publish**

4. **Try signing up again** in the app

5. **If it works** → Security rules were the problem
   - Revert to secure rules immediately
   - Debug why secure rules aren't working

6. **If it still fails** → Problem is elsewhere (network, config, etc.)

## Common Issues & Solutions

### Issue: `permission-denied` in console

**Solution**: Security rules are too restrictive or not deployed
- Check Step 4 above
- Try Step 6 (temporary open rules)

### Issue: `unavailable` or network errors

**Solution**: Firestore not reachable
- Check internet connection
- Check if Firebase project is active (not paused/suspended)
- Try disabling VPN/proxy

### Issue: No errors but no data

**Solution**: Offline persistence caching writes locally
- Check browser's IndexedDB (DevTools → Application → IndexedDB → firebase)
- Data might be queued but not syncing

### Issue: Writes timeout after 30 seconds

**Solution**: Firestore connection slow or blocked
- Check Network tab for slow requests
- Try different network/browser
- Check Firebase status: https://status.firebase.google.com/

## Report Back

Please share:
1. Screenshot of browser console showing any errors
2. Screenshot of Network tab showing firestore requests (with status codes)
3. Result of the JavaScript console test (Step 3)
4. Whether temporary open rules work (Step 6)

This will help me identify the exact issue!
