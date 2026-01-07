"use client";

import { useState, useMemo } from "react";
import {
  useCalendarEvents,
  getCalendarDays,
  isEventOnDate,
  getEventPosition,
  eventTypeLabels,
  eventTypeColors,
  eventTypeBorderColors,
  CalendarEvent,
  CalendarEventType,
} from "@/hooks/use-calendar";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Checkbox } from "@/components/ui/checkbox";
import {
  Calendar,
  ChevronRight,
  ChevronLeft,
  Target,
  Bell,
  MessageSquare,
  ExternalLink,
} from "lucide-react";
import Link from "next/link";

const WEEKDAYS = ["السبت", "الأحد", "الاثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة"];

const MONTHS = [
  "يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو",
  "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"
];

const eventTypeIcons: Record<CalendarEventType, React.ElementType> = {
  challenge: Target,
  announcement: Bell,
  message: MessageSquare,
};

const eventTypeLinks: Record<CalendarEventType, string> = {
  challenge: "/gamification/challenges",
  announcement: "/notifications/announcements",
  message: "/engagement/messages",
};

export default function ContentCalendarPage() {
  const [currentDate, setCurrentDate] = useState(new Date());
  const [selectedEvent, setSelectedEvent] = useState<CalendarEvent | null>(null);
  const [filters, setFilters] = useState<Record<CalendarEventType, boolean>>({
    challenge: true,
    announcement: true,
    message: true,
  });

  const year = currentDate.getFullYear();
  const month = currentDate.getMonth();

  // Get date range for the current month view
  const startDate = new Date(year, month, 1).toISOString();
  const endDate = new Date(year, month + 1, 0).toISOString();

  const { data: events, isLoading } = useCalendarEvents(startDate, endDate);

  // Filter events based on type
  const filteredEvents = useMemo(() => {
    return events?.filter((e) => filters[e.type]) || [];
  }, [events, filters]);

  // Get calendar days with events
  const calendarDays = useMemo(() => {
    const days = getCalendarDays(year, month);

    // Add events to each day
    days.forEach((day) => {
      day.events = filteredEvents.filter((event) => isEventOnDate(event, day.date));
    });

    return days;
  }, [year, month, filteredEvents]);

  const goToPrevMonth = () => {
    setCurrentDate(new Date(year, month - 1, 1));
  };

  const goToNextMonth = () => {
    setCurrentDate(new Date(year, month + 1, 1));
  };

  const goToToday = () => {
    setCurrentDate(new Date());
  };

  const toggleFilter = (type: CalendarEventType) => {
    setFilters((f) => ({ ...f, [type]: !f[type] }));
  };

  const formatDate = (dateStr: string) => {
    return new Date(dateStr).toLocaleDateString("ar-SA", {
      weekday: "long",
      year: "numeric",
      month: "long",
      day: "numeric",
    });
  };

  // Count events by type for legend
  const eventCounts = useMemo(() => {
    const counts: Record<CalendarEventType, number> = {
      challenge: 0,
      announcement: 0,
      message: 0,
    };
    events?.forEach((e) => {
      counts[e.type]++;
    });
    return counts;
  }, [events]);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <div className="w-14 h-14 bg-gradient-to-br from-teal-500 to-cyan-600 rounded-2xl flex items-center justify-center shadow-lg">
            <Calendar className="h-7 w-7 text-white" />
          </div>
          <div>
            <h1 className="text-3xl font-bold">تقويم المحتوى</h1>
            <p className="text-muted-foreground mt-1">
              عرض مرئي للمحتوى المجدول
            </p>
          </div>
        </div>
        <Button variant="outline" onClick={goToToday}>
          اليوم
        </Button>
      </div>

      <div className="grid gap-6 lg:grid-cols-4">
        {/* Filters & Legend */}
        <Card>
          <CardHeader>
            <CardTitle>الفلاتر</CardTitle>
            <CardDescription>اختر أنواع المحتوى للعرض</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {(Object.keys(eventTypeLabels) as CalendarEventType[]).map((type) => {
              const Icon = eventTypeIcons[type];
              return (
                <label
                  key={type}
                  className="flex items-center gap-3 cursor-pointer"
                >
                  <Checkbox
                    checked={filters[type]}
                    onCheckedChange={() => toggleFilter(type)}
                  />
                  <div className={`w-3 h-3 rounded-full ${eventTypeColors[type]}`} />
                  <Icon className="h-4 w-4 text-muted-foreground" />
                  <span className="flex-1">{eventTypeLabels[type]}</span>
                  <Badge variant="secondary" className="text-xs">
                    {eventCounts[type]}
                  </Badge>
                </label>
              );
            })}
          </CardContent>
        </Card>

        {/* Calendar */}
        <Card className="lg:col-span-3">
          <CardHeader>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                <Button variant="ghost" size="icon" onClick={goToPrevMonth}>
                  <ChevronRight className="h-5 w-5" />
                </Button>
                <h2 className="text-xl font-bold min-w-32 text-center">
                  {MONTHS[month]} {year}
                </h2>
                <Button variant="ghost" size="icon" onClick={goToNextMonth}>
                  <ChevronLeft className="h-5 w-5" />
                </Button>
              </div>
              <p className="text-sm text-muted-foreground">
                {filteredEvents.length} عنصر مجدول
              </p>
            </div>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <Skeleton className="h-[600px] w-full" />
            ) : (
              <div className="border rounded-lg overflow-hidden">
                {/* Weekday headers */}
                <div className="grid grid-cols-7 bg-muted/50">
                  {WEEKDAYS.map((day) => (
                    <div
                      key={day}
                      className="p-2 text-center text-sm font-medium border-b"
                    >
                      {day}
                    </div>
                  ))}
                </div>

                {/* Calendar grid */}
                <div className="grid grid-cols-7">
                  {calendarDays.map((day, index) => (
                    <div
                      key={day.date}
                      className={`min-h-24 p-1 border-b border-l ${
                        !day.isCurrentMonth ? "bg-muted/30" : ""
                      } ${day.isToday ? "bg-primary/5" : ""}`}
                    >
                      <div
                        className={`text-sm mb-1 ${
                          day.isToday
                            ? "w-6 h-6 rounded-full bg-primary text-primary-foreground flex items-center justify-center font-bold"
                            : day.isCurrentMonth
                            ? "text-foreground"
                            : "text-muted-foreground"
                        }`}
                      >
                        {new Date(day.date).getDate()}
                      </div>
                      <div className="space-y-0.5">
                        {day.events.slice(0, 3).map((event) => {
                          const position = getEventPosition(event, day.date);
                          return (
                            <button
                              key={event.id}
                              onClick={() => setSelectedEvent(event)}
                              className={`w-full text-center text-[10px] px-1 min-h-[18px] truncate text-white transition-opacity hover:opacity-80 flex items-center justify-center ${
                                eventTypeColors[event.type]
                              } ${
                                position === "start"
                                  ? "rounded-r"
                                  : position === "end"
                                  ? "rounded-l"
                                  : position === "single"
                                  ? "rounded"
                                  : ""
                              } ${!event.is_active ? "opacity-50" : ""}`}
                            >
                              <span className="truncate">{event.title}</span>
                            </button>
                          );
                        })}
                        {day.events.length > 3 && (
                          <div className="text-[10px] text-muted-foreground text-center">
                            +{day.events.length - 3} أخرى
                          </div>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Upcoming Events List */}
      <Card>
        <CardHeader>
          <CardTitle>الأحداث القادمة</CardTitle>
          <CardDescription>
            المحتوى المجدول في الأيام القادمة
          </CardDescription>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="space-y-4">
              {[...Array(3)].map((_, i) => (
                <Skeleton key={i} className="h-16 w-full" />
              ))}
            </div>
          ) : (
            <div className="space-y-3">
              {filteredEvents
                .filter((e) => new Date(e.start_date) >= new Date())
                .sort((a, b) => new Date(a.start_date).getTime() - new Date(b.start_date).getTime())
                .slice(0, 10)
                .map((event) => {
                  const Icon = eventTypeIcons[event.type];
                  return (
                    <div
                      key={event.id}
                      className={`flex items-center gap-4 p-3 rounded-lg border-r-4 bg-muted/30 ${
                        eventTypeBorderColors[event.type]
                      }`}
                    >
                      <div
                        className={`w-10 h-10 rounded-lg flex items-center justify-center ${
                          eventTypeColors[event.type]
                        }`}
                      >
                        <Icon className="h-5 w-5 text-white" />
                      </div>
                      <div className="flex-1">
                        <p className="font-medium">{event.title}</p>
                        <p className="text-xs text-muted-foreground">
                          {formatDate(event.start_date)}
                          {event.end_date && event.end_date !== event.start_date && (
                            <> — {formatDate(event.end_date)}</>
                          )}
                        </p>
                      </div>
                      <div className="flex items-center gap-2">
                        <Badge variant={event.is_active ? "default" : "secondary"}>
                          {event.is_active ? "نشط" : "معطل"}
                        </Badge>
                        <Link href={eventTypeLinks[event.type]}>
                          <Button variant="ghost" size="icon">
                            <ExternalLink className="h-4 w-4" />
                          </Button>
                        </Link>
                      </div>
                    </div>
                  );
                })}
              {filteredEvents.filter((e) => new Date(e.start_date) >= new Date()).length === 0 && (
                <p className="text-center py-8 text-muted-foreground">
                  لا يوجد محتوى مجدول قادم
                </p>
              )}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Event Detail Dialog */}
      <Dialog open={!!selectedEvent} onOpenChange={(open) => !open && setSelectedEvent(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle className="flex items-center gap-3">
              {selectedEvent && (
                <>
                  <div
                    className={`w-8 h-8 rounded-lg flex items-center justify-center ${
                      eventTypeColors[selectedEvent.type]
                    }`}
                  >
                    {(() => {
                      const Icon = eventTypeIcons[selectedEvent.type];
                      return <Icon className="h-4 w-4 text-white" />;
                    })()}
                  </div>
                  {selectedEvent.title}
                </>
              )}
            </DialogTitle>
            <DialogDescription>
              {selectedEvent && eventTypeLabels[selectedEvent.type]}
            </DialogDescription>
          </DialogHeader>
          {selectedEvent && (
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-sm text-muted-foreground">تاريخ البداية</p>
                  <p className="font-medium">{formatDate(selectedEvent.start_date)}</p>
                </div>
                {selectedEvent.end_date && (
                  <div>
                    <p className="text-sm text-muted-foreground">تاريخ النهاية</p>
                    <p className="font-medium">{formatDate(selectedEvent.end_date)}</p>
                  </div>
                )}
              </div>
              <div>
                <p className="text-sm text-muted-foreground">الحالة</p>
                <Badge variant={selectedEvent.is_active ? "default" : "secondary"}>
                  {selectedEvent.is_active ? "نشط" : "معطل"}
                </Badge>
              </div>
              {Object.keys(selectedEvent.metadata).length > 0 && (
                <div>
                  <p className="text-sm text-muted-foreground mb-2">تفاصيل إضافية</p>
                  <div className="bg-muted/50 rounded-lg p-3 text-sm">
                    {Object.entries(selectedEvent.metadata).map(([key, value]) => (
                      <div key={key} className="flex justify-between">
                        <span className="text-muted-foreground">{key}:</span>
                        <span>{String(value)}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}
              <Link href={eventTypeLinks[selectedEvent.type]} className="block">
                <Button className="w-full">
                  <ExternalLink className="h-4 w-4 ml-2" />
                  الانتقال للتعديل
                </Button>
              </Link>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
