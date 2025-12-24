-- Create gifts table for curated product recommendations
-- Products are fetched from Saudi retailers (Amazon.sa, Noon, Jarir)

CREATE TABLE IF NOT EXISTS gifts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Product info
  name_ar TEXT NOT NULL,           -- "ساعة آبل ووتش SE الجيل الثاني"
  name_en TEXT NOT NULL,           -- "Apple Watch SE 2nd Gen"
  brand TEXT NOT NULL,             -- "Apple"
  category TEXT NOT NULL,          -- "electronics", "perfume", "jewelry", etc.

  -- Pricing & Purchase
  price_sar INTEGER NOT NULL,      -- 999 (no decimals for simplicity)
  image_url TEXT NOT NULL,         -- Product image URL
  purchase_url TEXT NOT NULL,      -- "https://amazon.sa/dp/..."
  retailer TEXT NOT NULL,          -- "Amazon.sa", "Noon", "Jarir"

  -- Matching criteria for AI ranking
  occasions TEXT[] NOT NULL DEFAULT '{}',       -- ["birthday", "graduation", "eid"]
  recipient_tags TEXT[] NOT NULL DEFAULT '{}',  -- ["tech_lover", "fitness", "professional"]
  gender TEXT DEFAULT 'unisex',                 -- "male", "female", "unisex"
  age_range TEXT,                               -- "18-30", "30-50", "50+"

  -- Status
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS: Public read access (gifts are not user-specific)
ALTER TABLE gifts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read access for gifts"
  ON gifts
  FOR SELECT
  USING (true);

-- Indexes for fast filtering
CREATE INDEX IF NOT EXISTS idx_gifts_category ON gifts(category);
CREATE INDEX IF NOT EXISTS idx_gifts_retailer ON gifts(retailer);
CREATE INDEX IF NOT EXISTS idx_gifts_price ON gifts(price_sar);
CREATE INDEX IF NOT EXISTS idx_gifts_occasions ON gifts USING GIN(occasions);
CREATE INDEX IF NOT EXISTS idx_gifts_tags ON gifts USING GIN(recipient_tags);
CREATE INDEX IF NOT EXISTS idx_gifts_active ON gifts(is_active) WHERE is_active = true;

-- Update timestamp trigger
CREATE OR REPLACE FUNCTION update_gifts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER gifts_updated_at
  BEFORE UPDATE ON gifts
  FOR EACH ROW
  EXECUTE FUNCTION update_gifts_updated_at();

-- Comments for documentation
COMMENT ON TABLE gifts IS 'Curated gift products from Saudi retailers for AI recommendations';
COMMENT ON COLUMN gifts.occasions IS 'Gift occasions: birthday, wedding, graduation, ramadan, eid, newborn, recovery, general';
COMMENT ON COLUMN gifts.recipient_tags IS 'Recipient interests: tech_lover, fitness, fashion, home, religious, reader, gamer, foodie, traveler, artist';
COMMENT ON COLUMN gifts.gender IS 'Target gender: male, female, unisex';
COMMENT ON COLUMN gifts.age_range IS 'Target age range: 0-12, 13-17, 18-30, 30-50, 50+';
