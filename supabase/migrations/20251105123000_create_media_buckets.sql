-- Ensure the public buckets used for post uploads exist
INSERT INTO storage.buckets (id, name, public)
SELECT 'images', 'images', TRUE
WHERE NOT EXISTS (
  SELECT 1 FROM storage.buckets WHERE id = 'images'
);

INSERT INTO storage.buckets (id, name, public)
SELECT 'videos', 'videos', TRUE
WHERE NOT EXISTS (
  SELECT 1 FROM storage.buckets WHERE id = 'videos'
);

-- Make sure both buckets remain public even if they already existed
UPDATE storage.buckets
SET public = TRUE
WHERE id IN ('images', 'videos');

-- Allow anyone to read media files from these buckets
DROP POLICY IF EXISTS "Public read access for images" ON storage.objects;
CREATE POLICY "Public read access for images"
  ON storage.objects
  FOR SELECT
  USING (bucket_id = 'images');

DROP POLICY IF EXISTS "Public read access for videos" ON storage.objects;
CREATE POLICY "Public read access for videos"
  ON storage.objects
  FOR SELECT
  USING (bucket_id = 'videos');

-- Allow authenticated users to upload/replace their media files
DROP POLICY IF EXISTS "Authenticated uploads for images" ON storage.objects;
CREATE POLICY "Authenticated uploads for images"
  ON storage.objects
  FOR INSERT
  WITH CHECK (bucket_id = 'images' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated uploads for videos" ON storage.objects;
CREATE POLICY "Authenticated uploads for videos"
  ON storage.objects
  FOR INSERT
  WITH CHECK (bucket_id = 'videos' AND auth.role() = 'authenticated');

-- Allow authenticated users to overwrite existing media (needed for upsert=true)
DROP POLICY IF EXISTS "Authenticated updates for images" ON storage.objects;
CREATE POLICY "Authenticated updates for images"
  ON storage.objects
  FOR UPDATE
  USING (bucket_id = 'images' AND auth.role() = 'authenticated')
  WITH CHECK (bucket_id = 'images' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated updates for videos" ON storage.objects;
CREATE POLICY "Authenticated updates for videos"
  ON storage.objects
  FOR UPDATE
  USING (bucket_id = 'videos' AND auth.role() = 'authenticated')
  WITH CHECK (bucket_id = 'videos' AND auth.role() = 'authenticated');