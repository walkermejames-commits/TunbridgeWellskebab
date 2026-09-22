// Deploy this function with --no-verify-jwt. Stripe authenticates it by signed webhook.
import Stripe from "npm:stripe@18.4.0";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.97.0";

Deno.serve(async (request) => {
  const stripeSecret = Deno.env.get("STRIPE_SECRET_KEY");
  const endpointSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET");
  const url = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const signature = request.headers.get("stripe-signature");
  if (!stripeSecret || !endpointSecret || !url || !serviceRoleKey || !signature) return new Response("Webhook configuration missing", { status: 400 });

  try {
    const stripe = new Stripe(stripeSecret, { httpClient: Stripe.createFetchHttpClient() });
    const event = await stripe.webhooks.constructEventAsync(await request.text(), signature, endpointSecret);
    const admin = createClient(url, serviceRoleKey, { auth: { persistSession: false } });
    if (event.type === "payment_intent.succeeded") {
      const intent = event.data.object as Stripe.PaymentIntent;
      const orderId = intent.metadata.order_id;
      if (orderId) {
        const { data: order } = await admin.from("orders").select("status").eq("id", orderId).maybeSingle();
        if (order?.status === "pending_payment") {
          await admin.from("orders").update({ status: "paid", payment_status: "paid" }).eq("id", orderId);
          await admin.from("order_status_events").insert({ order_id: orderId, from_status: "pending_payment", to_status: "paid", event_type: "stripe_payment_succeeded" });
        }
      }
    }
    if (event.type === "payment_intent.payment_failed") {
      const intent = event.data.object as Stripe.PaymentIntent;
      if (intent.metadata.order_id) await admin.from("orders").update({ payment_status: "failed" }).eq("id", intent.metadata.order_id);
    }
    return new Response(JSON.stringify({ received: true }), { status: 200, headers: { "Content-Type": "application/json" } });
  } catch (error) {
    console.error("stripe-webhook failed", error instanceof Error ? error.message : "unknown error");
    return new Response("Webhook rejected", { status: 400 });
  }
});

