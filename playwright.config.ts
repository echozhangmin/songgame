import { defineConfig, devices } from '@playwright/test';

/**
 * 浏览器 E2E：默认用系统 Chrome（channel: 'chrome'），不必下载 Chromium。
 * 线上冒烟：PLAYWRIGHT_BASE_URL=https://echozhangmin.github.io/songgame npx playwright test
 */
const BASE = process.env.PLAYWRIGHT_BASE_URL;

export default defineConfig({
  testDir: './tests',
  timeout: 45_000,
  expect: { timeout: 8_000 },
  fullyParallel: false,
  reporter: [['list']],
  use: {
    baseURL: BASE || 'http://127.0.0.1:8765',
    channel: 'chrome',
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
  },
  projects: [
    { name: 'desktop', use: { ...devices['Desktop Chrome'], channel: 'chrome', viewport: { width: 1280, height: 800 } } },
    { name: 'mobile', use: { browserName: 'chromium', channel: 'chrome', isMobile: true, hasTouch: true, viewport: { width: 390, height: 844 }, deviceScaleFactor: 3 } },
  ],
  webServer: BASE ? undefined : {
    command: process.env.DIST ? 'python3 -m http.server 8765 --directory dist' : 'python3 -m http.server 8765',
    port: 8765,
    reuseExistingServer: true,
    timeout: 20_000,
  },
});
