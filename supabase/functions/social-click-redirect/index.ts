// @deno-types="npm:@types/node"
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { getCorsHeaders } from "../_shared/cors.ts";

/**
 * HTTP endpoint: Log UTM click data and redirect to the App Store.
 *
 * Called via URL like:
 *   https://{supabase-url}/functions/v1/social-click-redirect
 *     ?post_id=xxx
 *     &utm_source=twitter
 *     &utm_medium=social
 *     &utm_campaign=ramadan_2026
 *     &utm_content=post123
 *     &redirect=https://apps.apple.com/app/silni/id123
 *
 * - Parses query params for UTM data and redirect URL
 * - Hashes the client IP (SHA-256) for privacy-safe logging
 * - Inserts a row into social_click_log
 * - Returns a 302 redirect to the target URL
 * - If logging fails, still redirects (redirect is never blocked)
 *
 * Environment variables:
 * - SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
 */

serve(async (req) => {
  const corsHeaders = getCorsHeaders(req);

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Parse query parameters
    const url = new URL(req.url);
    const postId = url.searchParams.get("post_id");
    const utmSource = url.searchParams.get("utm_source");
    const utmMedium = url.searchParams.get("utm_medium");
    const utmCampaign = url.searchParams.get("utm_campaign");
    const utmContent = url.searchParams.get("utm_content");
    const redirect = url.searchParams.get("redirect");

    // Validate redirect parameter
    if (!redirect) {
      return new Response(
        JSON.stringify({
          error: "Missing required 'redirect' query parameter",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Log the click asynchronously - never block the redirect
    try {
      // Initialize Supabase client
      const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
      const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
      const supabase = createClient(supabaseUrl, supabaseKey);

      // Hash the IP address for privacy
      const ipAddress =
        req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ||
        req.headers.get("x-real-ip") ||
        "unknown";

      const hashedIp = await hashIp(ipAddress);

      // Insert click log
      const { error: insertError } = await supabase
        .from("social_click_log")
        .insert({
          post_id: postId || null,
          utm_source: utmSource || null,
          utm_medium: utmMedium || null,
          utm_campaign: utmCampaign || null,
          utm_content: utmContent || null,
          user_agent: req.headers.get("user-agent") || null,
          ip_hash: hashedIp,
        });

      if (insertError) {
        console.error("Failed to log click:", insertError);
      } else {
        console.log(
          `Click logged: source=${utmSource}, campaign=${utmCampaign}, post=${postId}`
        );
      }
    } catch (logError) {
      // Never block the redirect due to logging failure
      console.error("Error logging click (redirecting anyway):", logError);
    }

    // Always redirect, regardless of logging success
    return new Response(null, {
      status: 302,
      headers: {
        ...corsHeaders,
        Location: redirect,
      },
    });
  } catch (error) {
    console.error("Unexpected error:", error);

    // If we have a redirect param, still redirect even on unexpected errors
    try {
      const url = new URL(req.url);
      const redirect = url.searchParams.get("redirect");
      if (redirect) {
        return new Response(null, {
          status: 302,
          headers: {
            ...corsHeaders,
            Location: redirect,
          },
        });
      }
    } catch {
      // Fall through to error response
    }

    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

/**
 * Hash an IP address using SHA-256 for privacy-safe storage.
 * Returns a hex-encoded hash string.
 */
async function hashIp(ip: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(ip);
  const hashBuffer = await crypto.subtle.digest("SHA-256", data);
  const hashArray = new Uint8Array(hashBuffer);
  return Array.from(hashArray)
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}
