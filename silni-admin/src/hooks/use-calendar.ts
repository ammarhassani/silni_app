"use client";

import { useQuery } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";

// Types for calendar events
export type CalendarEventType = "challenge" | "announcement" | "message";

export interface CalendarEvent {
  id: string;
  type: CalendarEventType;
  title: string;
  start_date: string;
  end_date: string | null;
  is_active: boolean;
  metadata: Record<string, unknown>;
}

export interface CalendarDay {
  date: string;
  events: CalendarEvent[];
  isToday: boolean;
  isCurrentMonth: boolean;
}

// Event type labels and colors
export const eventTypeLabels: Record<CalendarEventType, string> = {
  challenge: "تحدي",
  announcement: "إشعار",
  message: "رسالة",
};

export const eventTypeColors: Record<CalendarEventType, string> = {
  challenge: "bg-amber-500",
  announcement: "bg-green-500",
  message: "bg-purple-500",
};

export const eventTypeBorderColors: Record<CalendarEventType, string> = {
  challenge: "border-amber-500",
  announcement: "border-green-500",
  message: "border-purple-500",
};

// Fetch all scheduled content for a date range
export function useCalendarEvents(startDate: string, endDate: string) {
  const supabase = createClient();

  return useQuery({
    queryKey: ["calendar-events", startDate, endDate],
    queryFn: async () => {
      const events: CalendarEvent[] = [];

      // Helper to check if event overlaps with date range
      const overlapsRange = (eventStart: string | null, eventEnd: string | null): boolean => {
        if (!eventStart && !eventEnd) return false;
        const start = eventStart || eventEnd!;
        const end = eventEnd || eventStart!;
        // Event overlaps if: event starts before range ends AND event ends after range starts
        return start <= endDate && end >= startDate;
      };

      // Fetch all Challenges with dates
      const { data: challenges } = await supabase
        .from("admin_challenges")
        .select("id, title_ar, start_date, end_date, is_active, type, xp_reward")
        .not("start_date", "is", null);

      challenges?.filter((c) => overlapsRange(c.start_date, c.end_date)).forEach((challenge) => {
        events.push({
          id: challenge.id,
          type: "challenge",
          title: challenge.title_ar,
          start_date: challenge.start_date || challenge.end_date!,
          end_date: challenge.end_date,
          is_active: challenge.is_active,
          metadata: { challenge_type: challenge.type, xp_reward: challenge.xp_reward },
        });
      });

      // Fetch scheduled Announcements
      const { data: announcements } = await supabase
        .from("admin_announcements")
        .select("id, title_ar, scheduled_for, status, target_users, priority")
        .gte("scheduled_for", startDate)
        .lte("scheduled_for", endDate)
        .not("scheduled_for", "is", null);

      announcements?.forEach((announcement) => {
        if (announcement.scheduled_for) {
          events.push({
            id: announcement.id,
            type: "announcement",
            title: announcement.title_ar,
            start_date: announcement.scheduled_for,
            end_date: null,
            is_active: announcement.status === "scheduled",
            metadata: { status: announcement.status, target: announcement.target_users, priority: announcement.priority },
          });
        }
      });

      // Fetch scheduled Messages (unified: banners, motd, in-app messages)
      const { data: messages } = await supabase
        .from("admin_in_app_messages")
        .select("id, name, title_ar, message_type, start_date, end_date, is_active, priority, trigger_type")
        .not("start_date", "is", null);

      messages?.filter((m) => overlapsRange(m.start_date, m.end_date)).forEach((message) => {
        events.push({
          id: message.id,
          type: "message",
          title: message.title_ar || message.name,
          start_date: message.start_date!,
          end_date: message.end_date,
          is_active: message.is_active,
          metadata: { message_type: message.message_type, trigger_type: message.trigger_type, priority: message.priority },
        });
      });

      return events;
    },
    staleTime: 60000, // 1 minute
  });
}

// Get calendar days for a month
export function getCalendarDays(year: number, month: number): CalendarDay[] {
  const today = new Date();
  const todayStr = today.toISOString().split("T")[0];

  const firstDay = new Date(year, month, 1);
  const lastDay = new Date(year, month + 1, 0);

  // Get the day of week for the first day (0 = Sunday)
  // Adjust for RTL (Saturday = 0 in Arabic calendar)
  const startDayOfWeek = (firstDay.getDay() + 1) % 7;

  const days: CalendarDay[] = [];

  // Previous month days
  const prevMonth = new Date(year, month, 0);
  for (let i = startDayOfWeek - 1; i >= 0; i--) {
    const date = new Date(prevMonth);
    date.setDate(prevMonth.getDate() - i);
    days.push({
      date: date.toISOString().split("T")[0],
      events: [],
      isToday: false,
      isCurrentMonth: false,
    });
  }

  // Current month days
  for (let day = 1; day <= lastDay.getDate(); day++) {
    const date = new Date(year, month, day);
    const dateStr = date.toISOString().split("T")[0];
    days.push({
      date: dateStr,
      events: [],
      isToday: dateStr === todayStr,
      isCurrentMonth: true,
    });
  }

  // Next month days to complete the grid (6 rows = 42 days)
  const remainingDays = 42 - days.length;
  for (let day = 1; day <= remainingDays; day++) {
    const date = new Date(year, month + 1, day);
    days.push({
      date: date.toISOString().split("T")[0],
      events: [],
      isToday: false,
      isCurrentMonth: false,
    });
  }

  return days;
}

// Check if event is on a specific date
export function isEventOnDate(event: CalendarEvent, date: string): boolean {
  if (!event.start_date) return false;
  const eventStart = event.start_date.split("T")[0];
  const eventEnd = event.end_date?.split("T")[0] || eventStart;

  return date >= eventStart && date <= eventEnd;
}

// Get event position in multi-day span
export function getEventPosition(event: CalendarEvent, date: string): "start" | "middle" | "end" | "single" {
  if (!event.start_date) return "single";
  const eventStart = event.start_date.split("T")[0];
  const eventEnd = event.end_date?.split("T")[0] || eventStart;

  if (eventStart === eventEnd) return "single";
  if (date === eventStart) return "start";
  if (date === eventEnd) return "end";
  return "middle";
}
