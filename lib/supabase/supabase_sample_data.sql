-- Helper function to insert users into auth.users table
CREATE OR REPLACE FUNCTION insert_user_to_auth(
    email text,
    password text
) RETURNS UUID AS $$
DECLARE
  user_id uuid;
  encrypted_pw text;
BEGIN
  user_id := gen_random_uuid();
  encrypted_pw := crypt(password, gen_salt('bf'));
  
  INSERT INTO auth.users
    (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES
    (gen_random_uuid(), user_id, 'authenticated', 'authenticated', email, encrypted_pw, '2023-05-03 19:41:43.585805+00', '2023-04-22 13:10:03.275387+00', '2023-04-22 13:10:31.458239+00', '{"provider":"email","providers":["email"]}', '{}', '2023-05-03 19:41:43.580424+00', '2023-05-03 19:41:43.585948+00', '', '', '', '');
  
  INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES
    (gen_random_uuid(), user_id, format('{"sub":"%s","email":"%s"}', user_id::text, email)::jsonb, 'email', '2022-05-03 19:41:43.582456+00', '2022-05-03 19:41:43.582497+00', '2022-05-03 19:41:43.582497+00');
  
  RETURN user_id;
END;
$$ LANGUAGE plpgsql;

-- Insert into auth.users using the helper function
SELECT insert_user_to_auth('client@example.com', 'password123');
SELECT insert_user_to_auth('freelancer1@example.com', 'password123');
SELECT insert_user_to_auth('freelancer2@example.com', 'password123');
SELECT insert_user_to_auth('editor@example.com', 'password123');
SELECT insert_user_to_auth('artist@example.com', 'password123');
SELECT insert_user_to_auth('designer@example.com', 'password123');
SELECT insert_user_to_auth('writer@example.com', 'password123');
SELECT insert_user_to_auth('photographer@example.com', 'password123');
SELECT insert_user_to_auth('musician@example.com', 'password123');
SELECT insert_user_to_auth('developer@example.com', 'password123');

-- Insert into users table
INSERT INTO users (id, username, full_name, email, avatar_url, bio, user_role, skill_level, hourly_rate, location, project_count, followers, following, specializations, following_ids, is_new, instagram_url, twitter_url, youtube_url, linkedin_url, website_url, portfolio_url, portfolio_file)
SELECT
    (SELECT id FROM auth.users WHERE email = 'client@example.com'),
    'client_user',
    'Client User',
    'client@example.com',
    'https://picsum.photos/id/1005/200/200',
    'A client looking for creative talent.',
    'client',
    'Intermediate',
    0,
    'New York, USA',
    5,
    10,
    2,
    '{"Project Management"}',
    '{}',
    FALSE,
    'https://instagram.com/client',
    'https://twitter.com/client',
    'https://youtube.com/client',
    'https://linkedin.com/in/client',
    'https://client.com',
    'https://client.com/portfolio',
    'client_portfolio.pdf'
UNION ALL
SELECT
    (SELECT id FROM auth.users WHERE email = 'freelancer1@example.com'),
    'freelancer_one',
    'Freelancer One',
    'freelancer1@example.com',
    'https://picsum.photos/id/1011/200/200',
    'Experienced graphic designer with a passion for branding.',
    'freelancer',
    'Expert',
    50.00,
    'London, UK',
    12,
    150,
    30,
    '{"Graphic Design", "Branding", "UI/UX"}',
    '{}',
    FALSE,
    'https://instagram.com/freelancer1',
    'https://twitter.com/freelancer1',
    'https://youtube.com/freelancer1',
    'https://linkedin.com/in/freelancer1',
    'https://freelancer1.com',
    'https://freelancer1.com/portfolio',
    'freelancer1_portfolio.zip'
UNION ALL
SELECT
    (SELECT id FROM auth.users WHERE email = 'freelancer2@example.com'),
    'freelancer_two',
    'Freelancer Two',
    'freelancer2@example.com',
    'https://picsum.photos/id/1012/200/200',
    'Video editor specializing in short-form content and motion graphics.',
    'freelancer',
    'Advanced',
    40.00,
    'Berlin, Germany',
    8,
    80,
    15,
    '{"Video Editing", "Motion Graphics", "Color Grading"}',
    '{}',
    FALSE,
    'https://instagram.com/freelancer2',
    'https://twitter.com/freelancer2',
    'https://youtube.com/freelancer2',
    'https://linkedin.com/in/freelancer2',
    'https://freelancer2.com',
    'https://freelancer2.com/portfolio',
    'freelancer2_portfolio.mov'
UNION ALL
SELECT
    (SELECT id FROM auth.users WHERE email = 'editor@example.com'),
    'pro_editor',
    'Professional Editor',
    'editor@example.com',
    'https://picsum.photos/id/1015/200/200',
    'Highly skilled video editor with 10+ years experience.',
    'freelancer',
    'Expert',
    65.00,
    'Los Angeles, USA',
    20,
    250,
    50,
    '{"Video Editing", "Post-Production", "VFX"}',
    '{}',
    FALSE,
    'https://instagram.com/editor',
    'https://twitter.com/editor',
    'https://youtube.com/editor',
    'https://linkedin.com/in/editor',
    'https://editor.com',
    'https://editor.com/portfolio',
    'editor_reel.mp4'
UNION ALL
SELECT
    (SELECT id FROM auth.users WHERE email = 'artist@example.com'),
    'digital_artist',
    'Digital Artist',
    'artist@example.com',
    'https://picsum.photos/id/1018/200/200',
    'Illustrator and concept artist.',
    'freelancer',
    'Advanced',
    45.00,
    'Tokyo, Japan',
    10,
    180,
    25,
    '{"Illustration", "Concept Art", "Digital Painting"}',
    '{}',
    FALSE,
    'https://instagram.com/artist',
    'https://twitter.com/artist',
    'https://youtube.com/artist',
    'https://linkedin.com/in/artist',
    'https://artist.com',
    'https://artist.com/portfolio',
    'artist_gallery.jpg'
UNION ALL
SELECT
    (SELECT id FROM auth.users WHERE email = 'designer@example.com'),
    'web_designer',
    'Web Designer',
    'designer@example.com',
    'https://picsum.photos/id/1025/200/200',
    'Frontend developer and UI/UX designer.',
    'freelancer',
    'Expert',
    55.00,
    'Sydney, Australia',
    15,
    200,
    40,
    '{"UI/UX Design", "Web Development", "Frontend"}',
    '{}',
    FALSE,
    'https://instagram.com/designer',
    'https://twitter.com/designer',
    'https://youtube.com/designer',
    'https://linkedin.com/in/designer',
    'https://designer.com',
    'https://designer.com/portfolio',
    'designer_showcase.pdf'
UNION ALL
SELECT
    (SELECT id FROM auth.users WHERE email = 'writer@example.com'),
    'content_writer',
    'Content Writer',
    'writer@example.com',
    'https://picsum.photos/id/1027/200/200',
    'SEO-focused content writer for blogs and websites.',
    'freelancer',
    'Intermediate',
    30.00,
    'Toronto, Canada',
    7,
    60,
    10,
    '{"Content Writing", "SEO", "Copywriting"}',
    '{}',
    FALSE,
    'https://instagram.com/writer',
    'https://twitter.com/writer',
    'https://youtube.com/writer',
    'https://linkedin.com/in/writer',
    'https://writer.com',
    'https://writer.com/portfolio',
    'writer_samples.docx'
UNION ALL
SELECT
    (SELECT id FROM auth.users WHERE email = 'photographer@example.com'),
    'event_photographer',
    'Event Photographer',
    'photographer@example.com',
    'https://picsum.photos/id/1033/200/200',
    'Specializing in event and portrait photography.',
    'freelancer',
    'Advanced',
    70.00,
    'Paris, France',
    18,
    300,
    60,
    '{"Photography", "Event Photography", "Portrait Photography"}',
    '{}',
    FALSE,
    'https://instagram.com/photographer',
    'https://twitter.com/photographer',
    'https://youtube.com/photographer',
    'https://linkedin.com/in/photographer',
    'https://photographer.com',
    'https://photographer.com/portfolio',
    'photographer_gallery.zip'
UNION ALL
SELECT
    (SELECT id FROM auth.users WHERE email = 'musician@example.com'),
    'sound_designer',
    'Sound Designer',
    'musician@example.com',
    'https://picsum.photos/id/1035/200/200',
    'Composer and sound designer for games and film.',
    'freelancer',
    'Expert',
    60.00,
    'Stockholm, Sweden',
    9,
    100,
    20,
    '{"Sound Design", "Music Composition", "Audio Production"}',
    '{}',
    FALSE,
    'https://instagram.com/musician',
    'https://twitter.com/musician',
    'https://youtube.com/musician',
    'https://linkedin.com/in/musician',
    'https://musician.com',
    'https://musician.com/portfolio',
    'musician_demo_reel.mp3'
UNION ALL
SELECT
    (SELECT id FROM auth.users WHERE email = 'developer@example.com'),
    'fullstack_dev',
    'Fullstack Developer',
    'developer@example.com',
    'https://picsum.photos/id/1039/200/200',
    'Web and mobile application developer.',
    'freelancer',
    'Expert',
    80.00,
    'San Francisco, USA',
    25,
    400,
    80,
    '{"Web Development", "Mobile Development", "Backend Development"}',
    '{}',
    FALSE,
    'https://instagram.com/developer',
    'https://twitter.com/developer',
    'https://youtube.com/developer',
    'https://linkedin.com/in/developer',
    'https://developer.com',
    'https://developer.com/portfolio',
    'developer_projects.zip';

-- Update following_ids for some users
UPDATE users
SET following_ids = ARRAY[
    (SELECT id::TEXT FROM users WHERE email = 'freelancer1@example.com'),
    (SELECT id::TEXT FROM users WHERE email = 'freelancer2@example.com')
]
WHERE email = 'client@example.com';

UPDATE users
SET following_ids = ARRAY[
    (SELECT id::TEXT FROM users WHERE email = 'editor@example.com'),
    (SELECT id::TEXT FROM users WHERE email = 'artist@example.com')
]
WHERE email = 'freelancer1@example.com';

-- Insert into jobs table
INSERT INTO jobs (title, description, category, budget_min, budget_max, deadline, client_id, status, requirements, reference_images, posted_at, bid_count)
SELECT
    'Logo Design for Tech Startup',
    'We need a modern and minimalist logo for our new tech startup. The logo should be scalable and work well across various platforms.',
    'Graphic Design',
    500.00,
    1000.00,
    NOW() + INTERVAL '14 days',
    (SELECT id FROM users WHERE email = 'client@example.com'),
    'open',
    'Vector format, brand guidelines, 3 revisions.',
    ARRAY['https://picsum.photos/id/237/200/300', 'https://picsum.photos/id/238/200/300'],
    NOW() - INTERVAL '5 days',
    2
UNION ALL
SELECT
    'Short Video Ad for Social Media',
    'Looking for a creative video editor to produce a 30-second social media ad. Footage will be provided, but creative input is highly valued.',
    'Video Editing',
    800.00,
    1500.00,
    NOW() + INTERVAL '10 days',
    (SELECT id FROM users WHERE email = 'client@example.com'),
    'open',
    'Final output in 1080p, suitable for Instagram/Facebook, background music.',
    ARRAY['https://picsum.photos/id/239/200/300', 'https://picsum.photos/id/240/200/300'],
    NOW() - INTERVAL '3 days',
    1
UNION ALL
SELECT
    'Website Redesign for E-commerce',
    'Our existing e-commerce website needs a complete redesign to improve user experience and conversion rates. Focus on modern aesthetics and mobile responsiveness.',
    'Web Development',
    3000.00,
    6000.00,
    NOW() + INTERVAL '30 days',
    (SELECT id FROM users WHERE email = 'client@example.com'),
    'open',
    'Figma prototypes, responsive design, SEO friendly, integration with Shopify.',
    ARRAY['https://picsum.photos/id/241/200/300', 'https://picsum.photos/id/242/200/300'],
    NOW() - INTERVAL '7 days',
    0
UNION ALL
SELECT
    'Blog Post Series on AI',
    'Need a series of 5 blog posts (1000 words each) on the latest advancements in Artificial Intelligence. Content should be engaging and informative.',
    'Content Writing',
    750.00,
    1200.00,
    NOW() + INTERVAL '21 days',
    (SELECT id FROM users WHERE email = 'client@example.com'),
    'open',
    'SEO optimized, original content, research-backed, quick turnaround.',
    '{}',
    NOW() - INTERVAL '2 days',
    0
UNION ALL
SELECT