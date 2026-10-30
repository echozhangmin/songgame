#!/usr/bin/env bash
# 一键发布：构建 → 提交 → 推送
# 用法：./deploy.sh "这次改了什么"
set -euo pipefail
cd "$(dirname "$0")"

MSG="${1:-更新}"

echo "== 1/3 构建 =="
python3 build.py

echo "== 2/3 提交 =="
git add -A
if git diff --cached --quiet; then
  echo "没有改动，跳过提交"
else
  git -c core.quotepath=false commit -m "$MSG"
fi

echo "== 3/3 推送 =="
git push origin HEAD 2>&1 | grep -v "known_hosts\|hostfile_replace_entries" || true

echo "完成：$(git log -1 --format='%h %s')"
git status -sb | head -1
