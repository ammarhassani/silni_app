/**
 * STATISTICS SCREEN
 *
 * User statistics and progress:
 * - Total interactions
 * - Streak information
 * - Points and level
 * - Achievements
 * - Monthly breakdown
 */

import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  SafeAreaView,
} from 'react-native';
import { useAuthStore } from '@/store/authStore';
import { Colors } from '@/constants/colors';
import { Typography } from '@/constants/typography';
import { Spacing } from '@/constants/spacing';

export default function StatisticsScreen() {
  const { user } = useAuthStore();

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView style={styles.scrollView}>
        {/* Header */}
        <View style={styles.header}>
          <Text style={styles.title}>الإحصائيات</Text>
        </View>

        {/* Level Card */}
        <View style={styles.card}>
          <View style={styles.levelContainer}>
            <Text style={styles.levelNumber}>{user?.level || 1}</Text>
            <Text style={styles.levelLabel}>المستوى</Text>
          </View>
          <View style={styles.pointsContainer}>
            <Text style={styles.pointsText}>
              {user?.points || 0} نقطة
            </Text>
          </View>
        </View>

        {/* Stats Grid */}
        <View style={styles.statsGrid}>
          <View style={styles.statCard}>
            <Text style={styles.statIcon}>🔥</Text>
            <Text style={styles.statNumber}>{user?.currentStreak || 0}</Text>
            <Text style={styles.statLabel}>سلسلة حالية</Text>
          </View>
          <View style={styles.statCard}>
            <Text style={styles.statIcon}>📊</Text>
            <Text style={styles.statNumber}>{user?.totalInteractions || 0}</Text>
            <Text style={styles.statLabel}>تواصل</Text>
          </View>
        </View>

        <View style={styles.statsGrid}>
          <View style={styles.statCard}>
            <Text style={styles.statIcon}>⭐</Text>
            <Text style={styles.statNumber}>{user?.longestStreak || 0}</Text>
            <Text style={styles.statLabel}>أطول سلسلة</Text>
          </View>
          <View style={styles.statCard}>
            <Text style={styles.statIcon}>🏆</Text>
            <Text style={styles.statNumber}>{user?.badges?.length || 0}</Text>
            <Text style={styles.statLabel}>شارة</Text>
          </View>
        </View>

        {/* Achievements Section */}
        <View style={styles.card}>
          <Text style={styles.sectionTitle}>الإنجازات</Text>
          <View style={styles.emptyState}>
            <Text style={styles.emptyStateIcon}>🏆</Text>
            <Text style={styles.emptyStateText}>
              لم تحصل على أي إنجازات بعد
            </Text>
          </View>
        </View>

        {/* Monthly Stats */}
        <View style={styles.card}>
          <Text style={styles.sectionTitle}>إحصائيات الشهر</Text>
          <View style={styles.emptyState}>
            <Text style={styles.emptyStateIcon}>📈</Text>
            <Text style={styles.emptyStateText}>
              لا توجد بيانات لهذا الشهر
            </Text>
          </View>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background.light,
  },
  scrollView: {
    flex: 1,
  },
  header: {
    padding: Spacing.lg,
    paddingTop: Spacing.xl,
  },
  title: {
    ...Typography.h1,
    color: Colors.text.primary,
  },
  card: {
    backgroundColor: Colors.white,
    borderRadius: 16,
    padding: Spacing.lg,
    marginHorizontal: Spacing.lg,
    marginBottom: Spacing.md,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  levelContainer: {
    alignItems: 'center',
    paddingVertical: Spacing.lg,
  },
  levelNumber: {
    fontSize: 64,
    fontWeight: 'bold',
    color: Colors.gold.main,
  },
  levelLabel: {
    ...Typography.h3,
    color: Colors.text.secondary,
    marginTop: Spacing.xs,
  },
  pointsContainer: {
    alignItems: 'center',
    paddingTop: Spacing.md,
    borderTopWidth: 1,
    borderTopColor: Colors.border,
  },
  pointsText: {
    ...Typography.body,
    color: Colors.text.secondary,
    fontWeight: '600',
  },
  statsGrid: {
    flexDirection: 'row',
    paddingHorizontal: Spacing.lg,
    marginBottom: Spacing.md,
    gap: Spacing.md,
  },
  statCard: {
    flex: 1,
    backgroundColor: Colors.white,
    borderRadius: 16,
    padding: Spacing.lg,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  statIcon: {
    fontSize: 32,
    marginBottom: Spacing.sm,
  },
  statNumber: {
    fontSize: 32,
    fontWeight: 'bold',
    color: Colors.primary.main,
  },
  statLabel: {
    ...Typography.caption,
    color: Colors.text.secondary,
    marginTop: Spacing.xs,
  },
  sectionTitle: {
    ...Typography.h3,
    color: Colors.text.primary,
    marginBottom: Spacing.md,
  },
  emptyState: {
    alignItems: 'center',
    paddingVertical: Spacing.xl,
  },
  emptyStateIcon: {
    fontSize: 48,
    marginBottom: Spacing.sm,
  },
  emptyStateText: {
    ...Typography.body,
    color: Colors.text.secondary,
  },
});
