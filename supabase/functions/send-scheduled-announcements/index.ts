// @deno-types="npm:@types/node"
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";
import { getCorsHeaders } from "../_shared/cors.ts";

// Cron job: Send scheduled admin announcements
// Schedule: every 15 minutes
serve(async (req) => {
  const corsHeaders = getCorsHeaders(req);

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    console.log("📢 Starting scheduled announcements check...");

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    // Use SERVICE_ROLE_JWT as primary since reserved SUPABASE_SERVICE_ROLE_KEY has issues
    const supabaseKey = Deno.env.get("SERVICE_ROLE_JWT") ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const serviceRoleJWT = Deno.env.get("SERVICE_ROLE_JWT")!;

    const now = new Date().toISOString();

    // Use direct REST API call to bypass schema cache
    const announcementsResponse = await fetch(
      `${supabaseUrl}/rest/v1/admin_announcements?status=eq.scheduled&scheduled_for=lte.${now}&order=scheduled_for.asc`,
      {
        headers: {
          "apikey": supabaseKey,
          "Authorization": `Bearer ${supabaseKey}`,
          "Content-Type": "application/json",
        },
      }
    );

    if (!announcementsResponse.ok) {
      const errorText = await announcementsResponse.text();
      console.error("❌ Error fetching announcements:", errorText);
      throw new Error(`Failed to fetch announcements: ${errorText}`);
    }

    const announcements = await announcementsResponse.json();

    if (!announcements || announcements.length === 0) {
      console.log("ℹ️ No pending announcements to send");
      return new Response(
        JSON.stringify({ message: "No pending announcements" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log(`📋 Found ${announcements.length} announcement(s) to send`);

    // Initialize Supabase client for user queries
    const supabase = createClient(supabaseUrl, supabaseKey, {
      auth: { persistSession: false }
    });

    let announcementsSent = 0;

    for (const announcement of announcements) {
      console.log(`📤 Processing announcement: "${announcement.title}"`);

      try {
        let targetUserIds: string[] = [];

        if (announcement.target_users === "all") {
          const { data: users } = await supabase.from("users").select("id");
          targetUserIds = users?.map((u: any) => u.id) || [];
        } else if (announcement.target_users === "active") {
          const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();
          const { data: users } = await supabase.from("users").select("id").gte("last_sign_in_at", sevenDaysAgo);
          targetUserIds = users?.map((u: any) => u.id) || [];
        } else if (announcement.target_users === "premium") {
          const { data: users } = await supabase.from("users").select("id").eq("is_premium", true);
          targetUserIds = users?.map((u: any) => u.id) || [];
        } else if (announcement.target_users === "custom" && announcement.custom_user_ids) {
          targetUserIds = announcement.custom_user_ids;
        }

        if (targetUserIds.length === 0) {
          console.log(`⚠️ No target users found for announcement ${announcement.id}`);
          continue;
        }

        console.log(`👥 Sending to ${targetUserIds.length} user(s)`);

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
                signal: AbortSignal.timeout(5000),
              }
            );

            if (notificationResponse.ok) {
              sentCount++;
            } else {
              failedCount++;
            }
          } catch (error) {
            failedCount++;
          }

          await new Promise((resolve) => setTimeout(resolve, 50));
        }

        console.log(`📊 Announcement ${announcement.id}: ${sentCount} sent, ${failedCount} failed`);

        // Three-status terminal mapping (CTO 2026-04-26):
        //   sent    — all recipients delivered
        //   partial — at least one delivered, at least one failed
        //   failed  — none delivered
        const totalCount = sentCount + failedCount;
        let finalStatus: "sent" | "partial" | "failed";
        if (sentCount === 0) {
          finalStatus = "failed";
        } else if (sentCount === totalCount) {
          finalStatus = "sent";
        } else {
          finalStatus = "partial";
        }

        // Update status + delivery counts using REST API.
        await fetch(
          `${supabaseUrl}/rest/v1/admin_announcements?id=eq.${announcement.id}`,
          {
            method: "PATCH",
            headers: {
              "apikey": supabaseKey,
              "Authorization": `Bearer ${supabaseKey}`,
              "Content-Type": "application/json",
              "Prefer": "return=minimal",
            },
            body: JSON.stringify({
              status: finalStatus,
              total_recipients: totalCount,
              successful_sends: sentCount,
              failed_sends: failedCount,
              sent_at: new Date().toISOString(),
            }),
          }
        );

        announcementsSent++;
      } catch (error) {
        console.error(`❌ Error processing announcement ${announcement.id}:`, error);

        // Revert to draft
        await fetch(
          `${supabaseUrl}/rest/v1/admin_announcements?id=eq.${announcement.id}`,
          {
            method: "PATCH",
            headers: {
              "apikey": supabaseKey,
              "Authorization": `Bearer ${supabaseKey}`,
              "Content-Type": "application/json",
              "Prefer": "return=minimal",
            },
            body: JSON.stringify({ status: "draft" }),
          }
        );
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
