"use client";

import { useState, useMemo, useCallback } from "react";
import {
  useScheduledPosts,
  useUpdateSocialPost,
} from "@/hooks/use-social-posts";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  ChevronRight,
  ChevronLeft,
  Calendar,
  Pause,
  Play,
  ExternalLink,
  RefreshCw,
  X,
} from "lucide-react";
import type { SocialPost } from "@/types/database";

// --- Label maps ---

const platformLabels: Record<
  string,
  { label: string; color: string; dotColor: string }
> = {
  twitter: {
    label: "تويتر",
    color: "bg-blue-500/10 text-blue-600",
    dotColor: "bg-blue-500",
  },
  instagram: {
    label: "إنستغرام",
    color: "bg-pink-500/10 text-pink-600",
    dotColor: "bg-pink-500",
  },
};

const statusLabels: Record<string, { label: string; color: string }> = {
  scheduled: { label: "مجدول", color: "bg-yellow-500/10 text-yellow-600" },
  published: { label: "منشور", color: "bg-green-500/10 text-green-600" },
  failed: { label: "فشل", color: "bg-red-500/10 text-red-600" },
  draft: { label: "مسودة", color: "bg-gray-500/10 text-gray-600" },
};

const arabicDayNames = [
  "الأحد",
  "الإثنين",
  "الثلاثاء",
  "الأربعاء",
  "الخميس",
  "الجمعة",
  "السبت",
];

const hourSlots = [6, 8, 10, 12, 14, 16, 18, 20, 22];

type ViewTab = "month" | "week" | "list";
type ListFilter = "all" | "scheduled" | "published" | "failed";

// --- Helper functions ---

function isSameDay(d1: Date, d2: Date): boolean {
  return (
    d1.getFullYear() === d2.getFullYear() &&
    d1.getMonth() === d2.getMonth() &&
    d1.getDate() === d2.getDate()
  );
}

function getMonthDays(year: number, month: number): (Date | null)[] {
  const firstDay = new Date(year, month, 1);
  const lastDay = new Date(year, month + 1, 0);
  const daysInMonth = lastDay.getDate();
  const startDow = firstDay.getDay(); // 0=Sunday

  const cells: (Date | null)[] = [];

  // Leading blanks
  for (let i = 0; i < startDow; i++) {
    cells.push(null);
  }

  // Days of month
  for (let d = 1; d <= daysInMonth; d++) {
    cells.push(new Date(year, month, d));
  }

  // Trailing blanks to fill grid
  while (cells.length % 7 !== 0) {
    cells.push(null);
  }

  return cells;
}

function getWeekDays(date: Date): Date[] {
  const days: Date[] = [];
  const dayOfWeek = date.getDay(); // 0=Sunday
  const sunday = new Date(date);
  sunday.setDate(date.getDate() - dayOfWeek);

  for (let i = 0; i < 7; i++) {
    const d = new Date(sunday);
    d.setDate(sunday.getDate() + i);
    days.push(d);
  }
  return days;
}

function getPostsForDay(posts: SocialPost[], day: Date): SocialPost[] {
  return posts.filter((p) => {
    if (!p.scheduled_at) return false;
    return isSameDay(new Date(p.scheduled_at), day);
  });
}

function formatArabicMonth(date: Date): string {
  return date.toLocaleDateString("ar-SA", { month: "long", year: "numeric" });
}

function formatArabicTime(dateStr: string): string {
  return new Date(dateStr).toLocaleTimeString("ar-SA", {
    hour: "2-digit",
    minute: "2-digit",
  });
}

function formatArabicDate(date: Date): string {
  return date.toLocaleDateString("ar-SA", {
    day: "numeric",
    month: "short",
  });
}

function hasConflict(
  post: SocialPost,
  allPosts: SocialPost[],
  newScheduledAt?: string
): boolean {
  const scheduledAt = newScheduledAt || post.scheduled_at;
  if (!scheduledAt) return false;

  const postTime = new Date(scheduledAt).getTime();
  const twoHoursMs = 2 * 60 * 60 * 1000;

  return allPosts.some((other) => {
    if (other.id === post.id) return false;
    if (other.platform !== post.platform) return false;
    if (!other.scheduled_at) return false;
    const otherTime = new Date(other.scheduled_at).getTime();
    return Math.abs(postTime - otherTime) < twoHoursMs;
  });
}

// --- Main component ---

export default function SocialCalendarPage() {
  const { data: posts, isLoading } = useScheduledPosts();
  const updatePost = useUpdateSocialPost();

  const [activeView, setActiveView] = useState<ViewTab>("month");
  const [currentDate, setCurrentDate] = useState(new Date());
  const [selectedDay, setSelectedDay] = useState<Date | null>(null);
  const [selectedPost, setSelectedPost] = useState<SocialPost | null>(null);
  const [detailDialogOpen, setDetailDialogOpen] = useState(false);
  const [editScheduledAt, setEditScheduledAt] = useState("");
  const [listFilter, setListFilter] = useState<ListFilter>("all");
  const [sortAsc, setSortAsc] = useState(true);
  const [isPaused, setIsPaused] = useState(false);
  const [draggedPostId, setDraggedPostId] = useState<string | null>(null);

  const allPosts = posts || [];

  // --- Navigation ---

  const goToPrevMonth = () => {
    setCurrentDate(
      new Date(currentDate.getFullYear(), currentDate.getMonth() - 1, 1)
    );
    setSelectedDay(null);
  };

  const goToNextMonth = () => {
    setCurrentDate(
      new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 1)
    );
    setSelectedDay(null);
  };

  const goToPrevWeek = () => {
    const d = new Date(currentDate);
    d.setDate(d.getDate() - 7);
    setCurrentDate(d);
  };

  const goToNextWeek = () => {
    const d = new Date(currentDate);
    d.setDate(d.getDate() + 7);
    setCurrentDate(d);
  };

  // --- Post detail dialog ---

  const openPostDetail = (post: SocialPost) => {
    setSelectedPost(post);
    if (post.scheduled_at) {
      const d = new Date(post.scheduled_at);
      const offset = d.getTimezoneOffset();
      const local = new Date(d.getTime() - offset * 60000);
      setEditScheduledAt(local.toISOString().slice(0, 16));
    } else {
      setEditScheduledAt("");
    }
    setDetailDialogOpen(true);
  };

  const handleRetry = () => {
    if (!selectedPost) return;
    updatePost.mutate(
      { id: selectedPost.id, status: "scheduled" },
      {
        onSuccess: () => setDetailDialogOpen(false),
      }
    );
  };

  const handleCancel = () => {
    if (!selectedPost) return;
    updatePost.mutate(
      { id: selectedPost.id, status: "draft" },
      {
        onSuccess: () => setDetailDialogOpen(false),
      }
    );
  };

  const handleReschedule = () => {
    if (!selectedPost || !editScheduledAt) return;
    updatePost.mutate(
      {
        id: selectedPost.id,
        scheduled_at: new Date(editScheduledAt).toISOString(),
      },
      {
        onSuccess: () => setDetailDialogOpen(false),
      }
    );
  };

  // --- Pause / Resume ---

  const handlePauseAll = () => {
    const scheduledPosts = allPosts.filter((p) => p.status === "scheduled");
    scheduledPosts.forEach((p) => {
      updatePost.mutate({ id: p.id, status: "draft" });
    });
    setIsPaused(true);
  };

  const handleResumeAll = () => {
    const draftPosts = allPosts.filter((p) => p.status === "draft");
    draftPosts.forEach((p) => {
      updatePost.mutate({ id: p.id, status: "scheduled" });
    });
    setIsPaused(false);
  };

  // --- Drag-and-drop (Week View) ---

  const handleDragStart = useCallback(
    (postId: string) => {
      setDraggedPostId(postId);
    },
    []
  );

  const handleDrop = useCallback(
    (day: Date, hour: number) => {
      if (!draggedPostId) return;
      const newDate = new Date(day);
      newDate.setHours(hour, 0, 0, 0);
      updatePost.mutate({
        id: draggedPostId,
        scheduled_at: newDate.toISOString(),
      });
      setDraggedPostId(null);
    },
    [draggedPostId, updatePost]
  );

  const handleDragOver = useCallback(
    (e: React.DragEvent) => {
      e.preventDefault();
    },
    []
  );

  // --- Computed data ---

  const monthDays = useMemo(
    () =>
      getMonthDays(currentDate.getFullYear(), currentDate.getMonth()),
    [currentDate]
  );

  const weekDays = useMemo(() => getWeekDays(currentDate), [currentDate]);

  const weekRange = useMemo(() => {
    const days = weekDays;
    return `${formatArabicDate(days[0])} - ${formatArabicDate(days[6])}`;
  }, [weekDays]);

  const filteredListPosts = useMemo(() => {
    let filtered = [...allPosts];

    // If a day is selected in month view, filter to that day
    if (activeView === "month" && selectedDay) {
      filtered = filtered.filter(
        (p) => p.scheduled_at && isSameDay(new Date(p.scheduled_at), selectedDay)
      );
    }

    if (listFilter !== "all") {
      filtered = filtered.filter((p) => p.status === listFilter);
    }

    filtered.sort((a, b) => {
      const aTime = a.scheduled_at
        ? new Date(a.scheduled_at).getTime()
        : 0;
      const bTime = b.scheduled_at
        ? new Date(b.scheduled_at).getTime()
        : 0;
      return sortAsc ? aTime - bTime : bTime - aTime;
    });

    return filtered;
  }, [allPosts, listFilter, sortAsc, activeView, selectedDay]);

  // --- Conflict check for detail dialog ---

  const detailConflict = useMemo(() => {
    if (!selectedPost || !editScheduledAt) return false;
    return hasConflict(selectedPost, allPosts, new Date(editScheduledAt).toISOString());
  }, [selectedPost, editScheduledAt, allPosts]);

  // --- Render ---

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Card>
          <CardContent>
            <div className="text-center py-16 text-muted-foreground">
              جاري التحميل...
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* ======= Header ======= */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Calendar className="h-5 w-5" />
              <CardTitle>تقويم النشر</CardTitle>
            </div>
            <div className="flex items-center gap-2">
              {isPaused ? (
                <Button variant="outline" onClick={handleResumeAll}>
                  <Play className="h-4 w-4 ml-2" />
                  استئناف الكل
                </Button>
              ) : (
                <Button variant="outline" onClick={handlePauseAll}>
                  <Pause className="h-4 w-4 ml-2" />
                  إيقاف الكل
                </Button>
              )}
            </div>
          </div>
        </CardHeader>
        <CardContent>
          {/* View Tabs */}
          <div className="flex items-center gap-2 mb-6">
            <Button
              variant={activeView === "month" ? "default" : "outline"}
              size="sm"
              onClick={() => {
                setActiveView("month");
                setSelectedDay(null);
              }}
            >
              شهري
            </Button>
            <Button
              variant={activeView === "week" ? "default" : "outline"}
              size="sm"
              onClick={() => setActiveView("week")}
            >
              أسبوعي
            </Button>
            <Button
              variant={activeView === "list" ? "default" : "outline"}
              size="sm"
              onClick={() => {
                setActiveView("list");
                setSelectedDay(null);
              }}
            >
              قائمة
            </Button>
          </div>

          {/* ======= Month View ======= */}
          {activeView === "month" && (
            <div>
              {/* Month navigation */}
              <div className="flex items-center justify-between mb-4">
                <Button variant="ghost" size="icon" onClick={goToNextMonth}>
                  <ChevronRight className="h-5 w-5" />
                </Button>
                <span className="text-lg font-semibold">
                  {formatArabicMonth(currentDate)}
                </span>
                <Button variant="ghost" size="icon" onClick={goToPrevMonth}>
                  <ChevronLeft className="h-5 w-5" />
                </Button>
              </div>

              {/* Day headers */}
              <div className="grid grid-cols-7 gap-1 mb-1">
                {arabicDayNames.map((name) => (
                  <div
                    key={name}
                    className="text-center text-xs font-medium text-muted-foreground py-2"
                  >
                    {name}
                  </div>
                ))}
              </div>

              {/* Day cells */}
              <div className="grid grid-cols-7 gap-1">
                {monthDays.map((day, idx) => {
                  if (!day) {
                    return (
                      <div key={`empty-${idx}`} className="h-20 rounded-md" />
                    );
                  }

                  const dayPosts = getPostsForDay(allPosts, day);
                  const allPublished =
                    dayPosts.length > 0 &&
                    dayPosts.every((p) => p.status === "published");
                  const hasFailed = dayPosts.some(
                    (p) => p.status === "failed"
                  );
                  const isSelected = selectedDay && isSameDay(day, selectedDay);
                  const isToday = isSameDay(day, new Date());

                  return (
                    <button
                      key={day.toISOString()}
                      onClick={() =>
                        setSelectedDay(
                          isSelected ? null : day
                        )
                      }
                      className={`h-20 rounded-md border p-1 text-right transition-colors hover:bg-accent/50 flex flex-col ${
                        allPublished ? "bg-green-500/5" : ""
                      } ${hasFailed ? "border-red-500 border-2" : "border-border"} ${
                        isSelected
                          ? "ring-2 ring-primary"
                          : ""
                      } ${isToday ? "bg-accent/30" : ""}`}
                    >
                      <span
                        className={`text-sm font-medium ${
                          isToday ? "text-primary font-bold" : ""
                        }`}
                      >
                        {day.getDate()}
                      </span>
                      {dayPosts.length > 0 && (
                        <div className="flex flex-wrap gap-1 mt-auto">
                          {dayPosts.slice(0, 5).map((p) => {
                            const pf =
                              platformLabels[p.platform] ||
                              platformLabels.twitter;
                            return (
                              <span
                                key={p.id}
                                className={`inline-block h-2 w-2 rounded-full ${pf.dotColor}`}
                              />
                            );
                          })}
                          {dayPosts.length > 5 && (
                            <span className="text-[10px] text-muted-foreground">
                              +{dayPosts.length - 5}
                            </span>
                          )}
                        </div>
                      )}
                    </button>
                  );
                })}
              </div>

              {/* Selected day posts */}
              {selectedDay && (
                <div className="mt-4">
                  <h3 className="text-sm font-semibold mb-2">
                    منشورات{" "}
                    {selectedDay.toLocaleDateString("ar-SA", {
                      weekday: "long",
                      day: "numeric",
                      month: "long",
                    })}
                  </h3>
                  {getPostsForDay(allPosts, selectedDay).length === 0 ? (
                    <p className="text-sm text-muted-foreground">
                      لا توجد منشورات مجدولة لهذا اليوم
                    </p>
                  ) : (
                    <div className="space-y-2">
                      {getPostsForDay(allPosts, selectedDay).map((post) => {
                        const pf =
                          platformLabels[post.platform] ||
                          platformLabels.twitter;
                        const st =
                          statusLabels[post.status] || statusLabels.scheduled;
                        return (
                          <button
                            key={post.id}
                            onClick={() => openPostDetail(post)}
                            className="w-full flex items-center gap-3 p-3 border rounded-lg hover:bg-accent/50 transition-colors text-right"
                          >
                            <span
                              className={`inline-block h-3 w-3 rounded-full shrink-0 ${pf.dotColor}`}
                            />
                            <span className="truncate flex-1 text-sm">
                              {post.text_ar.slice(0, 60)}
                              {post.text_ar.length > 60 ? "..." : ""}
                            </span>
                            <Badge className={st.color}>{st.label}</Badge>
                            {post.scheduled_at && (
                              <span className="text-xs text-muted-foreground whitespace-nowrap">
                                {formatArabicTime(post.scheduled_at)}
                              </span>
                            )}
                          </button>
                        );
                      })}
                    </div>
                  )}
                </div>
              )}
            </div>
          )}

          {/* ======= Week View ======= */}
          {activeView === "week" && (
            <div>
              {/* Week navigation */}
              <div className="flex items-center justify-between mb-4">
                <Button variant="ghost" size="icon" onClick={goToNextWeek}>
                  <ChevronRight className="h-5 w-5" />
                </Button>
                <span className="text-lg font-semibold">{weekRange}</span>
                <Button variant="ghost" size="icon" onClick={goToPrevWeek}>
                  <ChevronLeft className="h-5 w-5" />
                </Button>
              </div>

              {/* Week grid */}
              <div className="overflow-x-auto">
                <div className="min-w-[700px]">
                  {/* Day headers */}
                  <div className="grid grid-cols-[60px_repeat(7,1fr)] gap-1 mb-1">
                    <div />
                    {weekDays.map((day, idx) => (
                      <div
                        key={idx}
                        className={`text-center text-xs font-medium py-2 rounded-t-md ${
                          isSameDay(day, new Date())
                            ? "bg-primary/10 text-primary font-bold"
                            : "text-muted-foreground"
                        }`}
                      >
                        <div>{arabicDayNames[day.getDay()]}</div>
                        <div className="text-[11px]">{day.getDate()}</div>
                      </div>
                    ))}
                  </div>

                  {/* Hour rows */}
                  {hourSlots.map((hour) => (
                    <div
                      key={hour}
                      className="grid grid-cols-[60px_repeat(7,1fr)] gap-1 min-h-[60px]"
                    >
                      {/* Hour label */}
                      <div className="text-xs text-muted-foreground flex items-start justify-center pt-1 tabular-nums" dir="ltr">
                        {hour.toString().padStart(2, "0")}:00
                      </div>

                      {/* Day cells */}
                      {weekDays.map((day, dayIdx) => {
                        const cellPosts = allPosts.filter((p) => {
                          if (!p.scheduled_at) return false;
                          const d = new Date(p.scheduled_at);
                          return (
                            isSameDay(d, day) &&
                            d.getHours() >= hour &&
                            d.getHours() < hour + 2
                          );
                        });

                        return (
                          <div
                            key={dayIdx}
                            className="border border-border/50 rounded-sm p-0.5 min-h-[60px]"
                            onDragOver={handleDragOver}
                            onDrop={() => handleDrop(day, hour)}
                          >
                            {cellPosts.map((post) => {
                              const pf =
                                platformLabels[post.platform] ||
                                platformLabels.twitter;
                              const st =
                                statusLabels[post.status] ||
                                statusLabels.scheduled;
                              return (
                                <div
                                  key={post.id}
                                  draggable
                                  onDragStart={() => handleDragStart(post.id)}
                                  onClick={() => openPostDetail(post)}
                                  className="flex items-center gap-1 p-1 rounded text-[11px] cursor-pointer hover:bg-accent/50 transition-colors mb-0.5 border border-border/30"
                                >
                                  <span
                                    className={`inline-block h-2 w-2 rounded-full shrink-0 ${pf.dotColor}`}
                                  />
                                  <span className="truncate flex-1">
                                    {post.text_ar.slice(0, 30)}
                                    {post.text_ar.length > 30 ? "..." : ""}
                                  </span>
                                  <span
                                    className={`inline-block h-1.5 w-1.5 rounded-full shrink-0 ${
                                      post.status === "published"
                                        ? "bg-green-500"
                                        : post.status === "failed"
                                        ? "bg-red-500"
                                        : "bg-yellow-500"
                                    }`}
                                  />
                                </div>
                              );
                            })}
                          </div>
                        );
                      })}
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* ======= List View ======= */}
          {activeView === "list" && (
            <div>
              {/* Filter buttons */}
              <div className="flex items-center gap-2 mb-4">
                {(
                  [
                    { key: "all", label: "الكل" },
                    { key: "scheduled", label: "مجدول" },
                    { key: "published", label: "منشور" },
                    { key: "failed", label: "فشل" },
                  ] as { key: ListFilter; label: string }[]
                ).map(({ key, label }) => (
                  <Button
                    key={key}
                    variant={listFilter === key ? "default" : "outline"}
                    size="sm"
                    onClick={() => setListFilter(key)}
                  >
                    {label}
                  </Button>
                ))}
                <div className="flex-1" />
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => setSortAsc(!sortAsc)}
                >
                  {sortAsc ? "الأقدم أولاً" : "الأحدث أولاً"}
                </Button>
              </div>

              {filteredListPosts.length === 0 ? (
                <div className="text-center py-8 text-muted-foreground">
                  لا توجد منشورات
                </div>
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>الحالة</TableHead>
                      <TableHead>المنصة</TableHead>
                      <TableHead>النص</TableHead>
                      <TableHead>الوقت المجدول</TableHead>
                      <TableHead className="w-[80px]">إجراءات</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {filteredListPosts.map((post) => {
                      const pf =
                        platformLabels[post.platform] ||
                        platformLabels.twitter;
                      const st =
                        statusLabels[post.status] || statusLabels.scheduled;
                      const conflict = hasConflict(post, allPosts);

                      return (
                        <TableRow key={post.id}>
                          <TableCell>
                            <Badge className={st.color}>{st.label}</Badge>
                          </TableCell>
                          <TableCell>
                            <div className="flex items-center gap-1.5">
                              <span
                                className={`inline-block h-2.5 w-2.5 rounded-full ${pf.dotColor}`}
                              />
                              <span className="text-sm">{pf.label}</span>
                            </div>
                          </TableCell>
                          <TableCell>
                            <div>
                              <span className="text-sm">
                                {post.text_ar.slice(0, 60)}
                                {post.text_ar.length > 60 ? "..." : ""}
                              </span>
                              {conflict && (
                                <p className="text-xs text-yellow-600 mt-0.5">
                                  تحذير: يوجد منشور آخر على نفس المنصة خلال
                                  ساعتين
                                </p>
                              )}
                            </div>
                          </TableCell>
                          <TableCell>
                            {post.scheduled_at ? (
                              <span className="text-sm whitespace-nowrap">
                                {new Date(post.scheduled_at).toLocaleDateString(
                                  "ar-SA",
                                  {
                                    day: "numeric",
                                    month: "short",
                                  }
                                )}{" "}
                                {formatArabicTime(post.scheduled_at)}
                              </span>
                            ) : (
                              <span className="text-sm text-muted-foreground">
                                -
                              </span>
                            )}
                          </TableCell>
                          <TableCell>
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => openPostDetail(post)}
                            >
                              عرض
                            </Button>
                          </TableCell>
                        </TableRow>
                      );
                    })}
                  </TableBody>
                </Table>
              )}
            </div>
          )}
        </CardContent>
      </Card>

      {/* ======= Post Detail Dialog ======= */}
      <Dialog open={detailDialogOpen} onOpenChange={setDetailDialogOpen}>
        <DialogContent className="max-w-lg max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>تفاصيل المنشور</DialogTitle>
          </DialogHeader>

          {selectedPost && (
            <div className="space-y-4 py-2">
              {/* Platform & Status badges */}
              <div className="flex items-center gap-2 flex-wrap">
                <Badge
                  className={
                    (
                      platformLabels[selectedPost.platform] ||
                      platformLabels.twitter
                    ).color
                  }
                >
                  {
                    (
                      platformLabels[selectedPost.platform] ||
                      platformLabels.twitter
                    ).label
                  }
                </Badge>
                <Badge
                  className={
                    (
                      statusLabels[selectedPost.status] ||
                      statusLabels.scheduled
                    ).color
                  }
                >
                  {
                    (
                      statusLabels[selectedPost.status] ||
                      statusLabels.scheduled
                    ).label
                  }
                </Badge>
              </div>

              {/* Full Arabic text */}
              <div className="space-y-1">
                <p className="text-sm font-medium text-muted-foreground">
                  النص
                </p>
                <p className="text-sm leading-relaxed bg-muted/50 p-3 rounded-lg whitespace-pre-wrap">
                  {selectedPost.text_ar}
                </p>
              </div>

              {/* Hashtags */}
              {selectedPost.hashtags && selectedPost.hashtags.length > 0 && (
                <div className="space-y-1">
                  <p className="text-sm font-medium text-muted-foreground">
                    الهاشتاقات
                  </p>
                  <div className="flex flex-wrap gap-1">
                    {selectedPost.hashtags.map((tag, i) => (
                      <Badge key={i} variant="secondary">
                        {tag}
                      </Badge>
                    ))}
                  </div>
                </div>
              )}

              {/* Published link */}
              {selectedPost.status === "published" &&
                selectedPost.platform_post_url && (
                  <a
                    href={selectedPost.platform_post_url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex items-center gap-2 text-sm text-primary hover:underline"
                  >
                    <ExternalLink className="h-4 w-4" />
                    عرض المنشور على المنصة
                  </a>
                )}

              {/* Failed error message */}
              {selectedPost.status === "failed" &&
                selectedPost.error_message && (
                  <div className="bg-red-500/10 border border-red-500/20 rounded-lg p-3">
                    <p className="text-sm font-medium text-red-600 mb-1">
                      رسالة الخطأ
                    </p>
                    <p className="text-sm text-red-600/80">
                      {selectedPost.error_message}
                    </p>
                  </div>
                )}

              {/* Scheduled time (editable) */}
              <div className="space-y-2">
                <p className="text-sm font-medium text-muted-foreground">
                  وقت النشر المجدول
                </p>
                <Input
                  type="datetime-local"
                  value={editScheduledAt}
                  onChange={(e) => setEditScheduledAt(e.target.value)}
                  dir="ltr"
                  className="text-sm"
                />
                {detailConflict && (
                  <p className="text-xs text-yellow-600">
                    تحذير: يوجد منشور آخر على نفس المنصة خلال ساعتين من هذا
                    الوقت
                  </p>
                )}
              </div>
            </div>
          )}

          <DialogFooter className="flex-wrap gap-2">
            {/* Retry button (only for failed) */}
            {selectedPost?.status === "failed" && (
              <Button
                variant="outline"
                onClick={handleRetry}
                disabled={updatePost.isPending}
              >
                <RefreshCw className="h-4 w-4 ml-2" />
                إعادة المحاولة
              </Button>
            )}

            {/* Cancel button (set to draft) */}
            <Button
              variant="outline"
              onClick={handleCancel}
              disabled={updatePost.isPending}
            >
              <X className="h-4 w-4 ml-2" />
              إلغاء الجدولة
            </Button>

            {/* Reschedule button */}
            <Button
              onClick={handleReschedule}
              disabled={updatePost.isPending || !editScheduledAt}
            >
              {updatePost.isPending ? "جاري الحفظ..." : "حفظ الموعد"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
