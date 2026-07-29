#!/usr/bin/env -S deno run --allow-read --allow-net --allow-env
/**
 * ASC ops: build status, attach build, verify IAPs/subtitle/release type.
 * Does NOT submit for review.
 */
import { create, getNumericDate } from "https://deno.land/x/djwt@v3.0.2/mod.ts";

const ROOT = new URL("../", import.meta.url).pathname;
const ENV_FILE = Deno.env.get("ASC_ENV_FILE") ?? `${ROOT}secrets.asc.env`;
const BUNDLE_ID = "com.stillscout.stillscout";
const TARGET_VERSION = "1.0";
const TARGET_BUILD = 25;

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
  if (init.body) headers.set("Content-Type", "application/json");
  return await fetch(`https://api.appstoreconnect.apple.com/v1${path}`, { ...init, headers });
}

async function ascJson(token: string, path: string, init: RequestInit = {}) {
  const res = await ascFetch(token, path, init);
  const text = await res.text();
  if (!res.ok) throw new Error(`${path} → ${res.status}: ${text}`);
  return JSON.parse(text);
}

async function getAppId(token: string): Promise<string> {
  const json = await ascJson(token, `/apps?filter[bundleId]=${BUNDLE_ID}&limit=1`);
  const appId = json.data?.[0]?.id as string | undefined;
  if (!appId) throw new Error(`App not found for ${BUNDLE_ID}`);
  return appId;
}

async function getVersion1(token: string, appId: string) {
  const json = await ascJson(
    token,
    `/apps/${appId}/appStoreVersions?filter[platform]=IOS&limit=20`,
  );
  const version = json.data?.find(
    (v: { attributes?: { versionString?: string } }) =>
      v.attributes?.versionString === TARGET_VERSION,
  ) ?? json.data?.[0];
  if (!version?.id) throw new Error("No app store version found");
  return version as {
    id: string;
    attributes: {
      versionString?: string;
      appStoreState?: string;
      releaseType?: string;
    };
  };
}

async function listBuilds(token: string, appId: string) {
  const json = await ascJson(
    token,
    `/builds?filter[app]=${appId}&sort=-uploadedDate&limit=15&include=preReleaseVersion`,
  );
  return json.data as Array<{
    id: string;
    attributes: { version?: string; processingState?: string; uploadedDate?: string };
  }>;
}

async function getAttachedBuild(token: string, versionId: string) {
  const json = await ascJson(token, `/appStoreVersions/${versionId}/build`);
  const build = json.data;
  if (!build) return null;
  return build as { id: string; attributes: { version?: string; processingState?: string } };
}

async function attachBuild(token: string, versionId: string, buildId: string) {
  const res = await ascFetch(token, `/appStoreVersions/${versionId}/relationships/build`, {
    method: "PATCH",
    body: JSON.stringify({
      data: { type: "builds", id: buildId },
    }),
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`attach build → ${res.status}: ${text}`);
  return text ? JSON.parse(text) : null;
}

async function getSubtitles(token: string, appId: string) {
  const appInfos = await ascJson(token, `/apps/${appId}/appInfos`);
  const appInfoId = appInfos.data?.[0]?.id as string;
  if (!appInfoId) return {};
  const locs = await ascJson(token, `/appInfos/${appInfoId}/appInfoLocalizations`);
  const out: Record<string, string | null> = {};
  for (const loc of locs.data ?? []) {
    const locale = loc.attributes?.locale as string;
    if (locale === "en-US" || locale === "en-GB") {
      out[locale] = loc.attributes?.subtitle as string | null;
    }
  }
  return out;
}

async function getIapStates(token: string, appId: string) {
  const json = await ascJson(token, `/apps/${appId}/inAppPurchases?limit=50`);
  const targets = ["stillscout_pro_monthly", "stillscout_pro_yearly"];
  const out: Record<string, string> = {};
  for (const iap of json.data ?? []) {
    const attrs = iap.attributes as { productId?: string; state?: string };
    const pid = attrs.productId ?? "";
    if (targets.includes(pid)) {
      out[pid] = attrs.state ?? "UNKNOWN";
    }
  }
  return out;
}

async function getReviewPhone(token: string, versionId: string) {
  const json = await ascJson(token, `/appStoreVersions/${versionId}/appStoreReviewDetail`);
  const detail = json.data;
  return detail?.attributes?.contactPhone as string | undefined;
}

async function setReleaseTypeManual(token: string, versionId: string, current: string | undefined) {
  if (current === "MANUAL") return current;
  const res = await ascFetch(token, `/appStoreVersions/${versionId}`, {
    method: "PATCH",
    body: JSON.stringify({
      data: {
        type: "appStoreVersions",
        id: versionId,
        attributes: { releaseType: "MANUAL" },
      },
    }),
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`set releaseType → ${res.status}: ${text}`);
  return "MANUAL";
}

async function main() {
  const attach = Deno.args.includes("--attach");
  const fileEnv = loadEnv(ENV_FILE);
  const keyId = Deno.env.get("ASC_KEY_ID") ?? fileEnv.ASC_KEY_ID ?? "725F75L52R";
  const issuerId = Deno.env.get("ASC_ISSUER_ID") ?? fileEnv.ASC_ISSUER_ID ?? "";
  const keyPath = Deno.env.get("ASC_KEY_PATH") ?? fileEnv.ASC_KEY_PATH ?? "";
  if (!issuerId || !keyPath) {
    console.error("Missing ASC_ISSUER_ID or ASC_KEY_PATH");
    Deno.exit(1);
  }

  const pem = Deno.readTextFileSync(keyPath);
  const token = await makeJwt(keyId, issuerId, pem);
  const appId = await getAppId(token);
  const version = await getVersion1(token, appId);
  const versionId = version.id;
  const builds = await listBuilds(token, appId);
  const build25 = builds.find((b) => b.attributes.version === String(TARGET_BUILD));
  const attached = await getAttachedBuild(token, versionId);
  const subtitles = await getSubtitles(token, appId);
  const iaps = await getIapStates(token, appId);
  const reviewPhone = await getReviewPhone(token, versionId);

  const report = {
    appId,
    version: {
      id: versionId,
      versionString: version.attributes.versionString,
      appStoreState: version.attributes.appStoreState,
      releaseType: version.attributes.releaseType,
    },
    build25: build25
      ? {
          id: build25.id,
          version: build25.attributes.version,
          processingState: build25.attributes.processingState,
          uploadedDate: build25.attributes.uploadedDate,
        }
      : null,
    attachedBuild: attached
      ? {
          id: attached.id,
          version: attached.attributes.version,
          processingState: attached.attributes.processingState,
        }
      : null,
    subtitles,
    iaps,
    reviewPhone,
    attachAttempted: false,
    attachResult: null as string | null,
    releaseTypeAfter: version.attributes.releaseType,
  };

  if (attach && build25?.attributes.processingState === "VALID") {
    if (attached?.id !== build25.id) {
      try {
        await attachBuild(token, versionId, build25.id);
        report.attachAttempted = true;
        report.attachResult = "OK — build 25 attached";
        const newAttached = await getAttachedBuild(token, versionId);
        report.attachedBuild = newAttached
          ? {
              id: newAttached.id,
              version: newAttached.attributes.version,
              processingState: newAttached.attributes.processingState,
            }
          : null;
      } catch (e) {
        report.attachAttempted = true;
        report.attachResult = String(e);
      }
    } else {
      report.attachResult = "Already attached";
    }
  }

  try {
    report.releaseTypeAfter = await setReleaseTypeManual(
      token,
      versionId,
      version.attributes.releaseType,
    );
  } catch (e) {
    report.releaseTypeAfter = `error: ${e}`;
  }

  console.log(JSON.stringify(report, null, 2));
}

await main();
