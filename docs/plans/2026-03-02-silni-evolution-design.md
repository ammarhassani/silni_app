# Silni Evolution Design: From Chore Tracker to Family AI Companion

**Date:** 2026-03-02
**Status:** Approved Design
**Scope:** Subtle rethink + evolution (not rebuild)

---

## Problem Statement

Silni currently feels like a chore tracker with gamification bolted on. Four core weaknesses:

1. **Chore tracker feeling** — logging interactions is manual and pointless
2. **Fake gamification** — competing on who's a better family member via points/leaderboards feels hollow
3. **AI isn't compelling** — locked behind paywall, nobody experiences it
4. **No differentiation** — feels like a glorified contacts app with reminders

## New Vision

**Before:** "Track your family interactions and maintain streaks"
**After:** "Your family's AI companion that helps you stay close — without making connection feel like a task"

**The pitch:** "Silni knows your family. It reminds you that Dad's appointment is tomorrow. It writes Eid messages for your cousins. It notices when you haven't visited grandma. And it celebrates when your whole family stays connected. No points. No scores. Just family."

## Market Context (Research-Backed)

- **Zero direct competitors** in Arabic/Islamic family connection space
- Every single-player personal CRM has died (Fabriq, Garden, UpHabit, Conduit)
- Survivors have auto-sync (Clay) or mutual accountability (Snapchat streaks)
- 1.8B Muslims, smartphone penetration >90% in KSA/UAE — massive blue ocean
- The loneliness epidemic is a global tailwind (US Surgeon General declared national epidemic)
- Islamic digital economy: $7.7T projected by 2025, VC funding surging 58% YoY in MENA

---

## Design Pillars

### Pillar 1: Three-Tier Relative Model

The app treats all relatives the same today. In reality, there are three fundamentally different relationship types:

| Type | Example | App Behavior |
|------|---------|-------------|
| **Household** (same roof) | Parents, siblings you live with | No contact tracking. Quality moment suggestions. "Ask Dad about his day tonight." |
| **Extended** (regular contact) | Grandparents, aunts, uncles, cousins | Gentle contact awareness. Fading plant in garden. Proactive AI nudges. |
| **Distant** (occasion-based) | Far relatives, elderly family | Occasion-only mode. AI sends birthday/Eid reminders + message drafts. |

**Detection:** User classifies during onboarding ("Who do you live with?" / "Regular contact?" / "Occasions only?"). AI can also infer over time from interaction frequency.

### Pillar 2: Kill Gamification, Replace with Compassionate Celebration

**Research basis:**
- Saudi research: more screen time = less respect for parents
- SPSP research: relationship scorekeeping predicts relationship decline
- Academic consensus: points for family connection is "theologically and psychologically wrong" for Islamic audience
- RECIPE framework (Nicholson): Reflection, Exposition, Choice, Information, Play, Engagement

| Remove | Replace With |
|--------|-------------|
| Points/XP system | Nothing. No numerical score for loving family |
| Levels (Beginner to Legend) | Visual growth metaphor: seedling to tree (no numbers) |
| Leaderboard | Family Activity — collective: "Your family connected 45 times this month" |
| "Gaming Center" screen | "My Journey" (رحلتي) — timeline of meaningful moments |
| Badges for volume | Milestones for meaning: "First Ramadan you contacted everyone" |
| Points notifications | Warmth: "Your grandmother smiled today because you called" |

**Streaks:** Keep but reframe. No streak-break panic. Compassionate recovery: "Welcome back — your family missed you" instead of "You lost your 42-day streak."

### Pillar 3: AI as Invisible Infrastructure

**Research basis:**
- Best AI apps (Perplexity, Arc, Notion AI) make AI felt, not seen
- Proactive AI (push value) beats reactive AI (wait for questions)
- "The app should push you OUT of the phone" — not maximize screen time

The AI doesn't live on a separate screen. It powers everything:

| Where AI Shows Up | How |
|---|---|
| Home briefing card | Proactive: surfaces the ONE thing to do today |
| Quick connect | Auto-logs type if user mentioned it in chat |
| Push notifications | Context-aware: "Your aunt mentioned she was unwell" |
| Occasion messages | AI writes, user taps send |
| Garden visualization | AI determines which plants bloom vs fade |
| Family feed | AI summarizes: "Your family was really connected this Ramadan" |
| Chat (premium depth) | "How do I reconnect with my brother after our argument?" |

### Pillar 4: Effortless Interaction Logging

**Current:** Pick relative -> Choose type (6 options) -> Add duration -> mood -> rating -> notes -> photos -> Save

**New:**
- **One-tap:** Tap face on home screen -> Done. Logged as "connected."
- **Natural language (premium):** Tell wasel "I visited grandma today" -> AI extracts type=visit, relative=grandma
- **Optional detail:** After quick-log, subtle "add details?" expandable for power users

**Simplified types:**
- Old: Call, Visit, Message, Gift, Event, Other (6 types)
- New: Connected (default), Met up (in-person) — types preserved in data model for AI analysis but users rarely select manually

### Pillar 5: Social Layer — Family Groups as Survival Mechanism

**Research:** Every solo-player family app died. Family groups = retention.

| Feature | Purpose |
|---|---|
| Family activity feed | Warm awareness: "Ahmed checked on grandma today" |
| Shared garden | Collective visualization that blooms when family connects |
| Occasion coordination | "Grandma's birthday Saturday — who's calling?" |
| Collective celebration | Silni Wrapped: "Your family connected 50 times this Ramadan" |
| Voice notes (premium) | Quick audio messages through the app |

---

## AI Knowledge Pipeline: How Wasel Gets "Jacked"

### Layer 0: Base Knowledge (Pre-installed)
- Islamic family relationship structures
- Saudi cultural norms and communication patterns
- Arabic dialect awareness (Gulf/Saudi colloquial)
- Common family dynamics and tension patterns

### Layer 1: Smart Onboarding (Minutes 1-5)
- Wasel-guided conversational onboarding (not forms)
- Phone contacts import (name, number, birthday, photo)
- Relationship classification: household / extended / distant
- User identifies priority focus relative

### Layer 2: One-Question Engine (Days 1-14)
- After each quick-connect, wasel asks ONE follow-up question (3-4x/week max)
- Questions rotate through: interests, health, communication style, best time, sensitive topics, life events, relationship dynamic
- Each answer stored as a permanent AI memory
- After 14 days: ~30-40 facts about the family

### Layer 3: Conversation Mining (Ongoing, Premium)
- Full chat conversations mined for facts via extractMemories()
- Extracts only what USER said (not AI)
- Categories: user_preference, family_dynamic, important_date, conversation_insight
- Importance rating 1-10
- The more they chat, the smarter wasel gets

### Layer 4: Pattern Recognition (Weeks 2+)
- Detects from interaction timestamps:
  - "User calls Dad every Friday"
  - "User connects more during Ramadan"
  - "3 weeks without Uncle contact — unusual"
  - "User always messages, never calls Grandma"
- Learns user's rhythm (skips Sundays, prefers evenings, etc.)

### Layer 5: Compound Insights (Month 2+)
- Combines multiple facts into smart suggestions:
  - Birthday + hobby + health concern = "Surprise Dad with a fishing trip, and ask about his blood sugar"
  - Gap + interest + event = "Uncle's son is graduating — great excuse to reconnect"
- This is the "magic" — deeply personal, context-rich suggestions

### Layer 6: Family Group Intelligence (If Group)
- Detects gaps: "Nobody called Grandma this week"
- Coordinates: "Your brother called Dad yesterday — focus on Mom today"
- Celebrates: "Your family connected 50 times this Ramadan"
- Plans: "Eid next week — coordinate a gathering?"

### Layer 7: Seasonal Intelligence (Calendar-Aware)
- Islamic calendar: Ramadan preparation, Eid greetings, Jumu'ah prompts
- Cultural calendar: summer vacation, back to school, wedding season
- Personal calendar: birthdays, anniversaries, medical appointments

---

## Home Screen Redesign

Design principle: 30-second sessions. Open -> see briefing -> tap connect -> close. Push user OUT of phone.

```
+-------------------------------+
|  Greeting + time-aware salaam  |
|                               |
|  AI Briefing Card (1 card)    |
|  "Dad's appointment tomorrow  |
|   — want to check on him?"   |
|        [Call]  [Message]      |
|                               |
|  Quick Connect Row            |
|  (face avatars, one-tap)      |
|                               |
|  Relationship Garden          |
|  (visual: blooming/fading     |
|   plants, not numbers)        |
|                               |
|  Family This Week             |
|  (collective, not competitive)|
|                               |
+-------------------------------+
```

---

## Monetization: Reverse Trial Model

**Research:** Reverse trials convert 7-21% vs 3-15% for traditional freemium.

**Day 1-14:** Full premium for every new user. They experience everything.

**After trial — strategic downgrade:**

| Feature | Free | Premium (MAX) |
|---------|------|---------------|
| Quick connect (one-tap) | Unlimited | Unlimited |
| Relatives (all 3 types) | Unlimited | Unlimited |
| Family tree | Full | Full |
| Streaks + journey milestones | Full | Full |
| Daily AI briefing | 1 card (teaser) | Unlimited |
| Push notification nudges | Basic (time-based) | Smart (context-aware AI) |
| Occasion messages | 1/month | Unlimited |
| Full wasel chat | No | Yes |
| Relationship analysis | No | Yes |
| Communication scripts | No | Yes |
| Natural language logging | No | Yes |
| Garden visualization | Simple (bloom/fade) | Rich (detailed health, history) |
| Family feed | View only | Post, voice notes, coordination |
| Silni Wrapped | Basic summary | Full AI-powered celebration |
| Reminders | 1 | Unlimited |

---

## What This Is NOT

- NOT a chat app (don't compete with WhatsApp)
- NOT a photo gallery (don't compete with Google Photos)
- NOT a family CRM (the word "CRM" kills the soul)
- NOT a game about family (no scores for love)
- NOT something that maximizes screen time (pushes you to real connection)

## What This IS

- A family awareness layer — know what matters without asking
- An AI that coaches you to be a better family member
- A bridge between you and your relatives
- A celebration of family connection, not a measurement of it
- The only app serving 1.8B Muslims' most emphasized social obligation

---

## Implementation Priority (Suggested)

### Phase 1: Foundation (De-cringe + Quick Log)
- Implement three-tier relative model (household/extended/distant)
- Replace interaction form with one-tap quick connect
- Rebrand Gaming Center to "My Journey" (رحلتي)
- Remove points display from home screen
- Reframe streak language to compassionate mode

### Phase 2: AI Evolution
- Move AI briefing card to home screen (free tier: 1/day)
- Implement one-question engine (progressive fact gathering)
- Redesign smart notifications from streak-panic to context-aware warmth
- Implement reverse trial (14 days full access)

### Phase 3: Home Screen Redesign
- New home layout: briefing card + quick connect + garden + family activity
- Garden visualization (relationship health as plants)
- Remove premium banner rotation from home

### Phase 4: Social Layer
- Family activity feed for groups
- Collective celebration stats (not competitive)
- Occasion coordination features
- Voice notes (premium)

### Phase 5: Advanced AI
- Compound insights (combining facts across layers)
- Seasonal intelligence (Islamic calendar integration)
- Conversational onboarding (wasel-guided, not forms)
- Family group AI intelligence

---

## Complete Feature Fate Map

### Legend
- **Unchanged** — No changes needed, works well
- **Kept + Enhanced** — Works, gets better
- **Redesigned** — Same purpose, new execution
- **Removed** — Cut from the app

### Bottom Navigation (5 tabs)

| Current Tab | Fate | New Version |
|---|---|---|
| الرئيسية (Home) | Redesigned | AI-first home: briefing card, quick connect, garden |
| الأقارب (Relatives) | Kept + Enhanced | Add household/extended/distant filter tags |
| الإنجازات (Achievements) | Redesigned | Becomes "رحلتي" (My Journey) — timeline, not gaming center |
| واصل (AI Hub) | Kept + Enhanced | Hub stays as deep-dive portal; wasel also embedded in home |
| الإعدادات (Settings) | Unchanged | |

### Authentication (6 screens)

| Screen | Fate | Notes |
|---|---|---|
| Splash | Unchanged | |
| Onboarding | Redesigned | Wasel-guided conversational flow |
| Login | Unchanged | |
| Sign Up | Unchanged | |
| Email Verification | Unchanged | |
| Premium Onboarding | Unchanged | |

### Home Screen Widgets

| Widget | Fate | Notes |
|---|---|---|
| Header/Greeting | Kept | Warm, stays |
| Premium Upgrade Banner | Removed | Moved to settings/profile. Home stays clean |
| Message Widget | Kept | Admin banners still useful |
| Islamic Reminder (Hadith) | Kept, moved | Below the fold or in My Journey. Not competing with AI briefing |
| Occasion Card | Merged | Into AI briefing card |
| Proactive Insight Card | Merged | IS the AI briefing card now |
| Quick Actions (5 buttons) | Simplified | Keep: family tree, add relative. Remove redundant shortcuts |
| Quick Log Faces | Redesigned | Primary "Quick Connect" row — one tap = done |
| Family Circles | Kept | If user has groups |
| AI Priority Contacts | Merged | Into AI briefing |
| Due Reminders | Kept, deprioritized | Below the fold |
| Today's Activity | Kept | |
| Streak Badge Bar | Redesigned | Softer — no panic framing |
| Setup Reminders prompt | Removed | One-time, not permanent |
| Gamification Listener | Redesigned | Gentle milestones, no points popups |

New home widgets: AI Briefing Card, Relationship Garden, Family This Week

### Relatives Management (5 screens)

| Screen | Fate | Notes |
|---|---|---|
| Relatives List | Kept + Enhanced | Add type filter tabs (🏠📞🌙) |
| Relative Detail | Kept + Enhanced | Show type tag, adapt display per type |
| Add Relative | Redesigned | Simplified, conversational adds most. Type picker added |
| Edit Relative | Kept | Add type picker |
| Contact Import | Kept | Good as-is |

### Interaction Logging

| Feature | Fate | Notes |
|---|---|---|
| Full interaction form | Demoted | Hidden behind "add details?" expander |
| 6 interaction types | Simplified | Default: "connected." Types in data model for AI |
| Voice note recording | Kept | Low friction, good feature |
| Quick Log Faces | Redesigned | Primary one-tap connect |

### Reminders (2 screens)

| Screen | Fate | Notes |
|---|---|---|
| Reminders Screen | Unchanged | |
| Reminders Due Screen | Unchanged | |
| Smart nudge notifications | Redesigned | Warmth over urgency in language |

### Family Tree (1 screen)

| Feature | Fate | Notes |
|---|---|---|
| Family Tree Screen | **Unchanged** | Great feature, no changes needed |
| Tree layout algorithm | **Unchanged** | Works well |
| Edge inference | **Unchanged** | Smart, keep |
| Screenshot/share | **Unchanged** | |
| Access: home quick action | **Kept** | |
| Access: relative detail | **Kept** | |

### Gamification (5 screens) — Major Redesign

| Feature | Fate | New Version |
|---|---|---|
| Gaming Center Screen | Redesigned | "رحلتي" (My Journey) — meaningful moments timeline |
| Points/XP display | Removed from UI | Still tracked in backend for AI analysis |
| Level system (10 levels) | Removed | Visual growth: 🌱→🌿→🌳, no numbers |
| Badges Screen | Redesigned | Volume badges → meaning badges |
| Leaderboard | Redesigned | "Family Activity" — collective, not competitive |
| Challenges Screen | Redesigned | Soft suggestions, not missions |
| Detailed Stats | Redesigned | Insights over numbers |
| Level Up Modal | Removed | |
| Badge Unlock Modal | Redesigned | Softer celebration |
| Streak Milestone Modal | Redesigned | Compassionate framing |
| Floating Points Overlay | Removed | |
| Confetti effects | Reduced | Only for truly meaningful milestones |

### AI Assistant (7 screens)

| Screen | Fate | Notes |
|---|---|---|
| AI Hub (bento grid) | Kept | Deep-dive portal, wasel also on home now |
| AI Chat | Kept | Premium, no changes |
| Memory Viewer | Kept | |
| Message Composer | Kept | |
| Relationship Analysis | Kept | |
| Communication Scripts | Kept | |
| Weekly Report | Kept | |
| Occasion Messages | Kept + partially free | 1/month free |

New AI: briefing card (home), one-question engine, conversational onboarding, context-aware notifications, natural language logging

### Wrapped (2 screens)

| Screen | Fate | Notes |
|---|---|---|
| Monthly Wrapped | Kept + Enhanced | More narrative, less numbers |
| Yearly Wrapped | Kept + Enhanced | "Silni Wrapped" — the shareable celebration moment |

### Family Groups (3 screens)

| Screen | Fate | Notes |
|---|---|---|
| Create Group | Unchanged | |
| Group Detail | Kept + Enhanced | Add family activity feed |
| Join Group | Unchanged | |

New: family activity feed, collective stats, occasion coordination, voice notes (premium)

### Notifications (2 screens)

| Screen | Fate | Notes |
|---|---|---|
| Notification Settings | Unchanged | |
| Notification History | Unchanged | |
| Notification content | Redesigned | All language rewritten: warmth over urgency |

### Settings & Profile

| Screen | Fate | Notes |
|---|---|---|
| Settings Screen | Unchanged | |
| Profile Screen | Redesigned slightly | Remove points/level, add journey visualization |
| All other settings | Unchanged | |

### Subscription (3 screens)

| Screen | Fate | Notes |
|---|---|---|
| Paywall Screen | Redesigned | Reverse trial model, AI-value focused copy |
| Session Interstitial | Redesigned | Less frequent, smarter timing |
| Premium Banner | Removed from home | Moved to settings |

### Totals

| Status | Count |
|---|---|
| Unchanged | 29 |
| Kept + Enhanced | 12 |
| Redesigned | 18 |
| Removed | 5 (points overlay, level-up modal, premium home banner, setup prompt, floating points) |

**Nothing core is deleted.** Family tree, relatives, reminders, AI screens, wrapped, groups, settings — all stay. The evolution is reframing (gamification → journey), simplifying (interaction logging), and adding (AI briefing, garden, family feed).

---

## Sources

### Competitive Landscape
- Fabriq, Clay, Garden, Monica HQ — all analyzed
- 20+ failed personal CRM startups documented (Dex analysis)
- Zero Arabic/Islamic family connection apps found

### Gamification Research
- Yu-kai Chou Octalysis Framework: White Hat vs Black Hat drives
- Sebastian Deterding: "Pointsification" critique
- Scott Nicholson RECIPE Framework for meaningful gamification
- SPSP research: scorekeeping predicts relationship decline
- Saudi Arabia study: screen time negatively correlates with parental respect
- Nir Eyal ethical litmus test for habit-forming design

### AI Research
- Perplexity, Notion AI, Arc Browser design patterns
- Google Now / Alexa+ / Apple Intelligence proactive AI models
- Spotify Wrapped personalization model
- Reverse trial conversion data (7-21% vs 3-15%)
- Arabic NLP challenges and emerging solutions
- Character.AI / Pi.ai / Replika companion model analysis
