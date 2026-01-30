// @deno-types="npm:@types/node"
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { getCorsHeaders } from "../_shared/cors.ts";

/**
 * Cron job: Collect social media analytics for published posts
 * Fetches engagement metrics from Twitter and Instagram APIs for
 * all posts published within the last 30 days.
 *
 * Schedule: 0 3 * * * (daily at 3 AM)
 */

// ---------- Type Definitions ----------

interface SocialPost {
  id: string;
  platform: "twitter" | "instagram";
  platform_post_id: string;
  account_id: string;
}

interface SocialAccount {
  id: string;
  platform: "twitter" | "instagram";
  access_token_encrypted: string;
  status: string;
}

interface EngagementMetrics {
  likes: number;
  comments: number;
  shares: number;
  impressions: number;
}

interface CollectionError {
  postId: string;
  platform: string;
  error: string;
}

// ---------- Platform API Fetchers ----------

async function fetchTwitterMetrics(
  platformPostId: string,
  accessToken: string
): Promise<EngagementMetrics> {
  const url = `https://api.twitter.com/2/tweets/${platformPostId}?tweet.fields=public_metrics`;

  const response = await fetch(url, {
    headers: {
      Authorization: `Bearer ${accessToken}`,
    },
  });

  if (response.status === 401) {
    throw new TokenExpiredError("Twitter access token expired");
  }

  if (!response.ok) {
    const body = await response.text();
    throw new Error(
      `Twitter API error ${response.status}: ${body}`
    );
  }

  const json = await response.json();
  const metrics = json?.data?.public_metrics;

  if (!metrics) {
    throw new Error(
      `Twitter API returned no public_metrics for tweet ${platformPostId}`
    );
  }

  return {
    likes: metrics.like_count ?? 0,
    comments: metrics.reply_count ?? 0,
    shares: metrics.retweet_count ?? 0,
    impressions: metrics.impression_count ?? 0,
  };
}

async function fetchInstagramMetrics(
  platformPostId: string,
  accessToken: string
): Promise<EngagementMetrics> {
  // Step 1: Fetch basic metrics (likes, comments)
  const basicUrl = `https://graph.facebook.com/v18.0/${platformPostId}?fields=like_count,comments_count&access_token=${accessToken}`;

  const basicResponse = await fetch(basicUrl);

  if (basicResponse.status === 401) {
    throw new TokenExpiredError("Instagram access token expired");
  }

  if (!basicResponse.ok) {
    const body = await basicResponse.text();
    throw new Error(
      `Instagram API error ${basicResponse.status}: ${body}`
    );
  }

  const basicJson = await basicResponse.json();

  // Step 2: Fetch insights (impressions, reach)
  let impressions = 0;
  try {
    const insightsUrl = `https://graph.facebook.com/v18.0/${platformPostId}/insights?metric=impressions,reach&access_token=${accessToken}`;
    const insightsResponse = await fetch(insightsUrl);

    if (insightsResponse.ok) {
      const insightsJson = await insightsResponse.json();
      const insightsData = insightsJson?.data;

      if (Array.isArray(insightsData)) {
        for (const insight of insightsData) {
          if (insight.name === "impressions" && Array.isArray(insight.values) && insight.values.length > 0) {
            impressions = insight.values[0].value ?? 0;
            break;
          }
        }
      }
    } else {
      // Insights may not be available for all post types; log and continue
      console.warn(
        `Instagram insights unavailable for post ${platformPostId}: ${insightsResponse.status}`
      );
    }
  } catch (insightsError) {
    console.warn(
      `Failed to fetch Instagram insights for post ${platformPostId}:`,
      insightsError
    );
  }

  return {
    likes: basicJson.like_count ?? 0,
    comments: basicJson.comments_count ?? 0,
    shares: 0, // Not available via basic Instagram API
    impressions,
  };
}

// ---------- Custom Error ----------

class TokenExpiredError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "TokenExpiredError";
  }
}

// ---------- Main Handler ----------

serve(async (req) => {
  const corsHeaders = getCorsHeaders(req);

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    console.log("Starting social analytics collection...");

    // Initialize Supabase client with service role
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Calculate 30-day cutoff
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const cutoffDate = thirtyDaysAgo.toISOString();

    console.log(`Fetching published posts since ${cutoffDate}`);

    // Step 1: Fetch all eligible published posts
    const { data: posts, error: postsError } = await supabase
      .from("social_posts")
      .select("id, platform, platform_post_id, account_id")
      .eq("status", "published")
      .not("platform_post_id", "is", null)
      .gte("published_at", cutoffDate);

    if (postsError) {
      console.error("Error fetching posts:", postsError);
      throw postsError;
    }

    if (!posts || posts.length === 0) {
      console.log("No eligible published posts found");
      return new Response(
        JSON.stringify({ collected: 0, errors: 0, message: "No eligible posts" }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(`Found ${posts.length} published post(s) to collect metrics for`);

    // Step 2: Group posts by account_id and fetch accounts
    const accountIds = [...new Set(posts.map((p: SocialPost) => p.account_id))];

    const { data: accounts, error: accountsError } = await supabase
      .from("social_accounts")
      .select("id, platform, access_token_encrypted, status")
      .in("id", accountIds);

    if (accountsError) {
      console.error("Error fetching accounts:", accountsError);
      throw accountsError;
    }

    // Build a lookup map of account_id -> account
    const accountMap = new Map<string, SocialAccount>();
    if (accounts) {
      for (const account of accounts) {
        accountMap.set(account.id, account as SocialAccount);
      }
    }

    // Track expired accounts to skip subsequent posts from the same account
    const expiredAccountIds = new Set<string>();

    let collectedCount = 0;
    let errorCount = 0;
    const errors: CollectionError[] = [];

    // Step 3: Fetch metrics for each post
    for (const post of posts as SocialPost[]) {
      const postId = post.id;
      const platform = post.platform;
      const platformPostId = post.platform_post_id;
      const accountId = post.account_id;

      // Skip posts from accounts already marked as expired during this run
      if (expiredAccountIds.has(accountId)) {
        console.log(
          `Skipping post ${postId} - account ${accountId} has expired token`
        );
        errorCount++;
        errors.push({
          postId,
          platform,
          error: "Account token expired (skipped)",
        });
        continue;
      }

      const account = accountMap.get(accountId);

      if (!account) {
        console.warn(`Account ${accountId} not found for post ${postId}, skipping`);
        errorCount++;
        errors.push({ postId, platform, error: "Account not found" });
        continue;
      }

      // Skip already-expired accounts
      if (account.status === "expired") {
        console.log(
          `Skipping post ${postId} - account ${accountId} status is expired`
        );
        expiredAccountIds.add(accountId);
        errorCount++;
        errors.push({
          postId,
          platform,
          error: "Account already expired",
        });
        continue;
      }

      // Skip disconnected accounts
      if (account.status === "disconnected") {
        console.log(
          `Skipping post ${postId} - account ${accountId} is disconnected`
        );
        errorCount++;
        errors.push({
          postId,
          platform,
          error: "Account disconnected",
        });
        continue;
      }

      const accessToken = account.access_token_encrypted;

      try {
        let metrics: EngagementMetrics;

        if (platform === "twitter") {
          metrics = await fetchTwitterMetrics(platformPostId, accessToken);
        } else if (platform === "instagram") {
          metrics = await fetchInstagramMetrics(platformPostId, accessToken);
        } else {
          console.warn(`Unknown platform "${platform}" for post ${postId}, skipping`);
          errorCount++;
          errors.push({ postId, platform, error: `Unknown platform: ${platform}` });
          continue;
        }

        // Step 4: Fetch link_clicks from social_click_log
        const { count: linkClicks, error: clickError } = await supabase
          .from("social_click_log")
          .select("*", { count: "exact", head: true })
          .eq("post_id", postId);

        if (clickError) {
          console.warn(
            `Error fetching click count for post ${postId}:`,
            clickError
          );
        }

        // Step 5: Insert analytics snapshot
        const analyticsRecord = {
          post_id: postId,
          likes: metrics.likes,
          comments: metrics.comments,
          shares: metrics.shares,
          impressions: metrics.impressions,
          link_clicks: linkClicks ?? 0,
          snapshot_at: new Date().toISOString(),
        };

        const { error: insertError } = await supabase
          .from("social_analytics")
          .insert(analyticsRecord);

        if (insertError) {
          console.error(
            `Error inserting analytics for post ${postId}:`,
            insertError
          );
          errorCount++;
          errors.push({
            postId,
            platform,
            error: `Insert failed: ${insertError.message}`,
          });
          continue;
        }

        collectedCount++;
        console.log(
          `Collected metrics for ${platform} post ${postId}: ` +
            `likes=${metrics.likes}, comments=${metrics.comments}, ` +
            `shares=${metrics.shares}, impressions=${metrics.impressions}, ` +
            `clicks=${linkClicks ?? 0}`
        );
      } catch (error) {
        if (error instanceof TokenExpiredError) {
          // Mark account as expired in the database
          console.warn(
            `Token expired for account ${accountId} (${platform}), marking as expired`
          );

          const { error: updateError } = await supabase
            .from("social_accounts")
            .update({ status: "expired" })
            .eq("id", accountId);

          if (updateError) {
            console.error(
              `Failed to update account ${accountId} status:`,
              updateError
            );
          }

          // Add to expired set so we skip remaining posts from this account
          expiredAccountIds.add(accountId);

          errorCount++;
          errors.push({
            postId,
            platform,
            error: "Token expired - account marked as expired",
          });
        } else {
          console.error(
            `Error fetching metrics for ${platform} post ${postId}:`,
            error
          );
          errorCount++;
          errors.push({
            postId,
            platform,
            error: error instanceof Error ? error.message : String(error),
          });
        }
      }

      // Rate limiting: small delay between API calls to avoid hitting rate limits
      await new Promise((resolve) => setTimeout(resolve, 200));
    }

    console.log(
      `Analytics collection complete: collected=${collectedCount}, errors=${errorCount}`
    );

    if (errors.length > 0) {
      console.log("Error details:", JSON.stringify(errors, null, 2));
    }

    return new Response(
      JSON.stringify({
        collected: collectedCount,
        errors: errorCount,
        total_posts: posts.length,
        expired_accounts: [...expiredAccountIds],
        error_details: errors,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Unexpected error:", error);
    return new Response(
      JSON.stringify({
        collected: 0,
        errors: 1,
        error: error instanceof Error ? error.message : String(error),
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
