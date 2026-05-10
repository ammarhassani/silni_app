import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

// Helper to verify admin authentication
async function verifyAdminAuth(): Promise<{ authorized: boolean; error?: string }> {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    return { authorized: false, error: "Unauthorized - authentication required" };
  }

  const { data: profile } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", user.id)
    .single();

  if (profile?.role !== "admin") {
    return { authorized: false, error: "Forbidden - admin access required" };
  }

  return { authorized: true };
}

// --- Types ---

interface GenerateRequest {
  contentType: string;
  platform: "twitter" | "instagram" | "both";
  batchSize: number;
  dateRange: { start: string; end: string };
  tone: string;
  occasion?: string;
  skipCoveredDays?: boolean;
}

interface GeneratedPost {
  text_ar: string;
  text_en: string;
  hashtags: string[];
  suggested_time: string;
  image_prompt: string;
}

interface BrandVoice {
  tone_guidelines: string;
  banned_words: string[];
  hashtag_sets: Record<string, string[]>;
  arabic_dialect: string;
}

interface SocialTemplate {
  name: string;
  text_template: string;
  default_hashtags: string[];
  platform: string;
}

// --- Mock response for development ---

function generateMockPosts(req: GenerateRequest): GeneratedPost[] {
  const startDate = new Date(req.dateRange.start);
  const posts: GeneratedPost[] = [];

  const sampleTexts: Record<string, { ar: string; en: string }> = {
    hadith: {
      ar: "قال رسول الله ﷺ: «صلوا أرحامكم فإن صلة الرحم تزيد في العمر وتوسع في الرزق»",
      en: "The Prophet (PBUH) said: 'Maintain your family ties, for it increases your lifespan and expands your provision.'",
    },
    quran: {
      ar: "﴿وَاتَّقُوا اللَّهَ الَّذِي تَسَاءَلُونَ بِهِ وَالْأَرْحَامَ﴾ - النساء: 1",
      en: "\"And fear Allah, through whom you ask one another, and the wombs.\" - An-Nisa: 1",
    },
    family_tip: {
      ar: "نصيحة اليوم: خصص وقتاً أسبوعياً للتواصل مع أقاربك. مكالمة قصيرة تصنع فرقاً كبيراً في حياتهم وحياتك.",
      en: "Today's tip: Set aside weekly time to connect with your relatives. A short call makes a huge difference.",
    },
    feature: {
      ar: "مع تطبيق صِلني، تابع صلة أرحامك بذكاء. نظام التذكيرات الذكي يساعدك على عدم نسيان أحبائك.",
      en: "With Silni app, maintain your family ties smartly. Our smart reminder system helps you never forget your loved ones.",
    },
    update: {
      ar: "تحديث جديد في صِلني! أضفنا خاصية تتبع المناسبات العائلية لتكون دائماً على تواصل.",
      en: "New update in Silni! We added family occasion tracking to keep you always connected.",
    },
    cta: {
      ar: "حمّل تطبيق صِلني الآن وابدأ رحلة صلة الرحم. متوفر على iOS و Android مجاناً!",
      en: "Download Silni now and start your family connection journey. Available on iOS and Android for free!",
    },
    occasion: {
      ar: "بمناسبة قدوم شهر رمضان المبارك، لا تنسَ صلة أرحامك. صِلني يذكرك بمن تحب.",
      en: "As Ramadan approaches, don't forget your family ties. Silni reminds you of those you love.",
    },
  };

  const sample = sampleTexts[req.contentType] || sampleTexts.family_tip;

  for (let i = 0; i < req.batchSize; i++) {
    const postDate = new Date(startDate);
    postDate.setDate(postDate.getDate() + i);
    postDate.setHours(9 + (i % 12), 0, 0, 0);

    if (req.platform === "both") {
      posts.push({
        text_ar: sample.ar,
        text_en: sample.en,
        hashtags: [],
        suggested_time: postDate.toISOString(),
        image_prompt: `Islamic geometric pattern background with warm gold tones, featuring Arabic calligraphy about ${req.contentType} and family connections`,
      });
    } else {
      posts.push({
        text_ar: req.platform === "twitter" && sample.ar.length > 250
          ? sample.ar.slice(0, 250) + "..."
          : sample.ar,
        text_en: sample.en,
        hashtags: [],
        suggested_time: postDate.toISOString(),
        image_prompt: `Islamic geometric pattern background with warm gold tones, featuring Arabic calligraphy about ${req.contentType} and family connections`,
      });
    }
  }

  return posts;
}

// --- Build system prompt ---

function buildSystemPrompt(
  brandVoice: BrandVoice | null,
  templates: SocialTemplate[],
  platform: string,
  tone: string,
  occasion?: string,
): string {
  let prompt = `You are a social media content creator for "Silni" (صِلني), a mobile app that helps Muslims maintain family relationships (صلة الرحم).\n\n`;

  prompt += `## App Features (ONLY reference these — do NOT invent features)\n`;
  prompt += `### Free Features:\n`;
  prompt += `- تذكيرات للتواصل مع الأقارب (reminders to contact relatives — 1 free, unlimited with MAX)\n`;
  prompt += `- شجرة العائلة التفاعلية مع التكبير والتصغير (interactive pan-and-zoom family tree)\n`;
  prompt += `- تسجيل التواصل: مكالمات، رسائل، زيارات (log interactions: calls, messages, visits)\n`;
  prompt += `- سلاسل الصلة — streaks للحفاظ على التواصل المستمر مع تجميد الأيام (connection streaks with freeze protection)\n`;
  prompt += `- نقاط ومستويات وأوسمة — نظام تحفيزي (points, levels, badges — gamification system)\n`;
  prompt += `- مجموعات عائلية مع شجرة مشتركة ولوحة متصدرين (family groups with shared tree & leaderboard)\n`;
  prompt += `- أحاديث نبوية يومية على الشاشة الرئيسية (daily hadiths on home screen)\n`;
  prompt += `- تقارير سنوية وشهرية — ملخص تواصلك مع عائلتك (annual & monthly wrapped reports)\n`;
  prompt += `- استيراد جهات الاتصال من الجوال (import contacts from phone)\n`;
  prompt += `### MAX (Premium) Features:\n`;
  prompt += `- مركز أنيس — محادثة ذكية مع AI عن علاقاتك العائلية (AI chat about family relationships)\n`;
  prompt += `- محرر رسائل ذكي — AI يكتب لك رسائل مخصصة لكل قريب (AI message composer for each relative)\n`;
  prompt += `- تحليل العلاقات — تقييم قوة العلاقة مع كل قريب (relationship strength analysis)\n`;
  prompt += `- تقارير أسبوعية ذكية (AI weekly reports)\n`;
  prompt += `- رسائل مناسبات — تهاني عيد وتهاني مخصصة بالذكاء الاصطناعي (AI occasion messages)\n`;
  prompt += `- تذكيرات غير محدودة (unlimited reminders)\n`;
  prompt += `### General:\n`;
  prompt += `- متوفر على iOS و Android مجاناً\n`;
  prompt += `IMPORTANT: When promoting the app (format F), ONLY mention features listed above. NEVER make up features like plate sharing, group organization tools, or features that don't exist.\n\n`;

  if (brandVoice) {
    prompt += `## Brand Voice\n`;
    prompt += `- Tone: ${brandVoice.tone_guidelines}\n`;
    prompt += `- Dialect: ${brandVoice.arabic_dialect === "msa" ? "Modern Standard Arabic (فصحى)" : brandVoice.arabic_dialect === "colloquial" ? "Colloquial Arabic (عامية)" : "Mix of MSA and colloquial"}\n`;

    if (brandVoice.banned_words.length > 0) {
      prompt += `- NEVER use these words: ${brandVoice.banned_words.join(", ")}\n`;
    }
  }

  if (templates.length > 0) {
    prompt += `\n## Reference Templates (for style inspiration only)\n`;
    for (const t of templates) {
      prompt += `- ${t.name}: "${t.text_template}"\n`;
    }
  }

  if (occasion) {
    prompt += `\n## Occasion Context\n`;
    prompt += `${occasion}\n`;
    prompt += `\nIMPORTANT: Use the themes and emotional angles above. Each post MUST use a DIFFERENT theme or angle. Cycle through ALL of them before repeating any.\n`;
  }

  prompt += `\n## Content Rules\n`;
  prompt += `- Desired tone: ${tone}\n`;
  prompt += `- Do NOT include any hashtags\n`;
  prompt += `- Do NOT start every post the same way\n`;
  prompt += `- Use different emojis across posts — never repeat the same emoji in consecutive posts\n`;
  prompt += `\n## MANDATORY Format Rotation\n`;
  prompt += `You MUST cycle through these 6 formats in order. Post 1 uses format A, post 2 uses format B, etc. After format F, restart from A.\n`;
  prompt += `A) حكمة/اقتباس — Start with a hadith, Quran verse, or Arab proverb. Then a brief reflection.\n`;
  prompt += `B) نصيحة عملية — A concrete, actionable family tip. Use imperative verbs (اتصل، زُر، أرسل).\n`;
  prompt += `C) سؤال تفاعلي — An engaging question that sparks discussion. Keep it short.\n`;
  prompt += `D) قصة/مشهد — Paint a vivid 2-3 sentence scenario (e.g., "تخيل أنك..." or "في بيت جدتي...").\n`;
  prompt += `E) تأمل/خاطرة — A personal-feeling reflection or observation. Introspective, emotional.\n`;
  prompt += `F) دعوة للتطبيق — Directly promote Silni app with a specific feature or benefit. Include app name.\n`;

  if (platform === "twitter") {
    prompt += `- Platform: Twitter/X — each text_ar MUST be ≤280 characters\n`;
  } else if (platform === "instagram") {
    prompt += `- Platform: Instagram — longer text OK (up to 2200 chars), be descriptive\n`;
  } else {
    prompt += `- Platform: Both Twitter and Instagram\n`;
    prompt += `- Twitter versions: text_ar ≤280 chars. Instagram versions: longer, more descriptive.\n`;
  }

  prompt += `\n## Output Format\n`;
  prompt += `Respond with a JSON array ONLY. Each element:\n`;
  prompt += `- "text_ar": Arabic post text (NO hashtags)\n`;
  prompt += `- "text_en": English translation\n`;
  prompt += `- "suggested_time": ISO 8601 datetime\n`;
  prompt += `- "image_prompt": English prompt for AI image generation\n`;

  return prompt;
}

// --- POST handler ---

export async function POST(request: NextRequest) {
  const authResult = await verifyAdminAuth();
  if (!authResult.authorized) {
    return NextResponse.json(
      { error: authResult.error },
      { status: authResult.error?.includes("Forbidden") ? 403 : 401 },
    );
  }

  let body: GenerateRequest;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json(
      { error: "Invalid JSON body" },
      { status: 400 },
    );
  }

  const { contentType, platform, batchSize, dateRange, tone, occasion, skipCoveredDays } = body;

  if (!contentType || !platform || !batchSize || !dateRange?.start || !dateRange?.end || !tone) {
    return NextResponse.json(
      { error: "Missing required fields: contentType, platform, batchSize, dateRange (start, end), tone" },
      { status: 400 },
    );
  }

  if (batchSize < 1 || batchSize > 30) {
    return NextResponse.json(
      { error: "batchSize must be between 1 and 30" },
      { status: 400 },
    );
  }

  const apiKey = process.env.DEEPSEEK_API_KEY;

  if (!apiKey) {
    const mockPosts = generateMockPosts(body);
    return NextResponse.json({ posts: mockPosts, mock: true });
  }

  try {
    const supabase = createClient();

    const [brandVoiceResult, templatesResult] = await Promise.all([
      supabase
        .from("social_brand_voice")
        .select("tone_guidelines, banned_words, hashtag_sets, arabic_dialect")
        .eq("is_active", true)
        .single(),
      supabase
        .from("social_templates")
        .select("name, text_template, default_hashtags, platform")
        .eq("content_type", contentType)
        .eq("is_active", true),
    ]);

    const brandVoice: BrandVoice | null = brandVoiceResult.data as BrandVoice | null;
    const templates: SocialTemplate[] = (templatesResult.data as SocialTemplate[]) || [];

    // Build list of target dates (uncovered dates in range)
    const allDatesInRange: string[] = [];
    const rangeStart = new Date(dateRange.start);
    const rangeEnd = new Date(dateRange.end);
    for (let d = new Date(rangeStart); d <= rangeEnd; d.setDate(d.getDate() + 1)) {
      allDatesInRange.push(d.toISOString().split("T")[0]);
    }

    let targetDates = allDatesInRange;

    if (skipCoveredDays) {
      const { data: existingPosts } = await supabase
        .from("social_posts")
        .select("scheduled_at")
        .in("status", ["queued", "approved", "scheduled", "published"])
        .gte("scheduled_at", `${dateRange.start}T00:00:00`)
        .lte("scheduled_at", `${dateRange.end}T23:59:59`);

      if (existingPosts && existingPosts.length > 0) {
        const coveredSet = new Set<string>();
        for (const p of existingPosts) {
          if (p.scheduled_at) {
            coveredSet.add(p.scheduled_at.split("T")[0]);
          }
        }
        targetDates = allDatesInRange.filter((d) => !coveredSet.has(d));
      }
    }

    // Cap batch size to available dates
    const effectiveBatchSize = Math.min(batchSize, targetDates.length);

    if (effectiveBatchSize === 0) {
      return NextResponse.json(
        { error: "جميع الأيام في النطاق المحدد لديها منشورات بالفعل" },
        { status: 400 },
      );
    }

    const systemPrompt = buildSystemPrompt(brandVoice, templates, platform, tone, occasion);

    let userMessage = `Generate exactly ${effectiveBatchSize} posts about "${contentType}".`;
    if (occasion) {
      userMessage += `\n\nUse the occasion themes from the system prompt. Spread them evenly — each post should use a different theme.`;
    }
    userMessage += `\n\nREMINDER: Follow the A-B-C-D-E-F format rotation strictly. Post 1=A (quote), Post 2=B (tip), Post 3=C (question), Post 4=D (story), Post 5=E (reflection), Post 6=F (app promo), Post 7=A again, etc.`;
    if (platform === "both") {
      userMessage += `\nGenerate two versions per concept: Twitter (≤280 chars) and Instagram (longer). Total: ${effectiveBatchSize * 2} posts.`;
    }

    const deepseekResponse = await fetch("https://api.deepseek.com/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "deepseek-chat",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userMessage },
        ],
        temperature: 1.0,
        max_tokens: 8192,
        response_format: { type: "json_object" },
      }),
    });

    if (!deepseekResponse.ok) {
      const errorText = await deepseekResponse.text();
      console.error("DeepSeek API error:", deepseekResponse.status, errorText);
      return NextResponse.json(
        { error: `DeepSeek API error: ${deepseekResponse.status}` },
        { status: 502 },
      );
    }

    const deepseekData = await deepseekResponse.json();
    const content = deepseekData.choices?.[0]?.message?.content;

    if (!content) {
      return NextResponse.json(
        { error: "No content returned from DeepSeek API" },
        { status: 502 },
      );
    }

    let posts: GeneratedPost[];
    try {
      // Strip markdown code fences if present (```json ... ```)
      let jsonStr = content.trim();
      const fenceMatch = jsonStr.match(/```(?:json)?\s*([\s\S]*?)```/);
      if (fenceMatch) {
        jsonStr = fenceMatch[1].trim();
      }
      const parsed = JSON.parse(jsonStr);
      posts = Array.isArray(parsed) ? parsed : (parsed.posts || parsed.data || []);
    } catch {
      console.error("Failed to parse DeepSeek response:", content.slice(0, 500));
      return NextResponse.json(
        { error: "Failed to parse AI response as JSON" },
        { status: 502 },
      );
    }

    // Assign dates from targetDates (don't trust AI's suggested_time)
    const timeSlots = [9, 12, 15, 18, 21]; // varied posting hours
    const validatedPosts: GeneratedPost[] = posts
      .slice(0, effectiveBatchSize)
      .map((post, i) => {
        const dateStr = targetDates[i % targetDates.length];
        const hour = timeSlots[i % timeSlots.length];
        return {
          text_ar: post.text_ar || "",
          text_en: post.text_en || "",
          hashtags: [],
          suggested_time: `${dateStr}T${String(hour).padStart(2, "0")}:00:00.000Z`,
          image_prompt: post.image_prompt || "",
        };
      });

    return NextResponse.json({ posts: validatedPosts, mock: false });
  } catch (error) {
    console.error("Social generate error:", error);
    return NextResponse.json(
      { error: error instanceof Error ? error.message : "Failed to generate content" },
      { status: 500 },
    );
  }
}
