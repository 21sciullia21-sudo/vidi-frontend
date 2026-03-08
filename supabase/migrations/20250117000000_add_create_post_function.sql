-- Create a database function to insert posts, bypassing schema cache issues
CREATE OR REPLACE FUNCTION create_post(
  p_id UUID,
  p_user_id UUID,
  p_content TEXT,
  p_image_urls JSONB DEFAULT '[]'::jsonb,
  p_video_urls JSONB DEFAULT '[]'::jsonb,
  p_likes JSONB DEFAULT '[]'::jsonb,
  p_comment_count INT DEFAULT 0,
  p_created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  p_is_color_graded BOOLEAN DEFAULT false,
  p_camera_info JSONB DEFAULT NULL,
  p_clip_length INT DEFAULT NULL,
  p_video_format TEXT DEFAULT NULL,
  p_image_camera_info JSONB DEFAULT NULL,
  p_image_format TEXT DEFAULT NULL,
  p_after_image_url TEXT DEFAULT NULL
)
RETURNS posts
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  new_post posts;
BEGIN
  INSERT INTO posts (
    id,
    user_id,
    content,
    image_urls,
    video_urls,
    likes,
    comment_count,
    created_at,
    is_color_graded,
    camera_info,
    clip_length,
    video_format,
    image_camera_info,
    image_format,
    after_image_url
  )
  VALUES (
    p_id,
    p_user_id,
    p_content,
    p_image_urls,
    p_video_urls,
    p_likes,
    p_comment_count,
    p_created_at,
    p_is_color_graded,
    p_camera_info,
    p_clip_length,
    p_video_format,
    p_image_camera_info,
    p_image_format,
    p_after_image_url
  )
  RETURNING * INTO new_post;
  
  RETURN new_post;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION create_post TO authenticated;
GRANT EXECUTE ON FUNCTION create_post TO anon;
