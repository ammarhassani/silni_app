import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { getCorsHeaders } from "../_shared/cors.ts";

interface AnnouncementRequest {
  announcementId: string;
}

interface NotificationToken {
  user_id: string;
  fcm_token: string;
  platform: string;
}

serve(async (req) => {
  const corsHeaders = getCorsHeaders(req);

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { autoRefreshToken: false, persistSession: false } }
    );

    const { announcementId } = (await req.json()) as AnnouncementRequest;

    if (!announcementId) {
      return new Response(
        JSON.stringify({ success: false, error: "Missing announcementId" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Get the announcement
    const { data: announcement, error: fetchError } = await supabaseClient
      .from("admin_announcements")
      .select("*")
      .eq("id", announcementId)
      .single();

    if (fetchError || !announcement) {
      return new Response(
        JSON.stringify({ success: false, error: "Announcement not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Check if already sent
    if (announcement.status === "sent" || announcement.status === "sending") {
      return new Response(
        JSON.stringify({ success: false, error: "Announcement already sent or in progress" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Update status to sending
    await supabaseClient
      .from("admin_announcements")
      .update({ status: "sending" })
      .eq("id", announcementId);

    // Get target users based on audience
    let tokensQuery = supabaseClient
      .from("notification_tokens")
      .select("user_id, fcm_token, platform")
      .eq("is_active", true);

    if (announcement.target_users === "active") {
      // Active users: had activity in last 7 days
      const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();
      const { data: activeUsers } = await supabaseClient
        .from("user_activity")
        .select("user_id")
        .gte("last_active", sevenDaysAgo);

      if (activeUsers && activeUsers.length > 0) {
        const userIds = activeUsers.map((u) => u.user_id);
        tokensQuery = tokensQuery.in("user_id", userIds);
      }
    } else if (announcement.target_users === "premium") {
      // Premium users
      const { data: premiumUsers } = await supabaseClient
        .from("user_subscriptions")
        .select("user_id")
        .eq("status", "active")
        .neq("tier", "free");

      if (premiumUsers && premiumUsers.length > 0) {
        const userIds = premiumUsers.map((u) => u.user_id);
        tokensQuery = tokensQuery.in("user_id", userIds);
      }
    } else if (announcement.target_users === "custom" && announcement.custom_user_ids?.length > 0) {
      tokensQuery = tokensQuery.in("user_id", announcement.custom_user_ids);
    }
    // "all" = no filtering, send to everyone

    const { data: tokens, error: tokensError } = await tokensQuery;

    if (tokensError || !tokens || tokens.length === 0) {
      await supabaseClient
        .from("admin_announcements")
        .update({
          status: "failed",
          total_recipients: 0,
          sent_at: new Date().toISOString()
        })
        .eq("id", announcementId);

      return new Response(
        JSON.stringify({ success: false, error: "No valid tokens found", message: "لا يوجد مستخدمين لإرسال الإشعار لهم" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Get Firebase access token
    const firebaseServiceAccount = JSON.parse(
      Deno.env.get("FIREBASE_SERVICE_ACCOUNT") || "{}"
    );

    if (!firebaseServiceAccount.client_email || !firebaseServiceAccount.private_key) {
      throw new Error("Firebase service account not configured");
    }

    const accessToken = await getFirebaseAccessToken(firebaseServiceAccount);

    // Send notifications
    let successCount = 0;
    let failCount = 0;
    const errors: string[] = [];

    for (const token of tokens as NotificationToken[]) {
      try {
        const response = await sendFCMNotification(
          accessToken,
          firebaseServiceAccount.project_id,
          token.fcm_token,
          token.platform,
          {
            title: announcement.title_ar,
            body: announcement.body_ar,
            data: {
              type: "announcement",
              announcementId: announcement.id,
              deepLink: announcement.deep_link || "",
              ...announcement.deep_link_params,
            },
          }
        );

        if (response.ok) {
          successCount++;
        } else {
          failCount++;
          const errorText = await response.text();
          if (!errors.includes(errorText)) {
            errors.push(errorText);
          }
        }
      } catch (e) {
        failCount++;
        console.error(`Failed to send to ${token.user_id}:`, e);
      }
    }

    // Update announcement with results
    await supabaseClient
      .from("admin_announcements")
      .update({
        status: failCount === tokens.length ? "failed" : "sent",
        total_recipients: tokens.length,
        successful_sends: successCount,
        failed_sends: failCount,
        sent_at: new Date().toISOString(),
      })
      .eq("id", announcementId);

    return new Response(
      JSON.stringify({
        success: true,
        totalRecipients: tokens.length,
        successCount,
        failCount,
        errors: errors.slice(0, 3), // Only return first 3 errors
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (error) {
    console.error("Error sending announcement:", error);
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

// Helper: Get Firebase access token using service account
async function getFirebaseAccessToken(serviceAccount: {
  client_email: string;
  private_key: string;
}): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: serviceAccount.client_email,
    sub: serviceAccount.client_email,
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  };

  const encodedHeader = btoa(JSON.stringify(header))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
  const encodedPayload = btoa(JSON.stringify(payload))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");

  const signatureInput = `${encodedHeader}.${encodedPayload}`;

  // Import the private key and sign
  const privateKey = await crypto.subtle.importKey(
    "pkcs8",
    pemToBinary(serviceAccount.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    privateKey,
    new TextEncoder().encode(signatureInput)
  );

  const encodedSignature = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");

  const jwt = `${signatureInput}.${encodedSignature}`;

  // Exchange JWT for access token
  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const tokenData = await tokenResponse.json();
  return tokenData.access_token;
}

function pemToBinary(pem: string): ArrayBuffer {
  const base64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\n/g, "");
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes.buffer;
}

// Helper: Send FCM notification
async function sendFCMNotification(
  accessToken: string,
  projectId: string,
  fcmToken: string,
  platform: string,
  notification: {
    title: string;
    body: string;
    data?: Record<string, string>;
  }
): Promise<Response> {
  const message: Record<string, unknown> = {
    token: fcmToken,
    notification: {
      title: notification.title,
      body: notification.body,
    },
    data: notification.data || {},
  };

  // Platform-specific config
  if (platform === "ios") {
    message.apns = {
      payload: {
        aps: {
          alert: { title: notification.title, body: notification.body },
          sound: "default",
          badge: 1,
        },
      },
    };
  } else {
    message.android = {
      priority: "high",
      notification: {
        sound: "default",
        channelId: "silni_announcements",
      },
    };
  }

  return fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ message }),
    }
  );
}
