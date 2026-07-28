// =============================================================================
// revenuecat-webhook — StillScout Supabase Edge Function
// =============================================================================
// Receives RevenueCat subscriber webhook events and upserts a server-side
// entitlement cache (`pro_entitlements`) that `vision-score` trusts instead
// of any client-supplied "isPro" claim.
//
// Configure in RevenueCat: Project Settings → Integrations → Webhooks
//   URL:                  https://<project-ref>.functions.supabase.co/revenuecat-webhook
//   Authorization header: Bearer <REVENUECAT_WEBHOOK_SECRET>
//
// Deploy: supabase functions deploy revenuecat-webhook
// Secrets: supabase secrets set REVENUECAT_WEBHOOK_SECRET=...
// =============================================================================

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import {
  decideEntitlementUpdate,
  isAuthorizedWebhookRequest,
  type RevenueCatEvent,
} from "./lib.ts";

const REVENUECAT_WEBHOOK_SECRET = Deno.env.get("REVENUECAT_WEBHOOK_SECRET") ??
  "";

function serviceClient() {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }

  // Fail closed: reject every request until the secret is configured, so a
  // missing env var can never be mistaken for "webhook disabled = allow all".
  if (
    !isAuthorizedWebhookRequest(
      req.headers.get("authorization"),
      REVENUECAT_WEBHOOK_SECRET,
    )
  ) {
    console.warn("[revenuecat-webhook] rejected — bad or missing auth");
    return jsonResponse({ error: "unauthorized" }, 401);
  }

  let payload: Record<string, unknown>;
  try {
    payload = await req.json();
  } catch {
    return jsonResponse({ error: "invalid_json" }, 400);
  }

  const event = (payload.event ?? {}) as RevenueCatEvent;
  const update = decideEntitlementUpdate(event);

  if (!update) {
    // Not actionable (irrelevant event type / non-Pro product / malformed
    // event) — acknowledge quickly so RevenueCat does not retry.
    return jsonResponse({ ok: true, ignored: true });
  }

  const { error } = await serviceClient().rpc("upsert_pro_entitlement", {
    p_app_user_id: update.appUserId,
    p_is_pro: update.isPro,
    p_expires_at: update.expiresAt,
    p_platform: update.platform,
  });

  if (error) {
    // Non-2xx so RevenueCat retries with backoff instead of silently
    // dropping an entitlement change.
    console.error("[revenuecat-webhook] upsert failed:", error.message);
    return jsonResponse({ error: "upsert_failed" }, 500);
  }

  return jsonResponse({ ok: true });
});
