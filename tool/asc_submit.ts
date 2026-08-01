#!/usr/bin/env -S deno run --allow-read --allow-net --allow-env
/**
 * ASC submit for review + privacy probe + account phone search.
 */
import { create, getNumericDate } from "https://deno.land/x/djwt@v3.0.2/mod.ts";

const ROOT = new URL("../", import.meta.url).pathname;
const ENV_FILE = Deno.env.get("ASC_ENV_FILE") ?? `${ROOT}secrets.asc.env`;
const BUNDLE_ID = "com.stillscout.stillscout";
const APP_ID = "6790234719";
const VERSION_ID = "0676e217-a370-4728-ab95-39a65ce42515";
const REVIEW_DETAIL_ID = "c4685cc0-a698-42ab-a5a6-9fc042ae0e2d";
const SUB_MONTHLY = "6792454070";
const SUB_YEARLY = "6792454034";

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

async function ascProbe(token: string, path: string, init: RequestInit = {}) {
  const res = await ascFetch(token, path, init);
  const text = await res.text();
  return { path, status: res.status, body: text.slice(0, 2000) };
}

async function ascJson(token: string, path: string, init: RequestInit = {}) {
  const res = await ascFetch(token, path, init);
  const text = await res.text();
  if (!res.ok) throw new Error(`${path} → ${res.status}: ${text}`);
  return JSON.parse(text);
}

function extractPhones(obj: unknown, found: string[] = []): string[] {
  if (obj === null || obj === undefined) return found;
  if (typeof obj === "string") {
    if (/\+?\d[\d\s\-().]{7,}/.test(obj) && !obj.includes("000-000")) {
      found.push(obj);
    }
    return found;
  }
  if (Array.isArray(obj)) {
    for (const item of obj) extractPhones(item, found);
    return found;
  }
  if (typeof obj === "object") {
    for (const [k, v] of Object.entries(obj as Record<string, unknown>)) {
      if (/phone/i.test(k) && typeof v === "string" && v.trim()) found.push(v);
      extractPhones(v, found);
    }
  }
  return found;
}

async function main() {
  const doSubmit = Deno.args.includes("--submit");
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

  const report: Record<string, unknown> = { phase: "inspect" };

  // Version state
  const version = await ascJson(token, `/appStoreVersions/${VERSION_ID}`);
  report.version = {
    state: version.data?.attributes?.appStoreState,
    releaseType: version.data?.attributes?.releaseType,
    versionString: version.data?.attributes?.versionString,
  };

  // Existing review submissions
  const subs = await ascProbe(token, `/apps/${APP_ID}/reviewSubmissions?limit=10`);
  report.existingReviewSubmissions = subs;

  // Subscriptions state (modern API)
  const subMonthly = await ascProbe(token, `/subscriptions/${SUB_MONTHLY}`);
  const subYearly = await ascProbe(token, `/subscriptions/${SUB_YEARLY}`);
  report.subscriptions = { monthly: subMonthly, yearly: subYearly };

  // Privacy API probes
  const privacyPaths = [
    `/apps/${APP_ID}/appDataUsages`,
    `/apps/${APP_ID}/dataUsages`,
    `/appDataUsages`,
    `/appDataUsageCategories`,
    `/appPrivacyPolicyTypes`,
    `/apps/${APP_ID}/appPrivacyDetails`,
    `/appPrivacyDetails?filter[app]=${APP_ID}`,
    `/apps/${APP_ID}/appPrivacyDeclaration`,
    `/appPrivacyDeclarations?filter[app]=${APP_ID}`,
  ];
  report.privacyProbes = [];
  for (const p of privacyPaths) {
    report.privacyProbes.push(await ascProbe(token, p));
  }

  // Account / team phone search
  const accountPaths = [
    `/users`,
    `/users?limit=50`,
    `/actors`,
    `/userInvitations`,
    `/apps/${APP_ID}`,
    `/appStoreVersions/${VERSION_ID}/appStoreReviewDetail`,
    `/appStoreReviewDetails/${REVIEW_DETAIL_ID}`,
  ];
  report.phoneSearchErrors = [];
  const phones = new Set<string>();
  for (const p of accountPaths) {
    try {
      const json = await ascJson(token, p);
      for (const ph of extractPhones(json)) phones.add(ph);
    } catch (e) {
      report[`phoneSearchError_${p}`] = String(e).slice(0, 500);
    }
  }
  report.phonesFound = [...phones];

  if (!doSubmit) {
    console.log(JSON.stringify(report, null, 2));
    return;
  }

  const state = version.data?.attributes?.appStoreState as string;
  if (state === "PENDING_DEVELOPER_RELEASE") {
    report.submit = { action: "RELEASE", note: "Use release endpoint — version approved" };
    console.log(JSON.stringify(report, null, 2));
    return;
  }
  if (state === "WAITING_FOR_REVIEW" || state === "IN_REVIEW") {
    report.submit = { action: "ALREADY_SUBMITTED", state };
    console.log(JSON.stringify(report, null, 2));
    return;
  }

  const submitLog: Record<string, unknown> = {};

  // Step 1: create review submission
  let submissionId: string;
  try {
    const created = await ascJson(token, `/reviewSubmissions`, {
      method: "POST",
      body: JSON.stringify({
        data: {
          type: "reviewSubmissions",
          attributes: { platform: "IOS" },
          relationships: {
            app: { data: { type: "apps", id: APP_ID } },
          },
        },
      }),
    });
    submissionId = created.data.id;
    submitLog.createSubmission = { ok: true, id: submissionId };
  } catch (e) {
    submitLog.createSubmission = { ok: false, error: String(e) };
    report.submit = submitLog;
    console.log(JSON.stringify(report, null, 2));
    return;
  }

  // Step 2a: add app store version
  try {
    const item = await ascJson(token, `/reviewSubmissionItems`, {
      method: "POST",
      body: JSON.stringify({
        data: {
          type: "reviewSubmissionItems",
          relationships: {
            reviewSubmission: { data: { type: "reviewSubmissions", id: submissionId } },
            appStoreVersion: { data: { type: "appStoreVersions", id: VERSION_ID } },
          },
        },
      }),
    });
    submitLog.addVersion = { ok: true, id: item.data?.id };
  } catch (e) {
    submitLog.addVersion = { ok: false, error: String(e) };
  }

  // Step 2b: add subscriptions
  for (const [label, subId] of [["monthly", SUB_MONTHLY], ["yearly", SUB_YEARLY]] as const) {
    try {
      const item = await ascJson(token, `/reviewSubmissionItems`, {
        method: "POST",
        body: JSON.stringify({
          data: {
            type: "reviewSubmissionItems",
            relationships: {
              reviewSubmission: { data: { type: "reviewSubmissions", id: submissionId } },
              subscription: { data: { type: "subscriptions", id: subId } },
            },
          },
        }),
      });
      submitLog[`addSub_${label}`] = { ok: true, id: item.data?.id };
    } catch (e) {
      submitLog[`addSub_${label}`] = { ok: false, error: String(e) };
    }
  }

  // Step 3: submit
  try {
    const submitted = await ascJson(token, `/reviewSubmissions/${submissionId}`, {
      method: "PATCH",
      body: JSON.stringify({
        data: {
          type: "reviewSubmissions",
          id: submissionId,
          attributes: { submitted: true },
        },
      }),
    });
    submitLog.finalSubmit = {
      ok: true,
      state: submitted.data?.attributes?.state,
    };
  } catch (e) {
    submitLog.finalSubmit = { ok: false, error: String(e) };
  }

  // Re-fetch version state
  try {
    const v2 = await ascJson(token, `/appStoreVersions/${VERSION_ID}`);
    submitLog.finalVersionState = v2.data?.attributes?.appStoreState;
  } catch (e) {
    submitLog.finalVersionState = `error: ${e}`;
  }

  report.submit = submitLog;
  console.log(JSON.stringify(report, null, 2));
}

await main();
