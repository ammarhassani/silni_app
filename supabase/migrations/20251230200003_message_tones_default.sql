-- Add is_default column to message tones to make default tone configurable

ALTER TABLE admin_message_tones
  ADD COLUMN IF NOT EXISTS is_default BOOLEAN DEFAULT false;

-- Set 'warm' as default tone
UPDATE admin_message_tones
SET is_default = true
WHERE tone_key = 'warm';

-- Add index for quick default lookup
CREATE INDEX IF NOT EXISTS idx_admin_message_tones_default ON admin_message_tones(is_default) WHERE is_default = true;

COMMENT ON COLUMN admin_message_tones.is_default IS 'Marks the default tone to use when no tone is selected';
