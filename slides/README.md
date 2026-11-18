# 北宋赶考记 · Week 10 Showcase（Reslides）

按课程 [DAIHUM Reslides](https://github.com/boan-anbo/reslides) 公开格式构建（`theme: exhibit`：`::by::`/`::foot::` 槽位、frame/route 组件、讲者备注与秒表计时）。

- **放映（含讲者模式 /#/presenter/ 与计时器）：**
  ```bash
  RESLIDES=/path/to/reslides npm run dev     # → http://localhost:3100/
  ```
- **构建静态版：** `RESLIDES=/path/to/reslides npm run build` → `dist/`（已构建，可直接 `python3 -m http.server` 于 dist/ 放映）
- **导出 PDF：** `RESLIDES=/path/to/reslides npm run pdf`

## 结构（11 页 · 约 5.5 分钟）

1. **p1–p3**：封面 · 六项要求→六份证据（四闭环图） · 作品定位（实机画面）
2. **Loop 1（p4–p5）**：`docs/plan.md` 范围与 non-goals、`/goal` 声明、agent 生成的 HTML 示意图
3. **Loop 2（p6–p7）**：`./test.sh` 四套无头 + pytest（含"为什么不用 vitest"）；史料边界（据/推断/设三档、1057 截断）
4. **Loop 3（p8）**：`@playwright/mcp` + Playwright E2E 打线上 URL
5. **Loop 4（p9）**：两位朋友反馈原话 → 错题本（不降难度） → `data_test.js` 三条断言
6. **p10–p11**：真实困难（7.9 MB → 4G 38.0 s → 1.45 s 对比图） · 结语

## 备注

- 讲者备注写在每页 HTML 注释里（含时间轴），放映时开 `/#/presenter/`。
- 图：`public/images/`（两张项目自绘 SVG）与 `public/assets/`（实机截图，复用 PPTX 的素材）；`refs.bib` 为引用备档（正文引用走 `::foot::`）。
- 投屏备份：同目录 `北宋赶考记-Week10.pptx`（13 页，`build_slides.py` 生成）；现场演示脚本见 `docs/demo-7min.md`。
