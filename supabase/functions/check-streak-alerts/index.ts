// @deno-types="npm:@types/node"
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

/**
 * Cron job: Check for endangered streaks daily at 9 PM Riyadh time
 * Sends push notifications to users who haven't interacted today
 *
 * Schedule: 0 18 * * * (6 PM UTC = 9 PM Riyadh)
 */
serve(async (req) => {
  try {
    console.log("🔄 Starting streak alert check...");

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Get JWT for function-to-function calls
    const serviceRoleJWT = Deno.env.get("SERVICE_ROLE_JWT")!;

    // Get today's date in Riyadh timezone (UTC+3)
    const now = new Date();
    const riyadhOffset = 3 * 60; // minutes
    const riyadhTime = new Date(now.getTime() + riyadhOffset * 60 * 1000);
    const todayStart = new Date(riyadhTime);
    todayStart.setHours(0, 0, 0, 0);

    console.log(`📅 Checking for interactions since ${todayStart.toISOString()}`);

    // Get users with active streaks
    const { data: users, error: usersError } = await supabase
      .from("users")
      .select("id, full_name, current_streak")
      .gt("current_streak", 0);

    if (usersError) {
      console.error("❌ Error fetching users:", usersError);
      throw usersError;
    }

    if (!users || users.length === 0) {
      console.log("ℹ️ No users with active streaks found");
      return new Response(
        JSON.stringify({ message: "No users with active streaks" }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    console.log(`👥 Found ${users.length} user(s) with active streaks`);

    let alertsSent = 0;
    let skipped = 0;

    // Check each user for today's interactions
    for (const user of users) {
      // Check if user has any interactions today
      const { data: interactions, error: interactionsError } = await supabase
        .from("interactions")
        .select("id")
        .eq("user_id", user.id)
        .gte("created_at", todayStart.toISOString())
        .limit(1);

      if (interactionsError) {
        console.error(`❌ Error checking interactions for user ${user.id}:`, interactionsError);
        continue;
      }

      // If user has interactions today, skip them
      if (interactions && interactions.length > 0) {
        console.log(`✅ User ${user.id} has interacted today - skipping`);
        skipped++;
        continue;
      }

      // User hasn't interacted today - send alert
      console.log(`⚠️ User ${user.id} (${user.full_name}) hasn't interacted today - sending alert`);

      try {
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
              title: "🔥 حافظ على شعلتك!",
              body: `لديك شعلة ${user.current_streak} أيام! تفاعل مع أقاربك اليوم للحفاظ عليها`,
              data: {
                streak_count: user.current_streak.toString(),
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

    console.log(`📊 Streak check complete: ${alertsSent} alerts sent, ${skipped} skipped`);

    return new Response(
      JSON.stringify({
        success: true,
        checked: users.length,
        alertsSent,
        skipped,
        message: `Checked ${users.length} users, sent ${alertsSent} alerts`,
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
