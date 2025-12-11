// @deno-types="npm:@types/node"
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";


serve(async (req) => {
  try {
    console.log("📢 Starting scheduled announcements check...");

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Get JWT for function-to-function calls
    const serviceRoleJWT = Deno.env.get("SERVICE_ROLE_JWT")!;

    const now = new Date().toISOString();

    // Get pending announcements that are ready to send
    const { data: announcements, error: announcementsError } = await supabase
      .from("admin_announcements")
      .select("*")
      .eq("status", "scheduled")
      .lte("scheduled_for", now)
      .order("scheduled_for", { ascending: true });

    if (announcementsError) {
      console.error("❌ Error fetching announcements:", announcementsError);
      throw announcementsError;
    }

    if (!announcements || announcements.length === 0) {
      console.log("ℹ️ No pending announcements to send");
      return new Response(
        JSON.stringify({ message: "No pending announcements" }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    console.log(`📋 Found ${announcements.length} announcement(s) to send`);

    let announcementsSent = 0;

    // Process each announcement
    for (const announcement of announcements) {
      console.log(`📤 Processing announcement: "${announcement.title}"`);

      try {
        // Determine target users
        let targetUserIds: string[] = [];

        if (announcement.target_users === "all") {
          // Get all users
          const { data: users } = await supabase
            .from("users")
            .select("id");
          targetUserIds = users?.map((u) => u.id) || [];
        } else if (announcement.target_users === "active") {
          // Get users with recent activity (last 7 days)
          const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();
          const { data: users } = await supabase
            .from("users")
            .select("id")
            .gte("last_sign_in_at", sevenDaysAgo);
          targetUserIds = users?.map((u) => u.id) || [];
        } else if (announcement.target_users === "premium") {
          // Get premium users (if you have a premium system)
          const { data: users } = await supabase
            .from("users")
            .select("id")
            .eq("is_premium", true);
          targetUserIds = users?.map((u) => u.id) || [];
        } else if (announcement.target_users === "custom" && announcement.custom_user_ids) {
          // Use custom user IDs
          targetUserIds = announcement.custom_user_ids;
        }

        if (targetUserIds.length === 0) {
          console.log(`⚠️ No target users found for announcement ${announcement.id}`);
          continue;
        }

        console.log(`👥 Sending to ${targetUserIds.length} user(s)`);

        // Send notification to each user
        let sentCount = 0;
        let failedCount = 0;

        for (const userId of targetUserIds) {
          try {
            const notificationResponse = await fetch(
              `${supabaseUrl}/functions/v1/send-push-notification`,
              {
                method: "POST",
                headers: {
                  "Content-Type": "application/json",
                  Authorization: `Bearer ${serviceRoleJWT}`,
                },
                body: JSON.stringify({
                  userId,
                  notificationType: "announcement",
                  title: announcement.title,
                  body: announcement.body,
                  data: {
                    announcement_id: announcement.id,
                    ...announcement.notification_data,
                  },
                }),
              }
            );

            if (notificationResponse.ok) {
              sentCount++;
            } else {
              failedCount++;
              const errorText = await notificationResponse.text();
              console.error(`❌ Failed to send to user ${userId}:`, errorText);
            }
          } catch (error) {
            failedCount++;
            console.error(`❌ Error sending to user ${userId}:`, error);
          }

          // Rate limiting: wait 50ms between users
          await new Promise((resolve) => setTimeout(resolve, 50));
        }

        console.log(`📊 Announcement ${announcement.id}: ${sentCount} sent, ${failedCount} failed`);

        // Update announcement status
        await supabase
          .from("admin_announcements")
          .update({
            status: "sent",
            sent_at: new Date().toISOString(),
          })
          .eq("id", announcement.id);

        announcementsSent++;
      } catch (error) {
        console.error(`❌ Error processing announcement ${announcement.id}:`, error);

        // Mark announcement as failed
        await supabase
          .from("admin_announcements")
          .update({ status: "draft" }) // Revert to draft so admin can retry
          .eq("id", announcement.id);
      }
    }

    console.log(`✅ Announcement check complete: ${announcementsSent} sent`);

    return new Response(
      JSON.stringify({
        success: true,
        processed: announcements.length,
        announcementsSent,
        message: `Sent ${announcementsSent} announcement(s)`,
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
