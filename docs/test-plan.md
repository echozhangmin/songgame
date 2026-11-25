# 测试说明（Loop 2 的口播底稿）

> 老师问"你测了什么"，照这张表答。所有命令在仓库根目录，全部可现场跑。

## 一条命令

```bash
./test.sh          # 全部无头测试（约 5 秒）
npx playwright test # 浏览器层（约 13 秒）
```

## 四层各测什么

| 层 | 文件 | 数量 | 证明什么 | 典型断言 |
|---|---|---|---|---|
| 数据/史料（pytest） | `tests/test_data.py` | 13 | 数据没被改坏、年代不穿越、词条三档齐全 | `afterCutoff` 只有 6 题且 >1057；抽题池都走 `usable(q)`；有原文 ⇔ 标"据" |
| 规则（JXA） | `poem_test.js` | 8 | 题诗四标准与三档奖惩 | 抄《春晓》判下品；离题判中品 |
| 规则（JXA） | `dialogue_test.js` | 11 | 大儒座谈的话题门控与记忆 | 未投行卷时"问行卷文章"不出现 |
| 规则（JXA） | `data_test.js` | 44 | 运行时的抽题池、词条、旧档迁移 | 旧档缺 `talked` 也能读入并补默认值 |
| 全流程（JXA） | `walkthrough_test.js` | 54 × 3 种子 | 家塾→长亭→驿→山匪→虹桥→城门→行卷座谈→省试→殿试→琼林宴 | 第 8 日山匪必发；第 25 日入闱；结局诗囊非空 |
| 浏览器（Playwright） | `tests/e2e.spec.ts` | 7（桌面+手机） | 真实页面：0 报错、0 断链、可玩、可续、手机版面 | `expect(errors).toEqual([])`、`expect(bad).toEqual([])`、`scrollWidth === innerWidth` |
| 平衡（模拟） | `sim.js` | 180 局 | 数值不崩盘（只报告，不判失败） | 三档答题正确率各 60 局 |

## 历史边界（老师最可能追问）

| 概念 | 本作怎么落实 | 测试 |
|---|---|---|
| **据** | 有原文可引：行卷/温卷（《云麓漫钞》卷八）、长亭（李白《菩萨蛮》）等 5 条 | `test_quote_implies_ju...` |
| **推断** | 只到书名/篇名，用"所述"标明：49 条 | `test_glossary_has_57...` |
| **设** | 游戏机制：行动点、考运、诗品 3 条 | `test_tier_counts_are_stable` |
| **1057 截断** | 6 题标 `afterCutoff`，省试三场与殿试用 `usable()` 过滤 | `test_only_six_questions...`、`test_exam_pools_filter...` |
| 题库出处 | **不逐题标注**（2026-11-14 拍板）：通行知识，不作史料引证 | `docs/evidence.md` §3 |

> 一句话：**题库管"年代不穿越"，词条管"出处与三档"，两件事分开测。**

## 页面定位器（page locators）

Playwright 全部用语义化的 `data-*`，不依赖 CSS 类名或文案位置：

| 选择器 | 指什么 | 用例 |
|---|---|---|
| `[data-act="newgame"]` / `[data-act="continue"]` | 开始页两个入口 | 开局、续玩 |
| `[data-act="closeHelp"]` / `#overlay` | 凡例弹层 | 弹层出现/关闭 |
| `.act` | 当前幕的行动按钮 | 第一幕应有 5 个 |
| `[data-act="study"]` + `#overlay .opt` | 温书与四选一 | 答题→反馈 |
| `[data-act="glossIndex"]` + `[data-term]` | 词条索引与详情 | Esc 逐层退出 |
| `.meta-date`、`.meta button`、`.head` | 顶栏与手机版面 | 390px 下按钮 ≥36px、元素不重叠 |
| `link[rel="icon"]`、`meta[property="og:image"]` | 分享与图标 | 防 404、分享卡存在 |

## 故意没测的

- 诗"写得好不好"：判分是近似规则，只测边界（八例），不测审美。
- LLM 对话：没有接模型，不需要 judge。
- 真机 Safari/Android：只覆盖 Chromium + 手机视口；README 已如实说明。
