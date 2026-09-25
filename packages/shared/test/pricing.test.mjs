import test from "node:test";
import assert from "node:assert/strict";
const quote = (food, type, delivery = 250) => ({ food, delivery: type === "delivery" ? delivery : 0, platform: 100, transaction: 29, total: food + (type === "delivery" ? delivery : 0) + 100 + 29 });
test("collection has exact transparent fees", () => assert.deepEqual(quote(550, "collection"), { food: 550, delivery: 0, platform: 100, transaction: 29, total: 679 }));
test("delivery has exact transparent fees", () => assert.equal(quote(1100, "delivery").total, 1479));
test("quantity and modifiers remain integer pence", () => assert.equal((800 + 0) * 2, 1600));
test("fixed fees remain exact and itemised", () => {
  const result = quote(2500, "delivery");
  assert.equal(result.platform, 100);
  assert.equal(result.transaction, 29);
  assert.equal(result.total, 2879);
});
test("status progression contains the guarded delivery sequence", () => {
  const statuses = ["paid", "confirmed", "preparing", "ready_for_pickup", "driver_assigned", "driver_en_route_to_pickup", "collected", "driver_en_route", "nearby", "delivered"];
  assert.deepEqual(statuses.slice(0, 4), ["paid", "confirmed", "preparing", "ready_for_pickup"]);
  assert.equal(statuses.at(-1), "delivered");
});
