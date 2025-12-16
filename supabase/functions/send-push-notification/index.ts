// @deno-types="npm:@types/node"
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

// Firebase Admin SDK for FCM
const FIREBASE_SERVICE_ACCOUNT = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");

interface NotificationRequest {
  userId: string;
  notificationType: "reminder" | "streak" | "achievement" | "announcement";
  title: string;
  body: string;
  data?: Record<string, string>;
}

interface FCMMessage {
  message: {
    token: string;
    notification: {
      title: string;
      body: string;
    };
    data?: Record<string, string>;
    apns: {
      payload: {
        aps: {
          sound: "default";
          badge?: number;
        };
      };
    };
    android: {
      priority: "high";
      notification: {
        sound: "default";
        channelId: "silni_channel";
      };
    };
  };
}

/**
 * Send push notification to a user's devices via FCM
 *
 * Request body:
 * {
 *   "userId": "uuid",
 *   "notificationType": "reminder|streak|achievement|announcement",
 *   "title": "Notification title",
 *   "body": "Notification body",
 *   "data": { "key": "value" } // optional
 * }
 */
serve(async (req) => {
  try {
    // CORS headers
    if (req.method === "OPTIONS") {
      return new Response("ok", {
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "POST",
          "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
        },
      });
    }

    // Parse request
    const { userId, notificationType, title, body, data } = await req.json() as NotificationRequest;

    if (!userId || !notificationType || !title || !body) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    console.log(`📤 Sending ${notificationType} notification to user ${userId}`);

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    // Use SERVICE_ROLE_JWT as primary since reserved SUPABASE_SERVICE_ROLE_KEY has issues
    const supabaseKey = Deno.env.get("SERVICE_ROLE_JWT") ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Get user's active FCM tokens
    const { data: tokens, error: tokensError } = await supabase
      .from("notification_tokens")
      .select("fcm_token, platform")
      .eq("user_id", userId)
      .eq("is_active", true);

    if (tokensError) {
      console.error("❌ Error fetching tokens:", tokensError);
      return new Response(
        JSON.stringify({ error: "Failed to fetch user tokens" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    if (!tokens || tokens.length === 0) {
      console.log(`⚠️ No active FCM tokens found for user ${userId}`);
      return new Response(
        JSON.stringify({ message: "No active tokens found for user" }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    console.log(`📱 Found ${tokens.length} active token(s)`);

    // Get Firebase access token
    const firebaseCredentials = JSON.parse(FIREBASE_SERVICE_ACCOUNT!);
    const accessToken = await getFirebaseAccessToken(firebaseCredentials);

    // Send notification to each device
    const errors: string[] = [];
    const results = await Promise.allSettled(
      tokens.map(async ({ fcm_token, platform }) => {
        const fcmMessage: FCMMessage = {
          message: {
            token: fcm_token,
            notification: {
              title,
              body,
            },
            data: {
              type: notificationType,
              ...data,
            },
            apns: {
              payload: {
                aps: {
                  sound: "default",
                },
              },
            },
            android: {
              priority: "high",
              notification: {
                sound: "default",
                channelId: "silni_channel",
              },
            },
          },
        };

        const response = await fetch(
          `https://fcm.googleapis.com/v1/projects/${firebaseCredentials.project_id}/messages:send`,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              Authorization: `Bearer ${accessToken}`,
            },
            body: JSON.stringify(fcmMessage),
          }
        );

        if (!response.ok) {
          const errorText = await response.text();
          console.error(`❌ FCM error for ${platform}:`, errorText);
          errors.push(`${platform}: ${errorText}`);
          throw new Error(`FCM error: ${errorText}`);
        }

        const result = await response.json();
        console.log(`✅ Notification sent to ${platform}:`, result.name);
        return result;
      })
    );

    // Log notification history
    const successCount = results.filter((r) => r.status === "fulfilled").length;
    const failureCount = results.filter((r) => r.status === "rejected").length;

    if (errors.length > 0) {
      console.error("FCM Errors:", errors);
    }

    await supabase.from("notification_history").insert({
      user_id: userId,
      notification_type: notificationType,
      title,
      body,
      data,
      sent_at: new Date().toISOString(),
      status: successCount > 0 ? "sent" : "failed",
    });

    console.log(`📊 Results: ${successCount} sent, ${failureCount} failed`);

    return new Response(
      JSON.stringify({
        success: true,
        sent: successCount,
        failed: failureCount,
        message: `Notification sent to ${successCount} device(s)`,
        errors: errors.length > 0 ? errors : undefined,
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

/**
 * URL-safe base64 encoding for JWT
 */
function base64UrlEncode(str: string): string {
  return btoa(str)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

function arrayBufferToBase64Url(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  let binary = '';
  for (let i = 0; i < bytes.length; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

/**
 * Get Firebase access token using service account credentials
 */
async function getFirebaseAccessToken(credentials: any): Promise<string> {
  const header = { alg: "RS256", typ: "JWT" };
  const now = Math.floor(Date.now() / 1000);
  const claimSet = {
    iss: credentials.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };

  const jwtHeader = base64UrlEncode(JSON.stringify(header));
  const jwtClaimSet = base64UrlEncode(JSON.stringify(claimSet));
  const signatureInput = `${jwtHeader}.${jwtClaimSet}`;

  // Import private key
  const privateKey = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(credentials.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  // Sign JWT
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    privateKey,
    new TextEncoder().encode(signatureInput)
  );

  const jwtSignature = arrayBufferToBase64Url(signature);
  const jwt = `${signatureInput}.${jwtSignature}`;

  // Exchange JWT for access token
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const result = await response.json();

  if (!result.access_token) {
    console.error("Failed to get access token:", result);
    throw new Error(`OAuth error: ${JSON.stringify(result)}`);
  }

  return result.access_token;
}

/**
 * Convert PEM private key to ArrayBuffer
 */
function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes.buffer;
}
