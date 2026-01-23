// DeepSeek API Proxy Edge Function
// Securely proxies requests to DeepSeek API with rate limiting

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { getCorsHeaders } from "../_shared/cors.ts";

const DEEPSEEK_API_KEY = Deno.env.get("DEEPSEEK_API_KEY");
const DEEPSEEK_URL = "https://api.deepseek.com/v1/chat/completions";
const DEEPSEEK_MODEL = "deepseek-chat";

// Rate limiting: requests per user per day
// Note: Free users don't have AI access (blocked at app level), but keeping small limit as safeguard
const RATE_LIMIT_FREE = 0;
const RATE_LIMIT_PREMIUM = 200;

interface ChatRequest {
  messages: Array<{ role: string; content: string }>;
  temperature?: number;
  max_tokens?: number;
  stream?: boolean;
  health_check?: boolean;
}

serve(async (req: Request) => {
  const corsHeaders = getCorsHeaders(req);

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Parse request body
    const body: ChatRequest = await req.json();

    // Health check endpoint
    if (body.health_check) {
      return new Response(
        JSON.stringify({
          status: "ok",
          api_configured: !!DEEPSEEK_API_KEY,
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 200,
        }
      );
    }

    // Verify API key is configured
    if (!DEEPSEEK_API_KEY) {
      return new Response(
        JSON.stringify({
          error: "DeepSeek API key not configured",
          code: "API_KEY_MISSING",
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 500,
        }
      );
    }

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
      console.log("[DEBUG] Auth failed:", authError?.message);
      return new Response(
        JSON.stringify({ error: "Invalid token", code: "INVALID_TOKEN" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 401,
        }
      );
    }

    console.log("[DEBUG] User authenticated:", user.id, user.email);

    // Create service role client for rate limit operations
    const serviceClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { autoRefreshToken: false, persistSession: false } }
    );

    // Check subscription status for rate limit tier
    // Query 'users' table for 'subscription_status' column
    // App syncs MAX tier as 'premium' to the database
    const { data: userData, error: userError } = await serviceClient
      .from("users")
      .select("subscription_status")
      .eq("id", user.id)
      .single();

    // Debug: log the query result
    console.log("[DEBUG] User query result:", {
      userData,
      userError: userError?.message,
      subscription_status: userData?.subscription_status,
    });

    // If user record not found or no status, assume they're authenticated
    // and give them base limit (app-side handles actual feature gating)
    let isPremium = false;
    if (!userError && userData?.subscription_status === "premium") {
      isPremium = true;
    }

    console.log("[DEBUG] isPremium:", isPremium);

    // Give all authenticated users at least 50 requests (free users blocked at app level)
    // Premium users get 200
    const BASE_LIMIT = 50;
    const rateLimit = isPremium ? RATE_LIMIT_PREMIUM : BASE_LIMIT;

    console.log("[DEBUG] Rate limit set to:", rateLimit);

    // Check rate limiting
    const today = new Date().toISOString().split("T")[0];
    const { data: rateData } = await serviceClient
      .from("ai_rate_limits")
      .select("request_count")
      .eq("user_id", user.id)
      .eq("date", today)
      .single();

    const currentCount = rateData?.request_count || 0;

    console.log("[DEBUG] Rate check:", {
      today,
      currentCount,
      rateLimit,
      wouldExceed: currentCount >= rateLimit,
    });

    if (currentCount >= rateLimit) {
      return new Response(
        JSON.stringify({
          error: "Daily rate limit exceeded",
          code: "RATE_LIMIT_EXCEEDED",
          limit: rateLimit,
          used: currentCount,
          resets_at: `${today}T23:59:59Z`,
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 429,
        }
      );
    }

    // Make request to DeepSeek API
    const response = await fetch(DEEPSEEK_URL, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${DEEPSEEK_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: DEEPSEEK_MODEL,
        messages: body.messages,
        temperature: body.temperature ?? 0.7,
        max_tokens: body.max_tokens ?? 2048,
        stream: false, // Non-streaming for now
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error("DeepSeek API error:", response.status, errorText);
      return new Response(
        JSON.stringify({
          error: "AI service error",
          code: "AI_ERROR",
          status: response.status,
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: response.status,
        }
      );
    }

    const data = await response.json();

    // Extract content from response
    const content = data.choices?.[0]?.message?.content ?? "";

    // Update rate limit counter (upsert to handle first request of the day)
    await serviceClient.from("ai_rate_limits").upsert(
      {
        user_id: user.id,
        date: today,
        request_count: currentCount + 1,
        updated_at: new Date().toISOString(),
      },
      { onConflict: "user_id,date" }
    );

    return new Response(
      JSON.stringify({
        content,
        usage: data.usage,
        model: data.model,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error) {
    console.error("Edge function error:", error);
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
