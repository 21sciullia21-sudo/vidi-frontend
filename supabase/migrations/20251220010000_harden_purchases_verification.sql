-- Ensure purchases table supports Stripe verification lookups
ALTER TABLE purchases ADD COLUMN IF NOT EXISTS stripe_session_id text;
ALTER TABLE purchases ADD COLUMN IF NOT EXISTS status text DEFAULT 'paid';

CREATE INDEX IF NOT EXISTS idx_purchases_stripe_session_id ON purchases(stripe_session_id);
CREATE INDEX IF NOT EXISTS idx_purchases_user_session ON purchases(user_id, stripe_session_id);

-- Restrict purchases visibility to the owning user while permitting service role access
DROP POLICY IF EXISTS purchases_select_policy ON purchases;
CREATE POLICY purchases_select_policy ON purchases
  FOR SELECT
  USING (auth.role() = 'service_role' OR auth.uid() = user_id);

DROP POLICY IF EXISTS purchases_insert_policy ON purchases;
CREATE POLICY purchases_insert_policy ON purchases
  FOR INSERT
  WITH CHECK (auth.role() = 'service_role' OR auth.uid() = user_id);

DROP POLICY IF EXISTS purchases_update_policy ON purchases;
CREATE POLICY purchases_update_policy ON purchases
  FOR UPDATE
  USING (auth.role() = 'service_role' OR auth.uid() = user_id)
  WITH CHECK (auth.role() = 'service_role' OR auth.uid() = user_id);

DROP POLICY IF EXISTS purchases_delete_policy ON purchases;
CREATE POLICY purchases_delete_policy ON purchases
  FOR DELETE
  USING (auth.role() = 'service_role' OR auth.uid() = user_id);