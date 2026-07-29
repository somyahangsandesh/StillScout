#!/usr/bin/env -S deno run --allow-read --allow-write --allow-run --allow-env --allow-ffi --allow-net
/**
 * Render App Store screenshots from docs/asc_assets/screenshot_studio.html
 * at exact 1290×2796 px (iPhone 6.7").
 *
 * Usage:
 *   deno run --allow-read --allow-write --allow-run --allow-env --allow-ffi --allow-net tool/render_asc_screenshots.ts
 */
import puppeteer from "npm:puppeteer-core@24";
import { dirname, join, fromFileUrl } from "jsr:@std/path@1";

const ROOT = join(dirname(fromFileUrl(import.meta.url)), "..");
const STUDIO = join(ROOT, "docs/asc_assets/screenshot_studio.html");
const OUT_DIR = join(ROOT, "docs/asc_assets/screenshots_67");
const CHROME =
  Deno.env.get("CHROME_PATH") ??
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";

const SHOTS = [
  { id: "shot-01", file: "01_hero.png" },
  { id: "shot-02", file: "02_ai_scouting.png" },
  { id: "shot-03", file: "03_smart_selection.png" },
  { id: "shot-04", file: "04_stunning_results.png" },
  { id: "shot-05", file: "05_export.png" },
];

const W = 1290;
const H = 2796;

async function main() {
  await Deno.mkdir(OUT_DIR, { recursive: true });

  const browser = await puppeteer.launch({
    executablePath: CHROME,
    headless: true,
    args: ["--font-render-hinting=none", "--disable-dev-shm-usage"],
  });

  const page = await browser.newPage();
  await page.setViewport({ width: W, height: H, deviceScaleFactor: 1 });
  await page.goto(`file://${STUDIO}`, { waitUntil: "networkidle0", timeout: 60_000 });
  await page.evaluate(() => document.fonts.ready);

  const results: Array<{ file: string; bytes: number }> = [];

  for (const shot of SHOTS) {
    const el = await page.$(`#${shot.id}`);
    if (!el) throw new Error(`Missing artboard #${shot.id}`);
    const outPath = join(OUT_DIR, shot.file);
    await el.screenshot({ path: outPath, type: "png" });
    const stat = await Deno.stat(outPath);
    results.push({ file: shot.file, bytes: stat.size });
    console.log(`✓ ${shot.file} (${stat.size} bytes)`);
  }

  await browser.close();
  console.log(JSON.stringify({ outDir: OUT_DIR, shots: results }, null, 2));
}

await main();
