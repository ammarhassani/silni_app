"use client";

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import {
  BookOpen,
  Trophy,
  Bell,
  Palette,
  Brain,
  CreditCard,
  Quote,
  Award,
  TrendingUp,
  Target,
  Flame,
  Crown,
  Package,
  Lock,
  FileText,
  Clock,
  Paintbrush,
  Layers,
  Sparkles,
  Database,
  Server,
  HardDrive,
  CheckCircle2,
  XCircle,
  AlertCircle,
  Activity,
  Users,
  UserPlus,
  Zap,
  CalendarDays,
  History,
  ArrowUpRight,
  MessageSquare,
} from "lucide-react";
import Link from "next/link";
import { useDashboardStats, useSystemHealth, useRecentActivity } from "@/hooks/use-dashboard";
import { useDashboardOverview, useSubscriptionDistribution } from "@/hooks/use-analytics";
import { useAuditLogs, actionLabels, actionColors, resourceLabels, AuditLogEntry } from "@/hooks/use-audit-log";
import { useCalendarEvents, eventTypeLabels, eventTypeColors, CalendarEvent } from "@/hooks/use-calendar";
import { formatDistanceToNow, format } from "date-fns";
import { ar } from "date-fns/locale";

interface ModuleCard {
  title: string;
  description: string;
  icon: React.ElementType;
  href: string;
  color: string;
  stats?: { label: string; value: number | string }[];
}

export default function DashboardPage() {
  const { data: stats, isLoading: statsLoading } = useDashboardStats();
  const { data: health, isLoading: healthLoading } = useSystemHealth();
  const { data: activity, isLoading: activityLoading } = useRecentActivity();

  // New analytics hooks
  const { data: overview, isLoading: overviewLoading } = useDashboardOverview();
  const { data: subscriptionDist, isLoading: subscriptionLoading } = useSubscriptionDistribution();
  const { data: auditLogs, isLoading: auditLoading } = useAuditLogs({ limit: 5 });

  // Calendar for upcoming content
  const today = new Date();
  const endDate = new Date(today.getFullYear(), today.getMonth() + 1, today.getDate());
  const { data: upcomingContent, isLoading: calendarLoading } = useCalendarEvents(
    today.toISOString(),
    endDate.toISOString()
  );

  const modules: ModuleCard[] = [
    {
      title: "إدارة المحتوى",
      description: "إدارة الأحاديث والاقتباسات والرسائل",
      icon: BookOpen,
      href: "/content/hadith",
      color: "bg-blue-500/10 text-blue-500",
      stats: stats
        ? [
            { label: "أحاديث", value: stats.content.hadithCount },
            { label: "اقتباسات", value: stats.content.quotesCount },
            { label: "رسائل", value: stats.content.messagesCount },
          ]
        : undefined,
    },
    {
      title: "التلعيب",
      description: "إعداد النقاط والأوسمة والمستويات والتحديات",
      icon: Trophy,
      href: "/gamification/points",
      color: "bg-yellow-500/10 text-yellow-500",
      stats: stats
        ? [
            { label: "أوسمة", value: stats.gamification.badgesCount },
            { label: "مستويات", value: stats.gamification.levelsCount },
            { label: "تحديات نشطة", value: stats.gamification.challengesCount },
            { label: "السلسلة", value: stats.gamification.activeStreakConfig ? "مفعّل" : "معطّل" },
          ]
        : undefined,
    },
    {
      title: "الاشتراكات",
      description: "إدارة الباقات والمنتجات والميزات",
      icon: CreditCard,
      href: "/subscriptions/tiers",
      color: "bg-silni-teal/10 text-silni-teal",
      stats: stats
        ? [
            { label: "باقات", value: stats.subscriptions.tiersCount },
            { label: "منتجات", value: stats.subscriptions.productsCount },
            { label: "ميزات", value: stats.subscriptions.featuresCount },
          ]
        : undefined,
    },
    {
      title: "الإشعارات",
      description: "قوالب الإشعارات والفترات الزمنية",
      icon: Bell,
      href: "/notifications/templates",
      color: "bg-red-500/10 text-red-500",
      stats: stats
        ? [
            { label: "قوالب", value: stats.notifications.templatesCount },
            { label: "فترات زمنية", value: stats.notifications.timeSlotsCount },
          ]
        : undefined,
    },
    {
      title: "نظام التصميم",
      description: "الألوان والثيمات وتأثيرات الأنماط",
      icon: Palette,
      href: "/design/colors",
      color: "bg-purple-500/10 text-purple-500",
      stats: stats
        ? [
            { label: "ألوان", value: stats.design.colorsCount },
            { label: "ثيمات", value: stats.design.themesCount },
            { label: "تأثيرات", value: stats.design.animationsCount },
          ]
        : undefined,
    },
    {
      title: "الذكاء الاصطناعي",
      description: "إعداد واصل - الهوية والشخصية والذاكرة",
      icon: Brain,
      href: "/ai/identity",
      color: "bg-green-500/10 text-green-500",
      stats: stats
        ? [
            { label: "الهوية", value: stats.ai.hasIdentity ? "مُعدّة" : "غير مُعدّة" },
            { label: "أقسام الشخصية", value: stats.ai.personalitySections },
            { label: "أوضاع الاستشارة", value: stats.ai.counselingModes },
            { label: "مناسبات", value: stats.ai.occasionsCount },
          ]
        : undefined,
    },
  ];

  const healthStatus = {
    connected: { icon: CheckCircle2, color: "text-green-500", label: "متصل" },
    error: { icon: XCircle, color: "text-red-500", label: "خطأ" },
    checking: { icon: AlertCircle, color: "text-yellow-500", label: "جاري الفحص" },
  };

  const activityTypeIcons = {
    content: BookOpen,
    gamification: Trophy,
    subscription: CreditCard,
    ai: Brain,
  };

  const activityActionColors = {
    created: "bg-green-500/10 text-green-600",
    updated: "bg-blue-500/10 text-blue-600",
    deleted: "bg-red-500/10 text-red-600",
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold">لوحة التحكم</h1>
        <p className="text-muted-foreground mt-1">
          مرحباً بك في لوحة تحكم صِلني - إدارة شاملة لجميع إعدادات التطبيق
        </p>
      </div>

      {/* Live User Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
        <Card className="bg-gradient-to-br from-silni-teal/10 to-silni-teal/5 border-silni-teal/20">
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">إجمالي المستخدمين</p>
                {overviewLoading ? (
                  <Skeleton className="h-8 w-16 mt-1" />
                ) : (
                  <p className="text-2xl font-bold text-silni-teal">
                    {overview?.total_users?.toLocaleString() || 0}
                  </p>
                )}
              </div>
              <Users className="h-8 w-8 text-silni-teal" />
            </div>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-green-500/10 to-green-500/5 border-green-500/20">
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">مستخدمون جدد اليوم</p>
                {overviewLoading ? (
                  <Skeleton className="h-8 w-16 mt-1" />
                ) : (
                  <div className="flex items-center gap-2">
                    <p className="text-2xl font-bold text-green-600">
                      +{overview?.new_users_today || 0}
                    </p>
                    {(overview?.new_users_today || 0) > 0 && (
                      <ArrowUpRight className="h-4 w-4 text-green-500" />
                    )}
                  </div>
                )}
              </div>
              <UserPlus className="h-8 w-8 text-green-500" />
            </div>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-blue-500/10 to-blue-500/5 border-blue-500/20">
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">نشطون اليوم</p>
                {overviewLoading ? (
                  <Skeleton className="h-8 w-16 mt-1" />
                ) : (
                  <p className="text-2xl font-bold text-blue-600">
                    {overview?.active_users_today || 0}
                  </p>
                )}
              </div>
              <Zap className="h-8 w-8 text-blue-500" />
            </div>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-silni-gold/10 to-silni-gold/5 border-silni-gold/20">
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">مشتركون مدفوع</p>
                {subscriptionLoading ? (
                  <Skeleton className="h-8 w-16 mt-1" />
                ) : (
                  <p className="text-2xl font-bold text-silni-gold">
                    {subscriptionDist?.premium || 0}
                  </p>
                )}
              </div>
              <Crown className="h-8 w-8 text-silni-gold" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">تجربة مجانية</p>
                {subscriptionLoading ? (
                  <Skeleton className="h-8 w-16 mt-1" />
                ) : (
                  <p className="text-2xl font-bold">
                    {subscriptionDist?.trial || 0}
                  </p>
                )}
              </div>
              <Package className="h-8 w-8 text-purple-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">إجمالي التفاعلات</p>
                {overviewLoading ? (
                  <Skeleton className="h-8 w-16 mt-1" />
                ) : (
                  <p className="text-2xl font-bold">
                    {overview?.total_interactions?.toLocaleString() || 0}
                  </p>
                )}
              </div>
              <Activity className="h-8 w-8 text-orange-500" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Admin Config Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">إجمالي المحتوى</p>
                {statsLoading ? (
                  <Skeleton className="h-8 w-16 mt-1" />
                ) : (
                  <p className="text-2xl font-bold">
                    {(stats?.content.hadithCount || 0) + (stats?.content.quotesCount || 0) + (stats?.content.messagesCount || 0)}
                  </p>
                )}
              </div>
              <BookOpen className="h-8 w-8 text-blue-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">عناصر التلعيب</p>
                {statsLoading ? (
                  <Skeleton className="h-8 w-16 mt-1" />
                ) : (
                  <p className="text-2xl font-bold">
                    {(stats?.gamification.badgesCount || 0) +
                      (stats?.gamification.levelsCount || 0) +
                      (stats?.gamification.challengesCount || 0)}
                  </p>
                )}
              </div>
              <Trophy className="h-8 w-8 text-yellow-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">إعدادات AI</p>
                {statsLoading ? (
                  <Skeleton className="h-8 w-16 mt-1" />
                ) : (
                  <p className="text-2xl font-bold">
                    {(stats?.ai.personalitySections || 0) +
                      (stats?.ai.counselingModes || 0) +
                      (stats?.ai.aiParameters || 0)}
                  </p>
                )}
              </div>
              <Brain className="h-8 w-8 text-green-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">عناصر التصميم</p>
                {statsLoading ? (
                  <Skeleton className="h-8 w-16 mt-1" />
                ) : (
                  <p className="text-2xl font-bold">
                    {(stats?.design.colorsCount || 0) +
                      (stats?.design.themesCount || 0) +
                      (stats?.design.animationsCount || 0)}
                  </p>
                )}
              </div>
              <Palette className="h-8 w-8 text-purple-500" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Quick Access Modules */}
      <div>
        <h2 className="text-xl font-semibold mb-4">الوحدات الرئيسية</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {modules.map((module) => (
            <Link key={module.href} href={module.href}>
              <Card className="hover:shadow-md transition-shadow cursor-pointer h-full">
                <CardHeader className="pb-2">
                  <div className="flex items-start justify-between">
                    <div
                      className={`w-10 h-10 rounded-lg ${module.color} flex items-center justify-center`}
                    >
                      <module.icon className="h-5 w-5" />
                    </div>
                  </div>
                  <CardTitle className="text-lg mt-3">{module.title}</CardTitle>
                  <CardDescription>{module.description}</CardDescription>
                </CardHeader>
                {module.stats && (
                  <CardContent className="pt-0">
                    <div className="flex flex-wrap gap-2">
                      {statsLoading
                        ? [...Array(3)].map((_, i) => (
                            <Skeleton key={i} className="h-6 w-16" />
                          ))
                        : module.stats.map((stat) => (
                            <Badge key={stat.label} variant="secondary" className="text-xs">
                              {stat.label}: {stat.value}
                            </Badge>
                          ))}
                    </div>
                  </CardContent>
                )}
              </Card>
            </Link>
          ))}
        </div>
      </div>

      {/* Upcoming Content & Audit Logs Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Upcoming Scheduled Content */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-lg flex items-center gap-2">
              <CalendarDays className="h-5 w-5" />
              المحتوى القادم
            </CardTitle>
            <Link href="/content/calendar">
              <Badge variant="outline" className="cursor-pointer hover:bg-accent">
                عرض التقويم
              </Badge>
            </Link>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {calendarLoading ? (
                [...Array(4)].map((_, i) => (
                  <div key={i} className="flex items-center gap-3">
                    <Skeleton className="w-2 h-10" />
                    <div className="flex-1">
                      <Skeleton className="h-4 w-3/4" />
                      <Skeleton className="h-3 w-1/2 mt-1" />
                    </div>
                  </div>
                ))
              ) : upcomingContent && upcomingContent.length > 0 ? (
                upcomingContent
                  .filter((e: CalendarEvent) => new Date(e.start_date) >= new Date())
                  .sort((a: CalendarEvent, b: CalendarEvent) =>
                    new Date(a.start_date).getTime() - new Date(b.start_date).getTime()
                  )
                  .slice(0, 5)
                  .map((event: CalendarEvent) => (
                    <div
                      key={event.id}
                      className="flex items-center gap-3 p-2 rounded-lg hover:bg-muted/50"
                    >
                      <div className={`w-1 h-10 rounded-full ${eventTypeColors[event.type]}`} />
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium truncate">{event.title}</p>
                        <div className="flex items-center gap-2 mt-0.5">
                          <Badge variant="secondary" className="text-[10px]">
                            {eventTypeLabels[event.type]}
                          </Badge>
                          <span className="text-xs text-muted-foreground">
                            {format(new Date(event.start_date), "d MMM", { locale: ar })}
                          </span>
                        </div>
                      </div>
                      {!event.is_active && (
                        <Badge variant="outline" className="text-xs">معطل</Badge>
                      )}
                    </div>
                  ))
              ) : (
                <div className="text-center py-6 text-muted-foreground">
                  <CalendarDays className="h-8 w-8 mx-auto mb-2 opacity-50" />
                  <p>لا يوجد محتوى مجدول</p>
                </div>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Recent Audit Logs */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-lg flex items-center gap-2">
              <History className="h-5 w-5" />
              سجل العمليات
            </CardTitle>
            <Link href="/settings/audit">
              <Badge variant="outline" className="cursor-pointer hover:bg-accent">
                عرض السجل
              </Badge>
            </Link>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {auditLoading ? (
                [...Array(4)].map((_, i) => (
                  <div key={i} className="flex items-center gap-3">
                    <Skeleton className="w-8 h-8 rounded" />
                    <div className="flex-1">
                      <Skeleton className="h-4 w-full" />
                      <Skeleton className="h-3 w-20 mt-1" />
                    </div>
                  </div>
                ))
              ) : auditLogs && auditLogs.length > 0 ? (
                auditLogs.map((log: AuditLogEntry) => (
                  <div
                    key={log.id}
                    className="flex items-start gap-3 p-2 rounded-lg hover:bg-muted/50"
                  >
                    <Badge
                      variant="outline"
                      className={`text-xs shrink-0 ${actionColors[log.action]}`}
                    >
                      {actionLabels[log.action]}
                    </Badge>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm truncate">
                        {log.resource_name || resourceLabels[log.resource_type]}
                      </p>
                      <div className="flex items-center gap-2 mt-0.5">
                        <span className="text-xs text-muted-foreground truncate">
                          {log.admin_email?.split("@")[0] || "نظام"}
                        </span>
                        <span className="text-xs text-muted-foreground">
                          {formatDistanceToNow(new Date(log.created_at), {
                            addSuffix: true,
                            locale: ar,
                          })}
                        </span>
                      </div>
                    </div>
                  </div>
                ))
              ) : (
                <div className="text-center py-6 text-muted-foreground">
                  <History className="h-8 w-8 mx-auto mb-2 opacity-50" />
                  <p>لا توجد عمليات مسجلة</p>
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* System Status */}
        <Card>
          <CardHeader>
            <CardTitle className="text-lg flex items-center gap-2">
              <Server className="h-5 w-5" />
              حالة النظام
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {healthLoading ? (
                [...Array(3)].map((_, i) => (
                  <div key={i} className="flex items-center gap-3">
                    <Skeleton className="w-8 h-8 rounded-full" />
                    <div className="flex-1">
                      <Skeleton className="h-4 w-24" />
                      <Skeleton className="h-3 w-16 mt-1" />
                    </div>
                  </div>
                ))
              ) : (
                <>
                  <div className="flex items-center gap-3 p-3 rounded-lg bg-muted/50">
                    <Database className="h-5 w-5 text-muted-foreground" />
                    <div className="flex-1">
                      <p className="text-sm font-medium">قاعدة البيانات (Supabase)</p>
                    </div>
                    <div className="flex items-center gap-1">
                      {health && (() => {
                        const status = healthStatus[health.database];
                        const Icon = status.icon;
                        return (
                          <>
                            <Icon className={`h-4 w-4 ${status.color}`} />
                            <span className={`text-sm ${status.color}`}>{status.label}</span>
                          </>
                        );
                      })()}
                    </div>
                  </div>

                  <div className="flex items-center gap-3 p-3 rounded-lg bg-muted/50">
                    <Brain className="h-5 w-5 text-muted-foreground" />
                    <div className="flex-1">
                      <p className="text-sm font-medium">الذكاء الاصطناعي (DeepSeek)</p>
                    </div>
                    <div className="flex items-center gap-1">
                      {health && (() => {
                        const status = healthStatus[health.ai];
                        const Icon = status.icon;
                        return (
                          <>
                            <Icon className={`h-4 w-4 ${status.color}`} />
                            <span className={`text-sm ${status.color}`}>{status.label}</span>
                          </>
                        );
                      })()}
                    </div>
                  </div>

                  <div className="flex items-center gap-3 p-3 rounded-lg bg-muted/50">
                    <HardDrive className="h-5 w-5 text-muted-foreground" />
                    <div className="flex-1">
                      <p className="text-sm font-medium">التخزين (Supabase Storage)</p>
                    </div>
                    <div className="flex items-center gap-1">
                      {health && (() => {
                        const status = healthStatus[health.storage];
                        const Icon = status.icon;
                        return (
                          <>
                            <Icon className={`h-4 w-4 ${status.color}`} />
                            <span className={`text-sm ${status.color}`}>{status.label}</span>
                          </>
                        );
                      })()}
                    </div>
                  </div>
                </>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Recent Activity */}
        <Card>
          <CardHeader>
            <CardTitle className="text-lg flex items-center gap-2">
              <Activity className="h-5 w-5" />
              آخر التحديثات
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {activityLoading ? (
                [...Array(5)].map((_, i) => (
                  <div key={i} className="flex items-center gap-3">
                    <Skeleton className="w-8 h-8 rounded" />
                    <div className="flex-1">
                      <Skeleton className="h-4 w-full" />
                      <Skeleton className="h-3 w-20 mt-1" />
                    </div>
                  </div>
                ))
              ) : activity && activity.length > 0 ? (
                activity.map((item, index) => {
                  const TypeIcon = activityTypeIcons[item.type];
                  return (
                    <div key={index} className="flex items-start gap-3 p-2 rounded-lg hover:bg-muted/50">
                      <div className="w-8 h-8 rounded bg-muted flex items-center justify-center">
                        <TypeIcon className="h-4 w-4 text-muted-foreground" />
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm truncate">{item.item}</p>
                        <div className="flex items-center gap-2 mt-1">
                          <Badge
                            variant="secondary"
                            className={`text-xs ${activityActionColors[item.action]}`}
                          >
                            {item.action === "created" ? "إنشاء" : item.action === "updated" ? "تحديث" : "حذف"}
                          </Badge>
                          <span className="text-xs text-muted-foreground">
                            {formatDistanceToNow(new Date(item.timestamp), {
                              addSuffix: true,
                              locale: ar,
                            })}
                          </span>
                        </div>
                      </div>
                    </div>
                  );
                })
              ) : (
                <div className="text-center py-8 text-muted-foreground">
                  <Activity className="h-8 w-8 mx-auto mb-2 opacity-50" />
                  <p>لا توجد تحديثات حديثة</p>
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Quick Links */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg">روابط سريعة</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-3">
            {[
              { icon: BookOpen, label: "أحاديث", href: "/content/hadith" },
              { icon: Quote, label: "اقتباسات", href: "/content/quotes" },
              { icon: MessageSquare, label: "رسائل", href: "/engagement/messages" },
              { icon: Award, label: "أوسمة", href: "/gamification/badges" },
              { icon: TrendingUp, label: "مستويات", href: "/gamification/levels" },
              { icon: Target, label: "تحديات", href: "/gamification/challenges" },
              { icon: Flame, label: "السلسلة", href: "/gamification/streaks" },
              { icon: Crown, label: "الباقات", href: "/subscriptions/tiers" },
              { icon: Package, label: "المنتجات", href: "/subscriptions/products" },
              { icon: Lock, label: "الميزات", href: "/subscriptions/features" },
              { icon: FileText, label: "قوالب", href: "/notifications/templates" },
              { icon: Clock, label: "فترات", href: "/notifications/time-slots" },
              { icon: Paintbrush, label: "ألوان", href: "/design/colors" },
              { icon: Layers, label: "ثيمات", href: "/design/themes" },
              { icon: Sparkles, label: "تأثيرات", href: "/design/animations" },
            ].map((link) => (
              <Link key={link.href} href={link.href}>
                <div className="flex items-center gap-2 p-3 rounded-lg bg-muted/50 hover:bg-muted transition-colors">
                  <link.icon className="h-4 w-4 text-muted-foreground" />
                  <span className="text-sm">{link.label}</span>
                </div>
              </Link>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
