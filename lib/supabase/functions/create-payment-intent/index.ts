
const STRIPE_SECRET_KEY = Deno.env.get('STRIPE_SECRET_KEY')

const CORS_HEADERS = {
  'access-control-allow-origin': '*',
  'access-control-allow-headers': 'authorization, x-client-info, apikey, content-type',
  'access-control-allow-methods': 'POST, OPTIONS',
  'access-control-max-age': '86400',
}

const jsonResponse = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
  })

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS_HEADERS })
  }

  if (!STRIPE_SECRET_KEY) {
    return jsonResponse({ error: 'Stripe not configured' }, 500)
  }

  try {
    const { amount, currency, userId, assetIds } = await req.json()

    if (!amount || !currency || !userId || !Array.isArray(assetIds) || assetIds.length === 0) {
      return jsonResponse({ error: 'Missing required fields' }, 400)
    }

    const cents = Math.round(Number(amount))
    if (!Number.isFinite(cents) || cents <= 0) {
      return jsonResponse({ error: 'Amount must be a positive number' }, 400)
    }

    const resp = await fetch('https://api.stripe.com/v1/payment_intents', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${STRIPE_SECRET_KEY}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        amount: cents.toString(),
        currency: String(currency).toLowerCase(),
        'automatic_payment_methods[enabled]': 'true',
        'metadata[user_id]': String(userId),
        'metadata[asset_ids]': (assetIds as string[]).join(','),
      }),
    })

    const data = await resp.json()
    if (!resp.ok) {
      const message = (data?.error?.message as string) || 'Failed to create payment intent'
      return jsonResponse({ error: message }, 400)
    }

    const clientSecret = data?.client_secret as string | undefined
    if (!clientSecret) {
      return jsonResponse({ error: 'Stripe did not return client_secret' }, 400)
    }

    return jsonResponse({ clientSecret })
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error)
    return jsonResponse({ error: message }, 400)
  }
})
