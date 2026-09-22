import { createClient } from "https://esm.sh/@supabase/supabase-js@2.97.0";
import { json, options, requireEnv } from "../_shared/http.ts";

type AssignmentInput = { orderId: string; driverId: string; reason?: string };

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
    const input = await request.json() as AssignmentInput;
    if (!input.orderId || !input.driverId) return json({ error: "Order and driver are required" }, 400);

    const admin = createClient(url, serviceRoleKey, { auth: { persistSession: false } });
    const { data: actorRoles } = await admin.from("user_roles").select("role").eq("user_id", user.id);
    if (!actorRoles?.some(({ role }) => role === "owner" || role === "kitchen")) return json({ error: "Dispatch permission required" }, 403);

    const { data: order } = await admin.from("orders").select("status").eq("id", input.orderId).single();
    if (!order || order.status !== "ready_for_pickup") return json({ error: "Only ready orders can be assigned" }, 409);
    const { data: driverRoles } = await admin.from("user_roles").select("role").eq("user_id", input.driverId);
    const { data: availability } = await admin.from("driver_availability").select("status").eq("driver_id", input.driverId).maybeSingle();
    if (!driverRoles?.some(({ role }) => role === "driver") || availability?.status !== "available") {
      return json({ error: "Driver is not available" }, 409);
    }

    await admin.from("driver_assignments").update({ released_at: new Date().toISOString(), status: "reassigned", release_reason: input.reason ?? "Reassigned" })
      .eq("order_id", input.orderId).is("released_at", null);
    const { error: assignmentError } = await admin.from("driver_assignments").insert({
      order_id: input.orderId, driver_id: input.driverId, assigned_by: user.id, status: "offered",
    });
    if (assignmentError) throw assignmentError;
    const { error: orderError } = await admin.from("orders").update({ status: "driver_assigned" }).eq("id", input.orderId);
    if (orderError) throw orderError;
    await admin.from("order_status_events").insert({
      order_id: input.orderId, actor_id: user.id, actor_role: actorRoles[0].role,
      from_status: "ready_for_pickup", to_status: "driver_assigned", event_type: "driver_assigned", private_note: input.reason ?? null,
    });
    return json({ ok: true });
  } catch (error) {
    console.error("assign-driver failed", error instanceof Error ? error.message : "unknown error");
    return json({ error: "Unable to assign driver" }, 500);
  }
});

