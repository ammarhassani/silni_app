-- Create storage buckets for profile pictures
-- Run this in Supabase SQL Editor or as a migration

-- Create bucket for user profile pictures
INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-pictures', 'profile-pictures', true)
ON CONFLICT (id) DO NOTHING;

-- Create bucket for relative photos
INSERT INTO storage.buckets (id, name, public)
VALUES ('relative-photos', 'relative-photos', true)
ON CONFLICT (id) DO NOTHING;

-- RLS Policies for profile-pictures bucket

-- Allow authenticated users to upload to their own folder
CREATE POLICY "Users can upload own profile pictures"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile-pictures'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow authenticated users to update their own photos
CREATE POLICY "Users can update own profile pictures"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'profile-pictures'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow authenticated users to delete their own photos
CREATE POLICY "Users can delete own profile pictures"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'profile-pictures'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow public read access to profile pictures
CREATE POLICY "Public can view profile pictures"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'profile-pictures');

-- RLS Policies for relative-photos bucket

-- Allow authenticated users to upload to their own folder
CREATE POLICY "Users can upload relative photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'relative-photos'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow authenticated users to update their own relative photos
CREATE POLICY "Users can update relative photos"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'relative-photos'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow authenticated users to delete their own relative photos
CREATE POLICY "Users can delete relative photos"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'relative-photos'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow public read access to relative photos
CREATE POLICY "Public can view relative photos"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'relative-photos');
