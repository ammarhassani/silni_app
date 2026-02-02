# Family Tree Visual Rewrite — Design

**Date:** 2026-02-02
**Status:** Approved
**Scope:** Full canvas-based rewrite of the family tree screen using existing graph infrastructure

---

## Problem

The family tree screen renders a rigid grid with hardcoded generation levels based on `RelationshipType` enum values. It ignores the existing `FamilyGraph` model, `getGeneration()` BFS, and `getLabelForViewer()` perspective-aware labels. The result is:

- All uncles show "عم/خال" instead of "عمي" or "خالي"
- Extended family flattened into one row regardless of actual generation
- No visual indication of interaction health or streaks
- No animations — the tree feels dead
- Connection lines are thin gradient rectangles, not actual edge paths

The graph infrastructure (`FamilyGraph`, `FamilyEdge`, `FamilyGraphService`, `family_edges` table) is already built and persisting edges. The tree screen just needs to use it.

---

## Approach: Full CustomPainter Canvas

Everything drawn on a single `CustomPainter` canvas — nodes, lines, labels, animations. Wrapped in `InteractiveViewer` for pan/zoom. Detail interactions via Flutter `OverlayEntry` widgets positioned over the canvas.

### Why full canvas over hybrid approach

- Maximum control over rendering at any zoom level
- Single paint pass for the entire tree — no widget tree overhead for 30+ nodes
- Smooth zoom without widget layout recalculation
- Connection lines and nodes share the same coordinate system naturally

---

## Section 1: Layout Algorithm

Graph-driven positioning replaces hardcoded levels.

**Generation assignment:** `graph.getGeneration(nodeId)` runs BFS from the user node. User = 0, parents = -1, grandparents = -2, children = +1, uncles = -1 (siblings of parents), cousins = 0 (same generation as user). Already implemented in `FamilyGraph`, currently never called from the tree screen.

**Horizontal positioning within a generation:**

1. Group nodes by generation level
2. Within each generation, cluster by shared parent edge
3. Within each cluster, place spouses side-by-side
4. Space clusters with a gap wider than intra-cluster spacing
5. Center each generation row relative to the widest row

**Node sizing:** Fixed base size 70x90 (avatar circle + name + label). Connection lines route between node centers. Layout produces `Map<String, Offset>` for every node.

**Viewport:** `InteractiveViewer` wraps `CustomPaint`. Pinch to zoom, drag to pan. Initial viewport centers on the user node, zoomed to fit 2 generations.

---

## Section 2: Connection Lines

Actual graph edges drawn as bezier curves, not hardcoded gradient rectangles.

**Edge type visual styles:**

| Edge Type | Style | Color | Path |
|-----------|-------|-------|------|
| `parentOf` | Solid curved line | Primary green gradient | Cubic bezier, parent bottom → child top |
| `spouseOf` | Short horizontal + ring icon | Gold gradient | Left/right between adjacent nodes |
| `siblingOf` | Bracket connector | Light green, thin | Horizontal bar above group + vertical drops |

**Drawing order:** Lines paint first (behind nodes). Painter iterates all edges, maps `fromId`/`toId` to computed positions, draws appropriate bezier path.

**Line animation on load:** Lines draw progressively using `PathMetric` — starting from user node outward, 1-second staggered. Closer relatives first. Creates the tree "growing" from you.

**Interaction state on lines:**
- 14+ days no contact → dashed stroke
- Active streak → subtle glow (shadow paint with blur)
- The line itself communicates health

---

## Section 3: Node Rendering

Every node drawn on canvas — no Flutter widgets in the tree itself.

**Node anatomy (per node):**

1. **Circle background** — 60px diameter. Fill color by interaction health:
   - Green: contacted within expected frequency
   - Amber: 50-100% overdue
   - Red: 100%+ overdue
   - Blue ring: the user node
2. **Emoji avatar** — centered in circle via `TextPainter` with emoji font
3. **Name text** — below circle, max 1 line truncated, white, centered, Arabic font
4. **Relationship label** — below name, smaller, semi-transparent. Uses `FamilyGraphService.getLabelForViewer()` — shows "عمي" not "عم/خال"
5. **Streak fire** — small "🔥" + count drawn top-right if active streak
6. **Pulse ring** — 14+ days overdue nodes get animated expanding/fading ring (red tint, 2s repeat)

**Text rendering:** All `TextPainter` instances use `TextDirection.rtl` and the app's Arabic font family.

---

## Section 4: Living Animations

Continuous subtle animations so the tree never feels static.

**Breathing:** Slow scale oscillation on nodes, 0.98x→1.02x over 3 seconds. Each node's phase offset by generation level — they don't pulse in sync.

**Attention pulse:** Overdue nodes (14+ days) get an expanding ring, 60px→80px radius, fading 0.3→0 opacity. Red tint, repeats every 2 seconds. The tree tells you who needs attention.

**New contact celebration:** After logging an interaction and returning to tree, the node scales 1.0→1.3→1.0 with a green flash. Connection line glows. One-shot, 600ms.

**Growth on first load:** Nodes appear generation-by-generation from user outward. User at 100ms, parents at 300ms, grandparents+siblings at 500ms, extended at 700ms. Fade in + scale 0.5→1.0 with elastic easing. Lines draw simultaneously via `PathMetric`.

**Performance:** Single `AnimationController` at 60fps. Painter reads `controller.value`, computes per-node phase offsets. No widget rebuilds — just `CustomPainter.repaint` via `Listenable`.

---

## Section 5: Data Flow

No new backend work. Everything uses existing infrastructure.

**Data sources (all existing):**
- `familyEdgesStreamProvider(userId)` → `List<FamilyEdge>` (real-time stream)
- `relativesStreamProvider(userId)` → `List<Relative>` (last contact, streaks, priority)
- `familyGraphProvider(userId)` → `FamilyGraph` from edges

**New computation layer — `FamilyTreeLayoutService`:**
- Pure static, no dependencies
- Input: `FamilyGraph` + `List<Relative>` + canvas `Size`
- Output: `FamilyTreeLayout` data class:
  - `Map<String, Offset> nodePositions`
  - `List<LayoutEdge> edges` (type + from/to positions)
  - `Map<String, String> labels` (pre-computed from `getLabelForViewer()`)
  - `Rect bounds` (total tree bounds for InteractiveViewer)
- Recomputes only when relatives or edges change (provider-level caching)

**The painter reads, never computes.** `FamilyTreePainter` receives layout data + relative health data + animation value. All it does is draw.

**Empty graph fallback:** If `familyGraphProvider` returns null (no edges yet), `FamilyTreeLayoutService` infers edges on-the-fly using `FamilyGraphService.inferEdges()` from relationship types. The tree always renders with graph intelligence.

---

## Section 6: Tap Interaction & Detail Overlay

Canvas for the tree, real Flutter widgets for interactions.

**Hit testing:** `GestureDetector` wraps `CustomPaint`. On tap, convert local position to canvas coordinates (accounting for InteractiveViewer transform). Check distance to each node center — if within 40px, that node was tapped.

**Detail overlay:** `OverlayEntry` anchored near the tapped node's screen position. A compact card with:
- Emoji + full name + graph-aware label
- Last contact: "قبل ٣ أيام" with appropriate color
- Streak indicator if active
- Two action buttons: phone (direct call) + profile (navigate to detail)
- Small triangle pointer toward the tapped node
- Tap outside dismisses

**Long press:** Haptic feedback + highlight connected subgraph. Dims unconnected nodes to 0.3 opacity. Shows who this person connects to in the family. Release to restore.

---

## Section 7: Edge Cases

**Single relative (1-2 nodes):** Centered on canvas, connection to user. No empty state needed — `FamilyTreeGapCard` on home screen already prompts to add more.

**Large families (30+ nodes):** Layout computes bounds dynamically. InteractiveViewer allows full pan. Initial viewport fits 2 generations around user. Minimap in corner (small semi-transparent overview with viewport rectangle) for orientation.

**Orphan nodes (no edges):** Relatives with no edges placed in "unconnected" cluster at bottom. Dashed circle instead of solid — visual cue they're not linked.

**Arabic text overflow:** `TextPainter` with `maxLines: 1`, `ellipsis: '...'`. Full name in tap overlay.

**Performance:** Single `AnimationController`, `repaint` via `Listenable`. For 50+ nodes: circle draws + text paints only — no layout per frame.

**Premium gating:** Same existing behavior — free users see blur overlay + upgrade prompt.

---

## Files

| Action | File |
|--------|------|
| Create | `lib/features/family_tree/services/family_tree_layout_service.dart` |
| Create | `lib/features/family_tree/painters/family_tree_painter.dart` |
| Rewrite | `lib/features/family_tree/screens/family_tree_screen.dart` |
| Keep | `lib/features/family_tree/models/family_graph.dart` |
| Keep | `lib/features/family_tree/services/family_graph_service.dart` |
| Keep | `lib/features/family_tree/providers/family_graph_providers.dart` |
| Evaluate | `lib/features/family_tree/widgets/tree_node_widget.dart` (may delete if fully canvas) |
| Evaluate | `lib/features/family_tree/models/tree_node.dart` (replace with layout data class) |

---

## Testing

**Unit tests** (`test/unit/services/family_tree_layout_service_test.dart`):
- Generation assignment matches graph BFS
- Spouse nodes adjacent horizontally
- Clusters grouped by shared parent
- 30+ nodes computes without error
- Empty graph fallback infers edges
- Node health status from last contact + expected frequency

**Widget tests** (`test/widget/family_tree/family_tree_screen_test.dart`):
- Correct node count rendered
- Tap triggers detail overlay with graph-aware label
- Overlay dismisses on outside tap
- InteractiveViewer responds to gestures
- Premium gate shows blur for free users

**Golden tests** (`test/golden/family_tree/`):
- Small family (2 parents + user)
- Medium family (parents, grandparents, 3 siblings, 2 uncles)
- Update with `make update-goldens`

**Manual testing:**
- Arabic RTL text renders correctly on canvas
- Emoji display at correct size across devices
- 60fps on older devices
- Long-press highlight works
- Overlay doesn't clip at screen edges
