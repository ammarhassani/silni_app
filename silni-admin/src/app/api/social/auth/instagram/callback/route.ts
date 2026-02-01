import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  const appUrl = process.env.NEXT_PUBLIC_APP_URL || "http://localhost:3000";
  const accountsUrl = new URL("/social/accounts", appUrl);

  try {
    const { searchParams } = new URL(request.url);
    const code = searchParams.get("code");
    const stateParam = searchParams.get("state");
    const error = searchParams.get("error");

    // Handle Facebook OAuth errors (e.g., user denied access)
    if (error) {
      const errorDescription = searchParams.get("error_description") || error;
      accountsUrl.searchParams.set("error", `Instagram OAuth error: ${errorDescription}`);
      return NextResponse.redirect(accountsUrl);
    }

    if (!code || !stateParam) {
      accountsUrl.searchParams.set("error", "Missing code or state from Instagram callback");
      return NextResponse.redirect(accountsUrl);
    }

    // Retrieve and verify state from cookie
    const storedState = request.cookies.get("instagram_oauth_state")?.value;

    if (!storedState) {
      accountsUrl.searchParams.set("error", "OAuth session expired. Please try again.");
      return NextResponse.redirect(accountsUrl);
    }

    if (stateParam !== storedState) {
      accountsUrl.searchParams.set("error", "OAuth state mismatch. Possible CSRF attack.");
      return NextResponse.redirect(accountsUrl);
    }

    const facebookAppId = process.env.FACEBOOK_APP_ID;
    const facebookAppSecret = process.env.FACEBOOK_APP_SECRET;

    if (!facebookAppId || !facebookAppSecret) {
      accountsUrl.searchParams.set("error", "Facebook OAuth credentials not configured");
      return NextResponse.redirect(accountsUrl);
    }

    const redirectUri = `${appUrl}/api/social/auth/instagram/callback`;

    // Step 1: Exchange code for short-lived token
    const shortLivedParams = new URLSearchParams({
      client_id: facebookAppId,
      client_secret: facebookAppSecret,
      redirect_uri: redirectUri,
      code,
    });

    const shortLivedResponse = await fetch(
      `https://graph.facebook.com/v18.0/oauth/access_token?${shortLivedParams.toString()}`
    );

    if (!shortLivedResponse.ok) {
      const errorText = await shortLivedResponse.text();
      console.error("Facebook short-lived token error:", shortLivedResponse.status, errorText);
      accountsUrl.searchParams.set(
        "error",
        `Failed to exchange authorization code (${shortLivedResponse.status})`
      );
      return NextResponse.redirect(accountsUrl);
    }

    const shortLivedData = await shortLivedResponse.json();
    const shortLivedToken = shortLivedData.access_token;

    if (!shortLivedToken) {
      accountsUrl.searchParams.set("error", "No access token received from Facebook");
      return NextResponse.redirect(accountsUrl);
    }

    // Step 2: Exchange short-lived token for long-lived token
    const longLivedParams = new URLSearchParams({
      grant_type: "fb_exchange_token",
      client_id: facebookAppId,
      client_secret: facebookAppSecret,
      fb_exchange_token: shortLivedToken,
    });

    const longLivedResponse = await fetch(
      `https://graph.facebook.com/v18.0/oauth/access_token?${longLivedParams.toString()}`
    );

    if (!longLivedResponse.ok) {
      const errorText = await longLivedResponse.text();
      console.error("Facebook long-lived token error:", longLivedResponse.status, errorText);
      accountsUrl.searchParams.set(
        "error",
        `Failed to exchange for long-lived token (${longLivedResponse.status})`
      );
      return NextResponse.redirect(accountsUrl);
    }

    const longLivedData = await longLivedResponse.json();
    const longLivedToken = longLivedData.access_token;

    if (!longLivedToken) {
      accountsUrl.searchParams.set("error", "No long-lived token received from Facebook");
      return NextResponse.redirect(accountsUrl);
    }

    // Step 3: Fetch user's Facebook Pages
    const pagesResponse = await fetch(
      `https://graph.facebook.com/v18.0/me/accounts?access_token=${longLivedToken}`
    );

    if (!pagesResponse.ok) {
      const errorText = await pagesResponse.text();
      console.error("Facebook pages error:", pagesResponse.status, errorText);
      accountsUrl.searchParams.set(
        "error",
        `Failed to fetch Facebook pages (${pagesResponse.status})`
      );
      return NextResponse.redirect(accountsUrl);
    }

    const pagesData = await pagesResponse.json();
    const pages = pagesData.data;

    if (!pages || pages.length === 0) {
      accountsUrl.searchParams.set(
        "error",
        "No Facebook Pages found. You need a Facebook Page linked to an Instagram Business account."
      );
      return NextResponse.redirect(accountsUrl);
    }

    // Step 4: Get Instagram Business Account from the first page
    const firstPage = pages[0];
    const igAccountResponse = await fetch(
      `https://graph.facebook.com/v18.0/${firstPage.id}?fields=instagram_business_account&access_token=${longLivedToken}`
    );

    if (!igAccountResponse.ok) {
      const errorText = await igAccountResponse.text();
      console.error("Instagram business account error:", igAccountResponse.status, errorText);
      accountsUrl.searchParams.set(
        "error",
        `Failed to fetch Instagram business account (${igAccountResponse.status})`
      );
      return NextResponse.redirect(accountsUrl);
    }

    const igAccountData = await igAccountResponse.json();
    const igBusinessAccountId = igAccountData.instagram_business_account?.id;

    if (!igBusinessAccountId) {
      accountsUrl.searchParams.set(
        "error",
        "No Instagram Business account linked to this Facebook Page. Please link your Instagram Business account first."
      );
      return NextResponse.redirect(accountsUrl);
    }

    // Step 5: Fetch Instagram profile info
    const igProfileResponse = await fetch(
      `https://graph.facebook.com/v18.0/${igBusinessAccountId}?fields=name,username&access_token=${longLivedToken}`
    );

    if (!igProfileResponse.ok) {
      const errorText = await igProfileResponse.text();
      console.error("Instagram profile error:", igProfileResponse.status, errorText);
      accountsUrl.searchParams.set(
        "error",
        `Failed to fetch Instagram profile (${igProfileResponse.status})`
      );
      return NextResponse.redirect(accountsUrl);
    }

    const igProfileData = await igProfileResponse.json();

    // Calculate token expiration (60 days for long-lived tokens)
    const tokenExpiresAt = new Date(
      Date.now() + 60 * 24 * 60 * 60 * 1000
    ).toISOString();

    // Upsert into social_accounts
    const supabase = createClient();

    const { error: upsertError } = await supabase
      .from("social_accounts")
      .upsert(
        {
          platform: "instagram",
          account_name: igProfileData.name || igProfileData.username,
          account_handle: `@${igProfileData.username}`,
          access_token_encrypted: longLivedToken,
          refresh_token_encrypted: null,
          token_expires_at: tokenExpiresAt,
          scopes: [
            "instagram_basic",
            "instagram_content_publish",
            "pages_read_engagement",
          ],
          platform_user_id: igBusinessAccountId,
          status: "connected",
        },
        {
          onConflict: "platform,platform_user_id",
        }
      );

    if (upsertError) {
      console.error("Supabase upsert error:", upsertError);
      accountsUrl.searchParams.set(
        "error",
        `Failed to save Instagram account: ${upsertError.message}`
      );
      return NextResponse.redirect(accountsUrl);
    }

    // Clear OAuth cookie and redirect to accounts page
    const response = NextResponse.redirect(accountsUrl);

    response.cookies.set("instagram_oauth_state", "", {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "lax",
      path: "/",
      maxAge: 0,
    });

    return response;
  } catch (error) {
    console.error("Instagram OAuth callback error:", error);
    accountsUrl.searchParams.set(
      "error",
      encodeURIComponent(
        error instanceof Error ? error.message : "Instagram OAuth callback failed"
      )
    );
    return NextResponse.redirect(accountsUrl);
  }
}
