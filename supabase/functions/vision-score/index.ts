// =============================================================================
// vision-score — StillScout Supabase Edge Function
// =============================================================================
// Server-side Gemini proxy so API keys never ship in release app binaries.
//
// Single-frame: POST { image, device_id?, context? }
// Batch (AI Pro): POST { images: string[], pick_count, device_id?, context? }
//
// Deploy: supabase functions deploy vision-score
// Secrets: supabase secrets set GEMINI_API_KEY=...
// =============================================================================

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import {
  clientIp,
  MAX_BATCH_IMAGES,
  noteIpRequest,
  resolveDeviceKey,
} from "./lib.ts";

const DAILY_CAP = 200;

const GEMINI_KEY = Deno.env.get("GEMINI_API_KEY") ?? "";
const GEMINI_MODEL = "gemini-3.1-flash-lite";

const SYSTEM_PROMPT = `\
You are a meticulous photo scout helping a short-form video creator pick the \
single best still frame to export from their footage. You will see ONE frame. \
Score it honestly and independently on four axes, each an integer 1-100 \
(100 = excellent, 1 = unusable):

- blur_score: sharpness/focus of the main subject. Motion blur or soft focus = low.
- lighting_score: exposure quality — penalise both underexposed (too dark) and blown-out highlights. Even, flattering light = high.
- open_eyes_score: if a face is visible, how open/alert/flattering the eyes and expression are (closed eyes, mid-blink, awkward expression = low). If no face is visible, judge general subject clarity and energy instead.
- composition_score: framing quality — rule of thirds, headroom, leading lines, background clutter, subject placement.

Respond with ONLY compact JSON, no markdown, no prose, matching exactly:
{"blur_score":<int>,"lighting_score":<int>,"open_eyes_score":<int>,"composition_score":<int>,"summary":"<one short clause, max 14 words, on why this frame stands out or falls short>"}`;

const CONTEXT_INSTRUCTIONS: Record<string, string> = {
  portrait:
    "\n\nShot intent: PORTRAIT/SELFIE. A person's face is the primary subject and near-fills the frame. Weigh open_eyes_score heavily — judge open eyes, natural/flattering expression, and gaze — and penalize composition harder for awkward face cropping.",
  action:
    "\n\nShot intent: ACTION. The subject is moving fast (sports, pets, dance, etc). Prioritize blur_score above all — a frame that is razor-sharp but imperfectly composed beats a well-framed but motion-blurred one.",
  landscape:
    "\n\nShot intent: LANDSCAPE/SCENERY. No person is expected to be the subject. Score open_eyes_score based on overall scene sharpness, depth, and visual interest instead of faces. Weigh composition_score (framing, rule of thirds, horizon, leading lines) as the most important axis.",
  event:
    "\n\nShot intent: EVENT/GROUP. Multiple people may be visible. Judge open_eyes_score by the proportion of visible people with open eyes and genuine expressions, not just one face, and judge composition by how well the group and setting are framed together.",
};

function systemPromptFor(context: string | undefined): string {
  const extra = context ? CONTEXT_INSTRUCTIONS[context] : undefined;
  return extra ? SYSTEM_PROMPT + extra : SYSTEM_PROMPT;
}

function batchScoringPromptFor(
  context: string,
  frameCount: number,
  pickCount: number,
): string {
  const contextBlock = batchContextInstructionFor(context);
  return `You are an elite photo editor reviewing ${frameCount} frames from a single video. Frames are numbered 0 through ${frameCount - 1} and attached in order.

MANDATORY RULES — follow exactly or your output is invalid:
1. The "scores" array MUST contain exactly ${frameCount} objects — one per frame, indices 0 through ${frameCount - 1}. Never skip a frame.
2. The "picks" array MUST contain exactly ${pickCount} indices (the best ${pickCount} frames).
3. Output ONLY raw JSON — no markdown, no code fences, no extra text before or after.

PART 1 — Score EVERY frame (all ${frameCount}) on four axes (integers 1–100):
  • b (blur)       : sharpness of main subject.
  • l (lighting)   : exposure quality.
  • e (expression) : faces — openness/expression; no face — visual energy.
  • c (composition): rule of thirds, subject placement, balance.

PART 2 — Pick the ${pickCount} best frames.
${contextBlock}

JSON format (copy exactly, fill values):
{"scores":[{"i":0,"b":0,"l":0,"e":0,"c":0,"n":"note"},...],"picks":[best indices],"note":"≤20 word summary"}`;
}

function batchContextInstructionFor(context: string): string {
  switch (context) {
    case "portrait":
      return "Shot type: PORTRAIT / SELFIE — weigh expression and open eyes heavily.";
    case "action":
      return "Shot type: ACTION — prioritize peak moment and subject sharpness.";
    case "landscape":
      return "Shot type: LANDSCAPE — weigh composition and light; no face required.";
    case "event":
      return "Shot type: EVENT / GROUP — collective energy and open eyes across people.";
    default:
      return "Shot type: AUTO — judge purely on photographic impact.";
  }
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

async function tryConsumeQuota(deviceId: string): Promise<boolean> {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data, error } = await supabase.rpc("try_consume_vision_quota", {
    p_device_id: deviceId,
    p_cap: DAILY_CAP,
  });

  if (error) {
    // Fail closed — never allow unlimited proxy use when the DB is down.
    console.warn("[vision-score] quota RPC error — failing closed:", error.message);
    return false;
  }

  return data === true;
}

async function tryConsumeQuotaBatch(
  deviceId: string,
  count: number,
): Promise<boolean> {
  for (let i = 0; i < count; i++) {
    if (!await tryConsumeQuota(deviceId)) return false;
  }
  return true;
}

interface ScoreResult {
  blur_score: number;
  lighting_score: number;
  open_eyes_score: number;
  composition_score: number;
  summary: string;
}

function parseScore(raw: string): ScoreResult | null {
  let json: Record<string, unknown> | null = null;
  try {
    json = JSON.parse(raw);
  } catch {
    const match = /\{[\s\S]*\}/.exec(raw);
    if (!match) return null;
    try {
      json = JSON.parse(match[0]);
    } catch {
      return null;
    }
  }
  if (!json) return null;

  const b = json["blur_score"];
  const l = json["lighting_score"];
  const o = json["open_eyes_score"];
  const c = json["composition_score"];
  const s = json["summary"];

  if (
    typeof b !== "number" || typeof l !== "number" ||
    typeof o !== "number" || typeof c !== "number"
  ) return null;

  return {
    blur_score: Math.round(Math.min(100, Math.max(1, b))),
    lighting_score: Math.round(Math.min(100, Math.max(1, l))),
    open_eyes_score: Math.round(Math.min(100, Math.max(1, o))),
    composition_score: Math.round(Math.min(100, Math.max(1, c))),
    summary: typeof s === "string" ? s.slice(0, 100) : "",
  };
}

async function tryGeminiSingle(
  base64Jpeg: string,
  context?: string,
): Promise<ScoreResult | null> {
  if (!GEMINI_KEY) return null;
  try {
    const url =
      `https://generativelanguage.googleapis.com/v1/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_KEY}`;
    const resp = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        generationConfig: {
          // responseMimeType rejected by AQ.* keys on newer models —
          // JSON is enforced via the system prompt instead.
          maxOutputTokens: 512,
        },
        contents: [{
          parts: [
            { text: systemPromptFor(context) },
            { inline_data: { mime_type: "image/jpeg", data: base64Jpeg } },
          ],
        }],
      }),
      signal: AbortSignal.timeout(20_000),
    });
    if (!resp.ok) {
      console.warn(`[vision-score] Gemini single failed: ${resp.status}`);
      return null;
    }
    const data = await resp.json();
    const content: string = data?.candidates?.[0]?.content?.parts?.[0]?.text ??
      "";
    return parseScore(content);
  } catch (e) {
    console.warn("[vision-score] Gemini single error:", e);
    return null;
  }
}

type GeminiBatchResult =
  | { ok: true; batch: Record<string, unknown> }
  | { ok: false; incomplete: true; detail: string }
  | { ok: false; incomplete: false };

async function tryGeminiBatch(
  images: string[],
  pickCount: number,
  context: string,
): Promise<GeminiBatchResult> {
  if (!GEMINI_KEY || images.length === 0) {
    return { ok: false, incomplete: false };
  }

  const prompt = batchScoringPromptFor(context, images.length, pickCount);
  const parts: Array<Record<string, unknown>> = [{ text: prompt }];
  for (let i = 0; i < images.length; i++) {
    parts.push({ text: `Frame ${i}:` });
    parts.push({
      inline_data: { mime_type: "image/jpeg", data: images[i] },
    });
  }

  try {
    const url =
      `https://generativelanguage.googleapis.com/v1/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_KEY}`;
    const resp = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        generationConfig: {
          temperature: 0.1,
          maxOutputTokens: 8192,
        },
        contents: [{ role: "user", parts }],
      }),
      signal: AbortSignal.timeout(60_000),
    });
    if (!resp.ok) {
      console.warn(`[vision-score] Gemini batch failed: ${resp.status}`);
      return { ok: false, incomplete: false };
    }
    const data = await resp.json();
    const text: string = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
    if (!text) return { ok: false, incomplete: false };

    let json: Record<string, unknown> | null = null;
    try {
      json = JSON.parse(text);
    } catch {
      const match = /\{[\s\S]*\}/.exec(text);
      if (!match) return { ok: false, incomplete: false };
      try {
        json = JSON.parse(match[0]);
      } catch {
        return { ok: false, incomplete: false };
      }
    }
    if (!json || !Array.isArray(json["scores"]) || !Array.isArray(json["picks"])) {
      return { ok: false, incomplete: false };
    }
    // Reject sparse responses — every frame must be scored.
    const scores = json["scores"] as unknown[];
    if (scores.length < images.length) {
      const detail = `got ${scores.length}/${images.length} frame scores`;
      console.warn(`[vision-score] Incomplete batch scores: ${detail}`);
      return { ok: false, incomplete: true, detail };
    }
    const indices = new Set<number>();
    for (const entry of scores) {
      if (typeof entry !== "object" || entry === null) continue;
      const idx = (entry as Record<string, unknown>)["i"];
      if (typeof idx === "number" && Number.isInteger(idx)) {
        indices.add(idx);
      }
    }
    for (let i = 0; i < images.length; i++) {
      if (!indices.has(i)) {
        const detail = `missing score for frame index ${i}`;
        console.warn(`[vision-score] ${detail}`);
        return { ok: false, incomplete: true, detail };
      }
    }
    return { ok: true, batch: json };
  } catch (e) {
    console.warn("[vision-score] Gemini batch error:", e);
    return { ok: false, incomplete: false };
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "invalid_json" }, 400);
  }

  const deviceKey = resolveDeviceKey(body.device_id, req.headers);
  noteIpRequest(clientIp(req.headers));

  const context = typeof body.context === "string" ? body.context : "auto";

  // ── Batch path (AI Pro) ───────────────────────────────────────────────────
  if (Array.isArray(body.images)) {
    const images = body.images.filter((i) => typeof i === "string") as string[];
    const pickCount = typeof body.pick_count === "number"
      ? Math.max(1, Math.min(48, Math.round(body.pick_count)))
      : 10;

    if (images.length === 0) {
      return jsonResponse({ error: "missing_images" }, 400);
    }

    if (images.length > MAX_BATCH_IMAGES) {
      return jsonResponse(
        { error: "too_many_images", max: MAX_BATCH_IMAGES },
        400,
      );
    }

    if (!GEMINI_KEY) {
      return jsonResponse({ error: "gemini_not_configured" }, 503);
    }

    const batchResult = await tryGeminiBatch(images, pickCount, context);
    if (!batchResult.ok) {
      if (batchResult.incomplete) {
        return jsonResponse(
          {
            error: "incomplete_batch_scores",
            detail: batchResult.detail,
          },
          422,
        );
      }
      return jsonResponse({ error: "batch_failed" }, 503);
    }

    const quotaOk = await tryConsumeQuotaBatch(deviceKey, pickCount);
    if (!quotaOk) {
      return jsonResponse(
        { error: "quota_exceeded", code: "DAILY_CAP_REACHED" },
        429,
      );
    }

    return jsonResponse(batchResult.batch);
  }

  // ── Single-frame path ─────────────────────────────────────────────────────
  const image = body.image;
  if (!image || typeof image !== "string") {
    return jsonResponse({ error: "missing_image" }, 400);
  }

  const score = await tryGeminiSingle(image, context);
  if (!score) {
    return jsonResponse({ error: "gemini_failed" }, 503);
  }

  const allowed = await tryConsumeQuota(deviceKey);
  if (!allowed) {
    return jsonResponse(
      { error: "quota_exceeded", code: "DAILY_CAP_REACHED" },
      429,
    );
  }

  return jsonResponse(score);
});
