// @deno-types="npm:@types/node"
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

/**
 * Cron job: Send scheduled reminder notifications hourly
 * Checks reminder_schedules table for reminders that should fire this hour
 *
 * Schedule: 0 * * * * (every hour)
 */
serve(async (req) => {
  try {
    console.log("🔔 Starting scheduled reminders check...");

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Get JWT for function-to-function calls
    const serviceRoleJWT = Deno.env.get("SERVICE_ROLE_JWT")!;

    // Get current hour in Riyadh timezone (UTC+3)
    const now = new Date();
    const riyadhOffset = 3 * 60; // minutes
    const riyadhTime = new Date(now.getTime() + riyadhOffset * 60 * 1000);
    const currentHour = riyadhTime.getHours();
    const currentDay = riyadhTime.getDay(); // 0 = Sunday, 6 = Saturday

    console.log(`⏰ Current time: ${riyadhTime.toISOString()}, Hour: ${currentHour}, Day: ${currentDay}`);

    // Get all active reminder schedules for this hour
    const { data: schedules, error: schedulesError } = await supabase
      .from("reminder_schedules")
      .select(`
        *,
        relatives (
          id,
          full_name,
          user_id
        )
      `)
      .eq("is_active", true)
      .eq("notification_hour", currentHour);

    if (schedulesError) {
      console.error("❌ Error fetching schedules:", schedulesError);
      throw schedulesError;
    }

    if (!schedules || schedules.length === 0) {
      console.log(`ℹ️ No active reminders scheduled for hour ${currentHour}`);
      return new Response(
        JSON.stringify({ message: `No reminders for hour ${currentHour}` }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    console.log(`📋 Found ${schedules.length} schedule(s) for hour ${currentHour}`);

    let remindersSent = 0;
    let skipped = 0;

    // Check each schedule
    for (const schedule of schedules) {
      // Check if this reminder should fire today based on frequency
      let shouldFire = false;

      switch (schedule.frequency) {
        case "daily":
          shouldFire = true;
          break;

        case "weekly":
          // Check if today matches the configured day
          if (schedule.days_of_week && schedule.days_of_week.includes(currentDay)) {
            shouldFire = true;
          }
          break;

        case "monthly":
          // Fire on the same day of month as created
          const createdDate = new Date(schedule.created_at);
          const todayDate = riyadhTime.getDate();
          if (createdDate.getDate() === todayDate) {
            shouldFire = true;
          }
          break;

        case "custom":
          // Check custom interval (e.g., every 3 days)
          if (schedule.interval_days) {
            const daysSinceCreated = Math.floor(
              (riyadhTime.getTime() - new Date(schedule.created_at).getTime()) /
                (1000 * 60 * 60 * 24)
            );
            if (daysSinceCreated % schedule.interval_days === 0) {
              shouldFire = true;
            }
          }
          break;
      }

      if (!shouldFire) {
        console.log(`⏭️ Skipping schedule ${schedule.id} - not scheduled for today`);
        skipped++;
        continue;
      }

      // Get relative info
      const relative = schedule.relatives;
      if (!relative) {
        console.error(`❌ No relative found for schedule ${schedule.id}`);
        skipped++;
        continue;
      }

      console.log(`📤 Sending reminder for relative "${relative.full_name}" to user ${relative.user_id}`);

      try {
        // Prepare notification data
        const title = schedule.custom_title || `تذكير: ${relative.full_name}`;
        const body = schedule.custom_message || `حان وقت التواصل مع ${relative.full_name}`;

        // Call send-push-notification function
        const notificationResponse = await fetch(
          `${supabaseUrl}/functions/v1/send-push-notification`,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              Authorization: `Bearer ${serviceRoleJWT}`,
            },
            body: JSON.stringify({
              userId: relative.user_id,
              notificationType: "reminder",
              title,
              body,
              data: {
                relative_id: relative.id,
                schedule_id: schedule.id,
                frequency: schedule.frequency,
              },
            }),
          }
        );

        if (notificationResponse.ok) {
          remindersSent++;
          console.log(`✅ Reminder sent for schedule ${schedule.id}`);

          // Update last_sent timestamp
          await supabase
            .from("reminder_schedules")
            .update({ last_sent: new Date().toISOString() })
            .eq("id", schedule.id);
        } else {
          const errorText = await notificationResponse.text();
          console.error(`❌ Failed to send reminder for schedule ${schedule.id}:`, errorText);
        }
      } catch (error) {
        console.error(`❌ Error processing schedule ${schedule.id}:`, error);
      }

      // Rate limiting: wait 100ms between notifications
      await new Promise((resolve) => setTimeout(resolve, 100));
    }

    console.log(`📊 Reminder check complete: ${remindersSent} sent, ${skipped} skipped`);

    return new Response(
      JSON.stringify({
        success: true,
        hour: currentHour,
        checked: schedules.length,
        remindersSent,
        skipped,
        message: `Sent ${remindersSent} reminders for hour ${currentHour}`,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("❌ Unexpected error:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
