# LAUNCH_DEMO_SCRIPT

A 60-second screen recording for the App Store preview video. Arabic narration, line-by-line, with timing cues. Shoot on the same device as the screenshots (6.7" iPhone). Practice the flow once before recording so the timings land.

**Total runtime:** 60 seconds. **Pace:** unhurried — the narration is short on purpose, let the UI breathe.

---

## 0:00 → 0:03 — Cold open

**Action:** Home screen on, daily hadith visible, gold divider, quick actions, the 3-day streak in the header. No taps yet.
**Narration:** صلة الرحم زاد من الدنيا لما بعدها.
**Cue:** brief silence before the title.

## 0:03 → 0:08 — Add a relative

**Action:** Tap "+" → Add Relative. Type "خالتي فاطمة" in the name field. Tap "خالة" in the relationship picker. Tap save.
**Narration:** ابدأ بإضافة أهلك واحد واحد.
**Cue:** the success toast `تم إضافة خالتي فاطمة بنجاح` flashes — let it.

## 0:08 → 0:14 — Open Reminders, set a schedule

**Action:** Tap the Reminders tab. Tap "Create new reminder". Pick "أسبوعي". Pick Friday at 11:00. Save.
**Narration:** اختار وقت يناسبك للتذكير.
**Cue:** smooth, deliberate taps; the schedule card animates in.

## 0:14 → 0:20 — Attach the new relative to the schedule

**Action:** From the schedule card, tap "إضافة أقارب". Select "خالتي فاطمة" from the bottom sheet. Confirm.
**Narration:** ضمّ أقاربك للتذكير في ضغطة.
**Cue:** chip appears showing the count went from 0 to 1.

## 0:20 → 0:28 — Log an interaction (the moment of feedback)

**Action:** Open the relative detail for خالتي فاطمة. Tap the call action. (Cancel the call sheet immediately — this is a demo). The interaction-creation dialog auto-fires. Tap "حفظ".
**Narration:** كل تواصل يحسبه — نقاط، سلسلة، شهور.
**Cue:** the enriched toast appears: `+15 نقطة · 🔥 سلسلة 1 يوم مع خالتي فاطمة`. Hold it on screen for at least 1.5s.

## 0:28 → 0:34 — Streak milestone moment

**Action:** Pre-record the device with state where the next interaction triggers a 7-day milestone. Re-do the call action. The fancier toast fires: `✨ +15 نقطة · 🔥 وصلت لـ7 يوم متواصل مع خالتي فاطمة`.
**Narration:** ولما توصل لمحطة، صِلني يحتفل معاك.
**Cue:** sparkle in the toast. Hold 2 seconds.

## 0:34 → 0:42 — Open Wrapped (monthly)

**Action:** Navigate to `/monthly-wrapped`. Swipe through to the personality page (breathing glow + label).
**Narration:** آخر الشهر يجيك ملخص بأسلوبك أنت.
**Cue:** breathing glow circle pulse, gold particles if confetti fires on this page. Hold 3 seconds.

## 0:42 → 0:50 — AI Hub glance

**Action:** Tap the AI Hub bottom-nav icon. Show the three feature cards (المستشار, سيناريوهات, التقرير). Tap المستشار, scroll one assistant message into view with the `✨ AI` badge visible.
**Narration:** ولما تحتاج كلمة في موقف، المستشار حاضر.
**Cue:** the AI label badge subtle but in frame.

## 0:50 → 0:56 — Family Tree close-up

**Action:** Navigate to `/family-tree`. Pinch-zoom slowly out from the user node so siblings, parents, junction bar to uncle/aunt appear. Don't go far — just enough to show the perspective labels.
**Narration:** وشجرة عائلتك بمنظورك أنت.
**Cue:** zoom is the visual; the perspective labels are the message.

## 0:56 → 1:00 — Closing card

**Action:** Static end card with logo + closing line.
**Narration:** صِلْني يذكرك بصلة رحمك ويحسبها لك.
**Cue:** logo holds the last 1.5 seconds. Fade to black.

---

## Production notes

- Record at 60fps. Apple compresses to 30fps in the App Store player but the source quality matters for crops.
- Capture in airplane mode + Wi-Fi (so AI calls don't dial out and toast text isn't ad-libbed by the live model). Pre-stage cached AI replies before recording.
- Keep the bottom-nav visible on every shot except 0:34→0:42 (Wrapped is fullscreen) and the closing card.
- Voice talent: Saudi Arabic, warm, unhurried. The narration is brief — leave silence between lines if needed.
- Music: very subtle, instrumental, no vocals. Drop out for the Wrapped pulse and the closing line.
- Status bar: full battery, full Wi-Fi, time exactly 10:24 (matches the screenshots).
