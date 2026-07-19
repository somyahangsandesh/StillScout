import { assertEquals } from "jsr:@std/assert";
import {
  clientIp,
  isUuidish,
  MAX_BATCH_IMAGES,
  noteIpRequest,
  resolveDeviceKey,
} from "./lib.ts";

Deno.test("isUuidish accepts standard UUID v4", () => {
  assertEquals(
    isUuidish("550e8400-e29b-41d4-a716-446655440000"),
    true,
  );
  assertEquals(isUuidish("not-a-uuid"), false);
  assertEquals(isUuidish("12345"), false);
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
  assertEquals(resolveDeviceKey(undefined, headers), "203.0.113.9");
});

Deno.test("clientIp reads cf-connecting-ip first", () => {
  const headers = new Headers({
    "cf-connecting-ip": "198.51.100.2",
    "x-forwarded-for": "10.0.0.1, 10.0.0.2",
  });
  assertEquals(clientIp(headers), "198.51.100.2");
});

Deno.test("MAX_BATCH_IMAGES is 48", () => {
  assertEquals(MAX_BATCH_IMAGES, 48);
});

Deno.test("noteIpRequest is safe to call repeatedly", () => {
  noteIpRequest("127.0.0.1");
  noteIpRequest("127.0.0.1");
});
