"use client";

import { useQuery } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";

export interface AppTheme {
  id: string;
  theme_key: string;
  display_name_ar: string;
  display_name_en: string | null;
  is_dark: boolean;
  colors: {
    background_1: string;
    background_2: string;
    background_3: string;
    glass_background: string;
    glass_border: string;
    text_primary: string;
    text_secondary: string;
    [key: string]: string;
  };
  gradients: {
    background: { colors: string[] };
    [key: string]: { colors: string[] };
  };
  is_premium: boolean;
  is_default: boolean;
  sort_order: number;
  is_active: boolean;
}

// Fetch all active themes for preview
export function useThemes() {
  const supabase = createClient();

  return useQuery({
    queryKey: ["admin", "themes"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_themes")
        .select("*")
        .eq("is_active", true)
        .order("sort_order", { ascending: true });

      if (error) throw error;
      return data as AppTheme[];
    },
    staleTime: 5 * 60 * 1000, // Cache for 5 minutes
  });
}

// Convert Flutter's ARGB hex (#AARRGGBB) to CSS rgba
function argbHexToRgba(hex: string): string {
  if (!hex || hex.length !== 9 || !hex.startsWith("#")) {
    return "rgba(255,255,255,0.15)"; // fallback
  }
  const alpha = parseInt(hex.slice(1, 3), 16) / 255;
  const r = parseInt(hex.slice(3, 5), 16);
  const g = parseInt(hex.slice(5, 7), 16);
  const b = parseInt(hex.slice(7, 9), 16);
  return `rgba(${r},${g},${b},${alpha.toFixed(2)})`;
}

// Helper to convert theme to preview format
export function themeToPreviewFormat(theme: AppTheme) {
  const bgColors = theme.gradients?.background?.colors || [
    theme.colors.background_1,
    theme.colors.background_2,
    theme.colors.background_3,
  ];

  return {
    id: theme.theme_key,
    name: theme.display_name_ar,
    bg: `linear-gradient(180deg, ${bgColors[0]} 0%, ${bgColors[1]} 50%, ${bgColors[2]} 100%)`,
    surface: argbHexToRgba(theme.colors.glass_background),
    text: theme.colors.text_primary || "#ffffff",
  };
}
