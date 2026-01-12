-- Create storage bucket for in-app message images
-- This allows admins to upload banner images and illustrations for messages

-- Create the bucket (public for read access)
INSERT INTO storage.buckets (id, name, public)
VALUES ('message-images', 'message-images', true)
ON CONFLICT (id) DO NOTHING;

-- RLS Policies for message-images bucket

-- Allow admins to upload message images
CREATE POLICY "Admins can upload message images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'message-images'
  AND (SELECT is_admin())
);

-- Allow admins to update message images
CREATE POLICY "Admins can update message images"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'message-images'
  AND (SELECT is_admin())
);

-- Allow admins to delete message images
CREATE POLICY "Admins can delete message images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'message-images'
  AND (SELECT is_admin())
);

-- Allow public read access (images displayed in Flutter app)
CREATE POLICY "Public can view message images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'message-images');
