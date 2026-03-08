-- Create a public 'assets' storage bucket used for product uploads
-- Idempotent: safe to run multiple times

-- Create bucket if missing
INSERT INTO storage.buckets (id, name, public)
SELECT 'assets', 'assets', TRUE
WHERE NOT EXISTS (
  SELECT 1 FROM storage.buckets WHERE id = 'assets'
);

-- Ensure bucket stays public
UPDATE storage.buckets SET public = TRUE WHERE id = 'assets';

-- Public read access for objects in the 'assets' bucket
DROP POLICY IF EXISTS "Public read access for assets" ON storage.objects;
CREATE POLICY "Public read access for assets"
  ON storage.objects
  FOR SELECT
  USING (bucket_id = 'assets');

-- Allow authenticated users to upload into the 'assets' bucket
DROP POLICY IF EXISTS "Authenticated uploads for assets" ON storage.objects;
CREATE POLICY "Authenticated uploads for assets"
  ON storage.objects
  FOR INSERT
  WITH CHECK (bucket_id = 'assets' AND auth.role() = 'authenticated');

-- Allow authenticated users to update/overwrite their files (required for upsert)
DROP POLICY IF EXISTS "Authenticated updates for assets" ON storage.objects;
CREATE POLICY "Authenticated updates for assets"
  ON storage.objects
  FOR UPDATE
  USING (bucket_id = 'assets' AND auth.role() = 'authenticated')
  WITH CHECK (bucket_id = 'assets' AND auth.role() = 'authenticated');

-- Optional: allow authenticated deletes (kept consistent with images/videos migrations, omit delete)
