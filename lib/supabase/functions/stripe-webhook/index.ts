// supabase/functions/stripe-webhook/index.ts
// Stripe webhook using async verification in Deno (no Node shims)
// - Reads the raw request body exactly as sent by Stripe
// - Uses constructEventAsync to verify with SubtleCrypto
// - Avoids any std/node polyfills
// - Includes CORS handling for safety (does not affect Stripe)

import Stripe from "https://esm.sh/stripe@14.21.0/deno/stripe.mjs";

// Required: set in Supabase > Edge Functions > Secrets
const STRIPE_WEBHOOK_SECRET = Deno.env.get("STRIPE_WEBHOOK_SECRET") ?? "";
if (!STRIPE_WEBHOOK_SECRET) {
  console.error("Missing STRIPE_WEBHOOK_SECRET environment variable");
}

const CORS_HEADERS = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization, x-client-info, apikey, content-type",
  "access-control-allow-methods": "POST, OPTIONS",
  "access-control-max-age": "86400",
};

// Helper to respond with JSON + CORS
const json = (data: unknown, status = 200): Response =>
  new Response(JSON.stringify(data), {
    status,
    headers: { "content-type": "application/json", ...CORS_HEADERS },
  });

Deno.serve(async (req: Request) => {
  // Preflight
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: CORS_HEADERS });

  // Only accept POSTs from Stripe
  if (req.method !== "POST") return json({ error: "Method Not Allowed" }, 405);

  try {
    // IMPORTANT: Read raw body BEFORE any parsing. Signature verification must use raw bytes/text.
    const rawBody = await req.text();

    // Header can be cased either way depending on infra
    const sig = req.headers.get("stripe-signature") ?? req.headers.get("Stripe-Signature");
    if (!sig) return json({ error: "Missing stripe-signature header" }, 400);

    // Verify using async API (uses WebCrypto/SubtleCrypto under the hood in Deno)
    // Use the static webhooks helper to avoid any instance/null typing issues.
    let event: any;
    try {
      event = await Stripe.webhooks.constructEventAsync(rawBody, sig, STRIPE_WEBHOOK_SECRET);
    } catch (err) {
      console.error("❌ Webhook signature verification failed:", err);
      return json({ error: `Webhook Error: ${(err as Error).message}` }, 400);
    }

    // Minimal routing – extend with your business logic as needed
    switch (event.type) {
      case "checkout.session.completed": {
        // const session = event.data.object;
        console.log("checkout.session.completed", event.id);
        break;
      }
      case "payment_intent.succeeded": {
        // const pi = event.data.object;
        console.log("payment_intent.succeeded", event.id);
        break;
      }
      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    return json({ received: true }, 200);
  } catch (err) {
    console.error("Unhandled webhook error:", err);
    return json({ error: (err as Error).message ?? String(err) }, 500);
  }
});
