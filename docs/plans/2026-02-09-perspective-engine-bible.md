# Perspective Engine Bible

> The definitive reference for the shared family tree perspective engine.
> Every node type's visibility scope and Arabic kinship labels.

## Canonical Family Tree (User A is creator)

```
          Pat.Great-GP ── Pat.Great-GM          Mat.Great-GP ── Mat.Great-GM
                │                                      │
         Pat.Grandpa ── Pat.Grandma            Mat.Grandpa ── Mat.Grandma
                │                                      │
       ┌────────┼────────┐                    ┌────────┼────────┐
       │        │        │                    │        │        │
    Pat.Uncle  Dad    Pat.Aunt            Mat.Uncle  Mom    Mat.Aunt
       │        │        │                    │        │        │
  Pat.Cous.M   │   Pat.Cous.F           Mat.Cous.M   │   Mat.Cous.F
  Pat.Cous.F   │                         Mat.Cous.F   │
                │                                      │
                Dad ═══════════════════════════ Mom
                                 │
                    ┌────────────┼────────────┐
                    │            │            │
                 Brother      User A       Sister
                    │            │            │
                 Nephew    User A ══ Spouse  Niece
                                 │
                            ┌────┼────┐
                            │         │
                           Son    Daughter
```

**Key:** `──` = parentOf, `══` = spouseOf, siblings share a parent row.

---

## Architecture: Two-Layer Filter Pipeline

```
All Group Relatives
    ↓
[1] Enrich Sibling Edges (fix missing parentOf for ALL sibling pairs)
    ↓
[2] Rahim Scope Filter (directional BFS — blood only + direct spouse)
    ↓
Visible Relatives → computeLayout() → render with path-based perspective labels
```

---

## BFS Direction Rules

| How node was reached | Can go UP (parents) | Can go SIDEWAYS (siblings) | Can go DOWN (children) |
|---|---|---|---|
| **Start** (viewer) | Yes | Yes | Yes |
| **Via UP** (ancestor) | Yes | Yes | No |
| **Via SIDEWAYS** (sibling of ancestor) | No | No | Yes |
| **Via DOWN** (descendant) | No | No | Yes |

**Plus:** Viewer's direct spouse is added (1-hop, NOT traversed from).

**Why direction tracking?** Without it, going UP from a descendant would leak non-blood relatives into scope. Example: Mat.Uncle → Mom → User A → Dad (leaked! Dad is not blood to Mat.Uncle). Direction tracking blocks going UP from User A because User A was reached via DOWN.

---

## Edges After Enrichment

The sibling enrichment step propagates parentOf across ALL sibling pairs:

| Edge | Origin |
|------|--------|
| Dad → User A (parentOf) | Inferred from `father` type |
| Mom → User A (parentOf) | Inferred from `mother` type |
| Dad ↔ Mom (spouseOf) | Inferred |
| Brother ↔ User A (siblingOf) | Inferred from `brother` type |
| Sister ↔ User A (siblingOf) | Inferred from `sister` type |
| User A → Son (parentOf) | Inferred from `son` type |
| User A → Daughter (parentOf) | Inferred from `daughter` type |
| User A ↔ Spouse (spouseOf) | Inferred from `husband`/`wife` type |
| Pat.Grandpa → Dad (parentOf) | Inferred from `grandfather` + paternal |
| Pat.Grandma → Dad (parentOf) | Spouse-propagated from Grandpa |
| Pat.Grandpa ↔ Pat.Grandma (spouseOf) | Inferred |
| Mat.Grandpa → Mom (parentOf) | Inferred from `grandfather` + maternal |
| Mat.Grandma → Mom (parentOf) | Spouse-propagated |
| Mat.Grandpa ↔ Mat.Grandma (spouseOf) | Inferred |
| Pat.Uncle ↔ Dad (siblingOf) | Inferred from `uncle` + paternal |
| Pat.Aunt ↔ Dad (siblingOf) | Inferred from `aunt` + paternal |
| Mat.Uncle ↔ Mom (siblingOf) | Inferred from `uncle` + maternal |
| Mat.Aunt ↔ Mom (siblingOf) | Inferred from `aunt` + maternal |
| Brother → Nephew (parentOf) | Inferred from `nephew` type |
| Sister → Niece (parentOf) | Inferred from `niece` type |
| Pat.Uncle → Pat.Cous.M (parentOf) | Inferred from `cousin` + paternal |
| Mat.Aunt → Mat.Cous.F (parentOf) | Inferred from `cousin` + maternal |
| **ENRICHED:** Dad → Brother (parentOf) | Brother ↔ User A + Dad → User A |
| **ENRICHED:** Dad → Sister (parentOf) | Sister ↔ User A + Dad → User A |
| **ENRICHED:** Mom → Brother (parentOf) | Brother ↔ User A + Mom → User A |
| **ENRICHED:** Mom → Sister (parentOf) | Sister ↔ User A + Mom → User A |
| **ENRICHED:** Pat.Grandpa → Pat.Uncle (parentOf) | Pat.Uncle ↔ Dad + Pat.Grandpa → Dad |
| **ENRICHED:** Pat.Grandpa → Pat.Aunt (parentOf) | Pat.Aunt ↔ Dad + Pat.Grandpa → Dad |
| **ENRICHED:** Pat.Grandma → Pat.Uncle (parentOf) | Spouse of Pat.Grandpa |
| **ENRICHED:** Pat.Grandma → Pat.Aunt (parentOf) | Spouse of Pat.Grandpa |
| **ENRICHED:** Mat.Grandpa → Mat.Uncle (parentOf) | Mat.Uncle ↔ Mom + Mat.Grandpa → Mom |
| **ENRICHED:** Mat.Grandpa → Mat.Aunt (parentOf) | Mat.Aunt ↔ Mom + Mat.Grandpa → Mom |
| **ENRICHED:** Mat.Grandma → Mat.Uncle (parentOf) | Spouse of Mat.Grandpa |
| **ENRICHED:** Mat.Grandma → Mat.Aunt (parentOf) | Spouse of Mat.Grandpa |

---

## Perspective Tables

### 1. User A (Creator / Self)

| Visible Node | Label | Path |
|---|---|---|
| User A | أنا | — |
| Dad | أبي | parent |
| Mom | أمي | parent |
| Brother | أخوي | sibling |
| Sister | أختي | sibling |
| Son | ابني | child |
| Daughter | ابنتي | child |
| Spouse | زوجي/زوجتي | direct spouse |
| Pat.Grandpa | جدي | parent→parent |
| Pat.Grandma | جدتي | parent→parent |
| Mat.Grandpa | جدي | parent→parent |
| Mat.Grandma | جدتي | parent→parent |
| Pat.Uncle | عمي | parent(♂)→sibling(♂) |
| Pat.Aunt | عمتي | parent(♂)→sibling(♀) |
| Mat.Uncle | خالي | parent(♀)→sibling(♂) |
| Mat.Aunt | خالتي | parent(♀)→sibling(♀) |
| Nephew | ابن أخوي | sibling(♂)→child(♂) |
| Niece | بنت أختي | sibling(♀)→child(♀) |
| Pat.Cous.M | ابن عمي | parent(♂)→sibling(♂)→child(♂) |
| Pat.Cous.F | بنت عمي | parent(♂)→sibling(♂)→child(♀) |
| Mat.Cous.M | ابن خالي | parent(♀)→sibling(♂)→child(♂) |
| Mat.Cous.F | بنت خالتي | parent(♀)→sibling(♀)→child(♀) |

**Not visible:** Nobody — User A is the center of the tree, all nodes are blood-connected.

---

### 2. Dad (أب)

**BFS:** UP: Pat.Grandpa/Grandma → SIDEWAYS: Pat.Uncle/Aunt → DOWN: User A/Brother/Sister → further DOWN → Spouse: Mom

| Visible Node | Label | Path |
|---|---|---|
| Dad | أنا | — |
| Pat.Grandpa | أبي | parent |
| Pat.Grandma | أمي | parent |
| Pat.Uncle | أخوي | sibling |
| Pat.Aunt | أختي | sibling |
| User A | ابني | child |
| Brother | ابني | child |
| Sister | ابنتي | child |
| Mom | زوجتي | direct spouse |
| Son | حفيدي | child→child |
| Daughter | حفيدتي | child→child |
| Nephew | حفيدي | child(Brother)→child |
| Niece | حفيدتي | child(Sister)→child |
| Pat.Cous.M | ابن أخوي | sibling(♂)→child(♂) |
| Pat.Cous.F | بنت أخوي | sibling(♂)→child(♀) |

**Not visible:** Mat.Grandpa, Mat.Grandma, Mat.Uncle, Mat.Aunt, Mat.Cousins — Mom's blood family, only reachable through spouse (not traversed).

---

### 3. Mom (أم)

**Mirror of Dad, but maternal side.**

| Visible Node | Label | Path |
|---|---|---|
| Mom | أنا | — |
| Mat.Grandpa | أبي | parent |
| Mat.Grandma | أمي | parent |
| Mat.Uncle | أخوي | sibling |
| Mat.Aunt | أختي | sibling |
| User A | ابني | child |
| Brother | ابني | child |
| Sister | ابنتي | child |
| Dad | زوجي | direct spouse |
| Son | حفيدي | child→child |
| Daughter | حفيدتي | child→child |
| Nephew | حفيدي | child(Brother)→child |
| Niece | حفيدتي | child(Sister)→child |
| Mat.Cous.M | ابن أخوي | sibling(♂)→child(♂) |
| Mat.Cous.F | بنت أختي | sibling(♀)→child(♀) |

**Not visible:** Pat.Grandpa, Pat.Grandma, Pat.Uncle, Pat.Aunt, Pat.Cousins — Dad's family.

---

### 4. Brother (أخ)

**Same parents as User A → sees both sides, same scope as User A.**

| Visible Node | Label | Path |
|---|---|---|
| Brother | أنا | — |
| Dad | أبي | parent |
| Mom | أمي | parent |
| User A | أخوي | sibling |
| Sister | أختي | sibling |
| Nephew | ابني | child (his own) |
| Pat.Grandpa | جدي | parent→parent |
| Pat.Grandma | جدتي | parent→parent |
| Mat.Grandpa | جدي | parent→parent |
| Mat.Grandma | جدتي | parent→parent |
| Pat.Uncle | عمي | parent(♂)→sibling(♂) |
| Pat.Aunt | عمتي | parent(♂)→sibling(♀) |
| Mat.Uncle | خالي | parent(♀)→sibling(♂) |
| Mat.Aunt | خالتي | parent(♀)→sibling(♀) |
| Son | ابن أخوي | sibling(♂)→child(♂) |
| Daughter | بنت أخوي | sibling(♂)→child(♀) |
| Niece | بنت أختي | sibling(♀)→child(♀) |
| Pat.Cous.M | ابن عمي | parent(♂)→sibling(♂)→child(♂) |
| Mat.Cous.F | بنت خالتي | parent(♀)→sibling(♀)→child(♀) |

**Not visible:** Spouse (User A's spouse — not blood to Brother).

---

### 5. Sister (أخت)

**Same scope as Brother, relabeled for her perspective:**

| Visible Node | Label |
|---|---|
| Sister | أنا |
| Dad | أبي |
| Mom | أمي |
| User A | أخوي |
| Brother | أخوي |
| Niece | ابنتي (her own child) |
| Nephew | ابن أخوي (Brother's child) |
| Son | ابن أخوي |
| Daughter | بنت أخوي |
| *(rest same as Brother)* | |

---

### 6. Son (ابن)

**BFS:** Son → UP: User A → UP: Dad, Mom → further ancestors. User A's siblings become عم/عمة.

| Visible Node | Label | Path |
|---|---|---|
| Son | أنا | — |
| User A | أبي | parent |
| Daughter | أختي | sibling |
| Dad | جدي | parent→parent |
| Mom | جدتي | parent→parent |
| Brother | عمي | parent(♂)→sibling(♂) |
| Sister | عمتي | parent(♂)→sibling(♀) |
| Pat.Grandpa | جدي الأكبر | parent→parent→parent |
| Pat.Grandma | جدتي الكبرى | parent→parent→parent |
| Mat.Grandpa | جدي الأكبر | parent→parent→parent |
| Mat.Grandma | جدتي الكبرى | parent→parent→parent |
| Nephew | ابن عمي | parent(♂)→sibling(♂)→child(♂) |
| Niece | بنت عمتي | parent(♂)→sibling(♀)→child(♀) |
| Pat.Uncle | name fallback | 4-hop (great-uncle, no label) |

**Not visible:** User A's Spouse (not blood).

**Note:** User A (♂) is the connecting parent, so his siblings are عم/عمة (paternal side). Pat.Uncle/Mat.Uncle are great-uncles — no standard Arabic label, use full name.

---

### 7. Daughter (ابنة)

**Same as Son:** User A → "أبي", Son → "أخوي", Brother → "عمي", Sister → "عمتي".

---

### 8. Pat.Grandpa (جد أبوي)

| Visible Node | Label | Path |
|---|---|---|
| Pat.Grandpa | أنا | — |
| Pat.Great-GP | أبي | parent (if in tree) |
| Pat.Great-GM | أمي | parent (if in tree) |
| Dad | ابني | child |
| Pat.Uncle | ابني | child |
| Pat.Aunt | ابنتي | child |
| Pat.Grandma | زوجتي | direct spouse |
| User A | حفيدي | child→child |
| Brother | حفيدي | child→child |
| Sister | حفيدتي | child→child |
| Pat.Cous.M | حفيدي | child→child |
| Pat.Cous.F | حفيدتي | child→child |
| Son | name fallback | child→child→child (great-grandchild) |

**Not visible:** Mom, Mat.Grandpa, Mat.Grandma, Mat.Uncle, Mat.Aunt, Mat.Cousins.

---

### 9. Pat.Grandma (جدة أبوية)

**Same scope as Pat.Grandpa:** Pat.Grandpa → "زوجي", Dad → "ابني", etc.

---

### 10. Mat.Grandpa (جد أمي)

**Mirror of Pat.Grandpa, maternal side:**

| Visible Node | Label |
|---|---|
| Mat.Grandpa | أنا |
| Mom | ابنتي |
| Mat.Uncle | ابني |
| Mat.Aunt | ابنتي |
| Mat.Grandma | زوجتي |
| User A | حفيدي |
| Brother | حفيدي |
| Sister | حفيدتي |
| Mat.Cous.M | حفيدي |
| Mat.Cous.F | حفيدتي |

**Not visible:** Dad, Pat.side.

---

### 11. Mat.Grandma (جدة أمية)

**Same scope as Mat.Grandpa:** Mat.Grandpa → "زوجي", Mom → "ابنتي", etc.

---

### 12. Pat.Uncle (عم)

| Visible Node | Label | Path |
|---|---|---|
| Pat.Uncle | أنا | — |
| Pat.Grandpa | أبي | parent |
| Pat.Grandma | أمي | parent |
| Dad | أخوي | sibling |
| Pat.Aunt | أختي | sibling |
| Pat.Cous.M | ابني | child (his own) |
| Pat.Cous.F | ابنتي | child (his own) |
| User A | ابن أخوي | sibling(♂)→child(♂) |
| Brother | ابن أخوي | sibling(♂)→child(♂) |
| Sister | بنت أخوي | sibling(♂)→child(♀) |
| Son | name fallback | 3-hop (nephew's child) |
| Nephew | name fallback | 3-hop |

**Not visible:** Mom, Mat.Grandpa, Mat.Grandma, Mat.Uncle, Mat.Aunt, Mat.Cousins — Mom is just أخوي's wife.

---

### 13. Pat.Aunt (عمة)

**Same scope as Pat.Uncle:**

| Visible Node | Label |
|---|---|
| Pat.Aunt | أنا |
| Pat.Grandpa | أبي |
| Pat.Grandma | أمي |
| Dad | أخوي |
| Pat.Uncle | أخوي |
| User A | ابن أخوي |
| Brother | ابن أخوي |
| Sister | بنت أخوي |
| Pat.Cous.M | ابن أخوي (Pat.Uncle's son = brother's son) |
| Pat.Cous.F | بنت أخوي (Pat.Uncle's daughter) |

---

### 14. Mat.Uncle (خال)

| Visible Node | Label | Path |
|---|---|---|
| Mat.Uncle | أنا | — |
| Mat.Grandpa | أبي | parent |
| Mat.Grandma | أمي | parent |
| Mom | أختي | sibling |
| Mat.Aunt | أختي | sibling |
| Mat.Cous.M | ابني | child (his own) |
| User A | ابن أختي | sibling(♀ Mom)→child(♂) |
| Brother | ابن أختي | sibling(♀ Mom)→child(♂) |
| Sister | بنت أختي | sibling(♀ Mom)→child(♀) |
| Mat.Cous.F | بنت أختي | sibling(♀ Mat.Aunt)→child(♀) |

**Not visible:** Dad, Pat.Grandpa, Pat.Grandma, Pat.Uncle, Pat.Aunt, Pat.Cousins — Dad is just أختي's husband.

---

### 15. Mat.Aunt (خالة)

**Same scope as Mat.Uncle:**

| Visible Node | Label |
|---|---|
| Mat.Aunt | أنا |
| Mat.Grandpa | أبي |
| Mat.Grandma | أمي |
| Mom | أختي |
| Mat.Uncle | أخوي |
| Mat.Cous.F | ابنتي (her own child) |
| User A | ابن أختي (Mom's son) |
| Brother | ابن أختي |
| Sister | بنت أختي |
| Mat.Cous.M | ابن أخوي (Mat.Uncle's son = brother's son) |

**Not visible:** Dad, Pat.side.

---

### 16. Pat.Cousin.Male (ابن عم)

| Visible Node | Label | Path |
|---|---|---|
| Pat.Cous.M | أنا | — |
| Pat.Uncle | أبي | parent |
| Pat.Grandpa | جدي | parent→parent |
| Pat.Grandma | جدتي | parent→parent |
| Dad | عمي | parent(♂)→sibling(♂) |
| Pat.Aunt | عمتي | parent(♂)→sibling(♀) |
| Pat.Cous.F | أختي | sibling (same parent) |
| User A | ابن عمي | parent(♂)→sibling(♂)→child(♂) |
| Brother | ابن عمي | parent(♂)→sibling(♂)→child(♂) |
| Sister | بنت عمي | parent(♂)→sibling(♂)→child(♀) |

**Not visible:** Mom, Mat.side, Spouse.

---

### 17. Pat.Cousin.Female (بنت عم / بنت عمة)

**Same as Pat.Cousin.Male if same parent (Pat.Uncle).**

If parent is Pat.Aunt instead:

| Visible Node | Label |
|---|---|
| Pat.Cous.F | أنا |
| Pat.Aunt | أمي |
| Pat.Grandpa | جدي |
| Pat.Grandma | جدتي |
| Dad | خالي | parent(♀)→sibling(♂) |
| Pat.Uncle | خالي | parent(♀)→sibling(♂) |
| User A | ابن خالي | parent(♀)→sibling(♂)→child(♂) |

**Note:** When parent is female (Pat.Aunt), Dad becomes خالي not عمي — the parent's gender flips the labeling.

---

### 18. Mat.Cousin.Male (ابن خال)

| Visible Node | Label | Path |
|---|---|---|
| Mat.Cous.M | أنا | — |
| Mat.Uncle | أبي | parent |
| Mat.Grandpa | جدي | parent→parent |
| Mat.Grandma | جدتي | parent→parent |
| Mom | عمتي | parent(♂)→sibling(♀) |
| Mat.Aunt | عمتي | parent(♂)→sibling(♀) |
| User A | ابن عمتي | parent(♂)→sibling(♀ Mom)→child(♂) |
| Brother | ابن عمتي | parent(♂)→sibling(♀ Mom)→child(♂) |
| Sister | بنت عمتي | parent(♂)→sibling(♀ Mom)→child(♀) |

**Note:** Mat.Uncle is male, so his children see his siblings as عم/عمة. Mom is عمتي (father's sister) from this perspective.

---

### 19. Mat.Cousin.Female (بنت خالة)

| Visible Node | Label | Path |
|---|---|---|
| Mat.Cous.F | أنا | — |
| Mat.Aunt | أمي | parent |
| Mat.Grandpa | جدي | parent→parent |
| Mat.Grandma | جدتي | parent→parent |
| Mom | خالتي | parent(♀)→sibling(♀) |
| Mat.Uncle | خالي | parent(♀)→sibling(♂) |
| User A | ابن خالتي | parent(♀)→sibling(♀ Mom)→child(♂) |
| Brother | ابن خالتي | parent(♀)→sibling(♀ Mom)→child(♂) |
| Sister | بنت خالتي | parent(♀)→sibling(♀ Mom)→child(♀) |
| Mat.Cous.M | ابن خالي | parent(♀)→sibling(♂ Mat.Uncle)→child(♂) |

**Not visible:** Dad, Pat.side.

---

### 20. Nephew (ابن أخ — Brother's son)

| Visible Node | Label | Path |
|---|---|---|
| Nephew | أنا | — |
| Brother | أبي | parent |
| Dad | جدي | parent→parent |
| Mom | جدتي | parent→parent |
| User A | عمي | parent(♂)→sibling(♂) |
| Sister | عمتي | parent(♂)→sibling(♀) |
| Pat.Grandpa | جدي الأكبر | parent→parent→parent |
| Pat.Grandma | جدتي الكبرى | parent→parent→parent |
| Mat.Grandpa | جدي الأكبر | parent→parent→parent |
| Mat.Grandma | جدتي الكبرى | parent→parent→parent |
| Son | ابن عمي | parent(♂)→sibling(♂)→child(♂) |
| Daughter | بنت عمي | parent(♂)→sibling(♂)→child(♀) |
| Niece | بنت عمتي | parent(♂)→sibling(♀)→child(♀) |
| Pat.Uncle | name fallback | grandparent→sibling (great-uncle, 4-hop) |

**Not visible:** User A's Spouse.

---

### 21. Niece (بنت أخت — Sister's daughter)

| Visible Node | Label | Path |
|---|---|---|
| Niece | أنا | — |
| Sister | أمي | parent |
| Dad | جدي | parent→parent |
| Mom | جدتي | parent→parent |
| User A | خالي | parent(♀)→sibling(♂) |
| Brother | خالي | parent(♀)→sibling(♂) |
| Son | ابن خالي | parent(♀)→sibling(♂ User A)→child(♂) |
| Daughter | بنت خالي | parent(♀)→sibling(♂ User A)→child(♀) |
| Nephew | ابن خالي | parent(♀)→sibling(♂ Brother)→child(♂) |
| Pat.Grandpa | جدي الأكبر | parent→parent→parent |
| Mat.Grandpa | جدي الأكبر | parent→parent→parent |

**Key difference from Nephew:** Parent (Sister) is female → User A/Brother = خالي (not عمي).

---

### 22. Spouse (زوج/زوجة)

| Visible Node | Label | Path |
|---|---|---|
| Spouse | أنا | — |
| User A | زوجي/زوجتي | direct spouse |

**Not visible:** Everyone else — no blood connection. Dad, Mom, Brother, Sister, Grandparents, Uncles, Cousins, Son, Daughter are all NOT reachable via blood BFS.

**Note:** Son/Daughter edges are only from User A → Son/Daughter (parentOf). No Spouse → Son edge exists in the current data model. Spouse's blood family would be a separate tree.

---

## Label Resolution Algorithm

| Priority | Condition | Label (♂ target) | Label (♀ target) |
|---|---|---|---|
| 1 | Self | أنا | أنا |
| 2 | Direct parent | أبي | أمي |
| 3 | Direct child | ابني | ابنتي |
| 4 | Sibling | أخوي | أختي |
| 5 | Direct spouse | زوجي | زوجتي |
| 6 | Parent(♂)'s sibling(♂) | عمي | — |
| 7 | Parent(♂)'s sibling(♀) | — | عمتي |
| 8 | Parent(♀)'s sibling(♂) | خالي | — |
| 9 | Parent(♀)'s sibling(♀) | — | خالتي |
| 10 | Sibling(♂)'s child | ابن أخوي | بنت أخوي |
| 11 | Sibling(♀)'s child | ابن أختي | بنت أختي |
| 12 | Parent's parent | جدي | جدتي |
| 13 | Child's child | حفيدي | حفيدتي |
| 14 | Parent(♂)→sibling(♂)→child | ابن عمي | بنت عمي |
| 15 | Parent(♂)→sibling(♀)→child | ابن عمتي | بنت عمتي |
| 16 | Parent(♀)→sibling(♂)→child | ابن خالي | بنت خالي |
| 17 | Parent(♀)→sibling(♀)→child | ابن خالتي | بنت خالتي |
| 18 | Parent→parent→parent | جدي الأكبر | جدتي الكبرى |
| 19 | Fallback | person's fullName | person's fullName |

---

## Key Insight: Parent Gender Determines Side

The critical rule that makes all perspectives dynamic:

> **The gender of the CONNECTING PARENT determines whether labels are paternal (عم) or maternal (خال).**

- If you reach a target through a **male** parent → paternal labels (عم/عمة)
- If you reach a target through a **female** parent → maternal labels (خال/خالة)

This single rule handles ALL perspectives correctly without hardcoding any specific case.

### Examples:
- **Nephew** (Brother's son): parent = Brother (♂) → User A = عمي
- **Niece** (Sister's daughter): parent = Sister (♀) → User A = خالي
- **ابن عم** (Pat.Uncle's son): parent = Pat.Uncle (♂) → Dad = عمي
- **بنت خالة** (Mat.Aunt's daughter): parent = Mat.Aunt (♀) → Mom = خالتي
- **ابن خال** (Mat.Uncle's son): parent = Mat.Uncle (♂) → Mom = عمتي (!)

The last example is particularly important: Mat.Uncle is male, so from his son's perspective, Mom (Mat.Uncle's sister) is عمتي — even though from User A's perspective she's "أمي". The algorithm handles this automatically.

---

## Future (Not This PR)

- **Mahram privacy filter** — opt-in setting to hide ghayr-mahram opposite-gender relatives
- Relevance tiers (collapse distant branches by default)
- Re-centering tree on tap (navigate to another person's perspective)
- Privacy/blocking layer (user-controlled visibility)
- Foster/Rada'ah relationships
