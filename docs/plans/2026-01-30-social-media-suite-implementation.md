# Social Media Suite Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a full social media marketing suite in the Silni admin panel with AI content generation, review queue, scheduling calendar, direct publishing to Twitter/X and Instagram, and engagement analytics with conversion tracking.

**Architecture:** New `/social` route group with 5 pages (generate, calendar, accounts, analytics, templates). Data stored in 5 new Supabase tables. Publishing handled by Edge Functions on cron. OAuth flows via Next.js API routes. AI generation via DeepSeek.

**Tech Stack:** Next.js 14 App Router, shadcn/ui, React Query, Recharts, Supabase (PostgreSQL + Edge Functions + pgcrypto), DeepSeek API, Twitter API v2, Instagram Graph API.

**Design Doc:** `docs/plans/2026-01-30-social-media-suite-design.md`

---

## Task 1: Database Migration — Create Social Media Tables

**Files:**
- Create: `supabase/migrations/20260130100000_create_social_media_tables.sql`

**Step 1: Write the migration SQL**

```sql
-- Enable pgcrypto for token encryption
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Social accounts (connected Twitter/Instagram)
CREATE TABLE social_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  platform TEXT NOT NULL CHECK (platform IN ('twitter', 'instagram')),
  account_name TEXT NOT NULL,
  account_handle TEXT NOT NULL,
  access_token_encrypted TEXT NOT NULL,
  refresh_token_encrypted TEXT,
  token_expires_at TIMESTAMPTZ,
  scopes TEXT[],
  platform_user_id TEXT,
  status TEXT NOT NULL DEFAULT 'connected' CHECK (status IN ('connected', 'expired', 'disconnected')),
  last_post_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Social campaigns (group posts for tracking)
CREATE TABLE social_campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  utm_campaign TEXT NOT NULL UNIQUE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Social templates (reusable post structures)
CREATE TABLE social_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  content_type TEXT NOT NULL CHECK (content_type IN ('hadith', 'quran', 'family_tip', 'feature', 'update', 'cta', 'occasion')),
  platform TEXT NOT NULL CHECK (platform IN ('twitter', 'instagram', 'both')),
  text_template TEXT NOT NULL,
  default_hashtags TEXT[],
  default_tone TEXT CHECK (default_tone IN ('inspirational', 'educational', 'conversational', 'promotional')),
  is_recurring BOOLEAN DEFAULT false,
  recurring_schedule JSONB,
  tags TEXT[],
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Brand voice config (singleton-ish, one active row)
CREATE TABLE social_brand_voice (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tone_guidelines TEXT NOT NULL DEFAULT '',
  arabic_dialect TEXT NOT NULL DEFAULT 'msa' CHECK (arabic_dialect IN ('msa', 'colloquial', 'mix')),
  hashtag_sets JSONB DEFAULT '{}',
  banned_words TEXT[],
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Social posts (the core table)
CREATE TABLE social_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  platform TEXT NOT NULL CHECK (platform IN ('twitter', 'instagram')),
  content_type TEXT NOT NULL CHECK (content_type IN ('hadith', 'quran', 'family_tip', 'feature', 'update', 'cta', 'occasion')),
  text_ar TEXT NOT NULL,
  text_en TEXT,
  hashtags TEXT[],
  image_prompt TEXT,
  image_url TEXT,
  utm_link TEXT,
  tone TEXT CHECK (tone IN ('inspirational', 'educational', 'conversational', 'promotional')),
  status TEXT NOT NULL DEFAULT 'queued' CHECK (status IN ('draft', 'queued', 'approved', 'scheduled', 'published', 'failed', 'rejected')),
  scheduled_at TIMESTAMPTZ,
  published_at TIMESTAMPTZ,
  platform_post_id TEXT,
  platform_post_url TEXT,
  error_message TEXT,
  campaign_id UUID REFERENCES social_campaigns(id),
  template_id UUID REFERENCES social_templates(id),
  account_id UUID REFERENCES social_accounts(id),
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Social analytics (per-post engagement snapshots)
CREATE TABLE social_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES social_posts(id) ON DELETE CASCADE,
  likes INTEGER DEFAULT 0,
  comments INTEGER DEFAULT 0,
  shares INTEGER DEFAULT 0,
  impressions INTEGER DEFAULT 0,
  link_clicks INTEGER DEFAULT 0,
  snapshot_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Click tracking for UTM links
CREATE TABLE social_click_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID REFERENCES social_posts(id) ON DELETE SET NULL,
  utm_source TEXT,
  utm_medium TEXT,
  utm_campaign TEXT,
  utm_content TEXT,
  user_agent TEXT,
  ip_hash TEXT,
  clicked_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_social_posts_status ON social_posts(status);
CREATE INDEX idx_social_posts_scheduled ON social_posts(scheduled_at) WHERE status = 'scheduled';
CREATE INDEX idx_social_posts_platform ON social_posts(platform);
CREATE INDEX idx_social_posts_campaign ON social_posts(campaign_id);
CREATE INDEX idx_social_analytics_post ON social_analytics(post_id);
CREATE INDEX idx_social_analytics_snapshot ON social_analytics(snapshot_at);
CREATE INDEX idx_social_click_log_post ON social_click_log(post_id);
CREATE INDEX idx_social_click_log_campaign ON social_click_log(utm_campaign);
CREATE INDEX idx_social_accounts_platform ON social_accounts(platform);

-- Updated_at triggers
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER social_accounts_updated_at BEFORE UPDATE ON social_accounts FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER social_campaigns_updated_at BEFORE UPDATE ON social_campaigns FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER social_templates_updated_at BEFORE UPDATE ON social_templates FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER social_brand_voice_updated_at BEFORE UPDATE ON social_brand_voice FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER social_posts_updated_at BEFORE UPDATE ON social_posts FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- RLS policies (admin only)
ALTER TABLE social_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_brand_voice ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_click_log ENABLE ROW LEVEL SECURITY;

-- Allow service role full access (edge functions)
CREATE POLICY "service_role_all" ON social_accounts FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "service_role_all" ON social_campaigns FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "service_role_all" ON social_templates FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "service_role_all" ON social_brand_voice FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "service_role_all" ON social_posts FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "service_role_all" ON social_analytics FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "service_role_all" ON social_click_log FOR ALL USING (true) WITH CHECK (true);

-- Insert default brand voice
INSERT INTO social_brand_voice (tone_guidelines, arabic_dialect, hashtag_sets, banned_words)
VALUES (
  'دافئ، عائلي، متجذر في القيم الإسلامية، غير وعظي. نتحدث كصديق ناصح لا كواعظ.',
  'msa',
  '{"islamic": ["#صلة_الرحم", "#عائلة", "#اسلام", "#حديث", "#قرآن"], "app": ["#صلني", "#silni", "#family_app", "#تطبيق_عائلي"], "occasion": ["#رمضان", "#عيد", "#جمعة_مباركة"]}',
  ARRAY['سياسة', 'طائفي', 'مذهبي']
);
```

**Step 2: Apply the migration**

Run: `supabase db push` (if linked) or apply via Supabase dashboard.

**Step 3: Commit**

```bash
git add supabase/migrations/20260130100000_create_social_media_tables.sql
git commit -m "feat(social): add database tables for social media suite"
```

---

## Task 2: TypeScript Types for Social Media

**Files:**
- Modify: `silni-admin/src/types/database.ts` (append new types)

**Step 1: Add the types**

Append to `silni-admin/src/types/database.ts`:

```typescript
// ===== Social Media Suite =====

export type SocialPlatform = 'twitter' | 'instagram';
export type SocialPostStatus = 'draft' | 'queued' | 'approved' | 'scheduled' | 'published' | 'failed' | 'rejected';
export type SocialContentType = 'hadith' | 'quran' | 'family_tip' | 'feature' | 'update' | 'cta' | 'occasion';
export type SocialTone = 'inspirational' | 'educational' | 'conversational' | 'promotional';
export type SocialAccountStatus = 'connected' | 'expired' | 'disconnected';
export type ArabicDialect = 'msa' | 'colloquial' | 'mix';

export interface SocialAccount {
  id: string;
  platform: SocialPlatform;
  account_name: string;
  account_handle: string;
  access_token_encrypted: string;
  refresh_token_encrypted: string | null;
  token_expires_at: string | null;
  scopes: string[];
  platform_user_id: string | null;
  status: SocialAccountStatus;
  last_post_at: string | null;
  metadata: Record<string, unknown>;
  created_at: string;
  updated_at: string;
}

export interface SocialCampaign {
  id: string;
  name: string;
  description: string | null;
  utm_campaign: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface SocialTemplate {
  id: string;
  name: string;
  content_type: SocialContentType;
  platform: SocialPlatform | 'both';
  text_template: string;
  default_hashtags: string[];
  default_tone: SocialTone | null;
  is_recurring: boolean;
  recurring_schedule: Record<string, unknown> | null;
  tags: string[];
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface SocialBrandVoice {
  id: string;
  tone_guidelines: string;
  arabic_dialect: ArabicDialect;
  hashtag_sets: Record<string, string[]>;
  banned_words: string[];
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface SocialPost {
  id: string;
  platform: SocialPlatform;
  content_type: SocialContentType;
  text_ar: string;
  text_en: string | null;
  hashtags: string[];
  image_prompt: string | null;
  image_url: string | null;
  utm_link: string | null;
  tone: SocialTone | null;
  status: SocialPostStatus;
  scheduled_at: string | null;
  published_at: string | null;
  platform_post_id: string | null;
  platform_post_url: string | null;
  error_message: string | null;
  campaign_id: string | null;
  template_id: string | null;
  account_id: string | null;
  metadata: Record<string, unknown>;
  created_at: string;
  updated_at: string;
}

export interface SocialAnalytics {
  id: string;
  post_id: string;
  likes: number;
  comments: number;
  shares: number;
  impressions: number;
  link_clicks: number;
  snapshot_at: string;
  created_at: string;
}

export interface SocialClickLog {
  id: string;
  post_id: string | null;
  utm_source: string | null;
  utm_medium: string | null;
  utm_campaign: string | null;
  utm_content: string | null;
  user_agent: string | null;
  ip_hash: string | null;
  clicked_at: string;
}
```

**Step 2: Commit**

```bash
git add silni-admin/src/types/database.ts
git commit -m "feat(social): add TypeScript types for social media tables"
```

---

## Task 3: React Query Hooks — Social Posts

**Files:**
- Create: `silni-admin/src/hooks/use-social-posts.ts`

**Step 1: Write the hook**

Follow the exact pattern from `use-hadith.ts`:

```typescript
"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import type { SocialPost, SocialPostStatus } from "@/types/database";
import { toast } from "sonner";

const supabase = createClient();

export function useSocialPosts(statusFilter?: SocialPostStatus) {
  return useQuery({
    queryKey: ["admin", "social-posts", statusFilter],
    queryFn: async () => {
      let query = supabase
        .from("social_posts")
        .select("*")
        .order("created_at", { ascending: false });

      if (statusFilter) {
        query = query.eq("status", statusFilter);
      }

      const { data, error } = await query;
      if (error) throw error;
      return data as SocialPost[];
    },
  });
}

export function useSocialPostById(id: string) {
  return useQuery({
    queryKey: ["admin", "social-posts", id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("social_posts")
        .select("*")
        .eq("id", id)
        .single();
      if (error) throw error;
      return data as SocialPost;
    },
    enabled: !!id,
  });
}

export function useCreateSocialPost() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (post: Omit<SocialPost, "id" | "created_at" | "updated_at">) => {
      const { data, error } = await supabase
        .from("social_posts")
        .insert(post)
        .select()
        .single();
      if (error) throw error;
      return data as SocialPost;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "social-posts"] });
      toast.success("تم إنشاء المنشور بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في إنشاء المنشور: ${error.message}`);
    },
  });
}

export function useCreateSocialPostsBatch() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (posts: Omit<SocialPost, "id" | "created_at" | "updated_at">[]) => {
      const { data, error } = await supabase
        .from("social_posts")
        .insert(posts)
        .select();
      if (error) throw error;
      return data as SocialPost[];
    },
    onSuccess: (data) => {
      queryClient.invalidateQueries({ queryKey: ["admin", "social-posts"] });
      toast.success(`تم إنشاء ${data.length} منشور بنجاح`);
    },
    onError: (error) => {
      toast.error(`فشل في إنشاء المنشورات: ${error.message}`);
    },
  });
}

export function useUpdateSocialPost() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, ...post }: Partial<SocialPost> & { id: string }) => {
      const { data, error } = await supabase
        .from("social_posts")
        .update(post)
        .eq("id", id)
        .select()
        .single();
      if (error) throw error;
      return data as SocialPost;
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ["admin", "social-posts"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "social-posts", variables.id] });
      toast.success("تم تحديث المنشور بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في تحديث المنشور: ${error.message}`);
    },
  });
}

export function useDeleteSocialPost() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from("social_posts")
        .delete()
        .eq("id", id);
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "social-posts"] });
      toast.success("تم حذف المنشور بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في حذف المنشور: ${error.message}`);
    },
  });
}

export function useBulkUpdatePostStatus() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ ids, status }: { ids: string[]; status: SocialPostStatus }) => {
      const { error } = await supabase
        .from("social_posts")
        .update({ status })
        .in("id", ids);
      if (error) throw error;
    },
    onSuccess: (_, { ids, status }) => {
      queryClient.invalidateQueries({ queryKey: ["admin", "social-posts"] });
      const statusLabels: Record<string, string> = {
        approved: "قبول",
        rejected: "رفض",
        scheduled: "جدولة",
      };
      toast.success(`تم ${statusLabels[status] || status} ${ids.length} منشور بنجاح`);
    },
    onError: (error) => {
      toast.error(`فشل في تحديث الحالة: ${error.message}`);
    },
  });
}

export function useScheduledPosts() {
  return useQuery({
    queryKey: ["admin", "social-posts", "scheduled"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("social_posts")
        .select("*")
        .in("status", ["scheduled", "published", "failed"])
        .order("scheduled_at", { ascending: true });
      if (error) throw error;
      return data as SocialPost[];
    },
  });
}
```

**Step 2: Commit**

```bash
git add silni-admin/src/hooks/use-social-posts.ts
git commit -m "feat(social): add React Query hooks for social posts"
```

---

## Task 4: React Query Hooks — Templates, Campaigns, Accounts, Analytics, Brand Voice

**Files:**
- Create: `silni-admin/src/hooks/use-social-templates.ts`
- Create: `silni-admin/src/hooks/use-social-campaigns.ts`
- Create: `silni-admin/src/hooks/use-social-accounts.ts`
- Create: `silni-admin/src/hooks/use-social-analytics.ts`
- Create: `silni-admin/src/hooks/use-social-brand-voice.ts`

**Step 1: Write `use-social-templates.ts`**

Same CRUD pattern as use-hadith.ts for `social_templates` table. Include: `useSocialTemplates`, `useCreateSocialTemplate`, `useUpdateSocialTemplate`, `useDeleteSocialTemplate`, `useDuplicateSocialTemplate`. Query key: `["admin", "social-templates"]`. Toast messages in Arabic.

**Step 2: Write `use-social-campaigns.ts`**

CRUD for `social_campaigns`. Include: `useSocialCampaigns`, `useCreateSocialCampaign`, `useUpdateSocialCampaign`, `useDeleteSocialCampaign`. Query key: `["admin", "social-campaigns"]`.

**Step 3: Write `use-social-accounts.ts`**

Read + update for `social_accounts` (create/delete done via OAuth API routes). Include: `useSocialAccounts`, `useUpdateSocialAccount`, `useDisconnectSocialAccount` (sets status to 'disconnected'). Query key: `["admin", "social-accounts"]`.

**Step 4: Write `use-social-analytics.ts`**

Read-only queries. Include: `useSocialAnalyticsByPost(postId)`, `useSocialAnalyticsOverview(days: number)` (aggregated stats), `useSocialClicksByPost(postId)`, `useSocialClicksByCampaign(campaignId)`. Query key: `["admin", "social-analytics", ...]`.

**Step 5: Write `use-social-brand-voice.ts`**

Singleton pattern. Include: `useSocialBrandVoice` (fetch active brand voice), `useUpdateSocialBrandVoice`. Query key: `["admin", "social-brand-voice"]`.

**Step 6: Commit**

```bash
git add silni-admin/src/hooks/use-social-*.ts
git commit -m "feat(social): add hooks for templates, campaigns, accounts, analytics, brand voice"
```

---

## Task 5: Sidebar Navigation — Add Social Media Group

**Files:**
- Modify: `silni-admin/src/components/layout/sidebar.tsx`

**Step 1: Add the import**

Add `Share2` to the Lucide imports (line 6 block). Also add `Megaphone`, `Instagram`, `Twitter` if available, otherwise use `Globe` for accounts.

**Step 2: Add the navigation group**

Insert after the "إدارة المحتوى" group (after line 88):

```typescript
{
  title: "التواصل الاجتماعي",
  href: "/social",
  icon: Share2,
  badge: "جديد",
  children: [
    { title: "إنشاء المحتوى", href: "/social/generate", icon: Sparkles },
    { title: "التقويم", href: "/social/calendar", icon: CalendarDays },
    { title: "الحسابات", href: "/social/accounts", icon: Globe },
    { title: "التحليلات", href: "/social/analytics", icon: BarChart3 },
    { title: "القوالب", href: "/social/templates", icon: FileText },
  ],
},
```

**Step 3: Commit**

```bash
git add silni-admin/src/components/layout/sidebar.tsx
git commit -m "feat(social): add social media navigation to sidebar"
```

---

## Task 6: Accounts Page (`/social/accounts`)

**Files:**
- Create: `silni-admin/src/app/(dashboard)/social/accounts/page.tsx`

**Step 1: Write the page**

Build a page with two connection cards (Twitter/X and Instagram). Each card shows:
- Platform icon and name
- Connection status badge (connected=green, expired=amber, disconnected=gray)
- Account handle (if connected)
- Last post date (if connected)
- Connect / Disconnect button

Connect button links to OAuth API route (built in Task 9). Disconnect calls `useDisconnectSocialAccount`.

Follow the existing page pattern: `"use client"`, hooks for data, shadcn Card/Badge/Button components.

**Step 2: Commit**

```bash
git add silni-admin/src/app/\(dashboard\)/social/accounts/page.tsx
git commit -m "feat(social): add accounts management page"
```

---

## Task 7: Templates Page (`/social/templates`)

**Files:**
- Create: `silni-admin/src/app/(dashboard)/social/templates/page.tsx`

**Step 1: Write the page**

Two sections:

**Top: Brand Voice Config**
- Fetch with `useSocialBrandVoice()`
- Editable form: tone guidelines textarea, Arabic dialect select (MSA/Colloquial/Mix), hashtag sets editor (JSON or tag groups), banned words textarea
- Save button calls `useUpdateSocialBrandVoice`

**Bottom: Templates Table**
- Fetch with `useSocialTemplates()`
- Table columns: name, content type badge, platform badge, active switch, actions (edit/duplicate/delete)
- Create button opens dialog with: name, content type select, platform select, text template textarea with `{{variable}}` syntax, default hashtags input, tone select
- Search/filter by content type and platform

Follow the hadith page pattern for table + dialog layout.

**Step 2: Commit**

```bash
git add silni-admin/src/app/\(dashboard\)/social/templates/page.tsx
git commit -m "feat(social): add templates and brand voice config page"
```

---

## Task 8: Generate Page (`/social/generate`)

**Files:**
- Create: `silni-admin/src/app/(dashboard)/social/generate/page.tsx`
- Create: `silni-admin/src/app/api/social/generate/route.ts`

**Step 1: Write the API route for AI generation**

`silni-admin/src/app/api/social/generate/route.ts`:
- POST endpoint
- Accepts: `{ contentType, platform, batchSize, dateRange, tone, occasion? }`
- Fetches brand voice config from Supabase
- Fetches templates (if any match content type)
- Calls DeepSeek API with system prompt incorporating brand voice, banned words, hashtag sets
- System prompt instructs DeepSeek to generate `batchSize` posts as JSON array, each with: `text_ar`, `text_en`, `hashtags`, `suggested_time`, `image_prompt`
- For Twitter: enforce 280 char limit in prompt
- For Instagram: allow longer text + extra hashtags
- Returns generated posts array
- Admin auth required (use `verifyAdminAuth` pattern)

**Step 2: Write the page**

Two-column layout:

**Left: Generation Form**
- Content type dropdown (7 options)
- Platform toggle: Twitter / Instagram / Both
- Batch size slider (1-14, default 7)
- Date range picker (start/end date)
- Tone select (4 options)
- Occasion input (optional)
- "Generate" button — calls API route, inserts returned posts into DB with status `queued`

**Right: Review Queue**
- Fetch posts with `useSocialPosts('queued')`
- Card layout for each post:
  - Platform badge (blue=Twitter, pink=Instagram)
  - Status badge (yellow=queued, green=approved, red=rejected)
  - Post text (Arabic) with char count
  - Suggested hashtags
  - Suggested time
  - Action buttons: Approve, Reject, Edit (inline), Regenerate
- Bulk actions bar: Approve All, Reject All (using `useBulkUpdatePostStatus`)
- Approved posts get status changed to `approved` and `scheduled_at` set to suggested time

**Step 3: Commit**

```bash
git add silni-admin/src/app/api/social/generate/route.ts
git add silni-admin/src/app/\(dashboard\)/social/generate/page.tsx
git commit -m "feat(social): add AI content generation page with review queue"
```

---

## Task 9: OAuth API Routes (Twitter + Instagram)

**Files:**
- Create: `silni-admin/src/app/api/social/auth/twitter/route.ts`
- Create: `silni-admin/src/app/api/social/auth/twitter/callback/route.ts`
- Create: `silni-admin/src/app/api/social/auth/instagram/route.ts`
- Create: `silni-admin/src/app/api/social/auth/instagram/callback/route.ts`

**Step 1: Twitter OAuth 2.0 PKCE flow**

`api/social/auth/twitter/route.ts` (GET):
- Generate PKCE code verifier + challenge
- Store code verifier in encrypted cookie
- Build Twitter OAuth URL with:
  - `response_type=code`
  - `client_id` from env `TWITTER_CLIENT_ID`
  - `redirect_uri` = `{NEXT_PUBLIC_APP_URL}/api/social/auth/twitter/callback`
  - `scope=tweet.write tweet.read users.read offline.access`
  - `state` = random string (stored in cookie)
  - `code_challenge` + `code_challenge_method=S256`
- Redirect to Twitter OAuth URL

`api/social/auth/twitter/callback/route.ts` (GET):
- Verify state matches cookie
- Exchange code for tokens using PKCE verifier
- POST to `https://api.twitter.com/2/oauth2/token`
- Fetch user info from `https://api.twitter.com/2/users/me`
- Encrypt tokens with `pgcrypto` (call Supabase function or encrypt server-side)
- Upsert into `social_accounts`
- Redirect to `/social/accounts`

**Step 2: Instagram OAuth flow**

`api/social/auth/instagram/route.ts` (GET):
- Build Facebook OAuth URL:
  - `client_id` from env `FACEBOOK_APP_ID`
  - `redirect_uri` = `{NEXT_PUBLIC_APP_URL}/api/social/auth/instagram/callback`
  - `scope=instagram_basic,instagram_content_publish,pages_read_engagement`
  - `state` = random string (stored in cookie)
- Redirect to Facebook OAuth URL

`api/social/auth/instagram/callback/route.ts` (GET):
- Exchange code for short-lived token
- Exchange short-lived for long-lived token (60 day expiry)
- Fetch Instagram business account ID via `/me/accounts` and `/{page-id}?fields=instagram_business_account`
- Encrypt and store in `social_accounts`
- Redirect to `/social/accounts`

**Step 3: Commit**

```bash
git add silni-admin/src/app/api/social/auth/
git commit -m "feat(social): add OAuth flows for Twitter/X and Instagram"
```

**Environment variables needed (add to `.env.local`):**
```
TWITTER_CLIENT_ID=
TWITTER_CLIENT_SECRET=
FACEBOOK_APP_ID=
FACEBOOK_APP_SECRET=
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

---

## Task 10: Calendar Page (`/social/calendar`)

**Files:**
- Create: `silni-admin/src/app/(dashboard)/social/calendar/page.tsx`

**Step 1: Write the page**

Three view tabs: Month / Week / List.

**Month View:**
- Grid of 42 cells (6 weeks)
- Each day cell shows colored dots per post (blue=Twitter, pink=Instagram)
- Green border if all published, red if any failed
- Click a day to expand its posts

**Week View:**
- 7 columns, 24 hour rows
- Post cards at their scheduled time slot
- Drag-and-drop: `onDragStart`/`onDrop` to reschedule (calls `useUpdateSocialPost` with new `scheduled_at`)
- No timezone labels — all times in local browser time via `new Date().toLocaleTimeString()`

**List View:**
- Table with columns: status badge, platform icon, text preview (truncated 60 chars), scheduled time, actions
- Sortable by date, platform
- Filterable by status, platform

**All Views shared features:**
- Post detail dialog on click: full text, hashtags, image, edit form, reschedule date picker, cancel/retry buttons
- "Pause All" button: sets all `scheduled` posts to `draft`
- "Resume All" button: sets all `draft` posts back to `scheduled`
- Conflict warning: toast if scheduling within 2 hours of another post on same platform

**Step 2: Commit**

```bash
git add silni-admin/src/app/\(dashboard\)/social/calendar/page.tsx
git commit -m "feat(social): add scheduling calendar with month/week/list views"
```

---

## Task 11: Analytics Page (`/social/analytics`)

**Files:**
- Create: `silni-admin/src/app/(dashboard)/social/analytics/page.tsx`

**Step 1: Write the page**

**Top: Overview Cards (4 cards)**
- Total published (this month) — count from `social_posts` where `status=published`
- Total engagement — sum of latest `social_analytics` (likes+comments+shares)
- Total link clicks — sum from `social_click_log`
- Top performing post — post with highest engagement sum

**Middle: Charts (using Recharts)**

Import from recharts: `LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer`

1. **Engagement over time**: `LineChart` with 3 lines (likes, comments, shares) over 30 days
2. **Content type breakdown**: `BarChart` comparing engagement by content_type
3. **Platform comparison**: Side-by-side bar chart Twitter vs Instagram
4. **Best posting times**: Simple grid/heatmap (7 days x 24 hours) colored by average engagement

**Bottom: Post Performance Table**
- Columns: date, platform icon, text preview, likes, comments, shares, clicks, total engagement
- Sortable by any column
- Filter by platform, content type, campaign, date range

**Step 2: Commit**

```bash
git add silni-admin/src/app/\(dashboard\)/social/analytics/page.tsx
git commit -m "feat(social): add analytics page with charts and performance table"
```

---

## Task 12: Edge Function — Social Publisher (Cron)

**Files:**
- Create: `supabase/functions/social-publisher/index.ts`

**Step 1: Write the edge function**

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  // Fetch posts ready to publish
  const { data: posts, error } = await supabase
    .from("social_posts")
    .select("*, social_accounts!account_id(*)")
    .eq("status", "scheduled")
    .lte("scheduled_at", new Date().toISOString())
    .order("scheduled_at", { ascending: true })
    .limit(10);

  if (error || !posts?.length) {
    return new Response(JSON.stringify({ published: 0 }), { status: 200 });
  }

  let published = 0;
  for (const post of posts) {
    try {
      const account = post.social_accounts;
      if (!account || account.status !== "connected") {
        await supabase.from("social_posts").update({
          status: "failed",
          error_message: "No connected account",
        }).eq("id", post.id);
        continue;
      }

      // Decrypt token (via pgcrypto SQL function or stored decrypted in service role)
      const accessToken = account.access_token_encrypted; // In production: decrypt

      if (post.platform === "twitter") {
        const res = await fetch("https://api.twitter.com/2/tweets", {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            text: `${post.text_ar}\n\n${post.hashtags?.join(" ") || ""}\n\n${post.utm_link || ""}`.trim(),
          }),
        });

        if (!res.ok) throw new Error(`Twitter API: ${res.status} ${await res.text()}`);
        const result = await res.json();

        await supabase.from("social_posts").update({
          status: "published",
          published_at: new Date().toISOString(),
          platform_post_id: result.data?.id,
          platform_post_url: `https://twitter.com/i/status/${result.data?.id}`,
        }).eq("id", post.id);
      }

      if (post.platform === "instagram") {
        const igAccountId = account.platform_user_id;
        // Step 1: Create media container
        const createRes = await fetch(
          `https://graph.facebook.com/v18.0/${igAccountId}/media`,
          {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              caption: `${post.text_ar}\n\n${post.hashtags?.join(" ") || ""}\n\n${post.utm_link || ""}`.trim(),
              image_url: post.image_url,
              access_token: accessToken,
            }),
          }
        );
        if (!createRes.ok) throw new Error(`Instagram API: ${createRes.status}`);
        const { id: containerId } = await createRes.json();

        // Step 2: Publish container
        const publishRes = await fetch(
          `https://graph.facebook.com/v18.0/${igAccountId}/media_publish`,
          {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              creation_id: containerId,
              access_token: accessToken,
            }),
          }
        );
        if (!publishRes.ok) throw new Error(`Instagram publish: ${publishRes.status}`);
        const { id: mediaId } = await publishRes.json();

        await supabase.from("social_posts").update({
          status: "published",
          published_at: new Date().toISOString(),
          platform_post_id: mediaId,
          platform_post_url: `https://instagram.com/p/${mediaId}`,
        }).eq("id", post.id);
      }

      // Update account last_post_at
      await supabase.from("social_accounts").update({
        last_post_at: new Date().toISOString(),
      }).eq("id", account.id);

      published++;
    } catch (err) {
      await supabase.from("social_posts").update({
        status: "failed",
        error_message: err instanceof Error ? err.message : "Unknown error",
      }).eq("id", post.id);
    }
  }

  return new Response(JSON.stringify({ published }), { status: 200 });
});
```

**Step 2: Deploy**

Run: `supabase functions deploy social-publisher --project-ref bapwklwxmwhpucutyras`

Set up cron via Supabase dashboard: every 5 minutes, invoke this function.

**Step 3: Commit**

```bash
git add supabase/functions/social-publisher/
git commit -m "feat(social): add edge function for scheduled post publishing"
```

---

## Task 13: Edge Function — Analytics Collector (Cron)

**Files:**
- Create: `supabase/functions/social-analytics-collector/index.ts`

**Step 1: Write the edge function**

- Fetch all posts with `status=published` from last 30 days
- For each post, fetch engagement from platform API:
  - Twitter: `GET /2/tweets/{id}?tweet.fields=public_metrics`
  - Instagram: `GET /{media-id}?fields=like_count,comments_count,insights`
- Insert snapshot into `social_analytics`
- Run daily via cron

**Step 2: Deploy and set cron**

Run: `supabase functions deploy social-analytics-collector --project-ref bapwklwxmwhpucutyras`

**Step 3: Commit**

```bash
git add supabase/functions/social-analytics-collector/
git commit -m "feat(social): add edge function for daily analytics collection"
```

---

## Task 14: Edge Function — Token Refresh (Cron)

**Files:**
- Create: `supabase/functions/social-token-refresh/index.ts`

**Step 1: Write the edge function**

- Fetch accounts where `token_expires_at` is within 24 hours
- For Twitter: POST to `/2/oauth2/token` with `grant_type=refresh_token`
- For Instagram: GET `https://graph.facebook.com/v18.0/oauth/access_token?grant_type=fb_exchange_token&client_id=...&client_secret=...&fb_exchange_token=...`
- Update tokens and expiry in `social_accounts`
- If refresh fails, set status to `expired`
- Run hourly via cron

**Step 2: Deploy and set cron**

Run: `supabase functions deploy social-token-refresh --project-ref bapwklwxmwhpucutyras`

**Step 3: Commit**

```bash
git add supabase/functions/social-token-refresh/
git commit -m "feat(social): add edge function for OAuth token refresh"
```

---

## Task 15: Click Redirect Endpoint

**Files:**
- Create: `supabase/functions/social-click-redirect/index.ts`

**Step 1: Write the edge function**

HTTP endpoint (not cron). Called when user clicks a UTM link in a social post.

```typescript
// URL pattern: /social-click-redirect?post_id=X&utm_source=twitter&utm_campaign=Y&redirect=APP_STORE_URL
// Logs the click, then 302 redirects to the App Store URL
```

- Parse query params: `post_id`, `utm_source`, `utm_medium`, `utm_campaign`, `utm_content`, `redirect`
- Insert into `social_click_log` (hash IP for privacy, store user agent)
- Return 302 redirect to `redirect` URL (App Store link)

**Step 2: Deploy**

Run: `supabase functions deploy social-click-redirect --project-ref bapwklwxmwhpucutyras`

**Step 3: Commit**

```bash
git add supabase/functions/social-click-redirect/
git commit -m "feat(social): add click tracking redirect endpoint"
```

---

## Task 16: Integration Testing & Polish

**Step 1: Test the full flow locally**

1. Start admin panel: `cd silni-admin && npm run dev`
2. Navigate to `/social/accounts` — verify cards render
3. Navigate to `/social/templates` — create a template, edit brand voice
4. Navigate to `/social/generate` — generate a batch (mock DeepSeek if no key)
5. Review queue: approve posts
6. Navigate to `/social/calendar` — verify posts appear on calendar
7. Navigate to `/social/analytics` — verify empty state renders

**Step 2: Fix any issues found**

**Step 3: Final commit**

```bash
git add -A
git commit -m "feat(social): polish and integration fixes"
```

---

## Summary

| Task | Description | Files |
|------|-------------|-------|
| 1 | Database migration | 1 SQL file |
| 2 | TypeScript types | Modify 1 file |
| 3 | Posts hooks | 1 hook file |
| 4 | Other hooks (5) | 5 hook files |
| 5 | Sidebar navigation | Modify 1 file |
| 6 | Accounts page | 1 page file |
| 7 | Templates page | 1 page file |
| 8 | Generate page + API | 2 files |
| 9 | OAuth API routes | 4 route files |
| 10 | Calendar page | 1 page file |
| 11 | Analytics page | 1 page file |
| 12 | Publisher edge function | 1 function |
| 13 | Analytics collector | 1 function |
| 14 | Token refresh | 1 function |
| 15 | Click redirect | 1 function |
| 16 | Integration testing | N/A |

**Total: ~24 new files, 2 modified files, 16 commits**
