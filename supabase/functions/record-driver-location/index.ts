import { createClient } from "https://esm.sh/@supabase/supabase-js@2.97.0";
import { haversineMetres, json, options, requireEnv } from "../_shared/http.ts";

type LocationInput = {
  orderId: string;
  latitude: number;
  longitude: number;
  accuracyMetres?: number;
  headingDegrees?: number;
  capturedAt: string;
};

const activeStatuses = new Set(["driver_en_route_to_pickup", "collected", "driver_en_route", "nearby"]);

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
    const { data: { user }, error: userError } = await userClient.auth.getUser();
    if (userError || !user) return json({ error: "Invalid session" }, 401);

    const input = await request.json() as LocationInput;
    if (!input.orderId || !Number.isFinite(input.latitude) || !Number.isFinite(input.longitude)) {
      return json({ error: "Invalid location payload" }, 400);
    }
    if (input.latitude < -90 || input.latitude > 90 || input.longitude < -180 || input.longitude > 180) {
      return json({ error: "Location is outside coordinate bounds" }, 400);
    }
    const capturedAt = new Date(input.capturedAt);
    const now = Date.now();
    if (Number.isNaN(capturedAt.getTime()) || capturedAt.getTime() < now - 5 * 60_000 || capturedAt.getTime() > now + 30_000) {
      return json({ error: "Location timestamp is not acceptable" }, 400);
    }

    const admin = createClient(url, serviceRoleKey, { auth: { persistSession: false } });
    const { data: assignment, error: assignmentError } = await admin
      .from("driver_assignments")
      .select("id, status, released_at")
      .eq("order_id", input.orderId)
      .eq("driver_id", user.id)
      .is("released_at", null)
      .in("status", ["offered", "accepted"])
      .maybeSingle();
    if (assignmentError || !assignment) return json({ error: "You are not assigned to this delivery" }, 403);

    const { data: order, error: orderError } = await admin
      .from("orders")
      .select("status, is_demo")
      .eq("id", input.orderId)
      .single();
    if (orderError || !order || !activeStatuses.has(order.status)) {
      return json({ error: "Tracking is not active for this order" }, 409);
    }

    const { data: previous } = await admin
      .from("driver_live_locations")
      .select("latitude, longitude, captured_at")
      .eq("order_id", input.orderId)
      .maybeSingle();
    if (previous) {
      const elapsedSeconds = Math.max(1, (capturedAt.getTime() - new Date(previous.captured_at).getTime()) / 1000);
      const metres = haversineMetres(Number(previous.latitude), Number(previous.longitude), input.latitude, input.longitude);
      // Reject a clearly broken phone reading, not normal travel. 70 m/s is about 157 mph.
      if (metres / elapsedSeconds > 70) return json({ error: "Location jump rejected" }, 422);
    }

    const { error: upsertError } = await admin.from("driver_live_locations").upsert({
      order_id: input.orderId,
      driver_id: user.id,
      latitude: input.latitude,
      longitude: input.longitude,
      accuracy_metres: input.accuracyMetres ?? null,
      heading_degrees: input.headingDegrees ?? null,
      captured_at: capturedAt.toISOString(),
      received_at: new Date().toISOString(),
      tracking_active: true,
    }, { onConflict: "order_id" });
    if (upsertError) throw upsertError;

    return json({ ok: true, receivedAt: new Date().toISOString(), demo: order.is_demo });
  } catch (error) {
    console.error("record-driver-location failed", error instanceof Error ? error.message : "unknown error");
    return json({ error: "Unable to record driver location" }, 500);
  }
});

