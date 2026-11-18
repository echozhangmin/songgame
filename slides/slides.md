---
framework: react
theme: exhibit
title: "北宋赶考记 · Week 10 Showcase"
routerMode: hash
layout: cover
kicker: DHG508 · Week 10 Showcase
meta: 5.5 min · 2026-11-18
duration: 6min
timer: stopwatch
---

# 北宋赶考记 · 嘉祐二年

四个反馈闭环，把一个单文件 HTML 科举模拟做完、测住、部署上线

::by::

echozhangmin · https://songgame.pages.dev/

<!--
000–000.5 min

开场 15 秒：《北宋赶考记》，嘉祐二年科举模拟，单文件 HTML。今天只讲一件事——四个反馈闭环怎么把它做完、测住、送上线。线上地址在屏幕上，手机可开。
-->

---
kicker: 0 · 六项要求 → 六份证据
---

# 作业六项，每一项都有对应的实物。

<div class="body col">
<div class="frame fit wide"><span class="label">四个闭环 · 一份代码</span><img src="/images/diag-four-loops.svg" alt="四个反馈闭环围绕游戏本体" style="width:100%"></div>
</div>

::foot::

六项对应：`songgame.pages.dev` · `docs/plan.md` + `docs/architecture-explainer.html` · `./test.sh` · `scripts/browser-check.mjs` + `tests/e2e.spec.ts` · `docs/user-feedback.md` · `docs/difficulty.md`

<!--
000.5–1 min

三十秒过一遍作业清单，每一项都能点开实物：线上 URL、plan.md 加示意图、测试套件、浏览器闭环、朋友反馈转测试、还有一个真实困难。下面按这个顺序讲。
-->

---
kicker: 1 · 这是什么
---

# 临川举子，三十日赴京应省试、殿试。

<div class="body col">
<div class="frame fit wide"><span class="label">实机画面 · https://songgame.pages.dev/</span><img src="/assets/game-desktop.png" alt="北宋赶考记桌面端实机画面" style="width:100%"></div>
<div class="frame hot"><span class="label">一件完整的东西</span><div class="text">

- **十二幕**：家塾 → 长亭 → 驿站 → 山道 → 汴河 → 虹桥 → 城门 → 酒楼 → 书库 → 号舍 → 放榜
- **57 条词条**（据 5 · 推断 49 · 设 3）· 150 道题 · 大儒座谈 15 话题 · 题诗四重判定
- 每日 4 行动点，在温书／歇息／交游／盘缠之间取舍——**落第是经营失败**

</div></div>
</div>

<!--
1–1.5 min

半分钟说清产品：不是休闲游戏，是让玩家穿着制度的鞋子走三十天。57 条词条全部带出处三档标记。
-->

---
kicker: Loop 1 · Ideation
---

# 先锁意图，再让 agent 跑。

<div class="body">
<div class="frame"><span class="label">docs/plan.md · 范围与红线</span><div class="text">

- **范围**：完成 Week 10 交付——部署、测试、反馈闭环
- **Non-goals**：不引入前端框架、不接 API Key、不做多人
- **史料红线**：据／推断／设三档 + **1057 年截断**，晚于 1057 的题必须标 `afterCutoff`

</div></div>
<div class="frame hot"><span class="label">/goal 声明（可粘贴原文）</span><div class="text">

```
/goal 在 song-exam 完成 Week 10 交付：
1) 按 docs/plan.md 的范围与 non-goals 改代码；
2) 史料遵守 docs/evidence.md 三档与 1057 截断；
3) 任何改动后运行 ./test.sh，必须全绿；
4) 产出 dist/ 并在 Cloudflare Pages 上线；
5) 测试命令写入 AGENTS.md、未决问题写入 questions.md。
```

</div></div>
</div>

<!--
1.5–2.25 min

第一环：Plan 模式里先让 agent 复述范围、提三个问题，答完写进 plan.md。/goal 不是许愿，是绑定计划、证据表和测试命令的一段可执行指令——agent 跑偏时红线能把它拉回来。
-->

---
kicker: Loop 1 · Schematic
---

# agent 生成的项目示意图：一页看清机制与管线。

<div class="body col">
<div class="frame fit wide"><span class="label">docs/architecture-explainer.html（自包含 HTML，agent 生成）</span><img src="/assets/arch-hero.png" alt="agent 生成的 HTML 架构示意图" style="width:100%"></div>
<div class="frame"><div class="text">另有 `docs/architecture.md`：Mermaid 三图——日循环状态机 · 考试与结局流程 · 题诗四重判定。</div></div>
</div>

<!--
2.25–3 min

示意图是 agent 画的：十二幕、每天四个行动点、构建管线、测试层在一页里。看不懂终端大段文字的时候，一张图就是最好的对齐工具。课程允许三选一：HTML、Excalidraw、Mermaid——我两种都留了。
-->

---
kicker: Loop 2 · Automated Tests
---

# 一条命令跑完：`./test.sh`

<div class="body">
<div class="frame"><span class="label">song-exam/ · 测试资产</span><div class="text">

```
├─ sim.js               平衡模拟 · 180 局 ×3 档 ×3 模式
├─ walkthrough_test.js  全流程审计 · 54 例 ×3 种子
├─ poem_test.js         题诗四重判定 · 8 例
├─ dialogue_test.js     大儒座谈 · 49 例
├─ data_test.js         运行时数据守卫
├─ tests/test_data.py   pytest · 出处三档 / 1057 截断
├─ tests/e2e.spec.ts    Playwright E2E · 打线上 URL
└─ ./test.sh            构建 → 四套无头 → pytest → E2E
```

</div></div>
<div class="frame hot"><span class="label">为什么不 vitest</span><div class="text">

- 游戏是**零构建链**的单文件 HTML——逻辑直接跑在 JXA 无头环境，`osascript -l JavaScript` 即测试器
- 数据与逻辑同源：`data/*.json` 守结构，`*_test.js` 守行为——任何一层被改坏都在 1 秒内拦住

</div></div>
</div>

<!--
3–4 min · 现场就跑 ./test.sh，约五秒出全绿。

两层：技术逻辑用四套无头；历史边界用 pytest——下一页。
-->

---
kicker: Loop 2 · Historical Boundaries
---

# 测试不只测代码，也测史料边界。

<div class="body">
<div class="frame"><span class="label">tests/test_data.py · 数据守卫</span><div class="text">

- 57 条词条每条必须有有效的**据／推断／设**三档标记（据 5 · 推断 49 · 设 3）
- **1057 截断**：晚于嘉祐二年的内容必须显式标 `afterCutoff`
- 产物完整性：`北宋赶考记.html` 与 `index.html` 必须存在且无占位符残留

</div></div>
<div class="frame hot"><span class="label">机制即史实 · 被测试锁住的校正</span><div class="text">

- 省试三场＝**诗赋 · 论 · 策**（专场经义系熙宁后之制，已据《宋史·选举志一》校正）
- 默写古人原句判**下品**：名句库约 60 句入 `data_test.js` 断言

</div></div>
</div>

::foot::

Sources: 《宋史·选举志一》；欧阳修《归田录》；Rong, "Friendship in a context of hierarchical sociability," *Diogenes* 265–266 (2019).

<!--
4–4.5 min

历史项目的测试要多一层：每条断言守的不只是代码，是"这条说法有据可查、没穿越"。省试第二场从经义改回论，就是测试与史料对表的结果。
-->

---
kicker: Loop 3 · Automatic Browser Loop
---

# 让 agent 自己开浏览器：看 DOM、读 console、截图。

<div class="body">
<div class="frame"><span class="label">闭环两件套</span><div class="text">

```
├─ opencode.json              @playwright/mcp@latest
├─ scripts/browser-check.mjs  探索：DOM 几何 / console / 404
└─ tests/e2e.spec.ts          可重复 E2E：localhost + 线上 URL
```

</div></div>
<div class="frame hot"><span class="label">E2E 断言（同一套打 https://songgame.pages.dev/）</span><div class="text">

- **0** console 错误 · **0** 失效资源（404）
- 关键交互：重新开始 → 第 1 日行动 → 存档 → 刷新续玩
- 手机竖屏视口：按钮可点、无横向溢出

</div></div>
</div>

<!--
4.5–5.25 min

区别讲清楚：MCP 是 agent 的眼睛——探索性的看；Playwright 测试是可重复的关卡——每次提交都跑，线上也跑。现场可以切 mcp 演示。
-->

---
kicker: Loop 4 · Feedback → Regression Test
---

# 两位朋友说“题目有点难”——不降难度，改练习闭环。

<div class="body">
<div class="frame"><span class="label">docs/user-feedback.md · 原话入库</span><div class="text">

- 朋友 A：“做题的题目有点难，除此之外没了。”（朋友 B 同感）
- **诊断**：目标用户是中学生历史刷题；两位朋友不是目标用户——这条反馈不该变成“降难度”

</div></div>
<div class="frame hot"><span class="label">改动 → 永久测试（data_test.js 三条断言）</span><div class="text">

- **错题本**：温书答错的题记入（上限 40），下次温书优先重练；答对即移出
- 断言：答错记入 → 优先重出 → 答对移出。**难度、题量、计分全部不动**

</div></div>
</div>

<!--
5.25–6 min

第四环最容易被做成"改了就行"。规则是每条反馈都要落到改动加测试，否则不算完成。这条反馈的处理本身就是历史判断：目标用户是谁，决定反馈往哪边走。
-->

---
kicker: One Concrete Difficulty
---

# 单文件 7.9 MB：手机 4G 首屏 38 秒。

<div class="body col">
<div class="frame fit wide"><span class="label">4G 限速实测（Playwright + CDP 复现）</span><img src="/images/diag-deploy-split.svg" alt="38 秒与 1.45 秒对比" style="width:100%"></div>
<div class="frame"><div class="text">**改法**：同一份模板加 `build.py --dist`——图片转 WebP 外链、HTML 只留 158 KB、`_headers` 一年 immutable 缓存。单文件版保留作离线双保险。</div></div>
</div>

<!--
6–6.5 min（如时间紧可压到 15 秒）

真实困难要有数字：38 秒怎么发现、怎么复现（CDP 限速）、怎么改（拆分而不是放弃单文件）。若被追问第二个困难：walkthrough 测试 12 次跑挂 7 次——随机数没播种，固定种子后三个种子全绿。
-->

---
kicker: Thank You · Q&A
---

# 四个闭环，都在跑。

<div class="body">
<div class="frame fit wide"><span class="label">https://songgame.pages.dev/</span><div class="text">

01 **Ideation** — plan.md + /goal + 示意图　　02 **Tests** — ./test.sh 全绿
03 **Browser** — @playwright/mcp + E2E 打线上　　04 **Feedback** — “有点难” → 错题本 → 三条断言

</div></div>
</div>

::foot::

欢迎现场用手机打开试玩 · 投屏备份：`slides/北宋赶考记-Week10.pptx`（13 页）

<!--
收尾一句话：欢迎现在就用手机打开玩一局。问答备用页在 PPTX 里。
-->
