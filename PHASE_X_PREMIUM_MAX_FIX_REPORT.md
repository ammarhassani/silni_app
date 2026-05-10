# Phase X — premium → max standardization

**Engagement:** 2026-05-01
**Trigger:** Founder applied a sandboxed MAX subscription on a fresh account, sent one AI prompt, got back a `429 RATE_LIMIT_EXCEEDED` on the very first request.
**Hypothesis matched:** Hypothesis 2 — subscription tier resolution (with a related Hypothesis 3 element: the `429` was technically a true rate-limit response from the proxy, but the *cause* was a tier mismatch upstream of the rate-limit check, not stale counters).

---

## Root cause

The app's `SubscriptionTier` enum ships `free` / `max`. The DB column `users.subscription_status` is a free-form string. Three places in the stack spelled the paid tier as `"premium"` instead of `"max"`:

| File | Line | Bug |
|---|---|---|
| `lib/core/services/subscription_service.dart` | 796 | `state.tier == SubscriptionTier.max ? 'premium' : 'free'` — wrote `"premium"` to the DB on every successful paid sync |
| `supabase/functions/sync-subscription/index.ts` | 9 | `VALID_STATUSES = ["free", "premium"]` — accepted only `"premium"` for the paid tier |
| `supabase/functions/deepseek-proxy/index.ts` | 142 | `userData?.subscription_status === "premium"` — required `"premium"` to grant the paid rate limit |

Every paid user in the DB had `subscription_status='max'` (set manually by admin SQL or via RevenueCat promo flows that bypassed the buggy app-side write). The proxy's `=== "premium"` comparison therefore returned `false` for them, falling through to `RATE_LIMIT_FREE = 0`, which makes any request trigger `currentCount (0) >= 0 → 429`.

Pre-fix DB state confirmed the disconnect: **0 users had `"premium"`, 4 users had `"max"`.** The buggy `"premium"` write path had never produced a row.

### Founder's specific failure

Edge function logs around the founder's test session (epoch micros):

| Timestamp | Function | Status | Notes |
|---|---|---|---|
| 1777657528099 | sync-subscription | 200 | Initial post-login sync, sent `status: "free"` (no entitlement yet) |
| 1777657614690 | sync-subscription | **500** | Post-purchase sync, sent `status: "premium"` — DB update errored, **NOT** a 400 INVALID_STATUS |
| 1777657624778 | deepseek-proxy | 429 | Founder's AI prompt — rate-limited because their `subscription_status` was still `"free"` |

The 500 from sync-subscription is a **separate** issue from the tier mismatch and is the subject of the follow-up investigation below. The 429 from the proxy is what the founder saw.

---

## Fixes applied

### 1. Code (committed `a8a194f`)

- **`lib/core/services/subscription_service.dart:796`** — write `'max'` instead of `'premium'`
- **`supabase/functions/deepseek-proxy/index.ts:142`** — check `=== "max"`
- **`supabase/functions/sync-subscription/index.ts:9`** — `VALID_STATUSES = ["free", "max"]`

`flutter analyze lib/core/services/subscription_service.dart` — 0 issues.

### 2. Edge function deploys

```
$ supabase functions deploy deepseek-proxy --project-ref bapwklwxmwhpucutyras
Deployed Functions on project bapwklwxmwhpucutyras: deepseek-proxy

$ supabase functions deploy sync-subscription --project-ref bapwklwxmwhpucutyras
Deployed Functions on project bapwklwxmwhpucutyras: sync-subscription
```

### 3. Founder row + rate-limit reset

```sql
UPDATE users
SET subscription_status = 'max',
    subscription_expires_at = NOW() + INTERVAL '1 year'
WHERE id = '3c44e337-7773-48cc-b9e2-0170b58ba93d';
```

**Before:** `subscription_status='free'`, `subscription_expires_at=null`
**After:**  `subscription_status='max'`, `subscription_expires_at=2027-05-01 18:08:53Z`

```sql
DELETE FROM ai_rate_limits WHERE user_id = '3c44e337-7773-48cc-b9e2-0170b58ba93d';
```

Note: schema is `(user_id, date, request_count)` — date-keyed rows, not the `daily_count`/`last_reset_at` columns the runbook assumed. Founder had 0 rows pre-cleanup; delete returned empty (defensive no-op).

---

## Verification

- **Founder's row state confirmed via MCP:** `subscription_status='max'`, expires 2027-05-01.
- **Pending:** founder retests on real device — open AI hub, send a prompt. Tagged below.
- `flutter analyze lib/` — 0 issues maintained.

---

## Sandbox-sync investigation (read-only — no code changes)

**Goal:** understand why the founder's purchase produced a 500 from sync-subscription.

### Call chain (verified)

1. `SubscriptionService.purchase()` (`subscription_service.dart:413-468`) — `rc.Purchases.purchase(...)` → `_processCustomerInfo(result.customerInfo, ...)` after success.
2. `_processCustomerInfo()` (lines 308+) — reads `customerInfo.entitlements.active`, looks for `SubscriptionProducts.entitlementMax`, sets `tier = SubscriptionTier.max`, calls `_updateState`.
3. `_updateState()` (~line 765) — when `tierChanged && !state.isLoading`, calls `_syncSubscriptionToSupabase(state)` and `_cacheSubscriptionState(state)`.
4. `_syncSubscriptionToSupabase()` (line 782+) — invokes `sync-subscription` edge function.

The chain wires up correctly. The sync **was** invoked for the founder (proven by the log entry).

### Why did sync-subscription return 500?

The function only has two 500 paths:

- Line 117 — `updateError` from `serviceClient.from('users').update(...)` — DB rejected the update.
- Line 137 — catch-all unhandled exception inside the body.

The pre-fix request body would have been `status: "premium", product_id: <some sandbox id>, expires_at: <ISO>`. The pre-fix `VALID_STATUSES = ["free", "premium"]` would have accepted `"premium"`, so this is past the validator. That puts the failure inside the DB update or an unhandled error.

**Plausible causes (not verified — would need the function-internal log lines, which are not in the HTTP-level log we pulled):**

1. **Trigger guard.** Comments in the file say service-role bypasses a trigger guard. If a trigger is now blocking writes from service-role too (e.g., a check constraint added in a recent migration), the update fails. This is the most likely candidate.
2. **Constraint violation on `subscription_metadata`** or a related JSONB column the update touches indirectly.
3. **Service-role JWT issue** — a key rotation that didn't propagate to the function's env.

### Sandbox vs production receipts

The current `sync-subscription` does **not** call App Store's `verifyReceipt` endpoint — it trusts the client's `status` value and writes it directly. There is no sandbox/prod environment guard in the function. So the sandbox-receipt theory from the runbook does not apply to this codebase: the function couldn't reject a sandbox receipt because it never inspects the receipt at all.

This is a separate (security-adjacent) concern: a malicious client could call `sync-subscription` with `status: "max"` and lie. RevenueCat's webhooks are the authoritative receipt verifier; the current Dart client trusts RevenueCat's parsed entitlements but the edge function is purely a write helper. For the founder's case, this is fine — RevenueCat says they bought MAX, the client passes that on, the function writes it.

### Recommendations (for follow-up — not applied)

1. **Pull function-internal logs** for the founder's `sync-subscription` 500 (requires Supabase log explorer with a tighter time filter than the 24h MCP window).
2. **Look at `users` table triggers** — `\d+ users` or query `pg_trigger` for the `users` table. Any non-trivial trigger that could reject service-role writes is suspect.
3. **Backward-compat note for prod app builds.** Users on the App Store version still send `"premium"`. With `VALID_STATUSES = ["free", "max"]`, those syncs will now fail with 400 INVALID_STATUS instead of the previous 500. If the next app release is not imminent, consider temporarily aliasing `"premium" → "max"` in sync-subscription. (CTO call — not applied here.)

---

## Prod-impact query

Per the runbook, looking for paying users stuck on `'free'`:

```sql
SELECT id, email, subscription_status, subscription_expires_at,
       subscription_product_id, created_at
FROM users
WHERE subscription_status = 'free'
  AND (subscription_expires_at IS NOT NULL
       OR subscription_product_id IS NOT NULL)
ORDER BY created_at DESC;
```

**Result: 0 rows.** No silent stranded paying users.

**Cross-check** on the 4 pre-existing `"max"` users:

| Email | product_id | expires_at | Provenance |
|---|---|---|---|
| `abdulfatah.m.y@gmail.com` | `rc_promo_Silni MAX_lifetime` | 2225-12-12 | RevenueCat promo entitlement |
| `testpatuncle@test.com` | null | null | Manual admin SQL |
| `alhalafi2101@gmail.com` | null | null | Manual admin SQL |
| `tota296296@gmail.com` | null | null | Manual admin SQL |

3 of 4 are bare admin upgrades (no product_id, no expiry). 1 has a RevenueCat lifetime promo. None came from a normal purchase flow — consistent with the finding that the broken `"premium"` write path never produced a single row.

---

## Surprising findings

1. **The sync function never wrote the value the app sent.** The app sends `"premium"` → function accepts `"premium"` → DB never has `"premium"`. That's not a validator/spelling mismatch (those would 400). The post-purchase sync attempts that should have produced `"premium"` rows have all been 500-ing — the broken-tier-write *and* a separate DB-update bug have been compounding silently for the entire 4-user lifespan of the paid tier.

2. **Three out-of-sync places, one consistent direction.** App, sync-validator, and proxy all agreed on `"premium"`. The only thing that disagreed was the actual production reality (`"max"`). This suggests the rename `premium → max` happened in the enum definition but never propagated to the rest of the stack. Likely a partial refactor.

3. **The error message wasn't misleading at the proxy layer.** The 429 was an honest rate-limit response. The misleading thing was `RATE_LIMIT_FREE = 0` — the safeguard treated paid users with mismatched tier strings as if they had the free-tier limit, then enforced it strictly (≥0). A more defensive proxy would default unknown-tier rows to `RATE_LIMIT_PREMIUM` (since the user is authenticated and the app already gates feature access), or return a distinct `TIER_UNRECOGNIZED` error so this drift would have been visible.

---

## Next steps

- 🟢 **AI restored for founder** — pending real-device confirmation.
- 🟡 **sync-subscription 500 follow-up** — needs function-internal logs + trigger inspection. Separate work, not blocking founder.
- 🟡 **App Store build** — current prod build will hit a new 400 on the `"premium"` → `"max"` validator change. Either ship a release soon, or add a temporary `"premium"` → `"max"` alias in the function.
- 🟢 **No bulk DB cleanup needed** — prod-impact query came back empty.

@founder — please retest on the real device: open AI hub → send a prompt. Should succeed. If it does, this bug is closed.
