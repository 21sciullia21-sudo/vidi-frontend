-- Fix storage.objects policy creation quoting to prevent DO $$ delimiter syntax errors
DO $$
BEGIN
  IF has_table_privilege('storage.objects', 'ALTER') THEN
    EXECUTE 'ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY';
    EXECUTE 'DROP POLICY IF EXISTS storage_images_read_policy ON storage.objects';
    EXECUTE 'DROP POLICY IF EXISTS storage_videos_read_policy ON storage.objects';
    EXECUTE 'DROP POLICY IF EXISTS storage_images_insert_policy ON storage.objects';
    EXECUTE 'DROP POLICY IF EXISTS storage_videos_insert_policy ON storage.objects';
    EXECUTE 'DROP POLICY IF EXISTS storage_images_update_policy ON storage.objects';
    EXECUTE 'DROP POLICY IF EXISTS storage_videos_update_policy ON storage.objects';

    EXECUTE 'CREATE POLICY storage_images_read_policy ON storage.objects FOR SELECT USING (bucket_id = ''images'')';
    EXECUTE 'CREATE POLICY storage_videos_read_policy ON storage.objects FOR SELECT USING (bucket_id = ''videos'')';
    EXECUTE 'CREATE POLICY storage_images_insert_policy ON storage.objects FOR INSERT WITH CHECK (bucket_id = ''images'' AND auth.role() = ''authenticated'')';
    EXECUTE 'CREATE POLICY storage_videos_insert_policy ON storage.objects FOR INSERT WITH CHECK (bucket_id = ''videos'' AND auth.role() = ''authenticated'')';
    EXECUTE 'CREATE POLICY storage_images_update_policy ON storage.objects FOR UPDATE USING (bucket_id = ''images'' AND auth.role() = ''authenticated'') WITH CHECK (bucket_id = ''images'' AND auth.role() = ''authenticated'')';
    EXECUTE 'CREATE POLICY storage_videos_update_policy ON storage.objects FOR UPDATE USING (bucket_id = ''videos'' AND auth.role() = ''authenticated'') WITH CHECK (bucket_id = ''videos'' AND auth.role() = ''authenticated'')';
  END IF;
END $$;