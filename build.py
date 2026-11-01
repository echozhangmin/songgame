# -*- coding: utf-8 -*-
"""把题库注入模板，生成单文件可玩 HTML。

    python3 build.py            # 读 game.template.html + ../history-quiz/quiz_150.json
输出：
    北宋赶考记.html
模板里的占位符在生成时替换：
    __QUESTIONS__ / __GLOSSARY__   ← 题库与词条
    __SCENE_BG__                   ← assets/scene_bg.jpg（场景背景图，base64 内嵌）
    __SCROLL_IMG__                 ← assets/scroll.jpg（页眉画轴图，base64 内嵌）
"""
import base64
import json
import os
import re

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
        out.append({
            "id": q["id"],
            "era": q["era"],
            "stem": zh_quotes(q["stem"]),
            "options": {k: zh_quotes(v) for k, v in q["options"].items()},
            "answer": q["answer"],
            "explain": zh_quotes(q["explain"]),
        })
    return out


def write_glossary_md(glossary):
    """词条表：释义 + 出处，方便打印或贴进笔记。"""
    lines = ["# 北宋赶考记 · 词条表", "",
             f"共 {len(glossary)} 条。出处标“原文”者为原文引用，标“所述”者为据某书转述（未核到原文，只到书名/篇名一级）。", "",
             "| 词条 | 释义 | 出处 | 备注 |", "|---|---|---|---|"]
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
        lines.append(f"| **{clean(term)}** | {clean(g.get('def',''))} | {clean('；'.join(src))} | {clean(note)} |")
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
    return html.replace(token, b64, 1)


def main():
    qs = load_questions()
    if len(qs) != 150:
        raise SystemExit(f"题库条数异常：{len(qs)}")
    payload = json.dumps(qs, ensure_ascii=False, separators=(",", ":"))
    glossary = json.load(open(GLOSS, encoding="utf-8"))
    html = open(TEMPLATE, encoding="utf-8").read()
    if "__QUESTIONS__" not in html:
        raise SystemExit("模板缺少 __QUESTIONS__ 占位符")
    html = html.replace("__QUESTIONS__", payload, 1)
    html = html.replace("__GLOSSARY__", json.dumps(glossary, ensure_ascii=False, separators=(",", ":")), 1)
    html = embed_image(html, "__SCENE_BG__", SCENE_BG, "背景图")
    html = embed_image(html, "__SCROLL_IMG__", SCROLL, "画轴图")
    open(OUT, "w", encoding="utf-8").write(html)
    open(INDEX, "w", encoding="utf-8").write(html)
    print(f"题库注入：{len(qs)} 题")
    print(f"输出：{OUT}  ({os.path.getsize(OUT)/1024:.1f} KB)")
    print(f"输出：{INDEX}（Pages 入口）")
    print(f"词条：{len(glossary)} 条")
    write_glossary_md(glossary)


if __name__ == "__main__":
    main()
