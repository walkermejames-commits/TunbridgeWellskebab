import { createClient } from "https://esm.sh/@supabase/supabase-js@2.97.0";
import { json, options, requireEnv } from "../_shared/http.ts";

type BasketItem = {
  menuItemId: string;
  variantId?: string;
  quantity: number;
  modifierOptionIds?: string[];
  customerNote?: string;
};
type Input = {
  restaurantId: string;
  orderType: "collection" | "delivery";
  deliveryZoneId?: string;
  deliveryAddress?: Record<string, string>;
  customerName: string;
  customerPhone: string;
  deliveryNote?: string;
  idempotencyKey: string;
  items: BasketItem[];
};

function reference() {
  return `TWK-${crypto.randomUUID().replaceAll("-", "").slice(0, 8).toUpperCase()}`;
}

async function createStripePaymentIntent(amount: number, orderId: string) {
  const secret = requireEnv("STRIPE_SECRET_KEY");
  const body = new URLSearchParams({ amount: String(amount), currency: "gbp", "automatic_payment_methods[enabled]": "true", "metadata[order_id]": orderId });
  const response = await fetch("https://api.stripe.com/v1/payment_intents", {
    method: "POST", headers: { Authorization: `Bearer ${secret}`, "Content-Type": "application/x-www-form-urlencoded" }, body,
  });
  const payload = await response.json();
  if (!response.ok || !payload.id || !payload.client_secret) throw new Error("Stripe could not create a payment intent");
  return { id: payload.id as string, clientSecret: payload.client_secret as string };
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return options();
  if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);

  try {
    const authorization = request.headers.get("Authorization");
    if (!authorization) return json({ error: "Sign in required" }, 401);
    const url = requireEnv("SUPABASE_URL");
    const publishableKey = requireEnv("SUPABASE_PUBLISHABLE_KEY");
    const serviceRoleKey = requireEnv("SUPABASE_SERVICE_ROLE_KEY");
    const userClient = createClient(url, publishableKey, { global: { headers: { Authorization: authorization } } });
    const { data: { user } } = await userClient.auth.getUser();
    if (!user) return json({ error: "Invalid session" }, 401);
    const input = await request.json() as Input;
    if (!input.restaurantId || !input.idempotencyKey || !Array.isArray(input.items) || input.items.length === 0) {
      return json({ error: "A restaurant, idempotency key and basket are required" }, 400);
    }
    if (input.orderType === "delivery" && (!input.deliveryZoneId || !input.deliveryAddress)) return json({ error: "Delivery address and zone are required" }, 400);

    const admin = createClient(url, serviceRoleKey, { auth: { persistSession: false } });
    const { data: previous } = await admin.from("orders").select("id, public_reference, payment_status, is_demo")
      .eq("customer_id", user.id).eq("idempotency_key", input.idempotencyKey).maybeSingle();
    if (previous) return json({ ok: true, reused: true, orderId: previous.id, reference: previous.public_reference, paymentStatus: previous.payment_status, demo: previous.is_demo });

    const { data: runtime } = await admin.from("runtime_configuration").select("mode").eq("singleton", true).single();
    const isDemo = runtime?.mode !== "live";
    const menuItemIds = input.items.map((item) => item.menuItemId);
    const { data: menuItems, error: menuError } = await admin.from("menu_items")
      .select("id, name, base_price_pence, is_available, menu_item_variants(id, name, price_pence, is_available)")
      .in("id", menuItemIds).eq("restaurant_id", input.restaurantId);
    if (menuError || !menuItems || menuItems.length !== new Set(menuItemIds).size) return json({ error: "One or more menu items are unavailable" }, 409);

    const selectedOptionIds = input.items.flatMap((item) => item.modifierOptionIds ?? []);
    const { data: options } = selectedOptionIds.length
      ? await admin.from("modifier_options").select("id, name, price_delta_pence, is_available").in("id", selectedOptionIds)
      : { data: [] as Array<{ id: string; name: string; price_delta_pence: number; is_available: boolean }> };
    if ((options?.length ?? 0) !== new Set(selectedOptionIds).size || options?.some((option) => !option.is_available)) return json({ error: "A selected option is unavailable" }, 409);
    if (selectedOptionIds.length) {
      const { data: mappings } = await admin.from("menu_item_modifier_groups")
        .select("menu_item_id, modifier_group_id").in("menu_item_id", menuItemIds);
      const { data: optionGroups } = await admin.from("modifier_options")
        .select("id, modifier_group_id").in("id", selectedOptionIds);
      const groupForOption = new Map((optionGroups ?? []).map((option) => [option.id, option.modifier_group_id]));
      const permitted = new Set((mappings ?? []).map((mapping) => `${mapping.menu_item_id}:${mapping.modifier_group_id}`));
      if (input.items.some((item) => (item.modifierOptionIds ?? []).some((id) => !permitted.has(`${item.menuItemId}:${groupForOption.get(id)}`)))) return json({ error: "A selected option is not available for this menu item" }, 409);
    }

    const { data: feePolicy } = await admin.from("fee_policies").select("id, platform_fee_pence, transaction_fee_pence")
      .eq("restaurant_id", input.restaurantId).not("published_at", "is", null).is("retired_at", null).order("effective_from", { ascending: false }).limit(1).maybeSingle();
    if (!feePolicy) return json({ error: "No published fee policy" }, 503);
    let deliveryFee = 0;
    if (input.orderType === "delivery") {
      const { data: zone } = await admin.from("delivery_zones").select("delivery_fee_pence, is_available").eq("id", input.deliveryZoneId!).eq("restaurant_id", input.restaurantId).maybeSingle();
      if (!zone?.is_available) return json({ error: "Delivery is not available for this zone" }, 409);
      deliveryFee = zone.delivery_fee_pence;
    }

    const menuMap = new Map(menuItems.map((item) => [item.id, item]));
    const optionMap = new Map((options ?? []).map((option) => [option.id, option]));
    const lines = input.items.map((item) => {
      if (!Number.isInteger(item.quantity) || item.quantity < 1 || item.quantity > 99) throw new Error("Invalid quantity");
      const menu = menuMap.get(item.menuItemId)!;
      if (!menu.is_available) throw new Error("A menu item is unavailable");
      const variant = item.variantId ? menu.menu_item_variants.find((entry: { id: string }) => entry.id === item.variantId) : undefined;
      if (item.variantId && (!variant || !variant.is_available)) throw new Error("A selected size is unavailable");
      const selectedOptions = (item.modifierOptionIds ?? []).map((id) => optionMap.get(id)!);
      const unitPrice = (variant?.price_pence ?? menu.base_price_pence) + selectedOptions.reduce((sum, option) => sum + option.price_delta_pence, 0);
      return { menu, variant, selectedOptions, quantity: item.quantity, unitPrice, lineTotal: unitPrice * item.quantity, customerNote: item.customerNote ?? null };
    });
    const foodSubtotal = lines.reduce((sum, line) => sum + line.lineTotal, 0);
    const total = foodSubtotal + deliveryFee + feePolicy.platform_fee_pence + feePolicy.transaction_fee_pence;

    const { data: order, error: insertError } = await admin.from("orders").insert({
      public_reference: reference(), idempotency_key: input.idempotencyKey, restaurant_id: input.restaurantId, customer_id: user.id,
      order_type: input.orderType, status: isDemo ? "paid" : "pending_payment", payment_status: isDemo ? "paid" : "pending",
      fee_policy_id: feePolicy.id, delivery_zone_id: input.deliveryZoneId ?? null,
      customer_name_snapshot: input.customerName, customer_phone_snapshot: input.customerPhone,
      delivery_address_snapshot: input.orderType === "delivery" ? input.deliveryAddress : null,
      delivery_note: input.deliveryNote ?? null, food_subtotal_pence: foodSubtotal, delivery_fee_pence: deliveryFee,
      platform_fee_pence: feePolicy.platform_fee_pence, transaction_fee_pence: feePolicy.transaction_fee_pence,
      total_pence: total, is_demo: isDemo,
    }).select("id, public_reference").single();
    if (insertError || !order) {
      // A concurrent retry can hit the unique key after the preflight lookup.
      const { data: retry } = await admin.from("orders").select("id, public_reference, payment_status, is_demo")
        .eq("customer_id", user.id).eq("idempotency_key", input.idempotencyKey).maybeSingle();
      if (retry) return json({ ok: true, reused: true, orderId: retry.id, reference: retry.public_reference, paymentStatus: retry.payment_status, demo: retry.is_demo });
      throw insertError ?? new Error("Order could not be created");
    }
    await admin.from("order_items").insert(lines.map((line) => ({ order_id: order.id, menu_item_id: line.menu.id, menu_item_name_snapshot: line.menu.name, variant_name_snapshot: line.variant?.name ?? null, unit_price_pence: line.unitPrice, quantity: line.quantity, customer_note: line.customerNote, line_total_pence: line.lineTotal })));
    await admin.from("order_status_events").insert({ order_id: order.id, actor_id: user.id, actor_role: "customer", from_status: null, to_status: isDemo ? "paid" : "pending_payment", event_type: isDemo ? "demo_order_paid" : "order_created" });

    if (isDemo) return json({ ok: true, orderId: order.id, reference: order.public_reference, paymentStatus: "paid", demo: true });
    const paymentIntent = await createStripePaymentIntent(total, order.id);
    await admin.from("orders").update({ stripe_payment_intent_id: paymentIntent.id }).eq("id", order.id);
    return json({ ok: true, orderId: order.id, reference: order.public_reference, paymentStatus: "pending", clientSecret: paymentIntent.clientSecret, demo: false });
  } catch (error) {
    console.error("create-order failed", error instanceof Error ? error.message : "unknown error");
    return json({ error: "Unable to create this order" }, 500);
  }
});

