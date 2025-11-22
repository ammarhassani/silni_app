/**
 * HOME SCREEN - CROSS-PLATFORM WOW UI 🚀
 *
 * Beautiful dashboard with all WOW features:
 * - Liquid/Blob morphing background (SVG + Reanimated)
 * - Glassmorphism with expo-blur (works in Expo Go)
 * - 3D card flips
 * - Particle confetti
 * - Spring physics
 * - Parallax scrolling
 * - Works 100% in Expo Go!
 */

import React, { useRef, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  SafeAreaView,
  Dimensions,
  Platform,
  ScrollView,
} from 'react-native';
import { useAuthStore } from '@/store/authStore';
import { Colors } from '@/constants/colors';
import { Typography } from '@/constants/typography';
import { Spacing } from '@/constants/spacing';
import {
  FadeInView,
  ScaleButton,
} from '@/components/animated';
import { GlassCard } from '@/components/ui';
import { LinearGradient } from 'expo-linear-gradient';

// Conditionally import native-dependent components
let LiquidBackground: any = null;
let FlipCard3D: any = null;
let ParallaxScroll: any = null;
let ParallaxLayer: any = null;
let ConfettiExplosion: any = null;

if (Platform.OS !== 'web') {
  const animated = require('@/components/animated');
  LiquidBackground = animated.LiquidBackground;
  FlipCard3D = animated.FlipCard3D;
  ParallaxScroll = animated.ParallaxScroll;
  ParallaxLayer = animated.ParallaxLayer;
  ConfettiExplosion = animated.ConfettiExplosion;
}

const { width } = Dimensions.get('window');

// Web-safe wrapper components
const SafeParallaxScroll = Platform.OS === 'web'
  ? ({ children, style }: any) => <ScrollView style={style}>{children}</ScrollView>
  : ParallaxScroll;

const SafeParallaxLayer = Platform.OS === 'web'
  ? ({ children }: any) => <>{children}</>
  : ParallaxLayer;

export default function HomeScreen() {
  const { user } = useAuthStore();
  const confettiRef = useRef<any>(null);

  // Celebrate streak milestones
  useEffect(() => {
    if (Platform.OS === 'web') return;
    const streak = user?.currentStreak || 0;
    if (streak > 0 && streak % 7 === 0) {
      setTimeout(() => {
        confettiRef.current?.shoot();
      }, 1000);
    }
  }, [user?.currentStreak]);

  return (
    <View style={styles.container}>
      {/* Liquid Morphing Background - Native only */}
      {Platform.OS !== 'web' && LiquidBackground && (
        <LiquidBackground
          colors={['#10B981', '#059669', '#047857', '#065F46']}
          blobCount={6}
          speed="normal"
          intensity="dramatic"
        />
      )}

      {/* Gradient background for web */}
      {Platform.OS === 'web' && (
        <LinearGradient
          colors={['#10B981', '#059669', '#047857']}
          style={StyleSheet.absoluteFillObject}
        />
      )}

      {/* Confetti - Native only */}
      {Platform.OS !== 'web' && ConfettiExplosion && (
        <ConfettiExplosion
          ref={confettiRef}
          colors={['#10B981', '#F59E0B', '#8B5CF6', '#EC4899']}
          count={50}
          origin={{ x: width / 2, y: 100 }}
        />
      )}

      <SafeAreaView style={styles.safeArea}>
        <SafeParallaxScroll style={styles.scrollView}>
          {/* Header with Parallax */}
          <SafeParallaxLayer speed={0.3} opacity={[1, 0.5]}>
            <FadeInView delay={50}>
              <View style={styles.header}>
                <View>
                  <Text style={styles.greeting}>السلام عليكم</Text>
                  <Text style={styles.userName}>{user?.fullName || 'مستخدم'}</Text>
                </View>
                <ScaleButton>
                  <GlassCard style={styles.profilePicture} intensity={90}>
                    <Text style={styles.profileInitial}>
                      {user?.fullName?.charAt(0) || '👤'}
                    </Text>
                  </GlassCard>
                </ScaleButton>
              </View>
            </FadeInView>
          </SafeParallaxLayer>

          {/* 3D Flippable Streak Card - Native only, simple card on web */}
          <SafeParallaxLayer speed={0.5}>
            <FadeInView delay={100}>
              {Platform.OS !== 'web' && FlipCard3D ? (
                <View style={styles.cardWrapper}>
                  <FlipCard3D
                    flipOnPress={true}
                    frontContent={
                      <GlassCard style={styles.card} intensity={95}>
                        <View style={styles.cardHeader}>
                          <Text style={styles.cardTitle}>سلسلة التواصل</Text>
                          <Text style={styles.cardIcon}>🔥</Text>
                        </View>
                        <View style={styles.streakContainer}>
                          <Text style={styles.streakNumber}>{user?.currentStreak || 0}</Text>
                          <Text style={styles.streakLabel}>يوم متواصل</Text>
                        </View>
                        <Text style={styles.streakSubtext}>اضغط للمزيد ✨</Text>
                      </GlassCard>
                    }
                    backContent={
                      <GlassCard style={styles.card} intensity={95}>
                        <View style={styles.cardHeader}>
                          <Text style={styles.cardTitle}>إحصائيات السلسلة</Text>
                          <Text style={styles.cardIcon}>📊</Text>
                        </View>
                        <View style={styles.streakStatsContainer}>
                          <View style={styles.streakStatRow}>
                            <Text style={styles.streakStatLabel}>أطول سلسلة</Text>
                            <Text style={styles.streakStatValue}>
                              {user?.longestStreak || 0} يوم
                            </Text>
                          </View>
                          <View style={styles.streakStatRow}>
                            <Text style={styles.streakStatLabel}>هذا الشهر</Text>
                            <Text style={styles.streakStatValue}>
                              {user?.currentStreak || 0} يوم
                            </Text>
                          </View>
                        </View>
                        <Text style={styles.streakSubtext}>اضغط للعودة ✨</Text>
                      </GlassCard>
                    }
                  />
                </View>
              ) : (
                <GlassCard style={styles.card} intensity={95}>
                  <View style={styles.cardHeader}>
                    <Text style={styles.cardTitle}>سلسلة التواصل</Text>
                    <Text style={styles.cardIcon}>🔥</Text>
                  </View>
                  <View style={styles.streakContainer}>
                    <Text style={styles.streakNumber}>{user?.currentStreak || 0}</Text>
                    <Text style={styles.streakLabel}>يوم متواصل</Text>
                  </View>
                  <Text style={styles.streakSubtext}>
                    أطول سلسلة: {user?.longestStreak || 0} يوم
                  </Text>
                </GlassCard>
              )}
            </FadeInView>
          </SafeParallaxLayer>

          {/* Today's Reminders */}
          <SafeParallaxLayer speed={0.6}>
            <FadeInView delay={150}>
              <GlassCard style={styles.card} intensity={95}>
                <View style={styles.cardHeader}>
                  <ScaleButton>
                    <Text style={styles.cardLink}>عرض الكل</Text>
                  </ScaleButton>
                  <Text style={styles.cardTitle}>تذكيرات اليوم</Text>
                </View>
                <View style={styles.emptyState}>
                  <Text style={styles.emptyStateIcon}>📅</Text>
                  <Text style={styles.emptyStateText}>لا توجد تذكيرات لليوم</Text>
                </View>
              </GlassCard>
            </FadeInView>
          </SafeParallaxLayer>

          {/* Quick Actions */}
          <SafeParallaxLayer speed={0.7}>
            <FadeInView delay={200}>
              <View style={styles.actionsContainer}>
                <Text style={styles.sectionTitle}>إجراءات سريعة</Text>
                <View style={styles.actionsGrid}>
                  <ScaleButton style={styles.actionButtonWrapper}>
                    <LinearGradient
                      colors={Colors.primary.gradient}
                      start={{ x: 0, y: 0 }}
                      end={{ x: 1, y: 1 }}
                      style={styles.actionButton}
                    >
                      <Text style={styles.actionIcon}>➕</Text>
                      <Text style={styles.actionText}>إضافة قريب</Text>
                    </LinearGradient>
                  </ScaleButton>
                  <ScaleButton style={styles.actionButtonWrapper}>
                    <LinearGradient
                      colors={Colors.accent.gradient}
                      start={{ x: 0, y: 0 }}
                      end={{ x: 1, y: 1 }}
                      style={styles.actionButton}
                    >
                      <Text style={styles.actionIcon}>📝</Text>
                      <Text style={styles.actionText}>تسجيل تواصل</Text>
                    </LinearGradient>
                  </ScaleButton>
                  <ScaleButton style={styles.actionButtonWrapper}>
                    <LinearGradient
                      colors={Colors.gold.gradient}
                      start={{ x: 0, y: 0 }}
                      end={{ x: 1, y: 1 }}
                      style={styles.actionButton}
                    >
                      <Text style={styles.actionIcon}>🔔</Text>
                      <Text style={styles.actionText}>إضافة تذكير</Text>
                    </LinearGradient>
                  </ScaleButton>
                  <ScaleButton style={styles.actionButtonWrapper}>
                    <LinearGradient
                      colors={['#06B6D4', '#3B82F6']}
                      start={{ x: 0, y: 0 }}
                      end={{ x: 1, y: 1 }}
                      style={styles.actionButton}
                    >
                      <Text style={styles.actionIcon}>📊</Text>
                      <Text style={styles.actionText}>الإحصائيات</Text>
                    </LinearGradient>
                  </ScaleButton>
                </View>
              </View>
            </FadeInView>
          </SafeParallaxLayer>

          {/* Daily Hadith */}
          <SafeParallaxLayer speed={0.8}>
            <FadeInView delay={250}>
              <GlassCard style={styles.card} intensity={95}>
                <View style={styles.cardHeader}>
                  <Text style={styles.cardTitle}>حديث اليوم</Text>
                  <Text style={styles.cardIcon}>📖</Text>
                </View>
                <View style={styles.hadithContainer}>
                  <Text style={styles.hadithText}>
                    "من أحب أن يُبسط له في رزقه، ويُنسأ له في أثره، فليصل رحمه"
                  </Text>
                  <Text style={styles.hadithSource}>رواه البخاري ومسلم</Text>
                </View>
              </GlassCard>
            </FadeInView>
          </SafeParallaxLayer>

          {/* Statistics Summary */}
          <SafeParallaxLayer speed={0.9}>
            <FadeInView delay={300}>
              <GlassCard style={styles.card} intensity={95}>
                <Text style={styles.cardTitle}>ملخص الإحصائيات</Text>
                <View style={styles.statsGrid}>
                  <ScaleButton style={styles.statItem}>
                    <Text style={styles.statNumber}>{user?.totalInteractions || 0}</Text>
                    <Text style={styles.statLabel}>تواصل</Text>
                  </ScaleButton>
                  <View style={styles.statDivider} />
                  <ScaleButton style={styles.statItem}>
                    <Text style={styles.statNumber}>{user?.points || 0}</Text>
                    <Text style={styles.statLabel}>نقطة</Text>
                  </ScaleButton>
                  <View style={styles.statDivider} />
                  <ScaleButton style={styles.statItem}>
                    <Text style={styles.statNumber}>{user?.level || 1}</Text>
                    <Text style={styles.statLabel}>مستوى</Text>
                  </ScaleButton>
                </View>
              </GlassCard>
            </FadeInView>
          </SafeParallaxLayer>

          <View style={styles.bottomSpacing} />
        </SafeParallaxScroll>
      </SafeAreaView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  safeArea: {
    flex: 1,
  },
  scrollView: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: Spacing.lg,
    paddingTop: Spacing.md,
  },
  cardWrapper: {
    height: 220,
    marginHorizontal: Spacing.lg,
    marginBottom: Spacing.md,
  },
  greeting: {
    ...Typography.body,
    fontSize: 16,
    color: Colors.white,
    opacity: 0.9,
  },
  userName: {
    ...Typography.h2,
    fontSize: 28,
    fontWeight: '700',
    color: Colors.white,
    marginTop: Spacing.xs,
    textShadowColor: 'rgba(0, 0, 0, 0.2)',
    textShadowOffset: { width: 0, height: 1 },
    textShadowRadius: 2,
  },
  profilePicture: {
    width: 56,
    height: 56,
    borderRadius: 28,
    alignItems: 'center',
    justifyContent: 'center',
  },
  profileInitial: {
    ...Typography.h3,
    fontSize: 24,
    color: Colors.white,
  },
  card: {
    padding: Spacing.lg,
    marginHorizontal: Spacing.lg,
    marginBottom: Spacing.md,
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: Spacing.md,
  },
  cardTitle: {
    ...Typography.h3,
    fontSize: 20,
    fontWeight: '700',
    color: Colors.white,
  },
  cardIcon: {
    fontSize: 28,
  },
  cardLink: {
    ...Typography.caption,
    fontSize: 14,
    color: Colors.white,
    fontWeight: '600',
  },
  streakContainer: {
    alignItems: 'center',
    paddingVertical: Spacing.lg,
  },
  streakNumber: {
    fontSize: 64,
    fontWeight: '800',
    color: Colors.white,
    textShadowColor: 'rgba(0, 0, 0, 0.2)',
    textShadowOffset: { width: 0, height: 2 },
    textShadowRadius: 4,
  },
  streakLabel: {
    ...Typography.body,
    fontSize: 18,
    color: Colors.white,
    opacity: 0.9,
    marginTop: Spacing.sm,
  },
  streakSubtext: {
    ...Typography.caption,
    fontSize: 14,
    color: Colors.white,
    opacity: 0.8,
    textAlign: 'center',
  },
  streakStatsContainer: {
    paddingVertical: Spacing.md,
  },
  streakStatRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: Spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: Colors.glass.border,
  },
  streakStatLabel: {
    ...Typography.body,
    fontSize: 16,
    color: Colors.white,
    opacity: 0.9,
  },
  streakStatValue: {
    ...Typography.h3,
    fontSize: 24,
    fontWeight: '700',
    color: Colors.white,
  },
  emptyState: {
    alignItems: 'center',
    paddingVertical: Spacing.xl,
  },
  emptyStateIcon: {
    fontSize: 56,
    marginBottom: Spacing.md,
  },
  emptyStateText: {
    ...Typography.body,
    fontSize: 16,
    color: Colors.white,
    opacity: 0.8,
  },
  actionsContainer: {
    padding: Spacing.lg,
  },
  sectionTitle: {
    ...Typography.h3,
    fontSize: 20,
    fontWeight: '700',
    color: Colors.white,
    marginBottom: Spacing.md,
    textShadowColor: 'rgba(0, 0, 0, 0.2)',
    textShadowOffset: { width: 0, height: 1 },
    textShadowRadius: 2,
  },
  actionsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
  },
  actionButtonWrapper: {
    width: '48%',
    marginBottom: Spacing.md,
  },
  actionButton: {
    borderRadius: 16,
    padding: Spacing.lg,
    alignItems: 'center',
    ...Colors.shadow.md,
  },
  actionIcon: {
    fontSize: 40,
    marginBottom: Spacing.sm,
  },
  actionText: {
    ...Typography.caption,
    fontSize: 14,
    color: Colors.white,
    fontWeight: '700',
  },
  hadithContainer: {
    paddingVertical: Spacing.sm,
  },
  hadithText: {
    ...Typography.body,
    fontSize: 17,
    color: Colors.white,
    lineHeight: 30,
    textAlign: 'right',
    marginBottom: Spacing.md,
  },
  hadithSource: {
    ...Typography.caption,
    fontSize: 14,
    color: Colors.white,
    opacity: 0.8,
    textAlign: 'right',
  },
  statsGrid: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    alignItems: 'center',
    paddingVertical: Spacing.lg,
    marginTop: Spacing.sm,
  },
  statItem: {
    alignItems: 'center',
  },
  statNumber: {
    fontSize: 40,
    fontWeight: '800',
    color: Colors.white,
    textShadowColor: 'rgba(0, 0, 0, 0.2)',
    textShadowOffset: { width: 0, height: 1 },
    textShadowRadius: 2,
  },
  statLabel: {
    ...Typography.caption,
    fontSize: 14,
    color: Colors.white,
    opacity: 0.9,
    marginTop: Spacing.xs,
  },
  statDivider: {
    width: 1,
    height: 50,
    backgroundColor: Colors.glass.border,
  },
  bottomSpacing: {
    height: 100,
  },
});
