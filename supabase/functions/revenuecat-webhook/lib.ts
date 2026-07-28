// Pure helpers for revenuecat-webhook — importable from Deno tests without
// starting the edge runtime.

/** Product ids that grant the StillScout Pro entitlement. Must match
 * `rcProMonthlyId` / `rcProYearlyId` in `lib/config/stillscout_config.dart`. */
export const PRO_PRODUCT_IDS = new Set([
  "stillscout_pro_monthly",
  "stillscout_pro_yearly",
]);

/** Minimal shape we read off a RevenueCat webhook `event` object.
 * See https://www.revenuecat.com/docs/integrations/webhooks/event-types-and-fields */
export interface RevenueCatEvent {
  type?: unknown;
  app_user_id?: unknown;
  product_id?: unknown;
  expiration_at_ms?: unknown;
  store?: unknown;
}

export interface EntitlementUpdate {
  appUserId: string;
  isPro: boolean;
  expiresAt: string | null;
  platform: string | null;
}

/** Event types that unconditionally revoke Pro (subscription is fully over). */
const REVOKE_TYPES = new Set(["EXPIRATION", "BILLING_ISSUE"]);

/** Event types that (re-)grant Pro, subject to the product id + expiry checks. */
const GRANT_TYPES = new Set([
  "INITIAL_PURCHASE",
  "RENEWAL",
  "UNCANCELLATION",
  "PRODUCT_CHANGE",
  "SUBSCRIPTION_EXTENDED",
  "TRANSFER",
]);

function platformFor(event: RevenueCatEvent): string | null {
  return typeof event.store === "string" ? event.store : null;
}

/**
 * Decides how a single RevenueCat webhook event should update
 * `pro_entitlements`, or returns `null` when the event carries no
 * app_user_id/type, or is for a non-Pro product and therefore irrelevant.
 *
 * Note on CANCELLATION: RevenueCat fires this when a user turns off
 * auto-renew, but the subscriber keeps access until `expiration_at_ms`.
 * We do NOT treat CANCELLATION as an immediate revoke — we recompute
 * `isPro` from the expiry timestamp instead, so access correctly survives
 * until the paid period actually ends.
 */
export function decideEntitlementUpdate(
  event: RevenueCatEvent,
): EntitlementUpdate | null {
  const appUserId = typeof event.app_user_id === "string"
    ? event.app_user_id.trim()
    : "";
  if (!appUserId) return null;

  const type = typeof event.type === "string" ? event.type.toUpperCase() : "";
  if (!type) return null;

  const productId = typeof event.product_id === "string"
    ? event.product_id
    : "";
  const expMs = typeof event.expiration_at_ms === "number"
    ? event.expiration_at_ms
    : null;
  const expiresAt = expMs !== null ? new Date(expMs).toISOString() : null;
  // No expiry on the event (e.g. missing field) is treated as "not expired"
  // rather than immediately lapsed — we still gate on product id above.
  const notExpired = expMs === null ? true : expMs > Date.now();

  if (REVOKE_TYPES.has(type)) {
    return { appUserId, isPro: false, expiresAt, platform: platformFor(event) };
  }

  if (type === "CANCELLATION") {
    return {
      appUserId,
      isPro: notExpired,
      expiresAt,
      platform: platformFor(event),
    };
  }

  if (GRANT_TYPES.has(type)) {
    if (productId && !PRO_PRODUCT_IDS.has(productId)) {
      // Not a StillScout Pro product — don't touch the entitlement.
      return null;
    }
    return {
      appUserId,
      isPro: notExpired,
      expiresAt,
      platform: platformFor(event),
    };
  }

  // Unknown/irrelevant event type (TEST, INVOICE_ISSUANCE, etc.) — no-op.
  return null;
}

/** Constant-time-ish comparison to avoid trivial timing side-channels on the
 * webhook shared secret check. */
export function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return diff === 0;
}

/** Extracts the bearer token from an `Authorization: Bearer <token>` header. */
export function bearerToken(authHeader: string | null): string | null {
  if (!authHeader) return null;
  const match = /^Bearer\s+(.+)$/i.exec(authHeader.trim());
  return match ? match[1].trim() : null;
}

/** True when [authHeader] carries a bearer token matching [secret]. Always
 * false when [secret] is empty so a missing env var fails closed. */
export function isAuthorizedWebhookRequest(
  authHeader: string | null,
  secret: string,
): boolean {
  if (!secret) return false;
  const token = bearerToken(authHeader);
  if (!token) return false;
  return timingSafeEqual(token, secret);
}
