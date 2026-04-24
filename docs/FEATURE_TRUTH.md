# FEATURE_TRUTH.md

Ground truth on how the Silni app actually works today, derived from reading the code (Dart files, Supabase migrations, edge functions). Where the docs and the code disagree, the code wins and the contradiction is noted.

This document does not prescribe. It describes.

---

## 1. The Reminders system — how it actually works today

### What the user sees on the Reminders tab

[reminders_screen.dart](../lib/features/reminders/screens/reminders_screen.dart):157-253 builds, in order:
1. Header ("تذكير صلة الرحم")
2. Generic admin `MessageWidget` slot
3. **Unscheduled-relatives section** — relatives not in any active schedule, with quick-add buttons
4. Either an empty state with a CTA, or a list of `CompactScheduleCard` widgets, one per schedule
5. A "Create new reminder" button (hidden when all four frequency types are already in use)

### Data model

A reminder schedule is a **top-level entity that contains a list of relatives**. There is no join table. [reminder_schedule_model.dart](../lib/shared/models/reminder_schedule_model.dart):26-49:

```dart
class ReminderSchedule {
  final String id;
  final String userId;
  final ReminderFrequency frequency;
  final List<String> relativeIds;   // Postgres uuid[] column
  final String time;                // "HH:mm"
  final bool isActive;
  final List<int>? customDays;      // weekly only, 1-7
  final int? dayOfMonth;            // monthly only, 1-31
  ...
}
```

`relative_ids` is stored as a Postgres array on the `reminder_schedules` table. **One schedule contains many relatives. One relative can appear in many schedules** (no unique constraint enforces otherwise — see add path below).

### Create-schedule flow, in order

1. User taps "Create new reminder" on the reminders screen.
2. **Step 1 sheet** — [reminder_templates_widget.dart](../lib/features/reminders/widgets/reminder_templates_widget.dart):16-102 — picks one of four frequencies (daily / weekly / monthly / friday). Already-used frequencies are filtered out.
3. **Step 2 dialog** — [create_schedule_dialog.dart](../lib/features/reminders/widgets/create_schedule_dialog.dart):17-238 — picks the time (always required), plus a day-of-week picker (weekly only) or day-of-month picker (monthly only).
4. The repository creates the schedule row.

There is **no "add relatives" step in the create flow**. Relatives are added afterwards via `AddRelativesBottomSheet` from the schedule card.

Add/remove relatives from a schedule is a Set merge against `relative_ids` ([reminder_schedules_repository.dart:252-264](../lib/shared/repositories/reminder_schedules_repository.dart)).

### Auto-reminder on Add Relative

[auto_reminder_service.dart](../lib/core/services/auto_reminder_service.dart):81-150 is fire-and-forget from [add_relative_screen.dart:327](../lib/features/relatives/screens/add_relative_screen.dart). It:
1. Maps the new relative's `relationshipType` to a suggested frequency (immediate → daily 09:00; extended → weekly 10:00; distant → monthly 11:00).
2. Looks for any existing active schedule with that frequency.
3. **If one exists**, appends `relativeId` to its `relative_ids` array.
4. **If none exists**, creates a new schedule with that single relative.

So the answer to "does it create a new schedule or attach to an existing one?" is **(b) — attach if frequency match, otherwise create**.

### Reminder types

The founder mentioned "three types." The code has **four UI frequency values** plus an unused fifth:

| Frequency | Behavior | Source |
|---|---|---|
| `daily` | Every day at `time` | [reminder_schedule_model.dart:6](../lib/shared/models/reminder_schedule_model.dart) |
| `weekly` | Days in `custom_days[]` at `time` | line 7 |
| `monthly` | `day_of_month` of each month at `time` | line 8 |
| `friday` | Fridays only at `time` | line 9 |
| `custom` | `interval_days` cadence — handled in the edge function ([send-scheduled-reminders/index.ts:123-133](../supabase/functions/send-scheduled-reminders/index.ts)) but **not exposed in the create-schedule UI** |

If the founder was thinking "schedule-based / occasion-based / smart-nudge," only the schedule-based branch lives in `lib/features/reminders/`. Occasion-driven prompts live in `lib/features/home/widgets/occasion_card.dart`. Smart nudges are entirely server-side (see Section 8).

### Where reminders fire from

There is one source of truth: the **Supabase cron**. There is no `flutter_local_notifications.zonedSchedule(...)` in the codebase — the app does not schedule notifications locally.

The path is:
1. **`send-scheduled-reminders` cron** runs every minute. It queries `reminder_schedules` where `time = now_riyadh_HHmm` AND `is_active`, then evaluates frequency rules ([send-scheduled-reminders/index.ts:55-137](../supabase/functions/send-scheduled-reminders/index.ts)). Riyadh time is hardcoded (line 39).
2. For each matching schedule, it invokes **`send-push-notification`** with a consolidated payload (lines 208-229).
3. `send-push-notification` delivers via FCM. On the device, [fcm_notification_service.dart](../lib/shared/services/fcm_notification_service.dart):16-66 receives the message and shows it through `flutter_local_notifications` (foreground display only — not local scheduling).

Timezone caveat: every reminder fires on Riyadh time regardless of user device timezone. There is no per-user timezone column.

---

## 2. The Family Group flow — entry points and silent migrations

### Group create entry points

**One.** Grep for `AppRoutes.createFamilyGroup` and `CreateGroupScreen()` returns a single navigation site: [family_tree_screen.dart:453](../lib/features/family_tree/screens/family_tree_screen.dart) — a button labeled "إنشاء مجموعة" inside the family tree screen.

There is **no entry from `home_screen.dart`, no entry from the bottom nav, no entry from settings or profile**. To create a group, the user must navigate to the Family Tree screen first.

### Group join entry points

There is no in-app "I have an invite code" text input. Join is **deep-link only**. The router accepts:

- `com.silni.app://join/<CODE>` (custom scheme)
- `https://silniapp.com/join/<CODE>`
- `/join-family-group/<CODE>` (in-app route — only reachable via deep link)

Link parsing is in [app_router.dart:66-82](../lib/core/router/app_router.dart). The route itself is in the `publicRoutes` set ([app_routes.dart:19](../lib/core/router/app_routes.dart)) — no auth required to land on the join screen.

### Personal-tree → shared-tree migration

[family_tree_screen.dart:108-133](../lib/features/family_tree/screens/family_tree_screen.dart) defines `_ensureRelativesMigrated()`:

```dart
Future<void> _ensureRelativesMigrated(String groupId) async {
  if (_hasMigratedRelatives) return;
  _hasMigratedRelatives = true;
  final userId = SupabaseConfig.client.auth.currentUser?.id;
  if (userId == null) return;
  // Only the admin should migrate personal relatives into the group.
  final memberRow = await SupabaseConfig.client
      .from('family_group_members')
      .select('role')
      .eq('group_id', groupId)
      .eq('user_id', userId)
      .maybeSingle();
  final isAdmin = memberRow?['role'] == 'admin';
  if (isAdmin) {
    await FamilySharingService.ensureRelativesInGroup(
      userId: userId, groupId: groupId);
  }
  ref.invalidate(groupRelativesStreamProvider(groupId));
  ref.invalidate(sharedFamilyEdgesStreamProvider(groupId));
}
```

**Trigger**: fires once per session, when the user is admin of a group, when the family tree screen builds. The block runs in a post-frame callback.

**UI feedback**: there is no toast, no dialog, no banner, no label change. The two `ref.invalidate` calls cause the streams to refresh silently. Personal relatives end up associated with the group (via `family_group_id` on the `relatives` row).

### Node invitations vs group invite codes — two different jobs

These are **not redundant**. They serve different purposes:

**Group invite codes** (`family_groups.invite_code`, [migration](../supabase/migrations/20260201150000_family_groups.sql):6):
- 12-char hex string on every group.
- Anyone with the code becomes a `family_group_members` row when they tap a join link.
- They are a member of the group. They do not yet correspond to a node in the tree.
- Insert path: `lookup_group_by_invite_code` RPC, then membership insert, then `verifySharedEdges()` ([family_group_service.dart:86-115](../lib/features/family_groups/services/family_group_service.dart)).

**Node invitations** ([migration](../supabase/migrations/20260308100000_node_invitations.sql), [node_invitation_service.dart](../lib/features/family_groups/services/node_invitation_service.dart)):
- Admin sends "this tree node is you" to a phone number.
- Stored in `node_invitations` with status pending/accepted/cancelled.
- After the invitee logs in, [node_invitation_service.dart:43-48](../lib/features/family_groups/services/node_invitation_service.dart) `getMyPendingInvitations()` finds invites matching their verified phone.
- Acceptance via `accept_node_invitation` RPC sets `family_group_members.relative_id_in_tree` to the node, linking the user to a specific position in the tree.

So: a user typically goes through both — join code makes you a *member*; node invitation makes you *a specific person* in the tree.

### Self node (`is_self`)

The `is_self` boolean on `relatives` ([relative_model.dart:225](../lib/shared/models/relative_model.dart), default `false` line 282) marks the row that represents the user inside the tree. It is set in three places, all inside [family_sharing_service.dart](../lib/features/family_groups/services/family_sharing_service.dart):

1. **Line 36-48** — `initializeSharedTree()`, when the admin first creates a group. Inserts a relative row with `is_self: true, family_group_id: <new group>` and updates `family_group_members.relative_id_in_tree`.
2. **Line 215** — `verifySharedEdges()` defensive fallback: if the admin somehow has no self node after a group is created, one is inserted.
3. **Line 399** — `ensureRelativesInGroup()`, used during the first-time silent migration described above.

`relative_id_in_tree` lives on `family_group_members` ([migration:15](../supabase/migrations/20260201150000_family_groups.sql)). It is `NULL` for joiners until they accept a node invitation.

### Personal vs shared edges

`family_edges.family_group_id` ([migration](../supabase/migrations/20260204130000_family_sharing.sql):15-16):
- `NULL` → personal edge in the user's private tree.
- `<uuid>` → shared edge visible to all group members.

The shared-edge generator is `FamilySharingService.generateSharedEdges()` ([family_sharing_service.dart:104-136](../lib/features/family_groups/services/family_sharing_service.dart)) which calls `FamilyGraphService.inferEdges()` and rewrites every result with the group id.

`verifySharedEdges()` ([family_sharing_service.dart:150-303](../lib/features/family_groups/services/family_sharing_service.dart)) is idempotent and runs after every group join. It (a) ensures every member has a self node, (b) re-infers edges from the current graph, (c) upserts any missing edges with `onConflict: 'user_id,from_id,to_id,edge_type', ignoreDuplicates: true`.

---

## 3. The AI suite — five screens or one screen with five prompts?

[ai_chat_screen.dart](../lib/features/ai_assistant/screens/ai_chat_screen.dart) is the core conversational AI. The other five are evaluated below.

| Screen | Service call | Prompt source | Cache | DB | Output | Unique inputs | Save/export | Verdict |
|---|---|---|---|---|---|---|---|---|
| **Message Composer** ([file](../lib/features/ai_assistant/screens/message_composer_screen.dart)) | `DeepSeekAIService.getCommunicationScript()` ([line 137](../lib/features/ai_assistant/screens/message_composer_screen.dart)) | Occasion + tone templates | In-memory StateNotifier only | None | Structured `List<String>` | Occasion/tone metadata from admin config | Copy / share / edit / regenerate | Thin wrapper — could be a slash-command in chat |
| **Communication Scripts** ([file](../lib/features/ai_assistant/screens/communication_scripts_screen.dart)) | `DeepSeekAIService.getCommunicationScript()` ([line 137](../lib/features/ai_assistant/screens/communication_scripts_screen.dart)) | Admin-managed scenarios | In-memory StateNotifier only | None | Structured `CommunicationScript` (opening, key points, phrases-to-use, phrases-to-avoid, closing) | Admin scenarios | Copy-all | Thin wrapper — same backend method as Message Composer with a different display |
| **Relationship Analysis** ([file](../lib/features/ai_assistant/screens/relationship_analysis_screen.dart)) | `DeepSeekAIService.analyzeRelationship()` ([line 96](../lib/features/ai_assistant/screens/relationship_analysis_screen.dart)) | Built around `relative.healthScore` and `healthStatus2` | `AIPreloadService` in-memory cache, keyed by relative id ([line 82-91](../lib/features/ai_assistant/screens/relationship_analysis_screen.dart)) | None | Structured `RelationshipAnalysis` (summary + alerts + insights + suggestions) | `relative.healthScore` and last-contact aggregations not exposed to chat | Selectable markdown only | **Has unique data plumbing** — health-score context and the preload cache are bespoke |
| **Weekly Report** ([file](../lib/features/ai_assistant/screens/weekly_report_screen.dart)) | `DeepSeekAIService.getChatCompletion()` (generic) | Two custom prompts: aggregated stats + tip | **SharedPreferences with 7-day TTL** (`weekly_report_insight`, `weekly_report_tip`, `weekly_report_ts`) ([line 70-87](../lib/features/ai_assistant/screens/weekly_report_screen.dart)) | None | Free-text markdown | Aggregated weekly interactions, top relatives, streak, perspective labels ([line 103-126](../lib/features/ai_assistant/screens/weekly_report_screen.dart)) | None — selectable text | **Has unique data plumbing** — multi-relative aggregation + 7-day persistent cache |
| **Memory Viewer** ([file](../lib/features/ai_assistant/screens/memory_viewer_screen.dart)) | None directly. Reads from `aiMemoriesProvider` (Supabase) and `ChatHistoryService.deleteMemory()` ([line 408](../lib/features/ai_assistant/screens/memory_viewer_screen.dart)) | N/A | FutureProvider of Supabase fetch | **`ai_memories` table** (write happens during AI Chat, not here) | `AIMemory` records grouped by category | None — read-only | Swipe-to-delete | Read-only manager. Memory creation is a side effect of AI Chat, not this screen |

Memory model: [ai_models.dart:235-290](../lib/core/ai/ai_models.dart). Memories have category (`user_preference`, `relative_fact`, `important_date`, `conversation_insight`, `family_dynamic`), `content`, optional `relativeId`, importance 1–10, and `is_active`. They persist to a Supabase `ai_memories` table and are extracted during chat by the chat provider (memories are invalidated after every chat exchange — [ai_chat_provider.dart:109](../lib/features/ai_assistant/providers/ai_chat_provider.dart)).

### What `ai_hub_screen.dart` is doing

The file is **1,081 lines long**. Roughly:

- ~850+ lines of styling/animation/painters: ambient orbs ([line 124-165](../lib/features/ai_assistant/screens/ai_hub_screen.dart)), animated hero card with rotating SweepGradient borders and breathing glow ([line 191-594](../lib/features/ai_assistant/screens/ai_hub_screen.dart)), feature cards with custom pattern overlays ([line 598+](../lib/features/ai_assistant/screens/ai_hub_screen.dart)), and the `_DramaticPatternPainter` `CustomPainter` (line 895+) with five pattern enum cases (diagonalLines, overlappingFrames, connectedDots, ascendingBars, concentricCircles). Two `AnimationController`s: `_ringController` (8s loop, line 48-51) and `_glowController` (3s loop, line 54-57).
- ~100-150 lines of actual logic: feature-access checks via `featureAccessProvider(featureId)` and navigation to the chosen AI screen.

There is no LLM call, no data fetch, no persistence in the hub. It is presentation + navigation + paywall gates.

---

## 4. Voice Notes — usage signal and integration depth

Voice notes are **alive and attached to interactions** (not relatives, not reminders).

### Recording surface (one)

[relative_detail_screen.dart:280](../lib/features/relatives/screens/relative_detail_screen.dart) — the interaction-creation dialog includes a `VoiceNoteRecorder` widget. After the interaction is created, [line 384-399](../lib/features/relatives/screens/relative_detail_screen.dart) uploads the audio via `storageService.uploadVoiceNote(audioFilePath, user.id, interactionId)`.

### Playback surface (one)

[relative_interactions_list.dart:203-210](../lib/features/relatives/widgets/detail/relative_interactions_list.dart) — `VoiceNotePlayer` is rendered inline on each interaction card when `interaction.audioNoteUrl != null`.

### Data attachment

`interactions.audio_note_url TEXT` column ([schema.sql:16](../supabase/schema.sql)). The Dart model has `final String? audioNoteUrl;` ([interaction_model.dart:36](../lib/shared/models/interaction_model.dart), JSON mapped at lines 83 and 105). One audio URL per interaction. No voice-notes-on-relatives, no voice-notes-on-reminders.

### Storage

Bucket `voice-notes` is created in [migration 20260214100000](../supabase/migrations/20260214100000_create_voice_notes_bucket.sql):3 with public read and user-scoped write/delete RLS. Bucket is referenced as a constant in [supabase_storage_service.dart:12](../lib/shared/services/supabase_storage_service.dart) and used at lines 131, 141, 152.

### Analytics

**No voice-note-specific analytics events.** Grep on `analytics_events.dart` for `voice` or `audio` returns zero matches. The generic `interactionRecorded` event ([line 30](../lib/core/constants/analytics_events.dart)) fires whether or not a voice note was attached. There is no event distinguishing audio interactions from text-only interactions.

### Removal blast radius

7 files would change, ~650 lines:

1. [voice_note_button.dart](../lib/shared/widgets/voice_note_button.dart) (~361 lines, full delete)
2. [voice_note_player.dart](../lib/shared/widgets/voice_note_player.dart) (~158 lines, full delete)
3. [interaction_model.dart](../lib/shared/models/interaction_model.dart) (~50 lines: field, JSON map, copyWith)
4. [supabase_storage_service.dart](../lib/shared/services/supabase_storage_service.dart) (~35 lines: upload + delete methods, bucket constant)
5. [relative_detail_screen.dart](../lib/features/relatives/screens/relative_detail_screen.dart) (~25 lines: recorder slot in dialog + upload after interaction create)
6. [relative_interactions_list.dart](../lib/features/relatives/widgets/detail/relative_interactions_list.dart) (~8 lines: conditional player render)
7. [data_export_service.dart](../lib/shared/services/data_export_service.dart) (~10 lines: audio URL handling in export)

Plus: drop the `audio_note_url` column on `interactions` and delete the `voice-notes` storage bucket.

UI surfaces that would visually break: the interaction-creation dialog (mic icon disappears) and the per-interaction card slot (no orphaned containers — the player is wrapped in `if (audioNoteUrl != null)`, so it cleanly disappears).

---

## 5. The Family Tree — what it does that nothing else does

`lib/features/family_tree/` totals **5,696 lines**, **4.8% of `lib/`** (117,861 lines total).

### The perspective engine

`FamilyGraphService.getLabelForViewer()` ([family_graph_service.dart:535-679](../lib/features/family_tree/services/family_graph_service.dart)) computes a relationship label between any two nodes by walking the graph from the viewer's perspective. It checks direct relationships (parents, children, siblings, spouse), then 2-hop (grandparents, uncles/aunts, nephews/nieces), then 3-hop (cousins), then 4-hop (great-grandparents). Gender of the chain determines the Arabic word.

Concrete example from the same code: if relative A is the user's father, the user sees "أبي" (my father). The user's child viewing the same node A sees "جدي" (my grandfather), because from the child's perspective A is reached via parent → parent.

The function is used **outside the tree screen** by the AI Chat provider ([ai_chat_provider.dart:59](../lib/features/ai_assistant/providers/ai_chat_provider.dart)), which is the strongest cross-feature dependency in the codebase.

### Rahim scope

`computeRahimScope()` ([family_graph_service.dart:111-180](../lib/features/family_tree/services/family_graph_service.dart)) is **in-memory Dart, not a Postgres function** — there is no `compute_rahim_scope` migration. It is a directional BFS:

- Start at the viewer.
- Going UP from the viewer is allowed.
- Going SIDEWAYS at an ancestor (siblings of an ancestor) is allowed.
- From SIDEWAYS, going DOWN is allowed (you can see your aunt's descendants).
- From an ancestor reached via UP, you cannot go DOWN (this prevents the algorithm from falling out the other side of the family).
- Direct spouse is added at 1 hop but is never traversed from.

The set of reachable nodes is what the layout service positions. There is no UI surface labeled "rahim scope" — it's a constraint on which relatives the tree shows, applied implicitly during layout.

### Junction bars

[family_tree_layout_service.dart:556-603](../lib/features/family_tree/services/family_tree_layout_service.dart) builds a `LayoutJunction` ([tree_layout.dart:70-93](../lib/features/family_tree/models/tree_layout.dart)) for each parent of the user. The junction connects that parent to their siblings (the user's uncles/aunts), labeled "أعمام" (paternal uncles) or "أخوال" (maternal uncles) depending on side.

The painter ([family_tree_painter.dart:228-270](../lib/features/family_tree/painters/family_tree_painter.dart)) draws bezier curves from the parent through the junction to each sibling.

**Junction bars apply only to siblings of the user's direct parents.** Cousin–cousin or grandparent–grand-uncle relationships do not get junction bars. A grand-uncle gets a regular sibling edge to the grandparent he is sibling of.

### Paternal-left / maternal-right

This works. [family_tree_layout_service.dart:102-142](../lib/features/family_tree/services/family_tree_layout_service.dart) walks UP and SIDEWAYS from each parent (not DOWN — that would cross into the other parent's branch), tagging each ancestor with `_FamilySide.paternal` or `_FamilySide.maternal` based on the parent's gender. Lines 350-357 use the tag to choose `goRight = false` for paternal anchors and `goRight = true` for maternal. Confirmed by side-branch positioning at lines 373 and 434-438.

Mixed-gender cases (e.g., spouse of the maternal grandfather) and incomplete graphs fall back to `anchorPos.dx >= centerX` (line 357).

### Visual capabilities the tree provides that nothing else does

- **Placeholder nodes for missing relatives** ([placeholder_spawn_service.dart:25-135](../lib/features/family_tree/services/placeholder_spawn_service.dart)). Tapping a placeholder opens a creation flow ([family_tree_screen.dart:1036-1156](../lib/features/family_tree/screens/family_tree_screen.dart)) that pre-fills the relationship type — e.g., tap "+ Add Father" opens AddRelative pre-set to father. The relatives list uses a generic FAB only.
- **Screenshot watermarking** ([family_tree_screen.dart:149-174](../lib/features/family_tree/screens/family_tree_screen.dart)). Detects screenshot, hides placeholders, overlays branding for 3s. Also shows a snackbar (see Section 7, item 11).
- **Tree-as-image share** ([family_tree_screen.dart:210-290](../lib/features/family_tree/screens/family_tree_screen.dart)). Renders the canvas to a temp file and opens the system share sheet.
- **Perspective-aware labels in render** ([family_tree_layout_service.dart:531-539](../lib/features/family_tree/services/family_tree_layout_service.dart)). The relatives list uses `getSideAwareLabel`, a less context-aware fallback.

### What breaks if the visual canvas is removed but graph data is kept

Imports of `lib/features/family_tree/...` from outside the module:

- `ai_assistant/providers/ai_chat_provider.dart` → `getLabelForViewer` (perspective engine)
- `relatives/...` → `inferEdges`, `family_graph_service`, `family_graph_providers`
- `family_groups/services/family_sharing_service.dart` → `inferEdges`, `enrichAllSiblingEdges` (the shared-tree generator depends on graph inference)
- `contacts/...` → `inferEdges`, `family_graph_service`
- `home/`, `gamification/`, `reminders/`, `wrapped/` → `family_graph_providers` only

**No feature outside the tree imports `LayoutNode`, `TreeLayout`, the painters, `placeholder_spawn_service`, or `family_tree_layout_service`.** The pure data layer (graph + edges + perspective + inference) is reused everywhere; the visual layer is consumed only by the tree screen.

So if "the visual canvas" means painters + layout + placeholder UI, removing it leaves the perspective engine, `inferEdges`, `family_edges` schema, and graph providers intact. Reminders, AI, Family Groups, Wrapped do not depend on the canvas — they depend on the graph. Placeholder-driven add and screenshot share are tree-only and would go.

Rough breakdown of the 5,696 lines: the layout service (~1,300), the painters (~900), the screen + placeholder UI (~1,500) are canvas-bound; the graph service, models, and edge inference (~1,500-2,000) are reusable.

### `family_edges` table

[migration 20260201140000](../supabase/migrations/20260201140000_family_edges.sql):12-20:

```sql
CREATE TABLE IF NOT EXISTS family_edges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  from_id TEXT NOT NULL,
  to_id TEXT NOT NULL,
  edge_type TEXT NOT NULL CHECK (edge_type IN ('parent_of', 'sibling_of', 'spouse_of')),
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, from_id, to_id, edge_type)
);
```

`family_group_id` is added by the sharing migration (Section 2). Only three primitive edge types — uncle/cousin/grandparent are inferred from chains of these three.

---

## 6. Truly dead vs apparently dead

| Item | Verdict | Evidence |
|---|---|---|
| `phone_verification_screen.dart` | **Live** | Imported and routed in [app_router.dart](../lib/core/router/app_router.dart). Used as a step in the signup flow when phone verification is required. The earlier inventory's "dead code" claim was wrong. |
| `gyroscope_service.dart` | **Reachable but invisible** | `GyroscopeService` is consumed by [animated_islamic_pattern_background.dart](../lib/shared/widgets/animated_islamic_pattern_background.dart) for parallax. No dedicated UI surface — it's a decoration input. |
| `social-publisher` edge function | **Dead** | Zero references in `lib/`. No code calls `.invoke('social-publisher')` or writes to `social_posts`. Cron-only. |
| `social-token-refresh` | **Dead** | Zero references in `lib/`. No UI to connect Twitter/Instagram accounts. |
| `social-click-redirect` | **Dead** | Zero references in `lib/`. No code generates links pointing to it. |
| `social-analytics-collector` | **Dead** | Zero references in `lib/`. |
| `smartRemindersAI` feature flag | **Reachable but invisible** | Defined as `'smart_reminders_ai'` in [subscription_tier.dart:146](../lib/core/models/subscription_tier.dart), mapped to MAX, listed as an onboarding step in [onboarding_step.dart:155](../lib/features/premium_onboarding/models/onboarding_step.dart). **No code branch differentiates "smart" reminders from regular reminders.** It is a marketing label without a behavioral implementation. |
| `dataExport` | **Live** | Implemented end to end: feature flag, [data_export_provider.dart](../lib/shared/providers/data_export_provider.dart), [data_export_service.dart](../lib/shared/services/data_export_service.dart), [data_export_dialog.dart](../lib/shared/widgets/data_export_dialog.dart), reachable from profile. The earlier inventory's "no implementation" claim was wrong. |
| `onPrivacySettings` callback | **Reachable but stub** | Defined in [profile_actions_widget.dart](../lib/features/profile/widgets/profile_actions_widget.dart). The destination at [profile_screen.dart:143-147](../lib/features/profile/screens/profile_screen.dart) shows `UIHelpers.showSnackBar(context, 'إعدادات الخصوصية قريباً')` ("Privacy settings coming soon"). The button is alive; the destination is a placeholder. |
| `yearly_wrapped_screen.dart` | **Reachable but invisible** | Route `/yearly-wrapped` is registered. Grep for `pushNamed.*yearlyWrapped` and `push.*yearlyWrapped` returns zero hits. **No in-app navigation lands the user on this screen.** Only a deep link or an admin action would. |
| Apple sign-in | **Live** | `_signInWithApple()` defined at [login_screen.dart:688](../lib/features/auth/screens/login_screen.dart), wired to the Apple button at line 1153, dispatches to `AuthService.signInWithApple()`. Fully functional on iOS. |

---

## 7. The silent-feature list — what's still silent today

| # | Feature | Silent today? | Evidence |
|---|---|---|---|
| 1 | Auto-reminder on Add Relative | **Partial.** Save shows a SnackBar `'تم حفظ X بنجاح! 🎉'` ([add_relative_screen.dart:341-345](../lib/features/relatives/screens/add_relative_screen.dart)) with confetti and haptic. **The SnackBar does not mention that a reminder schedule was created or modified.** |
| 2 | Family group auto-creation / silent migration | **Yes, fully silent.** [family_sharing_service.dart:352-410](../lib/features/family_groups/services/family_sharing_service.dart). Two `ref.invalidate` calls only. No toast/dialog/banner. |
| 3 | Per-relative streak break | **Yes, fully silent.** [relative_streak_service.dart:104-158](../lib/core/services/relative_streak_service.dart) sets `streakBroken = true; newStreak = 1` but **does not emit any event** — the event-emit branch only runs for `streakIncreased && !streakBroken`. No notification, no toast. |
| 4 | Per-relative streak entirely absent from UI | **No — earlier inventory was wrong.** The streak is rendered on the relative detail header via [relative_streak_badge.dart:88-131](../lib/features/relatives/widgets/detail/relative_streak_badge.dart) (flame icon + count + warning state). It is visible per-relative on detail; it is not on the relatives list cards. |
| 5 | Points/streak/level update on every interaction | **Yes, silent.** [interactions_service.dart:47-62](../lib/shared/services/interactions_service.dart) calls `processInteractionGamification` and `updateRelativeStreak` but the calling UI in `relative_detail_screen.dart` shows no points/streak SnackBar. Badge unlocks (which do emit modals) are an exception. |
| 6 | Smart-nudge cron | **Yes, silent and uncontrolled.** [send-smart-nudges/index.ts:17-23](../supabase/functions/send-smart-nudges/index.ts) hardcodes `MAX_NUDGES_PER_DAY=2`, `MIN_GAP_DAYS=5`. No app UI to disable, configure, or view nudge history. |
| 7 | Personal-tree → shared-tree mode switch | **Yes, silent.** [family_tree_screen.dart:338-341](../lib/features/family_tree/screens/family_tree_screen.dart) ternary on `groupInfo` chooses provider with no header label, no toggle, no badge to indicate which mode the user is in. |
| 8 | AI preload on app start (MAX) | **Auto-runs, no opt-in.** [ai_preload_provider.dart:14-28](../lib/core/providers/ai_preload_provider.dart) gates on `isMax` only. No settings toggle. |
| 9 | Streak-freeze auto-award | **Event is emitted but UI handler is minimal.** [gamification_service.dart:253-257](../lib/core/services/gamification_service.dart) emits `GamificationEvent.freezeEarned`. [home_screen.dart:232](../lib/features/home/screens/home_screen.dart) has a case for `GamificationEventType.freezeEarned` but it does not render a celebratory modal — handler is brief. The earlier inventory's "event type defined but never emitted" claim was wrong. |
| 10 | Wrapped AI personality-title generation | **Visible but unlabelled.** [monthly_wrapped_screen.dart:715-733](../lib/features/wrapped/screens/monthly_wrapped_screen.dart) renders the AI-generated string. There is no "AI-generated" badge or sparkle icon — the title is presented as deterministic. |
| 11 | Screenshot watermark on family tree | **No — inventory was wrong.** [family_tree_screen.dart:158-163](../lib/features/family_tree/screens/family_tree_screen.dart) shows a SnackBar `'شجرة عائلتي من صلني 🌳'` for 3 seconds when a screenshot is detected. The watermark is announced. |

---

## 8. The data model — what's actually in the schema

121 migration files in `supabase/migrations/`. Below: the live tables, RPCs, and edge functions, with orphans flagged.

### Tables (~56)

**User & auth**: `profiles`, `users`, `subscription_events`, `notification_tokens`, `notification_history`.

**Family & graph**: `relatives`, `family_groups`, `family_group_members`, `family_edges`, `node_invitations`.

**Engagement**: `interactions` (has `audio_note_url`), `gamification_stats`, `relative_streaks`, `streak_freezes`, `freeze_usage_history`.

**AI**: `ai_memories`, `ai_generations` (cache of generated content), `chat_conversations`, `chat_messages`.

**Reminders**: `reminder_schedules` (with `relative_ids[]`).

**Admin/configuration (~32 tables, all prefixed `admin_`)**: AI identity, personality, parameters, streaming config; animations, colors, themes, pattern animations; app routes; badges, challenges, levels, points config, streak config; banners, MOTD, hadith, quotes, motivational; communication scenarios, counseling modes, message occasions, message tones, notification templates; reminder templates, reminder time slots; subscription tiers, subscription products, trial config; relationship labels; features (flag registry); audit log; memory categories.

**Social media subsystem (entirely orphan from the Flutter app)**: `social_accounts`, `social_posts`, `social_analytics`, `social_brand_voice`, `social_campaigns`, `social_templates`, `social_click_log`.

**Other orphans/reference-only from the app**: `admin_audit_log`, `admin_banners`, `admin_motd`, `admin_relationship_labels`, `admin_subscription_products`, `ai_rate_limits`, `nudge_history`, `onboarding_events`, `profiles` (the Flutter app reads `users` rather than `profiles` directly).

### RPCs

**Called from the app** (verified by grep on `.rpc(`):
`accept_node_invitation`, `cancel_node_invitation`, `create_group_atomic`, `create_node_invitation`, `get_applicable_messages`, `get_leaderboard`, `get_my_pending_invitations`, `increment_message_clicks`, `increment_message_impressions`, `leave_group_atomic`, `lookup_group_by_invite_code`, `record_message_impression`, `record_message_interaction`, `remove_member_atomic`, `rotate_invite_code`, `transfer_admin_atomic`.

**Called from the app but not defined in any migration** (broken references — these will fail at runtime if invoked):
- `award_points`
- `delete_user_account`

**Defined but only used by triggers / RLS / silni-admin / edge functions**: ~25 functions covering admin analytics (`get_admin_*`, `get_onboarding_analytics`), constraint enforcement (`prevent_*_immutable`, `enforce_*`), trial/subscription writes (`start_user_trial`, `end_user_trial`, `update_user_subscription` — used by `sync-subscription` edge function), trigger helpers (`update_*_updated_at`, `handle_new_user`, `log_role_change`, `log_subscription_event`).

### Edge functions (13 total)

**Called by the Flutter app** (verified by grep on `.functions.invoke(`):
- **`deepseek-proxy`** — proxy to DeepSeek's chat completion API. The single user-facing AI dependency. Called from [deepseek_ai_service.dart:178](../lib/core/ai/deepseek_ai_service.dart). Free users are blocked at the function (rate limit 0/day); MAX users get 200/day.

**Called via cron, not from the app**:
- `send-scheduled-reminders` — every minute, fires due reminders.
- `send-scheduled-announcements` — every 15 minutes, broadcasts admin announcements.
- `send-smart-nudges` — hourly, sends contact-gap nudges based on hardcoded thresholds.
- `check-streak-alerts` — hourly, warns users whose streak deadline is within 4 hours.
- `social-publisher` — every 5 minutes, publishes scheduled posts to Twitter/Instagram.
- `social-analytics-collector` — daily, collects engagement metrics from social platforms.
- `social-token-refresh` — hourly, refreshes OAuth tokens for connected social accounts.
- `sync-subscription` — daily, syncs RevenueCat → `users` columns.

**Triggered by other backend code, not the app**:
- `send-push-notification` — invoked by the cron functions above to deliver FCM/APNs.
- `send-announcement` — manually triggered by admin.
- `social-click-redirect` — HTTP endpoint, hit only by social-post UTM links.

So **1 of 13** edge functions is called directly from the Flutter app. Eight serve cron jobs. Four of those eight (the `social-*` set) have no app surface at all — their tables are not read or written anywhere in `lib/`.

---

## 9. Honest line-count and complexity sketch

`lib/` total: **117,861 lines** of Dart.

| Directory | Total lines | Screens | `*_service.dart` | `*_provider.dart` |
|---|---:|---:|---:|---:|
| `lib/features/ai_assistant/` | 11,748 | 8 | 1 | 3 |
| `lib/features/family_tree/` | 5,696 | 1 | 3 | 0 |
| `lib/features/reminders/` | 4,042 | 2 | 0 | 0 |
| `lib/features/relatives/` | 5,292 | 4 | 1 | 0 |
| `lib/features/gamification/` | 4,239 | 5 | 0 | 1 |
| `lib/features/home/` | 6,928 | 1 | 0 | 2 |
| `lib/features/wrapped/` | 4,745 | 2 | 2 | 0 |
| `lib/features/auth/` | 3,611 | 6 | 0 | 1 |
| `lib/features/profile/` | 1,110 | 1 | 0 | 0 |
| `lib/features/settings/` | 2,075 | 1 | 0 | 0 |
| `lib/core/services/` | 12,889 | 0 | 36 | 0 |
| `lib/core/providers/` | 1,936 | 0 | 0 | 18 |
| `lib/shared/services/` | 6,344 | 0 | 16 | 0 |

Notes:
- `lib/features/ai_assistant/` is by far the largest feature module — almost 12K lines for 8 screens, of which 1,081 lines are the navigation hub.
- `lib/features/home/` is 6,928 lines for one screen because of ~18 conditional cards/widgets.
- `lib/core/services/` holds 36 service files. 10 of them are admin-config fetchers (`ai_config`, `design_config`, `feature_config`, `gamification_config`, `notification_config`, `ui_strings`, `app_routes_config`, `cache_config`, `onboarding_config`, `content_config`).
- `lib/core/providers/` is 18 providers across ~1,900 lines — proportionally one of the cleaner directories.
- A combined "profile + settings" surface would be ~3,200 lines.

---

## 10. Questions only the founder can answer

These are genuine ambiguities the code cannot resolve.

1. **Two invitation systems coexist** — group invite codes (anyone with code joins as a member) and node invitations (admin claims a specific tree node by phone). Is the intended UX "always do both" (member → claim a node), or are these alternatives that should converge?

2. **`smartRemindersAI` is a tier label without a behavioral implementation** — was the plan to ship a different reminder algorithm for MAX (e.g., AI-chosen times based on past contact patterns), or is "smart reminders AI" just a marketing rename of "unlimited reminders"?

3. **AI screen consolidation** — Message Composer and Communication Scripts hit the same `getCommunicationScript()` method on `DeepSeekAIService` with different inputs. Were these intentionally separate user journeys, or one experiment that grew two surfaces?

4. **Yearly Wrapped has no in-app entry point** but the route is registered. Was this paused mid-rollout, or is the intent to expose it from somewhere (settings? wrapped landing card?) that was never wired?

5. **Voice notes are fully implemented but emit no analytics events.** Was this feature soft-launched (intentionally tracking-free) or shipped without instrumentation by accident?

6. **The `social-*` subsystem (4 edge functions, 7 tables, OAuth scaffolding for Twitter/Instagram) is fully built and entirely orphaned from the Flutter app.** Is this a separate growth tool driven by `silni-admin` (Next.js), a paused product direction, or to be deleted?

7. **`award_points` and `delete_user_account` RPCs are called from `lib/` but not defined in any migration.** Are these defined in a migration outside the repo, broken references that will throw at runtime, or were they renamed in the schema without updating the call sites?

8. **The auto-migration of personal relatives into a shared group** ([family_sharing_service.dart:352-410](../lib/features/family_groups/services/family_sharing_service.dart)) is intentional silence, or did the confirmation UI never get built?

9. **Per-relative streak breaks emit no event** ([relative_streak_service.dart:104-158](../lib/core/services/relative_streak_service.dart)) while streak increases and milestones do. Is this a deliberate "don't shame the user" choice, or was the broken-streak event simply never wired?

10. **Smart-nudge cron has hardcoded thresholds** (gap ≥ 5 days, ≤ 2/day). Was the plan to expose user-side controls for "less / more / off," or are the thresholds intentionally global?

11. **Riyadh time is hardcoded in `send-scheduled-reminders`** with no per-user timezone. Is the app intentionally KSA-only at launch, or is this a known TODO?

12. **`onPrivacySettings` button leads to a "coming soon" snackbar.** Was a privacy-settings screen designed and shelved, or is the button itself a placeholder?

---

End of document.
