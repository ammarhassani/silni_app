-- Add dimension columns for in-app message images
-- These allow specifying width/height for proper image display

-- Add dimension columns for banner image
ALTER TABLE admin_in_app_messages
ADD COLUMN IF NOT EXISTS image_width integer,
ADD COLUMN IF NOT EXISTS image_height integer;

-- Add dimension columns for illustration
ALTER TABLE admin_in_app_messages
ADD COLUMN IF NOT EXISTS illustration_width integer,
ADD COLUMN IF NOT EXISTS illustration_height integer;

-- Add comments for documentation
COMMENT ON COLUMN admin_in_app_messages.image_width IS 'Banner image width in pixels';
COMMENT ON COLUMN admin_in_app_messages.image_height IS 'Banner image height in pixels';
COMMENT ON COLUMN admin_in_app_messages.illustration_width IS 'Illustration width in pixels';
COMMENT ON COLUMN admin_in_app_messages.illustration_height IS 'Illustration height in pixels';
