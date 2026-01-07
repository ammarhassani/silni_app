-- Add cache config for UI strings and onboarding services

INSERT INTO admin_cache_config (service_key, cache_duration_seconds, description, description_ar) VALUES
('ui_strings', 3600, 'Custom UI text strings and labels', 'نصوص الواجهة والتسميات'),
('onboarding_config', 3600, 'Onboarding screens configuration', 'إعدادات شاشات التأهيل')
ON CONFLICT (service_key) DO NOTHING;
