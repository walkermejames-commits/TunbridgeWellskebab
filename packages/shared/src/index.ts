import { z } from "zod";

export const PLATFORM_FEE_PENCE = 100;
export const TRANSACTION_FEE_PENCE = 29;
export const formatMoney = (pence: number) => new Intl.NumberFormat("en-GB", { style: "currency", currency: "GBP" }).format(pence / 100);
export const quote = (foodSubtotalPence: number, orderType: "delivery" | "collection", deliveryFeePence = 250) => {
  const delivery = orderType === "delivery" ? deliveryFeePence : 0;
  return { foodSubtotalPence, deliveryFeePence: delivery, platformFeePence: PLATFORM_FEE_PENCE, transactionFeePence: TRANSACTION_FEE_PENCE, totalPence: foodSubtotalPence + delivery + PLATFORM_FEE_PENCE + TRANSACTION_FEE_PENCE };
};
export const orderStatuses = ["pending_payment", "paid", "confirmed", "preparing", "ready_for_pickup", "driver_assigned", "driver_en_route_to_pickup", "collected", "driver_en_route", "nearby", "delivered", "cancelled"] as const;
export type OrderStatus = typeof orderStatuses[number];
export const statusLabel: Record<OrderStatus, string> = { pending_payment: "Awaiting payment", paid: "Paid", confirmed: "Confirmed", preparing: "Preparing", ready_for_pickup: "Ready for pickup", driver_assigned: "Driver assigned", driver_en_route_to_pickup: "Driver travelling to pickup", collected: "Collected", driver_en_route: "On the way", nearby: "Driver nearby", delivered: "Delivered", cancelled: "Cancelled" };
export const createOrderSchema = z.object({ restaurantId: z.string().uuid(), idempotencyKey: z.string().min(16).max(200), orderType: z.enum(["delivery", "collection"]), customerName: z.string().min(1).max(100), customerPhone: z.string().min(6).max(30), deliveryAddress: z.unknown().optional(), items: z.array(z.object({ menuItemId: z.string().uuid(), variantId: z.string().uuid().optional(), modifierOptionIds: z.array(z.string().uuid()).optional(), quantity: z.number().int().min(1).max(99), customerNote: z.string().max(300).optional() })).min(1) });
export const locationSchema = z.object({ orderId: z.string().uuid(), latitude: z.number().gte(-90).lte(90), longitude: z.number().gte(-180).lte(180), capturedAt: z.string().datetime() });
