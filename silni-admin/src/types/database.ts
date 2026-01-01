// Database types for Silni Admin Panel

export interface AdminHadith {
  id: string;
  hadith_text: string;
  source: string;
  narrator: string | null;
  grade: 'صحيح' | 'حسن' | 'ضعيف' | 'موضوع' | null;
  category: string;
  tags: string[];
  is_active: boolean;
  display_priority: number;
  created_at: string;
  updated_at: string;
}

export interface AdminQuote {
  id: string;
  quote_text: string;
  author: string | null;
  source: string | null;
  category: string;
  tags: string[];
  is_active: boolean;
  display_priority: number;
  created_at: string;
  updated_at: string;
}

export interface AdminMOTD {
  id: string;
  title: string;
  message: string;
  type: 'tip' | 'motivation' | 'reminder' | 'announcement' | 'celebration';
  icon: string;
  background_gradient: { start: string; end: string };
  action_text: string | null;
  action_route: string | null;
  start_date: string | null;
  end_date: string | null;
  is_active: boolean;
  display_priority: number;
  created_at: string;
  updated_at: string;
}

export interface AdminBanner {
  id: string;
  title: string;
  description: string | null;
  image_url: string | null;
  background_gradient: { start: string; end: string } | null;
  action_type: 'route' | 'url' | 'action' | 'none';
  action_value: string | null;
  position: 'home_top' | 'home_bottom' | 'profile' | 'reminders';
  target_audience: 'all' | 'free' | 'max' | 'new_users';
  start_date: string | null;
  end_date: string | null;
  is_active: boolean;
  display_priority: number;
  impressions: number;
  clicks: number;
  created_at: string;
  updated_at: string;
}

export interface AdminPointsConfig {
  id: string;
  interaction_type: string;
  display_name_ar: string;
  display_name_en: string | null;
  base_points: number;
  notes_bonus: number;
  photo_bonus: number;
  rating_bonus: number;
  first_of_day_multiplier: number;
  daily_cap: number;
  icon: string;
  color_hex: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface AdminBadge {
  id: string;
  badge_key: string;
  display_name_ar: string;
  display_name_en: string | null;
  description_ar: string;
  description_en: string | null;
  emoji: string;
  category: 'streak' | 'volume' | 'variety' | 'special' | 'milestone';
  threshold_type: 'streak_days' | 'total_interactions' | 'unique_relatives' | 'specific_action' | 'custom';
  threshold_value: number;
  xp_reward: number;
  is_secret: boolean;
  is_active: boolean;
  sort_order: number;
  created_at: string;
  updated_at: string;
}

export interface AdminLevel {
  id: string;
  level: number;
  title_ar: string;
  title_en: string | null;
  xp_required: number;
  xp_to_next: number | null;
  icon: string | null;
  color_hex: string | null;
  perks: unknown[];
  created_at: string;
  updated_at: string;
}

export interface AdminChallenge {
  id: string;
  challenge_key: string;
  title_ar: string;
  title_en: string | null;
  description_ar: string;
  description_en: string | null;
  type: 'daily' | 'weekly' | 'monthly' | 'special' | 'seasonal';
  requirement_type: 'interaction_count' | 'unique_relatives' | 'specific_type' | 'streak' | 'custom';
  requirement_value: number;
  requirement_metadata: Record<string, unknown>;
  xp_reward: number;
  points_reward: number;
  badge_reward: string | null;
  icon: string;
  color_hex: string;
  start_date: string | null;
  end_date: string | null;
  is_active: boolean;
  is_recurring: boolean;
  sort_order: number;
  created_at: string;
  updated_at: string;
}

export interface AdminStreakConfig {
  id: string;
  config_key: string;
  deadline_hours: number;
  endangered_threshold_hours: number;
  critical_threshold_minutes: number;
  grace_period_hours: number;
  freeze_award_milestones: number[];
  max_freezes: number;
  freeze_cost_points: number;
  streak_restore_enabled: boolean;
  streak_restore_cost_points: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface AdminNotificationTemplate {
  id: string;
  template_key: string;
  title_ar: string;
  title_en: string | null;
  body_ar: string;
  body_en: string | null;
  category: 'reminder' | 'streak' | 'badge' | 'level' | 'challenge' | 'system' | 'promotional';
  variables: string[];
  icon: string | null;
  sound: string;
  channel_id: string;
  priority: 'min' | 'low' | 'default' | 'high' | 'max';
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface AdminReminderTimeSlot {
  id: string;
  slot_key: string;
  display_name_ar: string;
  display_name_en: string | null;
  start_hour: number;
  end_hour: number;
  icon: string | null;
  is_default: boolean;
  is_active: boolean;
  sort_order: number;
  created_at: string;
  updated_at: string;
}

export interface AdminColor {
  id: string;
  color_key: string;
  display_name_ar: string;
  display_name_en: string | null;
  hex_value: string;
  rgb_value: { r: number; g: number; b: number } | null;
  usage_context: string | null;
  is_primary: boolean;
  is_active: boolean;
  sort_order: number;
  created_at: string;
  updated_at: string;
}

export interface AdminTheme {
  id: string;
  theme_key: string;
  display_name_ar: string;
  display_name_en: string | null;
  is_dark: boolean;
  colors: Record<string, string>;
  gradients: Record<string, unknown>;
  shadows: Record<string, unknown>;
  is_premium: boolean;
  is_default: boolean;
  is_active: boolean;
  preview_image_url: string | null;
  sort_order: number;
  created_at: string;
  updated_at: string;
}

export interface AdminAnimation {
  id: string;
  animation_key: string;
  display_name_ar: string;
  display_name_en: string | null;
  duration_ms: number;
  curve: string;
  description: string | null;
  usage_context: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface AdminPatternAnimation {
  id: string;
  effect_key: string;
  display_name_ar: string;
  display_name_en: string | null;
  description_ar: string | null;
  default_enabled: boolean;
  battery_impact: 'low' | 'medium' | 'high';
  default_intensity: number;
  settings_key: string;
  is_premium: boolean;
  is_active: boolean;
  sort_order: number;
  created_at: string;
  updated_at: string;
}

// AI Management Types
export interface AdminAIIdentity {
  id: string;
  ai_name: string;
  ai_name_en: string | null;
  ai_role_ar: string;
  ai_role_en: string | null;
  ai_avatar_url: string | null;
  greeting_message_ar: string;
  greeting_message_en: string | null;
  dialect: string;
  personality_summary_ar: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface AdminAIPersonality {
  id: string;
  section_key: string;
  section_name_ar: string;
  content_ar: string;
  content_en: string | null;
  priority: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface AdminCounselingMode {
  id: string;
  mode_key: string;
  display_name_ar: string;
  display_name_en: string | null;
  description_ar: string | null;
  icon_name: string;
  color_hex: string;
  mode_instructions: string;
  is_default: boolean;
  is_active: boolean;
  sort_order: number;
  created_at: string;
  updated_at: string;
}

export interface AdminAIParameters {
  id: string;
  feature_key: string;
  display_name_ar: string;
  model_name: string;
  temperature: number;
  max_tokens: number;
  timeout_seconds: number;
  stream_enabled: boolean;
  description: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface AdminMessageOccasion {
  id: string;
  occasion_key: string;
  display_name_ar: string;
  display_name_en: string | null;
  emoji: string;
  prompt_addition: string | null;
  seasonal: boolean;
  is_active: boolean;
  sort_order: number;
  created_at: string;
  updated_at: string;
}

export interface AdminMessageTone {
  id: string;
  tone_key: string;
  display_name_ar: string;
  display_name_en: string | null;
  emoji: string;
  prompt_modifier: string | null;
  is_active: boolean;
  sort_order: number;
  created_at: string;
  updated_at: string;
}

export interface AdminSubscriptionTier {
  id: string;
  tier_key: string;
  display_name_ar: string;
  display_name_en: string | null;
  description_ar: string | null;
  description_en: string | null;
  reminder_limit: number;
  features: string[];
  icon_name: string;
  color_hex: string;
  is_default: boolean;
  is_active: boolean;
  sort_order: number;
  created_at: string;
  updated_at: string;
}

export interface AdminSubscriptionProduct {
  id: string;
  product_id: string;
  tier_key: string;
  display_name_ar: string;
  display_name_en: string | null;
  billing_period: 'monthly' | 'annual' | 'lifetime';
  price_usd: number | null;
  price_sar: number | null;
  savings_percentage: number | null;
  is_featured: boolean;
  is_active: boolean;
  sort_order: number;
  // RevenueCat sync fields
  price_source: 'manual' | 'app_store' | 'google_play' | null;
  price_verified_at: string | null;
  revenuecat_package_id: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface AdminFeature {
  id: string;
  feature_id: string;
  display_name_ar: string;
  display_name_en: string | null;
  description_ar: string | null;
  description_en: string | null;
  icon_name: string;
  category: 'ai' | 'analytics' | 'social' | 'customization' | 'utility';
  minimum_tier: string;
  locked_message_ar: string | null;
  locked_message_en: string | null;
  is_active: boolean;
  sort_order: number;
  created_at: string;
  updated_at: string;
}
