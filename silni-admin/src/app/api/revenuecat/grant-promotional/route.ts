import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

// RevenueCat promotional entitlement API (v1)
// https://www.revenuecat.com/reference/grant-a-promotional-entitlement

const REVENUECAT_API_V1_URL = "https://api.revenuecat.com/v1";

// Duration options for promotional entitlements
type PromotionalDuration =
  | "daily"
  | "three_day"
  | "weekly"
  | "monthly"
  | "two_month"
  | "three_month"
  | "six_month"
  | "yearly"
  | "lifetime";

// Map product types to RevenueCat durations
const productToDuration: Record<string, PromotionalDuration> = {
  monthly: "monthly",
  annual: "yearly",
};

// Helper to verify admin authentication
async function verifyAdminAuth(): Promise<{
  authorized: boolean;
  userId?: string;
  error?: string;
}> {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

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

  return { authorized: true, userId: user.id };
}

interface GrantPromotionalRequest {
  gift_id: string;
}

interface GrantPromotionalResponse {
  success: boolean;
  gift_id: string;
  revenuecat_promo_id?: string;
  activated_at?: string;
  expires_at?: string;
  error?: string;
}

export async function POST(
  request: NextRequest
): Promise<NextResponse<GrantPromotionalResponse>> {
  // Verify admin authentication
  const authResult = await verifyAdminAuth();
  if (!authResult.authorized) {
    return NextResponse.json(
      {
        success: false,
        gift_id: "",
        error: authResult.error,
      },
      { status: authResult.error?.includes("Forbidden") ? 403 : 401 }
    );
  }

  const apiKey = process.env.REVENUECAT_API_KEY_V1;
  const entitlementIdentifier = process.env.REVENUECAT_ENTITLEMENT_ID || "Silni MAX";

  if (!apiKey) {
    return NextResponse.json(
      {
        success: false,
        gift_id: "",
        error: "RevenueCat API key not configured",
      },
      { status: 500 }
    );
  }

  try {
    const body: GrantPromotionalRequest = await request.json();
    const { gift_id } = body;

    if (!gift_id) {
      return NextResponse.json(
        {
          success: false,
          gift_id: "",
          error: "gift_id is required",
        },
        { status: 400 }
      );
    }

    const supabase = createClient();

    // Fetch the gift details
    const { data: gift, error: fetchError } = await supabase
      .from("subscription_gifts")
      .select("*")
      .eq("id", gift_id)
      .single();

    if (fetchError || !gift) {
      return NextResponse.json(
        {
          success: false,
          gift_id,
          error: "Gift not found",
        },
        { status: 404 }
      );
    }

    // Verify gift is in scheduled status
    if (gift.status !== "scheduled") {
      return NextResponse.json(
        {
          success: false,
          gift_id,
          error: `Gift cannot be activated - current status: ${gift.status}`,
        },
        { status: 400 }
      );
    }

    // Verify recipient exists
    if (!gift.recipient_user_id) {
      return NextResponse.json(
        {
          success: false,
          gift_id,
          error: "Gift has no recipient user ID",
        },
        { status: 400 }
      );
    }

    // Get the duration for RevenueCat
    const duration = productToDuration[gift.product_type];
    if (!duration) {
      return NextResponse.json(
        {
          success: false,
          gift_id,
          error: `Invalid product type: ${gift.product_type}`,
        },
        { status: 400 }
      );
    }

    // Call RevenueCat promotional entitlement API
    // POST /v1/subscribers/{app_user_id}/entitlements/{entitlement_identifier}/promotional
    const rcUrl = `${REVENUECAT_API_V1_URL}/subscribers/${gift.recipient_user_id}/entitlements/${encodeURIComponent(entitlementIdentifier)}/promotional`;

    const rcResponse = await fetch(rcUrl, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        duration,
      }),
    });

    if (!rcResponse.ok) {
      const errorText = await rcResponse.text();
      console.error("RevenueCat promotional API error:", rcResponse.status, errorText);

      // Don't fail completely - still update the gift in DB but note the RC error
      // This allows for manual retry or alternative handling
      const { error: updateError } = await supabase
        .from("subscription_gifts")
        .update({
          admin_notes: `RevenueCat API failed (${rcResponse.status}): ${errorText}\n${gift.admin_notes || ""}`,
          updated_at: new Date().toISOString(),
        })
        .eq("id", gift_id);

      if (updateError) {
        console.error("Failed to update gift with RC error:", updateError);
      }

      return NextResponse.json(
        {
          success: false,
          gift_id,
          error: `RevenueCat API error: ${rcResponse.status}`,
        },
        { status: 502 }
      );
    }

    const rcData = await rcResponse.json();

    // Extract the promotional entitlement ID from the response
    // RevenueCat returns subscriber info with the new entitlement
    const entitlements = rcData?.subscriber?.entitlements;
    const promoEntitlement = entitlements?.[entitlementIdentifier];
    const promoId = promoEntitlement?.product_identifier || `promo_${gift_id}`;

    // Calculate expiration based on duration
    const now = new Date();
    let expiresAt: Date;
    switch (duration) {
      case "monthly":
        expiresAt = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
        break;
      case "yearly":
        expiresAt = new Date(now.getTime() + 365 * 24 * 60 * 60 * 1000);
        break;
      default:
        expiresAt = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
    }

    // Update gift status in database
    const { data: updatedGift, error: updateError } = await supabase
      .from("subscription_gifts")
      .update({
        status: "active",
        activated_at: now.toISOString(),
        expires_at: expiresAt.toISOString(),
        revenuecat_promo_id: promoId,
        updated_at: now.toISOString(),
      })
      .eq("id", gift_id)
      .select()
      .single();

    if (updateError) {
      console.error("Failed to update gift status:", updateError);
      // RevenueCat was successful but DB update failed
      // This is a critical inconsistency that should be logged/alerted
      return NextResponse.json(
        {
          success: false,
          gift_id,
          revenuecat_promo_id: promoId,
          error: "RevenueCat succeeded but database update failed",
        },
        { status: 500 }
      );
    }

    // Create notification for recipient
    await supabase.from("gift_notifications").insert({
      gift_id,
      notification_type: "gift_activated",
      recipient_id: gift.recipient_user_id,
      sent_at: now.toISOString(),
      delivery_method: "in_app",
    });

    // TODO: Send push notification using existing notification edge function

    return NextResponse.json({
      success: true,
      gift_id,
      revenuecat_promo_id: promoId,
      activated_at: now.toISOString(),
      expires_at: expiresAt.toISOString(),
    });
  } catch (error) {
    console.error("Grant promotional error:", error);
    return NextResponse.json(
      {
        success: false,
        gift_id: "",
        error: error instanceof Error ? error.message : "Internal server error",
      },
      { status: 500 }
    );
  }
}

// GET endpoint to check if a user has active promotional entitlements
export async function GET(request: NextRequest) {
  // Verify admin authentication
  const authResult = await verifyAdminAuth();
  if (!authResult.authorized) {
    return NextResponse.json(
      { error: authResult.error },
      { status: authResult.error?.includes("Forbidden") ? 403 : 401 }
    );
  }

  const apiKey = process.env.REVENUECAT_API_KEY_V1;
  if (!apiKey) {
    return NextResponse.json(
      { error: "RevenueCat API key not configured" },
      { status: 500 }
    );
  }

  const userId = request.nextUrl.searchParams.get("user_id");
  if (!userId) {
    return NextResponse.json(
      { error: "user_id parameter is required" },
      { status: 400 }
    );
  }

  try {
    // Get subscriber info from RevenueCat
    const rcUrl = `${REVENUECAT_API_V1_URL}/subscribers/${userId}`;
    const rcResponse = await fetch(rcUrl, {
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
    });

    if (!rcResponse.ok) {
      if (rcResponse.status === 404) {
        return NextResponse.json({
          user_id: userId,
          has_entitlements: false,
          entitlements: [],
        });
      }
      const errorText = await rcResponse.text();
      return NextResponse.json(
        { error: `RevenueCat API error: ${rcResponse.status} - ${errorText}` },
        { status: 502 }
      );
    }

    const rcData = await rcResponse.json();
    const entitlements = rcData?.subscriber?.entitlements || {};

    // Extract active entitlements
    const activeEntitlements = Object.entries(entitlements)
      .filter(([, value]: [string, unknown]) => {
        const entitlement = value as { expires_date?: string };
        return !entitlement.expires_date || new Date(entitlement.expires_date) > new Date();
      })
      .map(([key, value]: [string, unknown]) => {
        const entitlement = value as {
          product_identifier?: string;
          expires_date?: string;
          purchase_date?: string;
          store?: string;
        };
        return {
          identifier: key,
          product_identifier: entitlement.product_identifier,
          expires_date: entitlement.expires_date,
          purchase_date: entitlement.purchase_date,
          store: entitlement.store,
          is_promotional: entitlement.store === "promotional",
        };
      });

    return NextResponse.json({
      user_id: userId,
      has_entitlements: activeEntitlements.length > 0,
      entitlements: activeEntitlements,
    });
  } catch (error) {
    console.error("Get subscriber error:", error);
    return NextResponse.json(
      { error: error instanceof Error ? error.message : "Internal server error" },
      { status: 500 }
    );
  }
}
