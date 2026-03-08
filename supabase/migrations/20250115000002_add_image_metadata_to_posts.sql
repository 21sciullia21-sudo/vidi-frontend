-- Add image metadata columns to posts table
ALTER TABLE posts ADD COLUMN IF NOT EXISTS image_camera_info JSONB;
ALTER TABLE posts ADD COLUMN IF NOT EXISTS image_format TEXT;
ALTER TABLE posts ADD COLUMN IF NOT EXISTS is_screenshot BOOLEAN DEFAULT FALSE;
