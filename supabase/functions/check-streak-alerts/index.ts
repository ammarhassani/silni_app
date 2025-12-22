// @deno-types="npm:@types/node"
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

/**
 * Cron job: Check for endangered streaks (Snapchat-style)
 * Sends push notifications to users whose streak_deadline is within 4 hours
 *
 * Schedule: 0 * * * * (every hour)
 */
serve(async (req) => {
  try {
    console.log("🔄 Starting streak alert check (Snapchat-style)...");

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Get JWT for function-to-function calls
    const serviceRoleJWT = Deno.env.get("SERVICE_ROLE_JWT")!;

    const now = new Date();
    const fourHoursFromNow = new Date(now.getTime() + 4 * 60 * 60 * 1000);

    console.log(`📅 Checking for deadlines between now and ${fourHoursFromNow.toISOString()}`);

    // Get users with streak_deadline within 4 hours and active streaks
    const { data: users, error: usersError } = await supabase
      .from("users")
      .select("id, full_name, current_streak, streak_deadline")
      .gt("current_streak", 0)
      .not("streak_deadline", "is", null)
      .gt("streak_deadline", now.toISOString()) // Not expired yet
      .lte("streak_deadline", fourHoursFromNow.toISOString()); // Within 4 hours

    if (usersError) {
      console.error("❌ Error fetching users:", usersError);
      throw usersError;
    }

    if (!users || users.length === 0) {
      console.log("ℹ️ No users with endangered streaks found");
      return new Response(
        JSON.stringify({ message: "No users with endangered streaks" }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    console.log(`⚠️ Found ${users.length} user(s) with endangered streaks`);

    let alertsSent = 0;

    for (const user of users) {
      const deadline = new Date(user.streak_deadline);
      const hoursRemaining = Math.round((deadline.getTime() - now.getTime()) / (60 * 60 * 1000));

      console.log(`⏰ User ${user.id} (${user.full_name}): ${hoursRemaining}h remaining, streak: ${user.current_streak}`);

      try {
        // Determine urgency level for notification
        const isUrgent = hoursRemaining <= 1;
        const title = isUrgent
          ? "⏰ شعلتك على وشك الانطفاء!"
          : "🔥 حافظ على شعلتك!";
        const body = isUrgent
          ? `أقل من ساعة لحماية شعلة ${user.current_streak} يوم! تفاعل الآن`
          : `لديك ${hoursRemaining} ساعات لحماية شعلة ${user.current_streak} يوم`;

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
              userId: user.id,
              notificationType: "streak",
              title,
              body,
              data: {
                streak_count: user.current_streak.toString(),
                hours_remaining: hoursRemaining.toString(),
                urgent: isUrgent.toString(),
              },
            }),
          }
        );

        if (notificationResponse.ok) {
          alertsSent++;
          console.log(`✅ Streak alert sent to user ${user.id}`);
        } else {
          const errorText = await notificationResponse.text();
          console.error(`❌ Failed to send alert to user ${user.id}:`, errorText);
        }
      } catch (error) {
        console.error(`❌ Error sending notification to user ${user.id}:`, error);
      }

      // Rate limiting: wait 100ms between notifications
      await new Promise((resolve) => setTimeout(resolve, 100));
    }

    console.log(`📊 Streak check complete: ${alertsSent} alerts sent`);

    return new Response(
      JSON.stringify({
        success: true,
        checked: users.length,
        alertsSent,
        message: `Checked ${users.length} endangered users, sent ${alertsSent} alerts`,
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
