# 7 分钟现场演示脚本（11·18）

> 时间：5 分钟演示 + 2 分钟问答。目标不是"讲完所有功能"，而是让老师看到 **4 个闭环各自在工作**。
> 所有命令都在本仓库根目录执行，课前 10 分钟先跑一遍。
> 投屏备份：`slides/北宋赶考记-Week10.pptx`（11 页主讲 + 2 页 Q&A/命令备用；现场仍以切标签和跑命令为主）。

## 课前 10 分钟（只做这些）

0. 先跑自检：`./preflight.sh` —— 全 ✓ 才往下走。
1. **打开 4 个终端标签**，都 `cd` 到本仓库：
   - T1：测试（`./test.sh`）
   - T2：浏览器（`npx playwright test`）
   - T3：MCP / 检查脚本（`npm run check:mcp`）
   - T4：备用（`python3 -m http.server 8765` / `git status`）
2. **打开 5 个浏览器标签**：
   - 线上：https://songgame.pages.dev/
   - 示意图：`docs/architecture-explainer.html`
   - 计划：`docs/plan.md`（滚到 §8 `/goal` 与 §9 问答）
   - 证据：`docs/evidence.md`
   - 反馈：`docs/user-feedback.md`
3. **跑一遍**（确认不是红）：
   ```bash
   ./test.sh
   npx playwright test
   npm run check:mcp
   ```
4. 手机连同一个 Wi-Fi，打开线上 URL，确认第一幕能出。
5. **如果终端是装 Node 之前就开着的**：新开一个终端，或先跑 `source ~/.zshrc`，确认 `node -v` 有输出。
6. `opencode` 必须从**终端**启动（不要在 Dock/Spotlight 里点图标），否则拿不到 nvm 的 PATH，MCP 会报 `npx not found`。
5. 关掉通知、放大终端字号（≥16pt）、浏览器缩放 110%。

## 0:00–0:20 开场（20 秒）

> "《北宋赶考记》，嘉祐二年科举模拟，单文件 HTML，线上在 Cloudflare。
> 今天只演示四件事：怎么想清楚、怎么用测试锁住、怎么让 agent 自己看浏览器、以及朋友的一句话怎么变成一条永久测试。"

打开线上 URL，点「重新开始」→ 关掉凡例，停在第一幕。

## 0:20–1:15 Loop 1 · Ideation + 示意图（55 秒）

切到 `docs/plan.md`：

> "先锁意图再让 agent 跑。这是范围和 non-goals：不做多人、不接 Key、不逐题标出处。
> 这是可以直接粘贴的 `/goal`：绑定 plan、证据表和测试命令。"

切到 `docs/architecture-explainer.html`：

> "这是 agent 生成的自包含 HTML 示意图：12 幕、每日 4 行动点、构建管线、测试层都在一页里。"

（如果被问"为什么不是 Excalidraw/Mermaid"：HTML 是课程允许的三选一，且能直接投屏、无外部依赖。）

## 1:15–2:45 Loop 2 · 测试套件（90 秒）

T1：

```bash
./test.sh
```

口播（等它跑，约 5 秒）：

> "三层：pytest 13 条守数据与史料边界；JXA 跑规则：题诗 8、座谈 11、数据 44、全流程 54 条 × 3 个种子；最后 180 局平衡模拟只报告不判失败。"

指出输出里的两行：

- `13 passed` —— 1057 截断、据/推断/设、57 条词条出处、产物完整性
- `54 条断言` × 3 —— 家塾到琼林宴，含存档与结局

T2：

```bash
npx playwright test
```

口播：

> "浏览器层 7 条，桌面 + 手机：0 console error、0 断链、答题、刷新续玩、Esc 关弹窗、手机页头不重叠、按钮 ≥36px。"

如果老师追问"历史边界怎么测"：切 `docs/evidence.md`，指 6 道 `afterCutoff` 题和 `usable()` 过滤，说明"1057 年的考生不会考到 1069 年的王安石变法"。

## 2:45–3:30 Loop 3 · 自动浏览器（45 秒）

T3：

```bash
cat opencode.json
opencode mcp list
```

应看到：

```
✓ playwright  connected
  npx @playwright/mcp --browser chrome
```

然后：

```bash
npm run check:mcp
```

口播：

> "这不是截图工具，是 MCP 协议：脚本连上 @playwright/mcp 服务器，让它开 headless Chrome、导航线上页、读 console、再截桌面和手机两张图。输出里 `Total messages: 0 (Errors: 0)`。"

打开 `artifacts/mcp-mobile.png` 给老师看。

（备用：`npm run check:browser` 是同一套自动化的纯 Playwright 版本，会额外统计 4xx 并检查横向溢出；MCP 万一连不上就用它。）

## 3:30–4:30 Loop 4 · 朋友反馈 → 回归测试（60 秒）

打开 `docs/user-feedback.md`：

> "两位朋友在线上链接试玩，反馈只有一句：题目有点难，除此之外没了。"

> "但本作的目标用户是中学生历史刷题，题库按初中范围命制；两位朋友不是目标用户。所以我**不降难度**。"

> "我把这条反馈转成学习机制：**错题本**。温书答错的题记进来，下次温书优先重练；答对就移出。"

现场跑：

```bash
osascript -l JavaScript data_test.js | grep 错题
```

> "三条断言：记入、优先抽、答对移出。难度和计分一点没动。"

指一下 `docs/user-feedback.md` 的 A-1 / B-1 两行：原话、判断、改动、测试名都在。

（如果老师追问"为什么不降"：目标用户是中学生，题目范围就是初中历史；降难度会让刷题失去意义。改的是练习闭环，不是题目。）

## 4:30–5:00 一个真实困难（30 秒）

二选一，讲具体数字：

- **单文件 7.9 MB**：4G 限速首屏 38 秒 → 拆 `dist/` + WebP 后 **1.9 秒**；线上 HTML Brotli 后 61 KB。
- **测试不可信**：`walkthrough_test.js` 12 次跑挂 7 次（没播种 + 夜里不补精力）→ 固定种子 + 补属性 + 非零退出，现在 3 个种子稳定全绿。

## 5:00–7:00 Q&A 预备答案

| 可能被问 | 一句话 |
|---|---|
| 为什么不用 vitest？ | 没有 JS 构建链，逻辑用 JXA 直调游戏函数；数据/史料用 pytest；页面用 Playwright。三层都在 `./test.sh` 里。 |
| 为什么题目不标出处？ | 四选一是通行知识、不是史料主张；引证在 57 条词条，年代边界在 `afterCutoff`。 |
| 大儒对话能不能自由输入？ | 现在 15 个话题；半自由方案（意图匹配 + 记忆）评估过，排在 Week 12。 |
| 7.9 MB 单文件还有必要吗？ | 它是离线版承诺；线上走 `dist/`，两者同一模板。 |
| MCP 具体帮你做了什么？ | 让 agent 自己读 DOM 尺寸、console、404、截图，不用我人肉转述。 |

## 网络/环境出问题时的降级

1. **线上打不开**：T4 `python3 -m http.server 8765`，浏览器开 `http://127.0.0.1:8765/index.html`；跑检查时加 `URL=http://127.0.0.1:8765/index.html npm run check:browser`，说明"线上同版本，刚才已测过 7/7"。
2. **Playwright 起不来**：`npx playwright --version` 应输出 1.65.x；`node -v` 应有输出。都不行就直接展示 `artifacts/live-*.png` 和 `test-results/` 里的历史截图。
3. **MCP 连不上**：只展示 `opencode.json` + `npm run check:browser` 的输出，说明"同一套 Chromium 自动化，MCP 只是把它接给 agent"。
4. **pytest 没有 .venv**：`./test.sh` 会跳过并提示；只跑 JXA + Playwright 也能讲完三层。

## 红线

- 不现场装任何东西（Node 已装好：`node -v` = v26.13.1）。
- 不现场改代码，除非 Loop 4 需要展示一行 diff。
- 不念 README；每段只讲"这是什么、证明了什么"。
- 反馈必须是真人原话；没有就说没有。
