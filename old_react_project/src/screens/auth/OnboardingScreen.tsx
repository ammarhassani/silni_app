/**
 * ONBOARDING SCREEN - WOW REDESIGN
 *
 * Headspace-level dramatic animations:
 * - Liquid morphing blob backgrounds
 * - 3D flip cards for content
 * - Confetti explosion on final slide
 * - Spring physics everywhere
 * - Parallax floating elements
 */

import React, { useRef, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  Dimensions,
  ViewToken,
  Platform,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useAuthStore } from '@/store/authStore';
import { Colors } from '@/constants/colors';
import { Typography } from '@/constants/typography';
import { Spacing } from '@/constants/spacing';
import { LinearGradient } from 'expo-linear-gradient';

// Import components conditionally based on platform
import {
  SpringButton,
  ConfettiExplosion,
  ConfettiExplosionHandle,
  CONFETTI_THEMES,
} from '@/components/animated';

// Native-only components
let LiquidBackground: any = null;
let FlipCard3D: any = null;

if (Platform.OS !== 'web') {
  const animated = require('@/components/animated');
  LiquidBackground = animated.LiquidBackground;
  FlipCard3D = animated.FlipCard3D;
}

const { width } = Dimensions.get('window');

interface OnboardingSlide {
  id: string;
  title: string;
  description: string;
  icon: string;
  blobColors: string[]; // Liquid blob colors
}

const slides: OnboardingSlide[] = [
  {
    id: '1',
    title: 'صِلة الرحم',
    description:
      'من وصل رحمه وصله الله، ومن قطع رحمه قطعه الله\n\nساعدك تطبيق صِلني على تقوية علاقاتك العائلية',
    icon: '🤝',
    blobColors: ['#10B981', '#059669', '#047857'], // Emerald green blobs
  },
  {
    id: '2',
    title: 'تتبع تواصلك',
    description:
      'سجّل زياراتك واتصالاتك ورسائلك مع أقاربك\n\nاحتفظ بذكرياتك وتفاصيل لقاءاتك',
    icon: '📱',
    blobColors: ['#06B6D4', '#3B82F6', '#8B5CF6'], // Ocean blues to purple
  },
  {
    id: '3',
    title: 'تذكيرات ذكية',
    description:
      'لن تنسى التواصل مع أحبائك بعد اليوم\n\nتذكيرات تلقائية بناءً على عاداتك',
    icon: '🔔',
    blobColors: ['#8B5CF6', '#7C3AED', '#6D28D9'], // Royal purple blobs
  },
  {
    id: '4',
    title: 'إحصائيات وتحفيز',
    description:
      'تابع تقدمك واكسب النقاط والشارات\n\nابنِ سلسلة تواصل يومية مع عائلتك',
    icon: '📊',
    blobColors: ['#F59E0B', '#EC4899', '#8B5CF6'], // Warm sunset
  },
];

export default function OnboardingScreen() {
  const navigation = useNavigation<any>();
  const { setHasCompletedOnboarding } = useAuthStore();
  const flatListRef = useRef<FlatList>(null);
  const confettiRef = useRef<ConfettiExplosionHandle>(null);
  const [currentIndex, setCurrentIndex] = useState(0);

  const viewabilityConfig = {
    itemVisiblePercentThreshold: 50,
  };

  const onViewableItemsChanged = useRef(
    ({ viewableItems }: { viewableItems: ViewToken[] }) => {
      if (viewableItems.length > 0) {
        setCurrentIndex(viewableItems[0].index || 0);
      }
    }
  ).current;

  const handleNext = () => {
    if (currentIndex < slides.length - 1) {
      flatListRef.current?.scrollToIndex({ index: currentIndex + 1 });
    } else {
      handleGetStarted();
    }
  };

  const handleSkip = () => {
    handleGetStarted();
  };

  const handleGetStarted = async () => {
    // DRAMATIC CONFETTI EXPLOSION!
    confettiRef.current?.shoot();

    // Wait for confetti drama, then navigate
    setTimeout(async () => {
      await setHasCompletedOnboarding(true);
      navigation.replace('Login');
    }, 800);
  };

  const renderSlide = ({ item, index }: { item: OnboardingSlide; index: number }) => (
    <View style={styles.slide}>
      {/* LIQUID BLOB BACKGROUND - Morphing organic shapes (Native) or Gradient (Web) */}
      {Platform.OS !== 'web' && LiquidBackground ? (
        <LiquidBackground
          colors={item.blobColors}
          blobCount={6}
          speed="normal"
          intensity="dramatic"
        />
      ) : (
        <LinearGradient
          colors={item.blobColors}
          style={StyleSheet.absoluteFillObject}
        />
      )}

      {/* 3D FLIP CARD for content (Native) or Simple Card (Web) */}
      <View style={styles.slideContent}>
        {Platform.OS !== 'web' && FlipCard3D ? (
          <FlipCard3D
            flipOnPress={false}
            style={styles.cardContainer}
            frontContent={
              <View style={styles.contentCard}>
                <Text style={styles.iconLarge}>{item.icon}</Text>
                <Text style={styles.title}>{item.title}</Text>
                <Text style={styles.description}>{item.description}</Text>
              </View>
            }
            backContent={
              <View style={styles.contentCard}>
                <Text style={styles.title}>✨</Text>
              </View>
            }
          />
        ) : (
          <View style={styles.contentCard}>
            <Text style={styles.iconLarge}>{item.icon}</Text>
            <Text style={styles.title}>{item.title}</Text>
            <Text style={styles.description}>{item.description}</Text>
          </View>
        )}
      </View>
    </View>
  );

  return (
    <View style={styles.container}>
      {/* CONFETTI EXPLOSION - Hidden until triggered */}
      <ConfettiExplosion
        ref={confettiRef}
        colors={CONFETTI_THEMES.celebration}
        count={400}
      />

      {/* Slides with LIQUID BACKGROUNDS */}
      <FlatList
        ref={flatListRef}
        data={slides}
        renderItem={renderSlide}
        keyExtractor={(item) => item.id}
        horizontal
        pagingEnabled
        showsHorizontalScrollIndicator={false}
        onViewableItemsChanged={onViewableItemsChanged}
        viewabilityConfig={viewabilityConfig}
      />

      {/* Bottom UI Overlay */}
      <View style={styles.bottomOverlay}>
        {/* Pagination Dots with SPRING */}
        <View style={styles.pagination}>
          {slides.map((_, index) => (
            <View
              key={index}
              style={[
                styles.dot,
                index === currentIndex && styles.activeDot,
              ]}
            />
          ))}
        </View>

        {/* Actions with SPRING BUTTONS */}
        <View style={styles.bottomContainer}>
          {currentIndex < slides.length - 1 ? (
            <View style={styles.buttonRow}>
              <SpringButton onPress={handleSkip} style={styles.skipButton}>
                <Text style={styles.skipText}>تخطي</Text>
              </SpringButton>
              <SpringButton onPress={handleNext} style={styles.nextButton}>
                <Text style={styles.nextText}>التالي</Text>
              </SpringButton>
            </View>
          ) : (
            <SpringButton onPress={handleGetStarted} style={styles.startButton}>
              <Text style={styles.startText}>ابدأ الآن 🎉</Text>
            </SpringButton>
          )}
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000', // Fallback color
  },
  slide: {
    width,
    flex: 1,
  },
  slideContent: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: Spacing.xl,
  },
  cardContainer: {
    width: width * 0.85,
    height: 400,
  },
  contentCard: {
    flex: 1,
    backgroundColor: 'rgba(255, 255, 255, 0.15)',
    borderRadius: 30,
    padding: Spacing.xxl,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 2,
    borderColor: 'rgba(255, 255, 255, 0.3)',
    ...Colors.shadow.xl,
  },
  iconLarge: {
    fontSize: 100,
    marginBottom: Spacing.xl,
  },
  title: {
    ...Typography.h1,
    fontSize: 36,
    fontWeight: '800',
    color: Colors.white,
    textAlign: 'center',
    marginBottom: Spacing.lg,
    textShadowColor: 'rgba(0, 0, 0, 0.4)',
    textShadowOffset: { width: 0, height: 3 },
    textShadowRadius: 6,
  },
  description: {
    ...Typography.body,
    fontSize: 18,
    color: Colors.white,
    textAlign: 'center',
    lineHeight: 30,
    opacity: 0.95,
    textShadowColor: 'rgba(0, 0, 0, 0.3)',
    textShadowOffset: { width: 0, height: 1 },
    textShadowRadius: 3,
  },
  bottomOverlay: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    backgroundColor: 'rgba(0, 0, 0, 0.3)', // Subtle overlay
  },
  pagination: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: Spacing.lg,
  },
  dot: {
    width: 12,
    height: 12,
    borderRadius: 6,
    backgroundColor: 'rgba(255, 255, 255, 0.3)',
    marginHorizontal: 6,
  },
  activeDot: {
    width: 40,
    backgroundColor: Colors.white,
  },
  bottomContainer: {
    paddingHorizontal: Spacing.lg,
    paddingBottom: Spacing.xl + 10,
  },
  buttonRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    gap: Spacing.md,
  },
  skipButton: {
    flex: 1,
    paddingVertical: Spacing.lg,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    borderRadius: 16,
    alignItems: 'center',
    borderWidth: 2,
    borderColor: 'rgba(255, 255, 255, 0.3)',
  },
  skipText: {
    ...Typography.button,
    fontSize: 16,
    color: Colors.white,
    fontWeight: '700',
  },
  nextButton: {
    flex: 1,
    paddingVertical: Spacing.lg,
    backgroundColor: Colors.white,
    borderRadius: 16,
    alignItems: 'center',
    ...Colors.shadow.lg,
  },
  nextText: {
    ...Typography.button,
    fontSize: 16,
    color: Colors.primary.main,
    fontWeight: '800',
  },
  startButton: {
    width: '100%',
    paddingVertical: Spacing.lg,
    backgroundColor: Colors.white,
    borderRadius: 16,
    alignItems: 'center',
    ...Colors.shadow.xl,
  },
  startText: {
    ...Typography.button,
    fontSize: 18,
    color: Colors.primary.main,
    fontWeight: '800',
  },
});
