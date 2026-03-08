# Stripe Payment Integration Setup

Your app is now configured to accept payments through Stripe! Follow these steps to complete the setup.

## ✅ What's Already Done

- ✅ Stripe Flutter SDK installed and configured
- ✅ Publishable key added to the app
- ✅ Payment flow integrated into checkout page
- ✅ Supabase Edge Function created for secure payment processing

## 🔧 Required Setup Steps

### 1. Deploy the Supabase Edge Function

The payment intent creation must happen on your backend for security. Deploy the Edge Function:

```bash
# Navigate to your project directory
cd your-project-directory

# Deploy the function
supabase functions deploy create-payment-intent
```

### 2. Add Stripe Secret Key to Supabase

⚠️ **Never expose your secret key in client code!**

1. Get your **Secret Key** from Stripe Dashboard:
   - Go to [Stripe Dashboard](https://dashboard.stripe.com/test/apikeys)
   - Copy your **Secret key** (starts with `sk_test_` or `sk_live_`)

2. Add it to Supabase as an environment secret:

```bash
# Set the Stripe secret key
supabase secrets set STRIPE_SECRET_KEY=sk_test_your_secret_key_here
```

Or via Supabase Dashboard:
- Go to **Project Settings** → **Edge Functions** → **Secrets**
- Add: `STRIPE_SECRET_KEY` = `sk_test_...`

### 3. Test Payment Flow

1. **Test Mode**: Your app is using Stripe test keys
   - Use [Stripe test card numbers](https://stripe.com/docs/testing#cards)
   - Example: `4242 4242 4242 4242`
   - Any future expiry date
   - Any 3-digit CVC

2. **Try a purchase**:
   - Add an asset to cart
   - Go to checkout
   - Complete payment with test card
   - Verify purchase appears in your profile

### 4. Switch to Live Mode (Production)

When ready to accept real payments:

1. **Get Live Keys from Stripe**:
   - Complete Stripe account activation
   - Get your live publishable key (`pk_live_...`)
   - Get your live secret key (`sk_live_...`)

2. **Update the app**:
   - Replace test key in `lib/config/stripe_config.dart`
   - Update Supabase secret with live key

3. **Enable Payment Methods**:
   - Configure accepted payment methods in Stripe Dashboard
   - Enable Apple Pay / Google Pay if desired

## 📋 Payment Flow Overview

1. **User clicks "Complete Purchase"**
   → App validates form and shows loading state

2. **Create Payment Intent** (Backend)
   → Supabase Edge Function calls Stripe API
   → Returns client secret to app

3. **Present Payment Sheet** (Frontend)
   → Stripe collects payment details securely
   → Handles 3D Secure / authentication
   → Processes payment

4. **Record Purchase** (Database)
   → App saves purchase record to Supabase
   → User gets confirmation & download access

## 🔒 Security Features

- ✅ Secret keys stored server-side only
- ✅ Payment processing via secure Stripe SDK
- ✅ PCI-compliant payment collection
- ✅ No card data touches your servers
- ✅ Built-in fraud detection

## 🆘 Troubleshooting

### "Failed to initialize payment"
- Check that Edge Function is deployed
- Verify `STRIPE_SECRET_KEY` is set in Supabase
- Check Supabase function logs for errors

### "Payment was cancelled or failed"
- User cancelled payment sheet
- Card declined (check Stripe Dashboard)
- Authentication failed (3D Secure)

### Edge Function Errors
View logs:
```bash
supabase functions logs create-payment-intent
```

## 📚 Additional Resources

- [Stripe Testing](https://stripe.com/docs/testing)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
- [Flutter Stripe Docs](https://pub.dev/packages/flutter_stripe)
- [Stripe Dashboard](https://dashboard.stripe.com)

## 💰 Stripe Fees

- **Test Mode**: Free, no charges
- **Live Mode**: 2.9% + $0.30 per successful charge
- [Full pricing details](https://stripe.com/pricing)
