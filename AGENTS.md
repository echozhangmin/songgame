# AGENTS.md · 北宋赶考记

## 一键回归（每次改动后必跑；全部无头、秒级、不靠眼睛）

```bash
osascript -l JavaScript sim.js               # 平衡模拟：180 局 × 3 档答题率 + 两个故意玩崩模式
osascript -l JavaScript walkthrough_test.js  # 全流程交互审计 50 例（家塾→琼林宴全链）
osascript -l JavaScript poem_test.js         # 题诗四重标准判定 8 例
osascript -l JavaScript dialogue_test.js     # 大儒座谈 49 例（结构/门控/回落）
```

改任何机制后四条全绿才算过；测试预期要与机制同步修改（历史教训：预期数错会假报 FAIL）。

## 构建

```bash
python3 build.py   # game.template.html + data/*.json + assets/scene_*.jpg → 北宋赶考记.html / index.html
```

- 改题目只改 `data/quiz_150.json`；改词条只改 `data/glossary.json`；改规则/文案/数值/人物只改 `game.template.html`。
- 场景插图按 `assets/scene_<场景id>.jpg` 命名放入即自动内嵌（id 见 `game.template.html` SCENES）。

## 提交即部署

`git commit` 触发 post-commit 钩子自动 push → GitHub Pages（https://echozhangmin.github.io/songgame/）约 1–2 分钟后更新。
推送偶发 SSH 22 端口抖动：重试 `git push` 即可，不影响本地提交。

## 架构

见 `docs/architecture.md`（Mermaid：日循环状态机 / 考试与结局流程 / 题诗四重判定）。
