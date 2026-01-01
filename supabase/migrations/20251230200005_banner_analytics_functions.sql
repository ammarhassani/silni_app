-- RPC functions for banner analytics tracking

-- Function to increment banner impressions
CREATE OR REPLACE FUNCTION increment_banner_impressions(banner_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE admin_banners
  SET impressions = impressions + 1
  WHERE id = banner_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to increment banner clicks
CREATE OR REPLACE FUNCTION increment_banner_clicks(banner_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE admin_banners
  SET clicks = clicks + 1
  WHERE id = banner_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION increment_banner_impressions(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION increment_banner_clicks(UUID) TO authenticated;

COMMENT ON FUNCTION increment_banner_impressions IS 'Increment impression count for a banner';
COMMENT ON FUNCTION increment_banner_clicks IS 'Increment click count for a banner';
