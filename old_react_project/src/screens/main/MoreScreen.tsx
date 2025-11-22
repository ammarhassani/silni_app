/**
 * MORE SCREEN
 *
 * Settings and additional options:
 * - Profile
 * - Subscription status
 * - Settings
 * - Help & Support
 * - About
 * - Sign out
 */

import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  SafeAreaView,
  Alert,
} from 'react-native';
import { useAuthStore } from '@/store/authStore';
import { Colors } from '@/constants/colors';
import { Typography } from '@/constants/typography';
import { Spacing } from '@/constants/spacing';

export default function MoreScreen() {
  const { user, signOut } = useAuthStore();

  const handleSignOut = () => {
    Alert.alert(
      'تسجيل الخروج',
      'هل أنت متأكد أنك تريد تسجيل الخروج؟',
      [
        { text: 'إلغاء', style: 'cancel' },
        {
          text: 'تسجيل الخروج',
          style: 'destructive',
          onPress: async () => {
            await signOut();
          },
        },
      ]
    );
  };

  const MenuItem = ({
    icon,
    title,
    onPress,
    badge,
  }: {
    icon: string;
    title: string;
    onPress: () => void;
    badge?: string;
  }) => (
    <TouchableOpacity style={styles.menuItem} onPress={onPress}>
      <View style={styles.menuItemContent}>
        <View style={styles.menuItemLeft}>
          <Text style={styles.menuItemIcon}>{icon}</Text>
          <Text style={styles.menuItemTitle}>{title}</Text>
        </View>
        {badge && (
          <View style={styles.badge}>
            <Text style={styles.badgeText}>{badge}</Text>
          </View>
        )}
      </View>
    </TouchableOpacity>
  );

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView style={styles.scrollView}>
        {/* Header */}
        <View style={styles.header}>
          <Text style={styles.title}>المزيد</Text>
        </View>

        {/* Profile Card */}
        <TouchableOpacity style={styles.profileCard}>
          <View style={styles.profileInfo}>
            <View style={styles.profilePicture}>
              <Text style={styles.profileInitial}>
                {user?.fullName?.charAt(0) || '👤'}
              </Text>
            </View>
            <View>
              <Text style={styles.profileName}>{user?.fullName}</Text>
              <Text style={styles.profileEmail}>{user?.email}</Text>
            </View>
          </View>
          <View
            style={[
              styles.subscriptionBadge,
              user?.subscriptionStatus === 'premium' && styles.premiumBadge,
            ]}
          >
            <Text style={styles.subscriptionText}>
              {user?.subscriptionStatus === 'premium' ? '⭐ بريميوم' : 'مجاني'}
            </Text>
          </View>
        </TouchableOpacity>

        {/* Menu Sections */}
        <View style={styles.section}>
          <MenuItem icon="👤" title="الملف الشخصي" onPress={() => {}} />
          <MenuItem icon="🔔" title="الإشعارات" onPress={() => {}} />
          <MenuItem icon="🌙" title="المظهر" onPress={() => {}} />
          <MenuItem icon="🌐" title="اللغة" onPress={() => {}} />
        </View>

        <View style={styles.section}>
          <MenuItem
            icon="⭐"
            title="الترقية إلى بريميوم"
            onPress={() => {}}
            badge="جديد"
          />
          <MenuItem icon="📖" title="دليل الاستخدام" onPress={() => {}} />
          <MenuItem icon="💬" title="الدعم الفني" onPress={() => {}} />
          <MenuItem icon="⭐" title="قيّم التطبيق" onPress={() => {}} />
        </View>

        <View style={styles.section}>
          <MenuItem icon="📄" title="الشروط والأحكام" onPress={() => {}} />
          <MenuItem icon="🔒" title="سياسة الخصوصية" onPress={() => {}} />
          <MenuItem icon="ℹ️" title="عن التطبيق" onPress={() => {}} />
        </View>

        {/* Sign Out Button */}
        <TouchableOpacity style={styles.signOutButton} onPress={handleSignOut}>
          <Text style={styles.signOutText}>تسجيل الخروج</Text>
        </TouchableOpacity>

        {/* App Version */}
        <Text style={styles.version}>الإصدار 1.0.0</Text>
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
  profileCard: {
    backgroundColor: Colors.white,
    borderRadius: 16,
    padding: Spacing.lg,
    marginHorizontal: Spacing.lg,
    marginBottom: Spacing.lg,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  profileInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: Spacing.md,
  },
  profilePicture: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: Colors.primary.main,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: Spacing.md,
  },
  profileInitial: {
    fontSize: 24,
    color: Colors.white,
  },
  profileName: {
    ...Typography.h3,
    color: Colors.text.primary,
  },
  profileEmail: {
    ...Typography.caption,
    color: Colors.text.secondary,
    marginTop: Spacing.xs,
  },
  subscriptionBadge: {
    backgroundColor: Colors.background.light,
    paddingVertical: Spacing.xs,
    paddingHorizontal: Spacing.md,
    borderRadius: 20,
    alignSelf: 'flex-start',
  },
  premiumBadge: {
    backgroundColor: Colors.gold.lighter,
  },
  subscriptionText: {
    ...Typography.caption,
    fontWeight: '600',
    color: Colors.text.primary,
  },
  section: {
    backgroundColor: Colors.white,
    borderRadius: 16,
    marginHorizontal: Spacing.lg,
    marginBottom: Spacing.md,
    overflow: 'hidden',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  menuItem: {
    paddingVertical: Spacing.md,
    paddingHorizontal: Spacing.lg,
    borderBottomWidth: 1,
    borderBottomColor: Colors.background.light,
  },
  menuItemContent: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  menuItemLeft: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  menuItemIcon: {
    fontSize: 20,
    marginRight: Spacing.md,
  },
  menuItemTitle: {
    ...Typography.body,
    color: Colors.text.primary,
  },
  badge: {
    backgroundColor: Colors.primary.main,
    paddingVertical: 2,
    paddingHorizontal: Spacing.sm,
    borderRadius: 12,
  },
  badgeText: {
    ...Typography.caption,
    fontSize: 10,
    color: Colors.white,
    fontWeight: 'bold',
  },
  signOutButton: {
    backgroundColor: Colors.error.lighter,
    marginHorizontal: Spacing.lg,
    marginVertical: Spacing.lg,
    paddingVertical: Spacing.md,
    borderRadius: 12,
    alignItems: 'center',
  },
  signOutText: {
    ...Typography.button,
    color: Colors.error.main,
  },
  version: {
    ...Typography.caption,
    color: Colors.text.disabled,
    textAlign: 'center',
    marginBottom: Spacing.xl,
  },
});
