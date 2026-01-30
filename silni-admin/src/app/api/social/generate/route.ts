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
        hashtags: ["#صلني", "#صلة_الرحم", "#عائلة"],
        suggested_time: postDate.toISOString(),
        image_prompt: `Islamic geometric pattern background with warm gold tones, featuring Arabic calligraphy about ${req.contentType} and family connections`,
      });
    } else {
      posts.push({
        text_ar: req.platform === "twitter" && sample.ar.length > 250
          ? sample.ar.slice(0, 250) + "..."
          : sample.ar,
        text_en: sample.en,
        hashtags: req.platform === "instagram"
          ? ["#صلني", "#صلة_الرحم", "#عائلة", "#تواصل", "#رحم", "#إسلام"]
          : ["#صلني", "#صلة_الرحم", "#عائلة"],
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
  let prompt = `You are a social media content creator for "Silni" (صِلني), a mobile app that helps Muslims maintain family relationships (صلة الرحم). Generate social media posts in Arabic and English.\n\n`;

  if (brandVoice) {
    prompt += `## Brand Voice Guidelines\n`;
    prompt += `- Tone guidelines: ${brandVoice.tone_guidelines}\n`;
    prompt += `- Arabic dialect: ${brandVoice.arabic_dialect === "msa" ? "Modern Standard Arabic (فصحى)" : brandVoice.arabic_dialect === "colloquial" ? "Colloquial Arabic (عامية)" : "Mix of MSA and colloquial"}\n`;

    if (brandVoice.banned_words.length > 0) {
      prompt += `- NEVER use these words: ${brandVoice.banned_words.join(", ")}\n`;
    }

    const hashtagSets = brandVoice.hashtag_sets;
    if (hashtagSets && Object.keys(hashtagSets).length > 0) {
      prompt += `- Available hashtag sets:\n`;
      for (const [setName, tags] of Object.entries(hashtagSets)) {
        prompt += `  - ${setName}: ${tags.join(", ")}\n`;
      }
    }
  }

  if (templates.length > 0) {
    prompt += `\n## Reference Templates\nUse these as inspiration for style and structure:\n`;
    for (const t of templates) {
      prompt += `- ${t.name}: "${t.text_template}" (hashtags: ${(t.default_hashtags || []).join(", ")})\n`;
    }
  }

  prompt += `\n## Content Requirements\n`;
  prompt += `- Desired tone: ${tone}\n`;

  if (occasion) {
    prompt += `- Occasion/context: ${occasion}\n`;
  }

  if (platform === "twitter") {
    prompt += `- Platform: Twitter/X\n`;
    prompt += `- IMPORTANT: Each Arabic text (text_ar) MUST be 280 characters or less including hashtags\n`;
    prompt += `- Keep posts concise and impactful\n`;
  } else if (platform === "instagram") {
    prompt += `- Platform: Instagram\n`;
    prompt += `- Longer text is acceptable (up to 2200 characters)\n`;
    prompt += `- Include more hashtags (8-15 recommended)\n`;
    prompt += `- Text can be more descriptive and storytelling-oriented\n`;
  } else {
    prompt += `- Platform: Both Twitter and Instagram\n`;
    prompt += `- For Twitter versions: text_ar MUST be 280 characters or less\n`;
    prompt += `- For Instagram versions: text can be longer with more hashtags\n`;
  }

  prompt += `\n## Output Format\n`;
  prompt += `Respond with a JSON array ONLY (no other text). Each element must have:\n`;
  prompt += `- "text_ar": Arabic post text\n`;
  prompt += `- "text_en": English translation of the post\n`;
  prompt += `- "hashtags": array of hashtag strings (include # prefix)\n`;
  prompt += `- "suggested_time": ISO 8601 datetime string for optimal posting time\n`;
  prompt += `- "image_prompt": English prompt for AI image generation describing the ideal visual for this post\n`;

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

  const { contentType, platform, batchSize, dateRange, tone, occasion } = body;

  if (!contentType || !platform || !batchSize || !dateRange?.start || !dateRange?.end || !tone) {
    return NextResponse.json(
      { error: "Missing required fields: contentType, platform, batchSize, dateRange (start, end), tone" },
      { status: 400 },
    );
  }

  if (batchSize < 1 || batchSize > 14) {
    return NextResponse.json(
      { error: "batchSize must be between 1 and 14" },
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

    const systemPrompt = buildSystemPrompt(brandVoice, templates, platform, tone, occasion);

    let userMessage = `Generate ${batchSize} social media posts about "${contentType}" content.`;
    userMessage += ` The posts should be scheduled between ${dateRange.start} and ${dateRange.end}.`;
    if (occasion) {
      userMessage += ` The occasion is: ${occasion}.`;
    }
    if (platform === "both") {
      userMessage += ` Generate two versions per concept: one for Twitter (short, <=280 chars) and one for Instagram (longer, more hashtags). Total output should be ${batchSize * 2} posts.`;
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
        temperature: 0.8,
        max_tokens: 4096,
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
      const parsed = JSON.parse(content);
      posts = Array.isArray(parsed) ? parsed : (parsed.posts || parsed.data || []);
    } catch {
      console.error("Failed to parse DeepSeek response:", content);
      return NextResponse.json(
        { error: "Failed to parse AI response as JSON" },
        { status: 502 },
      );
    }

    const validatedPosts: GeneratedPost[] = posts.map((post) => ({
      text_ar: post.text_ar || "",
      text_en: post.text_en || "",
      hashtags: Array.isArray(post.hashtags) ? post.hashtags : [],
      suggested_time: post.suggested_time || new Date().toISOString(),
      image_prompt: post.image_prompt || "",
    }));

    return NextResponse.json({ posts: validatedPosts, mock: false });
  } catch (error) {
    console.error("Social generate error:", error);
    return NextResponse.json(
      { error: error instanceof Error ? error.message : "Failed to generate content" },
      { status: 500 },
    );
  }
}
