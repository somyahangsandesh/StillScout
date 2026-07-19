// Pure helpers for vision-score — importable from Deno tests without
// starting the edge runtime.

export const MAX_BATCH_IMAGES = 48;

/// Max decoded JPEG bytes per image in a batch (~512 KB raw ≈ ~700 KB base64).
export const MAX_IMAGE_BASE64_CHARS = 700_000;

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function isUuidish(value: string): boolean {
  return UUID_RE.test(value.trim());
}

export function clientIp(headers: Headers): string {
  return (
    headers.get("cf-connecting-ip") ??
    headers.get("x-forwarded-for")?.split(",")[0]?.trim() ??
    "unknown"
  );
}

/** Accept a UUID device_id; otherwise fall back to the client IP. */
export function resolveDeviceKey(
  deviceId: unknown,
  headers: Headers,
): string {
  if (typeof deviceId === "string" && isUuidish(deviceId)) {
    return deviceId.trim();
  }
  return clientIp(headers);
}

// Log-only per-IP rate note (in-memory; resets on cold start).
const ipWindows = new Map<string, { count: number; windowStart: number }>();
const RATE_WINDOW_MS = 60_000;
const RATE_WARN_THRESHOLD = 30;

export function noteIpRequest(ip: string): void {
  const now = Date.now();
  const entry = ipWindows.get(ip);
  if (!entry || now - entry.windowStart > RATE_WINDOW_MS) {
    ipWindows.set(ip, { count: 1, windowStart: now });
    return;
  }
  entry.count += 1;
  if (entry.count === RATE_WARN_THRESHOLD + 1) {
    console.warn(
      `[vision-score] high request rate from ${ip}: ${entry.count}/min`,
    );
  }
}

/** Validates batch image strings — count, type, and per-image size cap. */
export function validateBatchImages(
  images: unknown,
): { ok: true; images: string[] } | { ok: false; error: string } {
  if (!Array.isArray(images)) {
    return { ok: false, error: "missing_images" };
  }
  const strings = images.filter((i) => typeof i === "string") as string[];
  if (strings.length === 0) {
    return { ok: false, error: "missing_images" };
  }
  if (strings.length > MAX_BATCH_IMAGES) {
    return { ok: false, error: "too_many_images" };
  }
  for (let i = 0; i < strings.length; i++) {
    if (strings[i].length > MAX_IMAGE_BASE64_CHARS) {
      return { ok: false, error: "image_too_large" };
    }
  }
  return { ok: true, images: strings };
}

/** Clamps pick_count to a sane range and never above frame count. */
export function resolvePickCount(
  raw: unknown,
  imageCount: number,
): number {
  const requested = typeof raw === "number"
    ? Math.round(raw)
    : 10;
  const clamped = Math.max(1, Math.min(48, requested));
  return Math.min(clamped, imageCount);
}
