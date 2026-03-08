-- Drop existing policies
DO $$ 
DECLARE
  r RECORD;
BEGIN
  FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
    EXECUTE 'DROP POLICY IF EXISTS select_policy ON ' || quote_ident(r.tablename);
    EXECUTE 'DROP POLICY IF EXISTS insert_policy ON ' || quote_ident(r.tablename);
    EXECUTE 'DROP POLICY IF EXISTS update_policy ON ' || quote_ident(r.tablename);
    EXECUTE 'DROP POLICY IF EXISTS delete_policy ON ' || quote_ident(r.tablename);
  END LOOP;
END $$;

-- Drop existing tables
DROP TABLE IF EXISTS purchases CASCADE;
DROP TABLE IF EXISTS assets CASCADE;
DROP TABLE IF EXISTS comments CASCADE;
DROP TABLE IF EXISTS posts CASCADE;
DROP TABLE IF EXISTS bids CASCADE;
DROP TABLE IF EXISTS jobs CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Create users table (corrected column names)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY,
  username TEXT NOT NULL,
  full_name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  avatar_url TEXT DEFAULT '',
  bio TEXT DEFAULT '',
  user_role TEXT DEFAULT 'freelancer',
  instagram_url TEXT DEFAULT '',
  twitter_url TEXT DEFAULT '',
  youtube_url TEXT DEFAULT '',
  linkedin_url TEXT DEFAULT '',
  website_url TEXT DEFAULT '',
  portfolio_url TEXT DEFAULT '',
  followers TEXT[] DEFAULT '{}',
  following TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create jobs table
CREATE TABLE IF NOT EXISTS jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL,
  budget_min DECIMAL NOT NULL,
  budget_max DECIMAL NOT NULL,
  deadline TIMESTAMPTZ NOT NULL,
  client_id UUID REFERENCES users(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'open',
  requirements TEXT DEFAULT '',
  reference_images TEXT[] DEFAULT '{}',
  posted_at TIMESTAMPTZ DEFAULT NOW(),
  bid_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create bids table
CREATE TABLE IF NOT EXISTS bids (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
  editor_id UUID REFERENCES users(id) ON DELETE CASCADE,
  amount DECIMAL NOT NULL,
  delivery_days INTEGER NOT NULL,
  proposal TEXT NOT NULL,
  submitted_at TIMESTAMPTZ DEFAULT NOW(),
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create posts table (corrected column names)
CREATE TABLE IF NOT EXISTS posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  image_urls TEXT[] DEFAULT '{}',
  likes TEXT[] DEFAULT '{}',
  comment_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create comments table
CREATE TABLE IF NOT EXISTS comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create assets table (corrected column names)
CREATE TABLE IF NOT EXISTS assets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  seller_id UUID REFERENCES users(id) ON DELETE CASCADE,
  price DECIMAL NOT NULL,
  category TEXT NOT NULL,
  image_url TEXT NOT NULL,
  download_url TEXT NOT NULL,
  downloads INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create purchases table
CREATE TABLE IF NOT EXISTS purchases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  asset_id UUID REFERENCES assets(id) ON DELETE CASCADE,
  purchased_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_jobs_client_id ON jobs(client_id);
CREATE INDEX IF NOT EXISTS idx_jobs_posted_at ON jobs(posted_at);
CREATE INDEX IF NOT EXISTS idx_bids_job_id ON bids(job_id);
CREATE INDEX IF NOT EXISTS idx_bids_editor_id ON bids(editor_id);
CREATE INDEX IF NOT EXISTS idx_bids_submitted_at ON bids(submitted_at);
CREATE INDEX IF NOT EXISTS idx_posts_user_id ON posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts(created_at);
CREATE INDEX IF NOT EXISTS idx_comments_post_id ON comments(post_id);
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON comments(user_id);
CREATE INDEX IF NOT EXISTS idx_assets_seller_id ON assets(seller_id);
CREATE INDEX IF NOT EXISTS idx_purchases_user_id ON purchases(user_id);
CREATE INDEX IF NOT EXISTS idx_purchases_asset_id ON purchases(asset_id);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE bids ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchases ENABLE ROW LEVEL SECURITY;

-- Users policies (allow all operations for now)
CREATE POLICY select_policy_users ON users FOR SELECT USING (true);
CREATE POLICY insert_policy_users ON users FOR INSERT WITH CHECK (true);
CREATE POLICY update_policy_users ON users FOR UPDATE USING (true);
CREATE POLICY delete_policy_users ON users FOR DELETE USING (true);

-- Jobs policies
CREATE POLICY select_policy_jobs ON jobs FOR SELECT USING (true);
CREATE POLICY insert_policy_jobs ON jobs FOR INSERT WITH CHECK (true);
CREATE POLICY update_policy_jobs ON jobs FOR UPDATE USING (true);
CREATE POLICY delete_policy_jobs ON jobs FOR DELETE USING (true);

-- Bids policies
CREATE POLICY select_policy_bids ON bids FOR SELECT USING (true);
CREATE POLICY insert_policy_bids ON bids FOR INSERT WITH CHECK (true);
CREATE POLICY update_policy_bids ON bids FOR UPDATE USING (true);
CREATE POLICY delete_policy_bids ON bids FOR DELETE USING (true);

-- Posts policies
CREATE POLICY select_policy_posts ON posts FOR SELECT USING (true);
CREATE POLICY insert_policy_posts ON posts FOR INSERT WITH CHECK (true);
CREATE POLICY update_policy_posts ON posts FOR UPDATE USING (true);
CREATE POLICY delete_policy_posts ON posts FOR DELETE USING (true);

-- Comments policies
CREATE POLICY select_policy_comments ON comments FOR SELECT USING (true);
CREATE POLICY insert_policy_comments ON comments FOR INSERT WITH CHECK (true);
CREATE POLICY update_policy_comments ON comments FOR UPDATE USING (true);
CREATE POLICY delete_policy_comments ON comments FOR DELETE USING (true);

-- Assets policies
CREATE POLICY select_policy_assets ON assets FOR SELECT USING (true);
CREATE POLICY insert_policy_assets ON assets FOR INSERT WITH CHECK (true);
CREATE POLICY update_policy_assets ON assets FOR UPDATE USING (true);
CREATE POLICY delete_policy_assets ON assets FOR DELETE USING (true);

-- Purchases policies
CREATE POLICY select_policy_purchases ON purchases FOR SELECT USING (true);
CREATE POLICY insert_policy_purchases ON purchases FOR INSERT WITH CHECK (true);
CREATE POLICY update_policy_purchases ON purchases FOR UPDATE USING (true);
CREATE POLICY delete_policy_purchases ON purchases FOR DELETE USING (true);
