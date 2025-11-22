/**
 * RELATIVES SCREEN
 *
 * List of all relatives with:
 * - Search functionality
 * - Filter by priority/relationship
 * - Add new relative button
 */

import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  TextInput,
  SafeAreaView,
} from 'react-native';
import { useAuthStore } from '@/store/authStore';
import { Colors } from '@/constants/colors';
import { Typography } from '@/constants/typography';
import { Spacing } from '@/constants/spacing';

export default function RelativesScreen() {
  const { user } = useAuthStore();
  const [searchQuery, setSearchQuery] = useState('');

  // Placeholder data - will be replaced with real data from Firestore
  const relatives = [];

  return (
    <SafeAreaView style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.title}>الأقارب</Text>
      </View>

      {/* Search Bar */}
      <View style={styles.searchContainer}>
        <TextInput
          style={styles.searchInput}
          placeholder="ابحث عن قريب..."
          placeholderTextColor={Colors.text.disabled}
          value={searchQuery}
          onChangeText={setSearchQuery}
          textAlign="right"
        />
        <Text style={styles.searchIcon}>🔍</Text>
      </View>

      {/* Empty State */}
      {relatives.length === 0 && (
        <View style={styles.emptyState}>
          <Text style={styles.emptyStateIcon}>👥</Text>
          <Text style={styles.emptyStateTitle}>لا توجد أقارب بعد</Text>
          <Text style={styles.emptyStateText}>
            ابدأ بإضافة أقاربك للحفاظ على صلة الرحم
          </Text>
        </View>
      )}

      {/* Add Button */}
      <TouchableOpacity style={styles.addButton}>
        <Text style={styles.addButtonText}>➕ إضافة قريب</Text>
      </TouchableOpacity>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background.light,
  },
  header: {
    padding: Spacing.lg,
    paddingTop: Spacing.xl,
  },
  title: {
    ...Typography.h1,
    color: Colors.text.primary,
  },
  searchContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.white,
    marginHorizontal: Spacing.lg,
    marginBottom: Spacing.md,
    borderRadius: 12,
    paddingHorizontal: Spacing.md,
  },
  searchIcon: {
    fontSize: 20,
    marginRight: Spacing.sm,
  },
  searchInput: {
    flex: 1,
    paddingVertical: Spacing.md,
    ...Typography.body,
    color: Colors.text.primary,
  },
  emptyState: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: Spacing.xl,
  },
  emptyStateIcon: {
    fontSize: 80,
    marginBottom: Spacing.lg,
  },
  emptyStateTitle: {
    ...Typography.h2,
    color: Colors.text.primary,
    marginBottom: Spacing.sm,
  },
  emptyStateText: {
    ...Typography.body,
    color: Colors.text.secondary,
    textAlign: 'center',
    lineHeight: 24,
  },
  addButton: {
    backgroundColor: Colors.primary.main,
    marginHorizontal: Spacing.lg,
    marginBottom: Spacing.lg,
    paddingVertical: Spacing.md,
    borderRadius: 12,
    alignItems: 'center',
  },
  addButtonText: {
    ...Typography.button,
    color: Colors.white,
  },
});
