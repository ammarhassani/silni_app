/**
 * PARALLAX SCROLL - Multi-layer Depth Effect
 *
 * ScrollView with parallax layers at different speeds
 * Creates depth and 3D feeling
 * Supports opacity and scale transformations
 */

import React, { ReactNode } from 'react';
import { ScrollViewProps, StyleSheet } from 'react-native';
import Animated, {
  useAnimatedRef,
  useScrollViewOffset,
  useAnimatedStyle,
  interpolate,
  Extrapolation,
} from 'react-native-reanimated';

interface ParallaxScrollProps extends ScrollViewProps {
  children: ReactNode;
}

interface ParallaxLayerProps {
  children: ReactNode;
  speed?: number; // 0 = static, 1 = normal scroll speed, 0.5 = half speed
  opacity?: [number, number]; // [start, end] opacity range
  scale?: [number, number]; // [start, end] scale range
  style?: any;
}

export const ParallaxScroll: React.FC<ParallaxScrollProps> = ({
  children,
  ...scrollViewProps
}) => {
  const scrollRef = useAnimatedRef<Animated.ScrollView>();
  const scrollOffset = useScrollViewOffset(scrollRef);

  return (
    <Animated.ScrollView
      ref={scrollRef}
      showsVerticalScrollIndicator={false}
      {...scrollViewProps}
    >
      {React.Children.map(children, (child) => {
        if (React.isValidElement(child) && child.type === ParallaxLayer) {
          return React.cloneElement(child as React.ReactElement<any>, {
            scrollOffset,
          });
        }
        return child;
      })}
    </Animated.ScrollView>
  );
};

export const ParallaxLayer: React.FC<ParallaxLayerProps & { scrollOffset?: any }> = ({
  children,
  speed = 0.5,
  opacity,
  scale,
  style,
  scrollOffset,
}) => {
  const animatedStyle = useAnimatedStyle(() => {
    if (!scrollOffset) return {};

    const transforms: any[] = [];

    // Parallax translation
    transforms.push({
      translateY: scrollOffset.value * (1 - speed),
    });

    // Scale transformation
    if (scale) {
      const scaleValue = interpolate(
        scrollOffset.value,
        [0, 500],
        scale,
        Extrapolation.CLAMP
      );
      transforms.push({ scale: scaleValue });
    }

    // Opacity transformation
    const opacityValue = opacity
      ? interpolate(
          scrollOffset.value,
          [0, 500],
          opacity,
          Extrapolation.CLAMP
        )
      : 1;

    return {
      transform: transforms,
      opacity: opacityValue,
    };
  });

  return (
    <Animated.View style={[styles.layer, style, animatedStyle]}>
      {children}
    </Animated.View>
  );
};

const styles = StyleSheet.create({
  layer: {
    width: '100%',
  },
});
