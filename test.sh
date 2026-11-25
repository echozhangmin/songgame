#!/usr/bin/env bash
# 一条命令跑完全部检查：构建 → 题诗 → 座谈 → 数据守卫 → 全流程（3 个种子）→ 平衡模拟 →（若有依赖）浏览器 E2E
# 用法：./test.sh          只跑本地无头测试
#       ./test.sh --e2e    额外跑 Playwright（需先 npm install）
set -uo pipefail
cd "$(dirname "$0")"

fail=0
run() {
  local name="$1"; shift
  local out ec
  out=$("$@" 2>&1); ec=$?
  echo ""
  echo "===== $name ====="
  printf '%s\n' "$out" | tail -40
  if [ "$ec" -ne 0 ] || printf '%s\n' "$out" | grep -q '^FAIL'; then
    echo ">>> 失败：${name}（exit=${ec}）"
    fail=$((fail + 1))
  fi
}

echo "===== 构建 ====="
python3 build.py || exit 1

if [ -x .venv/bin/pytest ]; then
  run "Python 数据与史料边界（pytest）" .venv/bin/pytest -q
else
  echo ""
  echo "（未建 .venv：python3 -m venv .venv && .venv/bin/pip install -r requirements-dev.txt）"
fi

run "题诗判定（8 例）"            osascript -l JavaScript poem_test.js
run "大儒座谈（11 例）"           osascript -l JavaScript dialogue_test.js
run "数据与规则守卫"              osascript -l JavaScript data_test.js
for seed in 1 2 3; do
  export SEED="$seed"
  run "全流程审计（seed=${seed}）" osascript -l JavaScript walkthrough_test.js
  unset SEED
done

echo ""
echo "===== 平衡模拟（180 局，只报告不判失败） ====="
if osascript -l JavaScript sim.js > /tmp/songgame-sim.json 2>/dev/null; then
  python3 - <<'PY'
import json
d = json.load(open('/tmp/songgame-sim.json'))
print('局面：', '，'.join(f'{k} {v}' for k, v in sorted(d['ranks'].items(), key=lambda x: -x[1])))
print('死亡：', d['deaths'], '/', d['runs'])
PY
else
  echo "（sim 未跑通，跳过）"
fi

if [ "${1:-}" = "--e2e" ]; then
  if [ -x node_modules/.bin/playwright ]; then
    echo ""
    echo "===== 浏览器 E2E ====="
    node_modules/.bin/playwright test || fail=$((fail + 1))
  else
    echo ""
    echo "（未安装依赖：先运行 npm install，或 npx playwright install chrome）"
    fail=$((fail + 1))
  fi
fi

echo ""
if [ "$fail" -eq 0 ]; then
  echo "ALL GREEN ✔"
else
  echo "SOME CHECKS FAILED ✘（$fail 组）"
fi
exit "$fail"
