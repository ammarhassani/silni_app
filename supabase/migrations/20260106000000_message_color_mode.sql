-- Add color_mode column to admin_in_app_messages
-- Allows admin to choose between theme-compliant colors or custom colors

ALTER TABLE admin_in_app_messages
ADD COLUMN IF NOT EXISTS color_mode TEXT DEFAULT 'theme'
CHECK (color_mode IN ('theme', 'custom'));

-- Update existing messages to use 'custom' if they have non-default colors
UPDATE admin_in_app_messages
SET color_mode = 'custom'
WHERE background_color != '#FFFFFF'
   OR text_color != '#1F2937'
   OR background_gradient IS NOT NULL;

COMMENT ON COLUMN admin_in_app_messages.color_mode IS 'theme = adapts to user theme, custom = uses configured colors';
