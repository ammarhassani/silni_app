"use client";

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import {
  MessageSquare,
  MessagesSquare,
  Brain,
  TrendingUp,
  Calendar,
  Clock,
  Archive,
  BarChart3,
} from "lucide-react";
import {
  useConversationStats,
  useRecentConversations,
  useMemoryStats,
  useConversationActivity,
  modeLabels,
  memoryCategoryLabels,
} from "@/hooks/use-ai-conversations";
import { formatDistanceToNow } from "date-fns";
import { ar } from "date-fns/locale";

export default function AIConversationsPage() {
  const { data: stats, isLoading: statsLoading } = useConversationStats();
  const { data: recentConvs, isLoading: recentLoading } = useRecentConversations(15);
  const { data: memoryStats, isLoading: memoryLoading } = useMemoryStats();
  const { data: activity, isLoading: activityLoading } = useConversationActivity(14);

  // Calculate max for chart scaling
  const maxActivity = activity ? Math.max(...activity.map((d) => d.count), 1) : 1;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <div className="w-14 h-14 bg-gradient-to-br from-violet-500 to-purple-600 rounded-2xl flex items-center justify-center shadow-lg">
          <MessagesSquare className="h-7 w-7 text-white" />
        </div>
        <div>
          <h1 className="text-3xl font-bold">محادثات الذكاء الاصطناعي</h1>
          <p className="text-muted-foreground mt-1">
            إحصائيات ونظرة عامة على استخدام واصل
          </p>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">إجمالي المحادثات</p>
                {statsLoading ? (
                  <Skeleton className="h-8 w-16 mt-1" />
                ) : (
                  <p className="text-2xl font-bold">
                    {stats?.total_conversations?.toLocaleString() || 0}
                  </p>
                )}
              </div>
              <MessagesSquare className="h-8 w-8 text-violet-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">إجمالي الرسائل</p>
                {statsLoading ? (
                  <Skeleton className="h-8 w-16 mt-1" />
                ) : (
                  <p className="text-2xl font-bold">
                    {stats?.total_messages?.toLocaleString() || 0}
                  </p>
                )}
              </div>
              <MessageSquare className="h-8 w-8 text-blue-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">محادثات اليوم</p>
                {statsLoading ? (
                  <Skeleton className="h-8 w-16 mt-1" />
                ) : (
                  <p className="text-2xl font-bold text-green-600">
                    +{stats?.conversations_today || 0}
                  </p>
                )}
              </div>
              <TrendingUp className="h-8 w-8 text-green-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">رسائل اليوم</p>
                {statsLoading ? (
                  <Skeleton className="h-8 w-16 mt-1" />
                ) : (
                  <p className="text-2xl font-bold text-blue-600">
                    +{stats?.messages_today || 0}
                  </p>
                )}
              </div>
              <Calendar className="h-8 w-8 text-blue-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">متوسط الرسائل</p>
                {statsLoading ? (
                  <Skeleton className="h-8 w-16 mt-1" />
                ) : (
                  <p className="text-2xl font-bold">
                    {stats?.avg_messages_per_conversation || 0}
                  </p>
                )}
              </div>
              <BarChart3 className="h-8 w-8 text-orange-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">ذكريات محفوظة</p>
                {memoryLoading ? (
                  <Skeleton className="h-8 w-16 mt-1" />
                ) : (
                  <p className="text-2xl font-bold">
                    {memoryStats?.total?.toLocaleString() || 0}
                  </p>
                )}
              </div>
              <Brain className="h-8 w-8 text-purple-500" />
            </div>
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Activity Chart */}
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle className="text-lg flex items-center gap-2">
              <TrendingUp className="h-5 w-5" />
              نشاط المحادثات (14 يوم)
            </CardTitle>
          </CardHeader>
          <CardContent>
            {activityLoading ? (
              <Skeleton className="h-40 w-full" />
            ) : (
              <div className="flex items-end gap-1 h-40">
                {activity?.map((day, i) => (
                  <div
                    key={day.date}
                    className="flex-1 flex flex-col items-center gap-1"
                  >
                    <div
                      className="w-full bg-violet-500/80 rounded-t transition-all hover:bg-violet-600"
                      style={{
                        height: `${Math.max((day.count / maxActivity) * 100, 4)}%`,
                        minHeight: day.count > 0 ? "8px" : "2px",
                      }}
                      title={`${day.date}: ${day.count} محادثة`}
                    />
                    {i % 2 === 0 && (
                      <span className="text-[10px] text-muted-foreground">
                        {new Date(day.date).getDate()}
                      </span>
                    )}
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>

        {/* Modes Distribution */}
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">توزيع الأوضاع</CardTitle>
            <CardDescription>أكثر أوضاع الاستشارة استخداماً</CardDescription>
          </CardHeader>
          <CardContent>
            {statsLoading ? (
              <div className="space-y-3">
                {[...Array(4)].map((_, i) => (
                  <Skeleton key={i} className="h-8 w-full" />
                ))}
              </div>
            ) : (
              <div className="space-y-3">
                {Object.entries(stats?.by_mode || {})
                  .sort((a, b) => b[1] - a[1])
                  .map(([mode, count]) => {
                    const total = stats?.total_conversations || 1;
                    const percentage = Math.round((count / total) * 100);
                    return (
                      <div key={mode} className="space-y-1">
                        <div className="flex justify-between text-sm">
                          <span>{modeLabels[mode] || mode}</span>
                          <span className="text-muted-foreground">
                            {count} ({percentage}%)
                          </span>
                        </div>
                        <div className="h-2 bg-muted rounded-full overflow-hidden">
                          <div
                            className="h-full bg-violet-500 rounded-full"
                            style={{ width: `${percentage}%` }}
                          />
                        </div>
                      </div>
                    );
                  })}
                {Object.keys(stats?.by_mode || {}).length === 0 && (
                  <p className="text-sm text-muted-foreground text-center py-4">
                    لا توجد بيانات
                  </p>
                )}
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Recent Conversations */}
        <Card>
          <CardHeader>
            <CardTitle className="text-lg flex items-center gap-2">
              <Clock className="h-5 w-5" />
              آخر المحادثات
            </CardTitle>
            <CardDescription>نظرة عامة على المحادثات الأخيرة</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {recentLoading ? (
                [...Array(5)].map((_, i) => (
                  <div key={i} className="flex items-center gap-3">
                    <Skeleton className="w-10 h-10 rounded" />
                    <div className="flex-1">
                      <Skeleton className="h-4 w-3/4" />
                      <Skeleton className="h-3 w-1/2 mt-1" />
                    </div>
                  </div>
                ))
              ) : recentConvs && recentConvs.length > 0 ? (
                recentConvs.slice(0, 8).map((conv) => (
                  <div
                    key={conv.id}
                    className="flex items-center gap-3 p-2 rounded-lg hover:bg-muted/50"
                  >
                    <div className="w-10 h-10 rounded-lg bg-violet-500/10 flex items-center justify-center">
                      <MessageSquare className="h-5 w-5 text-violet-500" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium truncate">
                        {conv.title || "محادثة بدون عنوان"}
                      </p>
                      <div className="flex items-center gap-2 mt-0.5">
                        <Badge variant="secondary" className="text-[10px]">
                          {modeLabels[conv.mode] || conv.mode}
                        </Badge>
                        <span className="text-xs text-muted-foreground">
                          {conv.message_count} رسالة
                        </span>
                        <span className="text-xs text-muted-foreground">
                          {formatDistanceToNow(new Date(conv.updated_at), {
                            addSuffix: true,
                            locale: ar,
                          })}
                        </span>
                      </div>
                    </div>
                    {conv.is_archived && (
                      <Archive className="h-4 w-4 text-muted-foreground" />
                    )}
                  </div>
                ))
              ) : (
                <div className="text-center py-8 text-muted-foreground">
                  <MessagesSquare className="h-8 w-8 mx-auto mb-2 opacity-50" />
                  <p>لا توجد محادثات</p>
                </div>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Memory Categories */}
        <Card>
          <CardHeader>
            <CardTitle className="text-lg flex items-center gap-2">
              <Brain className="h-5 w-5" />
              توزيع الذكريات
            </CardTitle>
            <CardDescription>
              الذكريات المحفوظة حسب التصنيف
              {memoryStats && (
                <span className="mr-2">
                  • متوسط الأهمية: {memoryStats.avg_importance}
                </span>
              )}
            </CardDescription>
          </CardHeader>
          <CardContent>
            {memoryLoading ? (
              <div className="space-y-3">
                {[...Array(5)].map((_, i) => (
                  <Skeleton key={i} className="h-8 w-full" />
                ))}
              </div>
            ) : (
              <div className="space-y-3">
                {Object.entries(memoryStats?.by_category || {})
                  .sort((a, b) => b[1] - a[1])
                  .map(([category, count]) => {
                    const total = memoryStats?.total || 1;
                    const percentage = Math.round((count / total) * 100);
                    return (
                      <div key={category} className="space-y-1">
                        <div className="flex justify-between text-sm">
                          <span>{memoryCategoryLabels[category] || category}</span>
                          <span className="text-muted-foreground">
                            {count} ({percentage}%)
                          </span>
                        </div>
                        <div className="h-2 bg-muted rounded-full overflow-hidden">
                          <div
                            className="h-full bg-purple-500 rounded-full"
                            style={{ width: `${percentage}%` }}
                          />
                        </div>
                      </div>
                    );
                  })}
                {Object.keys(memoryStats?.by_category || {}).length === 0 && (
                  <p className="text-sm text-muted-foreground text-center py-4">
                    لا توجد ذكريات محفوظة
                  </p>
                )}
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Privacy Notice */}
      <Card className="border-amber-500/20 bg-amber-500/5">
        <CardContent className="pt-6">
          <div className="flex items-start gap-3">
            <div className="w-10 h-10 rounded-lg bg-amber-500/10 flex items-center justify-center shrink-0">
              <Brain className="h-5 w-5 text-amber-600" />
            </div>
            <div>
              <p className="font-medium text-amber-800 dark:text-amber-200">
                ملاحظة الخصوصية
              </p>
              <p className="text-sm text-amber-700 dark:text-amber-300 mt-1">
                محتوى المحادثات الفعلي محمي ومتاح للمستخدم فقط. هذه الصفحة تعرض
                إحصائيات مجمّعة فقط دون الكشف عن أي معلومات شخصية أو محتوى المحادثات.
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
