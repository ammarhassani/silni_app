/**
 * 3D FLIP CARD - Perspective Transforms
 *
 * Interactive card that flips in 3D space
 * Spring-based physics for natural movement
 * Supports front and back content
 */

import React, { ReactNode } from 'react';
import { Pressable, StyleSheet, ViewStyle } from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  interpolate,
  Extrapolation,
} from 'react-native-reanimated';
import { SPRING_PLAYFUL } from '@/utils/animations';

interface FlipCard3DProps {
  frontContent: ReactNode;
  backContent: ReactNode;
  style?: ViewStyle;
  flipOnPress?: boolean;
  isFlipped?: boolean;
  onFlip?: (isFlipped: boolean) => void;
}

export const FlipCard3D: React.FC<FlipCard3DProps> = ({
  frontContent,
  backContent,
  style,
  flipOnPress = true,
  isFlipped = false,
  onFlip,
}) => {
  // 0 = front, 1 = back
  const flip = useSharedValue(isFlipped ? 1 : 0);

  const handlePress = () => {
    if (!flipOnPress) return;

    const newValue = flip.value === 0 ? 1 : 0;
    flip.value = withSpring(newValue, SPRING_PLAYFUL);

    onFlip?.(newValue === 1);
  };

  // Front side animation
  const frontAnimatedStyle = useAnimatedStyle(() => {
    const rotateY = interpolate(
      flip.value,
      [0, 1],
      [0, 180],
      Extrapolation.CLAMP
    );

    const opacity = interpolate(
      flip.value,
      [0, 0.5, 0.5, 1],
      [1, 1, 0, 0],
      Extrapolation.CLAMP
    );

    return {
      transform: [
        { perspective: 1000 },
        { rotateY: `${rotateY}deg` },
      ],
      opacity,
      backfaceVisibility: 'hidden',
    };
  });

  // Back side animation
  const backAnimatedStyle = useAnimatedStyle(() => {
    const rotateY = interpolate(
      flip.value,
      [0, 1],
      [180, 360],
      Extrapolation.CLAMP
    );

    const opacity = interpolate(
      flip.value,
      [0, 0.5, 0.5, 1],
      [0, 0, 1, 1],
      Extrapolation.CLAMP
    );

    return {
      transform: [
        { perspective: 1000 },
        { rotateY: `${rotateY}deg` },
      ],
      opacity,
      backfaceVisibility: 'hidden',
    };
  });

  return (
    <Pressable onPress={handlePress} style={[styles.container, style]}>
      {/* Front Side */}
      <Animated.View style={[styles.card, styles.front, frontAnimatedStyle]}>
        {frontContent}
      </Animated.View>

      {/* Back Side */}
      <Animated.View style={[styles.card, styles.back, backAnimatedStyle]}>
        {backContent}
      </Animated.View>
    </Pressable>
  );
};

const styles = StyleSheet.create({
  container: {
    position: 'relative',
  },
  card: {
    width: '100%',
    height: '100%',
  },
  front: {
    position: 'absolute',
  },
  back: {
    position: 'absolute',
  },
});
