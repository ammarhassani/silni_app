/**
 * GRADIENT BACKGROUND
 *
 * Modern gradient backgrounds for full-screen effects
 * Supports multiple color stops and custom angles
 */

import React from 'react';
import { View, StyleSheet, ViewStyle } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Colors } from '@/constants/colors';

interface GradientBackgroundProps {
  colors?: string[];
  style?: ViewStyle;
  children?: React.ReactNode;
  start?: { x: number; y: number };
  end?: { x: number; y: number };
}

export const GradientBackground: React.FC<GradientBackgroundProps> = ({
  colors = Colors.gradients.primary,
  style,
  children,
  start = { x: 0, y: 0 },
  end = { x: 0, y: 1 },
}) => {
  return (
    <LinearGradient
      colors={colors}
      start={start}
      end={end}
      style={[styles.gradient, style]}
    >
      {children}
    </LinearGradient>
  );
};

const styles = StyleSheet.create({
  gradient: {
    flex: 1,
  },
});

// Pre-built gradient presets
export const GradientPresets = {
  primary: () => (
    <GradientBackground colors={Colors.gradients.primary} />
  ),
  sunset: () => (
    <GradientBackground colors={Colors.gradients.sunset} />
  ),
  ocean: () => (
    <GradientBackground colors={Colors.gradients.ocean} />
  ),
  forest: () => (
    <GradientBackground colors={Colors.gradients.forest} />
  ),
  royal: () => (
    <GradientBackground colors={Colors.gradients.royal} />
  ),
};
