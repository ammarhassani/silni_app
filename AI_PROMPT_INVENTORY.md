# AI Prompt Inventory — Phase γ.1

**Date:** 2026-05-02
**Scope:** Complete inventory of every prompt asset that shapes أنيس's output
**Status:** Findings only. No code changes. Decisions deferred to CTO + founder.
**Sources:** Production database (`bapwklwxmwhpucutyras`), `lib/core/ai/`, `lib/core/services/`, `supabase/functions/`

---

## Architecture overview (read first)

The Silni AI stack is a 3-layer system:

1. **Dart app (client)** — owns every system prompt. Builds the full prompt string at the call site, including personality, mode instructions, full relatives context, memories context, and feature-specific JSON-output instructions.
2. **`deepseek-proxy` edge function (server)** — **pure passthrough**. Does NOT inject any system message. Does NOT transform prompts. Does NOT summarize context. Auth + rate-limit + forward to DeepSeek API. Whatever the Dart app sends, that's what hits the model.
3. **DeepSeek API** — model: `deepseek-chat`. The function hardcodes this model. Temperature, max_tokens, stream are forwarded from the Dart app's `AIParameterConfig`.

**Implication:** Every prompt change goes through the Dart app or the admin tables that the Dart app reads. The proxy can be ignored for prompt-content design.

---

## Category 1 — Database-resident prompt content

### 1.1 `admin_ai_identity` (0 rows — EMPTY)

Schema:
```
ai_name, ai_name_en, ai_role_ar, ai_role_en, ai_avatar_url,
greeting_message_ar, greeting_message_en, dialect, personality_summary_ar,
is_active, created_at, updated_at
```

**The table is empty.** All identity values come from `AIIdentityConfig.fallback()` in [lib/core/services/ai_config_service.dart:413-422](lib/core/services/ai_config_service.dart#L413-L422):

```dart
factory AIIdentityConfig.fallback() {
  return AIIdentityConfig(
    aiName: 'أنيس',
    aiNameEn: 'Wasel',                                         // ← legacy English name
    aiRoleAr: 'مساعد ذكي متخصص في صلة الرحم والعلاقات الأسرية',
    aiRoleEn: 'Smart assistant for family connections',
    greetingMessageAr: 'السلام عليكم! أنا أنيس، مساعدك الشخصي لصلة الرحم. كيف يمكنني مساعدتك اليوم؟',
    dialect: 'saudi_arabic',
  );
}
```

### 1.2 `admin_ai_personality` (5 rows — ACTIVE)

This is the table that gets read by `AIConfigService.fullPersonalityPrompt`. **In production, this content goes into every system prompt.**

| section_key | section_name_ar | content_ar (verbatim) | priority |
|---|---|---|---|
| `base` | الهوية الأساسية | `أنت أنيس، مساعد ذكي متخصص في تعزيز صلة الرحم والعلاقات الأسرية. تتحدث بالعربية الفصحى وتهتم بالقيم الإسلامية.` | 1 |
| `values` | القيم الإسلامية | `تستند في نصائحك إلى تعاليم الإسلام حول صلة الرحم وبر الوالدين والإحسان للأقارب.` | 2 |
| `style` | أسلوب التواصل | `تتحدث بأسلوب ودي ومحترم، تستخدم التشجيع والتحفيز، وتتجنب الأحكام السلبية.` | 3 |
| `precision` | الدقة والاختصار | `تجيب بإيجاز ووضوح، وتتجنب الإطالة غير الضرورية. تركز على الفائدة العملية.` | 4 |
| `emotional` | الذكاء العاطفي | `تفهم مشاعر المستخدم وتتعامل معها بحساسية، وتقدم الدعم النفسي عند الحاجة.` | 5 |

Updated: `base` row last touched 2026-04-27 (renamed from واصل → أنيس in Phase 6.1). Other rows last touched 2026-01-11.

**🚩 Critical contradiction.** Section `base` says **"تتحدث بالعربية الفصحى"** (you speak Classical Arabic / Fusha). The hardcoded fallback in `ai_prompts.dart` and `ai_config_service.dart` says **"تتحدث بالعامية السعودية البيضاء"** (you speak Saudi colloquial). These are mutually exclusive registers. Whichever loads first wins, and the founder's actual production traffic goes to the DB version → **the AI is being told to speak Fusha while the marketing copy and dialect examples in code teach it Saudi colloquial.**

### 1.3 `admin_ai_parameters` (6 rows)

Tuning knobs per feature_key. No prompt content, just model parameters.

| feature_key | model | temp | max_tokens | timeout | stream | description |
|---|---|---|---|---|---|---|
| `chat` | deepseek | 0.7 | 2048 | 30 | true | المحادثة (counselor chat) |
| `memory_extraction` | deepseek | 0.3 | 500 | 30 | true | high-precision JSON extract |
| `message_generation` | deepseek | 0.9 | 2048 | 30 | true | creative message generation |
| `relationship_analysis` | deepseek | 0.7 | 2048 | 30 | true | analysis JSON output |
| `smart_reminders` | deepseek | 0.7 | 1024 | 30 | true | reminder suggestions |
| `weekly_report` | deepseek | 0.7 | 1500 | 30 | true | weekly summary |

All routes go to `deepseek` model regardless of `model_name`. The proxy hardcodes the actual model string `deepseek-chat`.

### 1.4 `admin_ai_streaming_config` (1 row)

Client-side streaming visual cadence (not prompt content):
```
sentence_end_delay_ms: 10
comma_delay_ms: 6
newline_delay_ms: 12
space_delay_ms: 2
word_min_delay_ms: 3, word_max_delay_ms: 5
is_streaming_enabled: true
```

This drives the typewriter animation pace, not the model. **Not prompt content.**

### 1.5 `admin_ai_touch_points` (7 rows — ALL ACTIVE)

Each touch point is a separately configured AI generation point on a screen. The `prompt_template` is the literal system prompt sent to DeepSeek (interpolated with `{{placeholder}}` substitutions by `AITouchPointService`).

#### 🚩 Row `home/greeting`
```
أنت واصل، مساعد صلة الرحم. اكتب تحية قصيرة وودية (جملة واحدة فقط) للمستخدم بناءً على:
- الوقت الحالي: {{time_of_day}}
- عدد الشعلات النشطة: {{active_streaks}}
- الأقارب المعرضون للخطر: {{at_risk_count}}
- المناسبات القادمة: {{upcoming_occasions}}

اجعل التحية دافئة وشخصية باللهجة السعودية. لا تزيد عن 15 كلمة.
```
**Persona is `واصل`, NOT `أنيس`.** The Phase 6.1 rename did not propagate here. Last updated 2026-01-12.
- temp: 0.8, max_tokens: 50

#### Row `home/priority_contacts`
```
بناءً على بيانات الأقارب التالية، رتب أهم 3 أقارب يحتاجون التواصل اليوم مع سبب قصير لكل منهم.

الأقارب:
{{relatives_data}}

الشعلات:
{{streaks_data}}

المناسبات القادمة:
{{occasions_data}}

أجب بصيغة JSON:
[{"name": "الاسم", "reason": "السبب في كلمات قليلة", "urgency": "high/medium/low"}]
```
- temp: 0.7, max_tokens: 200
- No persona declaration. No tone instructions.

#### Row `home/insight`
```
بناءً على بيانات التفاعلات والأنماط التالية، اكتب ملاحظة واحدة مفيدة ومشجعة للمستخدم عن صلة الرحم.

ملخص الصحة:
- علاقات صحية: {{healthy_count}}
- تحتاج اهتمام: {{needs_attention_count}}
- معرضة للخطر: {{at_risk_count}}

إحصائيات:
- إجمالي التفاعلات: {{total_interactions}}
- الشعلات النشطة: {{active_streaks}}

اجعل الملاحظة إيجابية ومحفزة. جملة أو جملتين فقط.
```
- temp: 0.8, max_tokens: 80
- No persona, no dialect.

#### Row `relative_detail/health_explanation`
```
اشرح باختصار لماذا صحة العلاقة مع {{relative_name}} هي {{health_status}}.

البيانات:
- آخر تواصل: {{days_since_contact}} يوم
- التقارب العاطفي: {{emotional_closeness}}/5
- جودة التواصل: {{communication_quality}}/5
- الشعلة الحالية: {{current_streak}} يوم

اكتب جملة أو جملتين تفسيرية بأسلوب ودي.
```
- temp: 0.7, max_tokens: 80

#### Row `reminders/time_suggestion`
```
بناءً على أنماط التواصل مع {{relative_name}}:
- أوقات التواصل السابقة: {{contact_times}}
- الوقت المفضل المسجل: {{preferred_time}}

اقترح أفضل وقت للتذكير بالتواصل. جملة واحدة فقط.
```
- temp: 0.7, max_tokens: 50

#### Row `reminders/frequency_recommendation`
```
بناءً على نوع العلاقة ({{relationship_type}}) وصحة العلاقة ({{health_status}}):

اقترح تكرار مناسب للتذكير (يومي/أسبوعي/شهري) مع تبرير قصير.
```
- temp: 0.7, max_tokens: 60

#### Row `relative_detail/conversation_starters`
```
أنت مساعد عربي متخصص في تقوية صلة الرحم.

معلومات عن القريب:
- الاسم: {{relative_name}}
- صلة القرابة: {{relationship_type}}
- الجنس: {{gender}}
- الاهتمامات: {{interests}}
- نوع الشخصية: {{personality_type}}
- آخر تواصل منذ: {{days_since_contact}} يوم

اقترح 3 مواضيع محادثة مناسبة. كل موضوع يجب أن يكون:
1. جملة واحدة كاملة جاهزة للاستخدام
2. مناسب لجنس القريب ({{gender}})
3. مبني على اهتماماته إن وجدت
4. لا تفترض أي معلومة غير مذكورة في البيانات أعلاه — لا تفترض وفاة أو مرض أو حالة اجتماعية أو أي شيء آخر

اكتب 3 مواضيع فقط، كل موضوع في سطر منفصل، بدون ترقيم أو نقاط:
```
- temp: 0.8, max_tokens: 150
- Has the no-fabrication guard rule (#4) — strongest of any touch-point.

### 1.6 `admin_counseling_modes` (4 rows — ALL ACTIVE)

These get injected into chat system prompts via `AIPrompts.getDynamicModeInstructions()`.

| mode_key | display_name_ar | mode_instructions (verbatim) | is_default |
|---|---|---|---|
| `general` | محادثة عامة | `تحدث بشكل عام عن أي موضوع يتعلق بصلة الرحم والعلاقات الأسرية.` | true |
| `relationship` | تحسين العلاقات | `ركز على تقديم نصائح عملية لتحسين وتعزيز العلاقات مع الأقارب.` | false |
| `conflict` | حل النزاعات | `ساعد في تحليل المشاكل العائلية واقترح حلولاً عملية وحكيمة.` | false |
| `communication` | فن التواصل | `قدم نصائح لتحسين مهارات التواصل والحوار مع الأقارب.` | false |

**The DB versions are one-line each.** The hardcoded fallback in `ai_prompts.dart:getModeInstructions()` is much richer (multi-bullet specifications). When config IS loaded, the model gets the **terse DB version**, not the rich hardcoded version. (See Surprises §5.)

### 1.7 `admin_suggested_prompts` (16 rows)

UI suggestions only — these populate the chip row above the empty composer. **Not part of the system prompt.** They appear in the conversation as user messages once tapped. Verbatim:

| mode_key | prompt_ar | sort |
|---|---|---|
| general | كيف أحافظ على صلة الرحم؟ | 1 |
| general | ما أهمية صلة الرحم في الإسلام؟ | 2 |
| general | كيف أتواصل مع قريب بعيد؟ | 3 |
| general | اقترح لي طرق للتواصل | 4 |
| relationship | كيف أحسن علاقتي بوالديّ؟ | 1 |
| relationship | كيف أتقرب من أقاربي؟ | 2 |
| relationship | علاقتي بأخي متوترة، ماذا أفعل؟ | 3 |
| relationship | كيف أصبح أكثر قرباً من عائلتي؟ | 4 |
| conflict | هناك خلاف عائلي، كيف أتصرف؟ | 1 |
| conflict | كيف أتعامل مع قريب صعب المراس؟ | 2 |
| conflict | كيف أصلح بين أقاربي المتخاصمين؟ | 3 |
| conflict | قريبي غاضب مني، ماذا أفعل؟ | 4 |
| communication | كيف أبدأ محادثة مع قريب؟ | 1 |
| communication | ماذا أقول في أول اتصال بعد انقطاع؟ | 2 |
| communication | كيف أعبر عن مشاعري لعائلتي؟ | 3 |
| communication | ما المواضيع المناسبة للحديث؟ | 4 |

### 1.8 `admin_communication_scenarios` (6 rows — ALL ACTIVE)

| scenario_key | title_ar | description_ar | prompt_context |
|---|---|---|---|
| reconnect | إعادة التواصل | التواصل بعد فترة انقطاع | **NULL** |
| congratulate | تهنئة | تهنئة بمناسبة سعيدة | **NULL** |
| condolence | تعزية | تقديم العزاء والمواساة | **NULL** |
| checkin | اطمئنان | الاطمئنان على الحال | **NULL** |
| apology | اعتذار | الاعتذار وطلب المسامحة | **NULL** |
| thanks | شكر | شكر وتقدير | **NULL** |

**🚩 All `prompt_context` fields are NULL.** Communication-script generation flows through `AIPrompts.communicationScriptPrompt(scenario, ...)` which formats this scenario name into the prompt — but the AI gets only the title, no scenario-specific guidance from the DB.

### 1.9 `admin_message_occasions` (12 rows — ALL ACTIVE)

| occasion_key | display_name_ar | prompt_addition |
|---|---|---|
| eid | عيد | **NULL** |
| ramadan | رمضان | **NULL** |
| birthday | عيد ميلاد | **NULL** |
| wedding | زواج | **NULL** |
| graduation | تخرج | **NULL** |
| newborn | مولود جديد | **NULL** |
| condolence | تعزية | **NULL** |
| recovery | شفاء | **NULL** |
| missing | اشتياق | **NULL** |
| checkin | اطمئنان | **NULL** |
| apology | اعتذار | **NULL** |
| thanks | شكر | **NULL** |

**🚩 All 12 `prompt_addition` fields are NULL.** Same pattern as scenarios — the AI gets the occasion key but no occasion-specific guidance.

### 1.10 `admin_message_tones` (4 rows — ALL ACTIVE)

| tone_key | display_name_ar | prompt_modifier |
|---|---|---|
| formal | رسمي | `استخدم لغة رسمية ومحترمة` |
| warm | دافئ | `استخدم لغة دافئة ومحببة` |
| humorous | مرح | `أضف لمسة خفيفة ومرحة` |
| religious | ديني | `أضف آيات أو أدعية مناسبة` |

`is_default` is **false on all 4 rows** despite the schema supporting a default. The Dart code hardcodes `'warm'` as the fallback default — see `AIConfigService.defaultToneKey`.

### 1.11 `admin_ai_error_messages` (10 rows)

User-facing error messages — **not prompt content**. Listed for completeness:

| code | message_ar | retry |
|---|---|---|
| 400 | طلب غير صالح. يرجى المحاولة مرة أخرى. | true |
| 401 | انتهت جلستك. يرجى تسجيل الدخول مرة أخرى. | false |
| 402 | هذه الميزة متاحة فقط لمشتركي MAX. | false |
| 403 | ليس لديك صلاحية لهذا الإجراء. | false |
| 404 | لم يتم العثور على المورد المطلوب. | true |
| 408 | انتهت مهلة الطلب. حاول مرة أخرى. | true |
| 429 | تم تجاوز الحد المسموح. انتظر قليلاً ثم حاول. | true |
| 500 | حدث خطأ في الخادم. نعتذر عن الإزعاج. | true |
| 502 | خطأ في بوابة الخادم. حاول بعد قليل. | true |
| 503 | الخدمة غير متوفرة حالياً. نعتذر عن الإزعاج. | true |

Note `404`/`408`/`502` rows are present but the lib/ default fallback table doesn't list them — minor consistency drift.

---

## Category 2 — Code-resident prompt content

### 2.1 [lib/core/ai/ai_identity.dart](lib/core/ai/ai_identity.dart)

Single source of truth for AI identity. Reads from `AIConfigService` (which reads from `admin_ai_identity` — empty in prod, so falls back).

**Static constants (lines 17-34):**
```dart
static const String defaultName = 'أنيس';
static const String defaultNameEn = 'Wasel';                                                  // ← legacy
static const String defaultRoleAr = 'مساعد ذكي متخصص في صلة الرحم والعلاقات الأسرية';
static const String defaultRoleEn = 'Smart assistant specializing in family connections';
static const String defaultGreetingAr =
    'السلام عليكم! أنا أنيس، مساعدك الشخصي لصلة الرحم. كيف يمكنني مساعدتك اليوم؟';
```

**Hardcoded fallback personality ([ai_identity.dart:97-119](lib/core/ai/ai_identity.dart#L97-L119)):**
```
أنت "أنيس"، مساعد ذكي متخصص في صلة الرحم والعلاقات الأسرية.

## شخصيتك الأساسية:
- تتحدث بالعامية السعودية البيضاء بأسلوب دافئ ومحب وطبيعي
- تجسّد قيم الإسلام بشكل طبيعي: المحبة، الرحمة، الصبر، والإحسان
- تهتم بصلة الرحم وتشجع على التواصل مع الأقارب

## لهجتك:
- استخدم العامية السعودية البيضاء (المفهومة لجميع السعوديين)
- لا تستخدم الفصحى الأدبية المتكلفة أو اللغة الرسمية
- اكتب كما يتحدث الناس عادةً في الحياة اليومية

## ذكاءك العاطفي:
- تلتقط مشاعر المستخدم من كلماته
- ترد على المشاعر أولاً قبل تقديم النصيحة
- لا تتسرع في الحلول

## قيمك الثابتة:
- صلة الرحم فريضة وليست اختياراً
- العائلة هي أساس المجتمع الصالح
- الصبر والحلم في التعامل مع الخلافات
```

**Dialect: Saudi colloquial.** Used only when `AIConfigService.isLoaded == false`.

### 2.2 [lib/core/ai/ai_prompts.dart](lib/core/ai/ai_prompts.dart)

Master prompt library. 1145 lines. Catalog:

#### `basePersonality` constant ([ai_prompts.dart:35-97](lib/core/ai/ai_prompts.dart#L35-L97)) — FALLBACK

The richest prompt asset in the codebase. Used when `AIConfigService.isLoaded == false`. Includes:
- Persona declaration (أنيس, family assistant)
- Saudi colloquial dialect with **explicit ✓/✗ examples** (line 47-56) — see §5 (few-shot)
- Emotional intelligence framework
- Values (صلة الرحم فريضة)
- Advisory style
- "ما يجب تجنبه" — list of behaviors to avoid
- **The accuracy guard:**
  ```
  ## قاعدة صارمة - الدقة المطلقة:
  ⚠️ لا تختلق أو تفترض أي معلومات غير موجودة في السياق.
  ⚠️ إذا لم تجد بيانات عن تواصل المستخدم، لا تدّعي أنه تواصل مع أحد.
  ⚠️ لا تقل "أرى أنك تواصلت" إلا إذا كانت البيانات موجودة فعلاً.
  ⚠️ إذا لم تكن متأكداً، اسأل المستخدم بدلاً من الافتراض.
  ⚠️ الصدق أهم من الظهور بمظهر المطّلع.
  ```

This entire block is **only used when admin config fails to load**. In normal production it's bypassed.

#### `getModeInstructions(CounselingMode mode)` ([ai_prompts.dart:100-139](lib/core/ai/ai_prompts.dart#L100-L139))

Hardcoded fallback per mode. Verbatim:

```
## وضع المحادثة العامة:
- ساعد المستخدم في أي موضوع يخص العائلة
- اقترح طرقاً للتواصل مع الأقارب
- قدّم تشجيعاً مستمراً على صلة الرحم
- كن مرناً في المواضيع المطروحة

## وضع نصائح العلاقات:
- ركّز على تعزيز الروابط الأسرية
- اقترح أنشطة مشتركة وطرق تواصل
- ساعد في فهم احتياجات كل طرف
- شجّع على الزيارات والاتصالات المنتظمة
- قدّم أفكاراً لتقوية العلاقة

## وضع حل الخلافات:
- استمع بتعاطف دون انحياز
- ساعد في فهم وجهة نظر الطرف الآخر
- اقترح خطوات عملية للمصالحة
- ذكّر بأهمية العفو والتسامح
- لا تشجّع على القطيعة إلا في حالات الضرر الشديد
- ساعد في صياغة كلمات الاعتذار إن لزم

## وضع التواصل الفعّال:
- ساعد في صياغة رسائل ومحادثات
- علّم أساليب التواصل اللطيف
- اقترح أوقات وطرق مناسبة للتواصل
- ساعد في التعامل مع الشخصيات المختلفة
- قدّم نصوصاً جاهزة للمحادثات الصعبة
```

The DB versions (§1.6) collapse each of these to a single sentence. **In production, the AI receives the DB sentence — not these rich rules.**

#### `buildChatSystemPrompt({mode, relative, allRelatives, memories, relationshipLabels})` ([ai_prompts.dart:243-273](lib/core/ai/ai_prompts.dart#L243-L273))

The system prompt that the **chat surface** uses. Composition order:

1. `dynamicPersonality` (= `AIIdentity.personality` = `AIConfigService.fullPersonalityPrompt`)
2. blank line
3. `getDynamicModeInstructions(mode.name)` — DB-resident mode-instructions wrapped in `## وضع X:` header
4. `buildAllRelativesContext(allRelatives, relationshipLabels)` — all user's relatives
5. `buildRelativeContext(relative)` — focus relative if any
6. `buildMemoriesContext(memories)` — extracted memories

#### `buildEnhancedChatSystemPrompt({mode, context: AIContext})` ([ai_prompts.dart:282-337](lib/core/ai/ai_prompts.dart#L282-L337))

Alternative builder using `AIContext` data. Adds gamification (active streaks, total interactions), upcoming occasions, and health summary.

**🚩 Not called from any production path.** Greppable only from tests. The chat surface uses `buildChatSystemPrompt`, not this. Dead-or-stale code.

#### `buildAllRelativesContext(relatives, {relationshipLabels})` ([ai_prompts.dart:340-423](lib/core/ai/ai_prompts.dart#L340-L423))

Renders all the user's relatives into a structured Markdown block. Sample shape (interpolated):

```
## عائلة المستخدم:
المستخدم لديه N قريب مسجل في التطبيق.

## أنواع الأقارب:
- أهل البيت: لا تنبّه على التواصل معهم — ركّز على جودة العلاقة ولحظات مشتركة
- تواصل دائم: نبّه لو مرت فترة بدون تواصل — اقترح طرق تواصل مناسبة
- مناسبات: ركّز على المناسبات القادمة والتهاني — لا تضغط على التواصل اليومي

## السياق الموسمي:
{IslamicCalendarService.getSeasonContext()}    // dynamic, e.g. "نحن في شهر رمضان"

### ملخص صحة العلاقات:
- علاقات صحية 🟢: H
- تحتاج اهتمام 🟡: N
- معرضة للخطر 🔴: A

### تفاصيل الأقارب:

#### الوالدين:
- 🟢 **{name}** ({label}) [أهل البيت] - تواصل اليوم ✓ | {personalityType}
...

#### الإخوة والأخوات:
- 🟡 **{name}** ({label}) [تواصل دائم] - آخر تواصل: منذ N أيام
...

#### الأقارب الآخرون:
...

### ⚠️ أقارب يحتاجون اهتماماً عاجلاً:
- **{name}** ({label}) - لم يتواصل منذ N يوم
...

**ملاحظة:** عندما يذكر المستخدم اسم أحد أقاربه أو صلة قرابته، استخدم هذه المعلومات لتقديم نصائح مخصصة.
إذا سأل عن نصيحة عامة، يمكنك الإشارة إلى الأقارب الذين يحتاجون اهتماماً.
```

**Token budget:** unbounded. Every relative gets a line. With 50 relatives the block exceeds 1500 tokens. No prioritization.

#### `buildRelativeContext(relative, {relationshipLabels})` ([ai_prompts.dart:142-220](lib/core/ai/ai_prompts.dart#L142-L220))

Renders a single focus relative. Includes name, label, priority, category, last contact (with warning escalation 🟢🟡🔴), health, personality, communication style, interests, sensitive topics, conflict history, AI notes.

#### `buildMemoriesContext(memories, {relativeId})` ([ai_prompts.dart:479-564](lib/core/ai/ai_prompts.dart#L479-L564))

Renders extracted memories grouped by category:
- `user_preference` → "عن المستخدم"
- `relative_fact` → "عن الأقارب"
- `family_dynamic` → "ديناميكيات عائلية"
- `important_date` → "تواريخ مهمة"
- `conversation_insight` → "ملاحظات من محادثات سابقة" (limited to top 5)

Closes with: `**استخدم هذه المعلومات لتقديم نصائح شخصية ومخصصة. لا تسأل عن معلومات تعرفها مسبقاً.**`

#### `_fallbackMemoryExtractionPrompt` (`memory_extraction` feature) ([ai_prompts.dart:568-610](lib/core/ai/ai_prompts.dart#L568-L610))

JSON-output prompt that runs offline against finished conversations. Verbatim:

```
حلل هذه المحادثة واستخرج معلومات جديدة ومفيدة فقط.

⚠️ هام جداً - لا تستخرج هذه المعلومات (موجودة بالفعل في قاعدة البيانات):
- أسماء الأقارب (الأب، الأم، الإخوة، إلخ)
- نوع صلة القرابة
- معلومات أساسية عن الأقارب موجودة في ملفاتهم

✅ استخرج فقط:
- user_preference: تفضيلات شخصية للمستخدم (أسلوب تواصله، اهتماماته، شخصيته)
- important_date: تواريخ مهمة جديدة (مناسبات، ذكريات، أحداث قادمة)
- conversation_insight: مشاعر أو مخاوف أو أهداف عبّر عنها المستخدم

أعد JSON فقط بهذا الشكل:
{
  "memories": [
    {
      "category": "user_preference",
      "content": "المعلومة بالعربية",
      "importance": 7
    }
  ]
}

## أمثلة على ما يجب تجاهله:
❌ "اسم والد المستخدم محمد" - موجود في بيانات الأقارب
❌ "أم المستخدم اسمها فاطمة" - موجود في بيانات الأقارب
❌ "لديه أخ اسمه أحمد" - موجود في بيانات الأقارب

## أمثلة على ما يجب استخراجه:
✅ "يفضل التواصل صباحاً" - تفضيل شخصي جديد
✅ "يشعر بالذنب لعدم زيارة جدته" - مشاعر مهمة
✅ "ذكرى زواج والديه في شهر رجب" - تاريخ جديد غير موجود
✅ "يجد صعوبة في التحدث عن مشاعره" - سمة شخصية

## قواعد صارمة:
- لا تستخرج ما قاله الذكاء الاصطناعي، فقط ما قاله المستخدم
- لا تكرر معلومات واضحة أو عامة
- الأهمية من 1 (منخفضة) إلى 10 (عالية جداً)
- إذا لم تجد شيئاً جديداً ومفيداً، أعد: {"memories": []}

أعد JSON فقط، بدون شرح.
```

**Note:** memory extraction is currently **disabled in chat** ([ai_chat_provider.dart:486](lib/features/ai_assistant/providers/ai_chat_provider.dart#L486)) — the comment says "Memory extraction disabled — Memory Viewer was deleted in Phase 0; collecting without surfacing is privacy debt." So this prompt exists but is not invoked.

#### `giftRecommendationPrompt` ([ai_prompts.dart:699-746](lib/core/ai/ai_prompts.dart#L699-L746))

JSON output. Saudi retail recommendation. Allowed retailers: `Amazon.sa, Noon, Jarir`. Output schema includes name, brand, price (number only, no "ر.س"), retailer, url, reason.

#### `messageGenerationPrompt(relative, occasionType, tone)` ([ai_prompts.dart:750-799](lib/core/ai/ai_prompts.dart#L750-L799))

Generates 3 occasion messages. Embeds full personality + relative metadata + occasion config + tone modifier. Output: JSON `{"messages": ["m1", "m2", "m3"]}`.

Each message: 50-80 words, with the no-fabrication clause:
```
- لا تفترض أي معلومة غير مذكورة في البيانات — لا تفترض وفاة أو مرض أو حالة اجتماعية أو أي شيء آخر
```

Three message variants prescribed:
- 1: `مباشرة ودافئة`
- 2: `تبدأ بدعاء أو حكمة`
- 3: `شاعرية أو عاطفية`

#### `occasionBatchPrompt({relatives, occasionType, ...})` ([ai_prompts.dart:803-859](lib/core/ai/ai_prompts.dart#L803-L859))

Batch occasion-message generation — one message per relative in one API call. 20-40 words each.

#### `communicationScriptPrompt(scenario, relative, context)` ([ai_prompts.dart:864-912](lib/core/ai/ai_prompts.dart#L864-L912))

Generates a structured conversation script. Output schema:
```
{
  "opening": "...",
  "key_points": ["..."],
  "phrases_to_use": ["..."],
  "phrases_to_avoid": ["..."],
  "closing": "..."
}
```

Notable instructions:
- "تجنب اللوم والنقد المباشر"
- "ركز على المشاعر بدلاً من الأخطاء"
- "استخدم 'أنا أشعر' بدلاً من 'أنت فعلت'"
- "اقترح حلولاً وليس فقط شكاوى"

#### `weeklyReportPrompt` (const) ([ai_prompts.dart:916-924](lib/core/ai/ai_prompts.dart#L916-L924))

```
أنت محلل علاقات عائلية. بناءً على البيانات المقدمة، اكتب تأملاً قصيراً (2-3 جمل)
يشجع المستخدم على صلة الرحم ويقدم نصيحة عملية واحدة للأسبوع القادم.

يجب أن يكون التأمل:
- إيجابياً ومشجعاً
- عملياً وقابلاً للتطبيق
- يعكس قيم صلة الرحم
```

**Hardcoded const. No admin override.**

#### `relationshipAnalysisPrompt(relative)` ([ai_prompts.dart:928-986](lib/core/ai/ai_prompts.dart#L928-L986))

JSON output for relationship deep-dive analysis. Schema includes summary, insights[], suggestions[] (with priority high/medium/low), alerts[].

#### `smartReminderPrompt(relatives)` ([ai_prompts.dart:990-1036](lib/core/ai/ai_prompts.dart#L990-L1036))

Output: top 3-5 priority reminders as JSON.

#### `shareCopyPrompt({cardType, context})` ([ai_prompts.dart:1043-1089](lib/core/ai/ai_prompts.dart#L1043-L1089))

Single-line social-media share copy. Card-type tone instructions:
- `streak`: "أسلوب افتخار وحماس"
- `badge`: "أسلوب احتفالي"
- `level_up`: "أسلوب تحفيزي"
- `occasion`: "أسلوب تهنئة ومعايدة"
- `wrapped`: "أسلوب ملخّص واستعراض"

Hard rules: ≤20 words, plain text only, no JSON, no markdown.

#### `wrappedPersonalityPrompt({stats})` ([ai_prompts.dart:1094-1143](lib/core/ai/ai_prompts.dart#L1094-L1143))

Generates a creative 2-4 word Arabic title for the user's wrapped/yearly summary. Notable: includes a **forbidden-titles list**:
```
## ألقاب ممنوعة (لا تستخدمها أبداً):
- "ملك الزيارات"
- "طائر الصباح العائلي"
- "بومة الليل العائلية"
- "وصّال الرحم"
- "صاحب المكالمات"
- "واصل العائلة"             ← legacy
- "الكريم"
```
The forbidden list still references "واصل العائلة" — Phase 6.1 leak.

### 2.3 [lib/core/services/ai_config_service.dart](lib/core/services/ai_config_service.dart)

Loads admin config + provides fallback paths.

#### `_hardcodedPersonality` ([ai_config_service.dart:353-374](lib/core/services/ai_config_service.dart#L353-L374))

A SECOND fallback personality, distinct from the one in [ai_identity.dart:97](lib/core/ai/ai_identity.dart#L97). Verbatim:

```
أنت "أنيس"، مساعد ذكي متخصص في صلة الرحم والعلاقات الأسرية.

## شخصيتك الأساسية:
- تتحدث بالعامية السعودية البيضاء بأسلوب دافئ ومحب وطبيعي
- تجسّد قيم الإسلام بشكل طبيعي: المحبة، الرحمة، الصبر، والإحسان

## لهجتك:
- استخدم العامية السعودية البيضاء (المفهومة لجميع السعوديين)
- لا تستخدم الفصحى الأدبية المتكلفة أو اللغة الرسمية
- اكتب كما يتحدث الناس عادةً في الحياة اليومية

## ذكاءك العاطفي:
- تلتقط مشاعر المستخدم من كلماته
- ترد على المشاعر أولاً قبل تقديم النصيحة
- لا تتسرع في الحلول

## قيمك الثابتة:
- صلة الرحم فريضة وليست اختياراً
- العائلة هي أساس المجتمع الصالح
- الصبر والحلم في التعامل مع الخلافات
```

This is essentially the same content as [ai_identity.dart:97-119](lib/core/ai/ai_identity.dart#L97-L119) — duplicate fallback. Used only via `fullPersonalityPrompt` getter when `personalitySections.isEmpty`.

#### `fullPersonalityPrompt` getter ([ai_config_service.dart:120-135](lib/core/services/ai_config_service.dart#L120-L135))

The actual prompt-construction site for the chat persona:

```dart
String get fullPersonalityPrompt {
  final sections = personalitySections;
  if (sections.isEmpty) return _hardcodedPersonality;

  final buffer = StringBuffer();
  buffer.writeln('أنت "${identity.aiName}"، ${identity.aiRoleAr}');
  buffer.writeln();

  for (final section in sections) {
    buffer.writeln('## ${section.sectionNameAr}:');
    buffer.writeln(section.contentAr);
    buffer.writeln();
  }

  return buffer.toString();
}
```

In production this produces:
```
أنت "أنيس"، مساعد ذكي متخصص في صلة الرحم والعلاقات الأسرية

## الهوية الأساسية:
أنت أنيس، مساعد ذكي متخصص في تعزيز صلة الرحم والعلاقات الأسرية. تتحدث بالعربية الفصحى وتهتم بالقيم الإسلامية.

## القيم الإسلامية:
تستند في نصائحك إلى تعاليم الإسلام حول صلة الرحم وبر الوالدين والإحسان للأقارب.

## أسلوب التواصل:
تتحدث بأسلوب ودي ومحترم، تستخدم التشجيع والتحفيز، وتتجنب الأحكام السلبية.

## الدقة والاختصار:
تجيب بإيجاز ووضوح، وتتجنب الإطالة غير الضرورية. تركز على الفائدة العملية.

## الذكاء العاطفي:
تفهم مشاعر المستخدم وتتعامل معها بحساسية، وتقدم الدعم النفسي عند الحاجة.
```

**This is the persona block that ships in production.** Compare to the colloquial-Saudi rich version that's only used as fallback. The "Classical Arabic" instruction in section `base` is what the model actually receives.

#### `AIMemorySystemConfig` defaults ([ai_config_service.dart:823-859](lib/core/services/ai_config_service.dart#L823-L859))

Hardcoded skip-keywords list (relationship terms the AI should NOT extract as memories): `اسم, اسمه, اسمها, يدعى, تدعى, والد, والدة, أب, أم, جد, جدة, أخ, أخت, إخوة, أخوات, عم, عمة, خال, خالة, ابن, ابنة, أبناء, بنات, زوج, زوجة`.

Default extraction instructions + ignore/extract examples — used when memory extraction runs.

### 2.4 [lib/core/ai/deepseek_ai_service.dart](lib/core/ai/deepseek_ai_service.dart) — `MockAIService`

Mock service for tests/dev. Includes hardcoded mock AI response strings ([deepseek_ai_service.dart:734-740, 760-765](lib/core/ai/deepseek_ai_service.dart#L734-L740)):

```
أهلاً بك! أنا أنيس، مساعدك في صلة الرحم.

صلة الرحم من أعظم الأعمال عند الله، وهي سبب للبركة في الرزق والعمر.

كيف يمكنني مساعدتك اليوم في التواصل مع أقاربك؟
```

Plus a hardcoded mock share-copy ([line 866](lib/core/ai/deepseek_ai_service.dart#L866)): `'ما شاء الله تواصلي مع أهلي ما وقف 🔥'`.

**Not in production path** but listed for completeness.

### 2.5 [lib/core/services/ai_touch_point_service.dart](lib/core/services/ai_touch_point_service.dart)

Reads `admin_ai_touch_points` and substitutes `{{placeholders}}`. The list of substituted placeholders ([ai_touch_point_service.dart:158-256](lib/core/services/ai_touch_point_service.dart#L158-L256)):

```
{{time_of_day}}, {{active_streaks}}, {{at_risk_count}},
{{healthy_count}}, {{needs_attention_count}}, {{total_interactions}},
{{upcoming_occasions}}, {{relatives_data}}, {{streaks_data}},
{{occasions_data}}, {{relative_name}}, {{relationship_type}},
{{interests}}, {{last_contact}}, {{health_status}},
{{days_since_contact}}, {{emotional_closeness}}, {{communication_quality}},
{{personality_type}}, {{gender}}, {{gender_pronoun}}, {{gender_verb}},
{{gender_ask}}, {{gender_possessive}}, {{current_streak}}, {{memories}},
{{contact_times}}, {{preferred_time}}
```

Last 4 placeholders (`contact_times`, `preferred_time`) are referenced in DB rows but not implemented in the substitution code → those will render literally as `{{contact_times}}` in the prompt. **Bug.**

---

## Category 3 — Edge function prompt content

### 3.1 [`deepseek-proxy`](supabase/functions/deepseek-proxy/index.ts) (version 17, last updated 2026-04-30)

**Pure passthrough.** Auth + rate-limit + SSE stream pipe. Hardcoded constants:
- `DEEPSEEK_URL = "https://api.deepseek.com/v1/chat/completions"`
- `DEEPSEEK_MODEL = "deepseek-chat"`
- Free user rate limit: 0/day (blocked)
- Paid (`max`) user rate limit: 200/day
- Default temperature if absent: 0.7
- Default max_tokens if absent: 2048

**No prompt injection.** No system message added. No content rewriting. The proxy receives `messages: [{role, content}, ...]` already containing the system message that the Dart app constructed; it forwards verbatim.

### 3.2 Other edge functions

The other 11 edge functions either don't call any LLM or are unrelated to chat:
- `send-push-notification`, `send-scheduled-reminders`, `send-scheduled-announcements`, `send-smart-nudges`, `check-streak-alerts`, `send-announcement` — push notification dispatch, no LLM
- `social-publisher`, `social-token-refresh`, `social-click-redirect`, `social-analytics-collector` — social-media publisher; no LLM in the AI counselor sense
- `sync-subscription` — subscription state sync, no LLM

**Conclusion:** the only LLM-touching edge function is `deepseek-proxy`, and it is a transparent proxy.

---

## Category 4 — Context assembly logic

### 4.1 [`AIContextEngine`](lib/core/ai/ai_context_engine.dart) — what gets assembled

Refreshed every 5 minutes via `_refreshCache(userId)`. Six parallel queries:

1. **`users.full_name`** ([ai_context_engine.dart:109-120](lib/core/ai/ai_context_engine.dart#L109-L120)) — single column.
2. **`relatives`** ([:122-142](lib/core/ai/ai_context_engine.dart#L122-L142)) — full row, `is_archived=false AND is_self=false`, ordered by priority. **Phase 9.X.D.A.fix Bug 1: self-node excluded** so the AI never references the user as their own relative.
3. **`interactions`** ([:144-161](lib/core/ai/ai_context_engine.dart#L144-L161)) — last 30 days, max 100, ordered desc by date.
4. **`relative_streaks`** ([:163-176](lib/core/ai/ai_context_engine.dart#L163-L176)) — all rows for user.
5. **`ai_memories`** ([:178-193](lib/core/ai/ai_context_engine.dart#L178-L193)) — `is_active=true`, ordered by importance desc, max 50.
6. **`users.total_interactions`** ([:195-207](lib/core/ai/ai_context_engine.dart#L195-L207)) — single column.

Plus computed-locally:
- **`upcomingOccasions`** ([:239-276](lib/core/ai/ai_context_engine.dart#L239-L276)) — birthdays in next 30 days, derived from `relatives.dateOfBirth`.
- **`healthSummary`** ([:279-314](lib/core/ai/ai_context_engine.dart#L279-L314)) — counts of healthy/needs-attention/at-risk + names of at-risk.

### 4.2 What ships in the chat system message

The chat surface uses `AIPrompts.buildChatSystemPrompt()` (NOT the enhanced variant). Composition order, top to bottom:

1. **Personality block** — from `AIIdentity.personality` → `AIConfigService.fullPersonalityPrompt` → `admin_ai_personality` table content (5 sections, see §1.2)
2. **Mode-instructions block** — from `AIPrompts.getDynamicModeInstructions(mode.name)` → `admin_counseling_modes.mode_instructions` (one-line per mode, see §1.6)
3. **Relatives block** — `AIPrompts.buildAllRelativesContext(allRelatives, ...)` (see §2.2)
4. **Focus relative block** — only if a relative is selected
5. **Memories block** — `AIPrompts.buildMemoriesContext(memories, ...)` (see §2.2)

After the system message, the OpenAI-style messages array continues with `[{role:'user'/'assistant', content:...}, ...]` representing the conversation history.

### 4.3 What's NOT in the chat system message (gaps)

- **`AIContext.userFullName`** — the user's name is fetched and cached, but `buildChatSystemPrompt` does NOT inject it. The AI never learns the user's name in chat. (`buildEnhancedChatSystemPrompt` does, but that's not called.)
- **`recentInteractions`** — fetched but unused in chat prompts. Only `daysSinceLastContact` per relative makes it into the prompt.
- **`totalInteractions`** — same, only in `buildEnhancedChatSystemPrompt`.
- **`streaks`** — only the focus-relative streak surfaces (and only in `buildEnhancedChatSystemPrompt`). Per-relative streak counts are not in the all-relatives block.
- **`upcomingOccasions`** — only in `buildEnhancedChatSystemPrompt`.

### 4.4 Token budget management

**None.** No truncation, no prioritization, no token counting. With 50 relatives + 20 memories + 5 occasions, the prompt can exceed 3-4k tokens before the user message even appears. `AIContextEngine.buildContext({tokenBudget: 2000})` accepts a `tokenBudget` parameter but it's **completely unused** ([ai_context_engine.dart:64](lib/core/ai/ai_context_engine.dart#L64)).

---

## Category 5 — Few-shot examples

The prompt library has **NO turn-by-turn dialogue exemplars** (no `User: X / Assistant: Y` pairs). The only few-shot patterns are in-context "✓ correct / ✗ wrong" snippets:

### 5.1 Dialect correction examples ([ai_prompts.dart:46-56](lib/core/ai/ai_prompts.dart#L46-L56)) — fallback only
```
- أمثلة على الأسلوب الصحيح:
  ✓ "وش رايك تتصل على أبوك اليوم؟"
  ✓ "حاول تزوره هالأسبوع"
  ✓ "ما تشوف إنك تأخرت عليه؟"
  ✓ "ليه ما تكلمه وتسأل عنه؟"
  ✓ "خلك على تواصل معاه"
- أمثلة على الأسلوب الخاطئ (تجنبه):
  ✗ "ما رأيك في أن تقوم بالاتصال بوالدك؟"
  ✗ "أقترح عليك زيارته في هذا الأسبوع"
  ✗ "ينبغي عليك المبادرة بالتواصل"
  ✗ "أنصحك بأن تبادر إلى صلة رحمك"
```
**Only used in fallback path.** Not in DB version.

### 5.2 Memory extraction examples ([ai_prompts.dart:592-601](lib/core/ai/ai_prompts.dart#L592-L601))
```
## أمثلة على ما يجب تجاهله:
❌ "اسم والد المستخدم محمد"
❌ "أم المستخدم اسمها فاطمة"
❌ "لديه أخ اسمه أحمد"

## أمثلة على ما يجب استخراجه:
✅ "يفضل التواصل صباحاً"
✅ "يشعر بالذنب لعدم زيارة جدته"
✅ "ذكرى زواج والديه في شهر رجب"
✅ "يجد صعوبة في التحدث عن مشاعره"
```

### 5.3 Wrapped personality examples ([ai_prompts.dart:1122-1138](lib/core/ai/ai_prompts.dart#L1122-L1138))
```
## أمثلة على ألقاب جيدة:
- "حارس الروابط"
- "صانع اللحظات"
- "نجم العائلة"
- "قلب لا ينقطع"
- "جسر العائلة"
- "عمود البيت"

## ألقاب ممنوعة (لا تستخدمها أبداً):
- "ملك الزيارات"
- "طائر الصباح العائلي"
- "بومة الليل العائلية"
- "وصّال الرحم"
- "صاحب المكالمات"
- "واصل العائلة"          ← Phase 6.1 leak
- "الكريم"
```

**No conversation few-shots in the chat prompt.** No worked example of "user says X → AI responds Y." The chat persona is governed entirely by abstract instructions.

---

## Category 6 — Recent live request sample

### 6.1 What I could capture

Edge function logs returned via MCP `get_logs` only expose **request metadata** (method, URL, status code, latency). Request bodies are **NOT in the logs**. Recent activity in the last hour shows zero `deepseek-proxy` invocations — the founder's chat traffic must have been earlier than the 24-hour log window or the test was an in-app session that hasn't drained logs yet.

### 6.2 Reconstructed sample (production path)

For a user with the most recent `chat_messages` row and 6 relatives, the full system message that hits DeepSeek looks like this. **Reconstructed from the prompt-assembly logic in §4.2:**

```
أنت "أنيس"، مساعد ذكي متخصص في صلة الرحم والعلاقات الأسرية

## الهوية الأساسية:
أنت أنيس، مساعد ذكي متخصص في تعزيز صلة الرحم والعلاقات الأسرية. تتحدث بالعربية الفصحى وتهتم بالقيم الإسلامية.

## القيم الإسلامية:
تستند في نصائحك إلى تعاليم الإسلام حول صلة الرحم وبر الوالدين والإحسان للأقارب.

## أسلوب التواصل:
تتحدث بأسلوب ودي ومحترم، تستخدم التشجيع والتحفيز، وتتجنب الأحكام السلبية.

## الدقة والاختصار:
تجيب بإيجاز ووضوح، وتتجنب الإطالة غير الضرورية. تركز على الفائدة العملية.

## الذكاء العاطفي:
تفهم مشاعر المستخدم وتتعامل معها بحساسية، وتقدم الدعم النفسي عند الحاجة.


## وضع محادثة عامة:
تحدث بشكل عام عن أي موضوع يتعلق بصلة الرحم والعلاقات الأسرية.


## عائلة المستخدم:
المستخدم لديه N قريب مسجل في التطبيق.

## أنواع الأقارب:
- أهل البيت: لا تنبّه على التواصل معهم — ركّز على جودة العلاقة ولحظات مشتركة
- تواصل دائم: نبّه لو مرت فترة بدون تواصل — اقترح طرق تواصل مناسبة
- مناسبات: ركّز على المناسبات القادمة والتهاني — لا تضغط على التواصل اليومي

### ملخص صحة العلاقات:
- علاقات صحية 🟢: H
- تحتاج اهتمام 🟡: N
- معرضة للخطر 🔴: A

### تفاصيل الأقارب:

#### الوالدين:
- 🟢 **{name}** (أبي) [أهل البيت] - تواصل اليوم ✓
- 🟢 **{name}** (أمي) [أهل البيت] - تواصل اليوم ✓

#### الإخوة والأخوات:
- 🟡 **{name}** (أخي) [تواصل دائم] - آخر تواصل: منذ 3 أيام
- 🟡 **{name}** (أختي) [تواصل دائم] - آخر تواصل: منذ 5 أيام

...

**ملاحظة:** عندما يذكر المستخدم اسم أحد أقاربه أو صلة قرابته، استخدم هذه المعلومات لتقديم نصائح مخصصة.
إذا سأل عن نصيحة عامة، يمكنك الإشارة إلى الأقارب الذين يحتاجون اهتماماً.
```

Followed by the user's actual question in the user role:
```
{role: "user", content: "كيف أحافظ على صلة الرحم؟"}
```

Total estimated token count for production conversations with 6 relatives: ~600-800 input tokens + user message + history. With 20+ relatives the system message exceeds 1500 tokens.

### 6.3 What the model actually responded (captured screenshot)

The founder's screenshot showed أنيس's response started:
```
وعليكم السلام ورحمة الله وبركاته،
حفظك الله أخي الكريم.

للحفاظ على صلة الرحم، إليك بعض الخطوات العملية:

١. **المبادرة بالاتصال**: لا تنتظر المناسبات...
٢. **الزيارة ولو مرة**: احرص على زيارتهم...
...
```

Register check on this output:
- `وعليكم السلام ورحمة الله وبركاته` — formal religious MSA greeting
- `حفظك الله أخي الكريم` — formal MSA address
- `للحفاظ على صلة الرحم، إليك بعض الخطوات العملية` — neutral MSA
- Numbered list with bold headers — the AI invented this Markdown structure on its own

**The model is producing MSA, matching the DB instruction (`تتحدث بالعربية الفصحى`). It is NOT producing the Saudi colloquial that the hardcoded fallback teaches.** Confirms §1.2 contradiction is live.

In a parallel session the founder reported the AI saying `حبيت أسألك عن صلة الرحم` (the perspective-inversion bug) — not visible in this specific screenshot but documented earlier. See §10.

---

## Category 7 — Persona consistency

### 7.1 Result of grep `واصل` across prompt assets

| Location | Status |
|---|---|
| `lib/core/ai/ai_identity.dart` | ✅ Clean (only `defaultNameEn = 'Wasel'` — English transliteration, benign) |
| `lib/core/ai/ai_prompts.dart` | ⚠️ Forbidden-list still mentions `"واصل العائلة"` (line 1136) — wrapped-personality only |
| `lib/core/services/ai_config_service.dart` | ✅ Clean |
| `lib/core/services/ai_touch_point_service.dart` | ✅ Clean |
| `admin_ai_identity` (DB) | N/A (empty table) |
| `admin_ai_personality` (DB) | ✅ All 5 sections say أنيس |
| **`admin_ai_touch_points` (DB)** | 🚩 **Row `home/greeting` literally starts with `أنت واصل`** — Phase 6.1 leak |
| `admin_counseling_modes` (DB) | ✅ Clean (no persona name in mode_instructions) |
| `admin_communication_scenarios` (DB) | ✅ N/A (all `prompt_context` fields NULL) |
| `admin_message_occasions` (DB) | ✅ N/A (all `prompt_addition` fields NULL) |
| `supabase/functions/deepseek-proxy` | ✅ N/A (no persona content) |

**One critical leak: `admin_ai_touch_points/home/greeting`.** Every time the home screen renders the greeting touch-point, the AI is sent a prompt that starts `أنت واصل، مساعد صلة الرحم.` **The user is told the AI is `أنيس`, but the AI is told it is `واصل` for that touch-point.** This is a live identity inconsistency.

### 7.2 Identity-layer drift summary

| Component | Persona name |
|---|---|
| App UI ("أنيس") | أنيس |
| `AIIdentity.defaultName` | أنيس |
| `AIIdentity.defaultNameEn` | Wasel ⚠️ |
| `admin_ai_personality.base.content_ar` | أنيس ✅ |
| `admin_ai_touch_points.home.greeting.prompt_template` | واصل ❌ |
| `wrappedPersonalityPrompt` forbidden list | mentions "واصل العائلة" ⚠️ |

---

## Category 8 — Tone and register inventory

| Asset | Register | Notes |
|---|---|---|
| `admin_ai_personality.base` (PROD) | **Classical Arabic / فصحى** | Explicit: `تتحدث بالعربية الفصحى` |
| `admin_ai_personality.values` | Conversational MSA | Religious vocabulary, neutral tone |
| `admin_ai_personality.style` | Conversational MSA | "ودي ومحترم" — friendly + respectful |
| `admin_ai_personality.precision` | Conversational MSA | Plain editorial guidance |
| `admin_ai_personality.emotional` | Conversational MSA | Therapeutic register |
| `ai_identity.dart` _hardcoded fallback_ | **Saudi colloquial / عامية بيضاء** | `وش رايك`, `حاول تزوره هالأسبوع` |
| `ai_config_service.dart` _hardcoded fallback_ | **Saudi colloquial** | Same as above |
| `ai_prompts.dart::basePersonality` | **Saudi colloquial** | Same as above |
| `admin_ai_touch_points/home/greeting` | Saudi colloquial | `اجعل التحية دافئة وشخصية باللهجة السعودية` |
| `admin_ai_touch_points/home/insight` | Conversational MSA | No dialect instruction |
| `admin_ai_touch_points/home/priority_contacts` | Conversational MSA | No dialect instruction |
| `admin_ai_touch_points/relative_detail/health_explanation` | Conversational MSA | "بأسلوب ودي" |
| `admin_ai_touch_points/relative_detail/conversation_starters` | Conversational MSA | No dialect anchor |
| `admin_counseling_modes.*` (DB) | Conversational MSA | One-line each, no dialect |
| `getModeInstructions` _hardcoded fallback_ | Conversational MSA | Imperative bullets |
| `messageGenerationPrompt` | Mixed | Personality block injects whichever register loaded; tone modifier separate |
| `weeklyReportPrompt` | Conversational MSA | "أنت محلل علاقات عائلية" — formal frame |
| `relationshipAnalysisPrompt` | Conversational MSA | Analytical register |
| `wrappedPersonalityPrompt` | Mixed | Asks for "اللهجة السعودية أو العربية الفصحى الخفيفة" — explicitly hybrid |

**Internal contradiction documented in §1.2** is the dominant register-level finding: production says Fusha, fallback says Saudi colloquial, dialect-specific touch-points say Saudi colloquial. The model resolves the contradiction in favor of whatever instruction is loudest — currently Fusha (DB version is "louder" because it's the first declarative sentence).

---

## Category 9 — Output formatting instructions

### 9.1 Chat system prompt (production) — formatting rules sent to model

| Aspect | Status |
|---|---|
| Lists / numbered lists | ❌ Not instructed |
| Markdown allowed/required | ❌ Not instructed |
| Headers | ❌ Not instructed |
| Hadith citations format | ❌ Not instructed |
| Quranic citation format | ❌ Not instructed |
| Length cap / brevity | ⚠️ Section `precision` says "تجيب بإيجاز ووضوح" but no token/word target |
| Bold / emphasis | ❌ Not instructed |
| Use of emoji | ❌ Not instructed |
| Code blocks | ❌ Not instructed |

**The model is improvising every time.** When the founder's screenshot shows numbered lists with bold headers and hadith citations in italic — that's the model's default behavior for DeepSeek-chat, not anything we asked for. This is why the rendering is inconsistent across messages.

### 9.2 JSON-output prompts (message generation, analysis, etc.) — formatting rules

These are well-specified — every JSON-output prompt declares the exact schema and ends with `أعد JSON فقط` or similar. Good.

### 9.3 Touch-point prompts — formatting rules

| Touch point | Formatting instruction |
|---|---|
| `home/greeting` | "جملة واحدة فقط... لا تزيد عن 15 كلمة" ✅ |
| `home/priority_contacts` | "أجب بصيغة JSON: [...]" ✅ |
| `home/insight` | "جملة أو جملتين فقط" ✅ |
| `relative_detail/health_explanation` | "جملة أو جملتين تفسيرية" ✅ |
| `reminders/time_suggestion` | "جملة واحدة فقط" ✅ |
| `reminders/frequency_recommendation` | "تبرير قصير" — vague |
| `relative_detail/conversation_starters` | "3 مواضيع... كل موضوع في سطر منفصل، بدون ترقيم أو نقاط" ✅ |

Touch points are well-bounded. The chat surface is the unbounded one.

---

## Category 10 — Error-mode prevention

### 10.1 What's protected (chat system prompt — production via DB)

The DB version of the personality has **no explicit "do not" rules.** All five sections are positive descriptors ("you do X"). Zero prohibitions.

### 10.2 What's protected in the FALLBACK personality only

Lines 91-97 of `ai_prompts.dart` (`basePersonality`):
```
## قاعدة صارمة - الدقة المطلقة:
⚠️ لا تختلق أو تفترض أي معلومات غير موجودة في السياق.
⚠️ إذا لم تجد بيانات عن تواصل المستخدم، لا تدّعي أنه تواصل مع أحد.
⚠️ لا تقل "أرى أنك تواصلت" إلا إذا كانت البيانات موجودة فعلاً.
⚠️ إذا لم تكن متأكداً، اسأل المستخدم بدلاً من الافتراض.
⚠️ الصدق أهم من الظهور بمظهر المطّلع.
```

Lines 83-89:
```
## ما يجب تجنبه:
- الأحكام القاسية أو اللوم المباشر
- النصائح السطحية أو العامة جداً
- تشجيع القطيعة إلا في حالات الضرر الشديد
- الدخول في مواضيع فقهية معقدة (وجّه للعلماء)
- الردود الطويلة المملة - كن موجزاً ومركزاً
- تكرار نفس العبارات في كل رد
```

**These guards exist only in the fallback path.** When `admin_ai_personality` IS loaded (production), these guards are **NOT in the system prompt the model receives.** Contrast this with the DB content (§1.2) — there are zero "do not" instructions there.

### 10.3 Specific risks audit

| Risk | Protected in DB prompt? | Protected in fallback prompt? |
|---|---|---|
| Perspective inversion ("AI asks user instead of answering") | ❌ NO | ❌ NO (no rule like "do not phrase a question back to the user") |
| Fabricating relative names | ❌ NO | ✅ Partially — "لا تختلق أو تفترض" |
| Fabricating contact data | ❌ NO | ✅ Yes — explicit |
| Fabricated hadith citations | ❌ NO | ❌ NO |
| Medical / legal advice | ❌ NO | ❌ NO |
| Fiqh / scholarly disputes | ❌ NO | ✅ Partial — "وجّه للعلماء" |
| Encouraging قطيعة | ❌ NO | ✅ Yes — "تشجيع القطيعة إلا في حالات الضرر الشديد" |
| Role confusion (AI imagining itself as a different character) | ❌ NO | ❌ NO |
| Mirroring user's question instead of answering | ❌ NO | ❌ NO |

### 10.4 The "حبيت أسألك" perspective-inversion failure mode

The founder reported the AI responded with `حبيت أسألك عن صلة الرحم` ("I want to ask you about صلة الرحم") to a user question about صلة الرحم. This is a classic LLM mirroring failure. **Nothing in the production system prompt prevents this:**

- The persona block says "you are أنيس, you speak Fusha, you uphold Islamic values" — descriptive, not prescriptive.
- The mode instruction says "تحدث بشكل عام عن أي موضوع يتعلق بصلة الرحم والعلاقات الأسرية" — describes scope, not direction.
- There is no instruction like "أنت تجيب عن أسئلة المستخدم — لا تطرح أنت أسئلة بدلاً من إعطاء جواب" ("You answer the user's questions — do not pose questions instead of giving an answer").
- The "ما يجب تجنبه" list (only in fallback) doesn't include "do not mirror the user's question."

When the user message is short ("كيف أحافظ على صلة الرحم؟"), DeepSeek's default behavior is sometimes to engage conversationally rather than answer directly — and there is no anchor to prevent that. **The bug is a prompt-engineering deficit, not a code bug.**

---

## Section 11 — Surprises and observations

### 11.1 The DB-vs-fallback dialect contradiction is the single biggest finding

[admin_ai_personality.base](#12-adminaipersonality-5-rows--active) says **Classical Arabic / Fusha** (`تتحدث بالعربية الفصحى`). The hardcoded fallbacks in [ai_identity.dart:103](lib/core/ai/ai_identity.dart#L103), [ai_config_service.dart:357](lib/core/services/ai_config_service.dart#L357), and [ai_prompts.dart:43](lib/core/ai/ai_prompts.dart#L43) say **Saudi colloquial** (`تتحدث بالعامية السعودية البيضاء`). These are **mutually exclusive registers.** The same user gets different personas depending on whether `AIConfigService` finishes loading on cold start.

This is the answer to "why does the AI sometimes feel formal and sometimes feel casual." It isn't model temperature — it's prompt drift.

### 11.2 The `home/greeting` touch-point still calls the AI `واصل`

Phase 6.1 renamed `واصل → أنيس` in lib/ and `admin_ai_personality`. But [admin_ai_touch_points/home/greeting.prompt_template](#15-adminaitouchpoints-7-rows--all-active) was missed and still literally starts with `أنت واصل، مساعد صلة الرحم`. Every home-screen greeting is sent to DeepSeek under the wrong identity. The wrapped-personality forbidden list ([ai_prompts.dart:1136](lib/core/ai/ai_prompts.dart#L1136)) also still mentions `واصل العائلة`.

### 11.3 `buildEnhancedChatSystemPrompt` is dead code in the chat path

[buildEnhancedChatSystemPrompt](lib/core/ai/ai_prompts.dart#L282-L337) ingests the full `AIContext` (gamification, occasions, health summary, focus relative streak). **No production caller invokes it from the chat surface.** The chat surface uses [`buildChatSystemPrompt`](lib/core/ai/ai_prompts.dart#L243-L273), which receives `allRelatives` + `memories` but not `userFullName`, `streaks`, `upcomingOccasions`, or `totalInteractions`. Net effect: the user's name + their gamification data + their upcoming birthdays are **never sent to the chat model**, despite being fetched and cached by `AIContextEngine`.

### 11.4 Tokenization is unbounded

[`AIContextEngine.buildContext({tokenBudget: 2000})`](lib/core/ai/ai_context_engine.dart#L64) advertises a token budget. The parameter is **completely ignored** in the rest of the file. With 50 relatives the system prompt easily hits 3-4k tokens before the user message. DeepSeek-chat's effective context window handles it, but there's no guardrail and no prioritization (e.g., dropping low-priority distant relatives first).

### 11.5 `admin_ai_identity` is empty in production

The table exists with 11 columns including `dialect`, `personality_summary_ar`, `greeting_message_ar`, `ai_avatar_url` — and the entire table has zero rows. Every identity field comes from `AIIdentityConfig.fallback()`. **No admin can override identity from the dashboard** because there's nothing to override. The CMS-driven identity story is an unimplemented feature.

### 11.6 `admin_message_occasions.prompt_addition` and `admin_communication_scenarios.prompt_context` are NULL across the board

12 occasion rows + 6 scenario rows = 18 rows that should carry occasion-specific or scenario-specific prompt guidance. **All 18 fields are NULL.** The AI receives only the occasion key (`eid`, `ramadan`, etc.) or the scenario key (`reconnect`, `apology`, etc.) — no qualitative direction. This means a "تهنئة برمضان" message and a "تهنئة بزواج" message both get identical guidance from the DB. The variety comes entirely from the occasion key string + the personality + the relative metadata.

### 11.7 The model is improvising all formatting

No prompt instructs the AI to use Markdown, numbered lists, blockquotes for hadiths, etc. The response in the founder's screenshot — bold headers, numbered list, hadith pull-quote — is DeepSeek-chat's default Arabic-content rendering. This is why messages render inconsistently across turns: same model, no anchor, output drifts. Phase β's UI added pull-quote rendering for blockquotes and rich list rendering — but the markdown styles file is interpreting whatever the model decides to emit, not what we asked it to emit.

### 11.8 Unsubstituted placeholders in touch-point prompts

[ai_touch_point_service.dart](lib/core/services/ai_touch_point_service.dart) substitutes ~20 placeholders. The DB row `reminders/time_suggestion` references `{{contact_times}}` and `{{preferred_time}}` — **neither is in the substitution code.** The model receives the literal text `{{contact_times}}` in its prompt. Probably degrades the suggestion quality silently. Likely true for any other DB touch-point that drifts ahead of the substitution code.

### 11.9 The "perspective inversion" bug has no prompt-side guard

There is no instruction anywhere in the production prompt that says "answer the user's question; do not mirror it back." The fallback's "Strict accuracy rules" don't cover this — they're about fabricating data, not about role direction. The bug is a prompt-engineering gap and will continue to surface until γ.2 adds a directive like:

```
أنت تجيب عن سؤال المستخدم بشكل مباشر.
لا تردّ على سؤاله بسؤال آخر بنفس الموضوع.
لا تقل "حبيت أسألك عن X" عندما يكون X هو ما سألك عنه المستخدم.
ابدأ ردك بالسلام أو دعاء قصير، ثم انتقل مباشرة إلى الإجابة.
```

(Drafted as illustration — γ.2 should design the actual phrasing.)

### 11.10 The DB-shipped mode instructions are *too brief*

`admin_counseling_modes.mode_instructions` is one sentence per mode. The hardcoded `getModeInstructions` (fallback only) provides 4-6 specific behavioral rules per mode. Production gets the one-liner. **The DB content was migrated as a rough draft and never expanded back to match the rich fallback.** When section `precision` says "you answer concisely" and the mode says "talk generally about family ties" — the model has very little to anchor to. Hence the variability.

### 11.11 Two duplicated personalities in the codebase

[`AIIdentity._fallbackPersonality`](lib/core/ai/ai_identity.dart#L97-L119) and [`AIConfigService._hardcodedPersonality`](lib/core/services/ai_config_service.dart#L353-L374) hold near-identical Saudi colloquial blocks. Either is fine alone, but two means future edits will drift. They were probably split in different phases without consolidation.

### 11.12 Memory extraction is the most thoughtfully prompted feature

The memory extraction prompt explicitly:
- Lists negative examples (skip relative facts)
- Lists positive examples (extract preferences, dates, insights)
- Has structured JSON output
- Has a strict importance rubric
- Excludes `relative_fact` category from auto-extraction (data already in the relatives table)

It also has rich admin-config support (skip-keywords, skip-relative-facts toggle, custom extraction rules). And it's **disabled at the call site** ([ai_chat_provider.dart:486](lib/features/ai_assistant/providers/ai_chat_provider.dart#L486)) because the Memory Viewer was deleted in Phase 0 and "collecting without surfacing is privacy debt." So the most thoughtful prompt in the codebase is dormant.

### 11.13 The chat surface never gives the AI the user's name

[`AIContextEngine`](lib/core/ai/ai_context_engine.dart#L109-L120) fetches `users.full_name` and caches it. [`AIContext.toPromptSummary`](lib/core/ai/ai_context_engine.dart#L418-L477) embeds it. [`buildEnhancedChatSystemPrompt`](lib/core/ai/ai_prompts.dart#L282-L337) would include it (via `AIContext`). But the actual chat caller uses `buildChatSystemPrompt` which doesn't take an `AIContext` and never receives the name. **Every conversation starts with the AI not knowing who it's talking to.** The persona greeting block in the chat UI says "أنيس / محادثة عامة" — there's no equivalent for the user. Address-by-name personalization is completely absent.

### 11.14 Suggested prompts in the DB are different from the suggested prompts in the Dart fallback

[admin_suggested_prompts](#17-adminsuggestedprompts-16-rows) has 16 rows. [`AISuggestedPrompt.fallbackPrompts()`](lib/core/services/ai_config_service.dart#L735-L747) has 9 entries. They overlap significantly but differ in content — `relationship` mode in DB has prompts about parents and siblings, the fallback has only "كيف أحسن علاقتي بوالديّ؟" and "كيف أتقرب من أقاربي؟". Drift between the two.

### 11.15 The proxy is a pure passthrough — strong design choice

`deepseek-proxy` does not transform anything about the prompt. This is the cleanest architectural decision in the AI stack: prompt design lives in one place (the Dart app), and every change is reviewable in code review. **CTO should preserve this for γ.2.** Putting prompt logic in the proxy is a common antipattern that fragments the prompt across deploy boundaries.

### 11.16 No "do not impersonate the user" rule

A subtle relative of the perspective-inversion bug: nothing prevents the AI from generating responses that *speak as the user* (e.g., "I should call my dad today" — first person from the user's POV instead of "you should call your dad" from the assistant's POV). Was not observed in the founder's screenshot but is unprotected.

### 11.17 The forbidden-titles list in `wrappedPersonalityPrompt` is the only "negative few-shot" in the codebase

Listing forbidden titles ([ai_prompts.dart:1130-1138](lib/core/ai/ai_prompts.dart#L1130-L1138)) is a smart prompt-engineering pattern. It's used nowhere else. Could be extended to chat: "do not use these patterns: [list]."

### 11.18 The streaming infrastructure is fine; the prompt is not

Phase β instrumented client-side paced rendering and a streaming cursor. The actual stream content quality is governed by the prompt — and the prompt is what we just inventoried. A streaming animation can't compensate for a model that produces "حبيت أسألك" instead of an answer.

---

## Files / sources cited

### Code
```
lib/core/ai/ai_identity.dart                        identity + fallback personality (Saudi colloquial)
lib/core/ai/ai_models.dart                          enums, data models, no prompt content
lib/core/ai/ai_prompts.dart                         master prompt library (1145 lines)
lib/core/ai/ai_service.dart                         interface
lib/core/ai/deepseek_ai_service.dart                client + MockAIService hardcoded responses
lib/core/ai/ai_context_engine.dart                  context assembly (530 lines)
lib/core/services/ai_config_service.dart            admin-config loader + 2nd hardcoded personality
lib/core/services/ai_touch_point_service.dart       touch-point dispatcher + placeholder substitution
lib/features/ai_assistant/providers/ai_chat_provider.dart   chat state notifier (uses buildChatSystemPrompt)
```

### Edge functions
```
supabase/functions/deepseek-proxy/index.ts          pure passthrough; model: deepseek-chat
```

### Database tables (rows)
```
admin_ai_identity                  0   (empty)
admin_ai_personality               5
admin_ai_parameters                6
admin_ai_streaming_config          1
admin_ai_touch_points              7   (1 of 7 still uses "واصل")
admin_ai_error_messages           10
admin_counseling_modes             4
admin_suggested_prompts           16
admin_communication_scenarios      6   (all prompt_context NULL)
admin_message_occasions           12   (all prompt_addition NULL)
admin_message_tones                4
```

### Logs
```
get_logs(edge-function) — last hour, 100 entries
   - 0 deepseek-proxy invocations captured
   - logs expose method/URL/status/latency only; no request bodies
```

---

## Closing

This inventory is the ground truth γ.2 needs to design from. The dominant design issues are: (a) register inconsistency between DB and code (Fusha vs. Saudi colloquial), (b) Phase 6.1 leak in `admin_ai_touch_points/home/greeting`, (c) zero negative-rule guardrails in production prompt, (d) brittle DB-resident mode instructions vs. richer hardcoded fallback that never ships, (e) absent token budget enforcement, (f) absent formatting instructions, and (g) the user's name is never sent to the chat model.

@CTO — ready for γ.2 prompt rewrite spec.
