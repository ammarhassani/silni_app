-- Create storage bucket for voice notes
INSERT INTO storage.buckets (id, name, public)
VALUES ('voice-notes', 'voice-notes', true)
ON CONFLICT (id) DO NOTHING;

-- RLS Policies for voice-notes bucket

-- Allow authenticated users to upload to their own folder
CREATE POLICY "Users can upload voice notes"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'voice-notes'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow authenticated users to update their own voice notes
CREATE POLICY "Users can update voice notes"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'voice-notes'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow authenticated users to delete their own voice notes
CREATE POLICY "Users can delete voice notes"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'voice-notes'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow public read access to voice notes (for shared interactions)
CREATE POLICY "Public can view voice notes"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'voice-notes');
