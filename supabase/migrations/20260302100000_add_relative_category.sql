ALTER TABLE relatives
ADD COLUMN relative_category TEXT NOT NULL DEFAULT 'extended'
CHECK (relative_category IN ('household', 'extended', 'distant'));

CREATE INDEX idx_relatives_category ON relatives(user_id, relative_category);
