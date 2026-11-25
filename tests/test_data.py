"""数据与史料边界测试（pytest）。

与 data_test.js 的分工：
- 这里用 Python 直接读源数据，守"结构、出处三档、1057 截断、产物完整性"；
- data_test.js 还会在 JS 运行时里验证抽题池、旧档迁移等行为。
两者跑的是同一批事实，但入口不同，任何一个都能在 1 秒内拦住数据被改坏。

运行：
    source .venv/bin/activate && pytest -q
"""
from __future__ import annotations

import json
import re
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
QUIZ = json.loads((ROOT / "data" / "quiz_150.json").read_text(encoding="utf-8"))
GLOSS = json.loads((ROOT / "data" / "glossary.json").read_text(encoding="utf-8"))
TEMPLATE = (ROOT / "game.template.html").read_text(encoding="utf-8")
BUILT = ROOT / "北宋赶考记.html"
COUNT_TAG = {"据": 0, "推断": 0, "设": 0}
for entry in GLOSS.values():
    COUNT_TAG[entry["tag"]] += 1


# ---------------------------------------------------------------- 题库结构

def test_quiz_has_150_well_formed_questions():
    assert len(QUIZ) == 150
    ids = [q["id"] for q in QUIZ]
    stems = [q["stem"] for q in QUIZ]
    assert len(set(ids)) == 150, "题号重复"
    assert len(set(stems)) == 150, "题干重复"
    for q in QUIZ:
        assert set(q["options"]) == {"A", "B", "C", "D"}, q["id"]
        assert q["answer"] in q["options"], q["id"]
        assert q["era"] in {"先秦", "秦汉", "魏晋南北朝", "隋唐", "五代与北宋"}, q["id"]
        assert q.get("explain"), q["id"]


def test_only_six_questions_are_marked_after_1057():
    late = {q["id"]: q["afterCutoff"] for q in QUIZ if q.get("afterCutoff")}
    assert late == {132: 1069, 135: 1084, 144: 1069, 145: 1069, 147: 1088, 148: 1100}
    assert all(year > 1057 for year in late.values())


def test_exam_pools_filter_the_cutoff():
    # 三场省试与殿试都必须走 usable()，否则 1069 年的题会穿进 1057 年的考场
    pools = re.search(r"const EXAM_POOLS = \[(.*?)\];", TEMPLATE, re.S)
    assert pools, "找不到 EXAM_POOLS"
    entries = [line.strip() for line in pools.group(1).splitlines() if line.strip().startswith("q =>")]
    assert len(entries) == 3
    assert all("usable(q)" in line for line in entries), entries
    assert TEMPLATE.count("pickQuestion(usable)") == 2, "省试/殿试应各有一处 usable 过滤"
    assert "const CUTOFF_YEAR = 1057;" in TEMPLATE


# ---------------------------------------------------------------- 词条三档

def test_glossary_has_57_entries_with_source_and_tier():
    assert len(GLOSS) == 57
    for term, entry in GLOSS.items():
        assert entry.get("def"), term
        assert entry.get("src"), term
        assert entry.get("tag") in {"据", "推断", "设"}, term


def test_quote_implies_ju_and_no_quote_never_claims_ju():
    for term, entry in GLOSS.items():
        has_quote = any(src.get("quote") for src in entry["src"])
        if has_quote:
            assert entry["tag"] == "据", f"{term} 有原文却未标据"
        else:
            assert entry["tag"] != "据", f"{term} 无原文却标据"


def test_tier_counts_are_stable():
    assert COUNT_TAG == {"据": 5, "推断": 49, "设": 3}


def test_glossary_markdown_matches_json():
    md = (ROOT / "词条表.md").read_text(encoding="utf-8")
    assert f"共 {len(GLOSS)} 条" in md
    for term, entry in GLOSS.items():
        assert f"| **{term}** | {entry['tag']} |" in md, term


# ---------------------------------------------------------------- 场景与产物

def test_twelve_scenes_each_have_art_or_a_known_fallback():
    ids = re.findall(r"\{id:'([a-z]+)', name:'", TEMPLATE)
    assert len(ids) == 12
    assets = ROOT / "assets"
    missing = [sid for sid in ids if sid != "jiaxu" and not (assets / f"scene_{sid}.jpg").exists()]
    assert missing == [], f"缺场景图：{missing}"


def test_single_file_build_is_complete():
    assert BUILT.exists(), "先运行 python3 build.py"
    html = BUILT.read_text(encoding="utf-8")
    for token in ("__QUESTIONS__", "__GLOSSARY__", "__SCENE_BG__", "__SCENE_ART__", "__SCROLL_IMG__"):
        assert token not in html, f"残留占位符 {token}"
    assert "<title>北宋赶考记 · 嘉祐二年</title>" in html
    assert 'rel="icon"' in html
    assert 'property="og:image"' in html
    assert "data:image/jpeg;base64," in html, "单文件版必须内嵌图片"


def test_dist_package_references_only_existing_assets():
    dist = ROOT / "dist"
    index = dist / "index.html"
    if not index.exists():
        pytest.skip("未生成 dist/（python3 build.py --dist）")
    html = index.read_text(encoding="utf-8")
    refs = sorted(set(re.findall(r"assets/[A-Za-z0-9_.-]+\.webp", html)))
    assert refs, "dist 没有任何 WebP 资源"
    for ref in refs:
        assert (dist / ref).exists(), f"缺资源 {ref}"
    assert (dist / "_headers").exists()
    assert (dist / "og.jpg").exists()
    assert "data:image/jpeg;base64," not in html, "dist 不应再内嵌大图"


# ---------------------------------------------------------------- 设计约束

def test_save_schema_is_versioned_and_merged():
    assert "const SAVE_VERSION = 4;" in TEMPLATE
    assert "Object.assign(freshState(), g)" in TEMPLATE, "旧档必须补默认字段"
    assert "if (g.v && g.v > SAVE_VERSION) return null;" in TEMPLATE


def test_demo_documents_exist():
    for name in ("plan.md", "evidence.md", "architecture-explainer.html", "user-feedback.md"):
        path = ROOT / "docs" / name
        assert path.exists() and path.stat().st_size > 200, name
    assert (ROOT / "questions.md").exists()
    assert (ROOT / "AGENTS.md").exists()


def test_mcp_and_playwright_are_configured():
    config = json.loads((ROOT / "opencode.json").read_text(encoding="utf-8"))
    assert "playwright" in config["mcp"]
    deps = json.loads((ROOT / "package.json").read_text(encoding="utf-8"))["devDependencies"]
    assert "@playwright/test" in deps
    assert "@playwright/mcp" in deps
    assert (ROOT / "tests" / "e2e.spec.ts").exists()
