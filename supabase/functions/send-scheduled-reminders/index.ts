// @deno-types="npm:@types/node"
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import { getCorsHeaders } from "../_shared/cors.ts";

/**
 * Cron job: Send scheduled reminder notifications every minute
 * Checks reminder_schedules table for reminders that should fire at this exact minute
 *
 * Schedule: * * * * * (every minute)
 *
 * Flutter App Schema:
 * - time: TEXT (HH:mm format, e.g., "09:33", "21:01")
 * - relative_ids: UUID[] (array of relative IDs)
 * - custom_days: INTEGER[] (1=Monday, 7=Sunday)
 * - day_of_month: INTEGER (1-31 for monthly reminders)
 * - frequency: TEXT (daily, weekly, monthly, friday, custom)
 */
serve(async (req) => {
  const corsHeaders = getCorsHeaders(req);

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    console.log("🔔 Starting scheduled reminders check...");

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    // Use SERVICE_ROLE_JWT as primary since reserved SUPABASE_SERVICE_ROLE_KEY has issues
    const supabaseKey = Deno.env.get("SERVICE_ROLE_JWT") ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Get current time in Riyadh timezone (UTC+3)
    const now = new Date();
    const riyadhOffset = 3 * 60; // minutes
    const riyadhTime = new Date(now.getTime() + riyadhOffset * 60 * 1000);
    const currentHour = riyadhTime.getUTCHours();
    const currentMinute = riyadhTime.getUTCMinutes();
    const currentJsDay = riyadhTime.getUTCDay(); // 0 = Sunday, 6 = Saturday
    const currentDayOfMonth = riyadhTime.getUTCDate();

    // Format current time as HH:mm for exact matching
    const currentTimeStr = `${currentHour.toString().padStart(2, "0")}:${currentMinute.toString().padStart(2, "0")}`;

    // Convert JS day (0=Sunday) to Flutter day (1=Monday, 7=Sunday)
    const currentFlutterDay = currentJsDay === 0 ? 7 : currentJsDay;

    console.log(`⏰ Current Riyadh time: ${riyadhTime.toISOString()}`);
    console.log(`   Time: ${currentTimeStr}, JS Day: ${currentJsDay}, Flutter Day: ${currentFlutterDay}, Day of Month: ${currentDayOfMonth}`);

    // Get all active reminder schedules that match the current time exactly
    const { data: schedules, error: schedulesError } = await supabase
      .from("reminder_schedules")
      .select("*")
      .eq("is_active", true)
      .eq("time", currentTimeStr);

    if (schedulesError) {
      console.error("❌ Error fetching schedules:", schedulesError);
      throw schedulesError;
    }

    if (!schedules || schedules.length === 0) {
      console.log(`ℹ️ No active reminders scheduled for ${currentTimeStr}`);
      return new Response(
        JSON.stringify({ message: `No reminders for ${currentTimeStr}` }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log(`📋 Found ${schedules.length} schedule(s) for ${currentTimeStr}`);

    let remindersSent = 0;
    let skipped = 0;

    // Check each schedule
    for (const schedule of schedules) {
      console.log(`\n📝 Processing schedule ${schedule.id} (frequency: ${schedule.frequency})`);

      // Check if this reminder should fire today based on frequency
      let shouldFire = false;

      switch (schedule.frequency) {
        case "daily":
          shouldFire = true;
          console.log("   ✓ Daily reminder - fires today");
          break;

        case "weekly":
          // custom_days uses Flutter numbering: 1=Monday, 7=Sunday
          if (schedule.custom_days && Array.isArray(schedule.custom_days) && schedule.custom_days.length > 0) {
            shouldFire = schedule.custom_days.includes(currentFlutterDay);
            console.log(`   Weekly check: custom_days=${JSON.stringify(schedule.custom_days)}, today=${currentFlutterDay}, fires=${shouldFire}`);
          } else {
            // If no custom_days specified, fire every day (treat as daily)
            shouldFire = true;
            console.log("   Weekly reminder with no/empty custom_days - fires today");
          }
          break;

        case "monthly":
          // day_of_month is 1-31
          if (schedule.day_of_month) {
            shouldFire = schedule.day_of_month === currentDayOfMonth;
            console.log(`   Monthly check: day_of_month=${schedule.day_of_month}, today=${currentDayOfMonth}, fires=${shouldFire}`);
          } else {
            // Fallback: fire on the same day as created
            const createdDate = new Date(schedule.created_at);
            shouldFire = createdDate.getDate() === currentDayOfMonth;
            console.log(`   Monthly fallback: created on day ${createdDate.getDate()}, today=${currentDayOfMonth}, fires=${shouldFire}`);
          }
          break;

        case "friday":
          // Friday is day 5 in JavaScript (0=Sunday)
          shouldFire = currentJsDay === 5;
          console.log(`   Friday check: today is JS day ${currentJsDay}, fires=${shouldFire}`);
          break;

        case "custom":
          // Custom frequency - use interval_days if available
          if (schedule.interval_days) {
            const daysSinceCreated = Math.floor(
              (riyadhTime.getTime() - new Date(schedule.created_at).getTime()) /
                (1000 * 60 * 60 * 24)
            );
            shouldFire = daysSinceCreated % schedule.interval_days === 0;
            console.log(`   Custom check: interval=${schedule.interval_days}, days since created=${daysSinceCreated}, fires=${shouldFire}`);
          }
          break;

        default:
          console.log(`   ⚠️ Unknown frequency: ${schedule.frequency}`);
      }

      if (!shouldFire) {
        console.log(`   ⏭️ Skipping - not scheduled for today`);
        skipped++;
        continue;
      }

      // Get relative_ids array
      const relativeIds = schedule.relative_ids;
      if (!relativeIds || !Array.isArray(relativeIds) || relativeIds.length === 0) {
        console.log(`   ⚠️ No relatives in schedule, skipping`);
        skipped++;
        continue;
      }

      console.log(`   👥 Found ${relativeIds.length} relative(s) to notify about`);

      // Fetch relatives info — also pull last_contact_date for the
      // recent-contact suppression check (Phase 9.X.D Track A3).
      const { data: relatives, error: relativesError } = await supabase
        .from("relatives")
        .select("id, full_name, user_id, last_contact_date, relative_category")
        .in("id", relativeIds);

      if (relativesError) {
        console.error(`   ❌ Error fetching relatives:`, relativesError);
        skipped++;
        continue;
      }

      if (!relatives || relatives.length === 0) {
        console.log(`   ⚠️ No relatives found with IDs: ${relativeIds}`);
        skipped++;
        continue;
      }

      // Phase 9.X.D Track A3: Recent-contact suppression.
      //
      // The "remind me to call dad after lunch" production bug — if the user
      // already contacted a relative recently, don't fire a reminder for that
      // relative. Default-on behavior, gated by users.suppress_reminders_after_recent_contact.
      //
      // v1 uses a single 24h threshold for all relative_categories. The CTO
      // spec mentioned a 6h household threshold but said to simplify if it
      // adds complexity; revisit in v1.1 if households need tighter cadence.
      let workingRelatives: any[] = relatives;
      const SUPPRESSION_HOURS = 24;
      try {
        const { data: userRow, error: userErr } = await supabase
          .from("users")
          .select("suppress_reminders_after_recent_contact")
          .eq("id", schedule.user_id)
          .single();

        const suppressionEnabled =
          userErr ? true : (userRow?.suppress_reminders_after_recent_contact ?? true);

        if (suppressionEnabled) {
          const cutoffMs = riyadhTime.getTime() - SUPPRESSION_HOURS * 60 * 60 * 1000;
          const filtered: any[] = [];
          for (const r of relatives) {
            if (r.last_contact_date) {
              const lastMs = new Date(r.last_contact_date).getTime();
              const hoursAgo = ((riyadhTime.getTime() - lastMs) / (1000 * 60 * 60)).toFixed(1);
              if (lastMs >= cutoffMs) {
                console.log(
                  `   ⏸️ Suppressing reminder for relative ${r.id} (${r.full_name}) — last contact ${hoursAgo}h ago, threshold ${SUPPRESSION_HOURS}h`
                );
                continue;
              }
            }
            filtered.push(r);
          }
          workingRelatives = filtered;
        }
      } catch (e) {
        console.warn(`   ⚠️ Suppression check failed (proceeding without filter):`, e);
        workingRelatives = relatives;
      }

      if (workingRelatives.length === 0) {
        // All relatives in this schedule were recently contacted. Skip the
        // notification entirely AND skip last_sent update so tomorrow's tick
        // re-evaluates fresh.
        console.log(
          `   ⏭️ All ${relatives.length} relative(s) in schedule were recently contacted within ${SUPPRESSION_HOURS}h — skipping send`
        );
        skipped++;
        continue;
      }

      // Build consolidated notification for the (possibly suppression-filtered)
      // relative list. relativeNames + allIds reflect post-filter set so the
      // user only sees a notification about people they haven't contacted recently.
      const relativeNames = workingRelatives.map((r: any) => r.full_name);
      const allIds = workingRelatives.map((r: any) => r.id).join(',');

      // Format names: show first 3, then "وX آخرون" for remaining
      let namesText: string;
      if (relativeNames.length === 1) {
        namesText = relativeNames[0];
      } else if (relativeNames.length === 2) {
        namesText = `${relativeNames[0]} و${relativeNames[1]}`;
      } else if (relativeNames.length === 3) {
        namesText = `${relativeNames[0]}، ${relativeNames[1]} و${relativeNames[2]}`;
      } else {
        const firstThree = relativeNames.slice(0, 3).join('، ');
        const remaining = relativeNames.length - 3;
        namesText = `${firstThree} و${remaining} آخرون`;
      }

      // Frequency to Arabic title mapping
      const frequencyTitles: Record<string, string> = {
        'daily': 'تذكير يومي',
        'weekly': 'تذكير أسبوعي',
        'monthly': 'تذكير شهري',
        'friday': 'تذكير الجمعة',
        'custom': 'تذكير مخصص'
      };

      const title = schedule.custom_title || frequencyTitles[schedule.frequency] || 'تذكير';
      const body = schedule.custom_message || `حان وقت التواصل مع ${namesText}`;

      console.log(`   📤 Sending consolidated reminder for ${relatives.length} relative(s) to user ${schedule.user_id}`);
      console.log(`   📝 Title: "${title}", Body: "${body}"`);

      // Only flip to true when send-push-notification confirms ≥1 device delivered.
      // last_sent is updated only on success; any failure (HTTP error, 0 tokens,
      // network exception) leaves last_sent unchanged so the schedule's "last
      // delivered at" reflects reality. Re-firing in the same minute is not a
      // concern because the cron WHERE clause keys on (is_active, time=HH:mm),
      // not on last_sent.
      let sentSuccessfully = false;

      try {
        // Call send-push-notification function with ONE consolidated notification.
        // 5s timeout (Phase 7 Task 7) — without this, a stalled inner
        // fetch could pin the cron-minute function for the platform's
        // wall-clock kill (~60s).
        const notificationResponse = await fetch(
          `${supabaseUrl}/functions/v1/send-push-notification`,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              Authorization: `Bearer ${supabaseKey}`,
            },
            body: JSON.stringify({
              userId: schedule.user_id,
              notificationType: "reminder",
              title,
              body,
              data: {
                type: "reminder",
                relative_ids: allIds,  // Comma-separated IDs for navigation
                schedule_id: schedule.id,
                frequency: schedule.frequency,
              },
            }),
            signal: AbortSignal.timeout(5000),
          }
        );

        const responseText = await notificationResponse.text();
        console.log(`   📨 Push notification response: ${responseText}`);

        if (notificationResponse.ok) {
          const responseData = JSON.parse(responseText);
          // Check if notification was actually sent (not just "no tokens found")
          if (responseData.sent > 0) {
            sentSuccessfully = true;
            remindersSent++;
            console.log(`   ✅ Consolidated reminder sent for ${relatives.length} relative(s)`);
          } else {
            console.log(`   ⚠️ No FCM tokens found for user - notification not delivered; last_sent unchanged`);
          }
        } else {
          console.error(`   ❌ Failed to send reminder (HTTP ${notificationResponse.status}): ${responseText}; last_sent unchanged`);
        }
      } catch (error) {
        console.error(`   ❌ Error sending notification (last_sent unchanged):`, error);
      }

      // Update last_sent only on confirmed delivery.
      if (sentSuccessfully) {
        await supabase
          .from("reminder_schedules")
          .update({ last_sent: new Date().toISOString() })
          .eq("id", schedule.id);
      }
    }

    console.log(`\n📊 Reminder check complete:`);
    console.log(`   - Time: ${currentTimeStr}`);
    console.log(`   - Schedules matched: ${schedules.length}`);
    console.log(`   - Reminders sent: ${remindersSent}`);
    console.log(`   - Skipped: ${skipped}`);

    return new Response(
      JSON.stringify({
        success: true,
        time: currentTimeStr,
        flutterDay: currentFlutterDay,
        dayOfMonth: currentDayOfMonth,
        schedulesMatched: schedules.length,
        remindersSent,
        skipped,
        message: `Sent ${remindersSent} reminders for ${currentTimeStr}`,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("❌ Unexpected error:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
