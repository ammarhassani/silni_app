-- Add cache config for engagement services

INSERT INTO admin_cache_config (service_key, cache_duration_seconds, description, description_ar) VALUES
('in_app_messages', 300, 'In-app messaging system', 'نظام الرسائل داخل التطبيق'),
('referral_config', 1800, 'Referral program configuration', 'إعدادات برنامج الإحالة')
ON CONFLICT (service_key) DO NOTHING;
