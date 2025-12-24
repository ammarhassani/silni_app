// DeepSeek API Proxy Edge Function
// Securely proxies requests to DeepSeek API with rate limiting

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const DEEPSEEK_API_KEY = Deno.env.get("DEEPSEEK_API_KEY");
const DEEPSEEK_URL = "https://api.deepseek.com/v1/chat/completions";
const DEEPSEEK_MODEL = "deepseek-chat";

// Rate limiting: requests per user per day
const RATE_LIMIT_FREE = 5;
const RATE_LIMIT_PREMIUM = 50;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface ChatRequest {
  messages: Array<{ role: string; content: string }>;
  temperature?: number;
  max_tokens?: number;
  stream?: boolean;
  health_check?: boolean;
}

serve(async (req: Request) => {
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
      return new Response(
        JSON.stringify({ error: "Invalid token", code: "INVALID_TOKEN" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 401,
        }
      );
    }

    // TODO: Check rate limiting
    // const { data: rateData } = await supabaseClient
    //   .from('ai_rate_limits')
    //   .select('request_count')
    //   .eq('user_id', user.id)
    //   .eq('date', new Date().toISOString().split('T')[0])
    //   .single();

    // TODO: Check subscription status for rate limit tier
    // const isPremium = await checkPremiumStatus(user.id);
    // const rateLimit = isPremium ? RATE_LIMIT_PREMIUM : RATE_LIMIT_FREE;

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

    // TODO: Update rate limit counter
    // await supabaseClient.rpc('increment_ai_usage', { user_id: user.id });

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
