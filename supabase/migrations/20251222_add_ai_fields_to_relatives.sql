-- Migration: Add AI-optimized fields to relatives table
-- Date: 2024-12-22
-- Description: Adds fields for AI features (gift recommendations, health scoring, counseling)

-- Gift-Related Fields
ALTER TABLE relatives ADD COLUMN IF NOT EXISTS interests TEXT[];
ALTER TABLE relatives ADD COLUMN IF NOT EXISTS favorite_colors TEXT[];
ALTER TABLE relatives ADD COLUMN IF NOT EXISTS favorite_foods TEXT[];
ALTER TABLE relatives ADD COLUMN IF NOT EXISTS clothing_size TEXT;
ALTER TABLE relatives ADD COLUMN IF NOT EXISTS gift_budget TEXT; -- 'low', 'medium', 'high'
ALTER TABLE relatives ADD COLUMN IF NOT EXISTS disliked_gifts TEXT[];
ALTER TABLE relatives ADD COLUMN IF NOT EXISTS wishlist TEXT[];

-- Personality & Communication Fields
ALTER TABLE relatives ADD COLUMN IF NOT EXISTS personality_type TEXT;
ALTER TABLE relatives ADD COLUMN IF NOT EXISTS communication_style TEXT; -- 'direct', 'gentle', 'formal'
ALTER TABLE relatives ADD COLUMN IF NOT EXISTS sensitive_topics TEXT[];
ALTER TABLE relatives ADD COLUMN IF NOT EXISTS relationship_challenges TEXT;
ALTER TABLE relatives ADD COLUMN IF NOT EXISTS relationship_strengths TEXT;
ALTER TABLE relatives ADD COLUMN IF NOT EXISTS ai_notes TEXT;

-- Health Scoring Fields
ALTER TABLE relatives ADD COLUMN IF NOT EXISTS emotional_closeness INTEGER CHECK (emotional_closeness >= 1 AND emotional_closeness <= 5);
ALTER TABLE relatives ADD COLUMN IF NOT EXISTS communication_quality INTEGER CHECK (communication_quality >= 1 AND communication_quality <= 5);
ALTER TABLE relatives ADD COLUMN IF NOT EXISTS conflict_history TEXT;
ALTER TABLE relatives ADD COLUMN IF NOT EXISTS support_level INTEGER CHECK (support_level >= 1 AND support_level <= 5);
ALTER TABLE relatives ADD COLUMN IF NOT EXISTS last_meaningful_interaction TIMESTAMPTZ;

-- Add comments for documentation
COMMENT ON COLUMN relatives.interests IS 'List of hobbies and interests for gift recommendations';
COMMENT ON COLUMN relatives.favorite_colors IS 'Preferred colors for gift selection';
COMMENT ON COLUMN relatives.favorite_foods IS 'Food preferences for gift ideas';
COMMENT ON COLUMN relatives.clothing_size IS 'Clothing size if known (e.g., M, L, 42)';
COMMENT ON COLUMN relatives.gift_budget IS 'Preferred gift price range: low, medium, high';
COMMENT ON COLUMN relatives.disliked_gifts IS 'Types of gifts to avoid';
COMMENT ON COLUMN relatives.wishlist IS 'Items they have mentioned wanting';
COMMENT ON COLUMN relatives.personality_type IS 'Personality description for AI context';
COMMENT ON COLUMN relatives.communication_style IS 'Preferred communication style';
COMMENT ON COLUMN relatives.sensitive_topics IS 'Topics to avoid in conversation';
COMMENT ON COLUMN relatives.relationship_challenges IS 'Current relationship issues for AI counseling';
COMMENT ON COLUMN relatives.relationship_strengths IS 'What works well in the relationship';
COMMENT ON COLUMN relatives.ai_notes IS 'Free-form notes for AI context';
COMMENT ON COLUMN relatives.emotional_closeness IS 'Emotional bond strength (1-5 scale)';
COMMENT ON COLUMN relatives.communication_quality IS 'Quality of communication (1-5 scale)';
COMMENT ON COLUMN relatives.conflict_history IS 'Past conflicts and resolutions';
COMMENT ON COLUMN relatives.support_level IS 'Level of mutual support (1-5 scale)';
COMMENT ON COLUMN relatives.last_meaningful_interaction IS 'Last deep or meaningful conversation';
