/**
 * MODERN COLOR SYSTEM - 2024/2025
 *
 * Featuring:
 * - Vibrant gradients for depth and energy
 * - Glassmorphism support with transparency
 * - Premium gold accents
 * - Dark mode optimized
 */

export const Colors = {
  // PRIMARY - Vibrant Emerald Green (Growth, Life, Connection)
  primary: {
    main: '#10B981',      // Emerald 500 - Modern, vibrant
    light: '#34D399',     // Emerald 400
    lighter: '#6EE7B7',   // Emerald 300
    dark: '#059669',      // Emerald 600
    darker: '#047857',    // Emerald 700
    gradient: ['#10B981', '#059669'], // Primary gradient
  },

  // ACCENT - Electric Purple (Premium, Spiritual)
  accent: {
    main: '#8B5CF6',      // Violet 500
    light: '#A78BFA',     // Violet 400
    dark: '#7C3AED',      // Violet 600
    gradient: ['#8B5CF6', '#7C3AED'], // Accent gradient
  },

  // GOLD - Warm Premium (Value, Greatness)
  gold: {
    main: '#F59E0B',      // Amber 500
    light: '#FBBF24',     // Amber 400
    lighter: '#FEF3C7',   // Amber 50
    dark: '#D97706',      // Amber 600
    gradient: ['#F59E0B', '#D97706'], // Gold gradient
  },

  // HERO GRADIENTS - Full screen backgrounds
  gradients: {
    primary: ['#10B981', '#059669'],           // Emerald gradient
    sunset: ['#F59E0B', '#EC4899', '#8B5CF6'], // Warm sunset
    ocean: ['#06B6D4', '#3B82F6', '#8B5CF6'],  // Ocean blues
    forest: ['#10B981', '#059669', '#047857'], // Deep forest
    royal: ['#8B5CF6', '#7C3AED', '#6D28D9'], // Royal purple
  },

  // GLASSMORPHISM - Frosted glass effects
  glass: {
    white: 'rgba(255, 255, 255, 0.1)',
    whiteLight: 'rgba(255, 255, 255, 0.15)',
    whiteStrong: 'rgba(255, 255, 255, 0.25)',
    dark: 'rgba(0, 0, 0, 0.1)',
    darkLight: 'rgba(0, 0, 0, 0.15)',
    darkStrong: 'rgba(0, 0, 0, 0.25)',
    border: 'rgba(255, 255, 255, 0.2)',
  },

  // NEUTRALS - Modern grays
  white: '#FFFFFF',
  offWhite: '#F9FAFB',  // Gray 50
  border: '#E5E7EB',    // Gray 200
  gray: {
    50: '#F9FAFB',
    100: '#F3F4F6',
    200: '#E5E7EB',
    300: '#D1D5DB',
    400: '#9CA3AF',
    500: '#6B7280',
    600: '#4B5563',
    700: '#374151',
    800: '#1F2937',
    900: '#111827',
  },

  // BACKGROUND - Light & Dark
  background: {
    light: '#FFFFFF',
    lightAlt: '#F9FAFB',
    dark: '#0F172A',      // Slate 900
    darkAlt: '#1E293B',   // Slate 800
  },

  // STATUS COLORS
  success: {
    main: '#10B981',      // Emerald 500
    light: '#D1FAE5',     // Emerald 100
    dark: '#059669',      // Emerald 600
  },

  error: {
    main: '#EF4444',      // Red 500
    light: '#FEE2E2',     // Red 100
    dark: '#DC2626',      // Red 600
  },

  warning: {
    main: '#F59E0B',      // Amber 500
    light: '#FEF3C7',     // Amber 100
    dark: '#D97706',      // Amber 600
  },

  info: {
    main: '#3B82F6',      // Blue 500
    light: '#DBEAFE',     // Blue 100
    dark: '#2563EB',      // Blue 600
  },

  // TEXT COLORS
  text: {
    primary: '#111827',   // Gray 900
    secondary: '#6B7280', // Gray 500
    disabled: '#9CA3AF',  // Gray 400
    hint: '#D1D5DB',      // Gray 300
    inverse: '#FFFFFF',
  },

  // DARK MODE
  dark: {
    background: '#0F172A',    // Slate 900
    surface: '#1E293B',       // Slate 800
    surfaceLight: '#334155',  // Slate 700
    primary: '#10B981',       // Emerald 500
    accent: '#8B5CF6',        // Violet 500
    text: '#F9FAFB',          // Gray 50
    textSecondary: '#94A3B8', // Slate 400
    border: '#334155',        // Slate 700
  },

  // SHADOWS - Modern elevation
  shadow: {
    sm: {
      shadowColor: '#000',
      shadowOffset: { width: 0, height: 1 },
      shadowOpacity: 0.05,
      shadowRadius: 2,
      elevation: 2,
    },
    md: {
      shadowColor: '#000',
      shadowOffset: { width: 0, height: 4 },
      shadowOpacity: 0.1,
      shadowRadius: 8,
      elevation: 4,
    },
    lg: {
      shadowColor: '#000',
      shadowOffset: { width: 0, height: 8 },
      shadowOpacity: 0.15,
      shadowRadius: 16,
      elevation: 8,
    },
    xl: {
      shadowColor: '#000',
      shadowOffset: { width: 0, height: 12 },
      shadowOpacity: 0.2,
      shadowRadius: 24,
      elevation: 12,
    },
    colored: {
      shadowColor: '#10B981',
      shadowOffset: { width: 0, height: 4 },
      shadowOpacity: 0.3,
      shadowRadius: 12,
      elevation: 6,
    },
  },
};

// Theme-aware colors helper
export const getThemeColors = (isDark: boolean) => {
  if (isDark) {
    return {
      background: Colors.dark.background,
      surface: Colors.dark.surface,
      surfaceLight: Colors.dark.surfaceLight,
      primary: Colors.dark.primary,
      accent: Colors.dark.accent,
      text: Colors.dark.text,
      textSecondary: Colors.dark.textSecondary,
      border: Colors.dark.border,
    };
  }

  return {
    background: Colors.background.light,
    surface: Colors.background.lightAlt,
    surfaceLight: Colors.offWhite,
    primary: Colors.primary.main,
    accent: Colors.accent.main,
    text: Colors.text.primary,
    textSecondary: Colors.text.secondary,
    border: Colors.border,
  };
};
