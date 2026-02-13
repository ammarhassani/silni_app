# Shareable Moments — Design

## Overview

Transform Silni's internal celebrations (confetti, modals) into shareable visual cards that users can post to WhatsApp, Instagram Stories, X/Twitter, and other platforms. AI-generated personalized copy for MAX users; static text for free users.

## Card Types

### 1. Streak Milestone Card
- **Trigger:** Streak milestone modal (3, 7, 14, 30, 50, 100, 200, 365, 500 days)
- **Visual:** Fire emoji hero, streak count large, tier-specific gradient (starter=warm, legendary=gold/purple)
- **Dynamic data:** Streak count, tier name, user's first name
- **AI copy (MAX):** Personalized brag — e.g., "٣٠ يوم وأنا ما وقّفت أكلّم أهلي 🔥"
- **Free copy:** "سلسلة [N] يوم من صلة الرحم — صِلني"

### 2. Badge Unlock Card
- **Trigger:** Badge unlock modal
- **Visual:** Badge emoji large and centered, badge name, badge-specific color gradient
- **Dynamic data:** Badge emoji, badge name, user's first name
- **AI copy (MAX):** Context-aware — e.g., "وسام الوفي — ٥٠ مكالمة مع العائلة ما هي بالسهلة"
- **Free copy:** "[badge name] — وسام من صِلني"

### 3. Level Up Card
- **Trigger:** Level up modal
- **Visual:** Level number with golden glow, stars/sparkle theme
- **Dynamic data:** New level number, total XP, user's first name
- **AI copy (MAX):** e.g., "مستوى ٧ — كل يوم أقرب لأهلي"
- **Free copy:** "وصلت مستوى [N] في صِلني"

### 4. Occasion Greeting Card (NEW)
- **Trigger:** Occasion messages screen — share button per message card + general family card at top
- **Visual:** Occasion-themed (crescent for Ramadan, mosque for Eid, Saudi flag for National Day)
- **Two modes:**
  - Personal card: "عيدك مبارك يا [عمي سعد]" with AI-personalized message
  - Family card: "كل عام وعائلة [الشمري] بخير"
- **AI copy (MAX):** Full personalized greeting from existing occasion message generation
- **Free copy:** Template-based greeting from `OccasionMessageService`

### 5. Family Wrapped Card (ENHANCED)
- **Trigger:** Monthly/yearly wrapped screens — share button
- **Visual:** Stats-focused — key numbers large with supporting context
- **Dynamic data:** Total interactions, unique relatives, top relative, longest streak, personality type
- **AI copy (MAX):** e.g., "شهر يناير: ٤٧ تواصل مع ١٢ قريب — أكثر واحد كلمته أبوي"
- **Free copy:** "[N] تواصل مع [N] قريب في [month/year] — صِلني"

## Card Visual Design

### Two Formats Per Card

**Story Format (1080x1920 — 9:16)**
- Primary for Instagram/WhatsApp/Snapchat stories
- Top third: App icon (small, `assets/images/app_icon.png`) + card type label
- Middle: Hero content (emoji/number/stats — large, centered)
- Bottom third: AI or static copy text + user's first name
- Background: Full gradient matching card type theme

**Square Format (1080x1080 — 1:1)**
- For WhatsApp messages, Twitter, general sharing
- Compact version of the same layout
- Rendered via existing `ShareCardWidget` pattern (improved design)

### Visual Language

**Backgrounds per card type:**
- Streak: Warm gradient (amber → deep orange), subtle flame pattern
- Badge: Badge-specific color gradient from existing badge tier colors
- Level Up: Gold → deep purple gradient, star particle pattern
- Occasion: Occasion-themed — Ramadan (deep blue → teal + crescent), Eid (green → gold), National Day (green → white)
- Wrapped: App primary gradient with stats overlaid

**Typography:**
- Cairo font (via `google_fonts`)
- Hero numbers: 72pt bold
- Title text: 28pt bold
- Body/AI copy: 18pt regular
- Watermark: 14pt, 0.6 opacity

**Branding:**
- App icon PNG (`assets/images/app_icon.png`) — small, corner placement
- "صِلني" text watermark at bottom, subtle
- Content is the focus, branding is secondary

## AI Copy Generation

### Method
New `DeepSeekAIService.generateShareCopy(cardType, context)` method.

### Prompts

**Streak:** "Write a one-line brag about maintaining a family connection streak. Saudi dialect. Warm, proud tone. Max 20 words."

**Badge:** "Write a one-line celebration for earning this family badge. Saudi dialect. Max 20 words."

**Level Up:** "Write a one-line about reaching a new family connection level. Saudi dialect. Motivational. Max 20 words."

**Occasion:** "Write a short occasion greeting for sharing. Saudi dialect. Heartfelt. Max 25 words."

**Wrapped:** "Summarize this month/year of family connection in one proud sentence. Saudi dialect. Max 25 words."

### Caching
- Key: `(userId, cardType, contextHash)`
- TTL: 7 days
- If AI fails or times out (3 seconds): fall back to static free-tier copy

## Share Flow

### Entry Points

**Existing (add improved share flow):**
1. Badge Unlock Modal → share button
2. Streak Milestone Modal → share button
3. Level Up Modal → share button
4. Monthly Wrapped Screen → share button
5. Yearly Wrapped Screen → share button (final page)

**New:**
6. Occasion Messages Screen → share card button per message + family card at top
7. Family Tree Screen → share icon in header (active sharing replaces passive screenshot detection)
8. Gaming Center Screen → share button on user stats hero card

### Share Bottom Sheet (`ShareBottomSheet`)

**Preview area:**
- Card preview scaled to fit
- Swipe left/right to toggle story ↔ square format
- Format label: "ستوري" / "مربع"

**Platform buttons row:**
- WhatsApp (green) → `Share.shareXFiles` targeting WhatsApp, auto-selects square format
- Instagram (gradient) → `instagram-stories://share` URL scheme, auto-selects story format
- X/Twitter (icon) → `Share.shareXFiles` targeting Twitter
- More (dots) → native share sheet

**Below buttons:**
- "حفظ الصورة" (Save Image) link → saves to gallery without sharing

### Platform Handling

**Instagram Stories:**
- Check `canLaunchUrl('instagram-stories://share')`
- If installed: pass image as background via URL scheme
- If not: fall back to native share sheet

**WhatsApp:**
- Share via `share_plus` with image file
- Include AI/static copy as caption text

**General share sheet:**
- Image + text, whichever format is selected

### Analytics
- `AnalyticsService.trackEvent('share', { cardType, format, platform })`
- Uses existing analytics infrastructure — no new tables

## Technical Approach

### Image Rendering
Extends existing `ShareCardWidget` pattern:
- `RepaintBoundary` + `toImage(pixelRatio: 3.0)` for high-quality export
- Insert into Overlay off-screen → wait for layout → capture → share → cleanup
- New card widgets per type, rendered at target resolution

### New Files
- `lib/shared/widgets/share_bottom_sheet.dart` — Unified share flow
- `lib/shared/widgets/share_cards/streak_share_card.dart`
- `lib/shared/widgets/share_cards/badge_share_card.dart`
- `lib/shared/widgets/share_cards/level_up_share_card.dart`
- `lib/shared/widgets/share_cards/occasion_share_card.dart`
- `lib/shared/widgets/share_cards/wrapped_share_card.dart`
- `lib/shared/widgets/share_cards/share_card_base.dart` — Base layout (story/square)

### Modified Files
- `badge_unlock_modal.dart` — Replace share button with `ShareBottomSheet`
- `streak_milestone_modal.dart` — Replace share button with `ShareBottomSheet`
- `level_up_modal.dart` — Replace share button with `ShareBottomSheet`
- `monthly_wrapped_screen.dart` — Replace share with `ShareBottomSheet`
- `yearly_wrapped_screen.dart` — Replace share with `ShareBottomSheet`
- `occasion_messages_screen.dart` — Add share card buttons
- `family_tree_screen.dart` — Add share icon in header
- `gaming_center_screen.dart` — Add share button on stats card
- `deepseek_ai_service.dart` — Add `generateShareCopy()` method
- `share_card_widget.dart` — Extend with story/square format support
- `shareable_card_generator.dart` — Add occasion + wrapped factories
