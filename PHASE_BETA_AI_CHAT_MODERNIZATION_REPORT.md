# Phase β — AI chat surface modernization

**Date:** 2026-05-01
**Source of brief:** CTO design pass (locked decisions)

Letter-paradigm rebuild of the AI chat surface across 9 tasks. Theme-aware throughout. No structural rewrites of state/data layers.

---

## β1 — Persona greeting block

**File:** [lib/features/ai_assistant/widgets/persona_greeting_block.dart](lib/features/ai_assistant/widgets/persona_greeting_block.dart) (new)

40px gradient avatar circle + theme-accent name (18px bold) + mode subtitle (13px white@0.6) + 1px white@0.1 hairline divider. Sits as item 0 in the conversation `ListView` so it scrolls with content (no sticky-pin per spec). Wired in [ai_chat_screen.dart:_buildMessagesList](lib/features/ai_assistant/screens/ai_chat_screen.dart) — index 0 is the greeting block, index ≥1 is the message stream, trailing slot is the typing/streaming indicator.

The previous elaborate empty state (3-layer halo avatar + welcome text + suggested-prompt grid) was deleted — its responsibilities split between β1 (persona block) and β3 (suggested-prompt chip row above composer).

---

## β2 — Message rendering rebuild

**File:** [lib/features/ai_assistant/widgets/conversation_message.dart](lib/features/ai_assistant/widgets/conversation_message.dart) (rewritten)

### `_UserMessageBubble`
- `Align(AlignmentDirectional.centerStart)` — bubble lives on the reading-start side (right edge in RTL).
- Max width: 80% of screen.
- Fill: `themeColors.primary` at 12% opacity.
- Border: 1px `themeColors.accent` at 30% opacity.
- Asymmetric corners via `BorderRadiusDirectional`: 16px on three corners, **4px** on `bottomStart` (the anchor corner closest to the screen edge in RTL = bottom-right physically).
- Body: `SelectableText`, 16px, line-height 1.6.

### `_AIMessageContent`
- Full conversation width minus 24px horizontal padding.
- No bubble — `Stack`-based layout with the markdown body padded 24px from a positioned 2px-wide vertical accent bar on the **physical left edge**.
- Accent bar: `accent @ 40% opacity` core with `BoxShadow(blurRadius: 8, accent @ 30% opacity)` — the soft glow is the AI's visual signature in lieu of an avatar.
- Markdown body uses [markdown_styles.dart](lib/features/ai_assistant/widgets/markdown_styles.dart) (β6 below).
- 32px (`AppSpacing.xl`) bottom padding between turns per the "generous whitespace" decision.

### Behavioral note
RTL semantic — for the AI accent line, the spec was explicit that the line lives on the *physical* left edge. For an Arabic reader the line marks the column's left margin (where the eye exits each line); for a designer who wrote the spec in LTR-thinking, "left edge" was the natural shorthand. I went with the literal interpretation since the spec was explicit.

---

## β5 — Long-press action sheet

**File:** [lib/features/ai_assistant/widgets/message_action_sheet.dart](lib/features/ai_assistant/widgets/message_action_sheet.dart) (new)

Replaces the persistent inline `MessageActionsRow` (Phase α2) entirely. Long-press on a message → light haptic + bottom sheet with theme-aware glass surface (`BackdropFilter(blur 20)` + `themeColors.background2 @ 85% opacity` + `Colors.white @ 18%` border).

Action set:
- **User messages:** نسخ, تعديل (when `onEdit` is bound), إعادة توليد الرد (when `onRegenerate` is bound — surfaced when this is the most recent user turn so its AI response can be regenerated).
- **AI messages:** نسخ, إعادة (when this is the last message + `onRegenerate` is bound), إبلاغ (placeholder — fires a "شكرًا للملاحظة" snackbar; no telemetry/persistence yet).

Long-press wired in [conversation_message.dart:_onLongPress](lib/features/ai_assistant/widgets/conversation_message.dart). Uses `GestureDetector(onLongPress:)` with `behavior: HitTestBehavior.opaque` so the gesture is reliably picked up over text and bubble surfaces alike. iOS-specific timing: GestureDetector's default ~500ms long-press threshold is what's used; should feel native on iOS.

`MessageActionsRow` widget in [message_actions.dart](lib/features/ai_assistant/widgets/message_actions.dart) is now dead code (kept the file because `CopyCodeButton` may still be useful for future code-block treatment; flagged for future cleanup).

---

## β3 — Composer rebuild

**File:** [lib/features/ai_assistant/screens/ai_chat_screen.dart:_buildInputArea + _buildGlassComposer + _ComposerSendButton](lib/features/ai_assistant/screens/ai_chat_screen.dart)

### Glass-pill composer
- `BackdropFilter(ImageFilter.blur(sigmaX: 20, sigmaY: 20))`.
- Fill: `themeColors.surface @ 70% opacity`.
- Border: 1px `Colors.white @ 15% opacity`.
- Radius: 24 (pill).
- Min height 48; `TextField` with `maxLines: 5` so prose grows to ~5 lines before internal scrolling.
- Hint: "اسأل {AIIdentity.name}..." at white@0.4.

### `_ComposerSendButton`
- Embedded inside the composer at the row's end (physical left in RTL — start is text input).
- 36×36 circle.
- Disabled state: outlined only (1.2px `accent @ 35%`, transparent fill, glyph at `textOnGradient @ 45%`, scale 0.9).
- Enabled state: gradient `[primary, primaryLight]` fill + `BoxShadow(blurRadius: 12, primary @ 45%)`, glyph at full `textOnGradient`, scale 1.0.
- On enable: `AnimatedScale` springs from 0.9 → 1.0 over 200ms with `Curves.easeOutBack` per spec.
- On press: scales to 0.92 (200ms) then back via release.

### Empty-conversation suggested-prompt chips
- Above the composer when `chatState.messages.isEmpty && !streaming && !loading && !hasComposerText`.
- Source: `suggestedPromptsProvider` (admin config with hardcoded fallback). Take(3).
- Chip widget: existing `SuggestedPromptChip` from [chat_message_bubble.dart](lib/features/ai_assistant/widgets/chat_message_bubble.dart).
- Tapping fills + sends.
- Fade out: `AnimatedSwitcher` with `AppAnimations.normal` (200ms) when `_hasComposerText` flips true (a `_messageController` listener tracks composer state).

### Composer text-state listener
Added `_hasComposerText` bool to `_AIChatScreenState`, listener on `_messageController.addListener(_onComposerChanged)`, dispatched on text changes. Drives both the send button's enabled/disabled state and the prompt-chip-row visibility.

---

## β6 — Rich content rendering

**File:** [lib/features/ai_assistant/widgets/markdown_styles.dart](lib/features/ai_assistant/widgets/markdown_styles.dart) (signature change — now takes `themeColors`)

- **Pull-quote treatment for blockquotes** — the AI primarily uses blockquotes for scripture (hadiths, Quranic citations). I judged content-based detection (regex on `قال رسول الله ﷺ` / `قال الله تعالى`) too brittle for v1, since `flutter_markdown` doesn't expose per-block decoration based on content without a custom `MarkdownElementBuilder`. **Decision: all blockquotes adopt the reverent treatment** — 5% accent surface, 3px right-edge accent border (RTL-correct quote bar at reading-start), italic body, larger line-height (1.7), full white body color. This is acceptable because the AI's blockquote usage in this app is heavily skewed toward scripture; non-scripture quotes (rare) inherit a worthy, not gaudy, treatment.
- **Inline code:** `accent` foreground on `Colors.black @ 30%` background — theme-aware.
- **Code blocks:** 1px `accent @ 20%` border on `Colors.white @ 5%` surface; 12px padding; FiraCode monospace via google_fonts. Theme-aware accent.
- **Bullet glyph + checkbox + link color** all switched from hardcoded `AppColors.islamicGreenLight` to `themeColors.accent`.

### Inline relative-name highlighting — DEFERRED
The spec's nice-to-have (highlight relative names mentioned by the AI) requires either pre-processing the markdown to wrap names in spans the parser would honor, or a custom `MarkdownElementBuilder` that segments paragraph text. Both were judged out-of-scope for this session per the spec's own guidance ("If implementation is fiddly with the markdown package, halt and report — we can defer to a follow-up.").

### Affected callers
- [conversation_message.dart](lib/features/ai_assistant/widgets/conversation_message.dart) — `buildChatMarkdownStyle(context, themeColors)` and `buildStreamingMarkdownStyle(context, themeColors)`.
- [weekly_report_screen.dart:481](lib/features/ai_assistant/screens/weekly_report_screen.dart#L481) and [:921](lib/features/ai_assistant/screens/weekly_report_screen.dart#L921) — `buildCardMarkdownStyle(context, themeColors)`.

---

## β7 — Conversation history refinements

**File:** [lib/features/ai_assistant/widgets/chat_history_drawer.dart](lib/features/ai_assistant/widgets/chat_history_drawer.dart)

### Chip section headers
`اليوم / أمس / هذا الأسبوع / أقدم` are now small theme-accent pills:
- Fill: `accent @ 12%`, border: 1px `accent @ 50%`, radius `radiusRound`.
- Text: 11px, w700, letter-spacing 0.2, accent color.
- Aligned to `AlignmentDirectional.centerStart` so they hang on the reading-start side (right in RTL).

### Most-recent emphasis
The single most recent conversation across all sections (today → yesterday → week → older — first non-empty section) gets:
- Slightly larger padding: `AppSpacing.sm + 2` (acts as a visual ~1.1× scale without breaking the layout grid).
- Title font size 15 vs 14, weight `w700` vs `w500`.
- Border: `accent @ 60%` width 1.2 vs default `Colors.white @ 12%` width 1.
- Soft glow: `BoxShadow(blurRadius: 12, accent @ 18%)`.
- Tile background: `Colors.white @ 8%` vs default `4%`.

### New-chat button repositioning
Moved from the top of the drawer to a fixed-bottom `Positioned(bottom: 0)` overlay inside a `Stack`. Underneath the button is a 24px gradient mask (transparent → `themeColors.primary @ 85%`) so list content fades behind the floating button while scrolling. The conversation `ListView` has 80px bottom padding so its last item never sits beneath the button.

### Helper signature changes
`_buildSectionHeader` now takes `themeColors`. `_buildConversationTile` takes a new `bool isMostRecent` flag. The list builder picks the most-recent ID up front and passes it to the tile builder.

---

## β8 — Header refinement

**File:** [lib/features/ai_assistant/screens/ai_chat_screen.dart:_buildAppBar](lib/features/ai_assistant/screens/ai_chat_screen.dart)

`AppBar` is now minimal: transparent background, elevation 0, default 56px toolbar height, empty title slot (`SizedBox.shrink()`), back button (start in RTL = right edge), segmented `_ChatHeaderControlCluster` (history + new-chat, kept from α3) on actions. The persona pill (avatar + name + mode) was deleted from the AppBar — the persona greeting block (β1) carries that responsibility inside the conversation. This removes redundant chrome and lets the conversation be the focus.

---

## β4 — Streaming animation

**File:** [lib/features/ai_assistant/widgets/conversation_message.dart:StreamingMessage](lib/features/ai_assistant/widgets/conversation_message.dart)

### Streaming infrastructure findings
End-to-end streaming **already plumbed** before β: [ai_chat_provider.dart:sendMessageStreaming](lib/features/ai_assistant/providers/ai_chat_provider.dart) consumes `_aiService.streamChatCompletion(...)` and updates `state.currentStreamContent` per chunk. No edge-function or service work needed. ✅

### What β4 adds
- **Paced character render.** `StreamingMessage` is now a `ConsumerStatefulWidget` with an internal `_displayed` buffer. A `Timer.periodic(33ms)` ticks at ~30Hz, advancing `_displayed` by up to 3 chars per tick toward the latest `widget.content`. Effective reveal rate ~80 chars/sec — fluent Arabic reading pace. If chunks arrive faster, the buffer absorbs them; if slower, the ticker idles (canceled when caught up, restarted in `didUpdateWidget` when more arrives).
- **Blinking cursor at the frontier.** `_BlinkingCursor` — a 2×18px theme-accent bar with `AnimationController` 1000ms repeat-reverse, opacity oscillates 0.3 ↔ 1.0. Sits inline at the end of the streamed text via a `Wrap` with `WrapCrossAlignment.center`.
- **Visual settling on completion** — when the stream completes, `currentStreamContent` clears and the assistant message is appended; the parent's `.animate().fadeIn(duration: AppAnimations.fast)` provides a soft visual transition between the streaming widget and the final `ConversationMessage`.

### Block-level settling pulse — DEFERRED
The spec calls for a 50ms opacity pulse on a paragraph or list-item when it completes. This requires detecting markdown-block boundaries from outside the markdown parser — non-trivial with `flutter_markdown` (no public block-completion event). I considered heuristics (`_displayed.endsWith('\n\n')` or `\n- `) but the timing would clash with the per-tick rebuild. Skipped for v1.

---

## β9 — Theme verification

### Automated checks
| Check | Result |
|---|---|
| `flutter analyze lib/` | **0 issues** |
| `flutter test test/unit/` | **1040/1040 passing** |
| `flutter test test/golden/` | **8/8 passing** |

### Theme-token usage in β changes
All new components read from `themeColorsProvider`. No hardcoded `AppColors.islamicGreen*` references survived in β-touched code paths. Tokens used:
- `themeColors.primary` — user bubble fill (12% alpha), composer send button gradient stop, drawer gradient, fade mask
- `themeColors.primaryLight` — gradient companion
- `themeColors.primaryDark` — drawer gradient stop
- `themeColors.accent` — AI accent line + glow, persona name, drawer chip headers, most-recent tile border, code block accent, bullet glyph, inline code, blockquote border
- `themeColors.surface` — composer pill fill (70% alpha)
- `themeColors.background2` — action sheet fill (85% alpha)
- `themeColors.textOnGradient` — body text where appropriate, send-button glyph

### Real-device verification — PENDING
| Verification | Status |
|---|---|
| Persona greeting block renders + scrolls with conversation | 🟡 founder retest |
| User bubble fill + asymmetric corner reads as anchored to reading-start edge | 🟡 founder retest |
| AI message accent line + glow visible against the gradient background | 🟡 founder retest |
| RTL list wrap (α1 fix preserved) | 🟡 founder retest |
| Pull-quote scripture-treatment renders distinctly when AI cites a hadith | 🟡 founder retest |
| Long-press a message → bottom sheet appears | 🟡 founder retest |
| Streaming reveals at fluent reading pace, cursor blinks at the frontier | 🟡 founder retest |
| Drawer: chip headers + most-recent emphasis + bottom-anchored new-chat pill + fade mask | 🟡 founder retest |
| All 6 themes (green / lavender / royal blue / sunset / rose / midnight) | 🟡 founder retest per theme |

---

## Surprising findings

1. **Streaming was already end-to-end.** The α report's "memory extraction was disabled but streaming intact" line was the clue. Verified by tracing `sendMessageStreaming` → `_aiService.streamChatCompletion`. No edge function changes needed for β4. The biggest perceived risk in the brief turned out to be a no-op infrastructure-wise.

2. **The `MessageActionsRow` from α2 is now fully dead.** β5 entirely replaces it. The file `message_actions.dart` has only `CopyCodeButton` (used by the markdown code-block treatment) still alive. The `MessageActionsRow` class can be deleted in a follow-up cleanup; left in place this round to keep the diff focused.

3. **The CTO spec's "left-edge accent line" is RTL-ambiguous.** I went literal (physical left), reasoning that the design intent was "marking the AI's column with a margin glyph" rather than "highlighting the start of the AI's prose." The Arabic reader sees the line at the column's terminal edge — visually consistent with the spec's diagram even if semantically backward to a developer thinking in "quote start indicator" terms. If the founder dislikes it on real device, swapping `Positioned(left:0)` to `PositionedDirectional(start: 0)` is a one-line change.

4. **Pull-quote-only treatment isn't reliably content-detectable** without a custom markdown element builder. Treating *all* blockquotes with the scripture treatment is the pragmatic compromise that fits this app's content distribution.

---

## Open questions for the CTO

1. **β2 — accent line on physical left vs RTL-start (right).** Worth a real-device look. The line is currently on the physical left edge; for Arabic readers, this puts the line at the END of each line's reading direction. If we want it at the START (right edge in RTL, mirroring the user bubble's anchor) it's a one-line directional swap. I have no strong opinion.

2. **β5 — should the long-press affordance also surface on tap-and-hold for the persona greeting block?** Currently the greeting is non-interactive. Some users might long-press it expecting a "switch mode" or "about أنيس" sheet. Noting for product input.

3. **β6 — defer or schedule the relative-name highlighting?** Implementation requires a custom `MarkdownElementBuilder` that segments paragraph text and matches against the user's relative list. ~1-day work. Founder call on whether this is enough product value to schedule.

4. **β6 — defer or upgrade the pull-quote detection?** Currently all blockquotes get the reverent treatment. A custom builder could distinguish scripture (`قال رسول الله ﷺ` regex) from regular quotes. Given the AI's content distribution, I'd lean defer.

5. **β4 — block-settling opacity pulse on paragraph completion.** I skipped this. Adding it requires either a custom markdown widget or a heuristic on `\n\n` boundaries with deferred opacity controllers. ~half-day work; minor visual benefit. Founder call.

6. **β7 — drawer is no longer a `ListView` directly; it's a `Stack(ListView, Positioned bottom)`.** The list has 80px bottom padding so its last tile clears the floating new-chat pill. If the founder wants the last tile to *touch* the pill's top edge (more density), reduce the padding. Currently set to 80 because it felt like the right breathing room.

7. **`MessageActionsRow` cleanup.** Phase α2 widget is now unused. Leaving it for a future cleanup PR rather than bundling its deletion into β. Founder can `/schedule` an agent to remove it later.

---

## Files touched

```
NEW   lib/features/ai_assistant/widgets/persona_greeting_block.dart      β1
NEW   lib/features/ai_assistant/widgets/message_action_sheet.dart        β5
EDIT  lib/features/ai_assistant/widgets/conversation_message.dart        β2 + β4 + β6 callers
EDIT  lib/features/ai_assistant/widgets/markdown_styles.dart             β6 (signature change, theme-aware)
EDIT  lib/features/ai_assistant/widgets/chat_message_bubble.dart         β2 (removed duplicate TypingIndicator)
EDIT  lib/features/ai_assistant/widgets/chat_history_drawer.dart         β7
EDIT  lib/features/ai_assistant/screens/ai_chat_screen.dart              β1 wire + β3 + β8
EDIT  lib/features/ai_assistant/screens/weekly_report_screen.dart        β6 caller migration
```

8 files. ~700 net lines changed. No structural rewrites of the data layer or providers.

---

## Verification request

@founder — please retest on real device. Specifically:

1. **Open the chat surface.** Persona greeting at the top, scrolls with the conversation, hairline divider beneath it.
2. **Send a prompt.** User bubble appears on the right with the asymmetric corner anchored to the right edge. AI streams in with a 2px theme-accent vertical line on the physical left, characters revealed at reading pace, blinking cursor at the frontier.
3. **Long-press a user message.** Bottom sheet rises with نسخ + تعديل + إعادة توليد الرد.
4. **Long-press an AI message.** Bottom sheet rises with نسخ + إعادة + إبلاغ.
5. **Empty composer with no messages.** Three suggested-prompt chips above the glass-pill composer. Start typing — chips fade out, send button scales up + lights gradient.
6. **Send a prompt that elicits a hadith.** Quote should render with reverent treatment (faint accent surface, accent right-border in RTL, italic).
7. **Open the chat history drawer.** Section headers are small theme-accent pills. The most recent conversation has heavier emphasis. New-chat button is anchored to the bottom with a soft fade mask above it.
8. **Switch theme** (settings → theme carousel) **and reopen the chat surface.** All accents should adopt the new theme — accent line, persona name, send button gradient, drawer chip headers, pull-quote bar. Verify in at least 3 of the 6 themes (green, lavender, midnight are the strongest stress tests).

If this passes, β is closed. β follow-ups (relative-name highlighting, scripture-vs-regular blockquote distinction, block-settling pulse, `MessageActionsRow` cleanup) can be scheduled separately.
