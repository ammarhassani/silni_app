# Social Media Suite — Admin Panel Design

**Date:** 2026-01-30
**Status:** Approved
**Scope:** New `/social` route group in silni-admin

## Overview

A full social media marketing suite inside the Silni admin panel. Covers AI-powered content generation, editorial review, scheduling, direct publishing to Twitter/X and Instagram, and engagement analytics with conversion tracking.

## Target Platforms

- Twitter/X (free API tier — tweet.write access)
- Instagram (free via Meta/Facebook Graph API — requires linked Business Page)

## Content Types

- Islamic content: daily hadith shares, Quran verses, family relationship tips, occasion-based posts (Ramadan, Eid, Jumu'ah)
- App marketing: feature announcements, user testimonials, app tips, download CTAs, behind-the-scenes

## Architecture

### Route Structure

```
(dashboard)/social/
├── generate/     — AI content generation & batch review queue
├── calendar/     — Visual schedule of upcoming posts
├── accounts/     — Connect & manage Twitter/X and Instagram
├── analytics/    — Engagement metrics & conversion tracking
└── templates/    — Reusable post templates & brand voice config
```

### Data Flow

```
AI Generation → Review Queue → Approved → Scheduled Calendar → Publisher (cron) → Platform APIs
                                                                       ↓
                                                              Analytics Collector ← Platform APIs
```

### New Supabase Tables

- `social_accounts` — Connected platform credentials (encrypted tokens)
- `social_posts` — All posts with status (draft/queued/approved/scheduled/published/failed)
- `social_templates` — Reusable content templates
- `social_analytics` — Engagement snapshots per post
- `social_campaigns` — Group posts into campaigns for conversion tracking

### Publishing Mechanism

A Supabase Edge Function runs on a cron schedule (every 5 minutes), picks up posts where `scheduled_at <= now()` and `status = 'scheduled'`, publishes them via platform APIs, and updates the status.

---

## Page Designs

### 1. Generate (`/social/generate`)

Two parts: a generation form and a review queue.

**Generation form:**
- Content type dropdown: hadith share, Quran verse, family tip, feature highlight, app update, download CTA, occasion post
- Platform toggle: Twitter/X, Instagram, or both (generates platform-appropriate versions — 280 chars for Twitter, longer caption + hashtags for Instagram)
- Batch size: 1–14 posts (default: 7 for a week)
- Date range: what period to schedule for
- Tone: inspirational, educational, conversational, promotional
- Occasion (optional): Ramadan, Eid, Jumu'ah, etc. — pulls from existing occasions data

**AI generation** uses DeepSeek with a system prompt tailored to Silni's brand voice. For each post it produces:
- Post text (Arabic + English variants)
- Suggested hashtags
- Suggested posting time (based on best engagement windows)
- Image prompt (for Instagram — images attached manually)
- UTM-tagged link to App Store

**Review queue** — list/card view of generated posts with status badges:
- Queued (yellow) — awaiting review
- Approved (green) — ready to schedule
- Rejected (red) — discarded
- Each card: edit inline, approve, reject, regenerate buttons
- Bulk actions: approve all, reject all

Once approved, posts land on the calendar at their suggested times (editable).

### 2. Calendar (`/social/calendar`)

Visual overview of all scheduled and published posts.

**Views:**
- Month view — color-coded dots per day (blue for Twitter, pink for Instagram, green for published, red for failed)
- Week view — time slots showing exact post times with preview cards
- List view — table with sorting and filtering

**Post card shows:**
- Platform icon
- Truncated post text
- Scheduled time (always local browser time, no timezone labels)
- Status badge
- Click to expand: full preview, edit, reschedule, or cancel

**Features:**
- Drag and drop to reschedule between time slots
- Optimal time suggestions — highlights best posting windows based on past engagement data (initially seeded with general Middle East peak times)
- Conflict detection — warns if two posts scheduled too close (configurable minimum gap, default 2 hours)
- Recurring posts — mark a template as recurring (e.g. weekly Jumu'ah reminder every Friday)
- Pause/resume — one-click pause all scheduled posts

**Failed post handling:**
- Status changes to "failed" with error details
- Toast notification on next admin login
- One-click retry or reschedule

**All times displayed in the user's local browser time. No timezone labels.**

### 3. Accounts (`/social/accounts`)

Manage connected social media accounts.

**Connection card per platform:**
- Platform logo and account name/handle
- Connection status (connected/expired/not connected)
- Last successful post date
- Connect/disconnect button

**Twitter/X connection:**
- OAuth 2.0 with PKCE (Twitter API v2)
- Scopes: `tweet.write`, `tweet.read`, `users.read`
- Callback redirects back to admin panel
- Access + refresh tokens stored encrypted in `social_accounts`
- Auto-refresh before expiry

**Instagram connection:**
- OAuth via Facebook Login (Instagram Graph API)
- Scopes: `instagram_basic`, `instagram_content_publish`, `pages_read_engagement`
- Same encrypted storage and auto-refresh

**Token management:**
- Encrypted in Supabase using `pgcrypto`
- Edge Function refreshes tokens proactively before expiry
- Expired tokens trigger "expired" status + admin warning banner

**Security:**
- API keys/secrets in Supabase Edge Function env vars, never exposed to browser
- All OAuth flows server-side via Next.js API routes

### 4. Analytics (`/social/analytics`)

Engagement metrics and conversion tracking.

**Overview cards:**
- Total posts published (this week/month)
- Total engagement (likes + comments + shares)
- Top performing post
- Link clicks (total UTM clicks)
- Estimated conversions (clicks to App Store)

**Post performance table:**
- Sortable by: date, platform, likes, comments, shares, link clicks
- Filter by: platform, content type, date range, campaign
- Each row: post text preview, platform, engagement breakdown, click count
- Click row for full details

**Charts:**
- Engagement over time — line chart, 30/60/90 days
- Content type breakdown — bar chart comparing content type performance
- Platform comparison — Twitter vs Instagram side-by-side
- Best posting times — heatmap of days/hours with highest engagement (feeds back into AI scheduling)

**Conversion tracking:**
- Every link gets UTM parameters: `utm_source=twitter|instagram`, `utm_medium=social`, `utm_campaign={campaign_name}`, `utm_content={post_id}`
- Lightweight redirect endpoint logs clicks before forwarding to App Store
- Funnel: post → click → App Store visit

**Data collection:**
- Edge Function runs daily, fetches engagement from Twitter/Instagram APIs for published posts, stores in `social_analytics`

### 5. Templates (`/social/templates`)

Reusable content structures and AI brand voice config.

**Brand voice config (top of page):**
- Tone guidelines — free text describing Silni's voice
- Arabic dialect preference — MSA or colloquial mix
- Hashtag sets — predefined groups by content type
- Banned words/phrases — words the AI must never use
- These settings feed into the AI system prompt

**Post templates:**
- Each template: name, content type, platform, text structure with `{{variables}}`, default hashtags
- Example: "Daily Hadith" for Twitter — `📖 {{hadith_text}}\n\n— {{narrator}}\n\n{{hashtags}}\n\nحمّل صِلني: {{link}}`
- Templates used for manual creation or as structure hints for AI generation

**Template management:**
- Create, edit, duplicate, delete
- Preview rendering per platform
- Active/archived status
- Tag by campaign or content type

---

## Tech Stack (Consistent with Existing Admin Panel)

- Next.js 14 App Router
- shadcn/ui components
- React Query for data fetching
- Recharts for analytics charts
- Supabase (database, auth, edge functions, pgcrypto)
- DeepSeek API for AI content generation
- Twitter API v2 (OAuth 2.0 PKCE)
- Instagram Graph API (Facebook OAuth)

## Edge Functions (New)

- `social-publisher` — Cron (every 5 min), publishes scheduled posts
- `social-analytics-collector` — Cron (daily), fetches engagement metrics
- `social-token-refresh` — Cron (hourly), refreshes expiring OAuth tokens
- `social-click-redirect` — HTTP endpoint, logs UTM clicks and redirects to App Store
