import Stripe from 'https://esm.sh/stripe@14.21.0/deno/stripe.mjs'

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
    return jsonResponse({ error: 'Stripe secret key not configured' }, 500)
  }

  let payload: Record<string, unknown>
  try {
    payload = (await req.json()) as Record<string, unknown>
  } catch (_) {
    return jsonResponse({ error: 'Invalid JSON payload' }, 400)
  }

  const { amount, currency, userId, assetIds, customerEmail, frontendUrl } = payload

  if (!amount || !currency || !userId || !Array.isArray(assetIds) || assetIds.length === 0) {
    return jsonResponse({ error: 'Missing required fields' }, 400)
  }

  const cents = Math.round(Number(amount))
  if (!Number.isFinite(cents) || cents <= 0) {
    return jsonResponse({ error: 'Amount must be a positive number' }, 400)
  }

  const stripe = new Stripe(STRIPE_SECRET_KEY, {
    apiVersion: '2024-06-20',
    httpClient: Stripe.createFetchHttpClient(),
  })

  const rawBase =
    (typeof frontendUrl === 'string' && frontendUrl.trim().length > 0 && frontendUrl.trim()) ||
    req.headers.get('origin') ||
    new URL(req.url).origin

  const baseUrl = rawBase.endsWith('/') ? rawBase.slice(0, -1) : rawBase
  const returnUrl = `${baseUrl}/#/payments/success?session_id={CHECKOUT_SESSION_ID}`

  try {
    const session = await stripe.checkout.sessions.create({
      ui_mode: 'embedded',
      mode: 'payment',
      payment_method_types: ['card'],
      return_url: returnUrl,
      customer_email: typeof customerEmail === 'string' ? customerEmail : undefined,
      line_items: [
        {
          price_data: {
            currency: String(currency).toLowerCase(),
            unit_amount: cents,
            product_data: {
              name: 'Vidi Asset Purchase',
            },
          },
          quantity: 1,
        },
      ],
      metadata: {
        userId: String(userId),
        assetIds: (assetIds as string[]).join(','),
      },
    })

    let clientSecret = session.client_secret ?? undefined
    if (!clientSecret) {
      const retrieved = await stripe.checkout.sessions.retrieve(session.id)
      clientSecret = retrieved.client_secret ?? undefined
    }

    if (!clientSecret) {
      return jsonResponse(
        { error: 'Stripe did not return a client_secret for embedded checkout', sessionId: session.id },
        400,
      )
    }

    return jsonResponse({
      sessionId: session.id,
      sessionUrl: session.url ?? null,
      clientSecret,
    })
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error)
    console.error('Failed to create checkout session', message)
    return jsonResponse({ error: message }, 400)
  }
})