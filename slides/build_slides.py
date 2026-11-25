# -*- coding: utf-8 -*-
"""生成 Week 10 演示 PPTX（北宋赶考记）。

运行：
    /Users/min/.dsh/dsh-runtimes/dsh-primary-runtime/dependencies/python/bin/python3 slides/build_slides.py
输出：
    slides/北宋赶考记-Week10.pptx
"""
import os
from PIL import Image
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.enum.shapes import MSO_SHAPE
from pptx.oxml.ns import qn
from lxml import etree

HERE = os.path.dirname(os.path.abspath(__file__))
ASSETS = os.path.join(HERE, "assets")
OUT = os.path.join(HERE, "北宋赶考记-Week10.pptx")

# ---------------- 色板 ----------------
BG      = RGBColor(0xF4, 0xEC, 0xD8)
BG2     = RGBColor(0xEC, 0xE0, 0xC4)
INK     = RGBColor(0x2B, 0x24, 0x18)
INK2    = RGBColor(0x5A, 0x4F, 0x3C)
MUTED   = RGBColor(0x8B, 0x7A, 0x5D)
RED     = RGBColor(0xA6, 0x3A, 0x2C)
GOLD    = RGBColor(0x9A, 0x81, 0x3D)
GREEN   = RGBColor(0x67, 0x70, 0x3F)
DARK    = RGBColor(0x2E, 0x27, 0x1B)
CREAM   = RGBColor(0xF6, 0xEF, 0xDC)
LINE    = RGBColor(0xD5, 0xC5, 0xA0)

SERIF = "Songti SC"
MONO  = "Menlo"

prs = Presentation()
prs.slide_width = Inches(13.333)
prs.slide_height = Inches(7.5)


# ---------------- 基础工具 ----------------
def set_font(run, size, color=INK, bold=False, font=SERIF, italic=False):
    run.font.size = Pt(size)
    run.font.bold = bold
    run.font.italic = italic
    run.font.name = font
    run.font.color.rgb = color
    rPr = run._r.get_or_add_rPr()
    for tag in ("a:ea", "a:cs"):
        el = rPr.find(qn(tag))
        if el is None:
            el = etree.SubElement(rPr, qn(tag))
        el.set("typeface", font)


def textbox(slide, x, y, w, h, text="", size=16, color=INK, bold=False,
            font=SERIF, align=PP_ALIGN.LEFT, line=1.3, anchor=MSO_ANCHOR.TOP,
            margins=(0, 0, 0, 0), italic=False):
    box = slide.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))
    tf = box.text_frame
    tf.word_wrap = True
    tf.vertical_anchor = anchor
    tf.margin_left, tf.margin_right, tf.margin_top, tf.margin_bottom = [Inches(m) for m in margins]
    p = tf.paragraphs[0]
    p.alignment = align
    p.line_spacing = line
    r = p.add_run()
    r.text = text
    set_font(r, size, color, bold, font, italic)
    return box


def paras(slide, x, y, w, h, items, line=1.35, anchor=MSO_ANCHOR.TOP):
    """items: [(text,size,color,bold,space_before,font), ...]"""
    box = slide.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))
    tf = box.text_frame
    tf.word_wrap = True
    tf.vertical_anchor = anchor
    tf.margin_left = tf.margin_right = tf.margin_top = tf.margin_bottom = 0
    for i, it in enumerate(items):
        text, size, color, bold, space = it[:5]
        font = it[5] if len(it) > 5 else SERIF
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.line_spacing = line
        p.space_before = Pt(space)
        r = p.add_run()
        r.text = text
        set_font(r, size, color, bold, font)
    return box


def rect(slide, x, y, w, h, fill=BG2, line_color=LINE, line_w=0.75,
         shape=MSO_SHAPE.ROUNDED_RECTANGLE, radius=None):
    shp = slide.shapes.add_shape(shape, Inches(x), Inches(y), Inches(w), Inches(h))
    if fill is None:
        shp.fill.background()
    else:
        shp.fill.solid()
        shp.fill.fore_color.rgb = fill
    if line_color is None:
        shp.line.fill.background()
    else:
        shp.line.color.rgb = line_color
        shp.line.width = Pt(line_w)
    shp.shadow.inherit = False
    if radius is not None and shape == MSO_SHAPE.ROUNDED_RECTANGLE:
        shp.adjustments[0] = radius
    return shp


def hline(slide, x, y, w, color=INK, width=1.0):
    shp = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(x), Inches(y), Inches(w), Pt(width))
    shp.fill.solid(); shp.fill.fore_color.rgb = color
    shp.line.fill.background()
    shp.shadow.inherit = False
    return shp


def picture(slide, name, x, y, w=None, h=None, border=True):
    path = os.path.join(ASSETS, name)
    iw, ih = Image.open(path).size
    if w is not None and h is None:
        h = w * ih / iw
    elif h is not None and w is None:
        w = h * iw / ih
    pic = slide.shapes.add_picture(path, Inches(x), Inches(y), Inches(w), Inches(h))
    if border:
        pic.line.color.rgb = LINE
        pic.line.width = Pt(0.75)
    return pic


_PAGE = [1]

def slide_base(page=0, kicker=None, title=None, dark=False):
    _PAGE[0] += 1
    page = _PAGE[0]
    s = prs.slides.add_slide(prs.slide_layouts[6])
    bgfill = s.background.fill
    bgfill.solid()
    bgfill.fore_color.rgb = DARK if dark else BG
    if kicker:
        textbox(s, 0.75, 0.5, 8.5, 0.3, kicker, 10.5, RED if not dark else GOLD, True)
    if title:
        textbox(s, 0.75, 0.82, 11.9, 0.72, title, 27, INK if not dark else CREAM, True, line=1.15)
        hline(s, 0.78, 1.55, 11.8, LINE if not dark else RGBColor(0x5A, 0x4E, 0x36), 0.75)
    # footer
    textbox(s, 0.78, 7.08, 7.5, 0.24, "北宋赶考记 · 嘉祐二年 ｜ 单文件 HTML 科举模拟", 8.5,
            MUTED if not dark else RGBColor(0x9E, 0x8D, 0x6C))
    textbox(s, 12.0, 7.08, 0.6, 0.24, f"{page:02d}", 9, MUTED if not dark else RGBColor(0x9E, 0x8D, 0x6C),
            align=PP_ALIGN.RIGHT)
    return s


def code_box(slide, x, y, w, h, lines, size=11, label=None):
    rect(slide, x, y, w, h, fill=DARK, line_color=DARK, radius=0.04)
    if label:
        textbox(slide, x + 0.22, y + 0.14, w - 0.4, 0.22, label, 8.5, GOLD, True)
        top = y + 0.42
    else:
        top = y + 0.22
    items = [(ln, size, CREAM, False, 0, MONO) for ln in lines]
    paras(slide, x + 0.24, top, w - 0.42, h - (top - y) - 0.12, items, line=1.38)


# ============================================================ 1 封面
s = prs.slides.add_slide(prs.slide_layouts[6])
s.background.fill.solid(); s.background.fill.fore_color.rgb = BG
# 右侧图
picture(s, "game-desktop.png", 7.55, 1.05, w=5.25)
# 左侧
textbox(s, 0.95, 0.95, 5.8, 0.3, "WEEK 10  ·  FEEDBACK LOOPS", 10.5, RED, True)
textbox(s, 0.9, 1.35, 6.2, 1.0, "北宋赶考记", 56, INK, True, line=1.0)
textbox(s, 0.95, 2.48, 6.3, 0.4, "嘉祐二年 · 单文件 HTML 科举模拟", 18, INK2)
hline(s, 0.97, 3.12, 5.7, LINE, 1.2)
paras(s, 0.97, 3.35, 5.9, 1.5, [
    ("一个临川举子，三十日赴京。", 17, INK2, False, 0),
    ("十二幕 · 五十七个词条 · 一百五十道题 · 零外部依赖", 14, MUTED, False, 8),
    ("省试、殿试、放榜，都在一个 .html 里。", 14, MUTED, False, 4),
], line=1.55)
textbox(s, 0.97, 5.35, 6.0, 0.28, "https://songgame.pages.dev/", 15, RED, True, MONO)
textbox(s, 0.97, 5.75, 6.0, 0.28, "2026-11-18  ·  5 分钟演示 + 2 分钟问答", 11.5, MUTED)
# 印章
rect(s, 11.95, 6.05, 0.72, 0.72, fill=None, line_color=RED, line_w=2.2, shape=MSO_SHAPE.RECTANGLE)
textbox(s, 11.95, 6.18, 0.72, 0.45, "嘉祐", 15, RED, True, align=PP_ALIGN.CENTER)
# 底部细线
hline(s, 0.95, 6.55, 5.8, LINE, 1.0)
textbox(s, 0.97, 6.68, 6.0, 0.3, "四个反馈闭环的现场证据", 12, GOLD, True)

s.notes_slide.notes_text_frame.text = (
    "（20 秒）《北宋赶考记》，嘉祐二年科举模拟，单文件 HTML，线上在 Cloudflare。"
    "今天只演示四件事：怎么想清楚、怎么用测试锁住、怎么让 agent 自己看浏览器、以及朋友的一句话怎么变成永久测试。"
)


# ============================================================ 2 六项要求
s = slide_base(2, "WEEK 10  ·  BRIEF → EVIDENCE", "六项要求，六份证据")
items = [
    ("01", "Live URL", "https://songgame.pages.dev/", "Cloudflare Pages，手机可开"),
    ("02", "Ideation + Schematic", "plan.md §8 /goal · §9 三问", "architecture-explainer.html"),
    ("03", "Automated Test Suite", "pytest 13 · JXA 45 / 73 / 54×3", "Playwright 7 条"),
    ("04", "Automatic Browser Loop", "@playwright/mcp", "headless Chrome · console · 截图"),
    ("05", "Feedback → Regression", "两位朋友：题难 → 错题本", "3 条 JXA 断言"),
    ("06", "One Concrete Difficulty", "7.9 MB 单文件 · 4G 38 s", "拆分后 1.45 s"),
]
for i, (num, head, a, b) in enumerate(items):
    x = 0.82 + (i % 2) * 5.95
    y = 1.85 + (i // 2) * 1.55
    textbox(s, x, y, 0.5, 0.3, num, 10.5, GOLD, True)
    textbox(s, x + 0.48, y - 0.03, 5.2, 0.32, head, 14, INK, True)
    textbox(s, x + 0.48, y + 0.38, 5.15, 0.3, a, 10.5, RED, True if i in (0, 2, 4) else False, MONO if i in (0, 2, 4) else SERIF)
    textbox(s, x + 0.48, y + 0.74, 5.15, 0.3, b, 10, MUTED)
    hline(s, x + 0.48, y + 1.22, 4.9, LINE, 0.5)
textbox(s, 0.82, 6.35, 11.6, 0.3, "对应 instructions.md · Bring to class 的六项；每一页后面都给出可现场打开的证据。", 10.5, INK2)
s.notes_slide.notes_text_frame.text = "（20 秒）先对表：Week 10 要的六项，这里各有一份可现场打开的证据。"


# ============================================================ 2 作品与目标
s = slide_base(2, "01  ·  WHAT IT IS", "不是休闲游戏，是给中学生的历史刷题场")
paras(s, 0.8, 1.85, 6.5, 3.3, [
    ("单文件 HTML，双击即玩", 16, INK, True, 0),
    ("不联网、不装依赖、无 API Key；线上版走 dist/，手机 4G 首屏 1.45 秒。", 12.5, INK2, False, 4),
    ("三十日 / 十二幕", 16, INK, True, 18),
    ("家塾 → 长亭 → 驿站 → 山道 → 汴河 → 虹桥 → 城门 → 酒楼 → 书库 → 号舍 → 放榜。", 12.5, INK2, False, 4),
    ("科举制度 + 史料词条", 16, INK, True, 18),
    ("57 条词条分「据 / 推断 / 设」；题库按初中历史范围命制，1057 年后的事不入考场。", 12.5, INK2, False, 4),
], line=1.35)

cards = [("12", "幕", "家塾到琼林宴"), ("57", "词条", "据 5 · 推断 49 · 设 3"),
         ("150", "题", "先秦 — 五代北宋"), ("0", "外部依赖", "离线 / 无 Key")]
for i, (num, unit, caption) in enumerate(cards):
    x = 7.55 + (i % 2) * 2.62
    y = 1.85 + (i // 2) * 2.05
    rect(s, x, y, 2.38, 1.78, fill=CREAM, line_color=LINE, radius=0.05)
    textbox(s, x + 0.2, y + 0.2, 2.0, 0.7, num, 34, RED if i == 0 else INK, True, line=1.0)
    textbox(s, x + 0.2, y + 0.92, 2.0, 0.28, unit, 13, INK2, True)
    textbox(s, x + 0.2, y + 1.24, 2.0, 0.4, caption, 9.5, MUTED)

textbox(s, 7.55, 6.02, 5.1, 0.3, "目标用户：中学生历史刷题  ·  不是普通玩家的休闲游戏", 11, RED, True)

s.notes_slide.notes_text_frame.text = (
    "（20 秒）它不是休闲游戏，是给中学生的历史刷题场。"
    "单文件、离线、零依赖；十二幕、五十七个词条、一百五十道题。"
    "线上版拆了资源，手机 4G 首屏 1.45 秒。"
)


# ============================================================ 3 Loop 1 计划
s = slide_base(3, "LOOP 1  ·  IDEATION & SCHEMATIC", "先锁意图，再让 agent 跑")
code_box(s, 0.8, 1.9, 6.4, 2.3, [
    "/goal 在 song-exam 完成 Week 10 交付：",
    "1) 按 docs/plan.md 的范围与 non-goals 改代码",
    "2) 史料遵守 据/推断/设 与 1057 截断",
    "3) 每次改动跑 ./test.sh 与 ./test.sh --e2e",
    "4) 产出 dist/ 并部署到 Cloudflare Pages",
], size=10.8, label="docs/plan.md  §8  ·  可直接粘贴")
paras(s, 0.8, 4.5, 6.4, 1.8, [
    ("Plan 模式三问（§9）", 12, RED, True, 0),
    ("① 单文件还是拆分？→ 两个都要，同一模板两套产物。", 11.5, INK2, False, 8),
    ("② 150 题要不要逐题标出处？→ 不标，引证在词条。", 11.5, INK2, False, 4),
    ("③ 大儒对话要不要接 LLM？→ 本周不接，保离线。", 11.5, INK2, False, 4),
], line=1.35)
rect(s, 7.45, 1.9, 5.3, 4.25, fill=CREAM, line_color=LINE, radius=0.05)
textbox(s, 7.7, 2.08, 4.8, 0.3, "docs/plan.md 的骨架", 12, RED, True)
paras(s, 7.7, 2.52, 4.8, 3.4, [
    ("§2 范围", 12.5, INK, True, 0),
    ("30 日 · 12 幕 · 4 层测试", 10.5, INK2, False, 2),
    ("§3 Non-goals", 12.5, INK, True, 12),
    ("不做多人 · 不接 Key · 不逐题标出处", 10.5, INK2, False, 2),
    ("§6 验收", 12.5, INK, True, 12),
    ("6 条可执行标准，全部能落到命令", 10.5, INK2, False, 2),
    ("§9 Plan 问答", 12.5, INK, True, 12),
    ("3 个真实分歧，不是事后补的标准答案", 10.5, INK2, False, 2),
], line=1.3)
textbox(s, 7.7, 6.35, 5.0, 0.3, "完整示意图见下一页  →", 10.5, RED, True)

s.notes_slide.notes_text_frame.text = (
    "（30 秒）先锁意图：范围和 non-goals 写进 plan.md，/goal 绑定计划、证据表、测试命令。"
    "三问三答是真实的规划分歧：单文件还是拆分、题目要不要逐题出处、大儒要不要接 LLM。"
    "右边是 agent 生成的自包含 HTML 示意图。"
)


# ============================================================ 4 Loop 1 示意图
s = slide_base(4, "LOOP 1  ·  SCHEMATIC", "一页看清：每天四个行动点，夜里结算")
picture(s, "arch-sec0.png", 0.8, 1.78, w=8.55)
paras(s, 9.7, 1.82, 3.0, 4.3, [
    ("12 幕", 16, INK, True, 0),
    ("按日切场景；赶路日行动点 −2。", 11, INK2, False, 4),
    ("固定遭遇", 16, INK, True, 18),
    ("第 8 日山匪、第 11 日水匪、第 12 日虹桥、第 15 日门税。", 11, INK2, False, 4),
    ("四层测试", 16, INK, True, 18),
    ("pytest / JXA / Playwright / 模拟，全部挂在同一条 ./test.sh 上。", 11, INK2, False, 4),
], line=1.35)

s.notes_slide.notes_text_frame.text = (
    "（25 秒）示意图不是装饰：十二幕、每日四行动点、事件与固定遭遇、考试与终局都在一页里。"
    "课堂上如果时间紧，只指这一页的 01 Daily Loop 和右下角的测试层。"
)


# ============================================================ 5 Loop 2 测试矩阵
s = slide_base(5, "LOOP 2  ·  AUTOMATED TEST SUITE", "四层自动化，一条命令跑完")
rows = [
    ("数据 / 史料", "pytest  ·  tests/test_data.py", "13", "1057 截断、据/推断/设、产物完整性"),
    ("运行规则", "JXA  ·  data_test.js", "45", "抽题池、错题本、旧档迁移"),
    ("玩法逻辑", "JXA  ·  poem / dialogue / walkthrough", "73", "题诗 8 · 座谈 11 · 全流程 54"),
    ("真实浏览器", "Playwright  ·  tests/e2e.spec.ts", "7", "0 报错、0 断链、续玩、Esc、手机版面"),
    ("平衡模拟", "JXA  ·  sim.js", "180", "只报告，不判失败"),
]
x, y, w = 0.82, 1.92, 11.65
cols = [2.35, 4.35, 1.05, 3.9]
# header
textbox(s, x, y, cols[0], 0.3, "层", 10, RED, True)
textbox(s, x + sum(cols[:1]), y, cols[1], 0.3, "文件 / 入口", 10, RED, True)
textbox(s, x + sum(cols[:2]), y, cols[2], 0.3, "数量", 10, RED, True)
textbox(s, x + sum(cols[:3]), y, cols[3], 0.3, "证明什么", 10, RED, True)
hline(s, x, y + 0.38, w, INK, 1.0)
row_h = 0.82
for i, (a, b, c, d) in enumerate(rows):
    yy = y + 0.5 + i * row_h
    textbox(s, x, yy, cols[0], 0.3, a, 13, INK, True)
    textbox(s, x + sum(cols[:1]), yy, cols[1], 0.5, b, 10.2, INK2, False, MONO)
    textbox(s, x + sum(cols[:2]), yy, cols[2], 0.3, c, 15, RED, True)
    textbox(s, x + sum(cols[:3]), yy, cols[3], 0.55, d, 10.5, INK2)
    if i < len(rows) - 1:
        hline(s, x, yy + 0.66, w, LINE, 0.6)
hline(s, x, y + 0.5 + len(rows) * row_h - 0.16, w, INK, 1.0)

rect(s, 0.82, 6.35, 11.65, 0.55, fill=DARK, line_color=DARK, radius=0.05)
textbox(s, 1.05, 6.46, 4.2, 0.3, "./test.sh", 13, CREAM, True, MONO)
textbox(s, 3.1, 6.46, 4.4, 0.3, "./test.sh --e2e", 13, CREAM, True, MONO)
textbox(s, 5.75, 6.46, 6.4, 0.3, "失败即非零退出；全流程固定种子 × 3", 10.5, GOLD)

s.notes_slide.notes_text_frame.text = (
    "（35 秒）四层：pytest 十三守数据与史料；JXA 四十五守运行规则；"
    "JXA 七十三跑玩法逻辑，其中全流程五十四条断言跑三个随机种子；Playwright 七条开真实浏览器；"
    "最后一百八十局平衡模拟只报告。"
)


# ============================================================ 6 史料边界
s = slide_base(6, "LOOP 2  ·  HISTORICAL BOUNDARIES", "题库管年代，词条管出处")
tiers = [
    ("据", "5", "有原文可引", "行卷、温卷（《云麓漫钞》卷八）\n长亭（李白《菩萨蛮》）", GREEN),
    ("推断", "49", "只到书名/篇名", "《宋史·选举志一》所述\n不假装是原文", GOLD),
    ("设", "3", "游戏机制", "行动点 · 考运 · 诗品\n史实如何、本作如何，都写明", RED),
]
for i, (name, num, sub, body, color) in enumerate(tiers):
    x = 0.82 + i * 4.0
    rect(s, x, 1.9, 3.7, 2.35, fill=CREAM, line_color=LINE, radius=0.05)
    textbox(s, x + 0.25, 2.08, 1.0, 0.5, name, 28, color, True, line=1.0)
    textbox(s, x + 1.15, 2.18, 2.3, 0.45, num, 22, INK, True)
    textbox(s, x + 0.25, 2.72, 3.2, 0.28, sub, 11, INK2, True)
    textbox(s, x + 0.25, 3.08, 3.2, 0.9, body, 10.5, MUTED, line=1.4)
rect(s, 0.82, 4.55, 11.65, 0.95, fill=RGBColor(0xEC, 0xDD, 0xD4), line_color=RGBColor(0xD8, 0xB8, 0xAC), radius=0.04)
textbox(s, 1.05, 4.7, 1.6, 0.3, "1057 截断", 12, RED, True)
textbox(s, 2.35, 4.7, 9.8, 0.6,
        "王安石变法（1069）等 6 题已标 afterCutoff，不进省试/殿试抽题池——1057 年的举子不该考到 12 年后的事。",
        11.5, INK2, line=1.35)
paras(s, 0.82, 5.85, 11.6, 0.9, [
    ("测试名：test_only_six_questions...  ·  test_exam_pools_filter...  ·  test_glossary_has_57...  ·  test_quote_implies_ju...", 10, MUTED, False, 0, MONO),
    ("题目不逐题标出处：四选一是通行知识，不作史料引证；引证在 57 条词条。", 10.5, MUTED, False, 4),
], line=1.3)

s.notes_slide.notes_text_frame.text = (
    "（25 秒）历史边界分两件事：题库管年代，词条管出处。"
    "六道 1069 年之后的题标了 afterCutoff，永远不进考场；词条五条据、四十九条推断、三条设。"
    "题目本身不逐题标出处，因为四选一是通行知识，不冒充史料引证。"
)


# ============================================================ 7 Loop 3 MCP
s = slide_base(7, "LOOP 3  ·  AUTOMATIC BROWSER LOOP", "让 agent 自己开浏览器、读 console、截图")
code_box(s, 0.8, 1.85, 6.1, 1.72, [
    '"mcp": {',
    '  "playwright": {',
    '    "command": ["npx","@playwright/mcp","--browser","chrome"]',
    '  }',
    '}',
], size=10, label="opencode.json")
code_box(s, 0.8, 3.72, 6.1, 1.25, [
    "$ npm run check:mcp",
    "MCP server: Playwright 1.66.0-alpha",
    "Total messages: 0 (Errors: 0)",
], size=10.5, label="现场输出")
paras(s, 0.8, 5.18, 6.2, 1.2, [
    ("不是截图工具：MCP 协议 → navigate → console → screenshot。", 12, INK, True, 0),
    ("agent 不用我人肉转述 console 报错和 DOM 尺寸。", 11, INK2, False, 6),
], line=1.35)
picture(s, "mcp-mobile.png", 7.3, 1.82, h=4.55)
textbox(s, 7.3, 6.5, 4.8, 0.3, "artifacts/mcp-mobile.png  ·  headless Chrome 实拍", 9.5, MUTED)
rect(s, 9.95, 2.05, 2.7, 2.4, fill=CREAM, line_color=LINE, radius=0.05)
textbox(s, 10.2, 2.22, 2.2, 0.3, "本次实跑", 10, RED, True)
textbox(s, 10.2, 2.62, 2.2, 0.6, "0", 30, GREEN, True)
textbox(s, 10.2, 3.25, 2.2, 0.3, "console errors", 9.5, MUTED)
textbox(s, 10.2, 3.62, 2.2, 0.5, "2 张截图\n桌面 + 手机", 9.5, INK2)

s.notes_slide.notes_text_frame.text = (
    "（30 秒）这是 MCP 协议实跑，不是普通截图：脚本连上 @playwright/mcp，让它开 headless Chrome、"
    "导航线上页、读 console、截桌面和手机两张图。输出 Errors: 0。"
    "右边这张就是 MCP 自己截的。"
)


# ============================================================ 8 Loop 4 反馈
s = slide_base(8, "LOOP 4  ·  FEEDBACK → REGRESSION TEST", "两位朋友说题难——不降难度，改练习闭环")
rect(s, 0.82, 1.85, 11.65, 0.95, fill=CREAM, line_color=LINE, radius=0.04)
textbox(s, 1.05, 1.98, 11.2, 0.7,
        "“做题的题目有点难，除此之外没了。”  ——  两位组外朋友，线上链接试玩", 15, INK2, italic=True, line=1.35)

flow = [
    ("判断", "目标用户是中学生刷题\n不是普通玩家的休闲游戏"),
    ("不降难度", "题库按初中历史范围\n题目 / 计分 / 考试 0 改动"),
    ("错题本", "答错记入 · 下次温书优先重练\n答对即移出"),
    ("三条断言", "记入 / 优先抽 / 答对移出\n锁住这个学习闭环"),
]
for i, (head, body) in enumerate(flow):
    x = 0.82 + i * 2.95
    rect(s, x, 3.15, 2.62, 1.75, fill=CREAM if i < 3 else DARK,
         line_color=LINE if i < 3 else DARK, radius=0.05)
    color = INK if i < 3 else CREAM
    textbox(s, x + 0.18, 3.3, 2.25, 0.3, head, 14, RED if i < 3 else GOLD, True)
    textbox(s, x + 0.18, 3.72, 2.25, 1.0, body, 10.5, color, line=1.4)
    if i < 3:
        textbox(s, x + 2.66, 3.72, 0.25, 0.4, "→", 16, MUTED, True, align=PP_ALIGN.CENTER)

textbox(s, 0.82, 5.35, 11.6, 0.3, "改动只在练习环节；题目难度与考试计分完全没动。", 12, RED, True)
code_box(s, 0.82, 5.8, 11.6, 1.0, [
    "$ osascript -l JavaScript data_test.js | grep 错题",
    "PASS 答错的温书题记入错题本  ·  PASS 下次温书优先抽这道错题  ·  PASS 答对后移出错题本",
], size=9.5)

s.notes_slide.notes_text_frame.text = (
    "（40 秒）两位朋友在线上链接试玩，反馈只有一句：题目有点难。"
    "但这是给中学生刷题的，题库就是初中历史范围；他们不是目标用户。所以我没降难度。"
    "我把反馈转成学习闭环：错题本——答错的题下次温书优先重练，答对移出。三条断言锁住。"
)


# ============================================================ 9 真实困难
s = slide_base(9, "ONE CONCRETE DIFFICULTY", "7.9 MB 单文件，手机 4G 首屏 38 秒")
paras(s, 0.82, 1.9, 5.6, 2.0, [
    ("38.0 s", 46, RED, True, 0),
    ("DOMContentLoaded，Chrome 限速 4G 实测", 11, MUTED, False, 4),
], line=1.15)
paras(s, 0.82, 3.55, 5.6, 1.6, [
    ("↓  拆分 dist/ + WebP + Brotli", 15, GOLD, True, 0),
    ("1.45 s", 46, GREEN, True, 4),
    ("HTML 传输 162 KB → 61 KB", 11, MUTED, False, 4),
], line=1.15)
rect(s, 0.82, 5.5, 5.65, 1.35, fill=CREAM, line_color=LINE, radius=0.04)
textbox(s, 1.05, 5.66, 5.2, 0.3, "体积与传输", 10, RED, True)
textbox(s, 1.05, 6.0, 5.2, 0.45, "7.9 MB 单文件  →  158 KB dist HTML  →  61 KB Brotli", 10.5, INK2, False, MONO)
paras(s, 6.9, 1.9, 5.6, 4.4, [
    ("① 同一模板，两种产物", 14, INK, True, 0),
    ("单文件保留离线性；build.py --dist 输出外链 WebP，HTML 158 KB。", 11, INK2, False, 4),
    ("② 缓存与按需加载", 14, INK, True, 16),
    ("_headers 给 assets/* 加一年 immutable；走到哪一幕才加载哪张图。", 11, INK2, False, 4),
    ("③ 实测方法", 14, INK, True, 16),
    ("Playwright + CDP 限速 1.6 Mbps / 150 ms，不是估算。", 11, INK2, False, 4),
    ("顺带：全流程测试 12 次跑挂 7 次 → 固定种子 + 补属性 + 非零退出，三个种子稳定全绿。", 10.5, MUTED, False, 16),
], line=1.35)

s.notes_slide.notes_text_frame.text = (
    "（30 秒）一个真实困难：单文件 7.9 MB，手机 4G 首屏 38 秒。"
    "同一模板拆出 dist/，图片转 WebP 外链、加缓存，首屏 1.45 秒，HTML 从 162 KB 压到 61 KB。"
    "这是用 Playwright 加 CDP 限速实测的，不是估算。"
)


# ============================================================ 10 收尾
_PAGE[0] += 1
s = prs.slides.add_slide(prs.slide_layouts[6])
s.background.fill.solid(); s.background.fill.fore_color.rgb = DARK
textbox(s, 0.95, 0.85, 6.0, 0.3, "THANK YOU  ·  Q&A", 10.5, GOLD, True)
textbox(s, 0.9, 1.3, 11.6, 0.9, "四个闭环，都在跑", 40, CREAM, True)
textbox(s, 0.95, 2.35, 11.5, 0.4, "https://songgame.pages.dev/", 22, GOLD, True, MONO)
hline(s, 0.95, 3.05, 11.4, RGBColor(0x5A, 0x4E, 0x36), 1.0)
checks = [
    ("01", "Ideation", "plan.md + /goal + HTML 示意图"),
    ("02", "Tests", "pytest + JXA + Playwright，一条命令"),
    ("03", "Agent Browser", "@playwright/mcp 自己读 console / 截图"),
    ("04", "Feedback", "两位朋友 → 错题本 → 三条断言"),
]
for i, (num, head, body) in enumerate(checks):
    x = 0.95 + (i % 2) * 5.9
    y = 3.35 + (i // 2) * 1.55
    textbox(s, x, y, 0.55, 0.35, num, 12, GOLD, True)
    textbox(s, x + 0.6, y - 0.04, 4.9, 0.35, head, 17, CREAM, True)
    textbox(s, x + 0.6, y + 0.4, 4.9, 0.5, body, 11, RGBColor(0xC9, 0xBA, 0x9A))
textbox(s, 0.95, 6.6, 11.4, 0.3, "北宋赶考记 · 嘉祐二年  ·  谢谢", 10.5, RGBColor(0x9E, 0x8D, 0x6C))

s.notes_slide.notes_text_frame.text = (
    "（15 秒）四个闭环都在跑：计划与示意图、四层测试、MCP 浏览器、朋友反馈。谢谢，下面是 Q&A。"
)


# ============================================================ 11 备用 Q&A
s = slide_base(11, "BACKUP  ·  Q&A", "可能被问到的六个问题")
qa = [
    ("为什么不用 vitest？", "没有 JS 构建链：逻辑用 JXA 直调游戏函数，数据用 pytest，页面用 Playwright，三层都在 ./test.sh。"),
    ("题目为什么不标出处？", "四选一是通行知识，不是史料主张；引证集中在 57 条词条，年代边界用 afterCutoff。"),
    ("大儒能不能自由对话？", "现在是 15 个话题；半自由方案（意图匹配 + 记忆 + 人设）评估过，排在 Week 12。"),
    ("7.9 MB 单文件还有必要？", "它是离线承诺；线上走 dist/，同一模板两种产物，md5 对得上。"),
    ("MCP 具体帮了什么？", "让 agent 自己读 console、404、DOM 尺寸、截图，不用人肉转述。"),
    ("朋友说题难，为什么不改？", "目标用户是中学生刷题；难度不降，改用错题本把练习闭环补上。"),
]
for i, (q, a) in enumerate(qa):
    x = 0.82 + (i % 2) * 5.95
    y = 1.85 + (i // 2) * 1.62
    textbox(s, x, y, 5.6, 0.3, q, 13, RED, True)
    textbox(s, x, y + 0.38, 5.55, 1.0, a, 10.8, INK2, line=1.4)

s.notes_slide.notes_text_frame.text = "备用页：Q&A 时直接按这六条答，不要展开成新话题。"


# ============================================================ 12 备用命令
s = slide_base(12, "BACKUP  ·  COMMANDS", "终端里会跑的四条命令")
cmds = [
    ("./preflight.sh", "Node / Playwright / MCP / pytest / 线上 URL，全 ✓ 才上台"),
    ("./test.sh --e2e", "pytest 13 + JXA 45 / 73 / 54×3 + Playwright 7 + 模拟 180"),
    ("npm run check:mcp", "MCP 开 headless Chrome，读 console，截两张图"),
    ("osascript -l JavaScript data_test.js | grep 错题", "错题本三条断言"),
]
for i, (cmd, desc) in enumerate(cmds):
    y = 1.9 + i * 1.25
    rect(s, 0.82, y, 11.65, 1.0, fill=CREAM, line_color=LINE, radius=0.04)
    textbox(s, 1.05, y + 0.14, 7.4, 0.3, cmd, 11, RED, True, MONO)
    textbox(s, 1.05, y + 0.55, 11.1, 0.3, desc, 10.5, INK2)

s.notes_slide.notes_text_frame.text = "备用页：环境出问题时按顺序跑这四条。"

prs.save(OUT)
print("saved", OUT, len(prs.slides.__iter__.__self__._sldIdLst), "slides")
