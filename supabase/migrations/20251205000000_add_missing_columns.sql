-- Add missing columns to bids table
ALTER TABLE bids ADD COLUMN IF NOT EXISTS accepted_at TIMESTAMPTZ;

-- Add missing columns to jobs table
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS assigned_editor_id UUID REFERENCES users(id) ON DELETE SET NULL;

-- Create index for the new column
CREATE INDEX IF NOT EXISTS idx_jobs_assigned_editor ON jobs(assigned_editor_id);
