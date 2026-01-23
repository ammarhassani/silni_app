-- =====================================================
-- Performance Indexes Migration
-- Adds indexes for frequently queried columns
-- These indexes improve query performance at scale
-- =====================================================

-- =====================================================
-- RELATIVES TABLE INDEXES
-- Frequently queried by user_id for all relative listings
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_relatives_user_id ON relatives(user_id);
CREATE INDEX IF NOT EXISTS idx_relatives_updated_at ON relatives(updated_at DESC);
-- Composite indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_relatives_user_archived ON relatives(user_id, is_archived);
CREATE INDEX IF NOT EXISTS idx_relatives_user_favorite ON relatives(user_id, is_favorite);
CREATE INDEX IF NOT EXISTS idx_relatives_user_priority ON relatives(user_id, priority, full_name);
CREATE INDEX IF NOT EXISTS idx_relatives_last_contact ON relatives(last_contact_date DESC);

-- =====================================================
-- INTERACTIONS TABLE INDEXES
-- Queried by relative_id, user_id, and created_at for
-- timeline views, statistics, and analytics
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_interactions_relative_id ON interactions(relative_id);
CREATE INDEX IF NOT EXISTS idx_interactions_user_relative ON interactions(user_id, relative_id);
CREATE INDEX IF NOT EXISTS idx_interactions_created_at ON interactions(created_at DESC);
-- Additional performance indexes
CREATE INDEX IF NOT EXISTS idx_interactions_user_id ON interactions(user_id);
CREATE INDEX IF NOT EXISTS idx_interactions_user_date ON interactions(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_interactions_relative_date ON interactions(relative_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_interactions_date ON interactions(date DESC);
CREATE INDEX IF NOT EXISTS idx_interactions_type ON interactions(type);

-- =====================================================
-- REMINDER_SCHEDULES TABLE INDEXES
-- Critical for cron jobs that query active reminders
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_reminder_schedules_user_id ON reminder_schedules(user_id);
CREATE INDEX IF NOT EXISTS idx_reminder_schedules_active ON reminder_schedules(is_active);
CREATE INDEX IF NOT EXISTS idx_reminder_schedules_user_active ON reminder_schedules(user_id, is_active);
-- Partial index for active reminders only (used by cron jobs)
CREATE INDEX IF NOT EXISTS idx_reminder_schedules_active_time
  ON reminder_schedules(time, user_id)
  WHERE is_active = true;

-- =====================================================
-- NOTIFICATION_TOKENS TABLE INDEXES
-- Queried by user_id for sending push notifications
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_notification_tokens_user_id ON notification_tokens(user_id);
-- Partial index for active tokens only
CREATE INDEX IF NOT EXISTS idx_notification_tokens_active
  ON notification_tokens(user_id)
  WHERE is_active = true;

-- =====================================================
-- RELATIVE_STREAKS TABLE INDEXES
-- Queried frequently for streak calculations
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_relative_streaks_user_id ON relative_streaks(user_id);
CREATE INDEX IF NOT EXISTS idx_relative_streaks_relative_id ON relative_streaks(relative_id);
-- Partial index for streaks with upcoming deadlines (for warning queries)
CREATE INDEX IF NOT EXISTS idx_relative_streaks_deadline_active
  ON relative_streaks(streak_deadline)
  WHERE current_streak > 0;

-- =====================================================
-- USERS TABLE PERFORMANCE INDEXES
-- Additional indexes for common user queries
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_users_subscription_status ON users(subscription_status);
CREATE INDEX IF NOT EXISTS idx_users_last_interaction ON users(last_interaction_at DESC NULLS LAST);
