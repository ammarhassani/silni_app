// DeepSeek API Proxy Edge Function
// Securely proxies requests to DeepSeek API with rate limiting
// Supports both streaming (SSE) and non-streaming (JSON) responses

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

    // Run subscription check and rate limit check in PARALLEL
    const today = new Date().toISOString().split("T")[0];
    const [userResult, rateResult] = await Promise.all([
      serviceClient
        .from("users")
        .select("subscription_status")
        .eq("id", user.id)
        .single(),
      serviceClient
        .from("ai_rate_limits")
        .select("request_count")
        .eq("user_id", user.id)
        .eq("date", today)
        .single(),
    ]);

    const { data: userData, error: userError } = userResult;
    const { data: rateData } = rateResult;

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

    // Free users: 0 requests (blocked at server level), Premium users: 200
    const rateLimit = isPremium ? RATE_LIMIT_PREMIUM : RATE_LIMIT_FREE;
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

    // Increment rate limit counter BEFORE the API call (prevents races during streaming)
    await serviceClient.from("ai_rate_limits").upsert(
      {
        user_id: user.id,
        date: today,
        request_count: currentCount + 1,
        updated_at: new Date().toISOString(),
      },
      { onConflict: "user_id,date" }
    );

    const wantStream = body.stream === true;

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
        stream: wantStream,
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

    // --- STREAMING PATH ---
    if (wantStream) {
      // Pipe DeepSeek's SSE stream through to the client
      const encoder = new TextEncoder();
      const decoder = new TextDecoder();

      const readable = new ReadableStream({
        async start(controller) {
          const reader = response.body!.getReader();
          let buffer = "";

          try {
            while (true) {
              const { done, value } = await reader.read();
              if (done) break;

              buffer += decoder.decode(value, { stream: true });

              // Process complete SSE lines
              const lines = buffer.split("\n");
              // Keep the last (possibly incomplete) line in the buffer
              buffer = lines.pop() || "";

              for (const line of lines) {
                const trimmed = line.trim();
                if (!trimmed || trimmed.startsWith(":")) continue;

                if (trimmed.startsWith("data: ")) {
                  const data = trimmed.slice(6);

                  if (data === "[DONE]") {
                    controller.enqueue(encoder.encode("data: [DONE]\n\n"));
                    controller.close();
                    return;
                  }

                  try {
                    const parsed = JSON.parse(data);
                    const content = parsed.choices?.[0]?.delta?.content;
                    if (content) {
                      // Forward just the content text as a simple SSE event
                      controller.enqueue(
                        encoder.encode(`data: ${JSON.stringify({ content })}\n\n`)
                      );
                    }
                  } catch {
                    // Skip malformed JSON chunks
                  }
                }
              }
            }

            // Flush any remaining buffer
            if (buffer.trim()) {
              const trimmed = buffer.trim();
              if (trimmed.startsWith("data: ") && trimmed.slice(6) === "[DONE]") {
                controller.enqueue(encoder.encode("data: [DONE]\n\n"));
              }
            }

            controller.close();
          } catch (err) {
            console.error("Stream processing error:", err);
            controller.enqueue(
              encoder.encode(
                `data: ${JSON.stringify({ error: "Stream interrupted" })}\n\n`
              )
            );
            controller.close();
          }
        },
      });

      return new Response(readable, {
        headers: {
          ...corsHeaders,
          "Content-Type": "text/event-stream",
          "Cache-Control": "no-cache",
          Connection: "keep-alive",
        },
        status: 200,
      });
    }

    // --- NON-STREAMING PATH (unchanged for non-chat features) ---
    const data = await response.json();

    // Extract content from response
    const content = data.choices?.[0]?.message?.content ?? "";

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
