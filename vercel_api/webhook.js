const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

module.exports = async (req, res) => {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).end('Method Not Allowed');
  }

  const sig = req.headers['stripe-signature'];
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

  let event;

  try {
    // Note: ensure raw body parsing is handled correctly in Vercel
    event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
  } catch (err) {
    console.error(`Webhook Error: ${err.message}`);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  if (event.type === 'payment_intent.succeeded') {
    const paymentIntent = event.data.object;
    const { assetIds, buyerId } = paymentIntent.metadata;

    if (assetIds && buyerId) {
      const assetIdList = assetIds.split(',');

      try {
        // Create purchase records for all assets
        const purchases = assetIdList.map(assetId => ({
          user_id: buyerId,
          asset_id: assetId.trim(),
          stripe_payment_intent_id: paymentIntent.id,
          amount: Math.round(paymentIntent.amount / assetIdList.length), // Split amount or store total? Storing split approximation.
          currency: paymentIntent.currency,
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
        
        console.log(`Purchases recorded for User ${buyerId} and Assets ${assetIds}`);
      } catch (err) {
        console.error('Error inserting into Supabase:', err);
        return res.status(500).json({ error: 'Internal Server Error' });
      }
    }
  }

  res.status(200).json({ received: true });
};
