"use client";

import { useState, useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import { useSocialPosts } from "@/hooks/use-social-posts";
import { useSocialAnalyticsOverview } from "@/hooks/use-social-analytics";
import { createClient } from "@/lib/supabase/client";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Select,
  SelectTrigger,
  SelectValue,
  SelectContent,
  SelectItem,
} from "@/components/ui/select";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Send,
  Heart,
  MousePointerClick,
  Trophy,
  ArrowUpDown,
  TrendingUp,
  BarChart3,
} from "lucide-react";
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from "recharts";
import type {
  SocialPost,
  SocialAnalytics,
  SocialContentType,
  SocialPlatform,
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

const platformLabels: Record<string, { label: string; color: string }> = {
  twitter: { label: "تويتر", color: "bg-blue-500/10 text-blue-600" },
  instagram: { label: "إنستغرام", color: "bg-pink-500/10 text-pink-600" },
};

const dayNames = [
  "الأحد",
  "الإثنين",
  "الثلاثاء",
  "الأربعاء",
  "الخميس",
  "الجمعة",
  "السبت",
];

const timePeriods = [
  { label: "صباحاً", range: [6, 12] },
  { label: "ظهراً", range: [12, 18] },
  { label: "مساءً", range: [18, 24] },
  { label: "ليلاً", range: [0, 6] },
];

type SortField =
  | "scheduled_at"
  | "likes"
  | "comments"
  | "shares"
  | "link_clicks"
  | "total";
type SortDir = "asc" | "desc";

interface AnalyticsWithPost extends SocialAnalytics {
  social_posts: {
    platform: SocialPlatform;
    content_type: SocialContentType;
    text_ar: string;
    scheduled_at: string | null;
  } | null;
}

export default function SocialAnalyticsPage() {
  const [periodDays, setPeriodDays] = useState<number>(30);
  const [platformFilter, setPlatformFilter] = useState<string>("all");
  const [contentTypeFilter, setContentTypeFilter] = useState<string>("all");
  const [sortField, setSortField] = useState<SortField>("scheduled_at");
  const [sortDir, setSortDir] = useState<SortDir>("desc");

  // Fetch published posts
  const { data: publishedPosts, isLoading: postsLoading } =
    useSocialPosts("published");

  // Fetch analytics overview for selected period
  const { data: analyticsRaw, isLoading: analyticsLoading } =
    useSocialAnalyticsOverview(periodDays);

  // Fetch analytics with joined post data
  const supabase = createClient();
  const { data: analyticsWithPosts, isLoading: analyticsPostsLoading } =
    useQuery({
      queryKey: ["admin", "social-analytics", "all", periodDays],
      queryFn: async () => {
        const since = new Date();
        since.setDate(since.getDate() - periodDays);

        const { data, error } = await supabase
          .from("social_analytics")
          .select(
            "*, social_posts!post_id(platform, content_type, text_ar, scheduled_at)"
          )
          .gte("snapshot_at", since.toISOString())
          .order("snapshot_at", { ascending: false });

        if (error) throw error;
        return data as AnalyticsWithPost[];
      },
    });

  const isLoading = postsLoading || analyticsLoading || analyticsPostsLoading;

  // --- Computed: Overview Cards ---
  const overviewStats = useMemo(() => {
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const publishedThisMonth =
      publishedPosts?.filter((p) => {
        const pubDate = new Date(p.published_at || p.created_at);
        return pubDate >= startOfMonth;
      }) || [];

    const totalLikes = analyticsRaw?.reduce((s, a) => s + a.likes, 0) || 0;
    const totalComments =
      analyticsRaw?.reduce((s, a) => s + a.comments, 0) || 0;
    const totalShares = analyticsRaw?.reduce((s, a) => s + a.shares, 0) || 0;
    const totalClicks =
      analyticsRaw?.reduce((s, a) => s + a.link_clicks, 0) || 0;
    const totalEngagement = totalLikes + totalComments + totalShares;

    // Find top post — get latest snapshot per post, then pick highest engagement
    const latestByPost = new Map<string, SocialAnalytics>();
    for (const a of analyticsRaw || []) {
      const existing = latestByPost.get(a.post_id);
      if (
        !existing ||
        new Date(a.snapshot_at) > new Date(existing.snapshot_at)
      ) {
        latestByPost.set(a.post_id, a);
      }
    }

    let topPostId: string | null = null;
    let topPostEngagement = 0;
    latestByPost.forEach((a, postId) => {
      const eng = a.likes + a.comments + a.shares;
      if (eng > topPostEngagement) {
        topPostEngagement = eng;
        topPostId = postId;
      }
    });

    const topPost = topPostId
      ? analyticsWithPosts?.find((a) => a.post_id === topPostId)
      : null;
    const topPostText =
      topPost?.social_posts?.text_ar?.slice(0, 60) || "لا توجد بيانات";

    return {
      publishedCount: publishedThisMonth.length,
      totalEngagement,
      totalClicks,
      topPostText,
    };
  }, [publishedPosts, analyticsRaw, analyticsWithPosts]);

  // --- Computed: Engagement Over Time ---
  const engagementTimeData = useMemo(() => {
    if (!analyticsWithPosts || analyticsWithPosts.length === 0) return [];

    const byDate = new Map<
      string,
      { likes: number; comments: number; shares: number }
    >();

    for (const a of analyticsWithPosts) {
      const dateStr = new Date(a.snapshot_at).toLocaleDateString("ar-SA", {
        month: "short",
        day: "numeric",
      });
      const existing = byDate.get(dateStr) || {
        likes: 0,
        comments: 0,
        shares: 0,
      };
      existing.likes += a.likes;
      existing.comments += a.comments;
      existing.shares += a.shares;
      byDate.set(dateStr, existing);
    }

    return Array.from(byDate.entries())
      .map(([date, vals]) => ({
        date,
        ...vals,
      }))
      .reverse();
  }, [analyticsWithPosts]);

  // --- Computed: Content Type Breakdown ---
  const contentTypeData = useMemo(() => {
    if (!analyticsWithPosts || analyticsWithPosts.length === 0) return [];

    const byType = new Map<string, number>();

    for (const a of analyticsWithPosts) {
      const ct = a.social_posts?.content_type || "unknown";
      const engagement = a.likes + a.comments + a.shares;
      byType.set(ct, (byType.get(ct) || 0) + engagement);
    }

    return Array.from(byType.entries()).map(([type, engagement]) => ({
      type: contentTypeLabels[type as SocialContentType] || type,
      engagement,
    }));
  }, [analyticsWithPosts]);

  // --- Computed: Platform Comparison ---
  const platformComparisonData = useMemo(() => {
    if (!analyticsWithPosts || analyticsWithPosts.length === 0) return [];

    const byPlatform: Record<
      string,
      { likes: number; comments: number; shares: number; clicks: number }
    > = {
      twitter: { likes: 0, comments: 0, shares: 0, clicks: 0 },
      instagram: { likes: 0, comments: 0, shares: 0, clicks: 0 },
    };

    for (const a of analyticsWithPosts) {
      const platform = a.social_posts?.platform;
      if (platform && byPlatform[platform]) {
        byPlatform[platform].likes += a.likes;
        byPlatform[platform].comments += a.comments;
        byPlatform[platform].shares += a.shares;
        byPlatform[platform].clicks += a.link_clicks;
      }
    }

    return [
      {
        metric: "إعجابات",
        twitter: byPlatform.twitter.likes,
        instagram: byPlatform.instagram.likes,
      },
      {
        metric: "تعليقات",
        twitter: byPlatform.twitter.comments,
        instagram: byPlatform.instagram.comments,
      },
      {
        metric: "مشاركات",
        twitter: byPlatform.twitter.shares,
        instagram: byPlatform.instagram.shares,
      },
      {
        metric: "نقرات",
        twitter: byPlatform.twitter.clicks,
        instagram: byPlatform.instagram.clicks,
      },
    ];
  }, [analyticsWithPosts]);

  // --- Computed: Best Posting Times Heatmap ---
  const heatmapData = useMemo(() => {
    // 7 days x 4 time periods
    const grid: number[][] = Array.from({ length: 7 }, () =>
      Array(4).fill(0)
    );

    if (!analyticsWithPosts) return grid;

    for (const a of analyticsWithPosts) {
      const scheduledAt = a.social_posts?.scheduled_at;
      if (!scheduledAt) continue;

      const date = new Date(scheduledAt);
      const dayIndex = date.getDay(); // 0=Sunday
      const hour = date.getHours();
      const engagement = a.likes + a.comments + a.shares;

      let periodIndex: number;
      if (hour >= 6 && hour < 12) periodIndex = 0;
      else if (hour >= 12 && hour < 18) periodIndex = 1;
      else if (hour >= 18 && hour < 24) periodIndex = 2;
      else periodIndex = 3;

      grid[dayIndex][periodIndex] += engagement;
    }

    return grid;
  }, [analyticsWithPosts]);

  const heatmapMax = useMemo(() => {
    let max = 0;
    for (const row of heatmapData) {
      for (const val of row) {
        if (val > max) max = val;
      }
    }
    return max;
  }, [heatmapData]);

  function getHeatmapColor(value: number): string {
    if (heatmapMax === 0 || value === 0) return "bg-muted";
    const ratio = value / heatmapMax;
    if (ratio < 0.25) return "bg-green-100 dark:bg-green-950";
    if (ratio < 0.5) return "bg-green-300 dark:bg-green-800";
    if (ratio < 0.75) return "bg-green-500 dark:bg-green-600 text-white";
    return "bg-green-700 dark:bg-green-400 text-white dark:text-green-950";
  }

  // --- Computed: Performance Table ---
  // Aggregate latest analytics per post
  const latestAnalyticsPerPost = useMemo(() => {
    if (!analyticsWithPosts) return new Map<string, AnalyticsWithPost>();

    const map = new Map<string, AnalyticsWithPost>();
    for (const a of analyticsWithPosts) {
      const existing = map.get(a.post_id);
      if (
        !existing ||
        new Date(a.snapshot_at) > new Date(existing.snapshot_at)
      ) {
        map.set(a.post_id, a);
      }
    }
    return map;
  }, [analyticsWithPosts]);

  const tableData = useMemo(() => {
    const entries = Array.from(latestAnalyticsPerPost.values());

    // Apply filters
    let filtered = entries;

    if (platformFilter !== "all") {
      filtered = filtered.filter(
        (a) => a.social_posts?.platform === platformFilter
      );
    }

    if (contentTypeFilter !== "all") {
      filtered = filtered.filter(
        (a) => a.social_posts?.content_type === contentTypeFilter
      );
    }

    // Sort
    filtered.sort((a, b) => {
      let aVal: number | string = 0;
      let bVal: number | string = 0;

      switch (sortField) {
        case "scheduled_at":
          aVal = a.social_posts?.scheduled_at || a.snapshot_at;
          bVal = b.social_posts?.scheduled_at || b.snapshot_at;
          return sortDir === "asc"
            ? aVal.localeCompare(bVal)
            : bVal.localeCompare(aVal);
        case "likes":
          aVal = a.likes;
          bVal = b.likes;
          break;
        case "comments":
          aVal = a.comments;
          bVal = b.comments;
          break;
        case "shares":
          aVal = a.shares;
          bVal = b.shares;
          break;
        case "link_clicks":
          aVal = a.link_clicks;
          bVal = b.link_clicks;
          break;
        case "total":
          aVal = a.likes + a.comments + a.shares + a.link_clicks;
          bVal = b.likes + b.comments + b.shares + b.link_clicks;
          break;
      }

      if (typeof aVal === "number" && typeof bVal === "number") {
        return sortDir === "asc" ? aVal - bVal : bVal - aVal;
      }
      return 0;
    });

    return filtered;
  }, [
    latestAnalyticsPerPost,
    platformFilter,
    contentTypeFilter,
    sortField,
    sortDir,
  ]);

  function handleSort(field: SortField) {
    if (sortField === field) {
      setSortDir((d) => (d === "asc" ? "desc" : "asc"));
    } else {
      setSortField(field);
      setSortDir("desc");
    }
  }

  function formatDate(dateStr: string | null | undefined): string {
    if (!dateStr) return "-";
    return new Date(dateStr).toLocaleDateString("ar-SA", {
      year: "numeric",
      month: "short",
      day: "numeric",
    });
  }

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <BarChart3 className="h-6 w-6 text-primary" />
          <h1 className="text-2xl font-bold">التحليلات</h1>
        </div>
        <Select
          value={String(periodDays)}
          onValueChange={(v) => setPeriodDays(Number(v))}
        >
          <SelectTrigger className="w-[140px]">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="7">٧ أيام</SelectItem>
            <SelectItem value="30">٣٠ يوم</SelectItem>
            <SelectItem value="90">٩٠ يوم</SelectItem>
          </SelectContent>
        </Select>
      </div>

      {/* ======= Section 1: Overview Cards ======= */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Total Published */}
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">المنشورات</p>
                <p className="text-3xl font-bold mt-1">
                  {isLoading ? "..." : overviewStats.publishedCount}
                </p>
                <p className="text-xs text-muted-foreground mt-1">
                  هذا الشهر
                </p>
              </div>
              <div className="h-12 w-12 rounded-full bg-green-500/10 flex items-center justify-center">
                <Send className="h-6 w-6 text-green-600" />
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Total Engagement */}
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">التفاعل</p>
                <p className="text-3xl font-bold mt-1">
                  {isLoading
                    ? "..."
                    : overviewStats.totalEngagement.toLocaleString("ar-SA")}
                </p>
                <p className="text-xs text-muted-foreground mt-1">
                  إعجابات + تعليقات + مشاركات
                </p>
              </div>
              <div className="h-12 w-12 rounded-full bg-pink-500/10 flex items-center justify-center">
                <Heart className="h-6 w-6 text-pink-600" />
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Total Clicks */}
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">النقرات</p>
                <p className="text-3xl font-bold mt-1">
                  {isLoading
                    ? "..."
                    : overviewStats.totalClicks.toLocaleString("ar-SA")}
                </p>
                <p className="text-xs text-muted-foreground mt-1">
                  نقرات الروابط
                </p>
              </div>
              <div className="h-12 w-12 rounded-full bg-blue-500/10 flex items-center justify-center">
                <MousePointerClick className="h-6 w-6 text-blue-600" />
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Top Post */}
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div className="flex-1 min-w-0">
                <p className="text-sm text-muted-foreground">الأفضل أداءً</p>
                <p
                  className="text-sm font-medium mt-1 truncate"
                  title={overviewStats.topPostText}
                >
                  {isLoading ? "..." : overviewStats.topPostText}
                </p>
              </div>
              <div className="h-12 w-12 rounded-full bg-yellow-500/10 flex items-center justify-center shrink-0 mr-3">
                <Trophy className="h-6 w-6 text-yellow-600" />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* ======= Section 2: Charts ======= */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Engagement Over Time */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <TrendingUp className="h-5 w-5" />
              التفاعل عبر الزمن
            </CardTitle>
          </CardHeader>
          <CardContent>
            {engagementTimeData.length === 0 ? (
              <div className="flex items-center justify-center h-[300px] text-muted-foreground">
                لا توجد بيانات كافية
              </div>
            ) : (
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={engagementTimeData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="date" fontSize={12} />
                  <YAxis fontSize={12} />
                  <Tooltip
                    contentStyle={{
                      textAlign: "right",
                      direction: "rtl",
                    }}
                  />
                  <Legend />
                  <Line
                    type="monotone"
                    dataKey="likes"
                    name="إعجابات"
                    stroke="#0d9488"
                    strokeWidth={2}
                    dot={false}
                  />
                  <Line
                    type="monotone"
                    dataKey="comments"
                    name="تعليقات"
                    stroke="#3b82f6"
                    strokeWidth={2}
                    dot={false}
                  />
                  <Line
                    type="monotone"
                    dataKey="shares"
                    name="مشاركات"
                    stroke="#f59e0b"
                    strokeWidth={2}
                    dot={false}
                  />
                </LineChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>

        {/* Content Type Breakdown */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <BarChart3 className="h-5 w-5" />
              أداء نوع المحتوى
            </CardTitle>
          </CardHeader>
          <CardContent>
            {contentTypeData.length === 0 ? (
              <div className="flex items-center justify-center h-[300px] text-muted-foreground">
                لا توجد بيانات كافية
              </div>
            ) : (
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={contentTypeData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="type" fontSize={12} />
                  <YAxis fontSize={12} />
                  <Tooltip
                    contentStyle={{
                      textAlign: "right",
                      direction: "rtl",
                    }}
                  />
                  <Bar
                    dataKey="engagement"
                    name="التفاعل"
                    fill="#0d9488"
                    radius={[4, 4, 0, 0]}
                  />
                </BarChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>

        {/* Platform Comparison */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <BarChart3 className="h-5 w-5" />
              مقارنة المنصات
            </CardTitle>
          </CardHeader>
          <CardContent>
            {platformComparisonData.every(
              (d) => d.twitter === 0 && d.instagram === 0
            ) ? (
              <div className="flex items-center justify-center h-[300px] text-muted-foreground">
                لا توجد بيانات كافية
              </div>
            ) : (
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={platformComparisonData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="metric" fontSize={12} />
                  <YAxis fontSize={12} />
                  <Tooltip
                    contentStyle={{
                      textAlign: "right",
                      direction: "rtl",
                    }}
                  />
                  <Legend />
                  <Bar
                    dataKey="twitter"
                    name="تويتر"
                    fill="#3b82f6"
                    radius={[4, 4, 0, 0]}
                  />
                  <Bar
                    dataKey="instagram"
                    name="إنستغرام"
                    fill="#ec4899"
                    radius={[4, 4, 0, 0]}
                  />
                </BarChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>

        {/* Best Posting Times Heatmap */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <TrendingUp className="h-5 w-5" />
              أفضل أوقات النشر
            </CardTitle>
          </CardHeader>
          <CardContent>
            {heatmapMax === 0 ? (
              <div className="flex items-center justify-center h-[300px] text-muted-foreground">
                لا توجد بيانات كافية
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full border-separate border-spacing-1">
                  <thead>
                    <tr>
                      <th className="text-xs font-medium text-muted-foreground p-2 text-right">
                        اليوم
                      </th>
                      {timePeriods.map((tp) => (
                        <th
                          key={tp.label}
                          className="text-xs font-medium text-muted-foreground p-2 text-center"
                        >
                          {tp.label}
                        </th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {dayNames.map((day, dayIdx) => (
                      <tr key={day}>
                        <td className="text-xs font-medium p-2 text-right whitespace-nowrap">
                          {day}
                        </td>
                        {timePeriods.map((tp, periodIdx) => {
                          const val = heatmapData[dayIdx][periodIdx];
                          return (
                            <td
                              key={tp.label}
                              className={`text-xs text-center p-3 rounded-md transition-colors ${getHeatmapColor(val)}`}
                              title={`${day} ${tp.label}: ${val}`}
                            >
                              {val > 0
                                ? val.toLocaleString("ar-SA")
                                : ""}
                            </td>
                          );
                        })}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* ======= Section 3: Post Performance Table ======= */}
      <Card>
        <CardHeader>
          <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
            <CardTitle>أداء المنشورات</CardTitle>
            <div className="flex items-center gap-3 flex-wrap">
              {/* Platform Filter */}
              <Select
                value={platformFilter}
                onValueChange={setPlatformFilter}
              >
                <SelectTrigger className="w-[130px]">
                  <SelectValue placeholder="المنصة" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">الكل</SelectItem>
                  <SelectItem value="twitter">تويتر</SelectItem>
                  <SelectItem value="instagram">إنستغرام</SelectItem>
                </SelectContent>
              </Select>

              {/* Content Type Filter */}
              <Select
                value={contentTypeFilter}
                onValueChange={setContentTypeFilter}
              >
                <SelectTrigger className="w-[150px]">
                  <SelectValue placeholder="نوع المحتوى" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">كل الأنواع</SelectItem>
                  {Object.entries(contentTypeLabels).map(([value, label]) => (
                    <SelectItem key={value} value={value}>
                      {label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="text-center py-8 text-muted-foreground">
              جاري التحميل...
            </div>
          ) : tableData.length === 0 ? (
            <div className="text-center py-12 text-muted-foreground">
              <BarChart3 className="h-12 w-12 mx-auto mb-4 opacity-30" />
              <p className="text-lg font-medium">
                لا توجد بيانات تحليلية بعد
              </p>
              <p className="text-sm mt-2">
                ستظهر البيانات بعد نشر منشورات.
              </p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>
                      <Button
                        variant="ghost"
                        size="sm"
                        className="gap-1 font-medium"
                        onClick={() => handleSort("scheduled_at")}
                      >
                        التاريخ
                        <ArrowUpDown className="h-3 w-3" />
                      </Button>
                    </TableHead>
                    <TableHead>المنصة</TableHead>
                    <TableHead>المحتوى</TableHead>
                    <TableHead>
                      <Button
                        variant="ghost"
                        size="sm"
                        className="gap-1 font-medium"
                        onClick={() => handleSort("likes")}
                      >
                        إعجابات
                        <ArrowUpDown className="h-3 w-3" />
                      </Button>
                    </TableHead>
                    <TableHead>
                      <Button
                        variant="ghost"
                        size="sm"
                        className="gap-1 font-medium"
                        onClick={() => handleSort("comments")}
                      >
                        تعليقات
                        <ArrowUpDown className="h-3 w-3" />
                      </Button>
                    </TableHead>
                    <TableHead>
                      <Button
                        variant="ghost"
                        size="sm"
                        className="gap-1 font-medium"
                        onClick={() => handleSort("shares")}
                      >
                        مشاركات
                        <ArrowUpDown className="h-3 w-3" />
                      </Button>
                    </TableHead>
                    <TableHead>
                      <Button
                        variant="ghost"
                        size="sm"
                        className="gap-1 font-medium"
                        onClick={() => handleSort("link_clicks")}
                      >
                        نقرات
                        <ArrowUpDown className="h-3 w-3" />
                      </Button>
                    </TableHead>
                    <TableHead>
                      <Button
                        variant="ghost"
                        size="sm"
                        className="gap-1 font-medium"
                        onClick={() => handleSort("total")}
                      >
                        التفاعل الكلي
                        <ArrowUpDown className="h-3 w-3" />
                      </Button>
                    </TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {tableData.map((row) => {
                    const platform =
                      platformLabels[row.social_posts?.platform || ""] || null;
                    const totalEngagement =
                      row.likes + row.comments + row.shares + row.link_clicks;

                    return (
                      <TableRow key={row.id}>
                        <TableCell className="whitespace-nowrap text-sm">
                          {formatDate(
                            row.social_posts?.scheduled_at || row.snapshot_at
                          )}
                        </TableCell>
                        <TableCell>
                          {platform ? (
                            <Badge className={platform.color}>
                              {platform.label}
                            </Badge>
                          ) : (
                            "-"
                          )}
                        </TableCell>
                        <TableCell
                          className="max-w-[200px] truncate text-sm"
                          title={row.social_posts?.text_ar || ""}
                        >
                          {row.social_posts?.text_ar?.slice(0, 50) || "-"}
                          {(row.social_posts?.text_ar?.length || 0) > 50
                            ? "..."
                            : ""}
                        </TableCell>
                        <TableCell className="text-center tabular-nums">
                          {row.likes.toLocaleString("ar-SA")}
                        </TableCell>
                        <TableCell className="text-center tabular-nums">
                          {row.comments.toLocaleString("ar-SA")}
                        </TableCell>
                        <TableCell className="text-center tabular-nums">
                          {row.shares.toLocaleString("ar-SA")}
                        </TableCell>
                        <TableCell className="text-center tabular-nums">
                          {row.link_clicks.toLocaleString("ar-SA")}
                        </TableCell>
                        <TableCell className="text-center font-semibold tabular-nums">
                          {totalEngagement.toLocaleString("ar-SA")}
                        </TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
              </Table>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
