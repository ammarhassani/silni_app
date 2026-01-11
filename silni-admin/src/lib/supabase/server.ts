import { createServerClient, type CookieOptions } from "@supabase/ssr";
import { cookies } from "next/headers";
import { config, CURRENT_ENV, type Environment } from "@/lib/env-config";

/**
 * Create a Supabase server client.
 * Uses the environment configured at build time.
 */
export function createClient() {
  const cookieStore = cookies();

  return createServerClient(config.supabaseUrl, config.supabaseAnonKey, {
    cookies: {
      get(name: string) {
        return cookieStore.get(name)?.value;
      },
      set(name: string, value: string, options: CookieOptions) {
        try {
          cookieStore.set({ name, value, ...options });
        } catch {
          // Handle cookies in read-only context (e.g., middleware)
        }
      },
      remove(name: string, options: CookieOptions) {
        try {
          cookieStore.set({ name, value: "", ...options });
        } catch {
          // Handle cookies in read-only context
        }
      },
    },
  });
}

/**
 * Get the current environment on the server side
 */
export function getServerEnvironment(): Environment {
  return CURRENT_ENV;
}
