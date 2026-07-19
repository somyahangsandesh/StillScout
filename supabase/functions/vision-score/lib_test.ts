import { assertEquals } from "jsr:@std/assert";
import {
  clientIp,
  isUuidish,
  MAX_BATCH_IMAGES,
  MAX_IMAGE_BASE64_CHARS,
  noteIpRequest,
  planQuotaFirstFlow,
  planQuotaFirstSingleFlow,
  resolveDeviceKey,
  resolvePickCount,
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

Deno.test("batch path reserves before Gemini", async () => {
  const src = await Deno.readTextFile(new URL("./index.ts", import.meta.url));
  const batch = src.slice(
    src.indexOf("// ── Batch path"),
    src.indexOf("// ── Single-frame path"),
  );
  assertEquals(batch.indexOf("tryReserveQuota") < batch.indexOf("tryGeminiBatch"), true);
  assertEquals(batch.includes("releaseQuota"), true);
});

Deno.test("single path reserves before Gemini", async () => {
  const src = await Deno.readTextFile(new URL("./index.ts", import.meta.url));
  const single = src.slice(src.indexOf("// ── Single-frame path"));
  assertEquals(
    single.indexOf("tryReserveQuota") < single.indexOf("tryGeminiSingle"),
    true,
  );
});
