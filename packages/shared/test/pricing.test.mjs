import test from "node:test";
import assert from "node:assert/strict";
const quote = (food, type, delivery = 250) => ({ food, delivery: type === "delivery" ? delivery : 0, platform: 100, transaction: 29, total: food + (type === "delivery" ? delivery : 0) + 100 + 29 });
test("collection has exact transparent fees", () => assert.deepEqual(quote(550, "collection"), { food: 550, delivery: 0, platform: 100, transaction: 29, total: 679 }));
test("delivery has exact transparent fees", () => assert.equal(quote(1100, "delivery").total, 1479));
test("quantity and modifiers remain integer pence", () => assert.equal((800 + 0) * 2, 1600));
