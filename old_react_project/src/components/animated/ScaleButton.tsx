/**
 * SCALE BUTTON - Simple version
 * Using React Native's built-in Animated API
 */

import React, { useRef } from 'react';
import {
  TouchableOpacity,
  Animated,
  ViewStyle,
  TouchableOpacityProps,
} from 'react-native';

interface ScaleButtonProps extends TouchableOpacityProps {
  children: React.ReactNode;
  onPress?: () => void;
  style?: ViewStyle;
  scaleValue?: number;
}

export const ScaleButton: React.FC<ScaleButtonProps> = ({
  children,
  onPress,
  style,
  scaleValue = 0.95,
  ...props
}) => {
  const scale = useRef(new Animated.Value(1)).current;

  const handlePressIn = () => {
    Animated.spring(scale, {
      toValue: scaleValue,
      useNativeDriver: true,
    }).start();
  };

  const handlePressOut = () => {
    Animated.spring(scale, {
      toValue: 1,
      useNativeDriver: true,
    }).start();
  };

  return (
    <TouchableOpacity
      onPressIn={handlePressIn}
      onPressOut={handlePressOut}
      onPress={onPress}
      activeOpacity={0.9}
      {...props}
    >
      <Animated.View style={[style, { transform: [{ scale }] }]}>
        {children}
      </Animated.View>
    </TouchableOpacity>
  );
};
