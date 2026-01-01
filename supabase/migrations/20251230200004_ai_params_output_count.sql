-- Add output_count column to AI parameters for features that generate multiple outputs

ALTER TABLE admin_ai_parameters
  ADD COLUMN IF NOT EXISTS output_count INTEGER;

-- Set default output count for message_generation
UPDATE admin_ai_parameters
SET output_count = 3
WHERE feature_key = 'message_generation';

COMMENT ON COLUMN admin_ai_parameters.output_count IS 'Number of outputs to generate (e.g., 3 messages for message composer). NULL means N/A for this feature.';
