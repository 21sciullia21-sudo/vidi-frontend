const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

module.exports = async (req, res) => {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).end('Method Not Allowed');
  }

  try {
    const { assetIds, buyerId, sellerStripeAccountId, amount, currency = 'usd' } = req.body;

    if (!assetIds || !buyerId || !sellerStripeAccountId || !amount) {
      return res.status(400).json({ error: 'Missing required parameters' });
    }

    const assetIdString = Array.isArray(assetIds) ? assetIds.join(',') : assetIds;
    const applicationFeeAmount = Math.round(amount * 0.10); // 10% Platform Fee

    // FIX: Create a PaymentIntent instead of a Checkout Session
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount,
      currency: currency,
      payment_method_types: ['card'],
      application_fee_amount: applicationFeeAmount,
      transfer_data: {
        destination: sellerStripeAccountId,
      },
      // Keep the metadata at the top level so the webhook can read it!
      metadata: {
        assetIds: assetIdString,
        buyerId: buyerId,
      },
    });

    // Send the secret key back to open the in-app checkout screen
    res.status(200).json({
      clientSecret: paymentIntent.client_secret,
    });
  } catch (error) {
    console.error('Error creating payment intent:', error);
    res.status(500).json({ error: error.message });
  }
};