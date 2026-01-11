/**
 * Environment Configuration
 *
 * Build-time environment configuration.
 * Each deployment (local/staging/production) has exactly ONE environment.
 * No runtime switching - this is the secure, best-practice approach.
 */

export type Environment = 'staging' | 'production';

export interface EnvironmentConfig {
  name: Environment;
  label: string;
  supabaseUrl: string;
  supabaseAnonKey: string;
  color: string;
  textColor: string;
  bgColor: string;
}

// Environment display configuration
const envDisplayConfig: Record<Environment, { label: string; color: string; textColor: string; bgColor: string }> = {
  staging: {
    label: 'Staging',
    color: '#f59e0b', // Amber
    textColor: 'text-amber-700',
    bgColor: 'bg-amber-100',
  },
  production: {
    label: 'Production',
    color: '#22c55e', // Green
    textColor: 'text-green-700',
    bgColor: 'bg-green-100',
  },
};

// Validate and get current environment (determined at build time)
function getValidEnvironment(): Environment {
  const envValue = process.env.NEXT_PUBLIC_ENV;
  if (envValue === 'staging' || envValue === 'production') {
    return envValue;
  }
  // Default to staging if not set or invalid
  return 'staging';
}

export const CURRENT_ENV: Environment = getValidEnvironment();

// Get display config with fallback
const displayConfig = envDisplayConfig[CURRENT_ENV] || envDisplayConfig.staging;

// Current environment configuration
export const config: EnvironmentConfig = {
  name: CURRENT_ENV,
  label: displayConfig.label,
  supabaseUrl: process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  supabaseAnonKey: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '',
  color: displayConfig.color,
  textColor: displayConfig.textColor,
  bgColor: displayConfig.bgColor,
};

/**
 * Get Supabase configuration
 */
export function getSupabaseConfig(): { url: string; anonKey: string } {
  return {
    url: config.supabaseUrl,
    anonKey: config.supabaseAnonKey,
  };
}

/**
 * Check if current environment is production
 */
export function isProduction(): boolean {
  return CURRENT_ENV === 'production';
}

/**
 * Check if current environment is staging
 */
export function isStaging(): boolean {
  return CURRENT_ENV === 'staging';
}
