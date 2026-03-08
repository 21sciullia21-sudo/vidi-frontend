-- Add before/after comparison column to posts table
-- Note: We determine if a post is before/after by checking if after_image_url is present
ALTER TABLE posts 
  ADD COLUMN IF NOT EXISTS after_image_url TEXT;

-- Remove the is_screenshot column as it's no longer needed
ALTER TABLE posts 
  DROP COLUMN IF EXISTS is_screenshot;

-- Add comment for clarity
COMMENT ON COLUMN posts.after_image_url IS 'URL of the after image for before/after comparisons. If present, this is a before/after post.';
