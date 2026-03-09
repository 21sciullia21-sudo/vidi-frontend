const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

module.exports = async (req, res) => {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).end('Method Not Allowed');
  }

  try {
    const { assetIds, buyerId, sellerStripeAccountId, amount, currency = 'usd', assetName } = req.body;

    if (!assetIds || !buyerId || !sellerStripeAccountId || !amount) {
      return res.status(400).json({ error: 'Missing required parameters' });
    }

    const assetIdString = Array.isArray(assetIds) ? assetIds.join(',') : assetIds;
    const applicationFeeAmount = Math.round(amount * 0.10); // 10% Platform Fee

    // Create a Checkout Session instead of a PaymentIntent
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [
        {
          price_data: {
            currency: currency,
            product_data: {
              name: assetName || 'Digital Asset Purchase',
            },
            unit_amount: amount,
          },
          quantity: 1,
        },
      ],
      mode: 'payment',
      
      // FIX 1: Pass the session ID back to Vidiplanet so your frontend can verify it!
      success_url: 'https://www.vidiplanet.com/success?session_id={CHECKOUT_SESSION_ID}',
      cancel_url: 'https://www.vidiplanet.com/cancel',
      
      // FIX 2: Put metadata at the top level so your webhook can actually read it
      metadata: {
        assetIds: assetIdString,
        buyerId: buyerId,
      },

      payment_intent_data: {
        application_fee_amount: applicationFeeAmount,
        transfer_data: {
          destination: sellerStripeAccountId,
        },
        // It's good practice to keep a copy here so it shows up on your Stripe dashboard receipts
        metadata: {
          assetIds: assetIdString,
          buyerId: buyerId,
        },
      },
    });

    // Return the URL so Flutter can open it
    res.status(200).json({
      url: session.url,
    });
  } catch (error) {
    console.error('Error creating checkout session:', error);
    res.status(500).json({ error: error.message });
  }
};