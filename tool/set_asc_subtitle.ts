#!/usr/bin/env -S deno run --allow-read --allow-net --allow-env
/**
 * Set App Store Connect subtitle for StillScout version 1.0 (en-GB + en-US).
 *
 * Requires secrets.asc.env with ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH.
 *
 * Usage:
 *   deno run --allow-read --allow-net --allow-env tool/set_asc_subtitle.ts
 *   deno run --allow-read --allow-net --allow-env tool/set_asc_subtitle.ts "Best stills from any video"
 */

import { create, getNumericDate } from "https://deno.land/x/djwt@v3.0.2/mod.ts";

const ROOT = new URL("../", import.meta.url).pathname;
const ENV_FILE = Deno.env.get("ASC_ENV_FILE") ??
  `${ROOT}secrets.asc.env`;
const BUNDLE_ID = "com.stillscout.stillscout";
const DEFAULT_SUBTITLE = "Best stills from any video";

type Env = Record<string, string>;

function loadEnv(path: string): Env {
  const env: Env = {};
  try {
    const text = Deno.readTextFileSync(path);
    for (const line of text.split("\n")) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith("#")) continue;
      const eq = trimmed.indexOf("=");
      if (eq <= 0) continue;
      env[trimmed.slice(0, eq).trim()] = trimmed.slice(eq + 1).trim();
    }
  } catch {
    // optional file
  }
  return env;
}

function b64url(data: Uint8Array): string {
  return btoa(String.fromCharCode(...data))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");
}

async function makeJwt(
  keyId: string,
  issuerId: string,
  pem: string,
): Promise<string> {
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

async function ascFetch(
  token: string,
  path: string,
  init: RequestInit = {},
): Promise<Response> {
  const url = `https://api.appstoreconnect.apple.com/v1${path}`;
  const headers = new Headers(init.headers);
  headers.set("Authorization", `Bearer ${token}`);
  headers.set("Content-Type", "application/json");
  return await fetch(url, { ...init, headers });
}

async function main() {
  const fileEnv = loadEnv(ENV_FILE);
  const keyId = Deno.env.get("ASC_KEY_ID") ?? fileEnv.ASC_KEY_ID ?? "725F75L52R";
  const issuerId = Deno.env.get("ASC_ISSUER_ID") ?? fileEnv.ASC_ISSUER_ID ?? "";
  const keyPath = Deno.env.get("ASC_KEY_PATH") ?? fileEnv.ASC_KEY_PATH ?? "";
  const subtitle = Deno.args[0]?.trim() || DEFAULT_SUBTITLE;

  if (!issuerId || !keyPath) {
    console.error(
      "Missing ASC_ISSUER_ID or ASC_KEY_PATH — set secrets.asc.env and retry.",
    );
    Deno.exit(1);
  }
  if (subtitle.length > 30) {
    console.error(`Subtitle too long (${subtitle.length}/30): ${subtitle}`);
    Deno.exit(1);
  }

  const pem = Deno.readTextFileSync(keyPath);
  const token = await makeJwt(keyId, issuerId, pem);

  const appsRes = await ascFetch(
    token,
    `/apps?filter[bundleId]=${BUNDLE_ID}&limit=1`,
  );
  if (!appsRes.ok) {
    console.error("List apps failed:", appsRes.status, await appsRes.text());
    Deno.exit(1);
  }
  const appsJson = await appsRes.json();
  const appId = appsJson.data?.[0]?.id as string | undefined;
  if (!appId) {
    console.error("App not found for bundle", BUNDLE_ID);
    Deno.exit(1);
  }

  const versionsRes = await ascFetch(
    token,
    `/apps/${appId}/appStoreVersions?filter[appStoreState]=PREPARE_FOR_SUBMISSION,READY_FOR_SALE,DEVELOPER_REJECTED,REJECTED,METADATA_REJECTED,WAITING_FOR_REVIEW&limit=5`,
  );
  if (!versionsRes.ok) {
    console.error("List versions failed:", versionsRes.status, await versionsRes.text());
    Deno.exit(1);
  }
  const versionsJson = await versionsRes.json();
  const version =
    versionsJson.data?.find((v: { attributes?: { versionString?: string } }) =>
      v.attributes?.versionString === "1.0"
    ) ?? versionsJson.data?.[0];
  const versionId = version?.id as string | undefined;
  if (!versionId) {
    console.error("No app store version found");
    Deno.exit(1);
  }

  const locRes = await ascFetch(token, `/apps/${appId}/appInfos`);
  if (!locRes.ok) {
    console.error("List app infos failed:", locRes.status, await locRes.text());
    Deno.exit(1);
  }
  const appInfosJson = await locRes.json();
  const appInfoId = appInfosJson.data?.[0]?.id as string | undefined;
  if (!appInfoId) {
    console.error("No app info resource found");
    Deno.exit(1);
  }

  const infoLocRes = await ascFetch(
    token,
    `/appInfos/${appInfoId}/appInfoLocalizations`,
  );
  if (!infoLocRes.ok) {
    console.error("List app info localizations failed:", infoLocRes.status, await infoLocRes.text());
    Deno.exit(1);
  }
  const locJson = await infoLocRes.json();
  const targets = (locJson.data ?? []).filter(
    (l: { attributes?: { locale?: string } }) =>
      l.attributes?.locale === "en-US" || l.attributes?.locale === "en-GB",
  );

  if (targets.length === 0) {
    console.error("No en-US/en-GB localizations on version 1.0");
    Deno.exit(1);
  }

  for (const loc of targets) {
    const locId = loc.id as string;
    const locale = loc.attributes?.locale as string;
    const patchRes = await ascFetch(token, `/appInfoLocalizations/${locId}`, {
      method: "PATCH",
      body: JSON.stringify({
        data: {
          type: "appInfoLocalizations",
          id: locId,
          attributes: { subtitle },
        },
      }),
    });
    if (!patchRes.ok) {
      console.error(`PATCH ${locale} failed:`, patchRes.status, await patchRes.text());
      Deno.exit(1);
    }
    console.log(`OK — ${locale} subtitle → "${subtitle}"`);
  }
}

await main();
