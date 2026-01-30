import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function GET(request: NextRequest) {
  const appUrl = process.env.NEXT_PUBLIC_APP_URL || "http://localhost:3000";
  const accountsUrl = new URL("/social/accounts", appUrl);

  try {
    const { searchParams } = new URL(request.url);
    const code = searchParams.get("code");
    const stateParam = searchParams.get("state");
    const error = searchParams.get("error");

    // Handle Twitter OAuth errors (e.g., user denied access)
    if (error) {
      accountsUrl.searchParams.set("error", `Twitter OAuth error: ${error}`);
      return NextResponse.redirect(accountsUrl);
    }

    if (!code || !stateParam) {
      accountsUrl.searchParams.set("error", "Missing code or state from Twitter callback");
      return NextResponse.redirect(accountsUrl);
    }

    // Retrieve and verify state from cookie
    const storedState = request.cookies.get("twitter_oauth_state")?.value;
    const codeVerifier = request.cookies.get("twitter_oauth_code_verifier")?.value;

    if (!storedState || !codeVerifier) {
      accountsUrl.searchParams.set("error", "OAuth session expired. Please try again.");
      return NextResponse.redirect(accountsUrl);
    }

    if (stateParam !== storedState) {
      accountsUrl.searchParams.set("error", "OAuth state mismatch. Possible CSRF attack.");
      return NextResponse.redirect(accountsUrl);
    }

    // Exchange authorization code for tokens
    const clientId = process.env.TWITTER_CLIENT_ID;
    const clientSecret = process.env.TWITTER_CLIENT_SECRET;

    if (!clientId || !clientSecret) {
      accountsUrl.searchParams.set("error", "Twitter OAuth credentials not configured");
      return NextResponse.redirect(accountsUrl);
    }

    const redirectUri = `${appUrl}/api/social/auth/twitter/callback`;
    const basicAuth = Buffer.from(`${clientId}:${clientSecret}`).toString("base64");

    const tokenResponse = await fetch("https://api.twitter.com/2/oauth2/token", {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        Authorization: `Basic ${basicAuth}`,
      },
      body: new URLSearchParams({
        code,
        grant_type: "authorization_code",
        client_id: clientId,
        redirect_uri: redirectUri,
        code_verifier: codeVerifier,
      }).toString(),
    });

    if (!tokenResponse.ok) {
      const errorText = await tokenResponse.text();
      console.error("Twitter token exchange error:", tokenResponse.status, errorText);
      accountsUrl.searchParams.set(
        "error",
        `Failed to exchange Twitter authorization code (${tokenResponse.status})`
      );
      return NextResponse.redirect(accountsUrl);
    }

    const tokenData = await tokenResponse.json();
    const { access_token, refresh_token, expires_in } = tokenData;

    if (!access_token) {
      accountsUrl.searchParams.set("error", "No access token received from Twitter");
      return NextResponse.redirect(accountsUrl);
    }

    // Fetch user info from Twitter
    const userResponse = await fetch(
      "https://api.twitter.com/2/users/me?user.fields=name,username,profile_image_url",
      {
        headers: {
          Authorization: `Bearer ${access_token}`,
        },
      }
    );

    if (!userResponse.ok) {
      const errorText = await userResponse.text();
      console.error("Twitter user info error:", userResponse.status, errorText);
      accountsUrl.searchParams.set(
        "error",
        `Failed to fetch Twitter user info (${userResponse.status})`
      );
      return NextResponse.redirect(accountsUrl);
    }

    const userData = await userResponse.json();
    const twitterUser = userData.data;

    if (!twitterUser) {
      accountsUrl.searchParams.set("error", "No user data returned from Twitter");
      return NextResponse.redirect(accountsUrl);
    }

    // Calculate token expiration
    const tokenExpiresAt = new Date(
      Date.now() + (expires_in || 7200) * 1000
    ).toISOString();

    // Upsert into social_accounts
    const supabase = createClient();

    const { error: upsertError } = await supabase
      .from("social_accounts")
      .upsert(
        {
          platform: "twitter",
          account_name: twitterUser.name,
          account_handle: `@${twitterUser.username}`,
          access_token_encrypted: access_token,
          refresh_token_encrypted: refresh_token || null,
          token_expires_at: tokenExpiresAt,
          scopes: ["tweet.write", "tweet.read", "users.read", "offline.access"],
          platform_user_id: twitterUser.id,
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
        `Failed to save Twitter account: ${upsertError.message}`
      );
      return NextResponse.redirect(accountsUrl);
    }

    // Clear OAuth cookies and redirect to accounts page
    const response = NextResponse.redirect(accountsUrl);

    response.cookies.set("twitter_oauth_state", "", {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "lax",
      path: "/",
      maxAge: 0,
    });

    response.cookies.set("twitter_oauth_code_verifier", "", {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "lax",
      path: "/",
      maxAge: 0,
    });

    return response;
  } catch (error) {
    console.error("Twitter OAuth callback error:", error);
    accountsUrl.searchParams.set(
      "error",
      encodeURIComponent(
        error instanceof Error ? error.message : "Twitter OAuth callback failed"
      )
    );
    return NextResponse.redirect(accountsUrl);
  }
}
