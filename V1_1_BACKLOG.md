# v1.1 Backlog — items deferred from v1.0 audits

## Database

- **Wave 2.6** — Remove redundant procedural teardown in `delete_user_account`. Now redundant after Wave 2.5 flipped 4 FKs to ON DELETE CASCADE. Hold for staging observation post-launch.
- **Wave 2.7** — RLS policy dedup. The `users` table has 12 policies (3 copies of each CRUD verb). Other tables have similar duplication. Pure cleanup, no behavior change.
- **Wave 3** — FK target unification. Audit H2 — mixed `auth.users` vs `public.users` FK targets across the schema.

## Performance (from PERFORMANCE_AUDIT.md)

10 🟡 findings + 10 🟢 findings. Triggers for revisit:
- 🟡 findings — bite at 100–1000 users; revisit when user count crosses 100.
- 🟢 findings — bite at 1000+ users; revisit when crossing 1000.

Specific items worth naming:
- Sequential fanout in 4 cron functions (smart-nudges, scheduled-reminders, announcement, scheduled-announcements). Won't finish wall-clock past ~2k items per call.
- DeepSeek streaming abort signal (excluded from Phase 7 because it would kill streams).
- AI Hub OfflineGuard wrapping (Phase 5 fold-in but worth tracking).

## Content (from CONTENT_AUDIT_FINDINGS.md)

- **3 unnumbered legacy hadith rows** (display_priority 94, 95, 96). Working hadiths with correct narrators and grades; only missing reference numbers in citation strings. Founder research needed (~30 min) + 5-line migration. Not correctness work.
- **16 hardcoded copy candidates** for admin-table migration. Includes paywall copy, AI suggested prompts, notification templates, achievement badge descriptions. Decide post-TestFlight which actually need editability based on real user feedback.

## UX (from UX_FLOW_AUDIT.md)

~24 🟡s + ~20 🟢s deferred. The 6 highest-leverage 🟡s shipped in Phase 5. Remainder in the audit doc with original severity and surface annotations.

## Notification topic infrastructure (from PHASE_5_5)

The cosmetic notification toggles were cut in Phase 5.5. v1.1 plan: ship FCM topic-subscription infrastructure (server-side topic publish + client-side subscribe/unsubscribe + offline reconciliation), then re-enable per-category toggles backed by topic membership. SharedPreferences keys preserved for migration readback.

## Phone-invite subsystem (from PHASE_5)

Cut in Phase 5. Database tables and RPCs preserved but unreachable. v1.1 decision: revisit if real users request "invite by phone" via TestFlight feedback. If pursued, also fixes the dormant `r.name`/`v_relative.name` column-name bug in `create_node_invitation` and `get_my_pending_invitations` RPCs.

## Android one-tap notification settings (from PHASE_5_5)

Add `app_settings` package (~5 KB) for one-tap deep-link to OS notification settings on Android. Currently SnackBar with manual path on Android only.

## admin_ai_identity defensive seed (from PHASE_6_1)

Currently empty on prod. v1 routes through code fallback. If the admin panel gains an "AI identity" editor, seed a row at that point — not before.

## Audit surfaces not yet fired

- Security & PII audit — CTO recommends as next when audit cycle resumes.
- Accessibility audit — VoiceOver labels, dynamic type, color contrast.
