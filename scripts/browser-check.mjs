/**
 * 自动浏览器检查（Loop 3 的现场演示脚本）
 * 用法：npm run check:browser
 *      URL=http://127.0.0.1:8765/index.html npm run check:browser
 * 做四件事：开桌面+手机两个视口 → 收集 console error / 4xx → 各截一张图 → 非零退出如有错
 */
import { chromium } from '@playwright/test';
import fs from 'node:fs';

const URL = process.env.URL || 'https://songgame.pages.dev/';
const OUT = 'artifacts';
fs.mkdirSync(OUT, { recursive: true });

const browser = await chromium.launch({ channel: 'chrome' });
const report = { url: URL, viewports: [], errors: [], bad: [] };

for (const [name, width, height, mobile] of [['desktop', 1280, 800, false], ['mobile', 390, 844, true]]) {
  const ctx = await browser.newContext({ viewport: { width, height }, isMobile: mobile, hasTouch: mobile, deviceScaleFactor: 2 });
  const page = await ctx.newPage();
  const errs = [], bad = [];

  page.on('console', m => { if (m.type() === 'error') errs.push(`[${name}] ${m.text()}`); });
  page.on('pageerror', e => errs.push(`[${name}] PAGEERROR ${e.message}`));
  page.on('response', r => { if (r.status() >= 400) bad.push(`[${name}] ${r.status()} ${r.url()}`); });

  const t0 = Date.now();
  await page.goto(URL, { waitUntil: 'load', timeout: 60000 });
  const loadMs = Date.now() - t0;

  // 走进第一幕，截一张"真在玩"的图
  if (await page.locator('[data-act="newgame"]').count()) {
    await page.click('[data-act="newgame"]');
    await page.click('[data-act="closeHelp"]');
    await page.waitForTimeout(250);
  }
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth - innerWidth);
  await page.evaluate(() => window.scrollTo(0, 0));
  await page.waitForTimeout(150);
  await page.screenshot({ path: `${OUT}/live-${name}.png`, fullPage: false });

  report.viewports.push({ name, loadMs, overflow, errors: errs.length, bad: bad.length });
  report.errors.push(...errs);
  report.bad.push(...bad);
  await ctx.close();
}
await browser.close();

console.log(JSON.stringify(report, null, 2));
if (report.errors.length || report.bad.length) {
  console.error(`\n✘ ${report.errors.length} 个 console error，${report.bad.length} 个 4xx/5xx`);
  process.exit(1);
}
console.log('\n✔ 0 console error，0 断链；截图在 artifacts/');
