import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

async function verifyAdminAuth(): Promise<{ authorized: boolean; error?: string }> {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    return { authorized: false, error: "Unauthorized - authentication required" };
  }

  const { data: profile } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", user.id)
    .single();

  if (profile?.role !== "admin") {
    return { authorized: false, error: "Forbidden - admin access required" };
  }

  return { authorized: true };
}

function generateRandomString(length: number): string {
  const array = new Uint8Array(length);
  crypto.getRandomValues(array);
  return Array.from(array, (byte) => byte.toString(36).padStart(2, "0"))
    .join("")
    .slice(0, length);
}

async function generatePKCEChallenge(verifier: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(verifier);
  const digest = await crypto.subtle.digest("SHA-256", data);
  const base64 = btoa(String.fromCharCode.apply(null, Array.from(new Uint8Array(digest))));
  // Base64url encode: replace +, /, and remove =
  return base64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

export async function GET(_request: NextRequest) {
  const authResult = await verifyAdminAuth();
  if (!authResult.authorized) {
    const errorMessage = encodeURIComponent(authResult.error || "Authentication failed");
    return NextResponse.redirect(
      new URL(`/social/accounts?error=${errorMessage}`, process.env.NEXT_PUBLIC_APP_URL)
    );
  }

  try {
    const clientId = process.env.TWITTER_CLIENT_ID;
    if (!clientId) {
      return NextResponse.redirect(
        new URL(
          `/social/accounts?error=${encodeURIComponent("Twitter client ID not configured")}`,
          process.env.NEXT_PUBLIC_APP_URL
        )
      );
    }

    const codeVerifier = generateRandomString(64);
    const codeChallenge = await generatePKCEChallenge(codeVerifier);
    const state = generateRandomString(32);

    const redirectUri = `${process.env.NEXT_PUBLIC_APP_URL}/api/social/auth/twitter/callback`;
    const scopes = ["tweet.write", "tweet.read", "users.read", "offline.access"];

    const queryParts = [
      `response_type=code`,
      `client_id=${encodeURIComponent(clientId)}`,
      `redirect_uri=${encodeURIComponent(redirectUri)}`,
      `scope=${scopes.map(encodeURIComponent).join("%20")}`,
      `state=${encodeURIComponent(state)}`,
      `code_challenge=${encodeURIComponent(codeChallenge)}`,
      `code_challenge_method=S256`,
    ];

    const twitterAuthUrl = `https://x.com/i/oauth2/authorize?${queryParts.join("&")}`;

    const isProduction = process.env.NODE_ENV === "production";

    const response = NextResponse.redirect(twitterAuthUrl);

    response.cookies.set("twitter_oauth_state", state, {
      httpOnly: true,
      secure: isProduction,
      sameSite: "lax",
      path: "/",
      maxAge: 600, // 10 minutes
    });

    response.cookies.set("twitter_oauth_code_verifier", codeVerifier, {
      httpOnly: true,
      secure: isProduction,
      sameSite: "lax",
      path: "/",
      maxAge: 600, // 10 minutes
    });

    return response;
  } catch (error) {
    console.error("Twitter OAuth initiation error:", error);
    const errorMessage = encodeURIComponent(
      error instanceof Error ? error.message : "Failed to initiate Twitter OAuth"
    );
    return NextResponse.redirect(
      new URL(`/social/accounts?error=${errorMessage}`, process.env.NEXT_PUBLIC_APP_URL)
    );
  }
}
