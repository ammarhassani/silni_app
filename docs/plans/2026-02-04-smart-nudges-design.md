# Smart Nudges — Intelligent, Admin-Driven Push Notifications

**Date:** 2026-02-04
**Status:** Draft
**Scope:** New nudge notification system with escalating tone, gender-aware templates, and full admin panel control

---

## Problem

The app has working reminder notifications, but they're generic: `"تذكير يومي — حان وقت التواصل مع عمك سعد"`. Every reminder sounds the same regardless of how long the user has been out of touch. The notification system doesn't know the gap, doesn't vary its tone, and doesn't feel personal.

## Solution

A new **smart nudge** system that runs alongside existing reminders. It proactively detects neglected relatives, picks an escalating-tone template based on the gap duration, respects gender for proper Arabic pronouns, rotates copy so the user never sees the same message twice, and is fully controlled from the admin panel.

**Existing reminder notifications are untouched.**

---

## Design

### 1. Admin Panel: Template Configuration

Extend `admin_notification_templates` with 4 new nullable columns:

| Column | Type | Purpose |
|--------|------|---------|
| `gap_min_days` | INTEGER | Minimum days since contact for this template |
| `gap_max_days` | INTEGER | Maximum days since contact for this template |
| `gender` | TEXT ('male', 'female', NULL) | Gender-specific template. NULL = fallback for either |
| `nudge_cooldown_hours` | INTEGER | Hours before this tier can nudge the same user+relative again |

Existing templates (reminder, streak, badge, level, challenge) are unaffected — their new columns stay NULL.

**Template variables:**
- `{{relative_label}}` — relationship label + name, e.g., "عمك سعد", "أمك"
- `{{days}}` — days since last contact

**Example templates an admin would create:**

| template_key | body_ar | gap_min | gap_max | gender | cooldown_hours |
|---|---|---|---|---|---|
| nudge_gentle_m_1 | {{relative_label}} له {{days}} أيام ما سمع صوتك | 3 | 6 | male | 72 |
| nudge_gentle_f_1 | {{relative_label}} لها {{days}} أيام ما سمعت صوتك | 3 | 6 | female | 72 |
| nudge_gentle_m_2 | وش أخبار {{relative_label}}؟ | 3 | 6 | male | 72 |
| nudge_gentle_f_2 | وش أخبار {{relative_label}}؟ | 3 | 6 | female | 72 |
| nudge_moderate_m_1 | {{relative_label}} له أسبوع ما حد كلمه | 7 | 13 | male | 72 |
| nudge_moderate_f_1 | {{relative_label}} لها أسبوع ما حد كلمها | 7 | 13 | female | 72 |
| nudge_direct_m_1 | {{relative_label}} له أسبوعين ما سمع صوتك | 14 | 29 | male | 48 |
| nudge_direct_f_1 | {{relative_label}} لها أسبوعين ما سمعت صوتك | 14 | 29 | female | 48 |
| nudge_heavy_m_1 | آخر مرة كلمت {{relative_label}} كان قبل شهر | 30 | 999 | male | 24 |
| nudge_heavy_f_1 | آخر مرة كلمت {{relative_label}} كان قبل شهر | 30 | 999 | female | 24 |

The admin panel auto-suggests cooldown hours when `gap_min_days` is set but the value is fully editable.

### 2. Admin Panel UI Changes

The existing `/notifications/templates` page gets:
- Two number inputs: "Gap min days" and "Gap max days" — shown when category is `nudge`
- A gender select: Male / Female / Both (NULL) — shown when category is `nudge`
- A cooldown hours input with auto-suggested default — shown when category is `nudge`
- All existing fields (template_key, title_ar, body_ar, variables, priority, etc.) remain unchanged

### 3. Nudge History Table

New table `nudge_history`:

```sql
CREATE TABLE nudge_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  relative_id UUID NOT NULL REFERENCES relatives(id) ON DELETE CASCADE,
  template_key TEXT NOT NULL,
  gap_days INTEGER NOT NULL,
  sent_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_nudge_history_user_relative ON nudge_history(user_id, relative_id, sent_at DESC);
CREATE INDEX idx_nudge_history_user_sent ON nudge_history(user_id, sent_at DESC);
```

Used for:
- **Cooldown enforcement** — don't nudge same user+relative within cooldown window
- **Template rotation** — exclude recently used template_keys for same user+relative
- **Daily cap** — count nudges sent to user today

### 4. Edge Function: `send-smart-nudges`

New cron job, runs **every hour**.

**Logic:**

```
1. Query all non-archived relatives with last_contact_date, joined with their user_id and gender
2. Calculate days_since_contact for each
3. Filter to relatives where days_since_contact >= 3
4. For each user, sort their overdue relatives by days_since_contact DESC (most overdue first)
5. For each user, limit processing to top 3 most overdue relatives
6. For each user+relative pair:
   a. Query nudge_history: find most recent nudge for this pair
   b. Query admin_notification_templates: find matching templates where
      - category = 'nudge'
      - gap_min_days <= days_since_contact
      - gap_max_days >= days_since_contact
      - gender = relative's gender OR gender IS NULL
      - is_active = true
   c. If most recent nudge exists and sent_at + nudge_cooldown_hours > now → skip
   d. Exclude template_keys used in last 5 nudges for this pair (rotation)
   e. Pick one template randomly from remaining matches
   f. Build message:
      - Map relationship_type to Arabic label (hardcoded lookup)
      - Combine label + full_name → relative_label (e.g., "عمك سعد")
      - Replace {{relative_label}} and {{days}} in template
   g. Call send-push-notification with title from template, body from template
   h. Insert into nudge_history
7. Rate limits per user:
   - Max 1 nudge per cron run (hourly)
   - Max 3 nudges per day
```

**Relationship label lookup (hardcoded in edge function):**

```typescript
const RELATIONSHIP_LABELS: Record<string, { male: string; female: string }> = {
  father:      { male: 'أبوك',    female: 'أبوك'    },
  mother:      { male: 'أمك',     female: 'أمك'     },
  brother:     { male: 'أخوك',    female: 'أخوك'    },
  sister:      { male: 'أختك',    female: 'أختك'    },
  son:         { male: 'ولدك',    female: 'ولدك'    },
  daughter:    { male: 'بنتك',    female: 'بنتك'    },
  grandfather: { male: 'جدك',     female: 'جدك'     },
  grandmother: { male: 'جدتك',    female: 'جدتك'    },
  uncle:       { male: 'عمك',     female: 'عمك'     },
  aunt:        { male: 'عمتك',    female: 'عمتك'    },
  nephew:      { male: 'ابن أخوك', female: 'ابن أخوك' },
  niece:       { male: 'بنت أختك', female: 'بنت أختك' },
  cousin:      { male: 'ولد عمك',  female: 'بنت عمك'  },
  husband:     { male: 'زوجك',    female: 'زوجك'    },
  wife:        { male: 'زوجتك',   female: 'زوجتك'   },
  other:       { male: '',        female: ''        },
};
```

Note: for `other` type or missing gender, use just `full_name` without a label prefix.

### 5. What Stays Untouched

- `send-scheduled-reminders` — user-configured reminders, no changes
- `check-streak-alerts` — streak warnings, no changes
- `send-push-notification` — transport layer, no changes
- All Flutter app code — no changes needed, nudges arrive as regular push notifications
- Existing admin_notification_templates data — existing templates unaffected (NULL gap columns)

### 6. Migration Summary

**Database migration:**
1. ALTER `admin_notification_templates`: add `gap_min_days`, `gap_max_days`, `gender`, `nudge_cooldown_hours`
2. CREATE `nudge_history` table with indexes
3. Seed initial nudge templates (gentle, moderate, direct, heavy × male, female)

**Admin panel:**
4. Update templates page to show new fields when category = 'nudge'
5. Add 'nudge' to category dropdown options

**Edge function:**
6. Create `send-smart-nudges/index.ts`
7. Configure cron schedule (hourly)

### 7. Testing

- Seed test templates in all 4 tiers × 2 genders
- Create test user with relatives at various gap levels
- Verify correct tier matching
- Verify gender-correct template selection
- Verify cooldown enforcement (no double-nudging within window)
- Verify rotation (different template each time)
- Verify daily cap (max 3 per user)
- Verify prioritization (most overdue relative first)
- Deploy to staging, trigger cron manually, confirm push notification arrives on phone
