// Main type definitions for Silni app (based on PRD Section 7)

import { Timestamp } from 'firebase/firestore';

// ====================
// User Types
// ====================

export type ThemeType = 'light' | 'dark' | 'islamic';
export type LanguageType = 'ar' | 'en';
export type SubscriptionStatus = 'free' | 'premium';

export interface User {
  id: string;
  email: string;
  phoneNumber: string | null;
  displayName: string;
  photoURL: string | null;

  // Settings
  language: LanguageType;
  theme: ThemeType;
  notificationsEnabled: boolean;

  // Subscription
  subscriptionStatus: SubscriptionStatus;
  subscriptionStartDate: Timestamp | null;
  subscriptionEndDate: Timestamp | null;

  // Stats (cached)
  totalRelatives: number;
  totalInteractions: number;
  currentStreak: number;
  longestStreak: number;
  level: number;
  xp: number;

  // Metadata
  createdAt: Timestamp;
  updatedAt: Timestamp;
  lastActiveAt: Timestamp;

  // Premium Features
  premiumFeatures: {
    cloudBackup: boolean;
    advancedStats: boolean;
    customThemes: boolean;
  };
}

// ====================
// Relative Types
// ====================

export type RelationshipType =
  | 'father'
  | 'mother'
  | 'brother'
  | 'sister'
  | 'son'
  | 'daughter'
  | 'grandfather_paternal'
  | 'grandfather_maternal'
  | 'grandmother_paternal'
  | 'grandmother_maternal'
  | 'uncle_paternal'
  | 'uncle_maternal'
  | 'aunt_paternal'
  | 'aunt_maternal'
  | 'nephew'
  | 'niece'
  | 'cousin_paternal'
  | 'cousin_maternal'
  | 'other';

export type RelationshipCategory = 'obligatory' | 'recommended';
export type FamilySide = 'paternal' | 'maternal' | 'both';
export type ContactMethod = 'call' | 'visit' | 'message';
export type ContactFrequency = 'daily' | 'weekly' | 'monthly';

export interface PhoneNumber {
  type: 'mobile' | 'home' | 'work';
  number: string;
  isPrimary: boolean;
}

export interface Address {
  street: string;
  city: string;
  country: string;
}

export interface SocialMedia {
  whatsapp?: string;
  twitter?: string;
  instagram?: string;
}

export interface Anniversary {
  name: string;
  date: Timestamp;
  recurring: boolean;
}

export interface CustomReminder {
  type: ContactMethod;
  frequency: ContactFrequency;
  time: string; // "09:00"
  daysOfWeek: number[]; // [0,1,2,3,4,5,6]
  enabled: boolean;
}

export interface Relative {
  id: string;
  userId: string;
  fullName: string;
  nickname: string | null;
  photoURL: string | null;

  // Relationship
  relationshipType: RelationshipType;
  relationshipCategory: RelationshipCategory;
  side: FamilySide;

  // Contact Info
  phoneNumbers: PhoneNumber[];
  email: string | null;
  address: Address | null;
  socialMedia: SocialMedia | null;

  // Important Dates
  birthDate: Timestamp | null;
  anniversaries: Anniversary[];

  // Notes
  notes: string; // Premium feature
  interests: string[];
  healthNotes: string;

  // Preferences
  preferredContactMethod: ContactMethod;
  contactFrequency: ContactFrequency;

  // Stats
  totalInteractions: number;
  lastInteractionDate: Timestamp | null;
  lastInteractionType: string | null;
  daysSinceLastContact: number;

  // Custom Reminders
  customReminders: CustomReminder[];

  // Groups (Premium)
  groups: string[];

  // Metadata
  createdAt: Timestamp;
  updatedAt: Timestamp;
  isArchived: boolean;
  sortOrder: number;
}

// ====================
// Interaction Types
// ====================

export type InteractionType = 'call' | 'visit' | 'message' | 'gift' | 'event' | 'other';
export type InteractionQuality = 'excellent' | 'good' | 'average';
export type InteractionSentiment = 'positive' | 'neutral' | 'negative';
export type SyncStatus = 'synced' | 'pending' | 'failed';

export interface Interaction {
  id: string;
  userId: string;
  relativeId: string;

  // Interaction Details
  type: InteractionType;
  date: Timestamp;
  duration: number | null; // in minutes

  // Quality & Sentiment (Premium)
  quality: InteractionQuality | null;
  sentiment: InteractionSentiment | null;

  // Notes
  notes: string;
  tags: string[];

  // Media
  photos: string[]; // Storage URLs
  audioNotes: string[]; // Storage URLs (Premium)

  // Follow-up
  hasFollowUp: boolean;
  followUpDate: Timestamp | null;
  followUpNote: string | null;

  // Metadata
  createdAt: Timestamp;
  updatedAt: Timestamp;
  syncStatus: SyncStatus;
}

// ====================
// Reminder Types
// ====================

export type ReminderType = 'interaction' | 'birthday' | 'anniversary' | 'custom';
export type ReminderStatus = 'active' | 'completed' | 'dismissed' | 'snoozed';
export type RecurrenceFrequency = 'daily' | 'weekly' | 'monthly' | 'yearly';

export interface Recurrence {
  frequency: RecurrenceFrequency;
  interval: number; // every X days/weeks/months
  endDate: Timestamp | null;
  daysOfWeek: number[] | null; // for weekly
  dayOfMonth: number | null; // for monthly
}

export interface Reminder {
  id: string;
  userId: string;
  relativeId: string | null;

  // Reminder Details
  type: ReminderType;
  title: string;
  message: string;

  // Schedule
  scheduledDate: Timestamp;
  scheduledTime: string; // "09:00"
  recurring: boolean;
  recurrence: Recurrence | null;

  // Status
  status: ReminderStatus;
  completedAt: Timestamp | null;
  snoozedUntil: Timestamp | null;

  // Notification
  notificationId: string | null;
  notificationSent: boolean;

  // Metadata
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

// ====================
// Achievement Types
// ====================

export type AchievementType = 'badge' | 'level' | 'streak' | 'milestone';

export interface Achievement {
  id: string;
  userId: string;

  // Achievement Details
  type: AchievementType;
  achievementId: string;
  title: string;
  description: string;
  icon: string;

  // Progress
  currentProgress: number;
  targetProgress: number;
  isUnlocked: boolean;

  // Reward
  xpReward: number;

  // Dates
  unlockedAt: Timestamp | null;
  createdAt: Timestamp;
}

// ====================
// Statistics Types
// ====================

export type PeriodType = 'daily' | 'weekly' | 'monthly' | 'yearly';

export interface InteractionsByType {
  calls: number;
  visits: number;
  messages: number;
  gifts: number;
  other: number;
}

export interface Statistics {
  id: string; // period identifier (e.g., "2024-03")
  userId: string;
  periodType: PeriodType;

  // Counts
  totalInteractions: number;
  interactionsByType: InteractionsByType;

  // Relatives
  uniqueRelativesContacted: number;
  mostContactedRelativeId: string;
  leastContactedRelativeIds: string[];

  // Streaks
  currentStreak: number;
  streakBroken: boolean;

  // Time Analysis
  averageInteractionsPerDay: number;
  busiestDay: string; // "Monday"
  busiestHour: number; // 14 (2 PM)

  // Quality (Premium)
  averageQuality: number;
  positiveInteractions: number;

  // Generated
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

// ====================
// Subscription Types
// ====================

export type SubscriptionPlatform = 'ios' | 'android';
export type SubscriptionPlanStatus = 'active' | 'cancelled' | 'expired' | 'grace_period';

export interface Subscription {
  id: string;
  userId: string;

  // Subscription Details
  platform: SubscriptionPlatform;
  productId: string;
  purchaseToken: string;

  // Status
  status: SubscriptionPlanStatus;
  startDate: Timestamp;
  currentPeriodEnd: Timestamp;
  cancelAt: Timestamp | null;

  // Payment
  currency: string;
  price: number;

  // Metadata
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
