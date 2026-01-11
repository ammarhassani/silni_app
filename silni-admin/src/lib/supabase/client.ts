import { createBrowserClient } from "@supabase/ssr";
import type { SupabaseClient } from "@supabase/supabase-js";
import { config } from "@/lib/env-config";

// Cached client instance
let cachedClient: SupabaseClient | null = null;

/**
 * Create a Supabase browser client.
 * Uses the environment configured at build time.
 */
export function createClient(): SupabaseClient {
  if (cachedClient) {
    return cachedClient;
  }

  cachedClient = createBrowserClient(config.supabaseUrl, config.supabaseAnonKey);
  return cachedClient;
}
