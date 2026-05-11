# Cross-Group Personal Identity Aggregation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use `- [ ]` checkboxes.

**Goal:** Make a user's primary relationships follow them everywhere. Today, when admin claims testprodjoiner as his wife in admin's group, that relationship is invisible in testprodjoiner's personal mode, in any group she creates, and to anyone trying to claim her as a relative via a different invite. After this lands: testprod is her husband — period. Everywhere she views. Available as a candidate when others try to claim her.

**Architecture: Personal-shadow projection.** On claim approval, denormalize the "other side" of the relationship into the claimant's personal scope. Each shadow row carries `mirrors_relative_id` linking to the canonical (admin-owned) row. Existing merge logic (Task A3 `groupTreeRelativesProvider`) naturally surfaces shadows in every group context. The address book dedups canonical vs shadow. The wizard's candidate search also looks in the anchor user's personal shadows. Cleanup on leave/kick removes shadows.

**Why not real-time aggregation (union edges across groups at query time)?**
- Tree layout algorithm assumes one self-node per render → would need graph-rewriting layer
- Rahim scope computation gets complicated across multiple group graphs
- Performance: every render fetches from N groups instead of 1
- Denormalization with `mirrors_relative_id` is incrementally implementable and reuses existing infrastructure

**Trade-off acknowledged:** data duplication. If admin updates testprod's photo, joiner's shadow goes stale. Mitigated by: (a) shadow only stores stable fields (name, gender, type), photo URL is snapshotted; (b) future sync job can refresh shadows from canonicals. For pre-launch, stale photo is acceptable.

**Tech Stack:** PostgreSQL (SECURITY DEFINER RPCs, RLS), Flutter (Riverpod, Supabase). Same conventions as the deferred-membership and personal-vs-shared refactors.

---

## Mental Model

```
                 Admin's group: عائلة عبدالله الزهراني
                 ─────────────────────────────────────
                 testprod (self, admin-owned)
                    │ spouse_of
                    │
                 testprodjoiner-in-admin-group (owned by joiner, is_self)
                 ─────────────────────────────────────


                 Personal scope (joiner-owned, family_group_id=NULL)
                 ─────────────────────────────────────────────
                 testprodjoiner-personal-self (is_self)
                    │ spouse_of (joiner-owned)
                    │
                 testprod-personal-shadow (mirrors → testprod's canonical id)
                 ─────────────────────────────────────────────


                 test fam (joiner's own group; admin = joiner)
                 ─────────────────────────────────────
                 testprodjoiner-in-test-fam (self, joiner-owned)
                    │ parent_of (joiner-owned)
                    │
                 Rajhi Tea Boy (mother, joiner-owned)
                 ─────────────────────────────────────


                 When joiner views test fam:
                   - test fam's relatives (self + mother)
                   - + viewer's personal scope (shadow of testprod)
                   = self + mother + husband testprod ✓
```

---

## File Structure

**Migrations:**
- `20260512100000_add_mirrors_relative_id.sql` — schema column + index
- `20260512110000_personal_self_node_guarantee.sql` — backfill missing personal self-nodes
- `20260512120000_approve_claim_creates_shadow.sql` — extend `approve_node_claim`
- `20260512130000_backfill_personal_shadows.sql` — one-shot shadow backfill for existing approved claims
- `20260512140000_candidate_search_includes_shadows.sql` — extend `get_candidate_relatives`
- `20260512150000_purge_extends_to_shadows.sql` — extend `_purge_member_group_data`

**Dart:**
- Modify: `lib/features/home/providers/home_providers.dart` — address-book dedup by `mirrors_relative_id`
- Modify: `lib/shared/models/relative_model.dart` — expose `mirrorsRelativeId` field

---

# Phase 1 — Schema + invariants

### Task 1: Add `mirrors_relative_id` column

**Files:**
- Create: `supabase/migrations/20260512100000_add_mirrors_relative_id.sql`

- [ ] **Step 1: Write the migration**

```sql
-- 20260512100000_add_mirrors_relative_id.sql
-- Track personal shadows that mirror admin-owned canonical relatives.
-- When user A claims to be admin's spouse via approve_node_claim, the
-- admin's "wife" row (canonical, admin-owned, in admin's group) gets a
-- personal-scope shadow inserted on the joiner's side. The shadow lives
-- in user A's personal NULL scope, has relationship_type from A's POV
-- ('husband'), and points to the canonical via mirrors_relative_id.

ALTER TABLE public.relatives
  ADD COLUMN IF NOT EXISTS mirrors_relative_id UUID
    REFERENCES public.relatives(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_relatives_mirrors_relative_id
  ON public.relatives(mirrors_relative_id)
  WHERE mirrors_relative_id IS NOT NULL;

COMMENT ON COLUMN public.relatives.mirrors_relative_id IS
  'When set, this row is a personal-scope shadow of another relative row '
  '(the canonical, typically admin-owned in a shared group). Used for '
  'cross-group identity projection (joiner sees her husband everywhere) '
  'and address-book dedup.';
```

- [ ] **Step 2: Apply via MCP**

- [ ] **Step 3: Verify**

```sql
SELECT column_name FROM information_schema.columns
WHERE table_name='relatives' AND column_name='mirrors_relative_id';
-- Expected: 1 row

SELECT indexname FROM pg_indexes
WHERE indexname='idx_relatives_mirrors_relative_id';
-- Expected: 1 row
```

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260512100000_add_mirrors_relative_id.sql
git commit -m "feat(reciprocity): mirrors_relative_id column for personal shadows"
```

---

### Task 2: Personal self-node guarantee

**Files:**
- Create: `supabase/migrations/20260512110000_personal_self_node_guarantee.sql`

**Why:** Personal shadows anchor to the user's personal NULL-scope self-node. If that's missing (e.g., kicked-and-rejoined users, or users created before the `self_node_on_signup` trigger), shadows have nothing to attach to. This migration ensures every authenticated user has exactly one `is_self=true AND family_group_id IS NULL` row.

- [ ] **Step 1: Probe — who's missing a personal self-node?**

```sql
SELECT u.id, u.email, u.raw_user_meta_data->>'display_name' AS name
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM public.relatives r
  WHERE r.user_id = u.id
    AND r.is_self = true
    AND r.family_group_id IS NULL
);
```

Save the output. If unexpectedly high (>50 rows pre-launch), check assumptions.

- [ ] **Step 2: Write the migration**

```sql
-- 20260512110000_personal_self_node_guarantee.sql
-- Backfill personal NULL-scope self-nodes for users who don't have one.
-- These are the anchor for cross-group personal-shadow projection.

BEGIN;

DO $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM auth.users u
  WHERE NOT EXISTS (
    SELECT 1 FROM public.relatives r
    WHERE r.user_id = u.id
      AND r.is_self = true
      AND r.family_group_id IS NULL
  );
  RAISE NOTICE 'Backfilling % personal self-nodes', v_count;
END $$;

INSERT INTO public.relatives (
  user_id, full_name, gender, relationship_type, family_group_id,
  is_self, added_by, relative_category
)
SELECT
  u.id,
  COALESCE(
    u.raw_user_meta_data->>'display_name',
    u.raw_user_meta_data->>'full_name',
    split_part(u.email, '@', 1),
    'مستخدم'
  ),
  COALESCE(u.raw_user_meta_data->>'gender', 'male'),
  'other',
  NULL,        -- personal scope
  true,        -- is_self
  u.id,        -- added_by themselves
  'general'
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM public.relatives r
  WHERE r.user_id = u.id
    AND r.is_self = true
    AND r.family_group_id IS NULL
);

COMMIT;
```

**Important:** Check column names against the current `relatives` schema. The actual columns probably include `family_side`, `date_of_birth`, etc. Insert only the columns we need; rely on defaults for the rest. Check the `add_relative_screen.dart`'s insert pattern for guidance.

- [ ] **Step 3: Apply via MCP, verify**

```sql
SELECT COUNT(*) FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM relatives r
  WHERE r.user_id = u.id AND r.is_self = true AND r.family_group_id IS NULL
);
-- Expected: 0
```

- [ ] **Step 4: Commit**

```bash
git commit -m "fix(reciprocity): backfill personal self-nodes for shadow anchoring"
```

---

# Phase 2 — Shadow creation on approval

### Task 3: Extend `approve_node_claim` to create personal shadow

**Files:**
- Create: `supabase/migrations/20260512120000_approve_claim_creates_shadow.sql`

**Why:** When admin approves a claim that creates a relationship like "joiner is my wife", we need to ALSO create a personal-scope shadow of the admin in the joiner's personal scope so testprod appears as joiner's husband everywhere joiner views.

- [ ] **Step 1: Read the current `approve_node_claim`**

```sql
SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname='approve_node_claim';
```

Copy the function body. We'll insert ADDITIONAL logic without removing existing behavior.

- [ ] **Step 2: Identify the inverse-relationship mapping**

When joiner declared themselves as `spouse` of admin, admin's relationship_type to joiner is also `spouse` (symmetric). But for "husband"/"wife" specificity we need gender:
- Joiner is female + declared spouse → admin is male → admin's shadow relationship_type = 'husband'
- Joiner is male + declared spouse → admin is female → admin's shadow relationship_type = 'wife'

For parent/child (asymmetric):
- Joiner declared as `parent` of admin → admin is joiner's CHILD → shadow type = 'son' or 'daughter' (based on admin's gender)
- Joiner declared as `child` of admin → admin is joiner's PARENT → shadow type = 'father' or 'mother' (based on admin's gender)
- Joiner declared as `sibling` of admin → admin is joiner's sibling → shadow type = 'brother' or 'sister'

Build a CASE expression that maps `(declared_edge_path, joiner_gender, admin_gender)` to the shadow's relationship_type.

- [ ] **Step 3: Write the migration**

```sql
-- 20260512120000_approve_claim_creates_shadow.sql
-- approve_node_claim now also creates a personal-scope shadow of the
-- ANCHOR (typically the admin) on the claimant's personal side.
-- This makes the relationship visible to the claimant everywhere they
-- view — personal mode, other groups, etc.

-- COMPLETE rewrite of approve_node_claim (read the previous version via
-- pg_get_functiondef and paste it verbatim, then insert the shadow-creation
-- block right before the final RETURN).

CREATE OR REPLACE FUNCTION public.approve_node_claim(p_claim_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_claim node_claims%ROWTYPE;
  v_target_relative_id UUID;
  v_created_new BOOLEAN := false;
  -- NEW for shadow:
  v_anchor_relative_id UUID;
  v_anchor_full_name TEXT;
  v_anchor_gender TEXT;
  v_anchor_user_id UUID;
  v_claimant_personal_self_id UUID;
  v_shadow_relationship_type TEXT;
  v_shadow_id UUID;
BEGIN
  -- ... (existing logic verbatim from the prior approve_node_claim) ...
  -- The existing logic:
  --   1. auth check
  --   2. lock + fetch claim
  --   3. admin auth check
  --   4. pending status check
  --   5. determine v_target_relative_id (existing OR new)
  --   6. flip is_self + user_id on target
  --   7. INSERT family_group_members ON CONFLICT UPDATE
  --   8. insert family_edges in admin's group
  --   9. UPDATE node_claims status='approved'
  
  -- ▼ NEW: Personal-shadow projection ▼
  -- Look up the anchor (admin's relative). The anchor is the canonical
  -- person we shadow into the claimant's personal scope.
  SELECT id, full_name, gender, user_id
    INTO v_anchor_relative_id, v_anchor_full_name, v_anchor_gender, v_anchor_user_id
    FROM relatives
   WHERE id = v_claim.declared_anchor_relative_id;
  
  -- Find the claimant's personal self-node (the anchor for shadows).
  SELECT id INTO v_claimant_personal_self_id
    FROM relatives
   WHERE user_id = v_claim.claimant_user_id
     AND is_self = true
     AND family_group_id IS NULL
   LIMIT 1;
  
  -- Skip shadow creation if either side is missing (defensive — should
  -- never happen post-Task-2 backfill).
  IF v_anchor_relative_id IS NOT NULL AND v_claimant_personal_self_id IS NOT NULL THEN
    -- Compute the shadow's relationship_type from the claimant's POV.
    -- The claim declared the claimant's relationship TO the anchor.
    -- We need the INVERSE.
    v_shadow_relationship_type := CASE v_claim.declared_edge_path
      WHEN 'spouse' THEN
        CASE WHEN v_anchor_gender = 'male' THEN 'husband' ELSE 'wife' END
      WHEN 'parent' THEN
        -- Claimant declared they're a PARENT of anchor → anchor is claimant's child
        CASE WHEN v_anchor_gender = 'male' THEN 'son' ELSE 'daughter' END
      WHEN 'child' THEN
        -- Claimant declared they're a CHILD of anchor → anchor is claimant's parent
        CASE WHEN v_anchor_gender = 'male' THEN 'father' ELSE 'mother' END
      WHEN 'sibling' THEN
        CASE WHEN v_anchor_gender = 'male' THEN 'brother' ELSE 'sister' END
      ELSE 'other'
    END;
    
    -- Insert the personal shadow.
    INSERT INTO relatives (
      user_id, full_name, gender, relationship_type,
      family_group_id, is_self, added_by, mirrors_relative_id,
      relative_category
    ) VALUES (
      v_claim.claimant_user_id,    -- owned by claimant
      v_anchor_full_name,
      v_anchor_gender,
      v_shadow_relationship_type,
      NULL,                          -- personal scope
      false,
      v_caller,                      -- approved by admin
      v_anchor_relative_id,          -- canonical pointer
      'general'
    )
    RETURNING id INTO v_shadow_id;
    
    -- Insert personal-scope edge from claimant's personal self → shadow.
    -- Edge type matches the canonical edge type.
    DECLARE
      v_edge_type TEXT;
      v_edge_from TEXT;
      v_edge_to TEXT;
    BEGIN
      v_edge_type := CASE v_claim.declared_edge_path
        WHEN 'spouse' THEN 'spouse_of'
        WHEN 'parent' THEN 'parent_of'      -- claimant is parent → from claimant to anchor
        WHEN 'child'  THEN 'parent_of'      -- claimant is child → from anchor to claimant
        WHEN 'sibling' THEN 'sibling_of'
        ELSE 'spouse_of'
      END;
      
      -- Direction depends on edge type semantics
      IF v_claim.declared_edge_path = 'child' THEN
        -- shadow is parent → claimant
        v_edge_from := v_shadow_id::text;
        v_edge_to := v_claimant_personal_self_id::text;
      ELSIF v_claim.declared_edge_path = 'parent' THEN
        -- claimant is parent → shadow
        v_edge_from := v_claimant_personal_self_id::text;
        v_edge_to := v_shadow_id::text;
      ELSE
        -- symmetric (spouse, sibling)
        v_edge_from := v_claimant_personal_self_id::text;
        v_edge_to := v_shadow_id::text;
      END IF;
      
      INSERT INTO family_edges (
        user_id, from_id, to_id, edge_type, family_group_id
      ) VALUES (
        v_claim.claimant_user_id,
        v_edge_from,
        v_edge_to,
        v_edge_type,
        NULL    -- personal scope
      );
    END;
  END IF;
  
  -- ▼ Existing notification call ▼
  PERFORM public._notify_claim_status(
    v_claim.claimant_user_id, v_claim.group_id, 'claim_approved'
  );
  
  RETURN jsonb_build_object(
    'claim_id', p_claim_id,
    'group_id', v_claim.group_id,
    'claimant_user_id', v_claim.claimant_user_id,
    'relative_id', v_target_relative_id,
    'created_new_node', v_created_new
  );
END;
$$;
```

**Important: this is a SKETCH. The actual implementer must:**
1. Pull the LIVE `approve_node_claim` body via `pg_get_functiondef`
2. Insert the shadow block right before the final RETURN
3. Preserve the existing edge-insertion logic and all the other behavior verbatim
4. Reconcile column names (e.g., `family_side`, `date_of_birth`) — match what the live INSERT into relatives uses

- [ ] **Step 4: Apply via MCP, verify with smoke**

```sql
SELECT proname, pronargs FROM pg_proc WHERE proname='approve_node_claim';
-- Expected: 1 row, pronargs=1, returns jsonb
```

- [ ] **Step 5: Commit**

---

### Task 4: Backfill personal shadows for existing approved claims

**Files:**
- Create: `supabase/migrations/20260512130000_backfill_personal_shadows.sql`

**Why:** Existing approved claims (e.g., testprodjoiner's wife-of-testprod claim) predate the shadow logic. One-shot backfill to create shadows for them.

- [ ] **Step 1: Probe — which claims need shadows?**

```sql
SELECT nc.id, nc.claimant_user_id, nc.declared_anchor_relative_id,
       nc.declared_edge_path, nc.declared_gender,
       r.full_name AS anchor_name, r.gender AS anchor_gender
FROM node_claims nc
JOIN relatives r ON r.id = nc.declared_anchor_relative_id
WHERE nc.status = 'approved'
  AND NOT EXISTS (
    -- Skip if shadow already exists
    SELECT 1 FROM relatives sh
    WHERE sh.user_id = nc.claimant_user_id
      AND sh.mirrors_relative_id = nc.declared_anchor_relative_id
      AND sh.family_group_id IS NULL
  );
```

Save the output. Pre-launch this should be ~1-5 rows.

- [ ] **Step 2: Write the migration**

```sql
-- 20260512130000_backfill_personal_shadows.sql
-- One-shot backfill of personal shadows for approved claims that
-- predate the shadow logic in 20260512120000.

DO $$
DECLARE
  rec RECORD;
  v_claimant_self_id UUID;
  v_shadow_id UUID;
  v_rel_type TEXT;
  v_edge_type TEXT;
  v_from TEXT;
  v_to TEXT;
BEGIN
  FOR rec IN
    SELECT nc.claimant_user_id, nc.declared_anchor_relative_id,
           nc.declared_edge_path, r.full_name AS anchor_name,
           r.gender AS anchor_gender
    FROM node_claims nc
    JOIN relatives r ON r.id = nc.declared_anchor_relative_id
    WHERE nc.status = 'approved'
      AND NOT EXISTS (
        SELECT 1 FROM relatives sh
        WHERE sh.user_id = nc.claimant_user_id
          AND sh.mirrors_relative_id = nc.declared_anchor_relative_id
          AND sh.family_group_id IS NULL
      )
  LOOP
    -- Find claimant's personal self-node
    SELECT id INTO v_claimant_self_id
      FROM relatives
     WHERE user_id = rec.claimant_user_id
       AND is_self = true AND family_group_id IS NULL
     LIMIT 1;
    
    CONTINUE WHEN v_claimant_self_id IS NULL;
    
    v_rel_type := CASE rec.declared_edge_path
      WHEN 'spouse' THEN
        CASE WHEN rec.anchor_gender = 'male' THEN 'husband' ELSE 'wife' END
      WHEN 'parent' THEN
        CASE WHEN rec.anchor_gender = 'male' THEN 'son' ELSE 'daughter' END
      WHEN 'child' THEN
        CASE WHEN rec.anchor_gender = 'male' THEN 'father' ELSE 'mother' END
      WHEN 'sibling' THEN
        CASE WHEN rec.anchor_gender = 'male' THEN 'brother' ELSE 'sister' END
      ELSE 'other'
    END;
    
    INSERT INTO relatives (
      user_id, full_name, gender, relationship_type, family_group_id,
      is_self, added_by, mirrors_relative_id, relative_category
    ) VALUES (
      rec.claimant_user_id, rec.anchor_name, rec.anchor_gender,
      v_rel_type, NULL, false, rec.claimant_user_id,
      rec.declared_anchor_relative_id, 'general'
    ) RETURNING id INTO v_shadow_id;
    
    v_edge_type := CASE rec.declared_edge_path
      WHEN 'spouse' THEN 'spouse_of'
      WHEN 'sibling' THEN 'sibling_of'
      ELSE 'parent_of'
    END;
    
    IF rec.declared_edge_path = 'child' THEN
      v_from := v_shadow_id::text;
      v_to := v_claimant_self_id::text;
    ELSIF rec.declared_edge_path = 'parent' THEN
      v_from := v_claimant_self_id::text;
      v_to := v_shadow_id::text;
    ELSE
      v_from := v_claimant_self_id::text;
      v_to := v_shadow_id::text;
    END IF;
    
    INSERT INTO family_edges (user_id, from_id, to_id, edge_type, family_group_id)
    VALUES (rec.claimant_user_id, v_from, v_to, v_edge_type, NULL);
    
    RAISE NOTICE 'Backfilled shadow for claimant=% anchor=% type=%',
      rec.claimant_user_id, rec.anchor_name, v_rel_type;
  END LOOP;
END $$;
```

- [ ] **Step 3: Apply via MCP, verify**

```sql
-- Should be 0 — every approved claim now has a shadow
SELECT COUNT(*) FROM node_claims nc
WHERE nc.status='approved'
  AND NOT EXISTS (
    SELECT 1 FROM relatives sh
    WHERE sh.user_id = nc.claimant_user_id
      AND sh.mirrors_relative_id = nc.declared_anchor_relative_id
      AND sh.family_group_id IS NULL
  );
```

- [ ] **Step 4: Commit**

---

# Phase 3 — Address-book dedup

### Task 5: `addressBookRelativesProvider` dedups by `mirrors_relative_id`

**Files:**
- Modify: `lib/features/home/providers/home_providers.dart`
- Modify: `lib/shared/models/relative_model.dart` — expose `mirrorsRelativeId` field if not already

**Why:** With shadows, the address book might show two rows for testprod: the canonical (admin-owned, visible in admin's group) AND the shadow (joiner-owned, personal scope). Show only one.

- [ ] **Step 1: Expose `mirrorsRelativeId` in the Dart model**

In `relative_model.dart`, find the `Relative` class. Add `final String? mirrorsRelativeId;` to the constructor/copyWith/toJson/fromJson. Check `Relative.fromJson(Map<String, dynamic>)` — read `json['mirrors_relative_id'] as String?`.

- [ ] **Step 2: Update `addressBookRelativesProvider`**

```dart
final addressBookRelativesProvider =
    StreamProvider.autoDispose<List<Relative>>((ref) {
  final link = ref.keepAlive();
  Timer? timer;
  ref.onDispose(() => timer?.cancel());
  ref.onCancel(() {
    timer = Timer(_cacheTimeout, () => link.close());
  });
  ref.onResume(() => timer?.cancel());

  return SupabaseConfig.client
      .from('relatives')
      .stream(primaryKey: ['id'])
      .map((rows) {
        final all = rows
            .map((json) => Relative.fromJson(json))
            .where((r) => !r.isSelf && !r.isArchived)
            .toList();
        
        // Dedup: if both canonical and shadow are visible, prefer the canonical.
        // A shadow has `mirrorsRelativeId != null`. The canonical is the row
        // whose id == some shadow's mirrorsRelativeId.
        final canonicalIds = all
            .map((r) => r.mirrorsRelativeId)
            .whereType<String>()
            .toSet();
        
        return all.where((r) {
          if (r.mirrorsRelativeId == null) {
            // Canonical row — always include
            return true;
          }
          // Shadow — include only if its canonical is NOT in the visible set
          // (which would mean RLS hides the canonical from this user)
          return !canonicalIds.contains(r.mirrorsRelativeId);
        }).toList();
      });
});
```

Wait — this logic is backwards. Let me think again:
- `canonicalIds` is the set of `mirrorsRelativeId` values from shadows. That's the IDs of canonicals that have shadows.
- For a shadow row: include it only if the canonical (with that id) is NOT in the visible set. But the canonical is visible iff its id is among `all`'s ids. So the right check is: include shadow iff canonical's id is NOT in `all`'s ids.

Corrected:
```dart
final visibleIds = all.map((r) => r.id).toSet();

return all.where((r) {
  if (r.mirrorsRelativeId == null) return true;
  // Shadow — include only if canonical is NOT visible
  return !visibleIds.contains(r.mirrorsRelativeId);
}).toList();
```

- [ ] **Step 3: Run analyzer**

```bash
flutter analyze lib/features/home/providers/home_providers.dart \
                lib/shared/models/relative_model.dart
```

- [ ] **Step 4: Commit**

---

# Phase 4 — Wizard candidate aggregation

### Task 6: `get_candidate_relatives` searches personal shadows

**Files:**
- Create: `supabase/migrations/20260512140000_candidate_search_includes_shadows.sql`

**Why:** When testprod uses an invite to join test fam as husband, the wizard's candidate query should find testprodjoiner (the anchor) as a match. Currently it only queries test fam scope edges. We extend it to ALSO query personal-scope edges anchored on testprodjoiner's personal self-node.

- [ ] **Step 1: Read the current `get_candidate_relatives`**

```sql
SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname='get_candidate_relatives';
```

The function has branches for parent/child/spouse/sibling/etc. Each branch queries `family_edges WHERE family_group_id = p_group_id`. We need to ALSO query personal-scope edges (`family_group_id IS NULL`) anchored on the anchor's personal self-node.

- [ ] **Step 2: Identify the anchor's personal-self link**

The anchor (passed as `p_anchor_relative_id`) is a relative in the target group. We need to find that user's PERSONAL self-node and search edges from there.

```sql
-- Get the user_id of the anchor (the person whose personal scope we'll also search)
SELECT user_id INTO v_anchor_user_id FROM relatives WHERE id = p_anchor_relative_id;
-- Find their personal self-node
SELECT id INTO v_anchor_personal_self_id
  FROM relatives
 WHERE user_id = v_anchor_user_id
   AND is_self = true
   AND family_group_id IS NULL
 LIMIT 1;
```

If the anchor has a personal self-node, the spouse branch becomes:

```sql
-- Existing: spouse_of edges in the group
SELECT DISTINCT r.id, r.full_name, ...
FROM family_edges e
JOIN relatives r ON ...
WHERE (e.from_id = p_anchor_relative_id::text OR e.to_id = p_anchor_relative_id::text)
  AND e.edge_type = 'spouse_of'
  AND e.family_group_id = p_group_id
  AND r.gender = p_gender
  AND r.is_self = false

UNION

-- NEW: spouse_of edges in the anchor user's personal scope (shadows)
SELECT DISTINCT r.id, r.full_name, ...
FROM family_edges e
JOIN relatives r ON ...
WHERE v_anchor_personal_self_id IS NOT NULL
  AND (e.from_id = v_anchor_personal_self_id::text OR e.to_id = v_anchor_personal_self_id::text)
  AND e.edge_type = 'spouse_of'
  AND e.family_group_id IS NULL
  AND e.user_id = v_anchor_user_id  -- only the anchor's own personal edges
  AND r.gender = p_gender
  AND r.is_self = false
  -- Exclude shadows that mirror people already in this group (avoid duplicates)
  AND NOT EXISTS (
    SELECT 1 FROM relatives canonical
    WHERE canonical.id = r.mirrors_relative_id
      AND canonical.family_group_id = p_group_id
  );
```

Apply similar UNION to each of the 9 branches.

- [ ] **Step 3: Write the migration**

Use the current `get_candidate_relatives` body as the base. Add the v_anchor_user_id + v_anchor_personal_self_id lookups at the top. Add a UNION clause to each edge-path branch.

This is sizable. Implementer must take care to:
- Preserve all existing logic
- Add UNION clauses (not OR-ed conditions — UNION dedupes by row identity)
- Test each edge_path

- [ ] **Step 4: Apply + verify**

```sql
-- Smoke: testprod tries to claim wife position in test fam
-- (test fam admin = testprodjoiner, anchor = testprodjoiner)
SET LOCAL "request.jwt.claims" = '{"sub":"8b3be95f-8c18-482e-848c-f5db4b6e3afd"}';
SELECT * FROM get_candidate_relatives(
  '<test_fam_group_id>'::uuid,
  '<testprodjoiner_in_test_fam_id>'::uuid,
  'spouse', NULL, 'male', '<test_fam_invite_code>'
);
-- Expected: at least 1 row matching the personal-shadow of testprod
```

- [ ] **Step 5: Commit**

---

# Phase 5 — Cleanup

### Task 7: `_purge_member_group_data` removes personal shadows

**Files:**
- Create: `supabase/migrations/20260512150000_purge_extends_to_shadows.sql`

**Why:** When testprodjoiner is kicked from admin's group, her personal shadow of testprod becomes stale (the relationship no longer holds). The kick purge should remove the shadow.

- [ ] **Step 1: Identify shadow-to-canonical link**

For each canonical relative in the group being purged that the departing user has a shadow of, delete the shadow.

```sql
-- All shadows owned by the departing user that mirror a canonical in the
-- group being purged.
SELECT id FROM relatives
WHERE user_id = p_user_id
  AND family_group_id IS NULL
  AND mirrors_relative_id IN (
    SELECT id FROM relatives WHERE family_group_id = p_group_id
  );
```

- [ ] **Step 2: Extend `_purge_member_group_data`**

Read current body via `pg_get_functiondef`. Add a new step that:
1. Collects shadow ids (owned by p_user_id, NULL scope, mirrors a canonical in p_group_id)
2. Deletes interactions on those shadows
3. Deletes personal edges (family_group_id IS NULL, user_id = p_user_id) referencing those shadows
4. Deletes the shadow rows themselves

Add right after the existing group-scope purge.

- [ ] **Step 3: Apply + verify**

- [ ] **Step 4: Commit**

---

# Phase 6 — Manual test

## Task 8: Verify cross-group reciprocity end-to-end

(User-driven.)

### Backfill check

Before testing, confirm the testprodjoiner case is handled by the backfill:

```sql
-- testprodjoiner should now have a personal shadow of testprod
SELECT r.id, r.full_name, r.relationship_type, r.user_id::text,
       r.family_group_id::text, r.mirrors_relative_id::text
FROM relatives r
WHERE r.user_id = '6251e7f6-445d-4954-a9c0-d430ae93cc48'
  AND r.mirrors_relative_id IS NOT NULL;
-- Expected: 1 row — shadow of testprod with type='husband'
```

### Journey 1: shadow visibility in personal mode

As testprodjoiner:
1. Tap switcher → "شخصي"
2. Open relatives page
3. Verify: testprod appears in the list (as "husband")
4. Verify: Rajhi Tea Boy still appears

### Journey 2: shadow visibility in another group

As testprodjoiner:
1. Tap switcher → "test fam" (her own group)
2. Open family tree
3. Verify: testprod appears in the tree as her husband (via personal merge from Task A3)
4. Open relatives page
5. Verify: testprod appears

### Journey 3: wizard candidate search finds shadow

As testprod (admin of original group):
1. Use the invite link to test fam (joiner's group)
2. Wizard prompts for role — pick "husband, male"
3. Verify: candidate list shows testprodjoiner (matched via her personal shadow connection)
4. Tap "claim existing node" → testprodjoiner
5. Wait for joiner to approve (joiner is admin of test fam)
6. After approval: testprod is a full member of test fam, the spouse relationship is in both groups

### Journey 4: cleanup on kick

As testprod (admin):
1. Kick testprodjoiner from admin's original group
2. Verify (via DB): testprodjoiner's shadow of testprod is deleted (mirrors_relative_id link removed)
3. testprodjoiner viewing her personal tree: testprod no longer appears

---

# Self-Review Checklist

**Spec coverage:**

- "testprodjoiner has testprod as a husband, the relative only appears in tree and not in relatives" → Task 5 (address-book dedup ensures the shadow appears as one row; Phase A3's address-book already shows it).
- "when she created fam group testjoiner is no longer there [== testprod isn't reachable]" → Tasks 3, 4 ensure shadow exists in personal scope → test fam's group-tree merge picks it up.
- "testprod tried to join the tree as a husband it shows there is no match" → Task 6 (candidate search includes shadows).

**Placeholder scan:** Tasks 3 and 6 explicitly require pulling the LIVE function body via `pg_get_functiondef` and inserting blocks rather than rewriting from scratch — flagged.

**Type consistency:** `mirrors_relative_id` (SQL) / `mirrorsRelativeId` (Dart) consistent. All UUIDs treated as TEXT for `family_edges` from_id/to_id per existing convention.

**Risk:**
- Task 3 (approve_node_claim rewrite) is high-risk because it's the central RPC. Implementer must copy live body verbatim and only INSERT the shadow block.
- Task 4 (backfill) is destructive (INSERTs new rows). Probe count first.
- Task 7 (purge extension) is destructive (DELETEs). Probe before applying.

---

# Open follow-ups (NOT in this plan)

- **Stale-photo sync:** if admin updates testprod's photo, joiner's shadow doesn't auto-update. A future job could refresh shadows from canonicals on schedule. Acceptable pre-launch.
- **Multi-hop shadows:** when admin claims joiner as wife AND joiner has her own parents in personal scope, admin doesn't get shadows of joiner's parents. That'd be in-laws projection — out of scope.
- **Bi-directional shadows:** when admin claims joiner as wife, admin gets a clean canonical reference (joiner's in-group row). But what if admin wants joiner to appear in admin's PERSONAL view too? Currently admin's view of joiner is group-scoped. A future enhancement.
