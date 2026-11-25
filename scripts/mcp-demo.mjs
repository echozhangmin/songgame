/**
 * @playwright/mcp 实跑演示（Loop 3）。
 * 不用打开 OpenCode：直接用 MCP 协议连上 Playwright MCP server，
 * 让它开浏览器 → 导航线上页 → 读 console → 截桌面/手机两张图。
 *
 * 用法：npm run check:mcp
 *      URL=http://127.0.0.1:8765/index.html npm run check:mcp
 */
import { spawn } from 'node:child_process';
import fs from 'node:fs';

const URL = process.env.URL || 'https://songgame.pages.dev/';
const OUT = 'artifacts';
fs.mkdirSync(OUT, { recursive: true });

const server = spawn('node_modules/.bin/playwright-mcp',
  ['--browser', 'chrome', '--headless', '--isolated', '--console-level', 'error'],
  { stdio: ['pipe', 'pipe', 'pipe'] });

let buffer = '';
const pending = new Map();
let nextId = 0;

server.stdout.on('data', chunk => {
  buffer += chunk.toString();
  let idx;
  while ((idx = buffer.indexOf('\n')) >= 0) {
    const line = buffer.slice(0, idx).trim();
    buffer = buffer.slice(idx + 1);
    if (!line) continue;
    try {
      const msg = JSON.parse(line);
      if (msg.id && pending.has(msg.id)) {
        pending.get(msg.id)(msg);
        pending.delete(msg.id);
      }
    } catch {
      // MCP server 偶尔会打非 JSON 日志，忽略
    }
  }
});
server.stderr.on('data', () => {}); // 保持管道不阻塞

function rpc(method, params) {
  return new Promise((resolve, reject) => {
    const id = ++nextId;
    pending.set(id, resolve);
    server.stdin.write(JSON.stringify({ jsonrpc: '2.0', id, method, params }) + '\n');
    setTimeout(() => {
      if (pending.has(id)) { pending.delete(id); reject(new Error(`timeout: ${method}`)); }
    }, 60_000);
  });
}

async function callTool(name, args = {}) {
  const res = await rpc('tools/call', { name, arguments: args });
  if (res.error) throw new Error(`${name}: ${JSON.stringify(res.error)}`);
  return res.result;
}

const init = await rpc('initialize', {
  protocolVersion: '2025-06-18',
  capabilities: {},
  clientInfo: { name: 'songgame-demo', version: '1.0' },
});
server.stdin.write(JSON.stringify({ jsonrpc: '2.0', method: 'notifications/initialized' }) + '\n');
console.log(`MCP server: ${init.result.serverInfo.name} ${init.result.serverInfo.version}`);

const nav = await callTool('browser_navigate', { url: URL });
console.log('navigate:', nav.content?.[0]?.text?.split('\n')[0] || 'ok');

// 桌面截图
const shot1 = await callTool('browser_take_screenshot', {
  scale: 'css', type: 'png', filename: `${OUT}/mcp-desktop.png`,
});
console.log('screenshot:', shot1.content?.[0]?.text || `${OUT}/mcp-desktop.png`);

// 缩到手机宽度再截一张
await callTool('browser_resize', { width: 390, height: 844 });
const shot2 = await callTool('browser_take_screenshot', {
  scale: 'css', type: 'png', filename: `${OUT}/mcp-mobile.png`,
});
console.log('screenshot:', shot2.content?.[0]?.text || `${OUT}/mcp-mobile.png`);

// console 错误
const consoleRes = await callTool('browser_console_messages', { level: 'error', all: true });
const consoleText = consoleRes.content?.map(c => c.text).join('\n') || '';
const errorCountMatch = consoleText.match(/Errors:\s*(\d+)/);
const errorCount = errorCountMatch
  ? Number(errorCountMatch[1])
  : consoleText.split('\n').filter(l => /\[error\]/i.test(l)).length;
console.log('\n—— console (level=error) ——');
console.log(consoleText.trim() || '(空)');

await callTool('browser_close');
server.kill();

if (errorCount > 0) {
  console.error(`\n✘ console 里有 ${errorCount} 条 error`);
  process.exit(1);
}
console.log('\n✔ MCP 浏览器检查完成：0 console error；截图 artifacts/mcp-desktop.png、mcp-mobile.png');
