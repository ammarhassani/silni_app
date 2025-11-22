# Firestore Database Structure

This document details the complete Firestore database structure for the Silni app, including all collections, fields, relationships, indexes, and security considerations.

## Table of Contents

1. [Collections Overview](#collections-overview)
2. [Users Collection](#users-collection)
3. [Relatives Collection](#relatives-collection)
4. [Interactions Collection](#interactions-collection)
5. [Reminders Collection](#reminders-collection)
6. [Achievements Collection](#achievements-collection)
7. [User Achievements Collection](#user-achievements-collection)
8. [Statistics Collection](#statistics-collection)
9. [Educational Content](#educational-content)
10. [Indexes](#indexes)
11. [Security Rules](#security-rules)

---

## Collections Overview

```
firestore
├── users/                    # User profiles and settings
├── relatives/                # Family members/relatives data
├── interactions/             # Logged interactions with relatives
├── reminders/                # Reminder schedules
├── achievements/             # Achievement templates (read-only)
├── userAchievements/         # User-earned achievements
├── statistics/               # Aggregated user statistics
├── hadiths/                  # Daily hadith content
└── faqs/                     # FAQ content
```

---

## Users Collection

**Path:** `/users/{userId}`

**Document ID:** Firebase Auth UID

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | ✅ | Firebase Auth UID |
| `email` | string | ✅ | User's email address |
| `fullName` | string | ✅ | User's full name (2-100 chars) |
| `phoneNumber` | string | ❌ | Phone number (Saudi format) |
| `profilePictureUrl` | string | ❌ | Cloudinary URL |
| `createdAt` | timestamp | ✅ | Account creation date |
| `lastLoginAt` | timestamp | ✅ | Last login timestamp |
| `emailVerified` | boolean | ✅ | Email verification status |
| `subscriptionStatus` | string | ✅ | "free" or "premium" |
| `subscriptionStartDate` | timestamp | ❌ | Premium start date |
| `subscriptionEndDate` | timestamp | ❌ | Premium end date |
| `language` | string | ✅ | "ar" or "en" (default: "ar") |
| `notificationsEnabled` | boolean | ✅ | Notification preference |
| `reminderTime` | string | ✅ | Preferred time (HH:mm format) |
| `theme` | string | ✅ | "light" or "dark" |
| `totalInteractions` | number | ✅ | Total logged interactions |
| `currentStreak` | number | ✅ | Current daily streak |
| `longestStreak` | number | ✅ | Longest streak achieved |
| `lastInteractionDate` | timestamp | ❌ | Last interaction date |
| `points` | number | ✅ | Gamification points |
| `level` | number | ✅ | User level (1-100) |
| `badges` | array | ✅ | Array of badge IDs |
| `dataExportRequested` | boolean | ✅ | GDPR data export flag |
| `accountDeletionRequested` | boolean | ✅ | Account deletion flag |

### Example Document

```json
{
  "id": "abc123xyz",
  "email": "user@example.com",
  "fullName": "محمد أحمد",
  "phoneNumber": "+966501234567",
  "profilePictureUrl": "https://res.cloudinary.com/silni/...",
  "createdAt": "2025-01-15T10:00:00Z",
  "lastLoginAt": "2025-01-20T09:30:00Z",
  "emailVerified": true,
  "subscriptionStatus": "premium",
  "subscriptionStartDate": "2025-01-15T10:00:00Z",
  "subscriptionEndDate": "2026-01-15T10:00:00Z",
  "language": "ar",
  "notificationsEnabled": true,
  "reminderTime": "09:00",
  "theme": "light",
  "totalInteractions": 45,
  "currentStreak": 7,
  "longestStreak": 12,
  "lastInteractionDate": "2025-01-20T00:00:00Z",
  "points": 450,
  "level": 3,
  "badges": ["first_interaction", "7_day_streak"],
  "dataExportRequested": false,
  "accountDeletionRequested": false
}
```

---

## Relatives Collection

**Path:** `/relatives/{relativeId}`

**Document ID:** Auto-generated

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | ✅ | Auto-generated ID |
| `userId` | string | ✅ | Owner's Firebase Auth UID |
| `fullName` | string | ✅ | Relative's full name |
| `relationshipType` | string | ✅ | Relationship type (see enum below) |
| `gender` | string | ❌ | "male" or "female" |
| `dateOfBirth` | timestamp | ❌ | Date of birth |
| `phoneNumber` | string | ❌ | Contact phone number |
| `email` | string | ❌ | Contact email |
| `address` | string | ❌ | Physical address |
| `city` | string | ❌ | City name |
| `country` | string | ❌ | Country name |
| `photoUrl` | string | ❌ | Cloudinary URL |
| `notes` | string | ❌ | Personal notes |
| `tags` | array | ❌ | Custom tags |
| `priority` | number | ✅ | 1 (high), 2 (medium), 3 (low) |
| `islamicImportance` | string | ❌ | Islamic priority level |
| `preferredContactMethod` | string | ❌ | "call", "visit", "message" |
| `bestTimeToContact` | string | ❌ | Preferred contact time |
| `interactionCount` | number | ✅ | Total interactions (default: 0) |
| `lastContactDate` | timestamp | ❌ | Last interaction date |
| `healthStatus` | string | ❌ | Health notes |
| `isArchived` | boolean | ✅ | Soft delete flag |
| `isFavorite` | boolean | ✅ | Favorite flag |
| `createdAt` | timestamp | ✅ | Creation timestamp |
| `updatedAt` | timestamp | ❌ | Last update timestamp |

### Relationship Types Enum

```
father, mother, brother, sister, son, daughter,
grandfather, grandmother, uncle, aunt,
nephew, niece, cousin, husband, wife, other
```

### Example Document

```json
{
  "id": "rel_001",
  "userId": "abc123xyz",
  "fullName": "أحمد محمد",
  "relationshipType": "brother",
  "gender": "male",
  "dateOfBirth": "1990-05-15T00:00:00Z",
  "phoneNumber": "+966501234567",
  "photoUrl": "https://res.cloudinary.com/silni/...",
  "notes": "يحب القهوة الصباحية",
  "tags": ["عائلة", "قريب"],
  "priority": 1,
  "islamicImportance": "محرم",
  "preferredContactMethod": "call",
  "bestTimeToContact": "مساءً",
  "interactionCount": 12,
  "lastContactDate": "2025-01-18T00:00:00Z",
  "isArchived": false,
  "isFavorite": true,
  "createdAt": "2025-01-01T10:00:00Z",
  "updatedAt": "2025-01-18T15:30:00Z"
}
```

---

## Interactions Collection

**Path:** `/interactions/{interactionId}`

**Document ID:** Auto-generated

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | ✅ | Auto-generated ID |
| `userId` | string | ✅ | Owner's Firebase Auth UID |
| `relativeId` | string | ✅ | Related relative ID |
| `type` | string | ✅ | Interaction type (see enum below) |
| `date` | timestamp | ✅ | Interaction date |
| `duration` | number | ❌ | Duration in minutes |
| `location` | string | ❌ | Location description |
| `notes` | string | ❌ | Interaction notes |
| `mood` | string | ❌ | Mood during interaction |
| `photoUrls` | array | ❌ | Array of Cloudinary URLs (premium) |
| `audioNoteUrl` | string | ❌ | Cloudinary audio URL (premium) |
| `tags` | array | ❌ | Custom tags |
| `rating` | number | ❌ | Quality rating (1-5) |
| `isRecurring` | boolean | ✅ | Recurring event flag |
| `createdAt` | timestamp | ✅ | Creation timestamp |
| `updatedAt` | timestamp | ❌ | Last update timestamp |

### Interaction Types Enum

```
call, visit, message, gift, event, other
```

### Example Document

```json
{
  "id": "int_001",
  "userId": "abc123xyz",
  "relativeId": "rel_001",
  "type": "visit",
  "date": "2025-01-18T16:00:00Z",
  "duration": 120,
  "location": "منزله",
  "notes": "زيارة عائلية ممتعة، تناولنا القهوة",
  "mood": "سعيد",
  "photoUrls": ["https://res.cloudinary.com/silni/..."],
  "tags": ["عائلة", "قهوة"],
  "rating": 5,
  "isRecurring": false,
  "createdAt": "2025-01-18T18:00:00Z"
}
```

---

## Reminders Collection

**Path:** `/reminders/{reminderId}`

**Document ID:** Auto-generated

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | ✅ | Auto-generated ID |
| `userId` | string | ✅ | Owner's Firebase Auth UID |
| `relativeId` | string | ✅ | Related relative ID |
| `title` | string | ✅ | Reminder title |
| `message` | string | ❌ | Custom message |
| `frequency` | string | ✅ | Frequency type (see enum below) |
| `customDays` | number | ❌ | Custom frequency (days) |
| `nextReminderDate` | timestamp | ✅ | Next reminder timestamp |
| `lastReminderDate` | timestamp | ❌ | Last sent timestamp |
| `time` | string | ✅ | Time (HH:mm format) |
| `isActive` | boolean | ✅ | Active status |
| `isSmart` | boolean | ✅ | Smart reminder flag |
| `notificationEnabled` | boolean | ✅ | Notification preference |
| `createdAt` | timestamp | ✅ | Creation timestamp |
| `updatedAt` | timestamp | ❌ | Last update timestamp |

### Frequency Types Enum

```
daily, weekly, biweekly, monthly, custom
```

### Example Document

```json
{
  "id": "rem_001",
  "userId": "abc123xyz",
  "relativeId": "rel_001",
  "title": "تذكير بزيارة أحمد",
  "message": "حان وقت زيارة أخيك أحمد",
  "frequency": "weekly",
  "nextReminderDate": "2025-01-25T09:00:00Z",
  "lastReminderDate": "2025-01-18T09:00:00Z",
  "time": "09:00",
  "isActive": true,
  "isSmart": true,
  "notificationEnabled": true,
  "createdAt": "2025-01-01T10:00:00Z",
  "updatedAt": "2025-01-18T09:05:00Z"
}
```

---

## Achievements Collection

**Path:** `/achievements/{achievementId}`

**Document ID:** Predefined IDs

**Note:** This is a read-only collection managed by admins/Cloud Functions.

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | ✅ | Achievement ID |
| `title` | object | ✅ | { ar: "...", en: "..." } |
| `description` | object | ✅ | { ar: "...", en: "..." } |
| `iconUrl` | string | ✅ | Achievement icon URL |
| `points` | number | ✅ | Points awarded |
| `category` | string | ✅ | Category type |
| `requirement` | object | ✅ | Unlock requirements |
| `isHidden` | boolean | ✅ | Hidden until unlocked |
| `order` | number | ✅ | Display order |

---

## User Achievements Collection

**Path:** `/userAchievements/{userAchievementId}`

**Document ID:** Auto-generated

**Note:** Managed by Cloud Functions only.

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `userId` | string | ✅ | User's Firebase Auth UID |
| `achievementId` | string | ✅ | Achievement ID |
| `unlockedAt` | timestamp | ✅ | Unlock timestamp |
| `notified` | boolean | ✅ | Notification sent flag |

---

## Statistics Collection

**Path:** `/statistics/{userId}`

**Document ID:** Firebase Auth UID

**Note:** Managed by Cloud Functions only (aggregated nightly).

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `totalInteractions` | number | Total interactions |
| `interactionsByType` | map | Count by type |
| `interactionsByMonth` | map | Count by month |
| `topRelatives` | array | Most contacted relatives |
| `averageInterval` | number | Avg days between contacts |
| `streakHistory` | array | Historical streaks |
| `lastUpdated` | timestamp | Last calculation time |

---

## Educational Content

### Hadiths Collection

**Path:** `/hadiths/{hadithId}`

**Fields:** `text` (object), `reference` (object), `category`, `order`

### FAQs Collection

**Path:** `/faqs/{faqId}`

**Fields:** `question` (object), `answer` (object), `category`, `order`

---

## Indexes

Create these composite indexes in Firebase Console:

### Relatives

```
Collection: relatives
Fields: userId (Ascending), isArchived (Ascending), priority (Descending), fullName (Ascending)
```

### Interactions

```
Collection: interactions
Fields: userId (Ascending), date (Descending)

Collection: interactions
Fields: relativeId (Ascending), date (Descending)
```

### Reminders

```
Collection: reminders
Fields: userId (Ascending), isActive (Ascending), nextReminderDate (Ascending)
```

---

## Security Rules

Comprehensive security rules are defined in `firestore.rules`. Key principles:

1. **Authentication Required:** All user data requires authentication
2. **Data Ownership:** Users can only access their own data
3. **Field Validation:** All writes validate required fields and data types
4. **Premium Features:** Photo attachments restricted to premium users
5. **Free Tier Limits:** Max 20 relatives for free users
6. **Read-Only Collections:** Achievements, statistics, educational content

---

## Deployment

### Deploy Security Rules

```bash
firebase deploy --only firestore:rules
```

### Create Indexes

Go to Firebase Console → Firestore → Indexes and create the indexes listed above, or they will be auto-created when queries fail.

---

## Best Practices

1. **Always use transactions** for operations that depend on current data
2. **Use batch writes** for multiple related operations
3. **Implement offline persistence** for better UX
4. **Cache frequently accessed data** (achievements, hadiths)
5. **Monitor Firestore usage** to stay within free tier limits
6. **Use Cloud Functions** for aggregations and statistics

---

## Free Tier Considerations

**Firestore Free Tier:**
- 1 GiB storage
- 50,000 reads/day
- 20,000 writes/day
- 20,000 deletes/day

**Optimization strategies:**
- Cache data locally using AsyncStorage
- Batch reads when possible
- Use pagination for large lists
- Implement optimistic updates

---

## Next Steps

1. Deploy security rules to Firebase
2. Create composite indexes
3. Test CRUD operations with services
4. Implement offline persistence
5. Add Cloud Functions for statistics aggregation
