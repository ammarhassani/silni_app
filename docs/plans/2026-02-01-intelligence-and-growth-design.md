# Silni Intelligence & Growth Engine Design

**Date:** 2026-02-01
**Status:** Draft
**Scope:** App-wide intelligence overhaul, shareability system, family network, and organic growth engine

---

## Core Philosophy

**Intelligence is not a feature. It is how the app thinks.**

Every time the app asks the user a question, that is a failure. Every manual form field, every dropdown menu, every configuration step is friction that kills retention and word-of-mouth. The app should answer its own questions, infer what it can, and only confirm with the user when genuinely unsure.

The goal: people say "التطبيق ذكي" (the app is smart) — and that alone makes them tell others about it.

---

## Part 1: Intelligence Layer — Every Corner of the App

### 1.1 Adding Relatives — Stop Interrogating the User

**Current state:** User fills a form with name, relationship type (18+ dropdown options), phone, gender, priority, avatar. Feels like paperwork.

**Intelligent version:**

- **Import from contacts, infer everything.** User picks a contact. The app reads name, phone number, and contact labels/groups. Auto-fills all fields. User sees a pre-filled card and taps confirm.

- **Contextual relationship selection.** When adding manually, user types a name. App asks "مين هالشخص لك؟" with smart options based on what's *missing* from the tree. If no parents exist, parents appear first. If parents exist but no siblings, siblings appear first. The app knows what gaps exist and guides the user to fill them. Max 3 taps to add anyone.

- **Never ask for gender, priority, or avatar.** Infer gender from relationship type and Arabic name patterns. Set priority automatically (parents = high, siblings = high, extended family = medium). Pick a matching avatar. User can change later but the default should be right 90% of the time.

- **Batch import intelligence.** When importing multiple contacts, don't ask relationship type for each one individually. Group them: "هؤلاء من جهة أبوك ولا أمك؟" — one question covers 5-10 contacts. Then narrow down within the group.

### 1.2 Logging Interactions — The App Should Know Before You Tell It

**Current state:** User opens the app, navigates to a relative, taps interaction type, optionally adds notes. Every single time.

**Intelligent version:**

- **One-tap logging from the home screen.** The app predicts who you're most likely to contact right now — based on day of week, time of day, and your history. Home screen shows 2-3 faces: "كلمت أحد منهم؟" — tap a face, done. No navigation, no forms.

- **Post-activity auto-suggestion.** When the user returns to the app after being away (app lifecycle detection), cross-reference the time gap with their habits. If they usually call their mom at this time and were away for 15 minutes — show a soft in-app card: "كلمت أمك؟" — one tap yes, one tap no. Not a notification popup, a natural in-app card.

- **Interaction type inference.** Friday afternoon = probably a visit. 11pm = probably a call. Eid = probably a visit. Pre-select the most likely type and let the user change it if wrong. The confirm button should be one tap away, not three.

- **Voice notes instead of typing.** For adding interaction notes, allow a 5-second voice recording that auto-transcribes. Nobody wants to type "زرت جدتي وكانت بخير" — they want to say it and move on.

### 1.3 Reminders — The App Should Set Them Itself

**Current state:** User manually creates reminder schedules, picks days, picks times, assigns relatives to each schedule. Heavy configuration.

**Intelligent version:**

- **Auto-generated reminders from day one.** The moment a user adds their mom, the app creates a reminder. No setup screen needed. Parents get daily/every-other-day. Grandparents get weekly. Uncles/aunts get bi-weekly. Cousins get monthly. Based on relationship type and cultural norms.

- **Smart timing.** Don't ask "what time?" — observe when the user opens the app and makes calls. After a week, the app knows you're active at 9pm. Reminders land at 8:45pm. Adjusted silently over time.

- **Adaptive frequency.** If the user contacts their uncle 3 times a week without reminders, stop reminding about him and redirect that slot to someone they're neglecting. The reminder system is alive, not static.

- **"صِلني يقترح" — a daily card.** Instead of multiple reminder notifications, one daily suggestion: "اليوم كلم خالتك فاطمة، لها ١٠ أيام" — a single, prioritized nudge. The app decided who matters most today. The user trusts it.

### 1.4 AI Assistant — It Should Come to You, Not Wait

**Current state:** User navigates to AI chat, selects counseling mode from 4 options, types a question.

**Intelligent version:**

- **Proactive micro-insights.** The AI surfaces one insight per day on the home screen: "لاحظت إنك تتواصل مع أمك كل يوم بس أبوك مرة بالأسبوع. شي طبيعي بس حبيت أنبهك." No chat needed. Just a card. The user feels *seen*.

- **Context-aware suggestions on relative profiles.** When you open a relative's profile, the AI already has something: "خالتك فاطمة قلت إن عندها فحوصات، ممكن تسأل عنها" — based on previous notes. The app connected the dots without being asked.

- **No mode selection.** The AI reads context and adapts. On a relative's page you haven't contacted in 30 days = repair mode. Just logged a visit = celebrate mode. The mode dropdown disappears entirely.

- **Pre-generated scripts for occasions.** Before Eid, the app pre-generates greeting messages for each relative. "رسائل العيد جاهزة لأقاربك" — tap to see personalized messages, ready to copy and send via WhatsApp. Zero effort.

### 1.5 Family Tree — It Should Build Itself

**Current state:** Every relative is manually added and positioned. The tree is a flat list with labels, not a real graph of relationships.

**Intelligent version:**

- **Relationship chain inference.** User added dad. User added someone as عمي (uncle). The app knows uncle is dad's brother and places them as siblings in the tree. When uncle's son is added as ابن عمي, the app places him as uncle's child. No manual arrangement.

- **Contextual "which side?" questions.** When adding a grandparent: "جدتك من طرف أبوك ولا أمك؟" — this one question places the entire branch correctly. Same for uncles, aunts, cousins.

- **Gap detection.** The app notices three uncles on dad's side, zero on mom's side. Soft prompt: "ما أضفت أحد من طرف أمك. تبي تضيف؟" — not a form, a conversation.

- **Occasion inference from tree structure.** If جدتك is elderly (health status), auto-surface more frequent reminders. If a relative has children in the tree, remind during school holidays: "عيال عمك سعد عندهم إجازة، وقت زيارة."

- **Contact deduplication.** In shared family trees, if two members add the same person with slightly different names or numbers, detect the overlap and merge intelligently.

### 1.6 The Home Screen — A Living Dashboard, Not a Menu

**Current state:** A starting point to navigate somewhere.

**Intelligent version:**

- **Today's priority.** One clear message: who to contact today, why, and how. "كلم جدتك، لها أسبوعين" — with a call button right there.

- **Family pulse.** A single visual showing family connection health. Green = doing well. Amber = some relatives need attention. Red = losing streaks. Glanceable in one second.

- **Recent wins.** "هالأسبوع كلمت ٧ أقارب" — positive reinforcement without navigating to stats.

- **Smart actions, not navigation buttons.** Instead of "Relatives | Reminders | AI | Stats" — show "كلم أمك | سجل زيارة عمك | شوف تقريرك" — actions, not destinations.

---

## Part 2: Notification Language — Saudi Dialect, Not App-Speak

### 2.1 Tone Shift

The app must sound like a friend who knows your family, not a productivity tool.

**Rules:**
- Use Saudi dialect (عامية), not formal Arabic (فصحى). "وش أخبارها" not "كيف حالها".
- Always name the relative. Never say "a family member." Always "أمك", "عمك سعد", "جدتك".
- Vary tone by urgency gap.

### 2.2 Examples

| Gap | Current | Intelligent |
|-----|---------|-------------|
| 3 days | تذكير: تواصل مع عمك سعد | عمك سعد يسلم عليك |
| 7 days | لم تتواصل مع خالتك منذ أسبوع | خالتك فاطمة وش أخبارها؟ لها أسبوع |
| 14 days | تذكير: ١٤ يوم بدون تواصل | أبوك له أسبوعين ما سمع صوتك |
| 30 days | تنبيه: شهر بدون تواصل | آخر مرة كلمت جدتك كان قبل شهر |

### 2.3 Pipeline Integration

- Content generator produces hundreds of notification copy variations per relationship type and time gap.
- Stored in `admin_ui_strings` table and rotated so users never see the same wording twice.
- The app feels alive because it always says something slightly different.

---

## Part 3: Shareable Moments — Every Celebration Escapes the App

### 3.1 Celebration Card Sharing

**Current state:** Streak milestone modal, badge unlock modal, and level-up modal all have confetti and animations — and then a "close" button. Dead end.

**Changes:**

- **Add a share button to every celebration modal.** Streak milestones, badge unlocks, level-ups. When tapped, generate a designed, branded image card (not a screenshot) with the achievement, user stats, and صِلني logo. Optimized for Twitter/X and WhatsApp dimensions.

- **The card must look good enough to post.** Spotify Wrapped energy — something people *want* to share because it makes them look good. "سلسلة ٣٠ يوم مع أمي 🔥" with a fire gradient and the Silni brand.

- **Pre-written share text that sounds natural.** Not "Download Silni!" — something like "٣٠ يوم ما قطعت التواصل مع أمي 🔥" with a link. The person sharing should feel like it's *their* achievement, not an ad.

### 3.2 Monthly "صِلني Wrapped"

A shareable monthly relationship summary:

- **Stats that tell a story:** Relatives connected with, longest streak, most contacted family member, total interactions, percentage of family in touch with.

- **Personality label.** Based on behavior, assign a fun Arabic label each month:
  - "واصل العائلة" (The Family Connector)
  - "بومة الليل العائلية" (The Family Night Owl)
  - "ملك الزيارات" (The Visit King)
  - These labels are what people screenshot and post — identity content.

- **One beautiful shareable card per month.** Auto-generated, branded, with key stat and personality label. Share button front and center. Designed for Twitter/X and WhatsApp status dimensions.

- **Pipeline expansion:** Content generator produces personality label copy, card text variations, and trending hashtags for sharing.

### 3.3 Yearly Wrapped

End of Ramadan or end of year — a full shareable story sequence:
- 5-6 slides (Instagram stories format): total interactions, most contacted relative, longest streak, personality type, family collective stats.
- This becomes an annual cultural moment people anticipate.

### 3.4 Home Screen Widgets

- iOS and Android widgets showing top streak in real-time: "أمي 🔥٤٥"
- Visible on the phone home screen. When someone glances — "وش هذا؟" — conversation starter.
- Passive brand visibility with zero user effort.

### 3.5 Family Leaderboard

In shared families — who has the most interactions this week? Not toxic competition, but "طلال كلم جدته ٥ مرات هالأسبوع" — the kind of thing a mom screenshots and sends to the family WhatsApp group saying "شوفوا طلال."

### 3.6 App Icon Badge

Badge count = days since last interaction with closest relative. Not notification count — relationship count. The red "٧" on the app icon isn't "7 notifications," it's "7 days since you called your mom." Subtle, personal, constant.

---

## Part 4: Family Network — Multiplayer Mode

### 4.1 Family Groups

The biggest structural change and the most important for organic growth.

- **A user creates a family inside Silni.** They add relatives and build a tree. They can now **invite** those relatives to join the app and link to the same family.

- **Invite flow:** Dad gets a WhatsApp deep link from his son: "يبا انضم لعائلتنا في صِلني" — taps it, downloads the app, joins the family group automatically. Tree is already built. Zero-friction onboarding.

### 4.2 Shared Family Tree

- **One family, one tree.** When a family member joins via invite link, they enter the same family group. Already-added relatives are visible to everyone — no duplicate work.

- **Collaborative adding.** Any member can add a new relative. "ابني ضيف خالتك فاطمة" becomes a real action. The new relative appears for everyone.

- **Individual streaks and stats.** The tree is shared, but interactions are personal. Dad has his own streak with خالة فاطمة. Son has his own. The family can see *who's staying connected* without seeing private details.

### 4.3 Perspective-Shifting Relationship Labels

- **Every relationship stored as a graph edge, not a label.** The app stores: "Person A is parent of Person B." From this, it derives everything:
  - Son sees: أمي (my mom)
  - Dad sees: زوجتي (my wife)
  - Cousin sees: خالتي (my aunt)
  - Grandma sees: بنتي (my daughter)

- **One data model, infinite perspectives.** Never store "this person is an aunt." Store graph connections and compute the right label for each viewer. The shared family tree looks correct for *everyone* automatically.

### 4.4 Family Activity (Privacy-First)

- Connected family members can see *that* connection is happening, not *what* was said.
- Activity indicators, not surveillance: "ابنك عنده سلسلة ١٤ يوم معك"
- Family-wide stats: "عائلة الغامدي تواصلوا ٤٧ مرة هالشهر" — collective achievement.

### 4.5 The Natural Invite Growth Loop

1. Son creates family, adds relatives
2. Sends dad a WhatsApp deep link
3. Dad joins, sees tree already built — immediate value, no setup
4. Dad says "ضيف عمك سعد" (add your uncle Saad)
5. Son adds him to the shared tree
6. Dad sends uncle Saad an invite link
7. Uncle Saad joins — tree grows, user count grows
8. Every new family member added is a potential new user
9. Every new user makes the app more valuable for everyone already in it

**Network effects built into the core product.**

---

## Part 5: Cultural Content Engine — صِلني on Every Tongue

### 5.1 Emotional Content That Gets Talked About

Content that makes someone pause, feel something, and mention it to someone else.

- **"متى آخر مرة" series.** Simple posts: "متى آخر مرة كلمت خالتك؟" — No branding in the post, only in the profile. These get shared because people feel called out. Highly templateable in the content generator.

- **Stat-based posts.** Anonymized aggregated data from the app: "مستخدمين صِلني تواصلوا مع عائلاتهم ٣ أضعاف أكثر من المعدل الطبيعي" — numbers make it feel newsworthy.

- **User testimonial threads.** Short, real-tone stories about how the app changed habits. No polish.

### 5.2 Cultural Presence — Make Silni Feel Like Culture

- **Own the language.** Make "صِلني" a verb: "صِلني عائلتك" — not "download our app" but a cultural call to action. If "هل صِلنيت أهلك؟" enters casual vocabulary, the brand wins.

- **Ride cultural moments.** Ramadan, Eid, Hajj season, Saudi National Day, school breaks. Content calendar pre-loaded with Saudi/Islamic dates and associated family themes. Auto-generate content batches weeks ahead.

- **Consistent visual aesthetic.** Content should have a look so recognizable that people identify a Silni post before reading it. Specific color treatment, typography, visual tone. Visual repetition creates cultural presence.

### 5.3 Amplification — Users as the Marketing Team

- **Shareable moments baked into the app.** Milestone cards, Wrapped summaries, personality labels (covered in Part 3).

- **"صِلني Challenge."** Periodic Twitter challenge: "كم قريب تقدر تتواصل معهم في أسبوع؟" — people post their Silni stats. Social pressure + fun. Challenges spread fast on Saudi Twitter.

- **WhatsApp-native sharing.** Share button defaults to WhatsApp with a pre-written natural message: "أنا استخدم صِلني وصراحة غيّر تواصلي مع أهلي" — something a person would actually send.

---

## Part 6: The Growth Flywheel

Every part feeds into one self-reinforcing loop:

```
User joins
  → Smart tree guides them to add relatives (intelligent, 3 taps)
  → App auto-sets reminders (no configuration)
  → User interacts with family (one-tap logging or auto-suggested)
  → Streaks build → badges unlock → levels up
  → Celebration generates shareable card → user posts on Twitter/X or WhatsApp
  → Someone sees it → "وش صِلني؟" → downloads the app
  → User invites family to shared tree → dad joins via deep link
  → Dad tells his brothers → uncle joins → tree grows
  → More family = richer stats → family leaderboard, collective Wrapped
  → Richer stats = more shareable moments → cycle repeats
```

The content pipeline runs in parallel:
- Emotional content creates cultural awareness
- Cultural moment content maintains presence
- In-app templates generate shareable cards, notification copy, Wrapped text, personality labels
- Constant rhythm keeps صِلني visible between organic user shares

---

## Implementation Priority

| Priority | Item | Impact | Effort |
|----------|------|--------|--------|
| 1 | Notification copy overhaul to Saudi dialect | High | Low |
| 2 | Shareable celebration cards on modals | High | Low-Med |
| 3 | Intelligent home screen (daily priority + one-tap logging) | High | Med |
| 4 | Auto-generated reminders (no manual setup) | High | Med |
| 5 | Monthly Wrapped with personality labels | High | Med |
| 6 | AI proactive insights (home screen cards) | Med-High | Med |
| 7 | Intelligent "add relative" flow (contextual, no dropdown) | High | Med |
| 8 | Family tree graph restructure (relationship inference) | High | High |
| 9 | Perspective-shifting labels (mom/wife/aunt per viewer) | High | High |
| 10 | Family groups with invite deep links | Critical | High |
| 11 | Shared family tree (collaborative adding) | Critical | High |
| 12 | Home screen widgets | Med | Med |
| 13 | Yearly Wrapped story sequence | Med | Med |
| 14 | Family leaderboard | Med | Med |
| 15 | Voice-to-text interaction notes | Med | Low-Med |
| 16 | AI mode auto-detection (remove dropdown) | Med | Low |
| 17 | Pre-generated Eid/occasion messages | Med | Low-Med |
| 18 | Cultural content calendar in pipeline | Med | Low |

Items 1-6 can ship incrementally without depending on each other.
Items 7-11 are the structural changes that transform the app — they depend on each other and should be planned as a single initiative.
Items 12-18 are enhancements that amplify everything above.

---

## Success Metrics

- **"Word on the streets"**: Organic Twitter/X mentions of صِلني (track via social listening)
- **Invite conversion rate**: % of invite links that result in new users
- **Share rate**: % of celebration moments that result in a share action
- **Reminder-free interactions**: % of interactions logged without a reminder triggering them (measures intelligence)
- **Time-to-first-interaction**: How fast a new user logs their first interaction (measures onboarding intelligence)
- **Family group size**: Average number of connected family members per group
- **Retention (D7, D30)**: Core metric that all intelligence improvements should lift
