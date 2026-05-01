// Sync Subscription Edge Function
// Securely updates user subscription status using service_role
// Called by the Flutter client after RevenueCat purchase verification

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { getCorsHeaders } from "../_shared/cors.ts";

// Tier values match the app's SubscriptionTier enum. 'premium' was the
// legacy name that drifted away from the rest of the stack; standardized
// on 'max' on 2026-05-01.
const VALID_STATUSES = ["free", "max"];

serve(async (req: Request) => {
  const corsHeaders = getCorsHeaders(req);

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Get user from authorization header
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Unauthorized", code: "UNAUTHORIZED" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 401,
        }
      );
    }

    // Create Supabase client for auth verification
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: { headers: { Authorization: authHeader } },
      }
    );

    // Verify user
    const {
      data: { user },
      error: authError,
    } = await supabaseClient.auth.getUser();

    if (authError || !user) {
      console.log("[sync-subscription] Auth failed:", authError?.message);
      return new Response(
        JSON.stringify({ error: "Invalid token", code: "INVALID_TOKEN" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 401,
        }
      );
    }

    // Parse request body
    const body = await req.json();
    const { status, product_id, expires_at, trial_active } = body;

    // Validate status
    if (!status || !VALID_STATUSES.includes(status)) {
      return new Response(
        JSON.stringify({
          error: `Invalid status. Must be one of: ${VALID_STATUSES.join(", ")}`,
          code: "INVALID_STATUS",
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 400,
        }
      );
    }

    console.log("[sync-subscription] Syncing for user:", user.id, {
      status,
      product_id,
      expires_at,
      trial_active,
    });

    // Create service role client to bypass the trigger guard
    const serviceClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { autoRefreshToken: false, persistSession: false } }
    );

    // Build update payload
    // When trial_active is false, do NOT include trial_started_at or trial_used
    // to prevent erasing trial history
    const updatePayload: Record<string, unknown> = {
      subscription_status: status,
      subscription_product_id: product_id ?? null,
      subscription_expires_at: expires_at ?? null,
    };

    if (trial_active) {
      updatePayload.trial_started_at = new Date().toISOString();
      updatePayload.trial_used = false;
    }

    // Update user subscription using service_role (bypasses trigger)
    const { error: updateError } = await serviceClient
      .from("users")
      .update(updatePayload)
      .eq("id", user.id);

    if (updateError) {
      console.error(
        "[sync-subscription] Update failed:",
        updateError.message
      );
      return new Response(
        JSON.stringify({
          error: "Failed to update subscription",
          code: "UPDATE_FAILED",
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 500,
        }
      );
    }

    console.log("[sync-subscription] Successfully synced for user:", user.id);

    return new Response(
      JSON.stringify({ success: true }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error) {
    console.error("[sync-subscription] Edge function error:", error);
    return new Response(
      JSON.stringify({
        error: "Internal server error",
        code: "INTERNAL_ERROR",
        message: error instanceof Error ? error.message : "Unknown error",
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 500,
      }
    );
  }
});
