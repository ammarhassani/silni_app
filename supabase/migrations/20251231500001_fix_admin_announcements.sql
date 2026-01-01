-- =====================================================
-- Fix Admin Announcements Table
-- Add missing columns to existing table
-- =====================================================

-- Add columns if they don't exist
DO $$
BEGIN
  -- Check if title column exists (old schema) vs title_ar (new schema)
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'admin_announcements' AND column_name = 'title'
  ) THEN
    -- Old schema exists, rename columns
    ALTER TABLE admin_announcements RENAME COLUMN title TO title_ar;
    ALTER TABLE admin_announcements RENAME COLUMN body TO body_ar;
  END IF;

  -- Add title_en if not exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'admin_announcements' AND column_name = 'title_en'
  ) THEN
    ALTER TABLE admin_announcements ADD COLUMN title_en TEXT;
  END IF;

  -- Add body_en if not exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'admin_announcements' AND column_name = 'body_en'
  ) THEN
    ALTER TABLE admin_announcements ADD COLUMN body_en TEXT;
  END IF;

  -- Add deep_link if not exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'admin_announcements' AND column_name = 'deep_link'
  ) THEN
    ALTER TABLE admin_announcements ADD COLUMN deep_link TEXT;
  END IF;

  -- Add deep_link_params if not exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'admin_announcements' AND column_name = 'deep_link_params'
  ) THEN
    ALTER TABLE admin_announcements ADD COLUMN deep_link_params JSONB DEFAULT '{}';
  END IF;

  -- Add notification_icon if not exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'admin_announcements' AND column_name = 'notification_icon'
  ) THEN
    ALTER TABLE admin_announcements ADD COLUMN notification_icon TEXT DEFAULT 'announcement';
  END IF;

  -- Add notification_sound if not exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'admin_announcements' AND column_name = 'notification_sound'
  ) THEN
    ALTER TABLE admin_announcements ADD COLUMN notification_sound TEXT DEFAULT 'default';
  END IF;

  -- Add priority if not exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'admin_announcements' AND column_name = 'priority'
  ) THEN
    ALTER TABLE admin_announcements ADD COLUMN priority TEXT DEFAULT 'high';
  END IF;

  -- Add total_recipients if not exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'admin_announcements' AND column_name = 'total_recipients'
  ) THEN
    ALTER TABLE admin_announcements ADD COLUMN total_recipients INTEGER DEFAULT 0;
  END IF;

  -- Add successful_sends if not exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'admin_announcements' AND column_name = 'successful_sends'
  ) THEN
    ALTER TABLE admin_announcements ADD COLUMN successful_sends INTEGER DEFAULT 0;
  END IF;

  -- Add failed_sends if not exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'admin_announcements' AND column_name = 'failed_sends'
  ) THEN
    ALTER TABLE admin_announcements ADD COLUMN failed_sends INTEGER DEFAULT 0;
  END IF;

  -- Add sent_by if not exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'admin_announcements' AND column_name = 'sent_by'
  ) THEN
    ALTER TABLE admin_announcements ADD COLUMN sent_by UUID;
  END IF;

  -- Add created_by if not exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'admin_announcements' AND column_name = 'created_by'
  ) THEN
    ALTER TABLE admin_announcements ADD COLUMN created_by UUID;
  END IF;

END $$;

-- Create or replace the is_admin function (in case it doesn't exist)
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
DECLARE
  user_role TEXT;
BEGIN
  SELECT role INTO user_role
  FROM profiles
  WHERE id = auth.uid();
  RETURN user_role = 'admin';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Add RLS policies (drop first if exist)
DROP POLICY IF EXISTS "Admins can view announcements" ON admin_announcements;
DROP POLICY IF EXISTS "Admins can create announcements" ON admin_announcements;
DROP POLICY IF EXISTS "Admins can update announcements" ON admin_announcements;
DROP POLICY IF EXISTS "Admins can delete announcements" ON admin_announcements;

CREATE POLICY "Admins can view announcements" ON admin_announcements
  FOR SELECT USING (is_admin());

CREATE POLICY "Admins can create announcements" ON admin_announcements
  FOR INSERT WITH CHECK (is_admin());

CREATE POLICY "Admins can update announcements" ON admin_announcements
  FOR UPDATE USING (is_admin());

CREATE POLICY "Admins can delete announcements" ON admin_announcements
  FOR DELETE USING (is_admin());

-- Grant execute on helper function
GRANT EXECUTE ON FUNCTION is_admin() TO authenticated;

-- Seed sample data (if table is empty)
INSERT INTO admin_announcements (title_ar, title_en, body_ar, body_en, deep_link, status, target_users)
SELECT
  'مرحباً بك في صِلني!',
  'Welcome to Silni!',
  'شكراً لانضمامك إلينا. اكتشف ميزات التطبيق الجديدة!',
  'Thank you for joining us. Discover new app features!',
  '/home',
  'draft',
  'all'
WHERE NOT EXISTS (SELECT 1 FROM admin_announcements LIMIT 1);
