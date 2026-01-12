import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

// Helper to verify admin authentication
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

// RevenueCat REST API v2 types - flexible to handle varying response structures
interface RevenueCatProduct {
  id?: string;
  store_identifier?: string;
  type?: string;
  created_at?: string;
  app_id?: string;
}

interface RevenueCatPackage {
  id?: string;
  identifier?: string;
  platform_product_identifier?: string;
  display_name?: string | null;
  position?: number;
}

interface RevenueCatOffering {
  id?: string;
  identifier?: string;
  display_name?: string | null;
  is_current?: boolean;
  packages?: RevenueCatPackage[];
  created_at?: string;
}

interface RevenueCatResponse {
  items?: unknown[];
  object?: string;
  // Some endpoints return data directly without items wrapper
  [key: string]: unknown;
}

export interface RevenueCatSyncStatus {
  connected: boolean;
  lastSyncAt: string;
  offerings: {
    id: string;
    identifier: string;
    displayName: string | null;
    isCurrent: boolean;
    packages: {
      id: string;
      identifier: string;
      productIdentifier: string;
      displayName: string | null;
    }[];
  }[];
  products: {
    id: string;
    storeIdentifier: string;
    type: string;
  }[];
  error?: string;
}

const REVENUECAT_API_URL = "https://api.revenuecat.com/v2";

export async function GET(request: NextRequest) {
  // Verify admin authentication
  const authResult = await verifyAdminAuth();
  if (!authResult.authorized) {
    return NextResponse.json({ error: authResult.error }, { status: authResult.error?.includes("Forbidden") ? 403 : 401 });
  }

  const projectId = process.env.REVENUECAT_PROJECT_ID;
  const apiKey = process.env.REVENUECAT_API_KEY_V2;

  // Check if credentials are configured
  if (!projectId || !apiKey) {
    return NextResponse.json<RevenueCatSyncStatus>({
      connected: false,
      lastSyncAt: new Date().toISOString(),
      offerings: [],
      products: [],
      error: "RevenueCat credentials not configured",
    });
  }

  try {
    // Fetch offerings and products in parallel
    const [offeringsRes, productsRes] = await Promise.all([
      fetch(`${REVENUECAT_API_URL}/projects/${projectId}/offerings`, {
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
        cache: "no-store",
      }),
      fetch(`${REVENUECAT_API_URL}/projects/${projectId}/products`, {
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
        cache: "no-store",
      }),
    ]);

    if (!offeringsRes.ok || !productsRes.ok) {
      const errorText = !offeringsRes.ok
        ? await offeringsRes.text()
        : await productsRes.text();
      const errorStatus = !offeringsRes.ok ? offeringsRes.status : productsRes.status;
      return NextResponse.json<RevenueCatSyncStatus>({
        connected: false,
        lastSyncAt: new Date().toISOString(),
        offerings: [],
        products: [],
        error: `RevenueCat API error: ${errorStatus} - ${errorText}`,
      });
    }

    const offeringsData: RevenueCatResponse = await offeringsRes.json();
    const productsData: RevenueCatResponse = await productsRes.json();

    // Handle different response structures - items array or direct data
    const offeringsList = Array.isArray(offeringsData.items)
      ? offeringsData.items as RevenueCatOffering[]
      : Array.isArray(offeringsData)
        ? offeringsData as RevenueCatOffering[]
        : [];

    const productsList = Array.isArray(productsData.items)
      ? productsData.items as RevenueCatProduct[]
      : Array.isArray(productsData)
        ? productsData as RevenueCatProduct[]
        : [];

    const syncStatus: RevenueCatSyncStatus = {
      connected: true,
      lastSyncAt: new Date().toISOString(),
      offerings: offeringsList.map((offering) => ({
        id: offering?.id || "",
        identifier: offering?.identifier || "",
        displayName: offering?.display_name || null,
        isCurrent: offering?.is_current || false,
        packages: (offering?.packages || []).map((pkg) => ({
          id: pkg?.id || "",
          identifier: pkg?.identifier || "",
          productIdentifier: pkg?.platform_product_identifier || "",
          displayName: pkg?.display_name || null,
        })),
      })),
      products: productsList.map((product) => ({
        id: product?.id || "",
        storeIdentifier: product?.store_identifier || "",
        type: product?.type || "",
      })),
    };

    return NextResponse.json(syncStatus);
  } catch (error) {
    console.error("RevenueCat API error:", error);
    return NextResponse.json<RevenueCatSyncStatus>({
      connected: false,
      lastSyncAt: new Date().toISOString(),
      offerings: [],
      products: [],
      error: error instanceof Error ? error.message : "Failed to connect to RevenueCat",
    });
  }
}

// POST endpoint to verify a specific product exists in RevenueCat
export async function POST(request: NextRequest) {
  // Verify admin authentication
  const authResult = await verifyAdminAuth();
  if (!authResult.authorized) {
    return NextResponse.json({ error: authResult.error }, { status: authResult.error?.includes("Forbidden") ? 403 : 401 });
  }

  const projectId = process.env.REVENUECAT_PROJECT_ID;
  const apiKey = process.env.REVENUECAT_API_KEY_V2;

  if (!projectId || !apiKey) {
    return NextResponse.json({
      verified: false,
      error: "RevenueCat credentials not configured",
    });
  }

  try {
    const { productId } = await request.json();

    if (!productId) {
      return NextResponse.json({
        verified: false,
        error: "Product ID required",
      }, { status: 400 });
    }

    // Fetch all products to check if the product exists
    const productsRes = await fetch(
      `${REVENUECAT_API_URL}/projects/${projectId}/products`,
      {
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
      }
    );

    if (!productsRes.ok) {
      return NextResponse.json({
        verified: false,
        error: `RevenueCat API error: ${productsRes.status}`,
      });
    }

    const productsData: RevenueCatResponse = await productsRes.json();
    const productsList = Array.isArray(productsData.items)
      ? productsData.items as RevenueCatProduct[]
      : [];
    const product = productsList.find(
      (p: RevenueCatProduct) => p.store_identifier === productId
    );

    return NextResponse.json({
      verified: !!product,
      product: product
        ? {
            id: product.id,
            storeIdentifier: product.store_identifier,
            type: product.type,
          }
        : null,
      verifiedAt: new Date().toISOString(),
    });
  } catch (error) {
    console.error("Product verification error:", error);
    return NextResponse.json({
      verified: false,
      error: error instanceof Error ? error.message : "Verification failed",
    });
  }
}
