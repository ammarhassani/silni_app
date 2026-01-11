-- ============================================
-- SCHEMA SYNC: Add missing columns from staging
-- ============================================

-- USERS TABLE - Add missing columns
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS freeze_auto_use BOOLEAN DEFAULT true;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS last_interaction_at TIMESTAMPTZ;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS onboarding_metadata JSONB;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS streak_warning_sent BOOLEAN DEFAULT false;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS subscription_product_id TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS subscription_expires_at TIMESTAMPTZ;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS trial_started_at TIMESTAMPTZ;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS trial_used BOOLEAN DEFAULT false;

-- REMINDER_SCHEDULES TABLE - Add missing columns
ALTER TABLE public.reminder_schedules ADD COLUMN IF NOT EXISTS relative_id UUID REFERENCES public.relatives(id) ON DELETE CASCADE;
ALTER TABLE public.reminder_schedules ADD COLUMN IF NOT EXISTS notification_hour INTEGER;
ALTER TABLE public.reminder_schedules ADD COLUMN IF NOT EXISTS days_of_week INTEGER[];
ALTER TABLE public.reminder_schedules ADD COLUMN IF NOT EXISTS interval_days INTEGER;
ALTER TABLE public.reminder_schedules ADD COLUMN IF NOT EXISTS custom_title TEXT;
ALTER TABLE public.reminder_schedules ADD COLUMN IF NOT EXISTS custom_message TEXT;
ALTER TABLE public.reminder_schedules ADD COLUMN IF NOT EXISTS last_sent TIMESTAMPTZ;
