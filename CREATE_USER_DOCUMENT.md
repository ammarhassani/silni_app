# 📝 Create User Document Manually

Since the automatic user document creation isn't working, follow these steps to create it manually in Firebase Console:

## Step 1: Open Firestore Console

Go to: https://console.firebase.google.com/project/silni-31811/firestore/data

## Step 2: Create `users` Collection

1. Click **"Start collection"** (if no collections exist)
   - OR click **"+ Start collection"** button at the top

2. **Collection ID**: Enter `users`

3. Click **"Next"**

## Step 3: Create Your User Document

1. **Document ID**: Enter exactly this (your Firebase Auth UID):
   ```
   hiwuF6WUIObb2Y2koFtGJnCBVNs2
   ```

2. **Add the following fields** one by one:

   Click **"Add field"** for each:

   | Field Name | Type | Value |
   |------------|------|-------|
   | `id` | string | `hiwuF6WUIObb2Y2koFtGJnCBVNs2` |
   | `email` | string | `azahrani337@gmail.com` |
   | `fullName` | string | `Abdulaziz` (or your actual name) |
   | `phoneNumber` | null | (leave as null) |
   | `profilePictureUrl` | null | (leave as null) |
   | `createdAt` | timestamp | (click calendar, select today's date) |
   | `lastLoginAt` | timestamp | (click calendar, select today's date) |
   | `emailVerified` | boolean | `false` |
   | `subscriptionStatus` | string | `free` |
   | `language` | string | `ar` |
   | `notificationsEnabled` | boolean | `true` |
   | `reminderTime` | string | `09:00` |
   | `theme` | string | `light` |
   | `totalInteractions` | number | `0` |
   | `currentStreak` | number | `0` |
   | `longestStreak` | number | `0` |
   | `points` | number | `0` |
   | `level` | number | `1` |
   | `badges` | array | (leave empty - click array then leave it empty) |
   | `dataExportRequested` | boolean | `false` |
   | `accountDeletionRequested` | boolean | `false` |

3. Click **"Save"**

## Step 4: (Optional) Create Sample Hadith

1. Click **"+ Start collection"** again

2. **Collection ID**: Enter `hadiths`

3. Click **"Next"**

4. **Document ID**: Enter `sample1`

5. Add these fields:

   | Field Name | Type | Value |
   |------------|------|-------|
   | `id` | string | `sample1` |
   | `arabicText` | string | `صِلَة الرَّحِمِ تزيد في العمر وتوسع في الرزق` |
   | `englishText` | string | `Maintaining family ties increases lifespan and expands sustenance` |
   | `reference` | string | `Sahih Bukhari` |
   | `category` | string | `family` |
   | `order` | number | `1` |

6. Click **"Save"**

## Step 5: Test the App

1. Run your app:
   ```bash
   flutter run -d chrome
   ```

2. Sign in with `azahrani337@gmail.com`

3. **Add a relative** - This should now work!

4. **Sign out and sign in again** - The relative should persist!

5. **Refresh Firestore Console** - You should see:
   - `users` collection with your document
   - `relatives` collection with your added relative

## Verification

After creating a relative, go back to Firestore Console and you should see:

```
└── users/
    └── hiwuF6WUIObb2Y2koFtGJnCBVNs2  ← Your user document
└── relatives/
    └── [auto-generated-id]  ← Your relative
        ├── userId: "hiwuF6WUIObb2Y2koFtGJnCBVNs2"
        ├── fullName: "..."
        ├── relationshipType: "..."
        ├── isArchived: false
        └── ...
└── hadiths/
    └── sample1  ← Sample hadith
```

## Troubleshooting

**If adding relative still fails:**

1. Check browser console (F12) for errors
2. Look for "Permission denied" or "Missing index" errors
3. Verify the user document ID **exactly matches** your Firebase Auth UID
4. Verify security rules are published (you did this earlier)
5. Verify all indexes show "Enabled" status (you did this earlier)

**Common mistakes:**
- ❌ Document ID doesn't match Firebase Auth UID
- ❌ Field names have typos (case-sensitive!)
- ❌ Field types are wrong (string vs number vs boolean)

Once the user document is created, everything should work perfectly! 🎉
