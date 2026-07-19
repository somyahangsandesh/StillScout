// Pure helpers for vision-score — importable from Deno tests without
// starting the edge runtime.

export const MAX_BATCH_IMAGES = 48;

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
