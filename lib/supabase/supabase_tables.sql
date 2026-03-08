DROP TABLE IF EXISTS purchases CASCADE;
DROP TABLE IF EXISTS assets CASCADE;
DROP TABLE IF EXISTS comments CASCADE;
DROP TABLE IF EXISTS posts CASCADE;
DROP TABLE IF EXISTS bids CASCADE;
DROP TABLE IF EXISTS jobs CASCADE;
DROP TABLE IF EXISTS payment_methods CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Create users table
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username TEXT NOT NULL,
  full_name TEXT DEFAULT '',
  email TEXT UNIQUE NOT NULL,
  avatar_url TEXT DEFAULT '',
  bio TEXT DEFAULT '',
  user_role TEXT DEFAULT 'freelancer',
  skill_level TEXT DEFAULT 'Beginner',
  hourly_rate NUMERIC DEFAULT 0,
  location TEXT DEFAULT '',
  project_count INTEGER DEFAULT 0,
  followers INTEGER DEFAULT 0,
  following INTEGER DEFAULT 0,
  specializations TEXT[] DEFAULT ARRAY[]::TEXT[],
  following_ids TEXT[] DEFAULT ARRAY[]::TEXT[],
  is_new BOOLEAN DEFAULT false,
  instagram_url TEXT DEFAULT '',
  twitter_url TEXT DEFAULT '',
  youtube_url TEXT DEFAULT '',
  linkedin_url TEXT DEFAULT '',
  website_url TEXT DEFAULT '',
  portfolio_url TEXT DEFAULT '',
  portfolio_file TEXT DEFAULT '',
  editing_style TEXT DEFAULT NULL,
  gear_badges TEXT[] DEFAULT ARRAY[]::TEXT[],
  featured_reel_url TEXT DEFAULT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT fk_users_auth FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE
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
  reference_images TEXT[] DEFAULT ARRAY[]::TEXT[],
  posted_at TIMESTAMPTZ DEFAULT NOW(),
  bid_count INTEGER DEFAULT 0
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
  status TEXT DEFAULT 'pending'
);

-- Create posts table (matches PostModel exactly)
CREATE TABLE IF NOT EXISTS posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  image_urls TEXT[] DEFAULT ARRAY[]::TEXT[],
  video_urls TEXT[] DEFAULT ARRAY[]::TEXT[],
  likes TEXT[] DEFAULT ARRAY[]::TEXT[],
  comment_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  camera_info JSONB DEFAULT NULL,
  clip_length INTEGER DEFAULT NULL,
  is_color_graded BOOLEAN DEFAULT FALSE,
  video_format TEXT DEFAULT NULL
);

-- Create comments table
CREATE TABLE IF NOT EXISTS comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create assets table (matches AssetModel exactly)
CREATE TABLE IF NOT EXISTS assets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id UUID REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  price DECIMAL NOT NULL,
  category TEXT NOT NULL,
  image_url TEXT DEFAULT '',
  download_url TEXT DEFAULT '',
  downloads INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create purchases table (matches PurchaseModel exactly)
CREATE TABLE IF NOT EXISTS purchases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  asset_id UUID REFERENCES assets(id) ON DELETE CASCADE,
  stripe_session_id TEXT DEFAULT NULL,
  status TEXT DEFAULT 'paid',
  amount DECIMAL NOT NULL,
  purchased_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create payment_methods table (metadata only, no card numbers)
CREATE TABLE IF NOT EXISTS payment_methods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  brand TEXT NOT NULL,
  last4 TEXT NOT NULL,
  exp_month INTEGER NOT NULL CHECK (exp_month BETWEEN 1 AND 12),
  exp_year INTEGER NOT NULL,
  is_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_jobs_client_id ON jobs(client_id);
CREATE INDEX IF NOT EXISTS idx_jobs_posted_at ON jobs(posted_at);
CREATE INDEX IF NOT EXISTS idx_bids_job_id ON bids(job_id);
CREATE INDEX IF NOT EXISTS idx_bids_editor_id ON bids(editor_id);
CREATE INDEX IF NOT EXISTS idx_bids_submitted_at ON bids(submitted_at);
CREATE INDEX IF NOT EXISTS idx_posts_user_id ON posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts(created_at);
CREATE INDEX IF NOT EXISTS idx_posts_is_color_graded ON posts(is_color_graded);
CREATE INDEX IF NOT EXISTS idx_posts_video_format ON posts(video_format);
CREATE INDEX IF NOT EXISTS idx_users_editing_style ON users(editing_style);
CREATE INDEX IF NOT EXISTS idx_comments_post_id ON comments(post_id);
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON comments(user_id);
CREATE INDEX IF NOT EXISTS idx_assets_seller_id ON assets(seller_id);
CREATE INDEX IF NOT EXISTS idx_purchases_user_id ON purchases(user_id);
CREATE INDEX IF NOT EXISTS idx_purchases_asset_id ON purchases(asset_id);
CREATE INDEX IF NOT EXISTS idx_purchases_stripe_session_id ON purchases(stripe_session_id);
CREATE INDEX IF NOT EXISTS idx_payment_methods_user_id ON payment_methods(user_id);

-- Ensure storage buckets needed for media uploads exist and remain public
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

UPDATE storage.buckets
SET public = TRUE
WHERE id IN ('images', 'videos');
