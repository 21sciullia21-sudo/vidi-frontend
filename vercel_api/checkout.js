const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

module.exports = async (req, res) => {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).end('Method Not Allowed');
  }

  try {
    // We accept assetIds (array or comma-separated string) to support multiple items
    // The sellerStripeAccountId is assumed to be the same for all items in this transaction
    const { assetIds, buyerId, sellerStripeAccountId, amount, currency = 'usd' } = req.body;

    if (!assetIds || !buyerId || !sellerStripeAccountId || !amount) {
      return res.status(400).json({ error: 'Missing required parameters' });
    }

    // specific handling for array vs string
    const assetIdString = Array.isArray(assetIds) ? assetIds.join(',') : assetIds;

    // Calculate application fee (e.g., 10%)
    const applicationFeeAmount = Math.round(amount * 0.10);

    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount,
      currency: currency,
      automatic_payment_methods: {
        enabled: true,
      },
      application_fee_amount: applicationFeeAmount,
      transfer_data: {
        destination: sellerStripeAccountId,
      },
      metadata: {
        assetIds: assetIdString, // We store as string to fit in metadata
        buyerId: buyerId,
      },
    });

    res.status(200).json({
      clientSecret: paymentIntent.client_secret,
    });
  } catch (error) {
    console.error('Error creating payment intent:', error);
    res.status(500).json({ error: error.message });
  }
};
