"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import type { RevenueCatSyncStatus } from "@/app/api/revenuecat/offerings/route";

// Re-export the type for convenience
export type { RevenueCatSyncStatus };

/**
 * Hook to fetch RevenueCat offerings and products sync status.
 * This provides connection status and product verification data.
 */
export function useRevenueCatSync() {
  return useQuery({
    queryKey: ["revenuecat", "sync"],
    queryFn: async (): Promise<RevenueCatSyncStatus> => {
      const response = await fetch("/api/revenuecat/offerings");
      if (!response.ok) {
        throw new Error("Failed to fetch RevenueCat status");
      }
      return response.json();
    },
    staleTime: 60000, // 1 minute
    refetchOnWindowFocus: false,
  });
}

interface ProductVerificationResult {
  verified: boolean;
  product?: {
    id: string;
    storeIdentifier: string;
    type: string;
  };
  verifiedAt?: string;
  error?: string;
}

/**
 * Hook to verify a specific product exists in RevenueCat.
 */
export function useVerifyProduct() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (productId: string): Promise<ProductVerificationResult> => {
      const response = await fetch("/api/revenuecat/offerings", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ productId }),
      });

      if (!response.ok) {
        throw new Error("Failed to verify product");
      }

      return response.json();
    },
    onSuccess: () => {
      // Invalidate the sync query to refresh data
      queryClient.invalidateQueries({ queryKey: ["revenuecat", "sync"] });
    },
  });
}

/**
 * Helper to check if a product ID exists in the RevenueCat sync data.
 */
export function isProductInRevenueCat(
  syncData: RevenueCatSyncStatus | undefined,
  productId: string
): boolean {
  if (!syncData?.connected) return false;

  // Check in products list
  const inProducts = syncData.products.some(
    (p) => p.storeIdentifier === productId
  );

  // Also check in packages
  const inPackages = syncData.offerings.some((offering) =>
    offering.packages.some((pkg) => pkg.productIdentifier === productId)
  );

  return inProducts || inPackages;
}

/**
 * Get the package info for a product ID from RevenueCat data.
 */
export function getPackageForProduct(
  syncData: RevenueCatSyncStatus | undefined,
  productId: string
): { offeringId: string; packageId: string; displayName: string | null } | null {
  if (!syncData?.connected) return null;

  for (const offering of syncData.offerings) {
    for (const pkg of offering.packages) {
      if (pkg.productIdentifier === productId) {
        return {
          offeringId: offering.identifier,
          packageId: pkg.identifier,
          displayName: pkg.displayName,
        };
      }
    }
  }

  return null;
}
