-- Create the purchases table
create table public.purchases (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  asset_id uuid not null references public.assets(id) on delete cascade,
  stripe_payment_intent_id text,
  amount integer not null, -- amount in cents
  currency text default 'usd',
  status text default 'pending',
  purchased_at timestamptz default now(),
  
  constraint purchases_pkey primary key (id)
);

-- Add RLS policies
alter table public.purchases enable row level security;

-- Policy: Users can view their own purchases
create policy "Users can view their own purchases"
  on public.purchases for select
  using (auth.uid() = user_id);

-- Policy: Service role can insert purchases (via webhook)
-- Note: Service role bypasses RLS, but explicit grant is good documentation
-- or grant insert on table public.purchases to service_role;
