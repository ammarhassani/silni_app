# Phase α — AI chat surface fixes

**Date:** 2026-05-01
**Source of report:** Founder real-device session in AI chat

Four issues. Four targeted fixes. No structural rewrites.

---

## α1 — RTL list wrap

### Symptom
Bold list-item heading lands flush right, but wrap continuation drifts to the left side, breaking the visual right-edge rhythm.

### Root cause
Single line in [lib/features/ai_assistant/widgets/markdown_styles.dart:142](lib/features/ai_assistant/widgets/markdown_styles.dart#L142):

```dart
textAlign: WrapAlignment.end,
```

`flutter_markdown` maps `WrapAlignment.end` → `TextAlign.end`. Inside an RTL `Directionality`, `TextAlign.end` resolves to **left**-aligned. So every wrap was being explicitly aligned to the wrong edge.

The default for `WrapAlignment` in flutter_markdown is `WrapAlignment.start` → `TextAlign.start` → in RTL = **right**-aligned. That's the correct value for Arabic content. The `WrapAlignment.end` override was the bug.

### Fix
Change `WrapAlignment.end` → `WrapAlignment.start`. Also explicitly set the per-block alignment fields (`h1Align…h6Align`, `unorderedListAlign`, `orderedListAlign`, `blockquoteAlign`) all to `start` so future block additions to the stylesheet don't accidentally inherit the wrong default.

```dart
// markdown_styles.dart:142-152
textAlign: WrapAlignment.start,
h1Align: WrapAlignment.start,
h2Align: WrapAlignment.start,
h3Align: WrapAlignment.start,
h4Align: WrapAlignment.start,
h5Align: WrapAlignment.start,
h6Align: WrapAlignment.start,
unorderedListAlign: WrapAlignment.start,
orderedListAlign: WrapAlignment.start,
blockquoteAlign: WrapAlignment.start,
```

### Surprising
The fix is not a wrapping issue at all — it's an explicit-misalignment issue. The wrap renderer was actually doing exactly what it was told. The misleading thing about the symptom was that "first line lands at the right but wraps drift left" reads as "wrap engine is broken in RTL." But `TextAlign.end` does *exactly* this when first lines fit and continuations don't. Our markdown styler was telling the renderer "align all this text to the end of the read direction (i.e., the left in RTL)" — and it dutifully did.

Verification: any prompt producing a multi-line list item should now have continuation lines flush right.

---

## α2 — Action chip spacing

### Symptom
Two-chip cluster (نسخ + تعديل / نسخ + إعادة) reads as too-spread.

### Code state (pre-fix)
[lib/features/ai_assistant/widgets/message_actions.dart](lib/features/ai_assistant/widgets/message_actions.dart) — the row was already using `mainAxisSize.min` so no `spaceBetween`/`spaceEvenly` to tighten. The visible looseness came from:
- `SizedBox(width: AppSpacing.sm)` between chips (= 8px)
- Each `_ActionButton` had horizontal padding `AppSpacing.sm` (= 8px) — so the gap between adjacent chip *icons* was effectively 8 + 8 + 8 = 24px

### Fix
- Inter-chip `SizedBox` → `AppSpacing.xs` (4px)
- `_ActionButton` horizontal padding → `AppSpacing.xs` (4px)

Effective center-to-center gap is now ~12px instead of ~24px. Vertical padding kept at `xs` (4) to preserve tap area.

---

## α3 — Header chrome

### Symptom
History + new-chat icon buttons appear to float in AppBar dead space, separated from each other.

### Fix
Replaced the two separate `GlassIconButton` actions with a single segmented glass-pill cluster ([ai_chat_screen.dart:780+](lib/features/ai_assistant/screens/ai_chat_screen.dart#L780)):

```
[ history | new-chat ]   ← single capsule, divider in the middle
```

Two private widgets at file scope:

- `_ChatHeaderControlCluster` — pill shell (theme-on-gradient tint, glass border)
- `_ClusterButton` — internal segment (Material+InkWell, no ring, just an icon padded inside the parent capsule)

This reads as one paired control, not two free-floating dots.

---

## α4 — Chat history drawer

### Symptoms
- Material grey scrim
- Solid `islamicGreenDark` drawer body — not theme-aware
- Material `IconButton` ripples on close + delete
- Custom-bordered new-chat button instead of the app's `GradientButton`

### Fixes (chat_history_drawer.dart)

| Surface | Before | After |
|---|---|---|
| Drawer scrim | Material default grey | `Colors.black.withValues(alpha: 0.55)` set on the chat screen's `Scaffold.drawerScrimColor` |
| Drawer body bg | `color: AppColors.islamicGreenDark` (fixed) | Theme-aware `LinearGradient([primaryDark, primary])` — adapts to all 6 themes |
| Drawer left edge | `alpha: 0.1` divider | `alpha: 0.18` divider |
| Header avatar | flat green circle | gradient circle with primary glow shadow |
| Header title | titleMedium | titleLarge with body subtitle (proper hierarchy) |
| Close button | `IconButton` (Material ripple) | glass-circle InkWell, matches the pattern used in `GlassIconButton` |
| New-chat button | custom InkWell+border `islamicGreenLight` text | `GradientButton` with theme-aware gradient |
| Tile background | `islamicGreenPrimary` selected tint | Theme-aware: subtle white-glass for unselected, accent-bordered for selected |
| Tile selected fontWeight | `w600` | `w700` (more visible) |
| Mode icon | `islamicGreenLight` flat | Theme accent + accent-bordered squircle |
| Delete glyph | `IconButton` (Material ripple) | glass-circle InkWell |

The drawer now adapts to whatever theme the user has active (green / lavender / royal blue / sunset / rose / midnight) — no more fixed Islamic-green-dark surface that clashes with non-default themes.

---

## Verification

| Check | Result |
|---|---|
| `flutter analyze lib/` | 0 issues |
| `flutter test test/unit/` | 1040/1040 passing |
| `flutter test test/golden/` | 8/8 passing |
| Real-device founder retest | 🟡 pending |

No golden test failures — the AI chat surface doesn't have golden coverage at the message-rendering level (only `GlassCard` / `DramaticGlassCard` are covered in `test/golden/widgets/`).

---

## Surprising findings

1. **α1 was a misalignment, not a wrap-engine bug.** The styler was *explicitly* telling the renderer to align text to the "end" of the read direction, which in RTL is the left. The wrap was working correctly all along — it was being told to align lines to the wrong edge. This kind of bug hides extremely well because the override looks intentional ("align RTL text… to the end? sure, that sounds right"), and only one test case (multi-line list items) exposes it.

2. **α2's "spaced too far apart" was a mismatch between perceived tightness and actual measurements.** The cluster was already `mainAxisSize.min` with `sm` (8px) gaps. The complaint mapped to "padding-on-padding-on-padding" stacking — the chip body was 8px-padded, the gap was 8px, and the chip body was 8px-padded again. Total perceived gap was ~24px between adjacent icons, which reads as loose for a two-icon cluster. Cutting both to `xs` (4) brings it to ~12px, which reads as a paired chip instead of two floating chips.

3. **The drawer was hardcoded to `islamicGreenDark`** even though the project has 6 themes. Anyone on the lavender/orange/midnight themes was seeing a green panel slide in — visually wrong but never reported, probably because most users haven't switched themes (founder mostly tested on default green, where the old hardcoding happened to match).

---

## Open questions for the CTO

1. **α2 — should chip vertical padding also drop to 0?** I kept `vertical: xs` (4px) for tap area. If accessibility allows, it could drop to 2px for an even tighter cluster. WCAG 2.0 AA wants 44×44 tap targets but the chip cluster is small inline action UI; current effective tap area is roughly 28×24. Worth a real-device touch-test to decide.

2. **α3 — the cluster pill is two icons.** If you ever add a third action (e.g., "share conversation"), the segmented divider pattern scales but the pill width grows. Discuss UX before adding.

3. **α4 — the drawer's section headers (اليوم / أمس / الأسبوع / أقدم) are still small `labelSmall` with `Colors.white54`.** They're functional but could use a small tier-styled chip treatment for stronger group anchoring. Not in scope here; flagged for Phase β.

4. **Phase β scope.** Founder's real-device test will surface whatever this round didn't catch. Likely candidates: streaming render perf, code-block rendering, table rendering on narrow viewports, scroll-to-bottom button. Triage with founder when ready.

---

## Files touched

```
lib/features/ai_assistant/widgets/markdown_styles.dart        α1
lib/features/ai_assistant/widgets/message_actions.dart        α2
lib/features/ai_assistant/screens/ai_chat_screen.dart         α3 + scrim
lib/features/ai_assistant/widgets/chat_history_drawer.dart    α4
```

@founder — please retest on real device. Specifically:

- Send a prompt that returns a numbered list with multi-line items → verify wrap aligns flush right
- Look at the chip cluster under a message → verify chips read as paired, not spread
- Look at the AppBar → history + new-chat should appear as one segmented pill in the right corner
- Open the chat history drawer → backdrop should dim with a deep glass tint (not Material grey); drawer surface should adopt the active theme; new-chat button should be a gradient pill; selected conversation should have a theme-accent border

If this passes, Phase α is closed. Phase β is a separate session.
