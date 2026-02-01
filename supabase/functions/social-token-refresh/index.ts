// @deno-types="npm:@types/node"
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { getCorsHeaders } from "../_shared/cors.ts";

/**
 * Cron job: Proactively refresh expiring OAuth tokens for connected social accounts.
 * Fetches accounts whose tokens expire within 24 hours and refreshes them
 * using the appropriate provider API (Twitter OAuth2 or Facebook/Instagram long-lived token).
 *
 * Schedule: 0 * * * * (every hour)
 *
 * Environment variables:
 * - SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
 * - TWITTER_CLIENT_ID
 * - FACEBOOK_APP_ID, FACEBOOK_APP_SECRET
 */

interface SocialAccount {
  id: string;
  platform: string;
  access_token_encrypted: string;
  refresh_token_encrypted: string | null;
  token_expires_at: string;
}

interface RefreshResult {
  accountId: string;
  platform: string;
  success: boolean;
  error?: string;
}

serve(async (req) => {
  const corsHeaders = getCorsHeaders(req);

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    console.log("Starting social token refresh check...");

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Environment variables for OAuth providers
    const twitterClientId = Deno.env.get("TWITTER_CLIENT_ID")!;
    const facebookAppId = Deno.env.get("FACEBOOK_APP_ID")!;
    const facebookAppSecret = Deno.env.get("FACEBOOK_APP_SECRET")!;

    // Calculate 24-hour window from now
    const now = new Date();
    const twentyFourHoursFromNow = new Date(
      now.getTime() + 24 * 60 * 60 * 1000
    );

    console.log(
      `Checking for tokens expiring between now and ${twentyFourHoursFromNow.toISOString()}`
    );

    // Fetch connected accounts with tokens expiring within 24 hours
    const { data: accounts, error: fetchError } = await supabase
      .from("social_accounts")
      .select(
        "id, platform, access_token_encrypted, refresh_token_encrypted, token_expires_at"
      )
      .eq("status", "connected")
      .lte("token_expires_at", twentyFourHoursFromNow.toISOString())
      .returns<SocialAccount[]>();

    if (fetchError) {
      console.error("Error fetching social accounts:", fetchError);
      throw fetchError;
    }

    if (!accounts || accounts.length === 0) {
      console.log("No accounts with expiring tokens found");
      return new Response(
        JSON.stringify({
          success: true,
          refreshed: 0,
          expired: 0,
          message: "No tokens need refreshing",
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(`Found ${accounts.length} account(s) with expiring tokens`);

    let refreshedCount = 0;
    let expiredCount = 0;
    const results: RefreshResult[] = [];

    for (const account of accounts) {
      let result: RefreshResult;

      try {
        switch (account.platform) {
          case "twitter":
            result = await refreshTwitterToken(
              supabase,
              account,
              twitterClientId
            );
            break;
          case "instagram":
            result = await refreshInstagramToken(
              supabase,
              account,
              facebookAppId,
              facebookAppSecret
            );
            break;
          default:
            console.log(
              `Unsupported platform "${account.platform}" for account ${account.id}, skipping`
            );
            result = {
              accountId: account.id,
              platform: account.platform,
              success: false,
              error: `Unsupported platform: ${account.platform}`,
            };
            break;
        }
      } catch (error) {
        console.error(
          `Unexpected error refreshing account ${account.id}:`,
          error
        );
        result = {
          accountId: account.id,
          platform: account.platform,
          success: false,
          error: error.message,
        };
      }

      if (result.success) {
        refreshedCount++;
      } else {
        expiredCount++;
      }

      results.push(result);

      // Rate limiting: wait 200ms between API calls
      await new Promise((resolve) => setTimeout(resolve, 200));
    }

    console.log(
      `Token refresh complete: ${refreshedCount} refreshed, ${expiredCount} expired`
    );

    return new Response(
      JSON.stringify({
        success: true,
        refreshed: refreshedCount,
        expired: expiredCount,
        results,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Unexpected error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

/**
 * Refresh a Twitter OAuth2 token using the refresh_token grant.
 *
 * POST https://api.twitter.com/2/oauth2/token
 * Body (form-encoded): grant_type=refresh_token, refresh_token, client_id
 */
async function refreshTwitterToken(
  supabase: ReturnType<typeof createClient>,
  account: SocialAccount,
  clientId: string
): Promise<RefreshResult> {
  console.log(
    `Refreshing Twitter token for account ${account.id}`
  );

  if (!account.refresh_token_encrypted) {
    console.error(
      `No refresh token available for Twitter account ${account.id}`
    );
    await markAccountExpired(supabase, account.id);
    return {
      accountId: account.id,
      platform: "twitter",
      success: false,
      error: "No refresh token available",
    };
  }

  try {
    const response = await fetch("https://api.twitter.com/2/oauth2/token", {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        grant_type: "refresh_token",
        refresh_token: account.refresh_token_encrypted,
        client_id: clientId,
      }).toString(),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(
        `Twitter token refresh failed for account ${account.id}: ${response.status} ${errorText}`
      );
      await markAccountExpired(supabase, account.id);
      return {
        accountId: account.id,
        platform: "twitter",
        success: false,
        error: `Twitter API ${response.status}: ${errorText}`,
      };
    }

    const data = await response.json();
    const newExpiresAt = new Date(
      Date.now() + data.expires_in * 1000
    ).toISOString();

    const { error: updateError } = await supabase
      .from("social_accounts")
      .update({
        access_token_encrypted: data.access_token,
        refresh_token_encrypted: data.refresh_token,
        token_expires_at: newExpiresAt,
        updated_at: new Date().toISOString(),
      })
      .eq("id", account.id);

    if (updateError) {
      console.error(
        `Failed to update Twitter account ${account.id}:`,
        updateError
      );
      return {
        accountId: account.id,
        platform: "twitter",
        success: false,
        error: `Database update failed: ${updateError.message}`,
      };
    }

    console.log(
      `Twitter token refreshed for account ${account.id}, new expiry: ${newExpiresAt}`
    );
    return { accountId: account.id, platform: "twitter", success: true };
  } catch (error) {
    console.error(
      `Twitter refresh error for account ${account.id}:`,
      error
    );
    await markAccountExpired(supabase, account.id);
    return {
      accountId: account.id,
      platform: "twitter",
      success: false,
      error: error.message,
    };
  }
}

/**
 * Refresh an Instagram (Facebook) long-lived token.
 *
 * GET https://graph.facebook.com/v18.0/oauth/access_token
 *   ?grant_type=fb_exchange_token
 *   &client_id={FACEBOOK_APP_ID}
 *   &client_secret={FACEBOOK_APP_SECRET}
 *   &fb_exchange_token={current_access_token}
 *
 * Returns a new long-lived token valid for ~60 days.
 */
async function refreshInstagramToken(
  supabase: ReturnType<typeof createClient>,
  account: SocialAccount,
  appId: string,
  appSecret: string
): Promise<RefreshResult> {
  console.log(
    `Refreshing Instagram token for account ${account.id}`
  );

  try {
    const url = new URL(
      "https://graph.facebook.com/v18.0/oauth/access_token"
    );
    url.searchParams.set("grant_type", "fb_exchange_token");
    url.searchParams.set("client_id", appId);
    url.searchParams.set("client_secret", appSecret);
    url.searchParams.set("fb_exchange_token", account.access_token_encrypted);

    const response = await fetch(url.toString());

    if (!response.ok) {
      const errorText = await response.text();
      console.error(
        `Instagram token refresh failed for account ${account.id}: ${response.status} ${errorText}`
      );
      await markAccountExpired(supabase, account.id);
      return {
        accountId: account.id,
        platform: "instagram",
        success: false,
        error: `Facebook API ${response.status}: ${errorText}`,
      };
    }

    const data = await response.json();
    const newExpiresAt = new Date(
      Date.now() + data.expires_in * 1000
    ).toISOString();

    const { error: updateError } = await supabase
      .from("social_accounts")
      .update({
        access_token_encrypted: data.access_token,
        token_expires_at: newExpiresAt,
        updated_at: new Date().toISOString(),
      })
      .eq("id", account.id);

    if (updateError) {
      console.error(
        `Failed to update Instagram account ${account.id}:`,
        updateError
      );
      return {
        accountId: account.id,
        platform: "instagram",
        success: false,
        error: `Database update failed: ${updateError.message}`,
      };
    }

    console.log(
      `Instagram token refreshed for account ${account.id}, new expiry: ${newExpiresAt}`
    );
    return { accountId: account.id, platform: "instagram", success: true };
  } catch (error) {
    console.error(
      `Instagram refresh error for account ${account.id}:`,
      error
    );
    await markAccountExpired(supabase, account.id);
    return {
      accountId: account.id,
      platform: "instagram",
      success: false,
      error: error.message,
    };
  }
}

/**
 * Mark a social account as expired when token refresh fails.
 */
async function markAccountExpired(
  supabase: ReturnType<typeof createClient>,
  accountId: string
): Promise<void> {
  const { error } = await supabase
    .from("social_accounts")
    .update({
      status: "expired",
      updated_at: new Date().toISOString(),
    })
    .eq("id", accountId);

  if (error) {
    console.error(
      `Failed to mark account ${accountId} as expired:`,
      error
    );
  } else {
    console.log(`Account ${accountId} marked as expired`);
  }
}
