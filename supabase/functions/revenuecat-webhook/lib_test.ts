import { assertEquals } from "jsr:@std/assert";
import {
  bearerToken,
  decideEntitlementUpdate,
  isAuthorizedWebhookRequest,
  timingSafeEqual,
} from "./lib.ts";

const FUTURE_MS = Date.now() + 30 * 24 * 60 * 60 * 1000;
const PAST_MS = Date.now() - 24 * 60 * 60 * 1000;

Deno.test("decideEntitlementUpdate grants Pro on INITIAL_PURCHASE for a Pro product", () => {
  const update = decideEntitlementUpdate({
    type: "INITIAL_PURCHASE",
    app_user_id: "user-1",
    product_id: "stillscout_pro_monthly",
    expiration_at_ms: FUTURE_MS,
    store: "APP_STORE",
  });
  assertEquals(update?.isPro, true);
  assertEquals(update?.appUserId, "user-1");
  assertEquals(update?.platform, "APP_STORE");
});

Deno.test("decideEntitlementUpdate grants Pro on RENEWAL", () => {
  const update = decideEntitlementUpdate({
    type: "RENEWAL",
    app_user_id: "user-2",
    product_id: "stillscout_pro_yearly",
    expiration_at_ms: FUTURE_MS,
  });
  assertEquals(update?.isPro, true);
});

Deno.test("decideEntitlementUpdate ignores grant events for non-Pro products", () => {
  const update = decideEntitlementUpdate({
    type: "INITIAL_PURCHASE",
    app_user_id: "user-3",
    product_id: "some_other_consumable",
    expiration_at_ms: FUTURE_MS,
  });
  assertEquals(update, null);
});

Deno.test("decideEntitlementUpdate revokes Pro on EXPIRATION", () => {
  const update = decideEntitlementUpdate({
    type: "EXPIRATION",
    app_user_id: "user-4",
    product_id: "stillscout_pro_monthly",
    expiration_at_ms: PAST_MS,
  });
  assertEquals(update?.isPro, false);
});

Deno.test("decideEntitlementUpdate revokes Pro on BILLING_ISSUE", () => {
  const update = decideEntitlementUpdate({
    type: "BILLING_ISSUE",
    app_user_id: "user-5",
  });
  assertEquals(update?.isPro, false);
});

Deno.test("decideEntitlementUpdate CANCELLATION keeps access until expiry", () => {
  const stillActive = decideEntitlementUpdate({
    type: "CANCELLATION",
    app_user_id: "user-6",
    expiration_at_ms: FUTURE_MS,
  });
  assertEquals(stillActive?.isPro, true);

  const alreadyLapsed = decideEntitlementUpdate({
    type: "CANCELLATION",
    app_user_id: "user-6",
    expiration_at_ms: PAST_MS,
  });
  assertEquals(alreadyLapsed?.isPro, false);
});

Deno.test("decideEntitlementUpdate is case-insensitive on event type", () => {
  const update = decideEntitlementUpdate({
    type: "renewal",
    app_user_id: "user-7",
    product_id: "stillscout_pro_monthly",
    expiration_at_ms: FUTURE_MS,
  });
  assertEquals(update?.isPro, true);
});

Deno.test("decideEntitlementUpdate returns null for missing app_user_id or type", () => {
  assertEquals(decideEntitlementUpdate({ type: "RENEWAL" }), null);
  assertEquals(decideEntitlementUpdate({ app_user_id: "user-8" }), null);
});

Deno.test("decideEntitlementUpdate ignores unknown event types", () => {
  assertEquals(
    decideEntitlementUpdate({ type: "TEST", app_user_id: "user-9" }),
    null,
  );
});

Deno.test("bearerToken extracts token from Authorization header", () => {
  assertEquals(bearerToken("Bearer abc123"), "abc123");
  assertEquals(bearerToken("bearer   abc123  "), "abc123");
  assertEquals(bearerToken(null), null);
  assertEquals(bearerToken("Basic abc123"), null);
});

Deno.test("timingSafeEqual compares strings correctly", () => {
  assertEquals(timingSafeEqual("secret", "secret"), true);
  assertEquals(timingSafeEqual("secret", "different"), false);
  assertEquals(timingSafeEqual("secret", "secre"), false);
});

Deno.test("isAuthorizedWebhookRequest fails closed when secret env var is empty", () => {
  assertEquals(isAuthorizedWebhookRequest("Bearer anything", ""), false);
});

Deno.test("isAuthorizedWebhookRequest accepts a matching bearer token", () => {
  assertEquals(
    isAuthorizedWebhookRequest("Bearer topsecret", "topsecret"),
    true,
  );
});

Deno.test("isAuthorizedWebhookRequest rejects a mismatched bearer token", () => {
  assertEquals(
    isAuthorizedWebhookRequest("Bearer wrong", "topsecret"),
    false,
  );
});
