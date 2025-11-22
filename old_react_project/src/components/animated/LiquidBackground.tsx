/**
 * LIQUID BACKGROUND - Headspace-style Morphing Blobs (Cross-Platform)
 *
 * Animated liquid/blob animations using SVG and Reanimated
 * Works in Expo Go without native modules
 * Multiple morphing circles with smooth organic movement
 */

import React, { useEffect } from 'react';
import { Dimensions, StyleSheet } from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedProps,
  withRepeat,
  withTiming,
  withSpring,
  Easing,
} from 'react-native-reanimated';
import Svg, { Circle, Defs, RadialGradient, Stop } from 'react-native-svg';

const AnimatedCircle = Animated.createAnimatedComponent(Circle);
const { width, height } = Dimensions.get('window');

interface LiquidBackgroundProps {
  colors?: string[];
  blobCount?: number;
  speed?: 'slow' | 'normal' | 'fast';
  intensity?: 'subtle' | 'normal' | 'dramatic';
}

interface Blob {
  x: Animated.SharedValue<number>;
  y: Animated.SharedValue<number>;
  r: Animated.SharedValue<number>;
  color: string;
}

export const LiquidBackground: React.FC<LiquidBackgroundProps> = ({
  colors = ['#10B981', '#059669', '#047857'], // Default emerald gradient
  blobCount = 5,
  speed = 'normal',
  intensity = 'dramatic',
}) => {
  // Speed configurations
  const speedConfigs = {
    slow: { duration: 8000 },
    normal: { duration: 5000 },
    fast: { duration: 3000 },
  };

  // Intensity configurations (blob sizes)
  const intensityConfigs = {
    subtle: { min: 60, max: 100 },
    normal: { min: 80, max: 140 },
    dramatic: { min: 100, max: 200 },
  };

  const config = speedConfigs[speed];
  const sizeConfig = intensityConfigs[intensity];

  // Create animated values for each blob
  const blobs: Blob[] = Array.from({ length: blobCount }, (_, i) => ({
    x: useSharedValue(Math.random() * width),
    y: useSharedValue(Math.random() * height),
    r: useSharedValue(sizeConfig.min + Math.random() * (sizeConfig.max - sizeConfig.min)),
    color: colors[i % colors.length],
  }));

  useEffect(() => {
    // Animate each blob independently for organic movement
    blobs.forEach((blob, index) => {
      // X movement
      blob.x.value = withRepeat(
        withTiming(width * 0.2 + Math.random() * width * 0.6, {
          duration: config.duration + index * 500,
          easing: Easing.inOut(Easing.ease),
        }),
        -1,
        true
      );

      // Y movement
      blob.y.value = withRepeat(
        withTiming(height * 0.2 + Math.random() * height * 0.6, {
          duration: config.duration + index * 700,
          easing: Easing.inOut(Easing.ease),
        }),
        -1,
        true
      );

      // Size pulsing
      blob.r.value = withRepeat(
        withTiming(
          sizeConfig.min + Math.random() * (sizeConfig.max - sizeConfig.min),
          {
            duration: config.duration + index * 300,
            easing: Easing.inOut(Easing.ease),
          }
        ),
        -1,
        true
      );
    });
  }, []);

  return (
    <Svg style={styles.svg}>
      <Defs>
        {blobs.map((blob, index) => (
          <RadialGradient key={`grad-${index}`} id={`grad${index}`} cx="50%" cy="50%">
            <Stop offset="0%" stopColor={blob.color} stopOpacity="0.7" />
            <Stop offset="100%" stopColor={blob.color} stopOpacity="0" />
          </RadialGradient>
        ))}
      </Defs>
      {blobs.map((blob, index) => {
        const animatedProps = useAnimatedProps(() => ({
          cx: blob.x.value,
          cy: blob.y.value,
          r: blob.r.value,
        }));

        return (
          <AnimatedCircle
            key={index}
            animatedProps={animatedProps}
            fill={`url(#grad${index})`}
          />
        );
      })}
    </Svg>
  );
};

const styles = StyleSheet.create({
  svg: {
    ...StyleSheet.absoluteFillObject,
  },
});
