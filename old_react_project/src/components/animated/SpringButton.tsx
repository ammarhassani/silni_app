/**
 * SPRING BUTTON - Bouncy Interactive Button
 *
 * Button with spring physics and scale animations
 * Dramatic, playful, satisfying to press
 * Supports haptic feedback
 */

import React, { ReactNode } from 'react';
import { Pressable, ViewStyle, Platform } from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
} from 'react-native-reanimated';
import * as Haptics from 'expo-haptics';
import { SPRING_PLAYFUL, SCALE } from '@/utils/animations';

interface SpringButtonProps {
  children: ReactNode;
  onPress?: () => void;
  style?: ViewStyle;
  pressScale?: number;
  enableHaptics?: boolean;
  disabled?: boolean;
}

export const SpringButton: React.FC<SpringButtonProps> = ({
  children,
  onPress,
  style,
  pressScale = SCALE.press,
  enableHaptics = true,
  disabled = false,
}) => {
  const scale = useSharedValue(1);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
  }));

  const handlePressIn = () => {
    if (disabled) return;

    // Scale down with spring
    scale.value = withSpring(pressScale, SPRING_PLAYFUL);

    // Haptic feedback
    if (enableHaptics && Platform.OS !== 'web') {
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    }
  };

  const handlePressOut = () => {
    if (disabled) return;

    // Scale back up with spring
    scale.value = withSpring(1, SPRING_PLAYFUL);
  };

  const handlePress = () => {
    if (disabled) return;

    // Success haptic on press
    if (enableHaptics && Platform.OS !== 'web') {
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    }

    onPress?.();
  };

  return (
    <Pressable
      onPressIn={handlePressIn}
      onPressOut={handlePressOut}
      onPress={handlePress}
      disabled={disabled}
    >
      <Animated.View style={[style, animatedStyle, disabled && { opacity: 0.5 }]}>
        {children}
      </Animated.View>
    </Pressable>
  );
};
