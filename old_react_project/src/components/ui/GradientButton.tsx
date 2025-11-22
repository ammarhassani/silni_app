/**
 * GRADIENT BUTTON
 *
 * Modern button with gradient background and scale animation
 * Supports primary, accent, and gold variants
 */

import React from 'react';
import {
  Text,
  StyleSheet,
  ViewStyle,
  TextStyle,
  ActivityIndicator,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Colors } from '@/constants/colors';
import { Typography } from '@/constants/typography';
import { Spacing } from '@/constants/spacing';
import { ScaleButton } from '@/components/animated/ScaleButton';

interface GradientButtonProps {
  title: string;
  onPress: () => void;
  variant?: 'primary' | 'accent' | 'gold';
  size?: 'small' | 'medium' | 'large';
  disabled?: boolean;
  loading?: boolean;
  style?: ViewStyle;
  textStyle?: TextStyle;
}

export const GradientButton: React.FC<GradientButtonProps> = ({
  title,
  onPress,
  variant = 'primary',
  size = 'medium',
  disabled = false,
  loading = false,
  style,
  textStyle,
}) => {
  const gradientColors = {
    primary: Colors.primary.gradient,
    accent: Colors.accent.gradient,
    gold: Colors.gold.gradient,
  }[variant];

  const sizeStyles = {
    small: styles.smallButton,
    medium: styles.mediumButton,
    large: styles.largeButton,
  }[size];

  const textSizeStyles = {
    small: styles.smallText,
    medium: styles.mediumText,
    large: styles.largeText,
  }[size];

  return (
    <ScaleButton
      onPress={onPress}
      disabled={disabled || loading}
      style={[styles.container, style]}
    >
      <LinearGradient
        colors={gradientColors}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 0 }}
        style={[
          styles.gradient,
          sizeStyles,
          disabled && styles.disabled,
        ]}
      >
        {loading ? (
          <ActivityIndicator color={Colors.white} />
        ) : (
          <Text style={[styles.text, textSizeStyles, textStyle]}>
            {title}
          </Text>
        )}
      </LinearGradient>
    </ScaleButton>
  );
};

const styles = StyleSheet.create({
  container: {
    borderRadius: 16,
    ...Colors.shadow.md,
  },
  gradient: {
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
  },
  smallButton: {
    paddingVertical: Spacing.sm,
    paddingHorizontal: Spacing.lg,
  },
  mediumButton: {
    paddingVertical: Spacing.md,
    paddingHorizontal: Spacing.xl,
  },
  largeButton: {
    paddingVertical: Spacing.lg,
    paddingHorizontal: Spacing.xxl,
  },
  text: {
    color: Colors.white,
    fontWeight: '600',
  },
  smallText: {
    ...Typography.caption,
    fontSize: 14,
  },
  mediumText: {
    ...Typography.button,
  },
  largeText: {
    ...Typography.button,
    fontSize: 18,
  },
  disabled: {
    opacity: 0.5,
  },
});
