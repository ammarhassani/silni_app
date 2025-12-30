# Silni App - API Specifications Documentation

## Overview

This document provides comprehensive API specifications for Silni's backend services, primarily using Supabase as the main backend with complementary Firebase services for notifications and analytics.

## Table of Contents

1. [Authentication APIs](#authentication-apis)
2. [User Management APIs](#user-management-apis)
3. [Relatives Management APIs](#relatives-management-apis)
4. [Interactions APIs](#interactions-apis)
5. [Reminders APIs](#reminders-apis)
6. [Gamification APIs](#gamification-apis)
7. [Subscription APIs](#subscription-apis)
8. [Premium Onboarding APIs](#premium-onboarding-apis)
9. [AI Services APIs](#ai-services-apis)
10. [Real-time Subscriptions](#real-time-subscriptions)
11. [Storage APIs](#storage-apis)
12. [Error Responses](#error-responses)
13. [Riverpod Providers Reference](#riverpod-providers-reference)

---

## Authentication APIs

### Supabase Authentication

Silni uses Supabase Auth for user authentication with the following endpoints:

#### Sign Up
```http
POST /auth/v1/signup
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securePassword123",
  "options": {
    "data": {
      "full_name": "أحمد محمد",
      "language": "ar"
    }
  }
}
```

**Response:**
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "user_metadata": {
      "full_name": "أحمد محمد",
      "language": "ar"
    }
  },
  "session": {
    "access_token": "jwt_token",
    "refresh_token": "refresh_token",
    "expires_in": 3600
  }
}
```

#### Sign In
```http
POST /auth/v1/token?grant_type=password
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

#### Sign Out
```http
POST /auth/v1/logout
Authorization: Bearer <access_token>
```

#### Social Authentication
```http
# Google Sign In
POST /auth/v1/token?grant_type=google

# Apple Sign In
POST /auth/v1/token?grant_type=apple
```

#### Reset Password
```http
POST /auth/v1/recover
Content-Type: application/json

{
  "email": "user@example.com"
}
```

---

## User Management APIs

### Users Table Schema

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | Primary Key | User UUID |
| email | String | Unique, Not Null | User email |
| full_name | String | Not Null, Length 2-100 | User full name |
| avatar_url | String | Nullable | Profile picture URL |
| phone_number | String | Nullable | Phone number |
| date_of_birth | Timestamp | Nullable | Birth date |
| gender | Enum | 'male', 'female', null | Gender |
| subscription_status | Enum | 'free', 'premium' | Subscription tier (free or MAX) |
| subscription_product_id | String | Nullable | RevenueCat product ID |
| subscription_expires_at | Timestamp | Nullable | Subscription expiration date |
| trial_started_at | Timestamp | Nullable | Trial start date |
| trial_used | Boolean | Default false | Whether trial was used |
| onboarding_metadata | JSONB | Default '{}' | Premium onboarding progress |
| level | Integer | Default 1 | Gamification level |
| total_points | Integer | Default 0 | Total points earned |
| current_streak | Integer | Default 0 | Current interaction streak |
| longest_streak | Integer | Default 0 | Longest streak achieved |
| created_at | Timestamp | Auto | Account creation |
| updated_at | Timestamp | Auto | Last update |

### User Profile Operations

#### Get Current User
```dart
// Using Supabase client
final user = SupabaseConfig.client.auth.currentUser;
```

#### Update User Profile
```http
PATCH /rest/v1/users?id=eq.{userId}
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "full_name": "أحمد محمد أحمد",
  "avatar_url": "https://example.com/avatar.jpg",
  "phone_number": "+966500000000"
}
```

#### Update User Preferences
```http
PATCH /rest/v1/users?id=eq.{userId}
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "preferences": {
    "language": "ar",
    "timezone": "Asia/Riyadh",
    "notifications": {
      "enabled": true,
      "quiet_hours": {
        "start": "22:00",
        "end": "06:00"
      }
    }
  }
}
```

---

## Relatives Management APIs

### Relatives Table Schema

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | Primary Key | Relative UUID |
| user_id | UUID | Foreign Key, Not Null | Owner user ID |
| full_name | String | Not Null, Length 2-100 | Relative name |
| relationship_type | Enum | Not Null | Relationship to user |
| gender | Enum | 'male', 'female', null | Gender |
| avatar_type | Enum | Avatar type | Visual representation |
| date_of_birth | Timestamp | Nullable | Birth date |
| phone_number | String | Nullable | Phone number |
| email | String | Nullable | Email address |
| address | String | Nullable | Physical address |
| city | String | Nullable | City |
| country | String | Nullable | Country |
| photo_url | String | Nullable | Photo URL |
| notes | Text | Nullable | Personal notes |
| priority | Integer | 1-3, Default 2 | Contact priority |
| islamic_importance | Text | Nullable | Islamic relationship context |
| preferred_contact_method | String | Nullable | Preferred contact method |
| best_time_to_contact | String | Nullable | Best contact time |
| interaction_count | Integer | Default 0 | Total interactions |
| last_contact_date | Timestamp | Nullable | Last contact |
| health_status | String | Nullable | Health status |
| is_archived | Boolean | Default false | Archive status |
| is_favorite | Boolean | Default false | Favorite status |
| contact_id | String | Nullable | Device contact ID |
| created_at | Timestamp | Auto | Creation time |
| updated_at | Timestamp | Auto | Last update |

#### Relationship Types Enum
```typescript
type RelationshipType = 
  | 'father' | 'mother' | 'brother' | 'sister'
  | 'son' | 'daughter' | 'grandfather' | 'grandmother'
  | 'uncle' | 'aunt' | 'nephew' | 'niece'
  | 'cousin' | 'husband' | 'wife' | 'other';
```

### CRUD Operations

#### Create Relative
```http
POST /rest/v1/relatives
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "full_name": "محمد أحمد",
  "relationship_type": "father",
  "gender": "male",
  "priority": 1,
  "phone_number": "+966500000001",
  "islamic_importance": "الوالد - حقوق البر الوالدين"
}
```

**Response:**
```json
{
  "id": "relative_uuid",
  "created_at": "2024-01-01T12:00:00Z"
}
```

#### Get Relatives (Paginated)
```http
GET /rest/v1/relatives?user_id=eq.{userId}&is_archived=eq.false&order=priority.asc,full_name.asc&limit=20&offset=0
Authorization: Bearer <access_token>
```

**Response:**
```json
[
  {
    "id": "relative_uuid",
    "user_id": "user_uuid",
    "full_name": "محمد أحمد",
    "relationship_type": "father",
    "priority": 1,
    "interaction_count": 15,
    "last_contact_date": "2024-01-01T12:00:00Z",
    "needs_contact": true,
    "health_score": 85
  }
]
```

#### Search Relatives
```http
GET /rest/v1/relatives?user_id=eq.{userId}&full_name=ilike.%{searchTerm}%&is_archived=eq.false
Authorization: Bearer <access_token>
```

#### Update Relative
```http
PATCH /rest/v1/relatives?id=eq.{relativeId}
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "phone_number": "+966500000002",
  "notes": "Updated notes",
  "priority": 1
}
```

#### Archive Relative
```http
PATCH /rest/v1/relatives?id=eq.{relativeId}
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "is_archived": true
}
```

#### Toggle Favorite
```http
PATCH /rest/v1/relatives?id=eq.{relativeId}
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "is_favorite": true
}
```

---

## Interactions APIs

### Interactions Table Schema

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | Primary Key | Interaction UUID |
| user_id | UUID | Foreign Key, Not Null | User ID |
| relative_id | UUID | Foreign Key, Not Null | Relative ID |
| type | Enum | Not Null | Interaction type |
| date | Timestamp | Not Null | Interaction date |
| duration | Integer | Nullable | Duration in minutes |
| location | String | Nullable | Location |
| notes | Text | Nullable | Interaction notes |
| mood | String | Nullable | Mood/feeling |
| photo_urls | Array | Nullable | Photo URLs |
| rating | Integer | 1-5, Nullable | Quality rating |
| is_recurring | Boolean | Default false | Recurring interaction |
| created_at | Timestamp | Auto | Creation time |
| updated_at | Timestamp | Auto | Last update |

#### Interaction Types Enum
```typescript
type InteractionType = 'call' | 'visit' | 'message' | 'gift' | 'event' | 'other';
```

### CRUD Operations

#### Create Interaction
```http
POST /rest/v1/interactions
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "relative_id": "relative_uuid",
  "type": "call",
  "date": "2024-01-01T12:00:00Z",
  "duration": 30,
  "notes": "مكالمة هاتفية ممتعة",
  "mood": "سعيد",
  "rating": 5
}
```

#### Get Interactions for Relative
```http
GET /rest/v1/interactions?relative_id=eq.{relativeId}&order=date.desc&limit=50
Authorization: Bearer <access_token>
```

#### Get Recent Interactions
```http
GET /rest/v1/interactions?user_id=eq.{userId}&order=date.desc&limit=10
Authorization: Bearer <access_token>
```

#### Update Interaction
```http
PATCH /rest/v1/interactions?id=eq.{interactionId}
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "notes": "Updated notes",
  "rating": 4
}
```

#### Delete Interaction
```http
DELETE /rest/v1/interactions?id=eq.{interactionId}
Authorization: Bearer <access_token>
```

---

## Reminders APIs

### Reminder Schedules Table Schema

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | Primary Key | Schedule UUID |
| user_id | UUID | Foreign Key, Not Null | User ID |
| relative_id | UUID | Foreign Key, Not Null | Target relative |
| frequency | Enum | Not Null | Reminder frequency |
| days_of_week | Array | Nullable | Days for weekly reminders |
| day_of_month | Integer | Nullable | Day for monthly reminders |
| time | Time | Not Null | Reminder time |
| next_reminder_date | Timestamp | Not Null | Next reminder |
| is_active | Boolean | Default true | Active status |
| message_template | Text | Nullable | Custom message |
| created_at | Timestamp | Auto | Creation time |
| updated_at | Timestamp | Auto | Last update |

#### Frequency Types
```typescript
type Frequency = 'daily' | 'weekly' | 'biweekly' | 'monthly' | 'friday' | 'custom';
```

### CRUD Operations

#### Create Reminder Schedule
```http
POST /rest/v1/reminder_schedules
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "relative_id": "relative_uuid",
  "frequency": "weekly",
  "days_of_week": [1, 3, 5],
  "time": "18:00",
  "next_reminder_date": "2024-01-01T18:00:00Z",
  "message_template": "تذكر بالاتصال بوالدك اليوم"
}
```

#### Get Reminder Schedules
```http
GET /rest/v1/reminder_schedules?user_id=eq.{userId}&is_active=eq.true&order=next_reminder_date.asc
Authorization: Bearer <access_token>
```

#### Get Due Reminders
```http
GET /rest/v1/reminder_schedules?user_id=eq.{userId}&is_active=eq.true&next_reminder_date=lte.{currentTimestamp}
Authorization: Bearer <access_token>
```

#### Update Reminder Schedule
```http
PATCH /rest/v1/reminder_schedules?id=eq.{scheduleId}
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "frequency": "daily",
  "time": "19:00",
  "is_active": false
}
```

#### Update Next Reminder Date
```http
# Database function to update next reminder date
POST /rest/v1/rpc/update_next_reminder
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "p_schedule_id": "schedule_uuid",
  "p_next_date": "2024-01-02T18:00:00Z"
}
```

---

## Gamification APIs

### User Gamification Fields

Additional fields in `users` table for gamification:

| Field | Type | Description |
|-------|------|-------------|
| level | Integer | Current user level |
| total_points | Integer | Total points earned |
| current_streak | Integer | Current interaction streak |
| longest_streak | Integer | Longest streak achieved |
| badges_earned | Array | List of earned badges |
| achievements | JSON | Achievement progress |

### Badges Table Schema

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | Primary Key | Badge UUID |
| name | String | Not Null | Badge name |
| description | Text | Not Null | Badge description |
| icon_url | String | Not Null | Badge icon |
| category | String | Not Null | Badge category |
| requirement_type | String | Not Null | Requirement type |
| requirement_value | Integer | Not Null | Requirement value |
| points_reward | Integer | Not Null | Points awarded |
| is_active | Boolean | Default true | Available status |

### User Achievements Table Schema

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | Primary Key | Achievement UUID |
| user_id | UUID | Foreign Key, Not Null | User ID |
| badge_id | UUID | Foreign Key, Not Null | Badge ID |
| earned_at | Timestamp | Auto | Earned date |
| progress_data | JSON | Nullable | Progress details |

### Gamification Operations

#### Get User Stats
```http
GET /rest/v1/users?id=eq.{userId}&select=level,total_points,current_streak,longest_streak,badges_earned
Authorization: Bearer <access_token>
```

#### Get Available Badges
```http
GET /rest/v1/badges?is_active=eq.true&order=category.asc,requirement_value.asc
Authorization: Bearer <access_token>
```

#### Get User Achievements
```http
GET /rest/v1/user_achievements?user_id=eq.{userId}&order=earned_at.desc
Authorization: Bearer <access_token>
```

#### Award Points
```http
# Database function to award points
POST /rest/v1/rpc/award_points
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "p_user_id": "user_uuid",
  "p_points": 10,
  "p_reason": "daily_interaction",
  "p_relative_id": "relative_uuid"
}
```

#### Check and Award Badge
```http
# Database function to check badge eligibility
POST /rest/v1/rpc/check_and_award_badge
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "p_user_id": "user_uuid",
  "p_badge_id": "badge_uuid",
  "p_progress_data": {
    "interactions_count": 50,
    "streak_days": 7
  }
}
```

---

## Subscription APIs

### Overview

Silni uses RevenueCat for in-app subscription management with a two-tier model:

| Tier | ID | Features |
|------|-----|----------|
| **Free** | `free` | Family management, Family tree, Custom themes, 3 reminders |
| **MAX** | `premium` | All Free features + All AI features + Unlimited reminders |

### Subscription Events Table Schema

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | Primary Key | Event UUID |
| user_id | UUID | Foreign Key | User reference |
| event_type | String | Not Null | Event type (see below) |
| from_tier | String | Nullable | Previous subscription tier |
| to_tier | String | Nullable | New subscription tier |
| product_id | String | Nullable | RevenueCat product ID |
| revenue_amount | Decimal(10,2) | Nullable | Revenue from event |
| currency | String | Default 'USD' | Currency code |
| metadata | JSONB | Default '{}' | Additional event data |
| created_at | Timestamp | Auto | Event timestamp |

#### Event Types

| Event Type | Description |
|------------|-------------|
| `purchase` | New subscription purchased |
| `renewal` | Subscription renewed |
| `upgrade` | Upgraded to higher tier |
| `downgrade` | Downgraded to lower tier |
| `cancellation` | Subscription cancelled |
| `trial_start` | Free trial started |
| `trial_end` | Free trial ended |
| `status_change` | Generic status change |

### Database Functions

#### Log Subscription Event
```sql
-- Function signature
CREATE OR REPLACE FUNCTION log_subscription_event(
  p_user_id UUID,
  p_event_type TEXT,
  p_from_tier TEXT DEFAULT NULL,
  p_to_tier TEXT DEFAULT NULL,
  p_product_id TEXT DEFAULT NULL,
  p_revenue_amount DECIMAL DEFAULT NULL,
  p_currency TEXT DEFAULT 'USD',
  p_metadata JSONB DEFAULT '{}'
) RETURNS UUID;
```

```http
POST /rest/v1/rpc/log_subscription_event
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "p_user_id": "user_uuid",
  "p_event_type": "purchase",
  "p_from_tier": "free",
  "p_to_tier": "premium",
  "p_product_id": "silni_max_monthly",
  "p_revenue_amount": 9.99
}
```

#### Update User Subscription
```sql
CREATE OR REPLACE FUNCTION update_user_subscription(
  p_user_id UUID,
  p_status TEXT,
  p_product_id TEXT DEFAULT NULL,
  p_expires_at TIMESTAMPTZ DEFAULT NULL
) RETURNS VOID;
```

```http
POST /rest/v1/rpc/update_user_subscription
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "p_user_id": "user_uuid",
  "p_status": "premium",
  "p_product_id": "silni_max_monthly",
  "p_expires_at": "2025-02-01T00:00:00Z"
}
```

#### Start User Trial
```sql
CREATE OR REPLACE FUNCTION start_user_trial(p_user_id UUID) RETURNS BOOLEAN;
```

```http
POST /rest/v1/rpc/start_user_trial
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "p_user_id": "user_uuid"
}
```

**Response:**
```json
{
  "result": true  // false if trial already used
}
```

#### End User Trial
```sql
CREATE OR REPLACE FUNCTION end_user_trial(p_user_id UUID) RETURNS VOID;
```

### RevenueCat Product IDs

| Product ID | Description | Billing |
|------------|-------------|---------|
| `silni_max_monthly` | MAX tier monthly | Monthly |
| `silni_max_annual` | MAX tier annual | Yearly (~40% savings) |

### Entitlement ID

```
Silni MAX - RevenueCat entitlement identifier for MAX tier access
```

### Get Subscription Events
```http
GET /rest/v1/subscription_events?user_id=eq.{userId}&order=created_at.desc&limit=50
Authorization: Bearer <access_token>
```

---

## Premium Onboarding APIs

### Overview

Premium onboarding provides an interactive tour of MAX features for new subscribers.

### Onboarding Events Table Schema

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | Primary Key | Event UUID |
| user_id | UUID | Foreign Key | User reference |
| event_type | String | Not Null | Event type (see below) |
| step_id | String | Nullable | Onboarding step identifier |
| step_index | Integer | Nullable | Step position (0-based) |
| metadata | JSONB | Default '{}' | Additional event data |
| created_at | Timestamp | Auto | Event timestamp |

#### Event Types

| Event Type | Description |
|------------|-------------|
| `onboarding_started` | User started premium onboarding |
| `step_viewed` | User viewed an onboarding step |
| `step_completed` | User completed an onboarding step |
| `step_skipped` | User skipped an onboarding step |
| `showcase_skipped` | User skipped entire showcase |
| `onboarding_completed` | User completed all onboarding |
| `tip_shown` | Contextual tip displayed |
| `tip_dismissed` | User dismissed a tip |

#### Step IDs

| Step ID | Description |
|---------|-------------|
| `ai_counselor` | AI Counselor feature introduction |
| `message_composer` | Message Composer feature |
| `communication_scripts` | Communication Scripts feature |
| `relationship_analysis` | Relationship Analysis feature |
| `smart_reminders_ai` | Smart Reminders AI feature |
| `weekly_reports` | Weekly Reports feature |

### Onboarding Metadata Structure

Stored in `users.onboarding_metadata`:

```json
{
  "hasStarted": true,
  "isCompleted": false,
  "currentStepIndex": 2,
  "completedSteps": ["ai_counselor", "message_composer"],
  "skippedSteps": [],
  "viewedScreens": ["ai_hub", "reminders"],
  "lastUpdated": "2025-01-01T12:00:00Z",
  "startedAt": "2025-01-01T10:00:00Z",
  "completedAt": null,
  "totalTimeSpentSeconds": 180
}
```

### Database Functions

#### Get Onboarding Analytics
```sql
CREATE OR REPLACE FUNCTION get_onboarding_analytics(
  p_start_date TIMESTAMPTZ DEFAULT NULL,
  p_end_date TIMESTAMPTZ DEFAULT NULL
) RETURNS TABLE (
  total_started BIGINT,
  total_completed BIGINT,
  completion_rate NUMERIC,
  avg_completion_time_seconds NUMERIC,
  showcase_skip_rate NUMERIC,
  most_completed_step TEXT,
  least_completed_step TEXT
);
```

```http
POST /rest/v1/rpc/get_onboarding_analytics
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "p_start_date": "2025-01-01T00:00:00Z",
  "p_end_date": "2025-01-31T23:59:59Z"
}
```

**Response:**
```json
{
  "total_started": 150,
  "total_completed": 120,
  "completion_rate": 80.00,
  "avg_completion_time_seconds": 245,
  "showcase_skip_rate": 5.33,
  "most_completed_step": "ai_counselor",
  "least_completed_step": "weekly_reports"
}
```

#### Get Step Analytics
```sql
CREATE OR REPLACE FUNCTION get_step_analytics(
  p_start_date TIMESTAMPTZ DEFAULT NULL
) RETURNS TABLE (
  step_id TEXT,
  times_viewed BIGINT,
  times_completed BIGINT,
  times_skipped BIGINT,
  completion_rate NUMERIC,
  avg_time_spent_seconds NUMERIC
);
```

```http
POST /rest/v1/rpc/get_step_analytics
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "p_start_date": "2025-01-01T00:00:00Z"
}
```

**Response:**
```json
[
  {
    "step_id": "ai_counselor",
    "times_viewed": 145,
    "times_completed": 130,
    "times_skipped": 10,
    "completion_rate": 89.66,
    "avg_time_spent_seconds": 45
  },
  {
    "step_id": "message_composer",
    "times_viewed": 135,
    "times_completed": 125,
    "times_skipped": 8,
    "completion_rate": 92.59,
    "avg_time_spent_seconds": 38
  }
]
```

### Log Onboarding Event
```http
POST /rest/v1/onboarding_events
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "user_id": "user_uuid",
  "event_type": "step_completed",
  "step_id": "ai_counselor",
  "step_index": 0,
  "metadata": {
    "timeSpentSeconds": 45,
    "source": "carousel"
  }
}
```

---

## AI Services APIs

### AI Analysis Endpoints

#### Analyze Relationship
```http
POST /functions/v1/analyze_relationship
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "relative_id": "relative_uuid",
  "analysis_type": "comprehensive",
  "time_period": "90_days"
}
```

**Response:**
```json
{
  "relationship_health_score": 85,
  "emotional_closeness": 4,
  "communication_quality": 5,
  "support_level": 4,
  "recommendations": [
    "Increase weekly calls to strengthen bond",
    "Consider planning a family gathering"
  ],
  "gift_suggestions": [
    {
      "category": "books",
      "suggestions": ["Islamic literature", "Hobby books"],
      "confidence": 0.85
    }
  ]
}
```

#### Generate Communication Script
```http
POST /functions/v1/generate_script
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "relative_id": "relative_uuid",
  "script_type": "reconciliation",
  "context": {
    "recent_conflict": "misunderstanding about family event",
    "desired_outcome": "reconciliation"
  }
}
```

**Response:**
```json
{
  "script": {
    "opening": "أبي، أريد أن أتحدث معك بصدق...",
    "main_points": [
      "أعتذر عن سوء الفهم",
      "أحبك وأقدرك دائماً"
    ],
    "closing": "أتمنى أن نتخطى هذا الأمر معاً"
  },
  "tone": "respectful",
  "estimated_duration": "5-10 minutes"
}
```

#### Get Weekly Report
```http
POST /functions/v1/weekly_report
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "start_date": "2024-01-01",
  "end_date": "2024-01-07",
  "include_ai_insights": true
}
```

**Response:**
```json
{
  "summary": {
    "total_interactions": 12,
    "unique_relatives": 5,
    "points_earned": 120,
    "new_badges": ["weekly_champion"]
  },
  "highlights": [
    "Longest streak: 5 days",
    "Most contacted: الأم",
    "Highest quality interaction: زيارة للأب"
  ],
  "ai_insights": {
    "relationship_trends": "improving",
    "recommendations": [
      "Focus on contacting cousins this week",
      "Consider organizing family gathering"
    ]
  }
}
```

---

## Real-time Subscriptions

### Supabase Realtime Channels

#### Subscribe to Relatives Changes
```dart
final channel = SupabaseConfig.client.channel('relatives')
  .onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'relatives',
    callback: (payload) {
      switch (payload.eventType) {
        case PostgresChangeEvent.insert:
          // Handle new relative
          break;
        case PostgresChangeEvent.update:
          // Handle relative update
          break;
        case PostgresChangeEvent.delete:
          // Handle relative deletion
          break;
      }
    },
  )
  .subscribe();
```

#### Subscribe to Interactions
```dart
final channel = SupabaseConfig.client.channel('interactions')
  .onPostgresChanges(
    event: PostgresChangeEvent.insert,
    schema: 'public',
    table: 'interactions',
    callback: (payload) {
      // Handle new interaction
      final interaction = Interaction.fromJson(payload.newRecord);
      // Update UI, refresh stats, etc.
    },
  )
  .subscribe();
```

#### Subscribe to Gamification Updates
```dart
final channel = SupabaseConfig.client.channel('gamification')
  .onPostgresChanges(
    event: PostgresChangeEvent.insert,
    schema: 'public',
    table: 'user_achievements',
    callback: (payload) {
      // Handle new achievement
      final achievement = UserAchievement.fromJson(payload.newRecord);
      // Show achievement modal, update stats
    },
  )
  .subscribe();
```

---

## Storage APIs

### Supabase Storage Buckets

#### User Avatars
```
Bucket: avatars
Path: users/{userId}/avatar/{fileName}
Allowed Types: image/*
Max Size: 5MB
```

#### Relative Photos
```
Bucket: relatives
Path: relatives/{relativeId}/{fileName}
Allowed Types: image/*
Max Size: 10MB
```

#### Interaction Attachments
```
Bucket: interactions
Path: interactions/{interactionId}/{fileName}
Allowed Types: image/*, video/*
Max Size: 10MB
```

### Upload Operations

#### Upload User Avatar
```http
POST /storage/v1/object/avatars/users/{userId}/avatar/{fileName}
Authorization: Bearer <access_token>
Content-Type: multipart/form-data

file: <image_data>
```

#### Upload Relative Photo
```http
POST /storage/v1/object/relatives/{relativeId}/{fileName}
Authorization: Bearer <access_token>
Content-Type: multipart/form-data

file: <image_data>
```

#### Generate Signed URL
```http
POST /storage/v1/object/sign/{bucket}/{path}
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "expiresIn": 3600
}
```

---

## Error Responses

### Standard Error Format

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "arabic_message": "بيانات الإدخال غير صالحة",
    "details": {
      "field": "email",
      "issue": "Invalid email format"
    },
    "timestamp": "2024-01-01T12:00:00Z",
    "request_id": "req_uuid"
  }
}
```

### Common Error Codes

| Code | HTTP Status | Description | Arabic Message |
|------|-------------|-------------|----------------|
| VALIDATION_ERROR | 400 | Invalid input data | بيانات الإدخال غير صالحة |
| UNAUTHORIZED | 401 | Authentication required | مطلوب مصادقة |
| FORBIDDEN | 403 | Access denied | الوصول مرفوض |
| NOT_FOUND | 404 | Resource not found | المورد غير موجود |
| CONFLICT | 409 | Resource conflict | تعارض في الموارد |
| RATE_LIMITED | 429 | Too many requests | طلبات كثيرة جداً |
| INTERNAL_ERROR | 500 | Server error | خطأ في الخادم |
| SERVICE_UNAVAILABLE | 503 | Service unavailable | الخدمة غير متاحة |

### Database-Specific Errors

| Error | Description | Resolution |
|-------|-------------|-------------|
| 23505 | Unique constraint violation | Check for duplicate data |
| 23503 | Foreign key violation | Ensure referenced record exists |
| 23514 | Check constraint violation | Validate data constraints |
| 42P01 | Table not found | Check table name and permissions |
| 42501 | Insufficient privileges | Check user permissions |

---

## Rate Limiting

### API Rate Limits

| Endpoint | Rate Limit | Window |
|----------|-------------|---------|
| Authentication | 10 requests | 1 minute |
| User Operations | 100 requests | 1 minute |
| Relative CRUD | 50 requests | 1 minute |
| Interaction CRUD | 100 requests | 1 minute |
| AI Services | 20 requests | 1 minute |
| Storage Upload | 10 requests | 1 minute |

### Rate Limit Headers

```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640995200
```

---

## Pagination

### Cursor-Based Pagination

For large datasets, Silni uses cursor-based pagination:

```http
GET /rest/v1/relatives?user_id=eq.{userId}&order=id.asc&limit=20
```

**Response:**
```json
{
  "data": [...],
  "pagination": {
    "has_more": true,
    "next_cursor": "next_uuid",
    "total_count": 150
  }
}
```

### Offset-Based Pagination

For smaller datasets:

```http
GET /rest/v1/relatives?user_id=eq.{userId}&order=id.asc&limit=20&offset=40
```

---

## Caching Strategy

### HTTP Caching Headers

```http
Cache-Control: public, max-age=300
ETag: "version_hash"
Last-Modified: Wed, 01 Jan 2024 12:00:00 GMT
```

### Client-Side Caching

- **User Data**: 5 minutes
- **Relatives**: 10 minutes
- **Interactions**: 2 minutes
- **Static Data**: 1 hour

---

## Webhooks

### Webhook Events

Silni supports webhooks for real-time integrations:

#### Interaction Created
```json
{
  "event": "interaction.created",
  "data": {
    "interaction_id": "uuid",
    "user_id": "uuid",
    "relative_id": "uuid",
    "type": "call",
    "timestamp": "2024-01-01T12:00:00Z"
  }
}
```

#### Achievement Unlocked
```json
{
  "event": "achievement.unlocked",
  "data": {
    "user_id": "uuid",
    "badge_id": "uuid",
    "badge_name": "Family Champion",
    "points_awarded": 100,
    "timestamp": "2024-01-01T12:00:00Z"
  }
}
```

---

## API Versioning

### Version Strategy

Silni uses URL path versioning:

- Current version: `/v1/`
- Previous versions: `/v0/` (deprecated)
- Future versions: `/v2/`

### Backward Compatibility

- Breaking changes require new version
- Additive changes don't require version bump
- Deprecation period: 6 months
- Migration guides provided for major updates

---

## Testing Endpoints

### Test Environment

- **URL**: `https://staging-api.silni.app`
- **Authentication**: Test accounts available
- **Data**: Reset daily

### Health Check

```http
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "timestamp": "2024-01-01T12:00:00Z",
  "services": {
    "database": "healthy",
    "storage": "healthy",
    "ai": "healthy"
  }
}
```

---

## Riverpod Providers Reference

### Subscription Providers

Location: `lib/core/providers/subscription_provider.dart`

| Provider | Type | Purpose |
|----------|------|---------|
| `subscriptionServiceProvider` | Provider | Singleton SubscriptionService access |
| `subscriptionStateProvider` | StreamProvider | Reactive subscription state stream |
| `subscriptionTierProvider` | Provider | Current subscription tier (derived) |
| `isMaxProvider` | Provider<bool> | Quick check if user has MAX tier |
| `isTrialActiveProvider` | Provider<bool> | Check if trial is active |
| `trialDaysRemainingProvider` | Provider<int> | Days remaining in trial |
| `offeringsProvider` | Provider | RevenueCat offerings (packages) |
| `subscriptionLoadingProvider` | Provider<bool> | Loading state |
| `subscriptionErrorProvider` | Provider<String?> | Error message |
| `featureAccessProvider` | Provider.family<bool, String> | Per-feature access check |
| `reminderLimitProvider` | Provider<int> | Current tier's reminder limit |
| `subscriptionExpirationProvider` | Provider<DateTime?> | Expiration date |
| `isExpiringProvider` | Provider<bool> | Is subscription expiring soon |

### Usage Examples

#### Check Feature Access
```dart
// In a widget
final hasAIChat = ref.watch(featureAccessProvider(FeatureIds.aiChat));

if (!hasAIChat) {
  // Show upgrade prompt or locked state
}
```

#### Check Subscription Tier
```dart
final isMax = ref.watch(isMaxProvider);
final tier = ref.watch(subscriptionTierProvider);

// tier.hasAIChat, tier.hasUnlimitedReminders, etc.
```

#### Watch Trial Status
```dart
final isTrialActive = ref.watch(isTrialActiveProvider);
final daysRemaining = ref.watch(trialDaysRemainingProvider);

if (isTrialActive) {
  Text('$daysRemaining أيام متبقية في الفترة التجريبية');
}
```

### Pattern Animation Providers

Location: `lib/core/providers/pattern_animation_provider.dart`

| Provider | Type | Purpose |
|----------|------|---------|
| `patternAnimationProvider` | StateNotifierProvider | Animation settings management |
| `isPatternAnimationEnabledProvider` | Provider<bool> | Any animation enabled |
| `isTouchEffectsEnabledProvider` | Provider<bool> | Touch effects enabled |

### Real-time Providers

Location: `lib/core/providers/realtime_provider.dart`

| Provider | Type | Purpose |
|----------|------|---------|
| `realtimeServiceProvider` | Provider | RealtimeService singleton |
| `realtimeSubscriptionsProvider` | StateNotifierProvider | Subscription management |
| `autoRealtimeSubscriptionsProvider` | Provider | Auto-manages based on auth |

### Feature IDs Constants

Location: `lib/core/models/subscription_tier.dart`

```dart
class FeatureIds {
  // MAX-only AI features
  static const String aiChat = 'ai_chat';
  static const String messageComposer = 'message_composer';
  static const String communicationScripts = 'communication_scripts';
  static const String relationshipAnalysis = 'relationship_analysis';
  static const String smartRemindersAI = 'smart_reminders_ai';
  static const String weeklyReports = 'weekly_reports';

  // MAX-only other features
  static const String advancedAnalytics = 'advanced_analytics';
  static const String leaderboard = 'leaderboard';
  static const String dataExport = 'data_export';
  static const String unlimitedReminders = 'unlimited_reminders';

  // Free features
  static const String customThemes = 'custom_themes';
  static const String familyTree = 'family_tree';
}
```

---

## Conclusion

This API specification provides comprehensive documentation for all Silni backend services. The API is designed to be:

1. **RESTful**: Following REST principles
2. **Secure**: Authentication and authorization
3. **Scalable**: Pagination and caching
4. **Real-time**: WebSocket subscriptions
5. **Reliable**: Error handling and retries
6. **Performant**: Optimized queries and responses

For implementation examples, refer to the service classes in the `lib/shared/services/` directory of the codebase.