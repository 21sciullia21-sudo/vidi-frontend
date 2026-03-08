-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE bids ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_methods ENABLE ROW LEVEL SECURITY;

-- Drop existing policies (with unique names)
DROP POLICY IF EXISTS users_select_policy ON users;
DROP POLICY IF EXISTS users_insert_policy ON users;
DROP POLICY IF EXISTS users_update_policy ON users;
DROP POLICY IF EXISTS users_delete_policy ON users;

DROP POLICY IF EXISTS jobs_select_policy ON jobs;
DROP POLICY IF EXISTS jobs_insert_policy ON jobs;
DROP POLICY IF EXISTS jobs_update_policy ON jobs;
DROP POLICY IF EXISTS jobs_delete_policy ON jobs;

DROP POLICY IF EXISTS bids_select_policy ON bids;
DROP POLICY IF EXISTS bids_insert_policy ON bids;
DROP POLICY IF EXISTS bids_update_policy ON bids;
DROP POLICY IF EXISTS bids_delete_policy ON bids;

DROP POLICY IF EXISTS posts_select_policy ON posts;
DROP POLICY IF EXISTS posts_insert_policy ON posts;
DROP POLICY IF EXISTS posts_update_policy ON posts;
DROP POLICY IF EXISTS posts_delete_policy ON posts;

DROP POLICY IF EXISTS comments_select_policy ON comments;
DROP POLICY IF EXISTS comments_insert_policy ON comments;
DROP POLICY IF EXISTS comments_update_policy ON comments;
DROP POLICY IF EXISTS comments_delete_policy ON comments;

DROP POLICY IF EXISTS assets_select_policy ON assets;
DROP POLICY IF EXISTS assets_insert_policy ON assets;
DROP POLICY IF EXISTS assets_update_policy ON assets;
DROP POLICY IF EXISTS assets_delete_policy ON assets;

DROP POLICY IF EXISTS purchases_select_policy ON purchases;
DROP POLICY IF EXISTS purchases_insert_policy ON purchases;
DROP POLICY IF EXISTS purchases_update_policy ON purchases;
DROP POLICY IF EXISTS purchases_delete_policy ON purchases;

DROP POLICY IF EXISTS payment_methods_select_policy ON payment_methods;
DROP POLICY IF EXISTS payment_methods_insert_policy ON payment_methods;
DROP POLICY IF EXISTS payment_methods_update_policy ON payment_methods;
DROP POLICY IF EXISTS payment_methods_delete_policy ON payment_methods;

DROP POLICY IF EXISTS storage_images_read_policy ON storage.objects;
DROP POLICY IF EXISTS storage_videos_read_policy ON storage.objects;
DROP POLICY IF EXISTS storage_images_insert_policy ON storage.objects;
DROP POLICY IF EXISTS storage_videos_insert_policy ON storage.objects;
DROP POLICY IF EXISTS storage_images_update_policy ON storage.objects;
DROP POLICY IF EXISTS storage_videos_update_policy ON storage.objects;

-- Users policies (UNIQUE NAMES)
CREATE POLICY users_select_policy ON users FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY users_insert_policy ON users FOR INSERT WITH CHECK (true);
CREATE POLICY users_update_policy ON users FOR UPDATE USING (auth.role() = 'authenticated') WITH CHECK (true);
CREATE POLICY users_delete_policy ON users FOR DELETE USING (auth.role() = 'authenticated');

-- Jobs policies (UNIQUE NAMES)
CREATE POLICY jobs_select_policy ON jobs FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY jobs_insert_policy ON jobs FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY jobs_update_policy ON jobs FOR UPDATE USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY jobs_delete_policy ON jobs FOR DELETE USING (auth.role() = 'authenticated');

-- Bids policies (UNIQUE NAMES)
CREATE POLICY bids_select_policy ON bids FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY bids_insert_policy ON bids FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY bids_update_policy ON bids FOR UPDATE USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY bids_delete_policy ON bids FOR DELETE USING (auth.role() = 'authenticated');

-- Posts policies (UNIQUE NAMES)
CREATE POLICY posts_select_policy ON posts FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY posts_insert_policy ON posts FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY posts_update_policy ON posts FOR UPDATE USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY posts_delete_policy ON posts FOR DELETE USING (auth.role() = 'authenticated');

-- Comments policies (UNIQUE NAMES)
CREATE POLICY comments_select_policy ON comments FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY comments_insert_policy ON comments FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY comments_update_policy ON comments FOR UPDATE USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY comments_delete_policy ON comments FOR DELETE USING (auth.role() = 'authenticated');

-- Assets policies (UNIQUE NAMES)
CREATE POLICY assets_select_policy ON assets FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY assets_insert_policy ON assets FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY assets_update_policy ON assets FOR UPDATE USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY assets_delete_policy ON assets FOR DELETE USING (auth.role() = 'authenticated');

-- Purchases policies (UNIQUE NAMES)
CREATE POLICY purchases_select_policy ON purchases FOR SELECT USING (auth.role() = 'service_role' OR auth.uid() = user_id);
CREATE POLICY purchases_insert_policy ON purchases FOR INSERT WITH CHECK (auth.role() = 'service_role' OR auth.uid() = user_id);
CREATE POLICY purchases_update_policy ON purchases FOR UPDATE USING (auth.role() = 'service_role' OR auth.uid() = user_id) WITH CHECK (auth.role() = 'service_role' OR auth.uid() = user_id);
CREATE POLICY purchases_delete_policy ON purchases FOR DELETE USING (auth.role() = 'service_role' OR auth.uid() = user_id);

-- Payment methods policies (UNIQUE NAMES)
CREATE POLICY payment_methods_select_policy ON payment_methods FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY payment_methods_insert_policy ON payment_methods FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY payment_methods_update_policy ON payment_methods FOR UPDATE USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY payment_methods_delete_policy ON payment_methods FOR DELETE USING (auth.role() = 'authenticated');

-- Use single-quoted EXECUTE strings to avoid nested $$ delimiter conflicts during migration runs
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
