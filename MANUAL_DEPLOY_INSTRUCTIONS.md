# 🔧 Manual Deployment Instructions

Since Firebase CLI is having issues detecting your existing Firestore database, follow these steps to manually deploy rules and indexes through the Firebase Console.

## ✅ Step 1: Deploy Security Rules (CRITICAL - Do This First!)

1. **Open Firestore Rules Editor**:
   - Go to: https://console.firebase.google.com/project/silni-31811/firestore/rules

2. **Clear existing rules** and paste the following:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // ==================== HELPER FUNCTIONS ====================

    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    function isPremium() {
      return isAuthenticated() &&
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.subscriptionStatus == 'premium';
    }

    function isValidEmail(email) {
      return email.matches('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$');
    }

    function isValidPhone(phone) {
      return phone == null || phone.matches('^(\\+966|00966|0)?5[0-9]{8}$');
    }

    // ==================== USERS COLLECTION ====================

    match /users/{userId} {
      allow read: if isOwner(userId);

      allow create: if isAuthenticated() &&
                      request.auth.uid == userId &&
                      request.resource.data.email is string &&
                      isValidEmail(request.resource.data.email) &&
                      request.resource.data.fullName is string &&
                      request.resource.data.fullName.size() >= 2 &&
                      request.resource.data.fullName.size() <= 100 &&
                      isValidPhone(request.resource.data.get('phoneNumber', null));

      allow update: if isOwner(userId) &&
                      request.resource.data.id == resource.data.id &&
                      request.resource.data.email == resource.data.email &&
                      request.resource.data.createdAt == resource.data.createdAt;

      allow delete: if false;
    }

    // ==================== RELATIVES COLLECTION ====================

    match /relatives/{relativeId} {
      allow read: if isAuthenticated() &&
                    resource.data.userId == request.auth.uid;

      allow create: if isAuthenticated() &&
                      request.resource.data.userId == request.auth.uid &&
                      request.resource.data.fullName is string &&
                      request.resource.data.fullName.size() >= 2 &&
                      request.resource.data.fullName.size() <= 100 &&
                      request.resource.data.relationshipType is string &&
                      request.resource.data.relationshipType in [
                        'father', 'mother', 'brother', 'sister',
                        'son', 'daughter', 'grandfather', 'grandmother',
                        'uncle', 'aunt', 'nephew', 'niece',
                        'cousin', 'husband', 'wife', 'other'
                      ] &&
                      request.resource.data.priority is int &&
                      request.resource.data.priority >= 1 &&
                      request.resource.data.priority <= 3;

      allow update: if isAuthenticated() &&
                      resource.data.userId == request.auth.uid &&
                      request.resource.data.userId == resource.data.userId &&
                      request.resource.data.createdAt == resource.data.createdAt;

      allow delete: if isAuthenticated() &&
                      resource.data.userId == request.auth.uid;
    }

    // ==================== INTERACTIONS COLLECTION ====================

    match /interactions/{interactionId} {
      allow read: if isAuthenticated() &&
                    resource.data.userId == request.auth.uid;

      allow create: if isAuthenticated() &&
                      request.resource.data.userId == request.auth.uid &&
                      request.resource.data.relativeId is string &&
                      request.resource.data.type is string &&
                      request.resource.data.type in [
                        'call', 'visit', 'message', 'gift', 'event', 'other'
                      ] &&
                      request.resource.data.date is timestamp &&
                      (request.resource.data.get('photoUrls', []).size() == 0 || isPremium());

      allow update: if isAuthenticated() &&
                      resource.data.userId == request.auth.uid &&
                      request.resource.data.userId == resource.data.userId &&
                      request.resource.data.relativeId == resource.data.relativeId &&
                      request.resource.data.createdAt == resource.data.createdAt;

      allow delete: if isAuthenticated() &&
                      resource.data.userId == request.auth.uid;
    }

    // ==================== REMINDERS COLLECTION ====================

    match /reminders/{reminderId} {
      allow read: if isAuthenticated() &&
                    resource.data.userId == request.auth.uid;

      allow create: if isAuthenticated() &&
                      request.resource.data.userId == request.auth.uid &&
                      request.resource.data.relativeId is string &&
                      request.resource.data.frequency is string &&
                      request.resource.data.frequency in [
                        'daily', 'weekly', 'biweekly', 'monthly', 'custom'
                      ] &&
                      request.resource.data.nextReminderDate is timestamp &&
                      request.resource.data.isActive is bool;

      allow update: if isAuthenticated() &&
                      resource.data.userId == request.auth.uid &&
                      request.resource.data.userId == resource.data.userId &&
                      request.resource.data.relativeId == resource.data.relativeId &&
                      request.resource.data.createdAt == resource.data.createdAt;

      allow delete: if isAuthenticated() &&
                      resource.data.userId == request.auth.uid;
    }

    // ==================== ACHIEVEMENTS COLLECTION ====================

    match /achievements/{achievementId} {
      allow read: if true;
      allow write: if false;
    }

    match /userAchievements/{userAchievementId} {
      allow read: if isAuthenticated() &&
                    resource.data.userId == request.auth.uid;
      allow write: if false;
    }

    // ==================== STATISTICS COLLECTION ====================

    match /statistics/{userId} {
      allow read: if isOwner(userId);
      allow write: if false;
    }

    // ==================== EDUCATIONAL CONTENT ====================

    match /hadiths/{hadithId} {
      allow read: if true;
      allow write: if false;
    }

    match /faqs/{faqId} {
      allow read: if true;
      allow write: if false;
    }

    // ==================== FCM TOKENS ====================

    match /fcmTokens/{userId} {
      allow read: if isOwner(userId);
      allow write: if isOwner(userId);
    }

    // ==================== DENY ALL OTHER PATHS ====================

    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

3. **Click "Publish"** button (top right)

4. **Verify**: You should see "Rules published successfully"

---

## 📊 Step 2: Deploy Firestore Indexes (CRITICAL for Performance!)

### Index #1: Relatives - Main Query
1. Go to: https://console.firebase.google.com/project/silni-31811/firestore/indexes
2. Click **"Add Index"** or **"Create Index"**
3. Fill in:
   - **Collection ID**: `relatives`
   - **Fields to index**:
     - Field: `userId`, Order: **Ascending**
     - Field: `isArchived`, Order: **Ascending**
     - Field: `priority`, Order: **Ascending**
     - Field: `fullName`, Order: **Ascending**
   - **Query scope**: Collection
4. Click **"Create"**

### Index #2: Relatives - Favorites
1. Click **"Add Index"** again
2. Fill in:
   - **Collection ID**: `relatives`
   - **Fields to index**:
     - Field: `userId`, Order: **Ascending**
     - Field: `isArchived`, Order: **Ascending**
     - Field: `isFavorite`, Order: **Descending**
     - Field: `lastContactDate`, Order: **Descending**
   - **Query scope**: Collection
3. Click **"Create"**

### Index #3: Interactions by User
1. Click **"Add Index"** again
2. Fill in:
   - **Collection ID**: `interactions`
   - **Fields to index**:
     - Field: `userId`, Order: **Ascending**
     - Field: `date`, Order: **Descending**
   - **Query scope**: Collection
3. Click **"Create"**

### Index #4: Interactions by Relative
1. Click **"Add Index"** again
2. Fill in:
   - **Collection ID**: `interactions`
   - **Fields to index**:
     - Field: `relativeId`, Order: **Ascending**
     - Field: `date`, Order: **Descending**
   - **Query scope**: Collection
3. Click **"Create"**

### Index #5: Interactions by Type
1. Click **"Add Index"** again
2. Fill in:
   - **Collection ID**: `interactions`
   - **Fields to index**:
     - Field: `userId`, Order: **Ascending**
     - Field: `type`, Order: **Ascending**
     - Field: `date`, Order: **Descending**
   - **Query scope**: Collection
3. Click **"Create"**

### Index #6: Reminders by User
1. Click **"Add Index"** again
2. Fill in:
   - **Collection ID**: `reminders`
   - **Fields to index**:
     - Field: `userId`, Order: **Ascending**
     - Field: `isActive`, Order: **Ascending**
     - Field: `nextReminderDate`, Order: **Ascending**
   - **Query scope**: Collection
3. Click **"Create"**

### Index #7: Reminders by Relative
1. Click **"Add Index"** again
2. Fill in:
   - **Collection ID**: `reminders`
   - **Fields to index**:
     - Field: `relativeId`, Order: **Ascending**
     - Field: `isActive`, Order: **Ascending**
     - Field: `nextReminderDate`, Order: **Ascending**
   - **Query scope**: Collection
3. Click **"Create"**

---

## ⏱️ Wait for Indexes to Build

After creating all 7 indexes:
- They will show status: **"Building..."** (orange)
- Wait **5-10 minutes** for all to show **"Enabled"** (green)
- DO NOT test the app until all indexes are enabled!

You can check the status at: https://console.firebase.google.com/project/silni-31811/firestore/indexes

---

## ✅ Step 3: Test the App

After all indexes show "Enabled":

1. **Clear browser cache**:
   - Press F12 to open DevTools
   - Right-click the refresh button → "Empty Cache and Hard Reload"
   - Or in Console tab, run: `localStorage.clear(); sessionStorage.clear();`

2. **Sign out and sign in again**

3. **Add a new relative**:
   - Click "Add Relative"
   - Fill in the form
   - Save
   - Check console for: `✅ [RELATIVES] Created relative with ID: [ID]`

4. **Verify persistence**:
   - Refresh the page (F5)
   - The relative should still be there
   - Check console for: `📊 [RELATIVES] Received X relatives from Firestore`

5. **Check Firestore Console**:
   - Go to: https://console.firebase.google.com/project/silni-31811/firestore/data
   - Navigate to `relatives` collection
   - You should see your created relative document

---

## 🐛 Troubleshooting

### If relatives still don't appear after adding:

1. **Check browser console (F12) for errors**:
   - Look for "Permission denied" → Rules not deployed correctly
   - Look for "Missing index" → Wait longer for indexes to build
   - Look for "❌ [RELATIVES] Error" → Check the error message

2. **Verify rules are published**:
   - Go to Firestore Rules tab
   - Should show "Published [timestamp]" at top

3. **Verify indexes are enabled**:
   - Go to Indexes tab
   - All 7 indexes should show green "Enabled" status

4. **Check network tab**:
   - F12 → Network tab
   - Filter by "firestore.googleapis.com"
   - Look for failed requests (red)

---

## 📞 Need Help?

If you're still experiencing issues after completing these steps, please share:
1. Screenshot of Firestore Indexes page showing all index statuses
2. Screenshot of browser console showing any error messages
3. Screenshot of Network tab showing Firestore requests

This will help diagnose the specific issue!
