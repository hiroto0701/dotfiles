#!/usr/bin/env node
// Usage: node check.mjs <c4.html> [out-dir]
// Renders every svg.c4 (except .legend) in the fixed light theme, writes screenshots,
// and reports layout and notation problems. Exit code 1 when any problem is found.
import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { tmpdir } from "node:os";
import { basename, join, resolve } from "node:path";

const MAX_ELEMENTS = 15;
const CHROME = process.env.CHROME ?? [
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
  "/Applications/Chromium.app/Contents/MacOS/Chromium",
  "/usr/bin/google-chrome",
  "/usr/bin/chromium",
].find(existsSync);

const [, , input, outArg] = process.argv;
if (!input) { console.error("usage: node check.mjs <c4.html> [out-dir]"); process.exit(2); }
if (!CHROME) { console.error("Chrome not found. Set CHROME=/path/to/chrome"); process.exit(2); }

const src = resolve(input);
const html = readFileSync(src, "utf8");
const out = resolve(outArg ?? join(tmpdir(), `c4-check-${basename(src, ".html")}`));
mkdirSync(out, { recursive: true });

const problems = [];
const warnings = [];
const page = (msg) => problems.push(`page: ${msg}`);

const main = html.match(/<main\b[^>]*>/)?.[0] ?? "";
const mode = main.match(/data-c4-mode="([^"]*)"/)?.[1];
const commit = main.match(/data-c4-commit="([^"]*)"/)?.[1];
if (!["as-is", "to-be"].includes(mode)) page(`<main data-c4-mode> must be "as-is" or "to-be" (got ${mode ?? "nothing"})`);
if (commit !== "none" && (!/^[0-9a-f]{7,40}$/.test(commit ?? "") || /^0+$/.test(commit))) page(`<main data-c4-commit> must be the real base commit hash, or "none" outside git (got ${commit ?? "nothing"})`);
if (/YYYY-MM-DD|システム名/.test(html)) page("template placeholders (YYYY-MM-DD / システム名) are still present");
if (!/<html\b[^>]*data-theme="light"/.test(html)) page('<html> must have data-theme="light" (the page is light-only)');
if (/prefers-color-scheme:\s*dark|data-theme="dark"|color-scheme:\s*dark/.test(html)) page("dark theme styles found: the page is light-only, remove them");

const styles = (html.match(/<style\b[\s\S]*?<\/style>/g) ?? []).join("\n");
const defs = html.match(/<svg\b[^>]*class="c4-defs"[\s\S]*?<\/svg>/)?.[0] ?? "";
if (!defs) page('arrow marker block <svg class="c4-defs"> is missing');
const svgs = (html.match(/<svg\b[^>]*class="c4[" ][\s\S]*?<\/svg>/g) ?? []).filter((s) => !/class="c4 legend"/.test(s));
if (svgs.length === 0) page('no <svg class="c4"> diagrams found');

// Runs inside Chrome. Uses screen rects so transforms on groups do not matter.
const probe = `
const svg = document.querySelector("svg.c4");
const name = svg.getAttribute("aria-label") || "(no aria-label)";
const r = (el) => el.getBoundingClientRect();
const overlap = (a, b, pad = 0) => a.left < b.right - pad && b.left < a.right - pad && a.top < b.bottom - pad && b.top < a.bottom - pad;
const inside = (a, b, pad) => a.left >= b.left + pad && a.right <= b.right - pad && a.top >= b.top && a.bottom <= b.bottom;
const txt = (t) => JSON.stringify(t.textContent.trim().slice(0, 30));
const issues = [];
const box = r(svg);
const els = [...svg.querySelectorAll("g.el")];
if (els.length > ${MAX_ELEMENTS}) issues.push(els.length + " elements (max ${MAX_ELEMENTS}): split this view");
const shapes = [];
for (const g of els) {
  const shape = g.querySelector(".shape");
  if (!shape) { issues.push("g.el without .shape: " + txt(g)); continue; }
  const sb = r(shape);
  shapes.push({ g, sb });
  for (const t of g.querySelectorAll("text")) {
    if (!inside(r(t), sb, 4)) issues.push("text overflows its box: " + txt(t));
  }
}
for (let i = 0; i < shapes.length; i++) for (let j = i + 1; j < shapes.length; j++) {
  if (overlap(shapes[i].sb, shapes[j].sb)) issues.push("boxes overlap: " + txt(shapes[i].g.querySelector(".name") || shapes[i].g) + " / " + txt(shapes[j].g.querySelector(".name") || shapes[j].g));
}
const labels = [...svg.querySelectorAll("g.rel text, g.boundary text")];
for (const g of svg.querySelectorAll("g.rel")) {
  if (!g.querySelector("text")) issues.push("relationship without a label (every arrow needs a verb)");
}
for (let i = 0; i < labels.length; i++) {
  const a = r(labels[i]);
  if (!inside(a, box, 0)) issues.push("label outside the svg: " + txt(labels[i]));
  for (const s of shapes) if (overlap(a, s.sb, 1)) issues.push("label sits on a box: " + txt(labels[i]) + " on " + txt(s.g.querySelector(".name") || s.g));
  for (let j = i + 1; j < labels.length; j++) {
    if (labels[i].parentNode !== labels[j].parentNode && overlap(a, r(labels[j]), 1)) issues.push("labels overlap: " + txt(labels[i]) + " / " + txt(labels[j]));
  }
}
// Segments of each arrow, in screen coordinates. Supports M L H V Z (absolute and relative).
const warnings = [];
const segsOf = (path) => {
  const toks = path.getAttribute("d").match(/[MLHVZmlhvz]|-?[\\d.]+/g) || [];
  const segs = []; let x = 0, y = 0, sx = 0, sy = 0, cmd = "M", i = 0;
  const num = () => parseFloat(toks[i++]);
  while (i < toks.length) {
    if (/[A-Za-z]/.test(toks[i])) cmd = toks[i++];
    const rel = cmd === cmd.toLowerCase(), c = cmd.toUpperCase();
    let nx = x, ny = y;
    if (c === "M") { nx = num() + (rel ? x : 0); ny = num() + (rel ? y : 0); x = sx = nx; y = sy = ny; cmd = rel ? "l" : "L"; continue; }
    if (c === "L") { nx = num() + (rel ? x : 0); ny = num() + (rel ? y : 0); }
    else if (c === "H") nx = num() + (rel ? x : 0);
    else if (c === "V") ny = num() + (rel ? y : 0);
    else if (c === "Z") { nx = sx; ny = sy; }
    else return null;
    segs.push([x + box.left, y + box.top, nx + box.left, ny + box.top]); x = nx; y = ny;
  }
  return segs;
};
const cross = (p, q) => {
  const d = (a, b, c) => (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0]);
  const a = [p[0], p[1]], b = [p[2], p[3]], c = [q[0], q[1]], e = [q[2], q[3]];
  const d1 = d(c, e, a), d2 = d(c, e, b), d3 = d(a, b, c), d4 = d(a, b, e);
  return ((d1 > 1 && d2 < -1) || (d1 < -1 && d2 > 1)) && ((d3 > 1 && d4 < -1) || (d3 < -1 && d4 > 1));
};
const hitsRect = (s, rc) => {
  const k = { left: rc.left + 2, right: rc.right - 2, top: rc.top + 2, bottom: rc.bottom - 2 };
  const edges = [[k.left, k.top, k.right, k.top], [k.right, k.top, k.right, k.bottom], [k.right, k.bottom, k.left, k.bottom], [k.left, k.bottom, k.left, k.top]];
  const inPt = (x, y) => x > k.left && x < k.right && y > k.top && y < k.bottom;
  return inPt(s[0], s[1]) || inPt(s[2], s[3]) || edges.some((e) => cross(s, e));
};
const rels = [...svg.querySelectorAll("g.rel")].map((g) => {
  const line = g.querySelector(".line");
  return { g, segs: line ? segsOf(line) : [], name: txt(g.querySelector("text") || g) };
});
for (const r1 of rels) if (r1.segs === null) warnings.push("arrow path uses curves; crossing checks skipped: " + r1.name);
for (let i = 0; i < rels.length; i++) for (let j = i + 1; j < rels.length; j++) {
  if (!rels[i].segs || !rels[j].segs) continue;
  if (rels[i].segs.some((p) => rels[j].segs.some((q) => cross(p, q)))) warnings.push("arrows cross: " + rels[i].name + " / " + rels[j].name);
}
for (const r1 of rels) for (const r2 of rels) {
  if (r1 === r2 || !r1.segs) continue;
  for (const t of r2.g.querySelectorAll("text")) if (r1.segs.some((s) => hitsRect(s, r(t)))) warnings.push("arrow runs through another label: " + r1.name + " through " + txt(t));
}
for (const b of svg.querySelectorAll("g.boundary rect")) {
  const k = r(b);
  const edges = [[k.left, k.top, k.right, k.top], [k.right, k.top, k.right, k.bottom], [k.right, k.bottom, k.left, k.bottom], [k.left, k.bottom, k.left, k.top]];
  for (const t of svg.querySelectorAll("g.rel text")) if (edges.some((e) => hitsRect(e, r(t)))) warnings.push("boundary line runs through a label: " + txt(t));
}
document.body.setAttribute("data-result", JSON.stringify({ name, issues, warnings }));
`;

const run = (args) => execFileSync(CHROME, ["--headless=new", "--disable-gpu", "--hide-scrollbars", ...args], { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] });

svgs.forEach((svg, i) => {
  const vb = svg.match(/viewBox="[\d.\-]+\s+[\d.\-]+\s+([\d.]+)\s+([\d.]+)"/);
  if (!vb) { problems.push(`svg #${i + 1}: missing numeric viewBox`); return; }
  const [w, h] = [Math.ceil(+vb[1]), Math.ceil(+vb[2])];
  const file = join(out, `svg${i + 1}.html`);
  writeFileSync(file, `<!doctype html><html data-theme="light"><head><meta charset="utf-8">${styles}
<style>body{margin:0;padding:8px;background:var(--surface)} svg.c4{width:${w}px!important;height:${h}px!important;max-width:none!important}</style></head>
<body>${defs}${svg}<script>${probe}</script></body></html>`);
  run([`--window-size=${w + 16},${h + 16}`, `--screenshot=${join(out, `svg${i + 1}.png`)}`, `file://${file}`]);
  const dom = run(["--virtual-time-budget=3000", "--dump-dom", `file://${file}`]);
  const raw = dom.match(/data-result="([^"]*)"/)?.[1];
  if (!raw) { problems.push(`svg #${i + 1}: probe did not run`); return; }
  const { name, issues, warnings: warns } = JSON.parse(raw.replace(/&quot;/g, '"').replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">"));
  for (const m of new Set(issues)) problems.push(`svg #${i + 1} ${name}: ${m}`);
  for (const m of new Set(warns)) warnings.push(`svg #${i + 1} ${name}: ${m}`);
});

console.log(`screenshots: ${out}`);
if (warnings.length) {
  console.log(`${warnings.length} warning(s) (do not fail the check; explain any you keep):`);
  for (const w of warnings) console.log(`- ${w}`);
}
if (problems.length) {
  console.log(`${problems.length} problem(s):`);
  for (const p of problems) console.log(`- ${p}`);
  process.exit(1);
}
console.log(`OK: ${svgs.length} diagram(s), no problems`);
