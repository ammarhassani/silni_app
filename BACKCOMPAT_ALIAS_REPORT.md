# Hotfix — sync-subscription premium→max alias

**Date:** 2026-05-01
**Trigger:** App Store production build still sends `subscription_status: "premium"`. Phase X premium→max standardization (commit `a8a194f`) tightened `VALID_STATUSES` to `["free", "max"]` — without this alias, all old-app-build syncs would hit `400 INVALID_STATUS`.

---

## Code change

**File:** [`supabase/functions/sync-subscription/index.ts`](supabase/functions/sync-subscription/index.ts)
**Commit:** `795ac73`

Inline alias inserted between body-parse and validation (lines 65–68):

```typescript
// Backward-compat alias: pre-Phase-X app builds send "premium" for the paid tier.
// Normalize to "max" so existing App Store users keep syncing correctly.
// TODO: remove this alias after forcing an app version update (probably v3.0).
const normalizedStatus = status === "premium" ? "max" : status;
```

Subsequent uses of `status` swapped to `normalizedStatus`:

- Line 71 — validator check: `!normalizedStatus || !VALID_STATUSES.includes(normalizedStatus)`
- Line 103 — DB update payload: `subscription_status: normalizedStatus`

Logs keep `raw_status` alongside the normalized value so we can see who's still on old builds:

```typescript
console.log("[sync-subscription] Syncing for user:", user.id, {
  status: normalizedStatus,
  raw_status: status,
  ...
});
```

---

## Deploy

```
$ date -u
2026-05-01T18:16:50Z

$ supabase functions deploy sync-subscription --project-ref bapwklwxmwhpucutyras
Uploading asset (sync-subscription): supabase/functions/sync-subscription/index.ts
Uploading asset (sync-subscription): supabase/functions/_shared/cors.ts
Deployed Functions on project bapwklwxmwhpucutyras: sync-subscription
```

**Deploy timestamp:** `2026-05-01T18:16:50Z`

---

## Verification

End-to-end curl tests require a live user JWT. Verified by static reasoning over the four input paths:

| Input `body.status` | After normalization | `VALID_STATUSES.includes(...)` | Outcome |
|---|---|---|---|
| `"free"` | `"free"` | true | passes validator, writes `"free"` |
| `"max"` | `"max"` | true | passes validator, writes `"max"` |
| `"premium"` | `"max"` (aliased) | true | passes validator, writes `"max"` ✓ new path |
| `"garbage"` | `"garbage"` | false | 400 INVALID_STATUS |
| `null` / missing | `undefined` | false | 400 INVALID_STATUS (caught by `!normalizedStatus`) |

The 400 INVALID_STATUS path no longer fires for `"premium"`. The 500 from the underlying DB-update bug (separate sync-flow follow-up) will still fire for any successful validator pass — that's expected, not a regression.

---

## TODO marker

Inline at [supabase/functions/sync-subscription/index.ts:67](supabase/functions/sync-subscription/index.ts#L67):

```typescript
// TODO: remove this alias after forcing an app version update (probably v3.0).
```

Removal trigger: next forced-update minimum-version bump that excludes pre-Phase-X clients from prod. Once the App Store no longer has any `"premium"`-sending clients in the wild, this normalization can be deleted and `VALID_STATUSES` enforcement returns to strict.
