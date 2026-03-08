// Stripe Webhook: records purchases and emails download links
// Endpoint: stripe-webhook
// Required Supabase secrets (set in Project Settings > Functions > Secrets):
// - STRIPE_SECRET_KEY
// - STRIPE_WEBHOOK_SECRET
// - SUPABASE_URL
// - SUPABASE_SERVICE_ROLE_KEY
// - RESEND_API_KEY (for email delivery)
// - RESEND_FROM (e.g. 'Vidi <noreply@your-domain.com>')

import Stripe from 'https://esm.sh/stripe@14.21.0/deno/stripe.mjs'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2?target=deno'

const STRIPE_SECRET_KEY = Deno.env.get('STRIPE_SECRET_KEY')
const STRIPE_WEBHOOK_SECRET = Deno.env.get('STRIPE_WEBHOOK_SECRET')
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')
const RESEND_FROM = Deno.env.get('RESEND_FROM') || 'Vidi <onboarding@resend.dev>'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, stripe-signature',
}

// Stripe SDK is imported via the Deno bundle above. We use the async verification API
// which relies on WebCrypto/SubtleCrypto and avoids Node polyfills.

const jsonResponse = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    if (!STRIPE_SECRET_KEY || !STRIPE_WEBHOOK_SECRET) return jsonResponse({ error: 'Stripe secrets not configured' }, 500)
    if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) return jsonResponse({ error: 'Supabase secrets not configured' }, 500)

    const sig = req.headers.get('stripe-signature')
    if (!sig) return jsonResponse({ error: 'Missing Stripe signature' }, 400)

    // Read raw body text for signature verification
    const bodyText = await req.text()

    // Redacted diagnostics to help debug signature mismatches (no sensitive data)
    try {
      const ua = req.headers.get('user-agent') || ''
      const ct = req.headers.get('content-type') || ''
      const cl = req.headers.get('content-length') || ''
      const parts = Object.fromEntries(
        (sig || '')
          .split(',')
          .map((p) => p.trim().split('=') as [string, string])
          .filter(([k, v]) => k && v),
      ) as Record<string, string>
      const maskedSig = parts.v1 ? `${parts.v1.slice(0, 8)}…(${parts.v1.length})` : 'missing'
      console.log('[stripe-webhook] diag', {
        method: req.method,
        url: new URL(req.url).pathname,
        ua: ua.includes('Stripe') ? 'Stripe/*' : ua.slice(0, 40),
        contentType: ct,
        contentLength: cl,
        bodyLength: bodyText.length,
        sig: { hasT: Boolean(parts.t), v1: maskedSig },
      })
    } catch (_) {
      // best-effort logging; ignore failures
    }

    let event: Stripe.Event
    try {
      // Use async verification to ensure compatibility with Deno edge runtime
      event = await Stripe.webhooks.constructEventAsync(bodyText, sig, STRIPE_WEBHOOK_SECRET)
    } catch (err) {
      // Include minimal non-sensitive diagnostics
      const ct = req.headers.get('content-type') || ''
      const cl = req.headers.get('content-length') || ''
      console.error('❌ Webhook signature verification failed', {
        message: (err as Error)?.message || String(err),
        contentType: ct,
        contentLength: cl,
        bodyLength: bodyText.length,
      })
      return jsonResponse({ error: 'Invalid signature' }, 400)
    }

    if (event.type !== 'checkout.session.completed') return jsonResponse({ received: true, ignored: event.type })

    const session = event.data.object as Stripe.Checkout.Session
    const metadata = session.metadata || {}
    const userId = String(metadata.userId || '')
    const assetIds = String(metadata.assetIds || '')
      .split(',')
      .map((s) => s.trim())
      .filter((s) => s.length > 0)

    const email = (session.customer_email || session.customer_details?.email || '').toString()

    if (!userId || assetIds.length === 0) return jsonResponse({ error: 'Missing metadata' }, 400)

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // 1) Fetch asset details (including price)
    const { data: assets, error: assetsErr } = await supabase
      .from('assets')
      .select('id,title,price,download_url')
      .in('id', assetIds)

    if (assetsErr) console.error('❌ Failed fetching assets', assetsErr)
    const assetMap = new Map(assets?.map((a) => [a.id, a]) || [])

    // 2) Record purchases
    const purchaseRows = assetIds.map((assetId) => {
      const asset = assetMap.get(assetId)
      return {
        user_id: userId,
        asset_id: assetId,
        stripe_session_id: session.id,
        amount: asset?.price || 0,
        status: 'paid',
      }
    })

    const { error: insertErr } = await supabase.from('purchases').insert(purchaseRows)
    if (insertErr) return jsonResponse({ error: 'Failed to record purchase' }, 500)

    // 3) Generate signed URLs when necessary
    const links: { title: string; url: string }[] = []
    for (const a of assets ?? []) {
      const ref: string = a.download_url || ''
      let url = ref
      if (ref && !ref.startsWith('http')) {
        // treat as storage reference: bucket/path
        const normalized = ref.startsWith('/') ? ref.slice(1) : ref
        const [bucket, ...rest] = normalized.split('/')
        const path = rest.join('/')
        if (bucket && path) {
          try {
            const { data, error } = await supabase.storage.from(bucket).createSignedUrl(path, 60 * 60 * 24)
            if (error) throw error
            url = data?.signedUrl ?? url
          } catch (_) {
            try {
              url = supabase.storage.from(bucket).getPublicUrl(path).data.publicUrl
            } catch (_) {}
          }
        }
      }
      links.push({ title: a.title || 'Download', url })
    }

    // 4) Send email with links (Resend)
    if (!RESEND_API_KEY) {
      console.warn('⚠️ RESEND_API_KEY not configured; skipping email send')
    } else if (email) {
      const html = `
        <div style="font-family: Inter, system-ui, -apple-system, Segoe UI, Roboto, Arial; line-height:1.6; color:#0f172a;">
          <h2 style="margin:0 0 12px;">Thanks for your purchase!</h2>
          <p style="margin:0 0 16px;">Here are your download links:</p>
          <ul style="padding-left:18px;">
            ${links.map((l) => `<li style="margin-bottom:10px"><strong>${escapeHtml(l.title)}</strong><br/><a href="${l.url}" target="_blank">${l.url}</a></li>`).join('')}
          </ul>
          <p style="margin-top:16px; font-size:13px; color:#475569;">Links expire in 24 hours. Save them now; you can revisit this email to fetch fresh links later.</p>
        </div>`

      const res = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: { Authorization: `Bearer ${RESEND_API_KEY}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ from: RESEND_FROM, to: [email], subject: 'Your Vidi downloads', html }),
      })
      if (!res.ok) console.error('❌ Failed sending email via Resend', await res.text())
    }

    return jsonResponse({ received: true })
  } catch (error) {
    return jsonResponse({ error: (error as Error).message ?? String(error) }, 400)
  }
})

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;')
}
