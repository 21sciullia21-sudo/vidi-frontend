-- Create payment_methods table to store user payment sources metadata
CREATE TABLE IF NOT EXISTS payment_methods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  brand TEXT NOT NULL,
  last4 TEXT NOT NULL,
  exp_month INTEGER NOT NULL CHECK (exp_month BETWEEN 1 AND 12),
  exp_year INTEGER NOT NULL,
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Ensure the purchases table has an amount column to track totals
ALTER TABLE purchases
  ADD COLUMN IF NOT EXISTS amount DECIMAL DEFAULT 0;

-- Enable RLS and scope policies to the authenticated owner
ALTER TABLE payment_methods ENABLE ROW LEVEL SECURITY;

CREATE POLICY payment_methods_select
  ON payment_methods
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY payment_methods_insert
  ON payment_methods
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY payment_methods_update
  ON payment_methods
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY payment_methods_delete
  ON payment_methods
  FOR DELETE
  USING (auth.uid() = user_id);

-- Only one default payment method per user enforced via constraint trigger
CREATE OR REPLACE FUNCTION enforce_single_default_payment_method()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_default THEN
    UPDATE payment_methods
      SET is_default = FALSE
      WHERE user_id = NEW.user_id
        AND id <> NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS payment_methods_single_default
ON payment_methods;

CREATE TRIGGER payment_methods_single_default
  BEFORE INSERT OR UPDATE ON payment_methods
  FOR EACH ROW
  EXECUTE FUNCTION enforce_single_default_payment_method();