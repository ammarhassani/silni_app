-- Add overlay opacity control for banner/background images
-- Allows controlling dark overlay on images:
-- 0 = promotional image (clear, no overlay)
-- 0.3 = subtle background (default)
-- 0.6 = dark background (for text readability)

ALTER TABLE admin_in_app_messages
ADD COLUMN IF NOT EXISTS image_overlay_opacity decimal(3,2) DEFAULT 0.3;

COMMENT ON COLUMN admin_in_app_messages.image_overlay_opacity IS
'Dark overlay opacity on images: 0=promotional (clear), 0.3=subtle background, 0.6=dark background';
