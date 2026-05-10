# Phase β.fix — Three rendering bugs from real-device test

**Date:** 2026-05-01
**Source of report:** Founder real-device session after Phase β

Four targeted fixes. No structural rewrites.

---

## Bug 1 — Composer opaque white background

### Root cause (surprising)

The β3 composer DID have the BackdropFilter and translucent fill in place ([ai_chat_screen.dart:_buildGlassComposer](lib/features/ai_assistant/screens/ai_chat_screen.dart) — `themeColors.surface.withValues(alpha: 0.7)`, ClipRRect-wrapped, sigmaX/sigmaY 20). The glass was rendering correctly UNDER the composer's own decoration.

The opacity was being painted OVER by the `TextField` inside it. Material's global `InputDecorationTheme` ([app_theme.dart:89-91](lib/core/theme/app_theme.dart#L89-L91), [:242-244](lib/core/theme/app_theme.dart#L242-L244), [:385-387](lib/core/theme/app_theme.dart#L385-L387)) sets:

```dart
inputDecorationTheme: InputDecorationTheme(
  filled: true,
  fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
  ...
),
```

Every `TextField` that doesn't explicitly opt out inherits `filled: true` + an opaque fill color. The composer's `InputDecoration` had `border: InputBorder.none` etc. but did NOT override `filled`/`fillColor` — so it inherited the global theme and painted an opaque fill (white in light theme, dark grey in dark theme) inside the BackdropFilter, visually obliterating the blur.

### Fix

[ai_chat_screen.dart:561-565](lib/features/ai_assistant/screens/ai_chat_screen.dart#L561-L565) — added explicit opt-out:

```dart
filled: false,
fillColor: Colors.transparent,
...
disabledBorder: InputBorder.none,
```

Now the TextField is fully transparent and the BackdropFilter's blur shows through. Verified: 0 analyzer issues; tests pass.

### Surprising

This bug was invisible in unit/golden tests because golden tests use ad-hoc themes without the global `InputDecorationTheme`. It only manifested on real device with the production theme applied. Lesson: any glass composer with TextField inside MUST opt out of `InputDecorationTheme` defaults explicitly.

---

## Bug 2 — Send icon: 180° rotation flipped vertically

### Root cause

[ai_chat_screen.dart:_ComposerSendButton](lib/features/ai_assistant/screens/ai_chat_screen.dart) had:

```dart
child: Transform.rotate(
  angle: 3.14159, // RTL — flip the send glyph horizontally.
  child: Icon(Icons.send_rounded, ...),
),
```

`Transform.rotate(angle: π)` is a 180° rotation around the icon's center — which flips both horizontally AND vertically. For a paper-airplane icon pointing right (→), this produces an arrow pointing left (←) but **upside down**: the wing curvature is inverted, the nose-cone is at the bottom-right instead of top-left. Reads as a malformed/wrong send icon.

### Fix

[ai_chat_screen.dart:845-855](lib/features/ai_assistant/screens/ai_chat_screen.dart) — replaced `Transform.rotate(angle: 3.14159)` with `Transform.flip(flipX: true)`:

```dart
child: Transform.flip(
  flipX: true,
  child: Icon(
    Icons.send_rounded,
    ...
  ),
),
```

`Transform.flip(flipX: true)` is a horizontal mirror only — preserves the icon's vertical orientation. Result: arrow points left (←), wings curve correctly, nose-cone at top-left.

### Send icon decision

Sticking with `Icons.send_rounded` from Material (CTO option A — quick win). Reasons:
- Already shipping; consistent with Flutter's RTL system that other apps recognize
- Custom SVG can be a v1.1 design upgrade without changing the placement architecture
- The `_rounded` suffix already softens the Material default (`Icons.send` outline) per the CTO note

### Send icon placement

Per CTO clarification, send icon stays at the **end of the Row in RTL = physical LEFT edge** of the composer. Matches WhatsApp/Telegram/iMessage Arabic conventions. No placement change.

---

## Bug 3 — AI accent line cutouts

### Root cause

Three places in [conversation_message.dart](lib/features/ai_assistant/widgets/conversation_message.dart) (`_AIMessageContent`, `StreamingMessage`, `TypingIndicator`) all used the same Stack pattern:

```dart
Stack(
  children: [
    Positioned(
      left: 0,
      top: 4,        // <-- 4px CUTOUT at top edge
      bottom: 4,     // <-- 4px CUTOUT at bottom edge
      child: Container(
        width: 2,
        decoration: BoxDecoration(
          color: accent,
          boxShadow: [BoxShadow(blurRadius: 8, ...)],
        ),
      ),
    ),
    ...
  ],
)
```

Two distinct issues:
1. `top: 4, bottom: 4` deliberately created a 4px gap at each end of the line (an early stylistic choice). This produced visible cutouts — the line didn't reach the message's top/bottom edges.
2. Even with the line reaching the bounds, the `BoxShadow(blurRadius: 8)` glow extends 8px outward — and Stack's default `clipBehavior: Clip.hardEdge` was clipping it at the message bounds, breaking the soft glow into a hard rectangle.

### Fix (CTO Pattern A — Stack with PositionedDirectional)

Applied to all 3 widgets ([conversation_message.dart:_AIMessageContent](lib/features/ai_assistant/widgets/conversation_message.dart), `StreamingMessage`, `TypingIndicator`):

1. Set `Positioned.top: 0, bottom: 0` so the line is continuous from the message's full top to bottom edges.
2. Set `Stack(clipBehavior: Clip.none, ...)` so the 8px glow can bleed past the message bounds without being clipped.

```dart
Stack(
  clipBehavior: Clip.none,        // β.fix#3 — let glow extend beyond bounds
  children: [
    Positioned(
      left: 0,
      top: 0,                      // β.fix#3 — was 4
      bottom: 0,                   // β.fix#3 — was 4
      child: Container(...),
    ),
    ...
  ],
)
```

### Pattern choice rationale

Picked **Pattern A (Stack with Positioned)** over Pattern B (CustomPaint):

- I was already using Pattern A in β2; the bug was specific values within it (top/bottom margins + clipBehavior), not the pattern itself
- Pattern A is more declarative — easier for any reader to reason about
- CustomPaint would offer more glow control (gradient stops, varying width) but isn't needed for v1
- Smaller diff = lower risk

If the founder later wants a non-uniform glow (e.g., brighter at the message vertical center, fading at the ends), promoting to Pattern B is straightforward.

### Note on `PositionedDirectional`

CTO suggested `PositionedDirectional(start: 0, ...)`. I kept `Positioned(left: 0, ...)` to match the β2 design decision (accent line on physical left edge regardless of read direction). Switching to `PositionedDirectional(start: 0)` would put the line on the reading-start side (right in RTL) — a different design choice. Flagged in β report's open question #1; awaiting founder verdict on real device. If founder wants RTL-start, it's a one-line swap.

---

## Bug 4 — MessageActionsRow cleanup

[lib/features/ai_assistant/widgets/message_actions.dart](lib/features/ai_assistant/widgets/message_actions.dart) — **deleted entirely.**

Verified before deletion (no call sites in `lib/` or `test/`):
- `MessageActionsRow` — 0 references outside the file itself
- `CopyCodeButton` — 0 references outside the file itself

Both were dead since β5 replaced the persistent action row with the long-press `MessageActionSheet`. `CopyCodeButton` was hypothetically reusable for future code-block surfacing but had never been wired up — flagged in β report's open question #7 as "leaving for cleanup PR." Promoted to this fix-pass since the file was already touched.

Directory after cleanup ([lib/features/ai_assistant/widgets/](lib/features/ai_assistant/widgets/)):

```
ai_error_card.dart
ai_loading_indicator.dart
chat_history_drawer.dart
chat_message_bubble.dart       ← still has dead ChatMessageBubble + CounselingModeCard (out of scope here)
conversation_message.dart
health_badge.dart
markdown_styles.dart
memory_indicator.dart
message_action_sheet.dart
persona_greeting_block.dart
```

---

## Verification

| Check | Result |
|---|---|
| `flutter analyze lib/` | **0 issues** |
| `flutter test test/unit/` | **1040/1040 passing** |
| `flutter test test/golden/` | **8/8 passing** |
| Real-device founder retest | 🟡 pending |

---

## Surprising findings

1. **The composer "opaque white" wasn't a BackdropFilter problem at all.** It was a TextField fill paint on top of the BackdropFilter. The glass infrastructure I built in β3 was correct; the inherited Material theme overrode the inner TextField. This kind of bug hides extremely well in unit/golden tests because golden tests don't typically apply the production `InputDecorationTheme`.

2. **`Transform.rotate(angle: π)` is the wrong tool for "flip horizontally"** even though it visually appears similar at first glance. The 180° rotation flips BOTH axes — an arrow paper-airplane comes out left-pointing AND upside-down. The wing curvature inversion is the giveaway. `Transform.flip(flipX: true)` is the correct primitive. I used the rotation in β3 thinking it was a horizontal flip; founder spotted the wrong-icon symptom on real device.

3. **Stack clips by default.** I knew `Stack(clipBehavior: Clip.none)` exists but assumed unbounded children would render past bounds without it. They don't. The 8px glow was being silently clipped at the message bounds in β2 even on simulator — but it's a subtle 8px gradient that's easy to miss until you're staring at a real device with finger-zoom.

---

## Open questions for the CTO

1. **Bug 3 — physical left vs RTL-start for the accent line.** Currently physical left (β2 design choice). β report's question #1 is still open. Real-device verification of this fix should reveal whether the founder's eye reads the left-edge line as the AI's "voice marker" or as a "wrong-side accent." If the latter, a one-line swap to `PositionedDirectional(start: 0, ...)` flips it to the reading-start side (right in RTL).

2. **Bug 1 follow-up — should we set `filled: false` globally for the AI chat surface or per-TextField?** Currently fixed per-TextField (only the composer). The edit dialog ([ai_chat_screen.dart:_showEditDialog](lib/features/ai_assistant/screens/ai_chat_screen.dart)) has its own `TextField` with `fillColor: Colors.black.withValues(alpha: 0.3)` — explicitly overriding, so it's safe. But if any future TextField is added to the chat surface and forgets to opt out, the bug would resurface. Worth a project-wide convention or a `GlassTextField` wrapper widget. Flagging for Phase γ.

3. **Bug 4 — cleanup of remaining dead code in `chat_message_bubble.dart`.** This file still contains `ChatMessageBubble` (unused) and `CounselingModeCard` (unused). Only `SuggestedPromptChip` is alive (used by the β3 composer suggested-prompt row). Could split: keep `SuggestedPromptChip` here or move to a dedicated `suggested_prompt_chip.dart`, then delete the rest. Out of scope for β.fix; flagging for a future cleanup pass.

4. **Send icon — promote to custom SVG?** The `Icons.send_rounded` works but reads as Material. A custom paper-airplane SVG sized to match the composer's accent color would feel more product-distinctive. Not blocking.

---

## Files touched

```
EDIT  lib/features/ai_assistant/screens/ai_chat_screen.dart            Bug 1 + Bug 2
EDIT  lib/features/ai_assistant/widgets/conversation_message.dart      Bug 3 (×3 sites)
DEL   lib/features/ai_assistant/widgets/message_actions.dart           Bug 4 (whole file)
```

3 files, ~30 net lines changed (mostly value tweaks: `top: 4` → `top: 0`, `Transform.rotate` → `Transform.flip`, `filled: true (inherited)` → `filled: false`).

---

## Verification request

@founder — please retest on real device. Specifically:

1. **Open the chat surface.** Composer at the bottom should now show the gradient pattern blurred behind it (glass-frosted), NOT opaque white.
2. **Look at the send icon.** The arrow should be a clean paper-airplane pointing LEFT (`←`) with the wing curvature pointing toward the upper-left — NOT upside-down or otherwise misshapen. Position is on the LEFT edge of the composer in RTL (start of the row, end of read direction).
3. **Send a prompt and look at the AI response.** The 2px theme-accent vertical line on the left should be CONTINUOUS from top to bottom of the message, with a SOFT GLOW that bleeds slightly past the message edges (not chopped off at the corners).
4. **Verify across 2-3 themes.** All three fixes are theme-aware — accent color, surface tint, and glow color all read from `themeColors`.

If this passes, β.fix is closed. Phase γ (AI prompt engineering overhaul) is next per CTO note.
