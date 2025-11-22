/**
 * GLASS CARD
 *
 * Glassmorphism card with frosted glass effect
 * Features semi-transparent background with blur effect
 */

import React from 'react';
import { View, StyleSheet, ViewStyle } from 'react-native';
import { BlurView } from 'expo-blur';
import { Colors } from '@/constants/colors';

interface GlassCardProps {
  children: React.ReactNode;
  style?: ViewStyle;
  intensity?: number; // 0-100
  tint?: 'light' | 'dark' | 'default';
  border?: boolean;
}

export const GlassCard: React.FC<GlassCardProps> = ({
  children,
  style,
  intensity = 80,
  tint = 'light',
  border = true,
}) => {
  return (
    <BlurView
      intensity={intensity}
      tint={tint}
      style={[
        styles.glassCard,
        border && styles.glassBorder,
        style,
      ]}
    >
      {children}
    </BlurView>
  );
};

const styles = StyleSheet.create({
  glassCard: {
    borderRadius: 20,
    overflow: 'hidden',
    backgroundColor: Colors.glass.whiteLight,
  },
  glassBorder: {
    borderWidth: 1,
    borderColor: Colors.glass.border,
  },
});

// Preset variations
export const GlassCardLight: React.FC<Omit<GlassCardProps, 'tint'>> = (props) => (
  <GlassCard {...props} tint="light" />
);

export const GlassCardDark: React.FC<Omit<GlassCardProps, 'tint'>> = (props) => (
  <GlassCard {...props} tint="dark" />
);
