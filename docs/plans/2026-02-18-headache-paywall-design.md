# Silni Marketing Overhaul — Complete Design

> Two systems working together: the **Headache Paywall** (pressure inside the app) and the **Conversion Rate Plan** (getting people in and through the funnel).

## Context

- **Current state**: <50 users, premium subscription at **35 SAR/month**, few/no subscribers
- **Problem**: Free users live comfortably without upgrading. Premium is invisible unless they tap a locked feature. No viral mechanics. No funnel optimization.
- **Goal**: Sustainable revenue of 1,000+ SAR/month within 3 months
- **Budget**: 20 SAR/day on social media ads (~600 SAR/month)
- **Time**: 5-10 hours/week
- **Audience**: Arab/Muslim families, practicing Muslims motivated by صلة الرحم

## Hard Rules

- Religion stays respectful — no memes, no humor around Islamic content
- No tech/app cringe — no "we built this feature" posts
- No push notification spam — that causes uninstalls
- Core functionality (interaction logging) stays free — pressure is about showing what they're *missing*

---

# Part 1: The Headache Paywall System

> Make free users constantly aware of what they're missing. 5-7 premium touchpoints per session.

## Free Tier Change

**Reminder limit: 3 → 1**

Free users get exactly ONE reminder. They choose the frequency (daily, weekly, monthly) but only for one relative. This is the single strongest conversion lever — reminders are the app's core habit loop.

## The 12 Tactics

### 1. Home Screen Premium Banner

A gold-gradient card inserted **right after the greeting** on the home screen. Not dismissable.

- Shows rotating teasers of MAX features (auto-rotates every 5 seconds)
- Example copy:
  - "ذكاء اصطناعي يحلل علاقاتك ويقترح متى تتواصل"
  - "تحليلات متقدمة لتواصلك مع عائلتك"
  - "تذكيرات ذكية بلا حدود"
- Tapping opens the paywall
- **Visible every single time free users open the app**

### 2. Reminder Limit Counter (Urgency Trigger)

Free users get 1 reminder. Make the limit painfully visible:

- Persistent pill badge: **"١/١ تذكير مستخدم"**
- When at 1/1, "add reminder" button becomes gold **"ترقية للمزيد"** button
- Counter turns red with shake animation when maxed out
- When user tries to add 2nd reminder → contextual paywall about unlimited reminders

### 3. Post-Action Upsell Bottom Sheet

After logging an interaction, **30% of the time** show a bottom sheet:

- "أحسنت! سجّلت تواصلاً مع أمك"
- "مشتركو MAX يحصلون على تحليل ذكي لعلاقاتهم — هل تريد تجربة مجانية؟"
- Two buttons: "جرّب مجاناً" (paywall) / "لاحقاً" (dismiss)
- Not every time — 30% keeps it unpredictable but frequent

### 4. Blurred AI Teasers (FOMO Generators)

Replace gold lock boxes with **blurred sample content**:

- **AI Insight card**: Blurred paragraph that *looks* like a real insight about the user's family
  - Overlay: "اشترك لقراءة التحليل"
- **AI Priority contacts**: Blurred relative names with urgency scores
  - Overlay: "MAX يخبرك من يجب أن تتواصل معه أولاً"
- **Weekly report**: Blurred chart/stats preview

**Key**: Blur is light enough to see shapes and colors but not text. Maximum FOMO.

### 5. Session-Based Paywall Interstitial

Every **3rd app open**, show a full-screen interstitial before home screen loads:

- Not the full paywall — a teaser card
- "جرّب صِلني MAX مجاناً لمدة ٧ أيام"
- 3 key features with icons
- Prominent "ابدأ التجربة" button
- Small "تخطي" text at bottom
- After 5 skips, reduce frequency to every 5th open

### 6. Settings Screen Upgrade Pressure

Amplify the existing subscription card for free users:

- Animated gold border pulse
- "أنت تستخدم النسخة المجانية" messaging
- List: "ميزات لم تجربها بعد:" with count ("٨ ميزات مقفلة")
- If trial unused: "تجربتك المجانية بانتظارك"

### 7. Contextual Paywall Copy (Duolingo's #1 Trick)

Different paywall headline based on trigger source:

| Trigger | Paywall Headline |
|---------|-----------------|
| AI chat locked | "احصل على مساعد ذكي لعلاقاتك" |
| Reminder limit hit | "لا تنسَ أحداً — تذكيرات بلا حدود" |
| Analytics locked | "اعرف من تواصلت معه ومن نسيته" |
| Leaderboard locked | "تنافس مع عائلتك في صلة الرحم" |
| Family tree locked | "شاهد شجرة عائلتك التفاعلية" |

Same paywall screen, dynamic hero message. User feels it speaks to their specific need.

### 8. "٠ ريال" CTA Copy

All paywall CTAs use:

- **"جرّب مجاناً بـ ٠ ريال"** instead of "ابدأ التجربة المجانية"
- Seeing the zero price converts better than "free" (Duolingo data)

### 9. Post-Value-Moment Triggers

Trigger paywall **right after** user feels value:

| Moment | Upsell |
|--------|--------|
| First interaction logged | "أحسنت! MAX يعطيك تحليل لتواصلك" |
| 3-day streak | "سلسلتك رائعة! إحصائيات متقدمة في MAX" |
| 3rd relative added | "عائلتك تكبر! شجرة العائلة في MAX" |
| First week completed | "أسبوع من التواصل! اكتشف تقاريرك الأسبوعية" |

Catch the emotional high and redirect it.

### 10. 5-7 Touchpoints Per Session

Minimum premium signals per session:

1. Home banner (always there)
2. Reminder limit counter
3. Blurred AI insight card
4. Blurred AI priority contacts
5. Post-interaction upsell (30%)
6. Session interstitial (every 3rd open)
7. Settings upgrade card

**Free users should never forget MAX exists.**

### 11. Trial Expiry Loss Aversion

For users on active trial:

- **Day 5**: "متبقي يومان على تجربتك المجانية"
- **Day 6**: "غداً تنتهي تجربتك — هل تريد الاستمرار؟"
- **Day 7**: "انتهت تجربتك اليوم — اشترك الآن لتستمر"
- **Post-expiry**: "هذا ما فقدته" card listing features they used during trial

### 12. Decoy Weekly Pricing

Add deliberately overpriced weekly option to make annual irresistible:

| Plan | Price | Per Month Equivalent |
|------|-------|---------------------|
| أسبوعي | 14.99 SAR | ~60 SAR/mo |
| **شهري** | **35 SAR** | **35 SAR/mo** |
| **سنوي** | **199.99 SAR** | **~16.7 SAR/mo** ⭐ |

Weekly plan exists only as a decoy to make monthly and annual look like great deals.

---

## What We're NOT Doing

- No fake notifications or push spam
- No blocking core interaction logging
- No timer-based popups mid-action
- No confirmshaming or guilt language
- No hidden cancellation flows
- The core app remains usable — pressure is about what they're *missing*

---

# Part 2: Conversion Rate Increase Plan

> Get more people into the app and move them through the funnel faster.

## The Funnel

```
App Store Visit → Install → Open → Onboard → Use → Trial → Pay
   [ASO]        [store]   [day1]  [flow]    [habit]  [paywall] [retain]
```

## A. App Store Optimization (ASO) — More Installs From Same Traffic

1. **Arabic-first screenshots** — RTL layout, not translated English. Show emotional value: streak screen, family tree, hadith reminder.
2. **First screenshot is everything** — "صِل رحمك — تابع تواصلك مع عائلتك" with clean phone mockup showing a streak.
3. **Keyword optimization** — Target: صلة الرحم, تواصل عائلي, تذكير بالأهل, شجرة العائلة. Low competition, high intent.
4. **Social proof in description** — "صُمم لمساعدتك على أداء واجب صلة الرحم" — religious duty framing, not another social app.
5. **A/B test** — Two screenshot sets: emotional (family, streaks) vs functional (features). Run 2-4 weeks via App Store Connect.

## B. Onboarding → Trial Conversion (The Critical 60 Seconds)

RevenueCat data: **80% of trial starts happen on day 1**. Miss day 1, miss them forever.

**Proposed flow:**

1. **Install → 3-screen value onboarding** (before sign-up)
   - Screen 1: "تابع تواصلك مع أهلك" (core value)
   - Screen 2: "احصل على تذكيرات ذكية" (reminders)
   - Screen 3: "ذكاء اصطناعي يحلل علاقاتك" (AI wow factor)
2. **→ Paywall (before sign-up)**
   - "جرّب صِلني MAX مجاناً بـ ٠ ريال لمدة ٧ أيام"
   - Show the 3 features with "✓ مفتوح مع MAX"
   - Skip button exists but small and grey
3. **→ Sign up → Home screen**

Paywall before sign-up: **3-5x higher trial start rates** (users at peak curiosity, no effort invested yet).

## C. Reverse Trial (The Nuclear Option)

Every new user gets **full MAX access for 7 days automatically**. No opt-in. No credit card.

After 7 days, downgrade to free (1 reminder, no AI, no analytics). They've *felt* the loss.

**Downgrade screen:**
- "استخدمت ٣ تذكيرات ذكية — الآن لديك ١ فقط"
- "حصلت على ٤ تحليلات — الآن مقفلة"
- "اشترك لاستعادة كل هذا"

RevenueCat data: reverse trials increase freemium-to-premium conversion by **10-40%**.

## D. Viral Loop — The App Sells Itself

### D1. Family invite on add-relative
- When user adds a relative, prompt: "ادعُ [الاسم] لتتابعوا تواصلكم معاً"
- Deep link pre-fills the relative's name in onboarding
- Invited person joins and sees they're already connected

### D2. Share streak cards
- At streak milestones (3, 7, 14, 30 days), auto-generate shareable image card
- "تواصلت مع أمي ١٤ يوم متواصل في صِلني"
- Instagram Story / WhatsApp ready format
- App branding + download link on card

### D3. Ramadan family challenge (seasonal)
- "تحدي رمضان العائلي — ٣٠ يوم تواصل"
- Requires inviting 2+ family members
- Leaderboard within family group
- The one time of year صلة الرحم is on everyone's mind

## E. Re-engagement — Win Back Lapsed Users

### Push notification sequence (after user goes quiet):
- **Day 3**: "سلسلة التواصل على وشك الانقطاع!"
- **Day 7**: "أهلك ينتظرون تواصلك — لا تنسَ صلة الرحم"
- **Day 14**: "عُد واستكمل مشوارك — عائلتك تستحق"
- **Day 30**: "جرّب MAX مجاناً وابدأ من جديد"

### Win-back offer:
- 30 days after trial expires: offer **3-day re-trial**
- "جرّب MAX مرة أخرى — ٣ أيام مجانية"

## F. Paid Ads (20 SAR/day)

1. **Instagram/Meta only** — better targeting than X for family/lifestyle
2. **Video creative**: 15-sec emotional — streak counter, missed calls, nasheed background
3. **Target**: Saudi + UAE + Kuwait, 22-40, interests: Islam, Quran, family
4. **Expected CPI**: 2-4 SAR → 5-10 installs/day
5. **Retargeting**: After 500 installs, create lookalike audience from engaged users
6. **A/B test 2 creatives** every 2 weeks — keep winner, replace loser

---

## Revenue Projections (at 35 SAR/month)

| Metric | Month 1 | Month 3 | Month 6 |
|--------|---------|---------|---------|
| Installs (paid) | 200 | 200 | 200 |
| Installs (viral) | 50 | 200 | 500 |
| Installs (organic/ASO) | 30 | 100 | 300 |
| **Total installs** | **280** | **500** | **1,000** |
| Trial starts (40%) | 112 | 200 | 400 |
| Trial → Paid (25%) | 28 | 50 | 100 |
| **Cumulative subscribers** | **~28** | **~75** | **~150** |
| **Monthly revenue** | **~980 SAR** | **~2,625 SAR** | **~5,250 SAR** |

*Subscribers accumulate — month 3 includes retained subscribers from months 1-2 (assuming 70% monthly retention).*

**Break-even on ad spend**: ~17 subscribers (17 × 35 = 595 SAR vs 600 SAR/month ads). Hit by end of month 1.

---

## Weekly Time Allocation (5-10 hrs/week)

| Hours | Activity |
|-------|----------|
| 2-3 | Build/improve app features (headache system, viral mechanics) |
| 1-2 | Create and manage ads (set up once, tweak weekly) |
| 1-2 | Create 2-3 organic posts (sincere, clean, premium) |
| 1 | Review analytics, respond to users, ASO tweaks |

---

---

# Part 3: Deep Research Additions (Round 2)

> New high-impact tactics from deeper market research.

## I. WhatsApp as Primary Viral Channel

86% of Saudi Arabia (29.6M users) uses WhatsApp daily. This is how things actually spread in the Gulf — not Instagram posts.

### WhatsApp share on interaction log
- When user logs an interaction, offer one-tap WhatsApp message to that relative
- Pre-written: "تواصلت معك اليوم عبر صِلني — حمّل التطبيق وتابع صلة الرحم معي 🔗"
- The relative gets a message from someone they trust (not an ad) with download link

### WhatsApp family group summary
- After weekly streak, generate shareable summary for family WhatsApp group
- "تقرير تواصل الأسبوع: تواصلت مع ٥ أفراد من عائلتي"
- Normalizes the app in the family group, creates social pressure

## II. Ramadan Mode (URGENT — Ramadan 2026 starts Feb 18)

Saudi app installs spike 67% during Ramadan. 45% of consumers more likely to engage with Ramadan campaigns. Highest-value users acquired BEFORE Ramadan.

### Ramadan-specific features
- Special Ramadan UI theme
- 30-day family challenge that auto-starts with Ramadan
- Daily notification: "اليوم ١٥ من رمضان — هل تواصلت مع رحمك اليوم؟"
- Ramadan-specific hadiths about صلة الرحم

### Pre-Ramadan ad spike
- Double ad budget (40 SAR/day) for first 2 weeks of Ramadan
- Ramadan-themed creative: lanterns, crescent, family gathering imagery

### Apple App Store featuring
- Submit for featuring via App Store Connect → Featuring Nominations
- Pitch: Arabic-first family ties app, built for صلة الرحم during Ramadan
- One featuring = thousands of free installs

## III. Hook Model Completion

### Variable rewards after logging interactions
- Random reward: sometimes +10 XP, sometimes +50, sometimes a badge, sometimes nothing
- Occasional "bonus day": "اليوم يوم مضاعف! كل تواصل = ضعف النقاط"
- Surprise unlocks: after 10th interaction, unlock special family insight or hadith
- Slot-machine psychology — unpredictability drives habitual usage

### Streak freeze monetization
- Free users: 0 streak freezes
- MAX users: 2 streak freezes per month
- Protects streak when user misses a day
- Duolingo's streak freeze reduced churn by 21%
- Users with 7+ day streaks are 3.6x more likely to stay engaged

## IV. صلة الرحم Score (Proprietary Metric)

A "credit score" for family ties:
- Calculated from: interaction frequency, number of relatives, streak length, variety of contact methods
- Gauge/meter on home screen: "درجة صلتك: ٧٢/١٠٠"
- Free users see the score, **detailed breakdown is MAX-only**
- People will screenshot and share (competitive families)
- Natural conversation starter: "My صلة score is 85, what's yours?"

## V. سفير صِلني (Ambassador Program)

Zero-budget micro-influencer strategy:
- Find 10-20 micro-influencers (5K-50K followers) in Islamic/family/lifestyle space
- Offer: lifetime MAX subscription free + "سفير صِلني" badge in-app
- In exchange: 2 authentic posts about using Silni
- Cost: $0 (lifetime sub costs nothing to provide)
- Potential reach: 100K-500K eyeballs

## VI. In-App Social Proof

### Live activity counter
- Home screen: "٢٣٤ شخص تواصلوا مع عائلاتهم اليوم عبر صِلني"
- Uses total interactions count (not unique users) for higher number
- Creates community feeling even at small scale

### Milestone share cards
- At 30-day streak: full-screen celebration with confetti
- Pre-generated beautiful Arabic share card
- One-tap share to WhatsApp/Instagram Story
- "أتممت ٣٠ يوم متواصل في صلة الرحم"
- Card designed to look so good people post for aesthetics alone

---

# Implementation Priority (RAMADAN EMERGENCY)

> Ramadan started. Every day without changes = wasted opportunity.

### Sprint 1 — Ship in 48 hours (Days 1-2 of Ramadan)
- [ ] Change reminder limit 3 → 1
- [ ] Home screen premium banner for free users
- [ ] Contextual paywall copy (dynamic headline per trigger)
- [ ] "٠ ريال" CTA copy on paywall
- [ ] Launch Meta ads (20 SAR/day, Ramadan creative)

### Sprint 2 — Ship by Day 5 of Ramadan
- [ ] Blurred AI teasers (replace lock boxes)
- [ ] Session interstitial (every 3rd app open)
- [ ] Reminder limit counter with urgency UI
- [ ] WhatsApp share button after logging interaction

### Sprint 3 — Ship by Day 10 of Ramadan
- [ ] صلة الرحم Score on home screen
- [ ] Variable rewards after interaction logging
- [ ] Post-action upsell bottom sheet (30% chance)
- [ ] Live interaction counter on home screen

### Sprint 4 — Ship by Day 15 of Ramadan
- [ ] Share streak cards (WhatsApp/Instagram Story)
- [ ] Streak freeze (0 for free, 2 for MAX)
- [ ] Post-value-moment triggers
- [ ] Settings screen upgrade pressure

### Ongoing (during Ramadan)
- [ ] Launch ambassador program (find 10 micro-influencers)
- [ ] Submit for Apple featuring (for next Ramadan — too late for this one)
- [ ] A/B test ad creatives every week
- [ ] ASO: Update screenshots with Ramadan theme

---

## Sources

### Paywall & Monetization
- [How Duolingo pushes users from freemium to premium](https://adplist.substack.com/p/how-duolingo-pushes-users-from-freemium)
- [7 Lessons: Duolingo Increased Premium Users by 176%](https://medium.com/@nicobottaro/monetization-7-lessons-on-how-duolingo-increased-premium-users-by-176-from-3-to-8-8-42e8d63b58f2)
- [Contextual Paywall Targeting — RevenueCat](https://www.revenuecat.com/blog/growth/contextual-paywall-targeting/)
- [Optimizing Paywall Placement — RevenueCat](https://www.revenuecat.com/blog/growth/paywall-placement/)
- [High-Converting Paywall Design — Apphud](https://apphud.com/blog/design-high-converting-subscription-app-paywalls)
- [8 Paywall Test Ideas — RevenueCat](https://www.revenuecat.com/blog/growth/paywall-tests-grow-app-revenue/)

### Conversion & Retention
- [State of Subscription Apps 2025 — RevenueCat](https://www.revenuecat.com/state-of-subscription-apps-2025/)
- [App Subscription Trial Benchmarks 2026](https://www.businessofapps.com/data/app-subscription-trial-benchmarks/)
- [Reverse Trial Guide — Userpilot](https://userpilot.com/blog/saas-reverse-trial/)
- [Reverse Trial Guide — Inflection](https://www.inflection.io/post/complete-guide-to-reverse-trials)
- [Mobile App Conversion Benchmarks — UXCam](https://uxcam.com/blog/mobile-app-conversion-rate/)
- [25 Strategies to Increase Conversion — CleverTap](https://clevertap.com/blog/increase-app-conversion-rate/)

### Viral & Growth
- [Viral Loop Examples — Tapp](https://www.tapp.so/blog/viral-loop-examples/)
- [Win-back Campaign Ideas — RevenueCat](https://www.revenuecat.com/blog/growth/win-back-campaign-examples-ideas/)
- [Onboarding Paywall Optimization — AppAgent](https://appagent.com/blog/mobile-app-onboarding-5-paywall-optimization-strategies/)
- [Subscription App Onboarding — Airbridge](https://www.airbridge.io/blog/subscription-app-onboarding)

### ASO
- [Arabic ASO — Istizada](https://istizada.com/arabic-aso/)
- [ASO Arabic Keywords — WA Translator](https://watranslator.com/app-store-localization-arabic-keywords/)
- [Right Time to Show a Paywall — ContextSDK](https://contextsdk.com/blogposts/the-right-time-to-show-a-paywall-why-smart-timing-beats-a-b-testing)

### Gulf Market & Ramadan
- [Muslim Pro: 62M downloads with zero marketing](https://bitsmedia.com/muslim-pro-zero-marketing/)
- [Muslim Pro reaches 170M users](https://programminginsider.com/muslim-pro-app-reaches-170-million-users-expands-features-to-serve-global-community/)
- [WhatsApp Marketing in Saudi Arabia](https://gmcsco.com/whatsapp-marketing-strategy-in-saudi-arabia-a-complete-guide-for-brands/)
- [Ramadan 2026 Gulf App Strategy — AppsFlyer](https://www.appsflyer.com/blog/measurement-analytics/ramadan-2026-gulf-strategy/)
- [Ramadan Strategies for App Marketers — Storyly](https://www.storyly.io/post/ramadan-strategies-for-app-marketers)
- [Saudi Arabia App Growth Report 2025](https://investgame.net/wp-content/uploads/2025/10/ST_2025-Middle-East-App-Growth-Report.pdf)
- [Social Media in Saudi Arabia — Sprinklr](https://www.sprinklr.com/blog/social-media-in-saudi-arabia/)

### Psychology & Gamification
- [Duolingo Streak Psychology](https://www.justanotherpm.com/blog/the-psychology-behind-duolingos-streak-feature)
- [Duolingo Gamification: Streaks & XP — Orizon](https://www.orizon.co/blog/duolingos-gamification-secrets)
- [Hook Model — Nir Eyal](https://www.nirandfar.com/how-to-manufacture-desire/)
- [Getting Featured on the App Store — Apple](https://developer.apple.com/app-store/getting-featured/)
