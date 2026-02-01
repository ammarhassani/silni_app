"use client";

import { useState } from "react";
import {
  useSocialPosts,
  useCreateSocialPostsBatch,
  useUpdateSocialPost,
  useBulkUpdatePostStatus,
} from "@/hooks/use-social-posts";
import { useSocialAccounts } from "@/hooks/use-social-accounts";
import { toast } from "sonner";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Select,
  SelectTrigger,
  SelectValue,
  SelectContent,
  SelectItem,
} from "@/components/ui/select";
import {
  Sparkles,
  Check,
  X,
  Pencil,
  CheckCheck,
  XCircle,
  Loader2,
  Calendar,
} from "lucide-react";
import {
  getUpcomingEvents,
  buildOccasionContext,
} from "@/lib/cultural-calendar";
import type {
  SocialContentType,
  SocialTone,
  SocialPlatform,
  SocialPost,
} from "@/types/database";

// --- Label maps ---

const contentTypeLabels: Record<SocialContentType, string> = {
  hadith: "حديث",
  quran: "قرآن",
  family_tip: "نصيحة عائلية",
  feature: "ميزة",
  update: "تحديث",
  cta: "دعوة للتحميل",
  occasion: "مناسبة",
};

const toneLabels: Record<SocialTone, string> = {
  inspirational: "ملهم",
  educational: "تعليمي",
  conversational: "حواري",
  promotional: "ترويجي",
};

const platformLabels: Record<string, { label: string; color: string }> = {
  twitter: { label: "تويتر", color: "bg-blue-500/10 text-blue-600" },
  instagram: { label: "إنستغرام", color: "bg-pink-500/10 text-pink-600" },
  both: { label: "الكل", color: "bg-purple-500/10 text-purple-600" },
};

const statusLabels: Record<string, { label: string; color: string }> = {
  queued: { label: "في الانتظار", color: "bg-yellow-500/10 text-yellow-600" },
  approved: { label: "مقبول", color: "bg-green-500/10 text-green-600" },
  rejected: { label: "مرفوض", color: "bg-red-500/10 text-red-600" },
};

// --- Types ---

interface GeneratedPost {
  text_ar: string;
  text_en: string;
  hashtags: string[];
  suggested_time: string;
  image_prompt: string;
}

interface GenerateFormState {
  contentType: SocialContentType;
  platform: "twitter" | "instagram" | "both";
  batchSize: number;
  dateStart: string;
  dateEnd: string;
  tone: SocialTone;
  occasion: string;
}

// --- Helpers ---

function getDefaultDateStart(): string {
  const d = new Date();
  return d.toISOString().split("T")[0];
}

function getDefaultDateEnd(): string {
  const d = new Date();
  d.setDate(d.getDate() + 7);
  return d.toISOString().split("T")[0];
}

// --- Post Card Component ---

function PostCard({
  post,
  onApprove,
  onReject,
  onSaveEdit,
}: {
  post: SocialPost;
  onApprove: (post: SocialPost) => void;
  onReject: (post: SocialPost) => void;
  onSaveEdit: (id: string, text_ar: string) => void;
}) {
  const [editing, setEditing] = useState(false);
  const [editText, setEditText] = useState(post.text_ar);

  const platformInfo = platformLabels[post.platform] || platformLabels.twitter;
  const statusInfo = statusLabels[post.status] || statusLabels.queued;

  const handleSave = () => {
    onSaveEdit(post.id, editText);
    setEditing(false);
  };

  const handleCancel = () => {
    setEditText(post.text_ar);
    setEditing(false);
  };

  return (
    <div className="border rounded-lg p-4 space-y-3">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Badge className={platformInfo.color}>{platformInfo.label}</Badge>
          <Badge className={statusInfo.color}>{statusInfo.label}</Badge>
        </div>
        <span className="text-xs text-muted-foreground">
          {post.text_ar.length} حرف
        </span>
      </div>

      {editing ? (
        <div className="space-y-2">
          <Textarea
            value={editText}
            onChange={(e) => setEditText(e.target.value)}
            rows={4}
            dir="rtl"
          />
          <div className="flex gap-2 justify-end">
            <Button variant="outline" size="sm" onClick={handleCancel}>
              إلغاء
            </Button>
            <Button size="sm" onClick={handleSave}>
              حفظ
            </Button>
          </div>
        </div>
      ) : (
        <p className="text-sm leading-relaxed whitespace-pre-wrap" dir="rtl">
          {post.text_ar}
        </p>
      )}

      {post.hashtags && post.hashtags.length > 0 && (
        <div className="flex flex-wrap gap-1">
          {post.hashtags.map((tag, i) => (
            <Badge key={i} variant="outline" className="text-xs">
              {tag}
            </Badge>
          ))}
        </div>
      )}

      {post.scheduled_at && (
        <p className="text-xs text-muted-foreground">
          الوقت المقترح: {new Date(post.scheduled_at).toLocaleString("ar-SA")}
        </p>
      )}

      {post.status === "queued" && !editing && (
        <div className="flex gap-2 justify-end pt-1">
          <Button
            variant="outline"
            size="sm"
            onClick={() => setEditing(true)}
          >
            <Pencil className="h-3.5 w-3.5 ml-1" />
            تعديل
          </Button>
          <Button
            variant="outline"
            size="sm"
            className="text-red-600 hover:text-red-700 hover:bg-red-50"
            onClick={() => onReject(post)}
          >
            <X className="h-3.5 w-3.5 ml-1" />
            رفض
          </Button>
          <Button
            size="sm"
            className="bg-green-600 hover:bg-green-700 text-white"
            onClick={() => onApprove(post)}
          >
            <Check className="h-3.5 w-3.5 ml-1" />
            قبول
          </Button>
        </div>
      )}
    </div>
  );
}

// --- Main Page ---

export default function SocialGeneratePage() {
  const [form, setForm] = useState<GenerateFormState>({
    contentType: "hadith",
    platform: "both",
    batchSize: 7,
    dateStart: getDefaultDateStart(),
    dateEnd: getDefaultDateEnd(),
    tone: "inspirational",
    occasion: "",
  });
  const [generating, setGenerating] = useState(false);
  const [generateError, setGenerateError] = useState<string | null>(null);

  const { data: queuedPosts, isLoading: postsLoading } = useSocialPosts("queued");
  const { data: accounts } = useSocialAccounts();
  const createBatch = useCreateSocialPostsBatch();
  const updatePost = useUpdateSocialPost();
  const bulkUpdate = useBulkUpdatePostStatus();

  // Find connected account for a given platform
  const getAccountForPlatform = (platform: string): string | null => {
    if (!accounts) return null;
    const account = accounts.find(
      (a) => a.platform === platform && a.status === "connected",
    );
    return account?.id || null;
  };

  const handleGenerate = async () => {
    setGenerating(true);
    setGenerateError(null);

    try {
      const response = await fetch("/api/social/generate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contentType: form.contentType,
          platform: form.platform,
          batchSize: form.batchSize,
          dateRange: { start: form.dateStart, end: form.dateEnd },
          tone: form.tone,
          occasion: form.occasion || undefined,
        }),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || "فشل في توليد المحتوى");
      }

      const data = await response.json();
      const generatedPosts: GeneratedPost[] = data.posts || [];

      if (generatedPosts.length === 0) {
        setGenerateError("لم يتم توليد أي منشورات");
        return;
      }

      const postsToInsert: Omit<SocialPost, "id" | "created_at" | "updated_at">[] =
        generatedPosts.map((post) => {
          const inferredPlatform: SocialPlatform =
            form.platform === "both"
              ? (post.text_ar.length <= 280 ? "twitter" : "instagram")
              : form.platform;

          return {
            platform: inferredPlatform,
            content_type: form.contentType,
            text_ar: post.text_ar,
            text_en: post.text_en || null,
            hashtags: post.hashtags || [],
            image_prompt: post.image_prompt || null,
            image_url: null,
            utm_link: null,
            tone: form.tone,
            status: "queued" as const,
            scheduled_at: post.suggested_time || null,
            published_at: null,
            platform_post_id: null,
            platform_post_url: null,
            error_message: null,
            campaign_id: null,
            template_id: null,
            account_id: null,
            metadata: {},
          };
        });

      createBatch.mutate(postsToInsert);
    } catch (error) {
      setGenerateError(
        error instanceof Error ? error.message : "حدث خطأ غير متوقع",
      );
    } finally {
      setGenerating(false);
    }
  };

  const handleApprove = (post: SocialPost) => {
    const accountId = getAccountForPlatform(post.platform);
    if (!accountId) {
      toast.error(`لا يوجد حساب ${post.platform === "twitter" ? "تويتر" : "إنستغرام"} متصل. اربط الحساب أولاً من صفحة الحسابات.`);
      return;
    }
    updatePost.mutate({
      id: post.id,
      status: "scheduled",
      account_id: accountId,
      scheduled_at: post.scheduled_at,
    });
  };

  const handleReject = (post: SocialPost) => {
    updatePost.mutate({
      id: post.id,
      status: "rejected",
    });
  };

  const handleSaveEdit = (id: string, text_ar: string) => {
    updatePost.mutate({ id, text_ar });
  };

  const handleBulkApprove = () => {
    if (!queuedPosts || queuedPosts.length === 0) return;

    // Group posts by platform to assign the correct account_id
    const byPlatform: Record<string, SocialPost[]> = {};
    for (const post of queuedPosts) {
      if (!byPlatform[post.platform]) byPlatform[post.platform] = [];
      byPlatform[post.platform].push(post);
    }

    for (const [platform, posts] of Object.entries(byPlatform)) {
      const accountId = getAccountForPlatform(platform);
      if (!accountId) {
        toast.error(`لا يوجد حساب ${platform === "twitter" ? "تويتر" : "إنستغرام"} متصل. اربط الحساب أولاً.`);
        continue;
      }
      const ids = posts.map((p) => p.id);
      bulkUpdate.mutate({ ids, status: "scheduled", account_id: accountId });
    }
  };

  const handleBulkReject = () => {
    if (!queuedPosts || queuedPosts.length === 0) return;
    const ids = queuedPosts.map((p) => p.id);
    bulkUpdate.mutate({ ids, status: "rejected" });
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">توليد المحتوى بالذكاء الاصطناعي</h1>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* ======= Left Section: Generation Form ======= */}
        <Card>
          <CardHeader>
            <CardTitle>نموذج التوليد</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid gap-4">
              {/* Content Type */}
              <div className="space-y-2">
                <Label>نوع المحتوى</Label>
                <Select
                  value={form.contentType}
                  onValueChange={(v) =>
                    setForm((f) => ({ ...f, contentType: v as SocialContentType }))
                  }
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {Object.entries(contentTypeLabels).map(([value, label]) => (
                      <SelectItem key={value} value={value}>
                        {label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              {/* Platform Toggle */}
              <div className="space-y-2">
                <Label>المنصة</Label>
                <div className="flex gap-2">
                  {(Object.entries(platformLabels) as [string, { label: string; color: string }][]).map(
                    ([value, info]) => (
                      <Button
                        key={value}
                        type="button"
                        variant={form.platform === value ? "default" : "outline"}
                        size="sm"
                        className={form.platform === value ? "" : info.color}
                        onClick={() =>
                          setForm((f) => ({
                            ...f,
                            platform: value as "twitter" | "instagram" | "both",
                          }))
                        }
                      >
                        {info.label}
                      </Button>
                    ),
                  )}
                </div>
              </div>

              {/* Batch Size */}
              <div className="space-y-2">
                <Label>عدد المنشورات</Label>
                <Input
                  type="number"
                  min={1}
                  max={14}
                  value={form.batchSize}
                  onChange={(e) =>
                    setForm((f) => ({
                      ...f,
                      batchSize: Math.min(14, Math.max(1, parseInt(e.target.value) || 1)),
                    }))
                  }
                />
              </div>

              {/* Date Range */}
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>من تاريخ</Label>
                  <Input
                    type="date"
                    value={form.dateStart}
                    onChange={(e) =>
                      setForm((f) => ({ ...f, dateStart: e.target.value }))
                    }
                  />
                </div>
                <div className="space-y-2">
                  <Label>إلى تاريخ</Label>
                  <Input
                    type="date"
                    value={form.dateEnd}
                    onChange={(e) =>
                      setForm((f) => ({ ...f, dateEnd: e.target.value }))
                    }
                  />
                </div>
              </div>

              {/* Cultural Calendar Suggestions */}
              {(() => {
                const upcomingEvents = getUpcomingEvents();
                if (upcomingEvents.length === 0) return null;
                return (
                  <div className="space-y-2">
                    <Label className="flex items-center gap-1.5">
                      <Calendar className="h-4 w-4" />
                      مناسبات قادمة
                    </Label>
                    <div className="space-y-2">
                      {upcomingEvents.map((event) => (
                        <button
                          key={event.key}
                          type="button"
                          className="w-full text-right border rounded-lg p-3 hover:bg-accent/50 transition-colors"
                          onClick={() => {
                            setForm((f) => ({
                              ...f,
                              contentType: (event.suggestedContentTypes[0] || "occasion") as SocialContentType,
                              occasion: buildOccasionContext(event),
                              dateStart:
                                event.gregorianDates[new Date().getFullYear()]?.start || f.dateStart,
                              dateEnd:
                                event.gregorianDates[new Date().getFullYear()]?.end || f.dateEnd,
                              batchSize: Math.min(event.durationDays, 14),
                            }));
                          }}
                        >
                          <div className="flex items-center justify-between">
                            <Badge variant="outline">
                              {event.suggestedContentTypes[0]}
                            </Badge>
                            <span className="font-medium">
                              {event.emoji} {event.nameAr}
                            </span>
                          </div>
                          <p className="text-xs text-muted-foreground mt-1">
                            {event.themes.slice(0, 2).join(" \u2022 ")}
                          </p>
                        </button>
                      ))}
                    </div>
                  </div>
                );
              })()}

              {/* Tone */}
              <div className="space-y-2">
                <Label>النبرة</Label>
                <Select
                  value={form.tone}
                  onValueChange={(v) =>
                    setForm((f) => ({ ...f, tone: v as SocialTone }))
                  }
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {Object.entries(toneLabels).map(([value, label]) => (
                      <SelectItem key={value} value={value}>
                        {label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              {/* Occasion (optional) */}
              <div className="space-y-2">
                <Label>المناسبة (اختياري)</Label>
                <Textarea
                  value={form.occasion}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, occasion: e.target.value }))
                  }
                  placeholder="مثال: رمضان، عيد الأضحى، يوم الأسرة..."
                  rows={3}
                  dir="rtl"
                />
              </div>

              {/* Generate Error */}
              {generateError && (
                <div className="text-sm text-red-600 bg-red-50 rounded-md p-3">
                  {generateError}
                </div>
              )}

              {/* Generate Button */}
              <Button
                onClick={handleGenerate}
                disabled={generating || createBatch.isPending}
                className="w-full"
              >
                {generating ? (
                  <>
                    <Loader2 className="h-4 w-4 ml-2 animate-spin" />
                    جاري التوليد...
                  </>
                ) : createBatch.isPending ? (
                  <>
                    <Loader2 className="h-4 w-4 ml-2 animate-spin" />
                    جاري الحفظ...
                  </>
                ) : (
                  <>
                    <Sparkles className="h-4 w-4 ml-2" />
                    توليد المحتوى
                  </>
                )}
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* ======= Right Section: Review Queue ======= */}
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <CardTitle>قائمة المراجعة</CardTitle>
              {queuedPosts && queuedPosts.length > 0 && (
                <Badge variant="secondary">{queuedPosts.length} منشور</Badge>
              )}
            </div>
          </CardHeader>
          <CardContent>
            {/* Bulk Actions */}
            {queuedPosts && queuedPosts.length > 0 && (
              <div className="flex gap-2 mb-4">
                <Button
                  variant="outline"
                  size="sm"
                  className="text-green-600 hover:text-green-700 hover:bg-green-50"
                  onClick={handleBulkApprove}
                  disabled={bulkUpdate.isPending}
                >
                  <CheckCheck className="h-3.5 w-3.5 ml-1" />
                  قبول الكل
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  className="text-red-600 hover:text-red-700 hover:bg-red-50"
                  onClick={handleBulkReject}
                  disabled={bulkUpdate.isPending}
                >
                  <XCircle className="h-3.5 w-3.5 ml-1" />
                  رفض الكل
                </Button>
              </div>
            )}

            {/* Posts List */}
            {postsLoading ? (
              <div className="text-center py-8 text-muted-foreground">
                جاري التحميل...
              </div>
            ) : !queuedPosts || queuedPosts.length === 0 ? (
              <div className="text-center py-8 text-muted-foreground">
                لا توجد منشورات في قائمة المراجعة
              </div>
            ) : (
              <div className="space-y-4 max-h-[600px] overflow-y-auto">
                {queuedPosts.map((post) => (
                  <PostCard
                    key={post.id}
                    post={post}
                    onApprove={handleApprove}
                    onReject={handleReject}
                    onSaveEdit={handleSaveEdit}
                  />
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
