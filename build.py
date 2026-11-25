# -*- coding: utf-8 -*-
"""把题库注入模板，生成单文件可玩 HTML。

    python3 build.py            # 读 game.template.html + ../history-quiz/quiz_150.json
输出：
    北宋赶考记.html
模板里的占位符在生成时替换：
    __QUESTIONS__ / __GLOSSARY__   ← 题库与词条
    __SCENE_BG__                   ← assets/scene_bg.jpg（共用场景背景，base64 内嵌）
    __SCENE_ART__                  ← assets/scene_<场景id>.jpg（分场景插图，按文件名内嵌成 JS 表）
    __SCROLL_IMG__                 ← assets/scroll.jpg（页眉画轴图，base64 内嵌，替换全部出现处）
"""
import base64
import json
import os
import re
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TEMPLATE = os.path.join(HERE, "game.template.html")
GLOSS = os.path.join(HERE, "data", "glossary.json")
BANK = os.path.join(HERE, "data", "quiz_150.json")
if not os.path.exists(BANK):
    BANK = os.path.join(HERE, "..", "history-quiz", "quiz_150.json")
SCENE_BG = os.path.join(HERE, "assets", "scene_bg.jpg")
SCROLL = os.path.join(HERE, "assets", "scroll.jpg")
OUT = os.path.join(HERE, "北宋赶考记.html")
INDEX = os.path.join(HERE, "index.html")   # GitHub Pages 入口
DIST = os.path.join(HERE, "dist")          # Cloudflare Pages 发布目录
SITE_URL = os.environ.get("SITE_URL", "https://songgame.pages.dev").rstrip("/")
OG_FONT = "/System/Library/Fonts/Supplemental/Songti.ttc"


QUOTE_RE = re.compile(r"'([^']*)'")


def zh_quotes(text: str) -> str:
    """把题库里的 ASCII 单引号转成中文引号，避免版面出现 'xxx' 这种洋标点。"""
    prev = None
    while prev != text:
        prev = text
        text = QUOTE_RE.sub(r"“\1”", text)
    return text


def load_questions():
    data = json.load(open(BANK, encoding="utf-8"))
    out = []
    for q in data:
        item = {
            "id": q["id"],
            "era": q["era"],
            "stem": zh_quotes(q["stem"]),
            "options": {k: zh_quotes(v) for k, v in q["options"].items()},
            "answer": q["answer"],
            "explain": zh_quotes(q["explain"]),
        }
        # 史事晚于嘉祐二年（1057）的题：只能作"后世追述"，不进省试/殿试抽题池
        if q.get("afterCutoff"):
            item["afterCutoff"] = int(q["afterCutoff"])
        out.append(item)
    return out


def write_glossary_md(glossary):
    """词条表：释义 + 出处，方便打印或贴进笔记。"""
    n_ju = sum(1 for g in glossary.values() if g.get("tag") == "据")
    n_tui = sum(1 for g in glossary.values() if g.get("tag") == "推断")
    n_she = sum(1 for g in glossary.values() if g.get("tag") == "设")
    lines = ["# 北宋赶考记 · 词条表", "",
             f"共 {len(glossary)} 条：据（有原文可引）{n_ju} 条、推断（据书名/篇名转述）{n_tui} 条、设（游戏设定）{n_she} 条。"
             "标注“原文”者是原文引用，标注“所述”者只到书名/篇名一级，未核到原文。", "",
             "| 词条 | 档 | 释义 | 出处 | 备注 |", "|---|---|---|---|---|"]
    for term, g in glossary.items():
        src = []
        for x in g.get("src", []):
            if x.get("quote"):
                src.append(f"{x['book']}原文：“{x['quote']}”")
            else:
                src.append(f"{x['book']}所述：{x.get('gist','')}")
        note = g.get("note", "")
        def clean(t):
            return str(t).replace("|", "／").replace("\n", " ")
        lines.append(f"| **{clean(term)}** | {clean(g.get('tag',''))} | {clean(g.get('def',''))} | {clean('；'.join(src))} | {clean(note)} |")
    lines.append("")
    path = os.path.join(HERE, "词条表.md")
    open(path, "w", encoding="utf-8").write("\n".join(lines))
    print(f"输出：{path}")


def embed_image(html, token, path, label):
    """把图片文件以 base64 塞进模板占位符，保持单文件 HTML。"""
    if token not in html:
        return html
    if not os.path.exists(path):
        raise SystemExit(f"模板里有 {token} 占位符，但找不到{label}：" + path)
    b64 = base64.b64encode(open(path, "rb").read()).decode("ascii")
    print(f"{label}内嵌：{os.path.relpath(path, HERE)}（{os.path.getsize(path)/1024:.0f} KB）")
    return html.replace(token, b64)


def load_scene_art():
    """assets/scene_<场景id>.jpg → {id: dataURI}；scene_bg.jpg 是共用底图，不在此列。

    文件名约定：场景 id 见模板 SCENES（jiaxu/changting/yizhan/shandao/bianhe/
    hongqiao/chengmen/jiulou/shuku/gongyuan/fangbang）。两段汴河共用 bianhe 一张。
    """
    arts = {}
    d = os.path.join(HERE, "assets")
    for fn in sorted(os.listdir(d)):
        m = re.match(r"scene_([A-Za-z0-9_]+)\.(jpe?g|png)$", fn)
        if not m or m.group(1) == "bg":
            continue
        mime = "image/png" if m.group(2) == "png" else "image/jpeg"
        raw = open(os.path.join(d, fn), "rb").read()
        arts[m.group(1)] = f"data:{mime};base64," + base64.b64encode(raw).decode("ascii")
        print(f"场景图内嵌：{fn}（{len(raw)/1024:.0f} KB）")
    return arts



# ---------------------------------------------------------------- dist 拆分版

def export_webp(src, out_base, max_w=1500, quality=76):
    """JPEG → WebP（有 Pillow 时）；没有 Pillow 就退回原图拷贝。返回 (相对路径, 字节数)。"""
    try:
        from PIL import Image
    except ImportError:
        ext = os.path.splitext(src)[1].lower()
        dst = out_base + ext
        shutil.copyfile(src, dst)
        return "assets/" + os.path.basename(dst), os.path.getsize(dst)
    im = Image.open(src).convert("RGB")
    if im.width > max_w:
        im = im.resize((max_w, round(im.height * max_w / im.width)), Image.LANCZOS)
    dst = out_base + ".webp"
    im.save(dst, "WEBP", quality=quality, method=6)
    return "assets/" + os.path.basename(dst), os.path.getsize(dst)


def make_og(path, bg=SCENE_BG):
    """1200×630 分享卡；缺字体/缺 Pillow 时静默跳过。"""
    try:
        from PIL import Image, ImageDraw, ImageFont, ImageFilter
        W, H = 1200, 630
        src = Image.open(bg).convert("RGB")
        r = max(W / src.width, H / src.height)
        im = src.resize((round(src.width * r), round(src.height * r)), Image.LANCZOS)
        x, y = (im.width - W) // 2, (im.height - H) // 2
        im = im.crop((x, y, x + W, y + H)).filter(ImageFilter.GaussianBlur(1.2))
        im = Image.blend(im, Image.new("RGB", (W, H), (35, 28, 18)), 0.52)
        d = ImageDraw.Draw(im)
        title = ImageFont.truetype(OG_FONT, 108)
        sub = ImageFont.truetype(OG_FONT, 36)
        small = ImageFont.truetype(OG_FONT, 26)
        seal = ImageFont.truetype(OG_FONT, 44)
        d.text((84, 150), "北宋赶考记", font=title, fill=(240, 232, 210))
        d.text((88, 292), "嘉祐二年 · 三十日赴京赶考", font=sub, fill=(214, 200, 170))
        d.text((88, 366), "省试 · 殿试 · 放榜 ｜ 单文件 HTML 科举模拟", font=small, fill=(190, 176, 148))
        d.rectangle([980, 120, 1110, 250], outline=(166, 58, 44), width=5)
        d.text((1002, 158), "嘉祐", font=seal, fill=(176, 70, 54))
        d.line([(84, 470), (W - 84, 470)], fill=(150, 130, 96), width=1)
        d.text((88, 496), "临川 → 汴京 ｜ 1057 ｜ 无外部依赖，双击即玩", font=small, fill=(180, 168, 142))
        im.save(path, "JPEG", quality=88, optimize=True, progressive=True)
        return True
    except Exception as e:
        print(f"（跳过分享卡：{e}）")
        return False


def build_dist(html, glossary):
    """把同一份模板改成"外链资源 + 缓存头"的静态站，供 Cloudflare Pages 发布。"""
    assets = os.path.join(DIST, "assets")
    os.makedirs(assets, exist_ok=True)
    total = 0

    bg_rel, bg_size = export_webp(SCENE_BG, os.path.join(assets, "scene_bg"))
    scroll_rel, scroll_size = export_webp(SCROLL, os.path.join(assets, "scroll"))
    total += bg_size + scroll_size

    html = html.replace("data:image/jpeg;base64,__SCENE_BG__", bg_rel)
    html = html.replace("data:image/jpeg;base64,__SCROLL_IMG__", scroll_rel)

    arts = {}
    d = os.path.join(HERE, "assets")
    for fn in sorted(os.listdir(d)):
        m = re.match(r"scene_([A-Za-z0-9_]+)\.(jpe?g|png)$", fn)
        if not m or m.group(1) == "bg":
            continue
        rel, size = export_webp(os.path.join(d, fn), os.path.join(assets, "scene_" + m.group(1)))
        arts[m.group(1)] = rel
        total += size
    html = html.replace("__SCENE_ART__", json.dumps(arts, ensure_ascii=False, separators=(",", ":")))

    # 分享卡与 canonical 指向线上域名（SITE_URL 可覆盖）
    html = html.replace("https://echozhangmin.github.io/songgame", SITE_URL)
    for token in ("__SCENE_BG__", "__SCROLL_IMG__", "__SCENE_ART__", "__QUESTIONS__", "__GLOSSARY__"):
        if token in html:
            raise SystemExit(f"dist 里残留占位符：{token}")

    out = os.path.join(DIST, "index.html")
    open(out, "w", encoding="utf-8").write(html)
    make_og(os.path.join(DIST, "og.jpg"))

    headers = """# Cloudflare Pages 缓存策略
/assets/*
  Cache-Control: public, max-age=31536000, immutable
/index.html
  Cache-Control: public, max-age=600
/og.jpg
  Cache-Control: public, max-age=86400
"""
    open(os.path.join(DIST, "_headers"), "w", encoding="utf-8").write(headers)
    total += os.path.getsize(out)
    print(f"输出：{out}（{os.path.getsize(out)/1024:.1f} KB）")
    print(f"输出：{assets}（{len(arts)+2} 个资源，{total/1024:.1f} KB）")
    print(f"线上域名（og/canonical）：{SITE_URL}")


def main():
    qs = load_questions()
    if len(qs) != 150:
        raise SystemExit(f"题库条数异常：{len(qs)}")
    payload = json.dumps(qs, ensure_ascii=False, separators=(",", ":"))
    glossary = json.load(open(GLOSS, encoding="utf-8"))
    base = open(TEMPLATE, encoding="utf-8").read()
    if "__QUESTIONS__" not in base:
        raise SystemExit("模板缺少 __QUESTIONS__ 占位符")
    if "__SCENE_ART__" not in base:
        raise SystemExit("模板缺少 __SCENE_ART__ 占位符")
    base = base.replace("__QUESTIONS__", payload, 1)
    base = base.replace("__GLOSSARY__", json.dumps(glossary, ensure_ascii=False, separators=(",", ":")), 1)

    # 单文件版：图片全部 base64 内嵌，双击即玩
    single = embed_image(base, "__SCENE_BG__", SCENE_BG, "背景图")
    single = embed_image(single, "__SCROLL_IMG__", SCROLL, "画轴图")
    single = single.replace("__SCENE_ART__", json.dumps(load_scene_art(), ensure_ascii=False, separators=(",", ":")))
    open(OUT, "w", encoding="utf-8").write(single)
    open(INDEX, "w", encoding="utf-8").write(single)

    print(f"题库注入：{len(qs)} 题")
    print(f"输出：{OUT}  ({os.path.getsize(OUT)/1024:.1f} KB)")
    print(f"输出：{INDEX}（Pages 入口）")
    print(f"词条：{len(glossary)} 条")
    write_glossary_md(glossary)

    if "--dist" in sys.argv:
        build_dist(base, glossary)


if __name__ == "__main__":
    main()
