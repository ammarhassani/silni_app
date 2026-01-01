-- Fix routes that require parameters - they shouldn't be selectable in MOTD
-- These routes need an ID to work (e.g., /relative/:id, /edit-relative/:id)

-- Mark parameterized routes as inactive (won't show in route selector)
UPDATE admin_app_routes
SET is_active = false,
    description_ar = 'يتطلب معرف (ID) - غير متاح للاختيار المباشر'
WHERE route_key IN ('relative_detail', 'edit_relative');

-- Also update the path to show they need parameters
UPDATE admin_app_routes
SET path = '/relative/:id'
WHERE route_key = 'relative_detail';

UPDATE admin_app_routes
SET path = '/edit-relative/:id'
WHERE route_key = 'edit_relative';
