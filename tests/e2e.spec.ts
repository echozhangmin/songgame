import { test, expect, type Page } from '@playwright/test';

/**
 * 浏览器反馈闭环（对应 Week 10 第 3 项）。
 * 守三件事：0 控制台报错 / 0 断链、关键路径能走通、手机版面不挤。
 * 兼容本地与线上：PLAYWRIGHT_BASE_URL=https://echozhangmin.github.io/songgame npx playwright test
 */

type Guard = { errors: string[]; bad: string[] };

function guard(page: Page): Guard {
  const g: Guard = { errors: [], bad: [] };
  page.on('console', m => { if (m.type() === 'error') g.errors.push(m.text()); });
  page.on('pageerror', e => g.errors.push('PAGEERROR ' + e.message));
  page.on('response', r => { if (r.status() >= 400) g.bad.push(`${r.status()} ${r.url()}`); });
  return g;
}

async function openGame(page: Page) {
  await page.goto('/index.html', { waitUntil: 'load' });
  await expect(page).toHaveTitle(/北宋赶考记/);
  await expect(page.locator('[data-act="newgame"]')).toBeVisible();
}

async function startNew(page: Page) {
  await openGame(page);
  await page.locator('[data-act="newgame"]').click();
  await expect(page.locator('#overlay')).toHaveCount(1);
  await page.locator('[data-act="closeHelp"]').click();
  await expect(page.locator('#overlay')).toHaveCount(0);
}

test('标题页 → 开局 → 凡例 → 第一幕：0 报错、0 断链、无横向溢出', async ({ page }) => {
  const g = guard(page);
  await openGame(page);
  await page.screenshot({ path: 'test-results/title.png', fullPage: false }).catch(() => {});

  // 站点元信息：分享给朋友时不至于是一条裸链接
  await expect(page.locator('link[rel="icon"]')).toHaveCount(1);
  await expect(page.locator('meta[name="description"]')).toHaveCount(1);
  await expect(page.locator('meta[property="og:image"]')).toHaveCount(1);

  await page.locator('[data-act="newgame"]').click();
  await expect(page.locator('#overlay')).toContainText('凡例');
  await page.locator('[data-act="closeHelp"]').click();
  await expect(page.locator('#overlay')).toHaveCount(0);

  await expect(page.locator('.act')).toHaveCount(5);
  await expect(page.locator('.meta-date')).toContainText('第 1 日');

  const overflow = await page.evaluate(() => document.documentElement.scrollWidth - window.innerWidth);
  expect(overflow, '不应出现横向滚动').toBe(0);
  expect(g.bad, '不应有 4xx/5xx 请求').toEqual([]);
  expect(g.errors, '不应有控制台报错').toEqual([]);
});

test('温书答题 → 反馈 → 刷新续玩：进度不丢', async ({ page }) => {
  const g = guard(page);
  await startNew(page);

  await page.locator('[data-act="study"]').click();
  await expect(page.locator('#overlay .opt').first()).toBeVisible();
  await page.locator('#overlay .opt:not(:disabled)').first().click();
  await expect(page.locator('#overlay .fb')).toBeVisible();
  await page.locator('[data-act="cont"]').click();
  await expect(page.locator('#overlay')).toHaveCount(0);

  await page.reload({ waitUntil: 'load' });
  const cont = page.locator('[data-act="continue"]');
  await expect(cont).toBeVisible();
  await cont.click();
  await expect(page.locator('.meta-date')).toContainText('第 1 日');
  await expect(page.locator('.act')).toHaveCount(5);

  expect(g.bad).toEqual([]);
  expect(g.errors).toEqual([]);
});

test('词条索引可开、Esc 可关（键盘可达）', async ({ page }) => {
  const g = guard(page);
  await startNew(page);

  await page.locator('[data-act="glossIndex"]').click();
  const overlay = page.locator('#overlay');
  await expect(overlay).toBeVisible();
  await expect(overlay).toHaveAttribute('role', 'dialog');
  await expect(overlay).toHaveAttribute('aria-modal', 'true');
  await expect(overlay).toContainText('词条索引');

  await page.keyboard.press('Escape');
  await expect(overlay).toHaveCount(0);

  // 点开一条词条，应显示据/推断/设档位
  await page.locator('[data-act="glossIndex"]').click();
  await overlay.locator('[data-term]').first().click();
  await expect(overlay.locator('.qtag')).toContainText(/原文可据|据书转述|游戏设定/);

  // Esc 逐层退出：词条详情 → 词条索引 → 游戏
  await page.keyboard.press('Escape');
  await expect(overlay).toContainText('词条索引');
  await page.keyboard.press('Escape');
  await expect(page.locator('#overlay')).toHaveCount(0);

  expect(g.errors).toEqual([]);
});

test('触控与版面：手机页头不挤、按钮够大、字号可读', async ({ page, isMobile, viewport }) => {
  test.skip(!isMobile, '只在移动端项目跑');
  const g = guard(page);
  await startNew(page);

  const head = await page.locator('.head').boundingBox();
  expect(head!.height, '页头不应高过 230px').toBeLessThan(230);

  const titleSize = await page.locator('.head h1').evaluate(el => parseFloat(getComputedStyle(el).fontSize));
  expect(titleSize, '标题字号应 ≤ 30px').toBeLessThanOrEqual(30);

  const buttons = await page.locator('.meta button').evaluateAll(els => els.map(el => el.getBoundingClientRect().height));
  expect(Math.min(...buttons), '顶栏按钮高度应 ≥ 36px').toBeGreaterThanOrEqual(36);

  // 页头各元素不重叠
  const boxes = await page.locator('.head > *').evaluateAll(els =>
    els.filter(el => getComputedStyle(el).display !== 'none')
       .map(el => { const r = el.getBoundingClientRect(); return { x: r.x, y: r.y, w: r.width, h: r.height }; }));
  for (let i = 0; i < boxes.length; i++) {
    for (let j = i + 1; j < boxes.length; j++) {
      const a = boxes[i], b = boxes[j];
      const overlap = a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h;
      expect(overlap, `页头元素 ${i} 与 ${j} 重叠`).toBeFalsy();
    }
  }

  const overflow = await page.evaluate(() => document.documentElement.scrollWidth - window.innerWidth);
  expect(overflow).toBe(0);
  expect(viewport!.width).toBeLessThanOrEqual(430);
  expect(await page.locator('.act').count()).toBeGreaterThan(0);
  expect(g.errors).toEqual([]);
});
