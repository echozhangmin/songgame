#!/usr/bin/env bash
# 课前自检：环境、依赖、MCP、pytest、线上 URL。只检查，不改文件。
# 用法：./preflight.sh
set -uo pipefail
cd "$(dirname "$0")"

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

fail=0
ok()   { printf "  ✓ %s\n" "$1"; }
bad()  { printf "  ✗ %s\n" "$1"; fail=$((fail + 1)); }

echo "== 1. Node / npm =="
if command -v node >/dev/null 2>&1; then ok "node $(node -v)  npm $(npm -v)"; else bad "node 不在 PATH（新开终端或 source ~/.zshrc）"; fi

echo "== 2. Playwright =="
if [ -x node_modules/.bin/playwright ]; then ok "playwright $(node_modules/.bin/playwright --version 2>/dev/null)"; else bad "缺 node_modules（npm install）"; fi
if [ -d "/Applications/Google Chrome.app" ]; then ok "Google Chrome 已安装"; else bad "没找到 Google Chrome（E2E 用 channel=chrome）"; fi

echo "== 3. Playwright MCP =="
if [ -x node_modules/.bin/playwright-mcp ]; then ok "playwright-mcp $(node_modules/.bin/playwright-mcp --version 2>/dev/null)"; else bad "缺 @playwright/mcp（npm install）"; fi
python3 - <<'PY' && ok "opencode.json 配了 playwright MCP" || bad "opencode.json 缺 playwright MCP"
import json, sys
cfg = json.load(open('opencode.json'))
sys.exit(0 if 'playwright' in cfg.get('mcp', {}) else 1)
PY

echo "== 4. pytest =="
if [ -x .venv/bin/pytest ]; then ok "pytest $(.venv/bin/pytest --version 2>/dev/null | head -1)"; else bad "缺 .venv（python3 -m venv .venv && .venv/bin/pip install -r requirements-dev.txt）"; fi

echo "== 5. 线上 URL =="
code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 https://songgame.pages.dev/ 2>/dev/null || echo 000)
[ "$code" = "200" ] && ok "https://songgame.pages.dev/ → 200" || bad "线上返回 $code（检查网络或 Cloudflare 部署）"

echo "== 6. 关键文件 =="
for f in docs/plan.md docs/architecture-explainer.html docs/evidence.md docs/user-feedback.md docs/demo-7min.md tests/test_data.py tests/e2e.spec.ts 北宋赶考记.html index.html; do
  [ -s "$f" ] && ok "$f" || bad "缺 $f"
done

echo
if [ "$fail" -eq 0 ]; then
  echo "READY ✔  下一步：./test.sh --e2e && npm run check:mcp"
else
  echo "有 $fail 项未就绪 ✘（按上面的提示补）"
fi
exit "$fail"
