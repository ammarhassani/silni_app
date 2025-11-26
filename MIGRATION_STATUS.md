# Supabase Migration Status

**Last Updated:** 2025-11-26
**Current Phase:** Phase 2 Complete, Phase 3 In Progress
**Environment:** Staging (APP_ENV=staging)

---

## ✅ Phase 1: Foundation (100% Complete)

### Supabase Projects
- ✅ Staging project: `dqqyhmydodjpqboykzow`
- ✅ Production project: `bapwklwxmwhpucutyras`
- ✅ Credentials stored in `.env`

### Database Schema
- ✅ **users** table - User profiles with gamification
- ✅ **relatives** table - Family members with relationships
- ✅ **interactions** table - Interaction tracking
- ✅ **reminder_schedules** table - Reminder configurations
- ✅ **hadith** table - Islamic content (8 hadith seeded)
- ✅ **fcm_tokens** table - Push notification tokens

### Database Features
- ✅ All indexes created for performance
- ✅ Row Level Security (RLS) enabled on all tables
- ✅ Auto-updating timestamps via triggers
- ✅ RPC functions:
  - `delete_user_account()` - Cascading user deletion
  - `record_interaction_and_update_relative()` - Atomic updates
  - `get_user_statistics()` - Aggregated stats

### Configuration
- ✅ `supabase_config.dart` created
- ✅ Environment-based configuration (staging/production)
- ✅ Supabase Flutter package added (^2.9.0)
- ✅ Unused Firebase packages removed (analytics, storage, auth, firestore)
- ✅ Kept Firebase packages: core, messaging (for FCM)

---

## ✅ Phase 2: Authentication Layer (100% Complete)

### Files Migrated
- ✅ `lib/core/config/supabase_config.dart` - Supabase initialization
- ✅ `lib/shared/services/auth_service.dart` - Supabase Auth integration
- ✅ `lib/features/auth/providers/auth_provider.dart` - Updated providers
- ✅ `lib/main.dart` - Supabase initialization added

### Authentication Features
- ✅ Sign up with email/password
- ✅ Sign in with email/password
- ✅ Sign out
- ✅ Password reset
- ✅ Account deletion (with RPC function)
- ✅ User profile creation in database
- ✅ Last login tracking
- ✅ Arabic error messages

### Changes Made
- `UserCredential` → `AuthResponse`
- `FirebaseAuth` → `SupabaseClient.auth`
- `User.uid` → `User.id` (in auth_service only)
- `FirebaseAuthException` → `AuthException`
- Firestore user document → Supabase users table insert

---

## 🔄 Phase 3: Data Layer (20% Complete)

### ❌ Blockers Preventing Build

**Critical Issues (50+ files affected):**

1. **User Object Property Change**
   - Problem: Firebase uses `user.uid`, Supabase uses `user.id`
   - Affected: ~20 files in `lib/features/`
   - Files: home_screen, relatives_screen, reminders_screen, profile_screen, etc.
   - Fix: Global find-replace `user?.uid` → `user?.id` and `user.uid` → `user.id`

2. **Models Still Using Firebase**
   - `lib/shared/models/relative_model.dart` - Uses Timestamp, DocumentSnapshot
   - `lib/shared/models/interaction_model.dart` - Uses Timestamp, DocumentSnapshot
   - `lib/shared/models/hadith_model.dart` - Uses Timestamp, DocumentSnapshot
   - `lib/shared/models/reminder_schedule_model.dart` - Uses Timestamp, DocumentSnapshot
   - Fix: Replace `fromFirestore()` with `fromJson()`, remove Firebase imports

3. **Services Still Using Firestore**
   - `lib/shared/services/relatives_service.dart` - Uses FirebaseFirestore
   - `lib/shared/services/interactions_service.dart` - Uses FirebaseFirestore
   - `lib/shared/services/hadith_service.dart` - Uses FirebaseFirestore
   - `lib/shared/services/reminder_schedules_service.dart` - Uses FirebaseFirestore
   - `lib/shared/services/notification_service.dart` - Uses Firestore for FCM tokens
   - Fix: Replace FirebaseFirestore with SupabaseClient, update all queries

4. **Profile Screen Using Firebase Directly**
   - `lib/features/profile/screens/profile_screen.dart`
   - Uses FirebaseAuth.instance and FirebaseFirestore.instance directly
   - Fix: Use auth_service and create users_service

---

## 📋 Remaining Tasks

### High Priority (Breaks Build)

1. **Replace `.uid` with `.id`** (20 occurrences)
   ```dart
   // Find: user?.uid
   // Replace: user?.id

   // Also find: user.uid
   // Replace: user.id
   ```

2. **Migrate Relative Model**
   - Remove: `import 'package:cloud_firestore/cloud_firestore.dart'`
   - Replace: `fromFirestore()` → `fromJson()`
   - Replace: `toFirestore()` → `toJson()`
   - Replace: `Timestamp` → `DateTime` (ISO 8601 strings)
   - Replace: `DocumentSnapshot` → `Map<String, dynamic>`

3. **Migrate Relatives Service**
   - Replace: `FirebaseFirestore` → `SupabaseClient`
   - Replace: `.collection('relatives')` → `.from('relatives')`
   - Replace: `.snapshots()` → `.stream(primaryKey: ['id'])`
   - Replace: `.where()` → `.eq()`, `.gte()`, etc.
   - Replace: `FieldValue.increment()` → SQL increment or RPC call
   - Replace: `Timestamp.now()` → `DateTime.now().toIso8601String()`

4. **Migrate Interaction Model** (same pattern as Relative)

5. **Migrate Interactions Service** (same pattern as Relatives)

6. **Migrate Hadith Model & Service**

7. **Migrate ReminderSchedule Model & Service**

8. **Migrate Notification Service** (FCM tokens → Supabase)

### Medium Priority (After Build Works)

9. **Create Users Service**
   - Handle user profile CRUD
   - Move logic from profile_screen.dart

10. **Update Profile Screen**
    - Use users_service instead of direct Firebase calls
    - Remove Firebase imports

11. **Test All Features**
    - Auth flow (signup, login, logout, password reset)
    - Relatives CRUD
    - Interactions CRUD
    - Reminders CRUD
    - Profile updates
    - Account deletion

12. **Update remaining screens** that might have Firebase references

### Low Priority (Cleanup)

13. **Remove Firebase Config** (optional - keep if FCM works)

14. **Code Cleanup**
    - Remove unused imports
    - Update comments
    - Remove Firebase-specific workarounds

15. **Documentation**
    - Update README
    - Add Supabase setup guide
    - Document environment variables

---

## 🔧 Quick Fix Script

To get the app building quickly, run these steps in order:

### Step 1: Fix User.uid → User.id

```bash
# In lib/features directory, replace all user.uid with user.id
find lib/features -name "*.dart" -exec sed -i 's/user\.uid/user.id/g' {} \;
find lib/features -name "*.dart" -exec sed -i 's/user?\.uid/user?.id/g' {} \;
```

### Step 2: Migrate Models (Priority Order)

1. `relative_model.dart`
2. `interaction_model.dart`
3. `hadith_model.dart`
4. `reminder_schedule_model.dart`

**Changes needed in each model:**
- Remove: `import 'package:cloud_firestore/cloud_firestore.dart';`
- Change: `factory X.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc)`
- To: `factory X.fromJson(Map<String, dynamic> json, String id)`
- Change: `Map<String, dynamic> toFirestore()`
- To: `Map<String, dynamic> toJson()`
- Replace: `Timestamp.fromDate()` → `DateTime.toIso8601String()`
- Replace: `timestamp.toDate()` → `DateTime.parse()`

### Step 3: Migrate Services (Priority Order)

1. `relatives_service.dart`
2. `interactions_service.dart`
3. `hadith_service.dart`
4. `reminder_schedules_service.dart`
5. `notification_service.dart`

**Changes needed in each service:**
- Remove: `FirebaseFirestore _firestore = FirebaseFirestore.instance;`
- Add: `SupabaseClient _supabase = SupabaseConfig.client;`
- Replace Firestore queries with Supabase queries
- Update real-time streams
- Handle timestamps as ISO 8601 strings

---

## 📊 Migration Mapping Reference

### Firebase → Supabase Equivalents

| Firebase | Supabase |
|----------|----------|
| `FirebaseFirestore.instance` | `SupabaseConfig.client` |
| `.collection('name')` | `.from('name')` |
| `.doc(id)` | `.select().eq('id', id).single()` |
| `.add(data)` | `.insert(data)` |
| `.set(data)` | `.insert(data)` or `.upsert(data)` |
| `.update(data)` | `.update(data).eq('id', id)` |
| `.delete()` | `.delete().eq('id', id)` |
| `.where('field', isEqualTo: value)` | `.eq('field', value)` |
| `.where('field', isGreaterThan: value)` | `.gt('field', value)` |
| `.where('field', isLessThan: value)` | `.lt('field', value)` |
| `.orderBy('field')` | `.order('field')` |
| `.limit(n)` | `.limit(n)` |
| `.snapshots()` | `.stream(primaryKey: ['id'])` |
| `.get()` | `.select()` |
| `.count()` | `.count()` |
| `Timestamp.now()` | `DateTime.now().toIso8601String()` |
| `Timestamp.fromDate(date)` | `date.toIso8601String()` |
| `timestamp.toDate()` | `DateTime.parse(string)` |
| `FieldValue.increment(1)` | Use RPC or SQL: `count = count + 1` |
| `FieldValue.serverTimestamp()` | `DEFAULT now()` or `DateTime.now()` |
| `DocumentSnapshot` | `Map<String, dynamic>` |
| `User.uid` | `User.id` |
| `UserCredential` | `AuthResponse` |
| `FirebaseAuthException` | `AuthException` |
| `FirebaseException` | `PostgrestException` |

### Real-time Streams

**Firebase:**
```dart
_firestore
  .collection('relatives')
  .where('userId', isEqualTo: uid)
  .where('isArchived', isEqualTo: false)
  .orderBy('priority')
  .snapshots()
  .map((snapshot) => snapshot.docs.map((doc) =>
    Relative.fromFirestore(doc)).toList());
```

**Supabase:**
```dart
_supabase
  .from('relatives')
  .stream(primaryKey: ['id'])
  .eq('user_id', uid)
  .eq('is_archived', false)
  .order('priority')
  .map((data) => data.map((json) =>
    Relative.fromJson(json, json['id'])).toList());
```

---

## 🎯 Current Status

**What Works:**
- ✅ Supabase initialization
- ✅ Database schema with RLS
- ✅ Authentication (signup, login, logout, password reset)
- ✅ User profile creation in database

**What Doesn't Work:**
- ❌ App doesn't build (50+ compilation errors)
- ❌ All features using relatives, interactions, hadith, reminders
- ❌ Profile screen
- ❌ Any screen displaying data from database

**Next Immediate Steps:**
1. Fix all `user.uid` → `user.id` references
2. Migrate Relative model and RelativesService
3. Test if relatives features work
4. Continue with other models/services

---

## 📞 Support

If you encounter issues:
1. Check Supabase Dashboard → Logs for errors
2. Check browser console for client-side errors
3. Verify RLS policies allow operations
4. Check API keys are correct in .env

**Supabase Staging Dashboard:**
https://supabase.com/dashboard/project/dqqyhmydodjpqboykzow

**Supabase Production Dashboard:**
https://supabase.com/dashboard/project/bapwklwxmwhpucutyras
