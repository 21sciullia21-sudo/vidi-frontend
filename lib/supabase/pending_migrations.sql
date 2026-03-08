-- Add video metadata columns to posts table
ALTER TABLE posts 
  ADD COLUMN IF NOT EXISTS video_urls TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS camera_info JSONB,
  ADD COLUMN IF NOT EXISTS clip_length INTEGER,
  ADD COLUMN IF NOT EXISTS is_color_graded BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS video_format TEXT;

-- Add index for faster video posts queries
CREATE INDEX IF NOT EXISTS idx_posts_video_urls ON posts USING GIN (video_urls);
