// @deno-types="npm:@types/node"
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { getCorsHeaders } from "../_shared/cors.ts";

/**
 * Cron job: Publish scheduled social media posts
 * Fetches posts with status='scheduled' and scheduled_at <= now,
 * publishes them to Twitter or Instagram, and updates their status.
 *
 * Schedule: every 5 minutes
 */

interface SocialPost {
  id: string;
  account_id: string;
  text_ar: string;
  hashtags: string[] | null;
  utm_link: string | null;
  image_url: string | null;
  scheduled_at: string;
  platform: string;
  status: string;
  social_accounts: {
    id: string;
    platform: string;
    is_connected: boolean;
    access_token_encrypted: string;
    platform_account_id: string | null;
  };
}

interface PublishResult {
  success: boolean;
  platform_post_id?: string;
  platform_post_url?: string;
  error_message?: string;
}

/**
 * Compose the final post text from its parts.
 */
function composePostText(post: SocialPost): string {
  const parts: string[] = [post.text_ar];
  if (post.hashtags?.length) parts.push(post.hashtags.join(" "));
  if (post.utm_link) parts.push(post.utm_link);
  return parts.join("\n\n").trim();
}

/**
 * Publish a post to Twitter (X) using the v2 API.
 */
async function publishToTwitter(
  text: string,
  accessToken: string,
): Promise<PublishResult> {
  try {
    const response = await fetch("https://api.twitter.com/2/tweets", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ text }),
    });

    if (!response.ok) {
      const errorBody = await response.text();
      console.error(`Twitter API error (${response.status}):`, errorBody);
      return {
        success: false,
        error_message: `Twitter API error ${response.status}: ${errorBody}`,
      };
    }

    const data = await response.json();
    const tweetId = data?.data?.id;

    return {
      success: true,
      platform_post_id: tweetId,
      platform_post_url: tweetId
        ? `https://twitter.com/i/web/status/${tweetId}`
        : undefined,
    };
  } catch (error) {
    console.error("Twitter publish error:", error);
    return {
      success: false,
      error_message: `Twitter publish failed: ${error.message}`,
    };
  }
}

/**
 * Publish a post to Instagram using the Graph API (two-step process).
 * Step 1: Create a media container.
 * Step 2: Publish the container.
 */
async function publishToInstagram(
  caption: string,
  accessToken: string,
  igAccountId: string,
  imageUrl?: string | null,
): Promise<PublishResult> {
  try {
    // Step 1: Create media container
    const containerParams: Record<string, string> = {
      caption,
      access_token: accessToken,
    };

    if (imageUrl) {
      containerParams.image_url = imageUrl;
    }

    const containerResponse = await fetch(
      `https://graph.facebook.com/v18.0/${igAccountId}/media`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(containerParams),
      },
    );

    if (!containerResponse.ok) {
      const errorBody = await containerResponse.text();
      console.error(
        `Instagram container creation error (${containerResponse.status}):`,
        errorBody,
      );
      return {
        success: false,
        error_message: `Instagram container error ${containerResponse.status}: ${errorBody}`,
      };
    }

    const containerData = await containerResponse.json();
    const creationId = containerData?.id;

    if (!creationId) {
      return {
        success: false,
        error_message: "Instagram container creation returned no ID",
      };
    }

    // Step 2: Publish the container
    const publishResponse = await fetch(
      `https://graph.facebook.com/v18.0/${igAccountId}/media_publish`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          creation_id: creationId,
          access_token: accessToken,
        }),
      },
    );

    if (!publishResponse.ok) {
      const errorBody = await publishResponse.text();
      console.error(
        `Instagram publish error (${publishResponse.status}):`,
        errorBody,
      );
      return {
        success: false,
        error_message: `Instagram publish error ${publishResponse.status}: ${errorBody}`,
      };
    }

    const publishData = await publishResponse.json();
    const mediaId = publishData?.id;

    return {
      success: true,
      platform_post_id: mediaId,
      platform_post_url: mediaId
        ? `https://www.instagram.com/p/${mediaId}/`
        : undefined,
    };
  } catch (error) {
    console.error("Instagram publish error:", error);
    return {
      success: false,
      error_message: `Instagram publish failed: ${error.message}`,
    };
  }
}

serve(async (req) => {
  const corsHeaders = getCorsHeaders(req);

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    console.log("📤 Starting social publisher check...");

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey =
      Deno.env.get("SERVICE_ROLE_JWT") ??
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const supabase = createClient(supabaseUrl, supabaseKey, {
      auth: { persistSession: false },
    });

    const now = new Date().toISOString();

    // Fetch posts ready to publish: status='scheduled' AND scheduled_at <= now
    // Join with social_accounts via account_id
    // Order by scheduled_at ascending, limit to 10 per run
    const { data: posts, error: postsError } = await supabase
      .from("social_posts")
      .select(
        `
        id,
        account_id,
        text_ar,
        hashtags,
        utm_link,
        image_url,
        scheduled_at,
        platform,
        status,
        social_accounts!account_id (
          id,
          platform,
          is_connected,
          access_token_encrypted,
          platform_account_id
        )
      `,
      )
      .eq("status", "scheduled")
      .lte("scheduled_at", now)
      .order("scheduled_at", { ascending: true })
      .limit(10);

    if (postsError) {
      console.error("Error fetching scheduled posts:", postsError);
      throw postsError;
    }

    if (!posts || posts.length === 0) {
      console.log("No scheduled posts to publish");
      return new Response(
        JSON.stringify({
          published: 0,
          failed: 0,
          total: 0,
          message: "No scheduled posts to publish",
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    console.log(`Found ${posts.length} post(s) to publish`);

    let publishedCount = 0;
    let failedCount = 0;

    for (const rawPost of posts) {
      const post = rawPost as unknown as SocialPost;
      const account = post.social_accounts;

      console.log(
        `\nProcessing post ${post.id} for platform: ${post.platform}`,
      );

      // Check if account is connected
      if (!account || !account.is_connected) {
        console.error(
          `Post ${post.id}: No connected account found for account_id ${post.account_id}`,
        );

        await supabase
          .from("social_posts")
          .update({
            status: "failed",
            error_message: "No connected account",
          })
          .eq("id", post.id);

        failedCount++;
        continue;
      }

      // Get access token
      const accessToken = account.access_token_encrypted;
      if (!accessToken) {
        console.error(
          `Post ${post.id}: No access token for account ${account.id}`,
        );

        await supabase
          .from("social_posts")
          .update({
            status: "failed",
            error_message: "No access token available",
          })
          .eq("id", post.id);

        failedCount++;
        continue;
      }

      // Compose the post text
      const composedText = composePostText(post);
      console.log(
        `Post ${post.id}: Composed text (${composedText.length} chars)`,
      );

      let result: PublishResult;

      // Publish based on platform
      if (post.platform === "twitter") {
        result = await publishToTwitter(composedText, accessToken);
      } else if (post.platform === "instagram") {
        const igAccountId = account.platform_account_id;
        if (!igAccountId) {
          result = {
            success: false,
            error_message:
              "No Instagram account ID (platform_account_id) configured",
          };
        } else {
          result = await publishToInstagram(
            composedText,
            accessToken,
            igAccountId,
            post.image_url,
          );
        }
      } else {
        result = {
          success: false,
          error_message: `Unsupported platform: ${post.platform}`,
        };
      }

      // Update post status based on result
      if (result.success) {
        console.log(
          `Post ${post.id}: Published successfully (platform_post_id: ${result.platform_post_id})`,
        );

        await supabase
          .from("social_posts")
          .update({
            status: "published",
            published_at: new Date().toISOString(),
            platform_post_id: result.platform_post_id || null,
            platform_post_url: result.platform_post_url || null,
          })
          .eq("id", post.id);

        // Update social_accounts.last_post_at
        await supabase
          .from("social_accounts")
          .update({
            last_post_at: new Date().toISOString(),
          })
          .eq("id", account.id);

        publishedCount++;
      } else {
        console.error(
          `Post ${post.id}: Failed - ${result.error_message}`,
        );

        await supabase
          .from("social_posts")
          .update({
            status: "failed",
            error_message: result.error_message || "Unknown error",
          })
          .eq("id", post.id);

        failedCount++;
      }

      // Rate limiting: wait 200ms between API calls to avoid hitting rate limits
      await new Promise((resolve) => setTimeout(resolve, 200));
    }

    const total = publishedCount + failedCount;
    console.log(
      `\nSocial publisher complete: ${publishedCount} published, ${failedCount} failed, ${total} total`,
    );

    return new Response(
      JSON.stringify({
        published: publishedCount,
        failed: failedCount,
        total,
        message: `Published ${publishedCount}, failed ${failedCount} of ${total} posts`,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    console.error("Unexpected error:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
