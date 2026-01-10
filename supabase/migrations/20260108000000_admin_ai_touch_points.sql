-- =============================================================================
-- AI Touch Points System
-- Enables admin-configurable AI enhancements across the app
-- =============================================================================

-- Create admin_ai_touch_points table
-- Defines where AI can inject intelligence in the app
CREATE TABLE IF NOT EXISTS admin_ai_touch_points (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  screen_key TEXT NOT NULL,               -- 'home', 'relative_detail', 'reminders', etc.
  touch_point_key TEXT NOT NULL,          -- 'greeting', 'priority_contacts', 'insight', etc.
  name_ar TEXT NOT NULL,                  -- Arabic display name
  name_en TEXT,                           -- English display name
  description_ar TEXT,                    -- Description in Arabic
  is_enabled BOOLEAN DEFAULT true,
  prompt_template TEXT NOT NULL,          -- The AI prompt template
  context_fields JSONB DEFAULT '[]'::jsonb, -- Which data to include: ["relatives", "streaks", "health"]
  display_config JSONB DEFAULT '{}'::jsonb, -- UI config: icon, position, style
  cache_duration_seconds INTEGER DEFAULT 300, -- How long to cache AI response
  priority INTEGER DEFAULT 0,             -- Order of display
  temperature FLOAT DEFAULT 0.7,          -- AI temperature for this touch point
  max_tokens INTEGER DEFAULT 150,         -- Max tokens for response
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(screen_key, touch_point_key)
);

-- Create ai_generations table for tracking AI usage
CREATE TABLE IF NOT EXISTS ai_generations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  touch_point_key TEXT NOT NULL,
  screen_key TEXT,
  prompt_hash TEXT,                       -- Hash of prompt for caching
  response TEXT,                          -- Cached response
  tokens_used INTEGER,
  latency_ms INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for efficient lookups
CREATE INDEX IF NOT EXISTS idx_ai_generations_user_touch ON ai_generations(user_id, touch_point_key);
CREATE INDEX IF NOT EXISTS idx_ai_generations_created ON ai_generations(created_at);

-- Enable RLS
ALTER TABLE admin_ai_touch_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_generations ENABLE ROW LEVEL SECURITY;

-- Admin touch points are readable by all authenticated users (config)
CREATE POLICY "admin_ai_touch_points_read_all" ON admin_ai_touch_points
  FOR SELECT USING (true);

-- AI generations - users can only see their own
CREATE POLICY "ai_generations_user_read" ON ai_generations
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "ai_generations_user_insert" ON ai_generations
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Function to update updated_at
CREATE OR REPLACE FUNCTION update_ai_touch_points_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_ai_touch_points_updated_at
  BEFORE UPDATE ON admin_ai_touch_points
  FOR EACH ROW
  EXECUTE FUNCTION update_ai_touch_points_updated_at();

-- =============================================================================
-- Seed Default Touch Points
-- =============================================================================

INSERT INTO admin_ai_touch_points (screen_key, touch_point_key, name_ar, name_en, description_ar, prompt_template, context_fields, display_config, temperature, max_tokens) VALUES

-- Home Screen Touch Points
('home', 'greeting', 'التحية الذكية', 'AI Greeting', 'تحية مخصصة بناءً على وقت اليوم وحالة العلاقات',
'أنت واصل، مساعد صلة الرحم. اكتب تحية قصيرة وودية (جملة واحدة فقط) للمستخدم بناءً على:
- الوقت الحالي: {{time_of_day}}
- عدد الشعلات النشطة: {{active_streaks}}
- الأقارب المعرضون للخطر: {{at_risk_count}}
- المناسبات القادمة: {{upcoming_occasions}}

اجعل التحية دافئة وشخصية باللهجة السعودية. لا تزيد عن 15 كلمة.',
'["time", "streaks", "health", "occasions"]'::jsonb,
'{"icon": "hand-wave", "position": "top"}'::jsonb,
0.8, 50),

('home', 'priority_contacts', 'من يحتاجك اليوم', 'Priority Contacts', 'قائمة الأقارب الأكثر حاجة للتواصل',
'بناءً على بيانات الأقارب التالية، رتب أهم 3 أقارب يحتاجون التواصل اليوم مع سبب قصير لكل منهم.

الأقارب:
{{relatives_data}}

الشعلات:
{{streaks_data}}

المناسبات القادمة:
{{occasions_data}}

أجب بصيغة JSON:
[{"name": "الاسم", "reason": "السبب في كلمات قليلة", "urgency": "high/medium/low"}]',
'["relatives", "streaks", "health", "occasions"]'::jsonb,
'{"icon": "users", "position": "main", "max_items": 3}'::jsonb,
0.7, 200),

('home', 'insight', 'رؤية اليوم', 'Daily Insight', 'ملاحظة ذكية عن أنماط التواصل',
'بناءً على بيانات التفاعلات والأنماط التالية، اكتب ملاحظة واحدة مفيدة ومشجعة للمستخدم عن صلة الرحم.

ملخص الصحة:
- علاقات صحية: {{healthy_count}}
- تحتاج اهتمام: {{needs_attention_count}}
- معرضة للخطر: {{at_risk_count}}

إحصائيات:
- إجمالي التفاعلات: {{total_interactions}}
- الشعلات النشطة: {{active_streaks}}

اجعل الملاحظة إيجابية ومحفزة. جملة أو جملتين فقط.',
'["health", "interactions", "streaks"]'::jsonb,
'{"icon": "lightbulb", "position": "bottom"}'::jsonb,
0.8, 80),

-- Relative Detail Touch Points
('relative_detail', 'conversation_starters', 'مواضيع للحديث', 'Conversation Starters', 'اقتراحات مواضيع بناءً على اهتمامات القريب',
'أنت واصل. اقترح 3 مواضيع للحديث مع {{relative_name}} بناءً على:

العلاقة: {{relationship_type}}
الاهتمامات: {{interests}}
آخر تواصل: {{last_contact}}
ذكريات سابقة: {{memories}}

اجعل المواضيع طبيعية ومناسبة للعلاقة. أجب بصيغة JSON:
[{"topic": "الموضوع", "opener": "جملة افتتاحية مقترحة"}]',
'["relative", "memories", "interactions"]'::jsonb,
'{"icon": "message-circle", "show_before_contact": true}'::jsonb,
0.8, 200),

('relative_detail', 'health_explanation', 'تفسير الصحة', 'Health Explanation', 'شرح حالة صحة العلاقة',
'اشرح باختصار لماذا صحة العلاقة مع {{relative_name}} هي {{health_status}}.

البيانات:
- آخر تواصل: {{days_since_contact}} يوم
- التقارب العاطفي: {{emotional_closeness}}/5
- جودة التواصل: {{communication_quality}}/5
- الشعلة الحالية: {{current_streak}} يوم

اكتب جملة أو جملتين تفسيرية بأسلوب ودي.',
'["relative", "health", "streaks"]'::jsonb,
'{"icon": "heart-pulse"}'::jsonb,
0.7, 80),

-- Reminders Screen Touch Points
('reminders', 'time_suggestion', 'أفضل وقت', 'Best Time', 'اقتراح أفضل وقت للتذكير',
'بناءً على أنماط التواصل مع {{relative_name}}:
- أوقات التواصل السابقة: {{contact_times}}
- الوقت المفضل المسجل: {{preferred_time}}

اقترح أفضل وقت للتذكير بالتواصل. جملة واحدة فقط.',
'["relative", "interactions", "patterns"]'::jsonb,
'{"icon": "clock"}'::jsonb,
0.7, 50),

('reminders', 'frequency_recommendation', 'تكرار مناسب', 'Frequency', 'اقتراح تكرار التذكير',
'بناءً على نوع العلاقة ({{relationship_type}}) وصحة العلاقة ({{health_status}}):

اقترح تكرار مناسب للتذكير (يومي/أسبوعي/شهري) مع تبرير قصير.',
'["relative", "health"]'::jsonb,
'{"icon": "repeat"}'::jsonb,
0.7, 60)

ON CONFLICT (screen_key, touch_point_key) DO UPDATE SET
  name_ar = EXCLUDED.name_ar,
  name_en = EXCLUDED.name_en,
  description_ar = EXCLUDED.description_ar,
  prompt_template = EXCLUDED.prompt_template,
  context_fields = EXCLUDED.context_fields,
  display_config = EXCLUDED.display_config,
  temperature = EXCLUDED.temperature,
  max_tokens = EXCLUDED.max_tokens,
  updated_at = NOW();

-- =============================================================================
-- Add to cache config (if table exists)
-- =============================================================================

DO $$
BEGIN
  -- Try to insert into admin_cache_config if it exists
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'admin_cache_config') THEN
    INSERT INTO admin_cache_config (service_key, cache_duration_seconds, description_ar)
    VALUES ('ai_touch_points', 300, 'نقاط الذكاء الاصطناعي')
    ON CONFLICT (service_key) DO NOTHING;
  END IF;
END $$;

-- Log the migration
DO $$
BEGIN
  RAISE NOTICE 'Migration 20260108000000_admin_ai_touch_points completed successfully';
END $$;
