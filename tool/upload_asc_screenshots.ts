#!/usr/bin/env -S deno run --allow-read --allow-write --allow-net --allow-env
/**
 * Upload iPhone 6.7" screenshots to App Store Connect (en-US + en-GB).
 * Replaces existing screenshots in each locale's APP_IPHONE_67 set.
 * Does NOT submit for review.
 *
 * Usage:
 *   deno run --allow-read --allow-write --allow-net --allow-env tool/upload_asc_screenshots.ts
 *   deno run ... tool/upload_asc_screenshots.ts --verify-only
 */
import { create, getNumericDate } from "https://deno.land/x/djwt@v3.0.2/mod.ts";
import { dirname, join, fromFileUrl, basename } from "jsr:@std/path@1";
import { crypto } from "jsr:@std/crypto@1";

const ROOT = join(dirname(fromFileUrl(import.meta.url)), "..");
const ENV_FILE = Deno.env.get("ASC_ENV_FILE") ?? join(ROOT, "secrets.asc.env");
const BUNDLE_ID = "com.stillscout.stillscout";
const TARGET_VERSION = "1.0";
const DISPLAY_TYPE = "APP_IPHONE_67";
const LOCALES = ["en-US", "en-GB"] as const;
const SCREENSHOT_DIR = join(ROOT, "docs/asc_assets/screenshots_67");
const SCREENSHOT_FILES = [
  "01_hero.png",
  "02_ai_scouting.png",
  "03_smart_selection.png",
  "04_stunning_results.png",
  "05_export.png",
];

type Env = Record<string, string>;

function loadEnv(path: string): Env {
  const env: Env = {};
  try {
    for (const line of Deno.readTextFileSync(path).split("\n")) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith("#")) continue;
      const eq = trimmed.indexOf("=");
      if (eq <= 0) continue;
      env[trimmed.slice(0, eq).trim()] = trimmed.slice(eq + 1).trim();
    }
  } catch {
    // optional
  }
  return env;
}

async function makeJwt(keyId: string, issuerId: string, pem: string): Promise<string> {
  const pemBody = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const der = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );
  return await create(
    { alg: "ES256", typ: "JWT", kid: keyId },
    { iss: issuerId, iat: getNumericDate(0), exp: getNumericDate(1200), aud: "appstoreconnect-v1" },
    key,
  );
}

async function ascFetch(token: string, path: string, init: RequestInit = {}): Promise<Response> {
  const headers = new Headers(init.headers);
  headers.set("Authorization", `Bearer ${token}`);
  if (init.body && !(init.body instanceof Uint8Array)) {
    headers.set("Content-Type", "application/json");
  }
  return await fetch(`https://api.appstoreconnect.apple.com/v1${path}`, { ...init, headers });
}

async function ascJson(token: string, path: string, init: RequestInit = {}) {
  const res = await ascFetch(token, path, init);
  const text = await res.text();
  if (!res.ok) throw new Error(`${path} → ${res.status}: ${text}`);
  return text ? JSON.parse(text) : null;
}

async function md5Base64(data: Uint8Array): Promise<string> {
  const hash = await crypto.subtle.digest("MD5", data);
  return btoa(String.fromCharCode(...new Uint8Array(hash)));
}

async function getAppId(token: string): Promise<string> {
  const json = await ascJson(token, `/apps?filter[bundleId]=${BUNDLE_ID}&limit=1`);
  const appId = json.data?.[0]?.id as string | undefined;
  if (!appId) throw new Error(`App not found for ${BUNDLE_ID}`);
  return appId;
}

async function getVersion(token: string, appId: string) {
  const json = await ascJson(
    token,
    `/apps/${appId}/appStoreVersions?filter[platform]=IOS&limit=20`,
  );
  const version = json.data?.find(
    (v: { attributes?: { versionString?: string } }) =>
      v.attributes?.versionString === TARGET_VERSION,
  );
  if (!version?.id) throw new Error(`Version ${TARGET_VERSION} not found`);
  return version as { id: string; attributes: Record<string, unknown> };
}

async function getLocalization(token: string, versionId: string, locale: string) {
  const json = await ascJson(token, `/appStoreVersions/${versionId}/appStoreVersionLocalizations`);
  const loc = json.data?.find(
    (l: { attributes?: { locale?: string } }) => l.attributes?.locale === locale,
  );
  if (!loc?.id) throw new Error(`Localization ${locale} not found`);
  return loc as { id: string; attributes: { locale: string } };
}

async function getOrCreateScreenshotSet(token: string, localizationId: string) {
  const json = await ascJson(
    token,
    `/appStoreVersionLocalizations/${localizationId}/appScreenshotSets`,
  );
  let set = json.data?.find(
    (s: { attributes?: { screenshotDisplayType?: string } }) =>
      s.attributes?.screenshotDisplayType === DISPLAY_TYPE,
  );
  if (set?.id) return set as { id: string };

  const created = await ascJson(token, "/appScreenshotSets", {
    method: "POST",
    body: JSON.stringify({
      data: {
        type: "appScreenshotSets",
        attributes: { screenshotDisplayType: DISPLAY_TYPE },
        relationships: {
          appStoreVersionLocalization: {
            data: { type: "appStoreVersionLocalizations", id: localizationId },
          },
        },
      },
    }),
  });
  return created.data as { id: string };
}

async function deleteExistingScreenshots(token: string, setId: string) {
  const json = await ascJson(token, `/appScreenshotSets/${setId}/appScreenshots`);
  for (const shot of json.data ?? []) {
    const id = shot.id as string;
    const res = await ascFetch(token, `/appScreenshots/${id}`, { method: "DELETE" });
    if (!res.ok && res.status !== 404) {
      const text = await res.text();
      throw new Error(`DELETE appScreenshots/${id} → ${res.status}: ${text}`);
    }
    console.log(`  deleted old screenshot ${id}`);
  }
}

async function uploadScreenshot(
  token: string,
  setId: string,
  filePath: string,
): Promise<string> {
  const data = await Deno.readFile(filePath);
  const fileName = basename(filePath);

  const reservation = await ascJson(token, "/appScreenshots", {
    method: "POST",
    body: JSON.stringify({
      data: {
        type: "appScreenshots",
        attributes: { fileName, fileSize: data.byteLength },
        relationships: {
          appScreenshotSet: { data: { type: "appScreenshotSets", id: setId } },
        },
      },
    }),
  });

  const screenshotId = reservation.data.id as string;
  const operations = reservation.data.attributes.uploadOperations as Array<{
    method: string;
    url: string;
    offset: number;
    length: number;
    requestHeaders: Array<{ name: string; value: string }>;
  }>;

  for (const op of operations) {
    const chunk = data.slice(op.offset, op.offset + op.length);
    const headers = new Headers();
    for (const h of op.requestHeaders ?? []) headers.set(h.name, h.value);
    const res = await fetch(op.url, { method: op.method, headers, body: chunk });
    if (!res.ok) {
      const text = await res.text();
      throw new Error(`Upload chunk failed → ${res.status}: ${text}`);
    }
  }

  const checksum = await md5Base64(data);
  await ascJson(token, `/appScreenshots/${screenshotId}`, {
    method: "PATCH",
    body: JSON.stringify({
      data: {
        type: "appScreenshots",
        id: screenshotId,
        attributes: { uploaded: true, sourceFileChecksum: checksum },
      },
    }),
  });

  // Poll until asset state is COMPLETE (or timeout)
  for (let i = 0; i < 30; i++) {
    const status = await ascJson(token, `/appScreenshots/${screenshotId}`);
    const state = status.data?.attributes?.assetDeliveryState?.state as string | undefined;
    if (state === "COMPLETE") return screenshotId;
    if (state === "FAILED") {
      throw new Error(`Screenshot upload failed: ${JSON.stringify(status.data?.attributes)}`);
    }
    await new Promise((r) => setTimeout(r, 2000));
  }
  throw new Error(`Screenshot ${screenshotId} did not reach COMPLETE in time`);
}

async function verifySet(token: string, setId: string, locale: string) {
  const json = await ascJson(token, `/appScreenshotSets/${setId}/appScreenshots`);
  const shots = (json.data ?? []) as Array<{
    attributes?: {
      fileName?: string;
      assetDeliveryState?: { state?: string };
    };
  }>;
  const states = shots.map((s) => s.attributes?.assetDeliveryState?.state ?? "UNKNOWN");
  const allComplete = states.length > 0 && states.every((s) => s === "COMPLETE");
  return {
    locale,
    setId,
    count: shots.length,
    allComplete,
    files: shots.map((s) => s.attributes?.fileName),
    states,
  };
}

async function main() {
  const verifyOnly = Deno.args.includes("--verify-only");
  const fileEnv = loadEnv(ENV_FILE);
  const keyId = Deno.env.get("ASC_KEY_ID") ?? fileEnv.ASC_KEY_ID ?? "";
  const issuerId = Deno.env.get("ASC_ISSUER_ID") ?? fileEnv.ASC_ISSUER_ID ?? "";
  const keyPath = Deno.env.get("ASC_KEY_PATH") ?? fileEnv.ASC_KEY_PATH ?? "";
  if (!keyId || !issuerId || !keyPath) {
    console.error("Missing ASC_KEY_ID, ASC_ISSUER_ID, or ASC_KEY_PATH");
    Deno.exit(1);
  }

  const pem = Deno.readTextFileSync(keyPath);
  const token = await makeJwt(keyId, issuerId, pem);
  const appId = await getAppId(token);
  const version = await getVersion(token, appId);

  const report: Record<string, unknown> = {
    appId,
    versionId: version.id,
    displayType: DISPLAY_TYPE,
    locales: {} as Record<string, unknown>,
  };

  for (const locale of LOCALES) {
    console.log(`\n── ${locale} ──`);
    const loc = await getLocalization(token, version.id, locale);
    const set = await getOrCreateScreenshotSet(token, loc.id);

    if (!verifyOnly) {
      await deleteExistingScreenshots(token, set.id);
      const uploaded: string[] = [];
      for (const file of SCREENSHOT_FILES) {
        const path = join(SCREENSHOT_DIR, file);
        console.log(`  uploading ${file}…`);
        const id = await uploadScreenshot(token, set.id, path);
        uploaded.push(id);
        console.log(`  ✓ ${file} → ${id}`);
      }
      (report.locales as Record<string, unknown>)[locale] = { uploaded };
    }

    const verification = await verifySet(token, set.id, locale);
    (report.locales as Record<string, unknown>)[locale] = {
      ...((report.locales as Record<string, unknown>)[locale] as object ?? {}),
      ...verification,
    };
    console.log(
      `  ${verification.allComplete ? "COMPLETE" : "INCOMPLETE"} — ${verification.count} screenshots`,
    );
  }

  console.log("\n" + JSON.stringify(report, null, 2));
}

await main();
