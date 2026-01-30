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

export async function GET(_request: NextRequest) {
  const authResult = await verifyAdminAuth();
  if (!authResult.authorized) {
    const errorMessage = encodeURIComponent(authResult.error || "Authentication failed");
    return NextResponse.redirect(
      new URL(`/social/accounts?error=${errorMessage}`, process.env.NEXT_PUBLIC_APP_URL)
    );
  }

  try {
    const facebookAppId = process.env.FACEBOOK_APP_ID;
    if (!facebookAppId) {
      return NextResponse.redirect(
        new URL(
          `/social/accounts?error=${encodeURIComponent("Facebook App ID not configured")}`,
          process.env.NEXT_PUBLIC_APP_URL
        )
      );
    }

    const state = generateRandomString(32);
    const redirectUri = `${process.env.NEXT_PUBLIC_APP_URL}/api/social/auth/instagram/callback`;
    const scope = "instagram_basic,instagram_content_publish,pages_read_engagement";

    const params = new URLSearchParams({
      client_id: facebookAppId,
      redirect_uri: redirectUri,
      scope,
      state,
    });

    const facebookAuthUrl = `https://www.facebook.com/v18.0/dialog/oauth?${params.toString()}`;

    const isProduction = process.env.NODE_ENV === "production";

    const response = NextResponse.redirect(facebookAuthUrl);

    response.cookies.set("instagram_oauth_state", state, {
      httpOnly: true,
      secure: isProduction,
      sameSite: "lax",
      path: "/",
      maxAge: 600, // 10 minutes
    });

    return response;
  } catch (error) {
    console.error("Instagram OAuth initiation error:", error);
    const errorMessage = encodeURIComponent(
      error instanceof Error ? error.message : "Failed to initiate Instagram OAuth"
    );
    return NextResponse.redirect(
      new URL(`/social/accounts?error=${errorMessage}`, process.env.NEXT_PUBLIC_APP_URL)
    );
  }
}
