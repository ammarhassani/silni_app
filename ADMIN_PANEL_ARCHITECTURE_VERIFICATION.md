# Admin Panel ↔ admin_* Tables Architecture Verification

**Date:** 2026-05-02
**Scope:** Verify the wiring between the admin panel and the AI-prompt admin tables before designing γ.2.
**Status:** Findings only. No code changes.

---

## TL;DR

- A **Next.js admin app** lives at [silni-admin/](silni-admin/), deployed at `https://silni-admin.vercel.app` (hardcoded in [supabase/functions/_shared/cors.ts](supabase/functions/_shared/cors.ts) allowed origins).
- **Every AI-prompt admin table has an editing UI** under `silni-admin/src/app/(dashboard)/ai/*`. All prompt-text fields the CTO asked about (`prompt_template`, `prompt_context`, `prompt_addition`, `mode_instructions`, `content_ar`, `prompt_modifier`, `prompt_ar`) are exposed in the UI.
- **The Flutter app caches admin reads for 5 minutes** ([cache_config_service.dart:23](lib/core/services/cache_config_service.dart#L23)). After an admin edit, a user's running app sees the change at most 5 minutes later — sooner on a cold start.
- **`admin_ai_personality` is loaded in production** (5 active rows). The Saudi-colloquial fallback in lib/ effectively never fires.
- **γ.2 content updates can be made by the founder via the admin panel — no SQL migration required** for content changes. Schema-level changes (new columns, new tables) still need a migration.

---

## Q1 — Admin UI per AI-prompt table

| Table | UI route | UI file | Editable prompt fields | New rows? |
|---|---|---|---|---|
| `admin_ai_identity` | `/ai/identity` | [ai/identity/page.tsx](silni-admin/src/app/(dashboard)/ai/identity/page.tsx) | `ai_name`, `ai_name_en`, `ai_role_ar`, `ai_role_en`, `dialect`, `greeting_message_ar`, `personality_summary_ar` | ❌ single-row table (table currently has **0 rows** — see Q3) |
| `admin_ai_personality` | `/ai/personality` | [ai/personality/page.tsx](silni-admin/src/app/(dashboard)/ai/personality/page.tsx) | `content_ar`, `content_en`, `section_name_ar`, `is_active` (toggle) | ❌ **edit-only** — `useUpdateAIPersonality` mutates by id; no `useCreate` hook. New sections need SQL. |
| `admin_ai_parameters` | `/ai/parameters` | [ai/parameters/page.tsx](silni-admin/src/app/(dashboard)/ai/parameters/page.tsx) | `temperature`, `max_tokens`, `timeout_seconds`, `stream_enabled`, `model_name`, `is_active` | ❌ edit-only |
| `admin_ai_streaming_config` | `/ai/streaming` | [ai/streaming/page.tsx](silni-admin/src/app/(dashboard)/ai/streaming/page.tsx) | all delay-ms fields + `is_streaming_enabled` | ❌ single-row |
| `admin_ai_touch_points` | `/ai/touch-points` | [ai/touch-points/page.tsx](silni-admin/src/app/(dashboard)/ai/touch-points/page.tsx) | **`prompt_template`** (textarea), `name_ar`, `description_ar`, `temperature`, `max_tokens`, `cache_duration_seconds`, `is_enabled` | ✅ full CRUD via `useCreateTouchPoint` / `useDeleteTouchPoint` ([use-ai-touch-points.ts](silni-admin/src/hooks/use-ai-touch-points.ts)) |
| `admin_counseling_modes` | `/ai/modes` | [ai/modes/page.tsx](silni-admin/src/app/(dashboard)/ai/modes/page.tsx) | **`mode_instructions`** (textarea), `display_name_ar`, `description_ar`, `icon_name`, `color_hex`, `is_default`, `is_active` | ❌ edit-only |
| `admin_suggested_prompts` | `/ai/prompts` | [ai/prompts/page.tsx](silni-admin/src/app/(dashboard)/ai/prompts/page.tsx) | **`prompt_ar`**, `prompt_en`, `mode_key`, `sort_order`, `is_active` | ✅ full CRUD (create / edit / delete) |
| `admin_communication_scenarios` | `/ai/scenarios` | [ai/scenarios/page.tsx](silni-admin/src/app/(dashboard)/ai/scenarios/page.tsx) | **`prompt_context`**, `title_ar`, `description_ar`, `emoji`, `color_hex`, `sort_order`, `is_active` | ✅ full CRUD ([use-communication-scenarios.ts](silni-admin/src/hooks/use-communication-scenarios.ts)) |
| `admin_message_tones` | `/ai/occasions` (Tones tab) | [ai/occasions/page.tsx](silni-admin/src/app/(dashboard)/ai/occasions/page.tsx) | **`prompt_modifier`**, `display_name_ar`, `is_default`, `is_active` | ❌ edit-only |
| `admin_message_occasions` | `/ai/occasions` (Occasions tab) | [ai/occasions/page.tsx](silni-admin/src/app/(dashboard)/ai/occasions/page.tsx) | **`prompt_addition`**, `display_name_ar`, `emoji`, `seasonal`, `is_active` | ❌ edit-only |
| `admin_ai_error_messages` | `/ai/errors` | [ai/errors/page.tsx](silni-admin/src/app/(dashboard)/ai/errors/page.tsx) | `message_ar`, `message_en`, `show_retry_button` | (not part of γ.2 scope but exists) |

### Stale admin UI references

[silni-admin/src/hooks/use-ai.ts](silni-admin/src/hooks/use-ai.ts#L269) defines `AdminAIMemoryConfig` and queries `admin_ai_memory_config` + `admin_memory_categories`. **Both tables were dropped on 2026-04-26** (Wave 2 Task 1B — confirmed by [ai_config_service.dart:264](lib/core/services/ai_config_service.dart#L264-L265) comment). The admin panel UI for memory still loads but errors silently on those queries. Cosmetic-only — flag for cleanup.

### Persona naming leak in admin UI

[ai/personality/page.tsx:73-74](silni-admin/src/app/(dashboard)/ai/personality/page.tsx#L73-L74) info-card text: `"هذه الأقسام تُدمج معاً لتشكل شخصية واصل الكاملة"`. **The admin UI itself still says "واصل" instead of "أنيس".** Phase 6.1 leak — same pattern as the `home/greeting` touch-point row in the inventory.

---

## Q2 — Cache behavior

### What caches what

[`AIConfigService`](lib/core/services/ai_config_service.dart) is a singleton in the Flutter app. On `initialize()` it parallel-fetches all 10 AI admin tables ([:48-60](lib/core/services/ai_config_service.dart#L48-L60)), populates per-table in-memory caches, and stamps `_lastFetchTime`. Each subsequent read uses the cache until it expires.

### TTL

The cache duration comes from [`CacheConfigService`](lib/core/services/cache_config_service.dart) under service key `ai_config`. Resolution order:

1. Look up `ai_config` in `admin_cache_config` table — **empty in production** (`SELECT * FROM admin_cache_config` → 0 rows)
2. Fall back to hardcoded default in [cache_config_service.dart:23](lib/core/services/cache_config_service.dart#L23): **`'ai_config': 300` seconds (= 5 minutes)**

So **every AI admin table is cached for 5 minutes** in the running Flutter app.

`AIConfigService.isCacheExpired()` is checked via [`_isCacheValid` getter](lib/core/services/ai_config_service.dart#L31-L34) on every request. If expired, a full refresh runs ([:65](lib/core/services/ai_config_service.dart#L65)).

### Invalidation mechanism

**There is none.** No webhook, no Supabase Realtime subscription, no push notification. The propagation model is purely TTL-based:

| User scenario | Time-to-see-change after admin edit |
|---|---|
| User cold-launches the app right after the edit | ≤ 1 cache miss = next read fetches fresh |
| User has the app open, in chat, with cache warm | up to **5 minutes** |
| User pulls-to-refresh? | No such flow wired to `AIConfigService.refresh()` |
| Admin force-clear button? | None |

`AIConfigService.refresh()` exists ([:47](lib/core/services/ai_config_service.dart#L47)) but only fires from `initialize()` if `_isCacheValid == false`. Same for `clearCache()` ([:68](lib/core/services/ai_config_service.dart#L68)) — no caller in production paths.

### Concrete trace — `admin_ai_personality`

1. App starts → `AIConfigService.initialize()` → `_fetchPersonality()` → SELECT from `admin_ai_personality WHERE is_active=true ORDER BY priority` → cached in `_personalityCache`.
2. Chat surface calls `AIIdentity.personality` → `AIConfigService.fullPersonalityPrompt` → reads `_personalityCache` (in-memory, no DB hit).
3. Admin updates the `base` row in the panel → `useUpdateAIPersonality.onSuccess` invalidates the React Query cache → admin UI refetches → admin sees fresh data.
4. **The Flutter app is unaware.** It keeps serving the stale `_personalityCache` for up to 5 minutes.
5. After 5 minutes, the next call to anything touching `_isCacheValid` triggers a full refresh ([:48-60](lib/core/services/ai_config_service.dart#L48-L60)).

### Concrete trace — `admin_suggested_prompts`

Same pattern. Cache is on `_suggestedPromptsCache` ([:243-256](lib/core/services/ai_config_service.dart#L243-L256)). The chat surface's empty-state chips (β3) read this cache. New rows added in the admin panel surface in the chip row at most 5 minutes after add.

### `admin_ai_touch_points` is its own cache

[`AITouchPointService`](lib/core/services/ai_touch_point_service.dart) maintains a SEPARATE cache from `AIConfigService`, also under the `ai_config` service key (5 min TTL). Same propagation behavior.

### Cache TTL can be overridden at admin time

If the founder ever populates `admin_cache_config` with `('ai_config', N)` rows, the Flutter app will pick up `N` seconds as the new TTL — but only on next `CacheConfigService` self-refresh, which is **1 hour** ([cache_config_service.dart:34](lib/core/services/cache_config_service.dart#L34)). So cache-config changes themselves take up to 1 hour to apply. (Currently irrelevant since the table is empty.)

---

## Q3 — Read path + fallback behavior per table

### `admin_ai_identity`

- **Read path:** [ai_config_service.dart:84-95](lib/core/services/ai_config_service.dart#L84-L95) — `SELECT ... WHERE is_active=true LIMIT 1`
- **Fallback:** [ai_config_service.dart:97](lib/core/services/ai_config_service.dart#L97) — `_identityCache ?? AIIdentityConfig.fallback()`. Fallback is hardcoded ([:413-422](lib/core/services/ai_config_service.dart#L413-L422)) with `aiName: 'أنيس'`, `aiNameEn: 'Wasel'`, `dialect: 'saudi_arabic'`.
- **Production state:** **Table is empty (0 rows).** The fallback fires on every cold start. The DB-driven identity story is unimplemented.

### `admin_ai_personality`

- **Read path:** [ai_config_service.dart:101-114](lib/core/services/ai_config_service.dart#L101-L114) — `SELECT ... WHERE is_active=true ORDER BY priority`
- **Fallback (table empty / fetch fails):** [ai_config_service.dart:117](lib/core/services/ai_config_service.dart#L117) — `_personalityCache ?? AIPersonalitySection.fallbackSections()` ([:450-471](lib/core/services/ai_config_service.dart#L450-L471) — 3 hardcoded sections, Saudi colloquial)
- **Fallback (sections list empty):** [ai_config_service.dart:122](lib/core/services/ai_config_service.dart#L122) — `if (sections.isEmpty) return _hardcodedPersonality` ([:353-374](lib/core/services/ai_config_service.dart#L353-L374) — full Saudi-colloquial block)
- **Production state:** **5 active rows.** The fallback effectively NEVER fires in production with healthy network. The DB content (which says `تتحدث بالعربية الفصحى`) is what the model receives.
- **When would fallback fire?** Only if (a) the network call fails on cold start AND (b) the device has not previously cached anything. In practice: (a) intermittent flake, (b) very rare (the cache survives app restart? — let me check).

  **Note:** `_personalityCache` is in-memory only — it's NOT persisted to disk/SharedPreferences. On cold start with offline network, the fallback fires. Once online, the cache populates and stays for the session.

### `admin_ai_parameters`

- **Read path:** [ai_config_service.dart:222-235](lib/core/services/ai_config_service.dart#L222-L235) — `SELECT ... WHERE is_active=true`
- **Fallback per feature_key:** [ai_config_service.dart:685-710](lib/core/services/ai_config_service.dart#L685-L710) — hardcoded temp/tokens defaults per feature
- **Production state:** 6 active rows; fallback rarely fires.

### `admin_counseling_modes`

- **Read path:** [ai_config_service.dart:139-152](lib/core/services/ai_config_service.dart#L139-L152)
- **Fallback:** [ai_config_service.dart:155](lib/core/services/ai_config_service.dart#L155) — 4 hardcoded modes ([:511-558](lib/core/services/ai_config_service.dart#L511-L558))
- **Production state:** 4 rows; fallback rarely fires. **The DB rows are 1-line-each `mode_instructions`; the hardcoded fallback in [ai_prompts.dart:100-139](lib/core/ai/ai_prompts.dart#L100-L139) is much richer.** When the DB IS reachable (the production case), the rich fallback is bypassed and the model receives the terse 1-liner. This is the chat-quality-degradation finding from the inventory.

### `admin_suggested_prompts`

- **Read path:** [ai_config_service.dart:243-256](lib/core/services/ai_config_service.dart#L243-L256) — `SELECT ... WHERE is_active=true`
- **Fallback:** [ai_config_service.dart:735-747](lib/core/services/ai_config_service.dart#L735-L747) — 9 hardcoded prompts (subset of the 16 DB rows)
- **Production state:** 16 rows; fallback rarely fires.

### `admin_communication_scenarios`

- **Read path:** [ai_config_service.dart:326-339](lib/core/services/ai_config_service.dart#L326-L339)
- **Fallback:** 6 hardcoded scenarios ([:1058-1121](lib/core/services/ai_config_service.dart#L1058-L1121))
- **Production state:** 6 rows in DB; **all `prompt_context` fields are NULL** in DB. So even though the table is read, the prompt-text payload is empty. (Inventory finding from §1.8.)

### `admin_message_occasions`

- Same pattern; 12 rows in DB; **all `prompt_addition` fields NULL**.

### `admin_message_tones`

- Same pattern; 4 rows in DB; **`prompt_modifier` populated**.

### `admin_ai_streaming_config`

- 1 row in DB; UI-side animation cadence only — not prompt content.

### `admin_ai_touch_points`

- **Read path:** [ai_touch_point_service.dart:50-67](lib/core/services/ai_touch_point_service.dart#L50-L67)
- **Fallback:** none. If the table is unreachable, all touch-point screens silently render nothing (`AITouchPointResult.error`).
- **Production state:** 7 rows; **the `home/greeting` row STILL contains `أنت واصل`** (Phase 6.1 leak — inventory finding §1.5).

### Confirmation: which path does production take?

For `admin_ai_personality` specifically: **the DB row wins.** The Fusha (`فصحى`) instruction in the DB row is what the model receives. The Saudi colloquial fallback in `lib/` only fires if the user's app cold-started while offline — vanishingly rare for an authenticated app (since auth itself requires network).

---

## Q4 — Actual founder workflow today

Based on the codebase + RLS policies + admin app:

1. **Admin app is hosted at `https://silni-admin.vercel.app`** (Vercel deployment; URL hardcoded in [supabase/functions/_shared/cors.ts](supabase/functions/_shared/cors.ts) allowed origins).
2. Founder navigates to that URL → [login page](silni-admin/src/app/(auth)/login/page.tsx) prompts for email + password.
3. Login flow ([page.tsx:22-80](silni-admin/src/app/(auth)/login/page.tsx#L22-L80)):
   - `supabase.auth.signInWithPassword({email, password})`
   - Then `SELECT role FROM profiles WHERE id = user.id`
   - **If `profiles.role !== 'admin'`** → sign out + show "ليس لديك صلاحية الوصول للوحة التحكم"
   - If admin → redirect to `/dashboard`
4. RLS enforces this server-side too — admin tables have policies like `Admins can manage X` gated on a `is_admin()` SQL function. Public can SELECT active rows; only admins can INSERT/UPDATE/DELETE.
5. Founder clicks the AI sidebar → 12 sub-pages (memory, modes, identity, personality, touch-points, streaming, conversations, scenarios, parameters, prompts, errors, occasions).
6. Inline edit forms write directly to Supabase via React Query mutations. Toast confirms `تم التحديث`.
7. **Five minutes later**, the user's running Flutter app fetches the new row and serves the updated prompt to the model.

### Workflow constraints

- **Edits to existing rows: full self-service via panel.** No engineer needed.
- **Adding rows to:**
  - `admin_ai_touch_points` → ✅ panel supports it (`useCreateTouchPoint`)
  - `admin_suggested_prompts` → ✅ panel supports it
  - `admin_communication_scenarios` → ✅ panel supports it
  - `admin_ai_personality` → ❌ edit-only. New sections require SQL/migration.
  - `admin_counseling_modes` → ❌ edit-only.
  - `admin_message_occasions` / `admin_message_tones` → ❌ edit-only.
- **Schema changes (new columns, new tables): require a migration deploy.** Out of scope for content updates.
- **Cache propagation: max 5-minute lag** between save and live behavior. Acceptable for content tweaks; surprising if you don't know it's there. No way to force-clear.

### γ.2 implications

For γ.2 to ship via founder edits in the admin panel without code work, the rewrite must:

1. **Stay within existing rows.** Re-author content for the 5 personality sections, 4 mode_instructions, 7 touch-point prompt_templates, the empty 12 prompt_addition fields and 6 prompt_context fields. **All seven categories of content the inventory flagged are panel-editable today.**
2. **Avoid needing new personality sections.** If γ.2 wants 7 sections instead of 5, that's a SQL insert (one-time), but going forward edits are panel-editable.
3. **Empty `admin_ai_identity` is the one schema-level wart** — the row needs to exist before the panel can edit it. One-time SQL insert to seed `('أنيس', 'Wasel', '...role...', 'saudi_arabic', ...)` would unlock all identity edits via panel. After that, fully self-service.

### Live operational risks worth the CTO knowing

- **No realtime invalidation:** if the founder edits during a critical demo, the demo phone won't see the change for up to 5 minutes. Forcing a kill-and-relaunch fixes it (cold start triggers immediate fetch).
- **No edit history / audit log on AI tables:** there's an `admin_audit_log` table (0 rows) wired up but no triggers populating it for AI table mutations. Reverting a bad prompt edit means manual SQL with the previous value.
- **The Vercel admin app is internet-accessible.** Auth is gated by `profiles.role='admin'`, but credentials are the only barrier — no IP allowlist, no MFA enforcement visible in the codebase. Founder + any future admin needs to keep their password strong.

---

## Files referenced

```
silni-admin/src/app/(auth)/login/page.tsx                                 admin login flow
silni-admin/src/app/(dashboard)/ai/identity/page.tsx                      admin_ai_identity editor
silni-admin/src/app/(dashboard)/ai/personality/page.tsx                   admin_ai_personality editor
silni-admin/src/app/(dashboard)/ai/parameters/page.tsx                    admin_ai_parameters editor
silni-admin/src/app/(dashboard)/ai/streaming/page.tsx                     admin_ai_streaming_config editor
silni-admin/src/app/(dashboard)/ai/touch-points/page.tsx                  admin_ai_touch_points editor (full CRUD)
silni-admin/src/app/(dashboard)/ai/modes/page.tsx                         admin_counseling_modes editor
silni-admin/src/app/(dashboard)/ai/prompts/page.tsx                       admin_suggested_prompts editor (full CRUD)
silni-admin/src/app/(dashboard)/ai/scenarios/page.tsx                     admin_communication_scenarios editor (full CRUD)
silni-admin/src/app/(dashboard)/ai/occasions/page.tsx                     admin_message_occasions + admin_message_tones (tabs)
silni-admin/src/app/(dashboard)/ai/errors/page.tsx                        admin_ai_error_messages editor
silni-admin/src/hooks/use-ai.ts                                           queries + mutations for most AI tables
silni-admin/src/hooks/use-ai-touch-points.ts                              touch-points CRUD
silni-admin/src/hooks/use-communication-scenarios.ts                      scenarios CRUD
lib/core/services/ai_config_service.dart                                  Flutter-side cached read + fallbacks
lib/core/services/ai_touch_point_service.dart                             Flutter-side touch-point cache + placeholder substitution
lib/core/services/cache_config_service.dart                               5-min `ai_config` TTL
supabase/functions/_shared/cors.ts                                        confirms `silni-admin.vercel.app` is the deployed admin URL
```

@founder — verify the workflow description in Q4 matches what you actually do day-to-day. CTO designs γ.2 from this.
