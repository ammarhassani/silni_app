# Silni v2.0 — Changelog

**Release: v2.0.0 (Build 36)**
**Date: February 2026**
**Covers: 80 commits from v1.1.0 to v2.0.0**

---

## App Store Release Notes

صِلني ٢.٠ — تجربة بصرية جديدة كلياً مع تصميم زجاجي فاخر، ملاحظات صوتية، ذكاء اصطناعي أعمق، وتجربة ملخصات غامرة.

Silni 2.0 is a complete visual overhaul with a premium glassmorphic design language, voice notes, deeper AI personality, and an immersive Wrapped story experience.

- **Glass Design System** — Every screen redesigned with frosted glass containers, ambient glow orbs, and smooth theme transitions across 4+ color themes.
- **Voice Notes** — Record audio notes during interaction logging with inline playback — replaces speech-to-text with native recording.
- **AI Personality Engine** — AI-generated Wrapped personality titles, dynamic shareable copy for MAX users, and perspective-aware Arabic relationship labels across all AI screens.
- **Immersive Wrapped** — Monthly and yearly recaps transformed into full-screen story experiences with aurora backgrounds, animated counters, ring charts, and auto-advance pages.
- **Shareable Moments** — Share streaks, badges, levels, wrapped recaps, and occasion messages as beautifully designed cards — with AI-generated captions for MAX subscribers.
- **Occasion Messages** — AI-generated culturally appropriate messages for Eid, Ramadan, and other Islamic occasions with WhatsApp send integration.
- **Dev Tools** — Admin-only QA panel for internal testing and debugging.

---

## What's New

### Glass Design System

- **Glassmorphic theme engine** — New `ThemeColors` properties for glass backgrounds, highlights, borders, card surfaces, and shimmer effects
- **Animated theme transitions** — 500ms staggered dissolve when switching themes: identity colors lead, backgrounds follow, text trails last
- **Dynamic theme carousel** — Theme picker in settings with horizontal scrolling carousel of all available themes
- **GlassPillTitle widget** — Reusable frosted glass pill for page titles with optional leading/trailing widgets and subtitle
- **GlassBottomSheet widget** — Reusable glassmorphic bottom sheet shell with backdrop blur, drag handle, and optional icon+title header
- **Ambient glow orbs** — Floating gradient orbs behind content on AI hub, chat, and assistant screens
- **Theme-aware colors everywhere** — Replaced hardcoded `AppColors.*` with `themeColorsProvider` across all screens

### Voice Notes

- **Audio recording** — Three-state record button (idle → recording → complete) with `record` package replacing `speech_to_text`
- **Inline playback** — Voice note player widget with seek bar, play/pause, and duration display using `just_audio`
- **Cloud storage** — Voice notes uploaded to Supabase `voice-notes` storage bucket with per-user RLS policies
- **Interaction model** — New `voiceNoteUrl` and `voiceNoteDuration` fields on interactions
- **Interaction list** — Voice note player shown inline on relative detail interaction history

### AI Assistant

- **Neon glass redesign** — All AI screens overhauled: AI hub with dramatic bento grid, chat with gradient message bubbles, composer with glow effects
- **Wrapped personality generation** — AI generates Arabic personality titles for monthly/yearly Wrapped recaps (e.g., "المتواصل الذهبي")
- **Dynamic share copy** — AI generates contextual Arabic captions for shareable cards (MAX feature)
- **Perspective labels provider** — Extracted `perspectiveLabelsProvider` for reuse across AI screens and relative selector
- **Weekly report caching** — SharedPreferences-based cache for AI-generated weekly reports
- **Card markdown style** — New `buildCardMarkdownStyle()` for rendering markdown inside glass cards
- **Death assumption guard** — AI conversation starters prompt updated to never assume relatives are deceased
- **Occasion messages** — AI-generated batch messages for Islamic occasions with template fallback
- **WhatsApp integration** — Send occasion messages directly via WhatsApp with Saudi phone number formatting

### Wrapped Experience

- **Full-screen story flow** — Monthly and yearly Wrapped transformed into page-based stories with auto-advance timer and manual navigation
- **Aurora background** — Mesh gradient ambient backgrounds using `mesh_gradient` package
- **Particle background** — Floating particle effect layer for depth
- **Activity chart** — Animated bar chart with Arabic numeral labels showing interaction patterns
- **Animated counter** — Rolling number counter widget for dramatic stat reveals
- **Interaction ring chart** — Donut chart showing interaction type breakdown (calls, visits, messages)
- **New stat fields** — Peak month, average per relative, unique relatives count
- **AI cache service** — SharedPreferences cache for AI-generated personality titles to avoid redundant API calls
- **Peak month calculation** — New `_peakMonth()` helper for monthly peak detection

### Reminders

- **Glass bottom sheets** — All reminder dialogs replaced with glassmorphic bottom sheets (create, edit, add relatives, day selector)
- **Optimistic state updates** — Toggle, delete, add, and remove operations update UI instantly before server confirmation
- **Glass time picker** — Custom glassmorphic time picker replacing platform default
- **Removed custom frequency** — `ReminderFrequency.custom` enum value removed; unknown frequencies default to `daily`
- **Smart suggestion widget** — Redesigned with glass containers and theme-aware styling
- **Schedule card** — Glass card design with gradient accents and animated toggles
- **Reminder templates** — Theme-aware template cards with glass styling

### Shareable Moments

- **ShareBottomSheet** — Capture any widget as an image and share via system sheet
- **AI copy loading** — Share bottom sheet supports async AI-generated captions with loading state
- **Share cards** — Badge, level up, streak, and wrapped share cards accept external gradient parameters
- **Share buttons** — Added to family tree header, gaming center stats, occasion messages, and all celebration modals
- **Arabic grammar** — Correct number agreement (تمييز العدد) for streak days on share cards
- **Wrapped share card** — Shows new stat fields (unique relatives, peak month)
- **iPad positioning fix** — Correct share sheet source rect computation on iPad

### Celebration Modals

- **Glass card redesign** — Badge unlock, level up, and streak milestone modals use subtle glass card animations instead of confetti
- **Sparkle particles** — Floating points overlay uses sparkle particle burst system
- **Arabic grammar** — Correct number agreement for streak/points display
- **Simplified layouts** — Reduced visual noise while maintaining celebration feel
- **Subscription congrats** — Theme-aware glass styling for premium upgrade celebration

### Settings

- **Refactored screen** — Settings screen restructured with extracted widget components
- **Theme carousel** — Theme picker button opens horizontal scrolling carousel of all themes
- **Subscription card** — Premium subscription status card with gradient styling
- **Glass-themed sections** — All settings sections use glassmorphic containers

### Home, Relatives & Onboarding

- **Home screen** — Layout adjustments for glass aesthetic consistency
- **Due reminders card** — Enhanced card with theme-aware styling
- **Relative detail** — Voice note support in interaction history list
- **Add/edit relative** — Minor theme alignment updates
- **Onboarding completion** — Glass-themed modal styling
- **Bottom nav** — Reduced shadow intensity for glass aesthetic

### Gamification

- **Gaming center** — Theme-aware redesign with glass containers
- **Family leaderboard** — Glass-styled leaderboard cards

### Dev Tools

- **Admin provider** — `userRoleProvider` and `isAdminProvider` for role-based access control
- **Dev tools screen** — Admin-only QA testing panel for internal debugging and feature testing

---

## Bug Fixes

- **AI death assumption** — Added guard instruction preventing AI from assuming relatives are deceased
- **Voice notes bucket RLS** — Per-user storage policies ensuring users can only access their own recordings
- **Fetch actual relatives count** — Gaming center share card now shows real count instead of placeholder
- **Hide zero-value stats** — Wrapped share card hides stats with zero values
- **CardBuilder signatures** — Aligned all cardBuilder signatures with ShareBottomSheet aiCopy parameter
- **Saudi phone formatting** — Convert local Saudi numbers to international format for wa.me links
- **Perspective labels in occasions** — Use perspective-aware relationship labels in occasion messages
- **Leaderboard not loading** — Users table RLS blocked cross-user reads; added `get_leaderboard()` SECURITY DEFINER RPC exposing only safe columns

---

## Backend & Database

- **4 new migrations**:
  - `20260112110000` — Reseed AI touch points with death assumption guard
  - `20260213100000` — Fix AI death assumption in conversation starters prompt
  - `20260214100000` — Create `voice-notes` storage bucket with per-user RLS policies
  - `20260218100000` — Add `get_leaderboard()` SECURITY DEFINER RPC for cross-user leaderboard

---

## Dependencies

- **Added**: `record: ^6.0.0` (audio recording), `just_audio: ^0.9.42` (audio playback), `mesh_gradient` (aurora backgrounds)
- **Removed**: `speech_to_text: ^7.3.0`
- **Platform**: Updated iOS Podfile.lock, macOS plugin registrant, iOS Info.plist microphone description

---

## Technical Improvements

- **Staggered theme dissolve** — AnimatedThemeColorsNotifier with lead/mid/follow/trail timing curves for smooth color transitions
- **Dynamic theme support** — Theme key stored as string to support arbitrary admin-configured themes
- **Optimistic update pattern** — Reminders use instant local state updates with server sync fallback
- **Provider extraction** — perspectiveLabelsProvider, admin providers extracted for reuse
- **Cache layers** — SharedPreferences caching for AI reports, wrapped personalities, and weekly reports
- **Model cleanup** — Removed `ReminderFrequency.custom`, unknown frequencies default to `daily`
- **Test updates** — Updated all tests for removed custom frequency, new AI share prompts, and model changes
