const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

// HELPER: This prevents Vercel from scrambling Stripe's security signature
const getRawBody = async (req) => {
  const chunks = [];
  for await (const chunk of req) {
    chunks.push(typeof chunk === 'string' ? Buffer.from(chunk) : chunk);
  }
  return Buffer.concat(chunks);
};

module.exports = async (req, res) => {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).end('Method Not Allowed');
  }

  const sig = req.headers['stripe-signature'];
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

  let event;

  try {
    const rawBody = await getRawBody(req);
    event = stripe.webhooks.constructEvent(rawBody, sig, webhookSecret);
  } catch (err) {
    console.error(`Webhook Error: ${err.message}`);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // FIX: Listen for the new Checkout Session event
  if (event.type === 'checkout.session.completed') {
    const session = event.data.object;
    
    // Grab the custom data attached to the checkout
    const assetIds = session.metadata?.assetIds;
    const buyerId = session.metadata?.buyerId;

    if (assetIds && buyerId) {
      const assetIdList = assetIds.split(',');

      try {
        const purchases = assetIdList.map(assetId => ({
          user_id: buyerId,
          asset_id: assetId.trim(),
          stripe_session_id: session.id, // FIX: Matches what your frontend is looking for!
          amount: Math.round(session.amount_total / assetIdList.length), 
          currency: session.currency || 'usd',
          status: 'completed',
          purchased_at: new Date().toISOString(),
        }));

        const { error } = await supabase
          .from('purchases')
          .insert(purchases);

        if (error) {
          console.error('Supabase insert error:', error);
          return res.status(500).json({ error: 'Failed to record purchases' });
        }
        
        console.log(`Successfully saved purchase for User ${buyerId}`);
      } catch (err) {
        console.error('Error inserting into Supabase:', err);
        return res.status(500).json({ error: 'Internal Server Error' });
      }
    } else {
        console.error('Webhook fired, but metadata was missing!');
    }
  }

  res.status(200).json({ received: true });
};