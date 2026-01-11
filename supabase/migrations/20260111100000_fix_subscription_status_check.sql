-- Fix subscription_status CHECK constraint to include 'pro' tier
-- This syncs production with staging

ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_subscription_status_check;

ALTER TABLE public.users ADD CONSTRAINT users_subscription_status_check
  CHECK (subscription_status = ANY (ARRAY['free'::text, 'premium'::text, 'pro'::text]));

-- Also update comment to reflect all tiers
COMMENT ON COLUMN public.users.subscription_status IS 'Current subscription tier: free, premium, or pro';
