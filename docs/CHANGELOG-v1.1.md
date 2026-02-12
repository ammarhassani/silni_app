# Silni v1.1 — Changelog

**Release: v1.1.1 (Build 34)**
**Date: February 2026**
**Covers: 81 commits from v1.0 to v1.1.1**

---

## App Store Release Notes

Silni v1.1 brings shared family trees, a completely redesigned tree view, an intelligent home screen, and monthly Wrapped recaps.

- **Shared Family Trees** — Create a family group, invite members with a link, and build your family tree together. Each member sees relationship labels from their own perspective.
- **Canvas Family Tree** — Completely rewritten tree view with smooth pan/zoom, junction bars connecting couples, and visual indicators for linked family members.
- **Smart Home Screen** — Daily priority contacts, one-tap interaction logging, and AI-powered insights that tell you who to reach out to and why.
- **Monthly & Yearly Wrapped** — See your relationship stats with personality labels, shareable summary cards, and interaction charts.
- **Voice Notes** — Record interaction notes with Arabic speech-to-text.
- **Family Leaderboard** — Weekly rankings to motivate your family group to stay connected.
- **Home Screen Widgets** — See your top streak directly on your iOS or Android home screen.

---

## What's New

### Family Tree

- **Complete canvas rewrite** — Replaced widget-based tree with a CustomPainter implementation for smooth 60fps rendering, pinch-to-zoom, and tap interactions
- **Graph-driven layout engine** — New layout algorithm that positions nodes based on graph relationships with automatic generation assignment and grid-based sibling layout
- **Junction bars** — Horizontal bars connecting spouse pairs, with child edges originating from the couple midpoint
- **Linked member indicators** — Star badges on tree nodes that represent real group members (claimed nodes)
- **Placeholder system** — Interactive ghost nodes showing suggested additions (e.g., "Add your mother") with pre-filled relationship metadata derived from tree position — tap to add without form fields
- **Placeholder spawn service** — Pure service computing which placeholders to show based on existing relatives, with card-based tree node widget
- **Editable family name** — Tap the tree header to rename your family tree
- **Family side layout** — Paternal relatives positioned on the left, maternal on the right, with side propagation through spouse edges
- **Perspective engine** — Relationship labels dynamically shift based on who is viewing the tree (e.g., your father sees his brother as "أخوي" while you see him as "عمي")
- **Extended label coverage** — Labels now cover cousins, nephews/nieces, great-grandparents, and more
- **Rahim scope** — Blood-relative visibility filtering using directional BFS, ensuring each viewer only sees relatives connected through lineage
- **Sibling edge enrichment** — Automatic inference of sibling relationships when parent edges exist

### Family Sharing

- **Family groups** — Create a group and invite family members with a shareable link
- **Universal deep links** — Join links work across iOS, Android, and web with Firebase hosting integration
- **Node claiming** — When joining a group, members pick which tree node represents them, linking their account to the shared tree
- **Shared edge generation** — Automatic creation of family_edges when members join, with post-join verification to fill gaps
- **Self-node management** — Each member has an `is_self` node in the shared tree for identity tracking
- **Join notifications** — Push notifications sent to existing members when someone new joins
- **Invite from relative profile** — One-tap invite button on any relative's detail screen
- **Family activity feed** — See today's interactions across all group members in real-time
- **Family leaderboard** — Weekly rankings by points, streaks, and total interactions
- **Group-wide interaction streams** — Real-time streams of group activity with rahim scope filtering
- **Perspective-aware rendering** — Shared trees automatically remap labels based on the viewer's position in the graph
- **Atomic group operations** — Join, leave, transfer admin, and remove member operations use database RPCs for consistency

### Smart Home Screen

- **Daily priority contacts** — Algorithm identifies the most important relative to contact today based on streak health, last contact date, and reminder schedules
- **One-tap interaction logging** — Quick-log faces widget for recording calls/visits with a single tap
- **Double-tap guard** — Prevents accidental duplicate interaction logging from rapid taps
- **Proactive AI insights** — Local rule-based insights without cloud AI calls — detects neglected relatives, streak risks, and contact patterns
- **Rahim scope filtering** — All home screen widgets respect blood-relative visibility in group mode
- **Family tree gap card** — Detects tree gaps and suggests who to add next by priority
- **Post-activity card** — Detects app resume and prompts interaction logging ("Did you call [name]?")
- **Wrapped entry card** — Monthly Wrapped entry card shown during first week of month
- **Interaction type inference** — Suggests call/visit/message based on time of day and occasion context

### AI Assistant

- **Auto-detect counseling mode** — AI switches to relationship counseling mode when the conversation context suggests personal guidance needs
- **Pre-generated occasion messages** — Ready-made messages for Eid al-Fitr, Eid al-Adha, Ramadan, and other Islamic occasions
- **Perspective-aware labels** — AI hub, message composer, and occasion screens show culturally appropriate Arabic relationship labels
- **Relationship context in prompts** — AI receives perspective-aware relationship labels for more accurate personalization

### Wrapped & Analytics

- **Monthly Wrapped** — Animated stat cards showing interaction counts, personality labels (e.g., "المتواصل الذهبي"), top contacted relatives, and streak performance
- **Yearly Wrapped** — Instagram-style swipeable story sequence with year-in-review stats
- **Shareable summary cards** — Generate and share beautiful recap images to social media
- **Interaction frequency charts** — Visual charts showing contact patterns over time
- **Wrapped data providers** — Efficient stats aggregation with caching

### Gamification

- **Shareable celebration cards** — Share streak milestones and achievements as beautifully designed cards
- **Weekly family leaderboard** — Compete with family members on points, streaks, and interactions
- **Gaming center leaderboard section** — Dedicated section in gaming center for family rankings

### Contacts & Relatives

- **Intelligent relationship picker** — Contextual suggestions based on existing relatives in your tree (e.g., suggests "أخ" if you have parents but no siblings)
- **Voice-to-text notes** — Arabic speech-to-text for recording interaction notes hands-free
- **Auto-generate reminders** — Automatically creates a reminder schedule when adding a new relative
- **Family side tracking** — Track whether relatives are from paternal or maternal side, with auto-inference from graph edges
- **Centralized gender detection** — Resolves gender from relationship type and name rather than silent male defaults
- **Contact import enhancement** — Import flow includes family side selection and improved gender detection
- **Edge cleanup on deletion** — Removing a relative now properly deletes associated graph edges

### Auth & Profile

- **Saved profile picture** — Returning users see their cached profile photo on the login and splash screens
- **Session cleanup service** — Dedicated service invalidates all user-dependent providers on sign out, preventing stale data leaks between accounts
- **User context provider** — Central source of family-aware state (userId, familyGroupId, selfNodeId) used across the app
- **Consistent auth styling** — Unified visual design across login, signup, and verification screens

### Platform & Infrastructure

- **iOS/Android home screen widgets** — Native WidgetKit (iOS) and AppWidgetProvider (Android) showing top streak
- **Universal link support** — iOS entitlements and Android intent filters for `silni.app/join/*` deep links
- **Apple App Site Association** — iOS universal links configuration for seamless app opening
- **Android asset links** — App links configuration for Android deep link verification
- **Join landing page** — Responsive Arabic landing page that redirects to app stores when app isn't installed
- **Firebase hosting** — Rewrites for `/join/**` paths and `.well-known` headers for app association
- **Web deep link handling** — Improved meta tags and deep link routing
- **Version bump script** — Auto-detects bump type from conventional commit messages and updates pubspec.yaml

### Notifications

- **Saudi dialect templates** — Notification templates using natural Saudi Arabic dialect with escalating tone levels based on days since last contact (gentle → moderate → direct → heavy)
- **Smart nudge infrastructure** — Admin UI for managing nudge categories, gap thresholds, and gender-specific templates
- **Nudge notification type** — Backend push notification handler supports "nudge" category
- **Cultural content calendar** — Islamic and cultural event calendar for scheduling occasion-based content

---

## Bug Fixes

- **Prevent joiner relative duplication** — Fixed duplicate relatives being created when joining a family group
- **Rahim scope on home screen** — Fixed stale data appearing when switching between group and personal mode
- **Double-tap guard** — Prevented race condition on rapid taps in QuickLogFaces widget
- **Auto-reminder relative ID** — Fixed empty relativeId when creating reminder for newly added relative
- **30-day insight window** — Proactive insights now correctly use 30-day interaction window instead of all-time
- **Invite button visibility** — Fixed invite button being invisible on gradient background
- **Share card iPad positioning** — Fixed incorrect share sheet positioning on iPad by computing source rect before async gap
- **Edge cleanup on deletion** — Fixed orphan edges remaining in graph after relative deletion
- **Home screen widget formatting** — Addressed initialization and formatting issues in native widgets
- **Import path fix** — Fixed relative import in inference service for proper module resolution
- **Social content type safety** — Cultural calendar now uses SocialContentType enum for type safety
- **gen_random_bytes schema** — Fixed family groups migration to use extensions schema for random byte generation

---

## Backend & Database

- **21 database migrations** covering:
  - Family side column on relatives table
  - Family group members RLS recursion fix
  - Smart nudges schema
  - Shared interactions RLS policies
  - Missing self-node backfill
  - Claimed node `is_self` fix
  - Family sharing hardening (multiple rounds)
  - Invite code rotation fix
  - Critical security fixes
  - Family edges group unique constraint
  - Security hardening
  - Atomic group operations (join, leave, transfer, remove)
  - Claim tree node RPC
  - Claim tree node RPC with user_id transfer
  - Group ID immutable trigger fix (allow initial assignment)

- **Edge functions**:
  - Smart nudges sender function (cron-based gap detection)
  - Push notification handler updated for nudge type

---

## Admin Dashboard

- Notification template management with smart nudge fields (category, gap threshold, gender)
- Database types updated for nudge columns

---

## Technical Improvements

- **Refactored tree rendering** — Removed 590 lines of legacy widget-based tree code
- **Graph data model** — Adjacency-list based FamilyGraph with perspective-shifting labels
- **Layout service** — Pure-function layout computation with comprehensive test coverage (367+ test lines)
- **Perspective engine** — `getLabelForViewer`, `remapForViewer`, `computeRahimScope` as pure, testable functions
- **Cache reconciliation** — `replaceRelativesForUser` for atomic cache updates
- **Stream recovery** — Provider invalidation on stream recovery for group and rahim providers
- **RPC error localization** — User-friendly Arabic error messages for all database RPCs with unit tests
- **Session persistence** — Profile picture caching for seamless return-user experience
- **User context provider** — Central family-aware state management
- **Session cleanup service** — Clean provider invalidation on sign-out
- **Interaction type inference** — Time-aware interaction type suggestions
