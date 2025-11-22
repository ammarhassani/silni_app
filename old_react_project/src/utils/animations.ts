/**
 * ANIMATION UTILITIES - Spring Physics & Presets
 *
 * Bold, dramatic, playful animations for "WOW" factor
 * Using Reanimated 4's spring physics engine
 */

import { WithSpringConfig } from 'react-native-reanimated';

// ==================== SPRING PRESETS ====================

/**
 * PLAYFUL - Headspace-style bouncy and fun
 * Use for: Buttons, cards, general interactions
 */
export const SPRING_PLAYFUL: WithSpringConfig = {
  mass: 1,
  stiffness: 150,
  damping: 8,
};

/**
 * DRAMATIC - Bold, eye-catching, memorable
 * Use for: Celebrations, milestones, big moments
 */
export const SPRING_DRAMATIC: WithSpringConfig = {
  mass: 1,
  stiffness: 200,
  damping: 6,
};

/**
 * GENTLE - Calm, smooth, relaxing
 * Use for: Backgrounds, subtle animations
 */
export const SPRING_GENTLE: WithSpringConfig = {
  mass: 1,
  stiffness: 80,
  damping: 12,
};

/**
 * SNAPPY - Quick, responsive, satisfying
 * Use for: Input focus, toggles, quick feedback
 */
export const SPRING_SNAPPY: WithSpringConfig = {
  mass: 0.5,
  stiffness: 180,
  damping: 15,
};

/**
 * BOUNCY - Maximum bounce for fun
 * Use for: Particle effects, playful elements
 */
export const SPRING_BOUNCY: WithSpringConfig = {
  mass: 1,
  stiffness: 250,
  damping: 5,
};

/**
 * ELASTIC - Stretchy, organic, liquid-like
 * Use for: Blob animations, liquid effects
 */
export const SPRING_ELASTIC: WithSpringConfig = {
  mass: 1.2,
  stiffness: 100,
  damping: 7,
};

// ==================== ANIMATION DURATIONS ====================

export const DURATION = {
  instant: 100,
  fast: 200,
  normal: 300,
  slow: 500,
  dramatic: 800,
} as const;

// ==================== EASING CURVES ====================

export const EASING = {
  // Custom cubic bezier curves for smooth animations
  smooth: [0.25, 0.1, 0.25, 1] as const,
  bounce: [0.68, -0.55, 0.265, 1.55] as const,
  inOut: [0.42, 0, 0.58, 1] as const,
};

// ==================== ANIMATION TIMING ====================

/**
 * Stagger delay for sequential animations
 * @param index - Index of element in sequence
 * @param baseDelay - Base delay in ms
 * @returns Total delay in ms
 */
export const staggerDelay = (index: number, baseDelay: number = 50): number => {
  return index * baseDelay;
};

/**
 * Get random delay for organic feel
 * @param min - Minimum delay in ms
 * @param max - Maximum delay in ms
 * @returns Random delay in ms
 */
export const randomDelay = (min: number = 0, max: number = 200): number => {
  return Math.random() * (max - min) + min;
};

// ==================== SCALE ANIMATIONS ====================

export const SCALE = {
  // Button press scale
  press: 0.95,
  // Card hover/focus scale
  hover: 1.05,
  // Dramatic entrance scale
  entrance: 0.8,
  // Pop effect
  pop: 1.2,
} as const;

// ==================== HAPTIC FEEDBACK PATTERNS ====================

export const HAPTIC = {
  light: 'light',
  medium: 'medium',
  heavy: 'heavy',
  success: 'success',
  warning: 'warning',
  error: 'error',
} as const;

// ==================== ANIMATION HELPERS ====================

/**
 * Convert degrees to radians
 */
export const toRadians = (degrees: number): number => {
  return (degrees * Math.PI) / 180;
};

/**
 * Convert radians to degrees
 */
export const toDegrees = (radians: number): number => {
  return (radians * 180) / Math.PI;
};

/**
 * Interpolate between two values
 */
export const interpolate = (
  value: number,
  inputRange: [number, number],
  outputRange: [number, number]
): number => {
  'worklet';
  const [inputMin, inputMax] = inputRange;
  const [outputMin, outputMax] = outputRange;

  const ratio = (value - inputMin) / (inputMax - inputMin);
  return outputMin + ratio * (outputMax - outputMin);
};

/**
 * Clamp value between min and max
 */
export const clamp = (value: number, min: number, max: number): number => {
  'worklet';
  return Math.min(Math.max(value, min), max);
};
