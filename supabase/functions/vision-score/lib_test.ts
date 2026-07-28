import { assertEquals } from "jsr:@std/assert";
import {
  _resetIpWindowsForTests,
  clientIp,
  DEFAULT_GLOBAL_DAILY_PICK_CEILING,
  FREE_DAILY_CAP,
  isIpRateLimited,
  isUuidish,
  isVerifiedProEntitlement,
  MAX_BATCH_IMAGES,
  MAX_IMAGE_BASE64_CHARS,
  noteIpRequest,
  planQuotaFirstFlow,
  planQuotaFirstSingleFlow,
  PRO_DAILY_CAP,
  reserveDenialResponse,
  resolveAppUserId,
  resolveDailyCap,
  resolveDeviceKey,
  resolveGlobalDailyCeiling,
  resolvePickCount,
  UNREACHABLE_ENTITLEMENT_LOOKUP,
  validateBatchImages,
} from "./lib.ts";

Deno.test("isUuidish accepts standard UUID v4", () => {
  assertEquals(isUuidish("550e8400-e29b-41d4-a716-446655440000"), true);
  assertEquals(isUuidish("not-a-uuid"), false);
});

Deno.test("resolveDeviceKey prefers UUID device_id", () => {
  const headers = new Headers({ "cf-connecting-ip": "203.0.113.1" });
  assertEquals(
    resolveDeviceKey("550e8400-e29b-41d4-a716-446655440000", headers),
    "550e8400-e29b-41d4-a716-446655440000",
  );
});

Deno.test("resolveDeviceKey falls back to IP for invalid device_id", () => {
  const headers = new Headers({ "cf-connecting-ip": "203.0.113.9" });
  assertEquals(resolveDeviceKey("short", headers), "203.0.113.9");
});

Deno.test("clientIp reads cf-connecting-ip first", () => {
  const headers = new Headers({
    "cf-connecting-ip": "198.51.100.2",
    "x-forwarded-for": "10.0.0.1",
  });
  assertEquals(clientIp(headers), "198.51.100.2");
});

Deno.test("MAX_BATCH_IMAGES is 48", () => {
  assertEquals(MAX_BATCH_IMAGES, 48);
});

Deno.test("noteIpRequest is safe to call repeatedly", () => {
  noteIpRequest("127.0.0.1");
});

Deno.test("isIpRateLimited is false for an unseen IP", () => {
  _resetIpWindowsForTests();
  assertEquals(isIpRateLimited("203.0.113.50"), false);
});

Deno.test("isIpRateLimited soft-blocks after the per-minute ceiling", () => {
  _resetIpWindowsForTests();
  const ip = "203.0.113.51";
  for (let i = 0; i < 89; i++) noteIpRequest(ip);
  assertEquals(isIpRateLimited(ip), false);
  noteIpRequest(ip); // 90th request in the window
  assertEquals(isIpRateLimited(ip), true);
});

Deno.test("isIpRateLimited does not affect other IPs", () => {
  _resetIpWindowsForTests();
  const hot = "203.0.113.52";
  for (let i = 0; i < 90; i++) noteIpRequest(hot);
  assertEquals(isIpRateLimited(hot), true);
  assertEquals(isIpRateLimited("203.0.113.53"), false);
});

Deno.test("validateBatchImages rejects empty and oversized payloads", () => {
  assertEquals(validateBatchImages([]), { ok: false, error: "missing_images" });
  assertEquals(
    validateBatchImages(["a".repeat(MAX_IMAGE_BASE64_CHARS + 1)]),
    { ok: false, error: "image_too_large" },
  );
});

Deno.test("resolvePickCount clamps to image count", () => {
  assertEquals(resolvePickCount(99, 3), 3);
  assertEquals(resolvePickCount(0, 5), 1);
});

Deno.test("quota-first: exhausted reserve never calls Gemini", () => {
  const plan = planQuotaFirstFlow({ reserveOk: false });
  assertEquals(plan.calledGemini, false);
  assertEquals(plan.httpStatus, 429);
});

Deno.test("quota-first: success keeps reservation", () => {
  const plan = planQuotaFirstFlow({ reserveOk: true, scoring: "success" });
  assertEquals(plan.releaseReservation, false);
});

Deno.test("quota-first: Gemini failure releases reservation", () => {
  assertEquals(
    planQuotaFirstFlow({ reserveOk: true, scoring: "failed" })
      .releaseReservation,
    true,
  );
  assertEquals(
    planQuotaFirstFlow({ reserveOk: true, scoring: "incomplete" })
      .httpStatus,
    422,
  );
});

Deno.test("quota-first single contract", () => {
  assertEquals(
    planQuotaFirstSingleFlow({ reserveOk: true, scoreOk: false })
      .releaseReservation,
    true,
  );
});

Deno.test("batch path reserves (per-device + global) before Gemini", async () => {
  const src = await Deno.readTextFile(new URL("./index.ts", import.meta.url));
  const batch = src.slice(
    src.indexOf("// ── Batch path"),
    src.indexOf("// ── Single-frame path"),
  );
  assertEquals(
    batch.indexOf("reserveTieredQuota") < batch.indexOf("tryGeminiBatch"),
    true,
  );
  assertEquals(batch.includes("releaseQuota"), true);
  assertEquals(batch.includes("releaseGlobalQuota"), true);
});

Deno.test("single path reserves (per-device + global) before Gemini", async () => {
  const src = await Deno.readTextFile(new URL("./index.ts", import.meta.url));
  const single = src.slice(src.indexOf("// ── Single-frame path"));
  assertEquals(
    single.indexOf("reserveTieredQuota") < single.indexOf("tryGeminiSingle"),
    true,
  );
  assertEquals(single.includes("releaseGlobalQuota"), true);
});

// ── Pro entitlement verification ────────────────────────────────────────

Deno.test("isVerifiedProEntitlement is true for an active, non-expired Pro row", () => {
  const future = new Date(Date.now() + 60_000).toISOString();
  assertEquals(
    isVerifiedProEntitlement({ ok: true, isPro: true, expiresAt: future }),
    true,
  );
});

Deno.test("isVerifiedProEntitlement is true when Pro row has no recorded expiry", () => {
  assertEquals(
    isVerifiedProEntitlement({ ok: true, isPro: true, expiresAt: null }),
    true,
  );
});

Deno.test("isVerifiedProEntitlement is false once the recorded expiry has passed", () => {
  const past = new Date(Date.now() - 60_000).toISOString();
  assertEquals(
    isVerifiedProEntitlement({ ok: true, isPro: true, expiresAt: past }),
    false,
  );
});

Deno.test("isVerifiedProEntitlement is false for a non-Pro row", () => {
  assertEquals(
    isVerifiedProEntitlement({ ok: true, isPro: false, expiresAt: null }),
    false,
  );
});

Deno.test("isVerifiedProEntitlement is false for an unparsable expiry", () => {
  assertEquals(
    isVerifiedProEntitlement({ ok: true, isPro: true, expiresAt: "not-a-date" }),
    false,
  );
});

Deno.test("isVerifiedProEntitlement fails safe (false) when the lookup itself failed", () => {
  const future = new Date(Date.now() + 60_000).toISOString();
  assertEquals(
    isVerifiedProEntitlement({ ok: false, isPro: true, expiresAt: future }),
    false,
  );
  assertEquals(isVerifiedProEntitlement(UNREACHABLE_ENTITLEMENT_LOOKUP), false);
});

Deno.test("resolveDailyCap grants the high Pro ceiling only when verified", () => {
  assertEquals(resolveDailyCap({ verifiedPro: true }), PRO_DAILY_CAP);
  assertEquals(resolveDailyCap({ verifiedPro: false }), FREE_DAILY_CAP);
  assertEquals(PRO_DAILY_CAP > FREE_DAILY_CAP, true);
});

Deno.test("a DB lookup error never silently grants the Pro cap (fail-safe end-to-end)", () => {
  const cap = resolveDailyCap({
    verifiedPro: isVerifiedProEntitlement(UNREACHABLE_ENTITLEMENT_LOOKUP),
  });
  assertEquals(cap, FREE_DAILY_CAP);
});

Deno.test("resolveAppUserId accepts a trimmed non-empty string and rejects the rest", () => {
  assertEquals(resolveAppUserId("  user-123  "), "user-123");
  assertEquals(resolveAppUserId(""), null);
  assertEquals(resolveAppUserId("   "), null);
  assertEquals(resolveAppUserId(null), null);
  assertEquals(resolveAppUserId(42), null);
  assertEquals(resolveAppUserId("x".repeat(201)), null);
});

// ── Global spend circuit-breaker ────────────────────────────────────────

Deno.test("resolveGlobalDailyCeiling parses a valid positive env value", () => {
  assertEquals(resolveGlobalDailyCeiling("12345"), 12345);
});

Deno.test("resolveGlobalDailyCeiling falls back to the default for missing/invalid input", () => {
  assertEquals(resolveGlobalDailyCeiling(undefined), DEFAULT_GLOBAL_DAILY_PICK_CEILING);
  assertEquals(resolveGlobalDailyCeiling(""), DEFAULT_GLOBAL_DAILY_PICK_CEILING);
  assertEquals(resolveGlobalDailyCeiling("not-a-number"), DEFAULT_GLOBAL_DAILY_PICK_CEILING);
  assertEquals(resolveGlobalDailyCeiling("0"), DEFAULT_GLOBAL_DAILY_PICK_CEILING);
  assertEquals(resolveGlobalDailyCeiling("-5"), DEFAULT_GLOBAL_DAILY_PICK_CEILING);
});

Deno.test("reserveDenialResponse denies with DAILY_CAP_REACHED when the per-user reserve fails", () => {
  const denial = reserveDenialResponse({
    userReserveOk: false,
    globalReserveOk: false,
  });
  assertEquals(denial?.code, "DAILY_CAP_REACHED");
});

Deno.test("reserveDenialResponse denies with GLOBAL_CAP_REACHED when only the global breaker trips", () => {
  const denial = reserveDenialResponse({
    userReserveOk: true,
    globalReserveOk: false,
  });
  assertEquals(denial?.code, "GLOBAL_CAP_REACHED");
});

Deno.test("reserveDenialResponse allows the request through when both reservations succeed", () => {
  assertEquals(
    reserveDenialResponse({ userReserveOk: true, globalReserveOk: true }),
    null,
  );
});

Deno.test("global circuit-breaker trips even for a verified Pro caller under their (high) per-user cap", () => {
  // A verified Pro caller comfortably under PRO_DAILY_CAP can still be
  // blocked once the global breaker has tripped — the global ceiling is
  // an independent, tier-agnostic backstop.
  const denial = reserveDenialResponse({
    userReserveOk: true, // well under PRO_DAILY_CAP
    globalReserveOk: false, // global ceiling already exceeded
  });
  assertEquals(denial, { error: "quota_exceeded", code: "GLOBAL_CAP_REACHED" });
});
