// Pure helpers for vision-score — importable from Deno tests without
// starting the edge runtime.

export const MAX_BATCH_IMAGES = 48;

/** Max decoded JPEG bytes per image in a batch (~512 KB raw ≈ ~700 KB base64). */
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

const ipWindows = new Map<string, { count: number; windowStart: number }>();
const RATE_WINDOW_MS = 60_000;
const RATE_WARN_THRESHOLD = 30;

/**
 * Hard per-IP ceiling within [RATE_WINDOW_MS]. This is a coarse abuse
 * backstop on top of the per-device daily quota (which is the primary
 * control) — it exists to blunt a single IP hammering the function with
 * spoofed/rotating device_ids (e.g. NAT/carrier-shared IPs get a generous
 * allowance; a genuinely malicious client hammering the endpoint does not).
 */
const RATE_BLOCK_THRESHOLD = 90;

/** Records one request from [ip] and returns the request count so far in
 * the current window (used by [isIpRateLimited]). */
export function noteIpRequest(ip: string): number {
  const now = Date.now();
  const entry = ipWindows.get(ip);
  if (!entry || now - entry.windowStart > RATE_WINDOW_MS) {
    ipWindows.set(ip, { count: 1, windowStart: now });
    return 1;
  }
  entry.count += 1;
  if (entry.count === RATE_WARN_THRESHOLD + 1) {
    console.warn(
      `[vision-score] high request rate from ${ip}: ${entry.count}/min`,
    );
  }
  if (entry.count === RATE_BLOCK_THRESHOLD) {
    console.warn(
      `[vision-score] soft-blocking ${ip}: ${entry.count}/min exceeds cap`,
    );
  }
  return entry.count;
}

/** True once [ip] has exceeded [RATE_BLOCK_THRESHOLD] requests in the
 * current 1-minute window — callers should reject with 429 before doing
 * any quota reservation or Gemini spend. */
export function isIpRateLimited(ip: string): boolean {
  const entry = ipWindows.get(ip);
  if (!entry) return false;
  if (Date.now() - entry.windowStart > RATE_WINDOW_MS) return false;
  return entry.count >= RATE_BLOCK_THRESHOLD;
}

/** Exposed for tests only — clears in-memory rate-limit state. */
export function _resetIpWindowsForTests(): void {
  ipWindows.clear();
}

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

export function resolvePickCount(
  raw: unknown,
  imageCount: number,
): number {
  const requested = typeof raw === "number" ? Math.round(raw) : 10;
  const clamped = Math.max(1, Math.min(48, requested));
  return Math.min(clamped, imageCount);
}

export type ScoringOutcome = "success" | "failed" | "incomplete";

export interface QuotaFirstFlowResult {
  calledGemini: boolean;
  releaseReservation: boolean;
  httpStatus: number;
  error?: string;
  code?: string;
}

export function planQuotaFirstFlow(opts: {
  reserveOk: boolean;
  scoring?: ScoringOutcome;
}): QuotaFirstFlowResult {
  if (!opts.reserveOk) {
    return {
      calledGemini: false,
      releaseReservation: false,
      httpStatus: 429,
      error: "quota_exceeded",
      code: "DAILY_CAP_REACHED",
    };
  }
  const scoring = opts.scoring ?? "failed";
  if (scoring === "success") {
    return { calledGemini: true, releaseReservation: false, httpStatus: 200 };
  }
  if (scoring === "incomplete") {
    return {
      calledGemini: true,
      releaseReservation: true,
      httpStatus: 422,
      error: "incomplete_batch_scores",
    };
  }
  return {
    calledGemini: true,
    releaseReservation: true,
    httpStatus: 503,
    error: "batch_failed",
  };
}

export function planQuotaFirstSingleFlow(opts: {
  reserveOk: boolean;
  scoreOk?: boolean;
}): QuotaFirstFlowResult {
  if (!opts.reserveOk) {
    return {
      calledGemini: false,
      releaseReservation: false,
      httpStatus: 429,
      error: "quota_exceeded",
      code: "DAILY_CAP_REACHED",
    };
  }
  if (opts.scoreOk) {
    return { calledGemini: true, releaseReservation: false, httpStatus: 200 };
  }
  return {
    calledGemini: true,
    releaseReservation: true,
    httpStatus: 503,
    error: "gemini_failed",
  };
}
