# -*- coding: utf-8 -*-
"""把题库注入模板，生成单文件可玩 HTML。

    python3 build.py            # 读 game.template.html + ../history-quiz/quiz_150.json
输出：
    北宋赶考记.html
"""
import json
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
TEMPLATE = os.path.join(HERE, "game.template.html")
BANK = os.path.join(HERE, "data", "quiz_150.json")
if not os.path.exists(BANK):
    BANK = os.path.join(HERE, "..", "history-quiz", "quiz_150.json")
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


def main():
    qs = load_questions()
    if len(qs) != 150:
        raise SystemExit(f"题库条数异常：{len(qs)}")
    payload = json.dumps(qs, ensure_ascii=False, separators=(",", ":"))
    html = open(TEMPLATE, encoding="utf-8").read()
    if "__QUESTIONS__" not in html:
        raise SystemExit("模板缺少 __QUESTIONS__ 占位符")
    html = html.replace("__QUESTIONS__", payload, 1)
    open(OUT, "w", encoding="utf-8").write(html)
    open(INDEX, "w", encoding="utf-8").write(html)
    print(f"题库注入：{len(qs)} 题")
    print(f"输出：{OUT}  ({os.path.getsize(OUT)/1024:.1f} KB)")
    print(f"输出：{INDEX}（Pages 入口）")


if __name__ == "__main__":
    main()
