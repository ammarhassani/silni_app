-- Add family_side column to relatives for extended family disambiguation.
-- Stores whether a grandparent/uncle/aunt is from the paternal or maternal side.
-- Nullable because only extended family types need this field.
ALTER TABLE relatives
  ADD COLUMN IF NOT EXISTS family_side TEXT CHECK (family_side IN ('paternal', 'maternal'));
