/**
 * CONFETTI EXPLOSION - Celebration Particles (Cross-Platform)
 *
 * Confetti bursts using Reanimated (works in Expo Go)
 * Customizable colors, count, and origin
 */

import React, { forwardRef, useImperativeHandle } from 'react';
import { View, StyleSheet, Dimensions } from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  Easing,
} from 'react-native-reanimated';

const { width, height } = Dimensions.get('window');

// Confetti color themes
export const CONFETTI_THEMES = {
  celebration: ['#10B981', '#F59E0B', '#8B5CF6', '#EC4899', '#3B82F6'],
  rainbow: ['#FF6B6B', '#4ECDC4', '#45B7D1', '#FFA07A', '#98D8C8'],
  gold: ['#FFD700', '#FFA500', '#FF8C00', '#FFB347', '#FFDB58'],
  islamic: ['#10B981', '#059669', '#047857', '#065F46', '#064E3B'],
};

interface ConfettiExplosionProps {
  colors?: string[];
  count?: number;
  origin?: { x: number; y: number };
  autoStart?: boolean;
}

export interface ConfettiExplosionHandle {
  shoot: () => void;
  reset: () => void;
}

export const ConfettiExplosion = forwardRef<
  ConfettiExplosionHandle,
  ConfettiExplosionProps
>(({
  colors = ['#10B981', '#F59E0B', '#8B5CF6', '#EC4899', '#3B82F6'],
  count = 50,
  origin = { x: width / 2, y: height * 0.3 },
}, ref) => {
  const particles = Array.from({ length: count }, (_, i) => {
    const angle = (Math.PI * 2 * i) / count;
    const velocity = 200 + Math.random() * 200;
    return {
      x: useSharedValue(origin.x),
      y: useSharedValue(origin.y),
      opacity: useSharedValue(0),
      rotation: useSharedValue(0),
      color: colors[i % colors.length],
      vx: Math.cos(angle) * velocity,
      vy: Math.sin(angle) * velocity - 100,
    };
  });

  useImperativeHandle(ref, () => ({
    shoot: () => {
      particles.forEach((p) => {
        p.x.value = origin.x;
        p.y.value = origin.y;
        p.opacity.value = 1;
        p.rotation.value = 0;

        p.x.value = withTiming(origin.x + p.vx, {
          duration: 1500,
          easing: Easing.out(Easing.quad),
        });

        p.y.value = withTiming(origin.y + p.vy + 500, {
          duration: 1500,
          easing: Easing.in(Easing.quad),
        });

        p.opacity.value = withTiming(0, { duration: 1500 });
        p.rotation.value = withTiming(720, { duration: 1500 });
      });
    },
    reset: () => {
      particles.forEach((p) => {
        p.opacity.value = 0;
      });
    },
  }));

  return (
    <View style={styles.container} pointerEvents="none">
      {particles.map((p, i) => {
        const animatedStyle = useAnimatedStyle(() => ({
          position: 'absolute',
          left: p.x.value - 5,
          top: p.y.value - 5,
          width: 10,
          height: 10,
          backgroundColor: p.color,
          opacity: p.opacity.value,
          transform: [{ rotate: `${p.rotation.value}deg` }],
          borderRadius: 2,
        }));

        return <Animated.View key={i} style={animatedStyle} />;
      })}
    </View>
  );
});

ConfettiExplosion.displayName = 'ConfettiExplosion';

const styles = StyleSheet.create({
  container: {
    ...StyleSheet.absoluteFillObject,
  },
});
