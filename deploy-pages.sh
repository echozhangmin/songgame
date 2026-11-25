#!/usr/bin/env bash
# 发布到 Cloudflare Pages（拆分版，手机首屏约 2 秒）
# 首次使用：npx wrangler login
# 用法：./deploy-pages.sh
#      PAGES_PROJECT=别的名字 SITE_URL=https://your.domain ./deploy-pages.sh
set -euo pipefail
cd "$(dirname "$0")"

PROJECT="${PAGES_PROJECT:-songgame}"
export SITE_URL="${SITE_URL:-https://${PROJECT}.pages.dev}"

echo "== 1/3 构建 dist（SITE_URL=$SITE_URL） =="
python3 build.py --dist

echo "== 2/3 自检 =="
[ -f dist/index.html ] || { echo "缺 dist/index.html"; exit 1; }
[ -f dist/og.jpg ] || echo "（提示：og.jpg 未生成，分享卡会缺图）"
grep -q "assets/scene_bg" dist/index.html || { echo "dist 仍在内嵌图片，检查 build --dist"; exit 1; }
du -sh dist
find dist -type f | wc -l | xargs echo "文件数："

echo "== 3/3 部署 =="
if ! command -v npx >/dev/null 2>&1; then
  echo "需要 Node/npm：装好 Node 后再跑；或把 dist/ 拖到 Cloudflare Pages 后台。"
  exit 1
fi
npx -y wrangler@latest pages deploy dist --project-name "$PROJECT"

echo ""
echo "完成。线上地址：$SITE_URL"
echo "下一步："
echo "  PLAYWRIGHT_BASE_URL=$SITE_URL npx playwright test     # 线上跑同一套 E2E"
