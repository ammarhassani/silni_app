"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import {
  useDashboardOverview,
  useUserGrowth,
  useSubscriptionDistribution,
  useInteractionStats,
  useGamificationStats,
  useSubscriptionEventStats,
  useTopActiveUsers,
} from "@/hooks/use-analytics";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { Button } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Users,
  UserPlus,
  Activity,
  TrendingUp,
  Crown,
  Phone,
  MessageSquare,
  Gift,
  Calendar,
  Star,
  Award,
  Flame,
  Zap,
  DollarSign,
  BarChart3,
  PieChart,
  Heart,
  Eye,
} from "lucide-react";

const interactionTypeLabels: Record<string, string> = {
  call: "مكالمة",
  visit: "زيارة",
  message: "رسالة",
  gift: "هدية",
  event: "مناسبة",
  other: "أخرى",
};

const interactionTypeIcons: Record<string, React.ElementType> = {
  call: Phone,
  visit: Eye,
  message: MessageSquare,
  gift: Gift,
  event: Calendar,
  other: Activity,
};

function StatCard({
  title,
  value,
  description,
  icon: Icon,
  trend,
  loading,
  gradient,
}: {
  title: string;
  value: string | number;
  description?: string;
  icon: React.ElementType;
  trend?: { value: number; label: string };
  loading?: boolean;
  gradient?: string;
}) {
  return (
    <Card className={gradient ? `bg-gradient-to-br ${gradient} border-0` : ""}>
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <CardTitle className="text-sm font-medium">{title}</CardTitle>
        <Icon className={`h-4 w-4 ${gradient ? "text-white/70" : "text-muted-foreground"}`} />
      </CardHeader>
      <CardContent>
        {loading ? (
          <Skeleton className="h-8 w-20" />
        ) : (
          <>
            <div className={`text-2xl font-bold ${gradient ? "text-white" : ""}`}>
              {typeof value === "number" ? value.toLocaleString("ar-SA") : value}
            </div>
            {description && (
              <p className={`text-xs ${gradient ? "text-white/70" : "text-muted-foreground"}`}>
                {description}
              </p>
            )}
            {trend && (
              <div className="flex items-center gap-1 mt-1">
                <TrendingUp className={`h-3 w-3 ${trend.value >= 0 ? "text-green-500" : "text-red-500"}`} />
                <span className={`text-xs font-medium ${trend.value >= 0 ? "text-green-600" : "text-red-600"}`}>
                  {trend.value >= 0 ? "+" : ""}{trend.value}% {trend.label}
                </span>
              </div>
            )}
          </>
        )}
      </CardContent>
    </Card>
  );
}

export default function AnalyticsPage() {
  const [showDebug, setShowDebug] = useState(false);
  const supabase = createClient();

  const { data: debugData, refetch: refetchDebug, isLoading: debugLoading } = useQuery({
    queryKey: ["debug-admin-stats"],
    queryFn: async () => {
      const { data, error } = await supabase.rpc("debug_admin_stats");
      if (error) return { error: error.message };
      return data;
    },
    enabled: showDebug,
  });

  const { data: overview, isLoading: overviewLoading } = useDashboardOverview();
  const { data: userGrowth, isLoading: growthLoading } = useUserGrowth(30);
  const { data: subscriptionDist, isLoading: subDistLoading } = useSubscriptionDistribution();
  const { data: interactionStats, isLoading: interactionLoading } = useInteractionStats();
  const { data: gamificationStats, isLoading: gamificationLoading } = useGamificationStats();
  const { data: subscriptionEvents, isLoading: subEventsLoading } = useSubscriptionEventStats();
  const { data: topUsers, isLoading: topUsersLoading } = useTopActiveUsers(10);

  // Calculate growth chart max for visual bar
  const maxGrowth = Math.max(...(userGrowth?.map((d) => d.count) || [1]), 1);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <div className="w-14 h-14 bg-gradient-to-br from-blue-500 to-purple-600 rounded-2xl flex items-center justify-center shadow-lg">
            <BarChart3 className="h-7 w-7 text-white" />
          </div>
          <div>
            <h1 className="text-3xl font-bold">لوحة التحليلات</h1>
            <p className="text-muted-foreground mt-1">
              نظرة شاملة على أداء التطبيق والمستخدمين
            </p>
          </div>
        </div>
        <Button variant="outline" size="sm" onClick={() => { setShowDebug(!showDebug); if (!showDebug) refetchDebug(); }}>
          {showDebug ? "إخفاء التصحيح" : "عرض التصحيح"}
        </Button>
      </div>

      {/* Debug Info */}
      {showDebug && (
        <Card className="border-yellow-500/50 bg-yellow-500/5">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-yellow-600">معلومات التصحيح</CardTitle>
          </CardHeader>
          <CardContent>
            {debugLoading ? (
              <Skeleton className="h-20 w-full" />
            ) : (
              <pre className="text-xs overflow-auto max-h-60 bg-black/5 p-3 rounded">
                {JSON.stringify(debugData, null, 2)}
              </pre>
            )}
          </CardContent>
        </Card>
      )}

      {/* Overview Stats */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="إجمالي المستخدمين"
          value={overview?.total_users || 0}
          icon={Users}
          loading={overviewLoading}
          gradient="from-blue-500 to-blue-600"
        />
        <StatCard
          title="مستخدمون جدد اليوم"
          value={overview?.new_users_today || 0}
          description={`${overview?.new_users_week || 0} هذا الأسبوع`}
          icon={UserPlus}
          loading={overviewLoading}
          gradient="from-green-500 to-emerald-600"
        />
        <StatCard
          title="المستخدمون النشطون اليوم"
          value={overview?.active_users_today || 0}
          description={`${overview?.active_users_week || 0} هذا الأسبوع`}
          icon={Activity}
          loading={overviewLoading}
          gradient="from-orange-500 to-amber-600"
        />
        <StatCard
          title="المشتركون (MAX)"
          value={overview?.premium_users || 0}
          description={`${overview?.free_users || 0} مجاني`}
          icon={Crown}
          loading={overviewLoading}
          gradient="from-purple-500 to-pink-600"
        />
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        {/* User Growth Chart */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <TrendingUp className="h-5 w-5 text-blue-500" />
              نمو المستخدمين (آخر 30 يوم)
            </CardTitle>
            <CardDescription>
              عدد المستخدمين الجدد يومياً
            </CardDescription>
          </CardHeader>
          <CardContent>
            {growthLoading ? (
              <Skeleton className="h-48 w-full" />
            ) : (
              <div className="space-y-2">
                <div className="flex items-end gap-1 h-40">
                  {userGrowth?.map((day, i) => (
                    <div
                      key={day.date}
                      className="flex-1 bg-blue-500/20 rounded-t relative group"
                      style={{ height: `${(day.count / maxGrowth) * 100}%`, minHeight: "4px" }}
                    >
                      <div
                        className="absolute bottom-0 left-0 right-0 bg-blue-500 rounded-t transition-all"
                        style={{ height: "100%" }}
                      />
                      <div className="absolute -top-8 left-1/2 -translate-x-1/2 bg-black text-white text-xs px-2 py-1 rounded opacity-0 group-hover:opacity-100 whitespace-nowrap z-10">
                        {day.count} مستخدم
                        <br />
                        {new Date(day.date).toLocaleDateString("ar-SA", { month: "short", day: "numeric" })}
                      </div>
                    </div>
                  ))}
                </div>
                <div className="flex justify-between text-xs text-muted-foreground">
                  <span>قبل 30 يوم</span>
                  <span>اليوم</span>
                </div>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Subscription Distribution */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <PieChart className="h-5 w-5 text-purple-500" />
              توزيع الاشتراكات
            </CardTitle>
            <CardDescription>
              تصنيف المستخدمين حسب نوع الاشتراك
            </CardDescription>
          </CardHeader>
          <CardContent>
            {subDistLoading ? (
              <Skeleton className="h-48 w-full" />
            ) : (
              <div className="space-y-4">
                <div className="flex gap-4">
                  {/* Pie chart representation */}
                  <div className="relative w-32 h-32">
                    <svg className="w-full h-full transform -rotate-90" viewBox="0 0 32 32">
                      {(() => {
                        const total = (subscriptionDist?.free || 0) + (subscriptionDist?.premium || 0) + (subscriptionDist?.trial || 0) || 1;
                        const freePercent = ((subscriptionDist?.free || 0) / total) * 100;
                        const premiumPercent = ((subscriptionDist?.premium || 0) / total) * 100;
                        const trialPercent = ((subscriptionDist?.trial || 0) / total) * 100;

                        const freeOffset = 0;
                        const premiumOffset = freePercent;
                        const trialOffset = freePercent + premiumPercent;

                        return (
                          <>
                            <circle
                              cx="16" cy="16" r="12"
                              fill="none"
                              stroke="hsl(var(--muted))"
                              strokeWidth="6"
                              strokeDasharray={`${freePercent} ${100 - freePercent}`}
                              strokeDashoffset={-freeOffset}
                            />
                            <circle
                              cx="16" cy="16" r="12"
                              fill="none"
                              stroke="hsl(280 100% 70%)"
                              strokeWidth="6"
                              strokeDasharray={`${premiumPercent} ${100 - premiumPercent}`}
                              strokeDashoffset={-premiumOffset}
                            />
                            <circle
                              cx="16" cy="16" r="12"
                              fill="none"
                              stroke="hsl(45 100% 60%)"
                              strokeWidth="6"
                              strokeDasharray={`${trialPercent} ${100 - trialPercent}`}
                              strokeDashoffset={-trialOffset}
                            />
                          </>
                        );
                      })()}
                    </svg>
                  </div>
                  <div className="flex-1 space-y-3">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <div className="w-3 h-3 rounded-full bg-muted" />
                        <span className="text-sm">مجاني</span>
                      </div>
                      <span className="font-bold">{subscriptionDist?.free.toLocaleString("ar-SA")}</span>
                    </div>
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <div className="w-3 h-3 rounded-full bg-purple-500" />
                        <span className="text-sm">MAX</span>
                      </div>
                      <span className="font-bold">{subscriptionDist?.premium.toLocaleString("ar-SA")}</span>
                    </div>
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <div className="w-3 h-3 rounded-full bg-amber-400" />
                        <span className="text-sm">تجريبي</span>
                      </div>
                      <span className="font-bold">{subscriptionDist?.trial.toLocaleString("ar-SA")}</span>
                    </div>
                  </div>
                </div>
                <div className="pt-4 border-t">
                  <div className="grid grid-cols-3 gap-4 text-center">
                    <div>
                      <p className="text-2xl font-bold text-green-600">
                        {subscriptionEvents?.purchases || 0}
                      </p>
                      <p className="text-xs text-muted-foreground">مشتريات</p>
                    </div>
                    <div>
                      <p className="text-2xl font-bold text-amber-600">
                        {subscriptionEvents?.trials_started || 0}
                      </p>
                      <p className="text-xs text-muted-foreground">تجارب</p>
                    </div>
                    <div>
                      <p className="text-2xl font-bold text-red-600">
                        {subscriptionEvents?.cancellations || 0}
                      </p>
                      <p className="text-xs text-muted-foreground">إلغاءات</p>
                    </div>
                  </div>
                </div>
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Interaction & Gamification Stats */}
      <div className="grid gap-6 lg:grid-cols-2">
        {/* Interaction Stats */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Heart className="h-5 w-5 text-rose-500" />
              إحصائيات التواصل
            </CardTitle>
            <CardDescription>
              {interactionStats?.total.toLocaleString("ar-SA")} تفاعل إجمالي
            </CardDescription>
          </CardHeader>
          <CardContent>
            {interactionLoading ? (
              <Skeleton className="h-48 w-full" />
            ) : (
              <div className="space-y-4">
                <div className="grid grid-cols-3 gap-4">
                  <div className="text-center p-3 bg-green-50 dark:bg-green-950 rounded-lg">
                    <p className="text-2xl font-bold text-green-600">{interactionStats?.today || 0}</p>
                    <p className="text-xs text-muted-foreground">اليوم</p>
                  </div>
                  <div className="text-center p-3 bg-blue-50 dark:bg-blue-950 rounded-lg">
                    <p className="text-2xl font-bold text-blue-600">{interactionStats?.this_week || 0}</p>
                    <p className="text-xs text-muted-foreground">آخر ٧ أيام</p>
                  </div>
                  <div className="text-center p-3 bg-purple-50 dark:bg-purple-950 rounded-lg">
                    <p className="text-2xl font-bold text-purple-600">{interactionStats?.this_month || 0}</p>
                    <p className="text-xs text-muted-foreground">آخر ٣٠ يوم</p>
                  </div>
                </div>
                <div className="space-y-2">
                  <p className="text-sm font-medium">حسب النوع:</p>
                  {Object.entries(interactionStats?.by_type || {}).map(([type, count]) => {
                    const Icon = interactionTypeIcons[type] || Activity;
                    const total = interactionStats?.total || 1;
                    const percentage = ((count as number) / total) * 100;
                    return (
                      <div key={type} className="flex items-center gap-3">
                        <Icon className="h-4 w-4 text-muted-foreground" />
                        <span className="text-sm w-16">{interactionTypeLabels[type] || type}</span>
                        <div className="flex-1 bg-muted rounded-full h-2">
                          <div
                            className="bg-primary rounded-full h-2 transition-all"
                            style={{ width: `${percentage}%` }}
                          />
                        </div>
                        <span className="text-sm font-medium w-12 text-left">
                          {(count as number).toLocaleString("ar-SA")}
                        </span>
                      </div>
                    );
                  })}
                </div>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Gamification Stats */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Star className="h-5 w-5 text-amber-500" />
              إحصائيات التلعيب
            </CardTitle>
            <CardDescription>
              متوسطات المستخدمين في نظام النقاط والمستويات
            </CardDescription>
          </CardHeader>
          <CardContent>
            {gamificationLoading ? (
              <Skeleton className="h-48 w-full" />
            ) : (
              <div className="grid grid-cols-2 gap-4">
                <div className="p-4 rounded-lg bg-gradient-to-br from-amber-50 to-orange-50 dark:from-amber-950 dark:to-orange-950">
                  <div className="flex items-center gap-2 mb-2">
                    <Zap className="h-5 w-5 text-amber-500" />
                    <span className="text-sm text-muted-foreground">إجمالي النقاط</span>
                  </div>
                  <p className="text-2xl font-bold">{gamificationStats?.total_points.toLocaleString("ar-SA")}</p>
                  <p className="text-xs text-muted-foreground">
                    متوسط: {gamificationStats?.avg_points.toLocaleString("ar-SA")} نقطة
                  </p>
                </div>
                <div className="p-4 rounded-lg bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-blue-950 dark:to-indigo-950">
                  <div className="flex items-center gap-2 mb-2">
                    <TrendingUp className="h-5 w-5 text-blue-500" />
                    <span className="text-sm text-muted-foreground">متوسط المستوى</span>
                  </div>
                  <p className="text-2xl font-bold">{gamificationStats?.avg_level}</p>
                  <p className="text-xs text-muted-foreground">من 10 مستويات</p>
                </div>
                <div className="p-4 rounded-lg bg-gradient-to-br from-red-50 to-rose-50 dark:from-red-950 dark:to-rose-950">
                  <div className="flex items-center gap-2 mb-2">
                    <Flame className="h-5 w-5 text-red-500" />
                    <span className="text-sm text-muted-foreground">متوسط السلسلة</span>
                  </div>
                  <p className="text-2xl font-bold">{gamificationStats?.avg_streak} يوم</p>
                  <p className="text-xs text-muted-foreground">
                    أعلى: {gamificationStats?.max_streak} يوم
                  </p>
                </div>
                <div className="p-4 rounded-lg bg-gradient-to-br from-purple-50 to-pink-50 dark:from-purple-950 dark:to-pink-950">
                  <div className="flex items-center gap-2 mb-2">
                    <Award className="h-5 w-5 text-purple-500" />
                    <span className="text-sm text-muted-foreground">حاملو الأوسمة</span>
                  </div>
                  <p className="text-2xl font-bold">{gamificationStats?.users_with_badges.toLocaleString("ar-SA")}</p>
                  <p className="text-xs text-muted-foreground">مستخدم لديه وسام أو أكثر</p>
                </div>
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Top Users */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Crown className="h-5 w-5 text-amber-500" />
            أكثر المستخدمين نشاطاً
          </CardTitle>
          <CardDescription>
            المستخدمون الأعلى في عدد التفاعلات
          </CardDescription>
        </CardHeader>
        <CardContent>
          {topUsersLoading ? (
            <div className="space-y-4">
              {[...Array(5)].map((_, i) => (
                <Skeleton key={i} className="h-12 w-full" />
              ))}
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="w-12">#</TableHead>
                  <TableHead>المستخدم</TableHead>
                  <TableHead>التفاعلات</TableHead>
                  <TableHead>السلسلة</TableHead>
                  <TableHead>المستوى</TableHead>
                  <TableHead>النقاط</TableHead>
                  <TableHead>الاشتراك</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {topUsers?.map((user, index) => (
                  <TableRow key={user.id}>
                    <TableCell>
                      {index < 3 ? (
                        <span className={`text-lg ${index === 0 ? "text-amber-500" : index === 1 ? "text-gray-400" : "text-amber-700"}`}>
                          {index === 0 ? "🥇" : index === 1 ? "🥈" : "🥉"}
                        </span>
                      ) : (
                        <span className="text-muted-foreground">{index + 1}</span>
                      )}
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-2">
                        <div className="w-8 h-8 rounded-full bg-gradient-to-br from-primary/20 to-primary/40 flex items-center justify-center text-sm font-medium">
                          {user.full_name?.[0] || user.email?.[0] || "?"}
                        </div>
                        <div>
                          <p className="font-medium text-sm">{user.full_name || "—"}</p>
                          <p className="text-xs text-muted-foreground">{user.email}</p>
                        </div>
                      </div>
                    </TableCell>
                    <TableCell className="font-bold">{(user.total_interactions || 0).toLocaleString("ar-SA")}</TableCell>
                    <TableCell>
                      <div className="flex items-center gap-1">
                        <Flame className="h-4 w-4 text-orange-500" />
                        {user.current_streak || 0}
                      </div>
                    </TableCell>
                    <TableCell>
                      <Badge variant="secondary">المستوى {user.level || 1}</Badge>
                    </TableCell>
                    <TableCell>{(user.points || 0).toLocaleString("ar-SA")}</TableCell>
                    <TableCell>
                      <Badge variant={user.subscription_status === "premium" ? "default" : "secondary"}>
                        {user.subscription_status === "premium" ? "MAX" : "مجاني"}
                      </Badge>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
