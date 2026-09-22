import { createClient } from "https://esm.sh/@supabase/supabase-js@2.97.0";
import { json, options, requireEnv } from "../_shared/http.ts";

type Input = { orderId: string; status: string; customerMessage?: string; privateNote?: string; proof?: { kind: "photo" | "otp" | "handed_to_customer" | "safe_place"; storagePath?: string; note?: string } };

const kitchenStatuses = new Set(["confirmed", "preparing", "ready_for_pickup", "cancelled"]);
const driverStatuses = new Set(["driver_en_route_to_pickup", "collected", "driver_en_route", "nearby", "delivered"]);

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
    if (!input.orderId || !input.status) return json({ error: "Order and status are required" }, 400);

    const admin = createClient(url, serviceRoleKey, { auth: { persistSession: false } });
    const { data: actorRoles } = await admin.from("user_roles").select("role").eq("user_id", user.id);
    const roles = new Set(actorRoles?.map(({ role }) => role) ?? []);
    const isOwner = roles.has("owner");
    const isKitchen = roles.has("kitchen");
    const isDriver = roles.has("driver");
    const { data: order } = await admin.from("orders").select("status").eq("id", input.orderId).single();
    if (!order) return json({ error: "Order not found" }, 404);

    if (!isOwner && isKitchen && !kitchenStatuses.has(input.status)) return json({ error: "Kitchen cannot make that status change" }, 403);
    if (!isOwner && isDriver) {
      if (!driverStatuses.has(input.status)) return json({ error: "Driver cannot make that status change" }, 403);
      const { data: assignment } = await admin.from("driver_assignments")
        .select("id").eq("order_id", input.orderId).eq("driver_id", user.id).is("released_at", null).maybeSingle();
      if (!assignment) return json({ error: "This job is not assigned to you" }, 403);
      if (input.status === "delivered" && !input.proof) return json({ error: "Proof of delivery is required" }, 422);
      if (input.status === "driver_en_route_to_pickup") {
        await admin.from("driver_assignments").update({ status: "accepted", accepted_at: new Date().toISOString() })
          .eq("order_id", input.orderId).eq("driver_id", user.id).is("released_at", null);
        await admin.from("driver_availability").upsert({ driver_id: user.id, status: "busy", updated_at: new Date().toISOString() });
      }
    }
    if (!isOwner && !isKitchen && !isDriver) return json({ error: "Operational role required" }, 403);

    const patch: Record<string, unknown> = { status: input.status };
    if (input.status === "delivered") patch.delivered_at = new Date().toISOString();
    if (input.status === "cancelled") patch.cancelled_at = new Date().toISOString();
    const { error: updateError } = await admin.from("orders").update(patch).eq("id", input.orderId);
    if (updateError) throw updateError;
    await admin.from("order_status_events").insert({
      order_id: input.orderId,
      actor_id: user.id,
      actor_role: isOwner ? "owner" : isKitchen ? "kitchen" : "driver",
      from_status: order.status,
      to_status: input.status,
      event_type: `status_${input.status}`,
      customer_message: input.customerMessage ?? null,
      private_note: input.privateNote ?? null,
    });
    if (input.proof) {
      await admin.from("proof_of_delivery").upsert({
        order_id: input.orderId, recorded_by: user.id, proof_kind: input.proof.kind,
        storage_path: input.proof.storagePath ?? null, note: input.proof.note ?? null,
      }, { onConflict: "order_id" });
    }
    if (input.status === "delivered" || input.status === "cancelled") {
      await admin.from("driver_live_locations").delete().eq("order_id", input.orderId);
      await admin.from("driver_assignments").update({ status: input.status === "delivered" ? "completed" : "cancelled", released_at: new Date().toISOString() })
        .eq("order_id", input.orderId).is("released_at", null);
      if (isDriver) await admin.from("driver_availability").upsert({ driver_id: user.id, status: "available", updated_at: new Date().toISOString() });
    }
    return json({ ok: true });
  } catch (error) {
    console.error("update-order-status failed", error instanceof Error ? error.message : "unknown error");
    return json({ error: "Unable to update this order" }, 500);
  }
});

