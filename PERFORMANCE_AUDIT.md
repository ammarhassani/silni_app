---
name: Silni Performance Audit
description: Findings-only audit across 7 categories. Predictions and measurements; no fixes. Severity scaled by user-count threshold.
type: project
---

# PERFORMANCE AUDIT

**Date:** 2026-04-27
**Method:** 5 parallel general-purpose subagents (Cats 2-6) + 2 in-context categories (Cat 1 DB queries via MCP, Cat 7 startup). Read-only — no code changes.

Severity legend (different from prior audits):
- 🔴 **Bites now (<100 users)** — already affecting current users.
- 🟡 **Bites at v1 scale (100-1000 users)** — perceptible during organic growth.
- 🟢 **Bites at v2 scale (1000+)** — predictable scale issue, plan but don't fix yet.
- ⚪ **Theoretical** — extreme scale or specific data shape only.

---

## Executive summary

### Counts per severity

| Severity | Count |
|---|---|
| 🔴 Bites now | **3** |
| 🟡 Bites at v1 (100-1k) | **15** |
| 🟢 Bites at v2 (1k+) | **10** |
| ⚪ Theoretical | **6** |

### Top 5 highest-impact findings

1. **🔴 `FamilyTreeLayoutService.computeLayout` recomputes on every state tick** — wrapped in `LayoutBuilder.builder` with no memoisation. Every keystroke, scroll, or stream tick triggers full layout recomputation. Already user-perceptible at N≥100 nodes; janky at N=150 (Cat 2).
2. **🔴 `aiAutoPreloadProvider` runs DeepSeek calls for free-tier users** who can't access AI features. 1+5 LLM calls per home-screen view. Pure waste (Cat 3).
3. **🔴 Realtime `interactions` change invalidates the entire singleton service**, not just the data stream. Causes broader rebuilds than necessary on every interaction tick (Cat 3).
4. **🟡 Markdown re-parse per chunk during AI streaming.** 50-100 full markdown re-parses per AI response on a long answer. Visible jank on mid-tier Android. Total CPU O(N²) in stream length (Cat 5).
5. **🟡 Warm-start re-fires ~24 admin queries on every app resume**, ignoring TTL. `didChangeAppLifecycleState` calls `refresh()` not `ensureFresh()` (Cat 3).

### Top 3 recommendations (post-TestFlight, not gating launch)

1. **Cache + memoize family-tree layout.** Trigger recompute only on graph-data change, not on `LayoutBuilder` constraints. Single biggest win.
2. **Throttle markdown re-parse during AI streaming.** Render plain `Text` until `isDone`, then swap to `MarkdownBody`. Or batch chunks at 100ms.
3. **Switch warm-resume `refresh()` calls to `ensureFresh()`.** Honour the existing TTL machinery instead of bypassing it.

---

## Category 1 — Database query performance

### Method
- MCP-introspected prod indexes for the 14 hot tables.
- `EXPLAIN ANALYZE` against prod for representative queries.
- **Prod scale today: 27 users, 31 relatives, 11 family_edges, 100 interactions, 16 chat_messages.** At this size every query plan picks seq scan (Postgres prefers seq for tiny tables); the audit therefore evaluates **whether the planner *would* switch to index scans at 100x scale**, judged by index coverage of the WHERE+ORDER pattern.

### Index coverage audit

| Hot path | Query shape | Index coverage | Verdict |
|---|---|---|---|
| Home: today contacted relatives | `interactions WHERE user_id AND date >= today` | `idx_interactions_user_date(user_id, date DESC)` ✓ | ✅ Covered |
| Home: relatives stream | `relatives WHERE user_id AND NOT is_archived ORDER BY priority, full_name` | `idx_relatives_user_priority(user_id, priority, full_name)` + `idx_relatives_user_archived` ✓ | ✅ Covered |
| Home: family_edges stream | `family_edges WHERE user_id` | `idx_family_edges_user_id` + composite uniques ✓ | ✅ Covered |
| Tree: shared family edges | `family_edges WHERE family_group_id` | `idx_family_edges_family_group` partial ✓ | ✅ Covered |
| Reminder cron | `reminder_schedules WHERE is_active=true AND time=HH:mm` | `idx_reminder_schedules_active_time(time, user_id) WHERE is_active=true` ✓ | ✅ Covered |
| Interaction history per relative | `interactions WHERE relative_id ORDER BY date DESC` | `idx_interactions_relative_date(relative_id, date DESC)` ✓ | ✅ Covered |
| Chat conversations drawer | `chat_conversations WHERE user_id ORDER BY updated_at DESC LIMIT 50` | `idx_chat_conversations_user_updated(user_id, updated_at DESC)` ✓ | ✅ Covered |
| Conversation messages | `chat_messages WHERE conversation_id ORDER BY created_at` | `idx_chat_messages_conversation_created` ✓ | ✅ Covered |
| AI memories | `ai_memories WHERE user_id AND is_active ORDER BY importance DESC` | `idx_ai_memories_user_active_importance` ✓ | ✅ Covered |
| Family group members | `family_group_members WHERE group_id` | `idx_family_group_members_group_id` + unique on (group_id, user_id) ✓ | ✅ Covered |
| Streak alerts cron | `relative_streaks WHERE current_streak > 0 ORDER BY streak_deadline` | `idx_relative_streaks_deadline_active` partial ✓ | ✅ Covered |
| Notification tokens fanout | `notification_tokens WHERE user_id AND is_active` | `idx_notification_tokens_user_id` + partial active ✓ | ✅ Covered |
| Daily hadith | `admin_hadith WHERE is_active=true ORDER BY display_priority DESC LIMIT 1` | `idx_admin_hadith_active` covers WHERE; **no composite for ORDER BY** | 🟢 Top-N heapsort picks at 10 rows (~0.1ms); at 1000+ rows could become noticeable. Needs `(is_active, display_priority DESC)` partial. |

### Sample EXPLAIN ANALYZE (today's prod)

```
relatives WHERE user_id AND NOT is_archived ORDER BY priority, full_name LIMIT 50
→ Seq Scan + quicksort (~1.9ms total). Will switch to idx_relatives_user_priority at higher cardinality.

family_edges WHERE user_id
→ Seq Scan (~0.1ms; 11 rows total in table). Index will be used at scale.

reminder_schedules WHERE is_active=true AND time='09:00'
→ Seq Scan (5 rows in table); idx_reminder_schedules_active_time will be used at scale.

admin_hadith WHERE is_active=true ORDER BY display_priority DESC LIMIT 1
→ Seq Scan + top-N heapsort (~0.1ms). Acceptable at 10 rows; revisit at 1000+.
```

### Findings

- 🟢 **Daily hadith ORDER BY not indexed.** Only matters at 1000+ admin_hadith rows. Add `(is_active, display_priority DESC)` partial index pre-emptively or at scale.
- 🟡 **Duplicate indexes on `users` table.** `idx_users_created_at`, `idx_users_email`, `idx_users_last_interaction`, `idx_users_streak_deadline`, `idx_users_subscription_status`, `users_email_key` — every one appears **twice**. Doubles INSERT/UPDATE cost on the busiest table; ~6 redundant indexes wasting disk + maintenance time. Likely from migration history that re-CREATE INDEX without IF NOT EXISTS in two places. Worth a one-shot cleanup migration. Bites at 500 users (when user-row writes start to matter).
- ⚪ **No row-count thresholds reached.** Every documented hot path has a covering index. No sequential-scan-on-large-table risks identified.

---

## Category 2 — Family graph algorithmic complexity

(Subagent-produced; full analysis incorporated.)

### Per-operation table

| Operation | Worst-case | Avg @ N=30 | Inflection (≥100ms) | Severity |
|---|---|---|---|---|
| `buildGraph(userId, edges)` | O(E) | <1 ms | N≈10,000 | ⚪ |
| `enrichAllSiblingEdges(graph)` | O(E²/N) | <1 ms | N≈500 | 🟢 |
| `computeRahimScope(viewer)` | **O(N²)** (uses `removeAt(0)`) | <1 ms | N≈3,000 | 🟢 |
| `remapForViewer(viewer, …)` | O(N · k²) | ~1 ms | N≈800 | 🟢 |
| `inferEdges(...)` | O(R + E) per add | <1 ms | N≈10,000 | ⚪ |
| `getLabelForViewer` | O(P · S · C) per call ≈ O(k³) | <0.5 ms × N calls | N≈300 (called per node) | 🟡 |
| `FamilyGraph.getGeneration` | **O((N+E)²)** (list-queue BFS) | small | N≈500 | 🟡 |
| **`FamilyTreeLayoutService.computeLayout`** | **O(N²)** dominated by `_resolveGlobalOverlaps` (20 iters × N²/2) + per-relative generation BFS + per-node label lookup | 5-15 ms | **N≈150-250** | 🔴 |

### Inflection points (mid-tier phone, single rebuild)

| N (relatives) | Layout time | UX |
|---|---|---|
| 30 | 5-10 ms | Imperceptible |
| 75 | 15-30 ms | Smooth |
| 150 | 60-120 ms | First jank |
| 300 | 250-500 ms | Visible freeze on every state change |
| 1000 | seconds | App feels broken |

### Memory footprint

~1.0–1.4 KB per relative in graph + layout combined. Not a concern at any realistic scale.

### Top issues

- 🔴 **`computeLayout` invoked inside `LayoutBuilder.builder`** (line 1019) — runs on every constraint change, every relative-stream tick, every `setState`. **No memoisation.** Single biggest perf risk in the app.
- 🟡 **`getLabelForViewer` called once per relative inside layout** — N invocations from within layout means total cost is O(N · k³). Allocates fresh `Set`/`List` for each `getSiblings/getParents/getChildren` call.
- 🟡 **`getGeneration` is per-call BFS from `userId`** — called once per relative in layout. A single multi-source BFS would precompute all generations in O(N+E).
- 🟢 **List-based BFS queues** in `computeRahimScope`, `getGeneration`, `_traceFamilySide` (`removeAt(0)`) — silently O(N²) instead of O(N+E). Fine until N≈500.
- 🟢 **`enrichAllSiblingEdges` runs in two places** for shared trees (line 980 in screen, line 57 in layout via `_enrichSiblingEdges`). Idempotent but wasteful.
- ⚪ **`graph.getSiblings/getParents/getChildren` always allocate** new lists/sets. A precomputed `Map<String, _Neighbors>` cache on FamilyGraph would eliminate the allocation churn.

---

## Category 3 — Network and caching

### Cold-start fetch list (top observations)

- **Pre-`runApp` blocking work** ~1.5-3s on cold cellular: Supabase + Firebase + Sentry + RevenueCat. RevenueCat (`SubscriptionService.initialize` at main.dart:303) is the biggest avoidable blocker — could default to free tier and resolve later.
- **`_initDeferredServices` (main.dart:475-490)** fires 14 admin-table queries in parallel post-launch. Good design. Total payload modest today.
- 🟡 **Feature config double-fetch.** `FeatureConfigService.refresh()` (deferred init) AND `FeatureConfigNotifier._loadConfigs()` (provider creation) hit the same 2 admin tables — 4 queries instead of 2 on cold start.

### Warm-start (resume from background)

- 🟡 **`didChangeAppLifecycleState` re-fires ~24 admin queries on every resume** (main.dart:730-743). Calls `refresh()` not `ensureFresh()`, bypassing the 5-60min TTLs configured in `cache_config_service.dart`. DAU resumes 5-10x/day → 100-200 admin queries per active user per day.

### Per-screen entry fetches

- **HomeScreen** depends on at least 5 streams; first paint waits for relatives + interactions + edges + group + reminder schedules. **AIPreload kicks off 1-N DeepSeek HTTP calls.**
- **FamilyTreeScreen** mount fires migration check + group-name lookup every time (guarded by `_hasMigratedRelatives` flag but only resets on error).
- Other screens reuse already-warmed providers. ✓

### Cache TTL & hit rates

| Service | Default TTL | Predicted hit rate |
|---|---|---|
| feature_config | 5 min | ~90% (but duplicated fetch lowers effective rate) |
| ai_config | 5 min | ~70% (10 sub-queries refresh in parallel) |
| content_config | 10 min | ~95% (hadith rotates daily — TTL could be 24h) |
| ui_strings | 60 min | ~99% |
| onboarding_config | 60 min | ~99% |

### Top issues

- 🔴 **`aiAutoPreloadProvider`** triggers DeepSeek calls for free-tier users who can't access AI. Pure waste (~80% of users).
- 🔴 **Realtime invalidates singleton service provider** (realtime_provider.dart:94, 132) on every postgres change, not just the data stream. Tears down `relativesServiceProvider` AND its data on every relative change.
- 🟡 **Warm-start `refresh()` ignores TTL** (above).
- 🟡 **`SubscriptionService.initialize` blocks `runApp`** — RevenueCat handshake.
- 🟡 **Feature config double-fetch** (above).
- 🟢 **`familyActivityFeed`** chains 4 sequential queries (members → relative names → interactions → interaction-relative names). N+1 pattern; bites at 1k+ users with active groups.
- 🟢 **Two parallel WebSocket subscriptions to `interactions`** for the same user — `todayContactedRelativesProvider` + `todayInteractionsStreamProvider`. Could share a base stream.
- ⚪ **`ui_strings` unfiltered fetch** — no `is_active` filter visible.
- ⚪ **Cache RAM-only**, no Hive persistence — every cold start pays full network cost.

---

## Category 4 — Image and asset loading

### Per-surface table

| Surface | Loading | Cached | Memory-capped |
|---|---|---|---|
| Avatar list (RelativesScreen) | Lazy build, **full-resolution decode** of every visible photo | Yes (DefaultCacheManager) | No app-level override |
| Avatar carousel | Same | Yes | No |
| Family tree canvas | **All nodes rendered at once** (no virtualization); emoji-only inside nodes (no per-node `CachedNetworkImage`) | n/a | n/a |
| Hadith card | Pure text + gradient — no images | n/a | n/a |
| Share-card generation | Off-screen `Overlay` + `RepaintBoundary` + `toImage(pixelRatio: 3.0)` synchronously on main thread | Temp file 5s | n/a |
| Voice notes | Audio only; no waveform rendering | just_audio default | n/a |
| Splash | Text + gradient + GoogleFonts preload | Google Fonts cache | n/a |
| Photo upload | `ImagePicker(maxWidth: 1920, maxHeight: 1920, imageQuality: 85)` → 300-800 KB JPEG, no resize | n/a | n/a |

### Top issues

- 🟡 **Avatar list — full-resolution decode on thumbnails.** No `memCacheHeight` / `memCacheWidth` / `maxWidthDiskCache` / `maxHeightDiskCache` on any of the 4 `CachedNetworkImage` callsites (`relative_avatar.dart`, `swipeable_relative_card.dart`, `avatar_carousel.dart`). For a 1920×1920 photo decoded into a 60×60 view, ~14 MB RGBA per relative. Default Flutter cap of ~100 MB fills after ~7 unique avatars. Estimated jank threshold: **~50 relatives with photos uploaded at full quality** trigger image-cache churn during scroll.
- 🟡 **No global `imageCache` tuning.** Zero references to `PaintingBinding.instance.imageCache` overrides. App relies on 1000-entry / 100 MB defaults.
- 🟡 **Family tree renders all nodes always.** No clip-to-viewport. Cost is layout, not decode (nodes are emoji-only). Bites at 100-1000 users with large extended families.
- 🟡 **`ImagePicker` keeps 1920×1920 / Q85.** 30× larger than needed for 60×60 avatars.
- 🟢 **Share card capture.** `toImage(pixelRatio: 3.0)` blocks UI thread during 1080×1920 rasterization. 200-500 ms hiccup on older devices.
- 🟢 **Animated list cascade.** `relatives_screen.dart:412` applies `.animate(delay: 100*index)` — at 50 relatives the last card has a 5s delay. Not an image cost, but list-render UX.
- 🟢 **Profile/login `Image.network`** — no caching, redownloads on rebuild. Single-image surfaces, low impact.
- ⚪ **N concurrent voice players spin up N decoders** at once.

### Single highest-leverage fix

Adding `memCacheHeight` / `memCacheWidth` to the four `CachedNetworkImage` callsites — eliminates findings #1, #2, and partially #6 with two lines per call.

---

## Category 5 — AI streaming and chat history

### Latency table

| Operation | TTFB / cost | Severity |
|---|---|---|
| First token (streaming) | ~1.2-2.5s typical, up to 90s | 🟢 |
| Per-chunk render | ~16-50ms (markdown re-parse every chunk) | 🟡 |
| Conversation open | 1 SELECT conv + 1 SELECT all messages (no limit) | 🟡 |
| Drawer open | 1 query, 50 conv max, no message join | 🟢 |
| Send (user-side perceived) | <50 ms | 🟢 |

### Bottlenecks

- 🟡 **Markdown re-parse per chunk during streaming.** `MarkdownBody(data: content)` rebuilds on every chunk. For a 500-token (~2KB Arabic) response with 80 chunks, that's 80 full re-parses growing from 25 chars to 2000 chars. CPU O(N²) total across chunks. Visible jank on mid-tier Android with longer responses.
- 🟡 **No pagination on `getMessages`.** `chat_history_service.dart:164` returns the entire conversation history with no `limit`, no cursor. 200-message thread = 100-400 KB JSON + full deserialization, blocking UI behind `isLoading=true`.
- 🟡 **3 serial DB roundtrips before upstream call** in `deepseek-proxy/index.ts`. `auth.getUser()` → `Promise.all(users + ai_rate_limits)` → `ai_rate_limits.upsert` — all awaited before `fetch(DEEPSEEK_URL)`. Adds 150-400ms to TTFB even on warm.
- 🟡 **Silent persistence failure.** Both `_saveMessageAsync(userMessage)` and `_saveMessageAsync(assistantMessage)` are fire-and-forget without retry/queue (`ai_chat_provider.dart:422,484`). On flaky network the messages display locally but never write to Supabase.
- 🟢 **Lazy conversation create blocks first send** — first message of a new conversation INSERTs the conversation row before the streaming HTTP starts.
- 🟢 **Hardcoded 50-conversation drawer cap** with no pagination.
- ⚪ **UTF-8 split-codepoint risk** during SSE chunk decode — `utf8.decode(bytes)` per chunk can fail mid-codepoint and silently drop in `try` around `jsonDecode`.
- ⚪ **Racy rate-limit upsert** in deepseek-proxy.

### Memory growth

`AIChatState.messages` in autoDispose provider — releases when chat screen closes. ~2-5 KB per ChatMessage. 100 messages ≈ 300-500 KB heap. Not a leak risk.

---

## Category 6 — Edge function performance

### Per-function table

| Function | Cold start | External APIs | Timeouts | Streaming | Scaling |
|---|---|---|---|---|---|
| `sync-subscription` | ~150-250ms | Supabase only | None | Buffered | None — O(1) |
| `deepseek-proxy` | ~150-250ms | DeepSeek + Supabase x2 | **None on `fetch`** | SSE | OK per-call |
| `send-push-notification` | ~150-250ms | Google OAuth + FCM v1 | **None on any `fetch`** | Buffered | OK |
| `send-smart-nudges` (cron 1h) | ~150-250ms | DeepSeek + self-fetch | DeepSeek 3s ✓ | Buffered | O(N relatives) — at 10k users serial loop will not finish in cron window |
| `check-streak-alerts` (cron 1h) | ~150-250ms | self-fetch | None | Buffered | O(N at-risk users) — sequential with 100ms gap |
| `send-scheduled-reminders` (cron 1m) | ~150-250ms | self-fetch | None | Buffered | **O(N matching schedules per minute)** — sequential |
| `send-announcement` (HTTP) | ~150-250ms | Google OAuth + FCM | None | Buffered | O(N tokens) — sequential, no inter-call delay |
| `send-scheduled-announcements` (cron 15m) | ~150-250ms | self-fetch | None | Buffered | O(N targeted users) sequential with 50ms sleep |

### Critical-path latency: AI chat

| Hop | Typical | Worst |
|---|---|---|
| Flutter → edge ingress (Riyadh) | 50-150ms | 400ms |
| Cold start (if dropped) | 0 (warm) or ~200ms | ~400ms |
| `auth.getUser()` | 30-80ms | 200ms |
| Parallel `users` + `ai_rate_limits` queries | 30-80ms ✓ | 200ms |
| Rate-limit upsert (sequential, before DeepSeek) | 30-60ms | 150ms |
| DeepSeek first-byte | 500-1200ms | 3-5s |
| Stream chunks back through edge SSE proxy | <10ms/chunk | — |
| **Total to first token** | **~700-1500ms** | **~4-6s** |

### Top issues

- 🟡 **`send-scheduled-reminders` peak-minute scaling.** Cron query covered by index, but the per-schedule fanout is sequential: 1 SELECT relatives + 1 self-fetch to `send-push-notification` + 1 `last_sent` UPDATE. At peak minutes (09:00, 21:00) with 10k users avg 1-2 schedules → 200-1000 matched schedules → 60-500s sequential work. **Will exceed the function wall-clock at ~1k matched schedules per minute.**
- 🟡 **`send-smart-nudges` global relatives scan.** Pulls all non-archived relatives globally with one query. At 10k users × 20 relatives = 200k rows — single payload could exceed PostgREST defaults.
- 🟡 **DeepSeek label-compose per nudge.** 500-2000ms per nudge × N users × hourly. At 10k users producing nudges in same hour: 10000 × ~600ms = ~100 min — won't finish in cron window. Cache opportunity: same `(relationshipType, fullName)` recomposes every run.
- 🟡 **No `AbortSignal` on FCM/DeepSeek/self-fetch in 6 of 7 functions.** A stalled FCM endpoint pins a function until wall-clock kill.
- 🟡 **`send-announcement` and `send-scheduled-announcements` sequential fanout.** Won't deliver to all users within a single invocation past ~2k recipients.
- 🟡 **`deepseek-proxy` rate-limit upsert serial-before-DeepSeek.** ~30-60ms tail latency every chat message.
- 🟢 **`check-streak-alerts` sequential with 100ms gap.** Capped at endangered-users count; fine to ~500 users; needs Promise.all + chunking past 1k.
- ⚪ **Code duplication** of `getFirebaseAccessToken` / `pemToBinary` between `send-push-notification` and `send-announcement` — refactor for maintenance, not perf.
- ⚪ **`FIREBASE_SERVICE_ACCOUNT` JSON parse inside handler** (`send-push-notification` line 108) — saves ~1-3ms × every invocation if moved to module scope.

### No dormant functions detected

All 7 active functions are wired (Flutter or cron). No removable candidates.

---

## Category 7 — App startup time

### Pre-runApp blocking sequence (main.dart)

| Step | Estimated cost |
|---|---|
| `WidgetsFlutterBinding.ensureInitialized` | ~10ms |
| `SystemChrome.setPreferredOrientations` | ~10ms |
| `initializeDateFormatting('ar')` | ~50ms |
| `EnvValidator.validate()` (sync) | ~5ms |
| `SupabaseConfig.initialize()` | ~100-300ms (network handshake but session can be cached) |
| `HiveInitializer.initialize()` | ~50-150ms (disk init) |
| `connectivityService.initialize()` | ~10ms |
| `Firebase.initializeApp()` | ~300-500ms (network for FCM token if first time) |
| `Analytics.logAppOpen()` | ~50ms (network, awaited) |
| `PerformanceMonitoringService().initialize()` | ~50ms |
| `SubscriptionService.instance.initialize()` (RevenueCat) | **~300-800ms** (network handshake) |
| `_initDeferredServices` (fire-and-forget, doesn't block) | 0ms blocking, ~14 admin queries in parallel post |
| `SentryFlutter.init()` (wraps `runApp` in `appRunner`) | ~200-400ms (DSN handshake) |
| **runApp called** | — |

**Total pre-runApp blocking: ~1.0-2.5s on cold device.**

### Post-runApp (splash → home)

| Step | Cost |
|---|---|
| First paint (splash renders) | ~50ms |
| `GoogleFonts.pendingFonts` preload | ~200-500ms (slower on first install) |
| **Hardcoded 1500ms animation delay** (`splash_screen.dart:52`) | **1500ms (pure wait)** |
| `sessionInitializationProvider` await | <100ms (cached session) |
| Route to `/home` | ~50ms |

**Total cold-tap-to-interactive-home: ~3-5s on cold start, ~2-3s on warm.**

### Findings

- 🟡 **Hardcoded 1500ms splash delay** for animation polish. Pure wait, no actual work. Already flagged in Phase 3 audit (Flow 1 finding 🟢). Easy win: race the delay against `sessionInitializationProvider.future`.
- 🟡 **`SubscriptionService.initialize` blocks `runApp`** (Cat 3 cross-reference). Could default to free tier and resolve later.
- 🟡 **Sentry wraps `runApp` in `appRunner`** — DSN handshake delays first-paint by ~200-400ms.
- 🟢 **Firebase + Analytics + PerformanceMonitoring chained sequentially.** Could parallelize via `Future.wait`.
- 🟢 **Hive init blocking** — usually fast but adds ~50-150ms; could be deferred or parallelized.
- 🟢 **`setPreferredOrientations` + `initializeDateFormatting` sequential** — could be `Future.wait`.
- ⚪ **`EnvValidator` is sync ~5ms** — could be moved post-runApp.

---

## Cross-cutting findings

1. **Three places re-fetch the same data** — `FeatureConfigService` (deferred init) + `FeatureConfigNotifier` (provider) + `didChangeAppLifecycleState` (warm resume) all hit `admin_features` + `admin_subscription_tiers`. Consolidate.
2. **Markdown re-parse + family-tree relayout share a pattern** — both rebuild from scratch on every state change with no memoisation. The Flutter convention `RepaintBoundary` + `const`-marker constructors would help both.
3. **Sequential fanout pattern** appears in 4 edge functions (smart-nudges, scheduled-reminders, announcement, scheduled-announcements). Each iterates `for (item of items) { await externalCall }`. Past 2k items per invocation, all four hit the function wall-clock.
4. **AI-system has 3 cumulative latencies** that compound to user-perceived first-token: serial pre-DeepSeek DB hops + DeepSeek prefill + per-chunk markdown re-parse. Total user-perceived TTFB is the sum, not the max.
5. **Avatar memory + image cache + global imageCache tuning** are three independent levers, each unset. Compounding risk on low-RAM Android devices with many relatives.

---

## Predictions: at what user-count does each 🟡 finding bite?

| Finding | Threshold |
|---|---|
| Markdown re-parse per chunk | Today on long responses; jank at any user count |
| Conversation history no pagination | First user with a 100+ message thread (any user count) |
| Warm-start refresh ignores TTL | ~300 DAU (when admin-table read load shows up in Supabase metrics) |
| Feature config double-fetch | ~500 (when cold-start latency starts showing in analytics) |
| RevenueCat blocks runApp | ~500 (slow networks more visible) |
| Avatar full-res decode | ~50 relatives uploaded at full quality / user (most users today have 5-20) |
| Family tree all-nodes rendered | ~80 nodes in shared trees (rare today) |
| `getLabelForViewer` per-node calls | ~150 nodes (already biting at 200+) |
| `getGeneration` per-call BFS | ~200 nodes |
| `send-scheduled-reminders` peak minute | ~1k users with 09:00 alarms |
| `send-smart-nudges` global scan | ~5k relatives globally |
| `send-announcement` sequential | ~2k recipients per blast |
| Splash 1500ms hardcoded | Today (every cold start) |
| Sentry wraps runApp | Today (every cold start) |
| `aiAutoPreloadProvider` for free users | Today (every home view) |

---

## What's NOT done in this audit

- No fixes. Findings only.
- No production load testing. Predictions are extrapolated from prod scale (~30 users) + EXPLAIN plans + code review.
- No measurement of cold-start time on a real device. Numbers in Cat 7 are estimates.

---

## Open questions for the CTO

1. **Is post-TestFlight v1.1 the right window for these fixes?** Most 🟡 findings won't bite for hundreds-to-thousands of users. The 🔴 ones (family-tree relayout, AI preload for free users, realtime invalidation) are the only "fix before/at TestFlight" candidates.
2. **Family-tree memoisation** — the single highest-leverage fix. Worth a dedicated session; needs careful Riverpod-provider integration.
3. **Markdown streaming** — render plain text during stream + swap to markdown at `isDone`? Or batch-throttle chunks at 100ms? Either is one PR.
4. **Avatar memCache lines** — 8 lines of code, fixes the highest-leverage 🟡. Worth doing in the next bug-fix session, not blocking on TestFlight.
