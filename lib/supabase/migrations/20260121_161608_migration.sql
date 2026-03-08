-- Ensure the assets storage bucket exists for product uploads
INSERT INTO storage.buckets (id, name, public)
SELECT 'assets', 'assets', TRUE
WHERE NOT EXISTS (
  SELECT 1 FROM storage.buckets WHERE id = 'assets'
);

-- Keep the bucket public so product downloads work without signed URLs
UPDATE storage.buckets
SET public = TRUE
WHERE id = 'assets';

-- Refresh storage policies for the assets bucket
DO $$
BEGIN
  IF has_table_privilege('storage.objects', 'ALTER') THEN
    EXECUTE 'ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY';

    EXECUTE 'DROP POLICY IF EXISTS storage_assets_read_policy ON storage.objects';
    EXECUTE 'DROP POLICY IF EXISTS storage_assets_insert_policy ON storage.objects';
    EXECUTE 'DROP POLICY IF EXISTS storage_assets_update_policy ON storage.objects';
    EXECUTE 'DROP POLICY IF EXISTS storage_assets_delete_policy ON storage.objects';

    EXECUTE 'CREATE POLICY storage_assets_read_policy ON storage.objects '
            'FOR SELECT USING (bucket_id = ''assets'')';
    EXECUTE 'CREATE POLICY storage_assets_insert_policy ON storage.objects '
            'FOR INSERT WITH CHECK (bucket_id = ''assets'' AND auth.role() = ''authenticated'')';
    EXECUTE 'CREATE POLICY storage_assets_update_policy ON storage.objects '
            'FOR UPDATE USING (bucket_id = ''assets'' AND auth.role() = ''authenticated'') '
            'WITH CHECK (bucket_id = ''assets'' AND auth.role() = ''authenticated'')';
    EXECUTE 'CREATE POLICY storage_assets_delete_policy ON storage.objects '
            'FOR DELETE USING (bucket_id = ''assets'' AND auth.role() = ''authenticated'')';
  END IF;
END $$;