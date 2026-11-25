#!/usr/bin/env python3
"""Convert paper/evidence.csv (or data/evidence.csv) into paper/evidence-table.tex."""
import csv
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
SRC = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else HERE / "evidence.csv"
OUT = pathlib.Path(sys.argv[2]) if len(sys.argv) > 2 else HERE / "evidence-table.tex"

ESCAPES = str.maketrans({
    "&": r"\&",
    "%": r"\%",
    "$": r"\$",
    "#": r"\#",
    "_": r"\_",
    "{": r"\{",
    "}": r"\}",
    "~": r"\textasciitilde{}",
    "^": r"\textasciicircum{}",
})


def tex_escape(val: str) -> str:
    return val.strip().replace("\\", r"\textbackslash{}").translate(ESCAPES)


with SRC.open(newline="", encoding="utf-8") as f:
    rows = list(csv.DictReader(f))

required = ("claim", "evidence", "locator", "level", "limit")
if not rows or any(col not in rows[0] for col in required):
    raise SystemExit(f"Expected CSV columns: {', '.join(required)} in {SRC}")

HEADER = r"  \textbf{Claim / Element} & \textbf{Source / File} & \textbf{Locator} & \textbf{Level} & \textbf{Boundary / Limit} \\"

lines = [
    f"% Auto-generated from {SRC.name} by make_evidence_table.py — edit the CSV, not this file.",
    r"\begin{longtable}{p{0.24\textwidth}p{0.18\textwidth}p{0.12\textwidth}p{0.07\textwidth}p{0.19\textwidth}}",
    r"\caption{Claims and design elements with locators, evidence tiers (\emph{ju} 据 documented, \emph{tui} 推断 inferred, \emph{she} 设 invented), and limits.}\label{tab:evidence}\\",
    r"\toprule",
    HEADER,
    r"\midrule",
    r"\endfirsthead",
    r"\multicolumn{5}{l}{\footnotesize\itshape Table \thetable\ (continued)}\\",
    r"\toprule",
    HEADER,
    r"\midrule",
    r"\endhead",
    r"\bottomrule",
    r"\endfoot",
]
for r in rows:
    cells = " & ".join(tex_escape(r[c]) for c in required)
    lines.append(f"  {cells} \\\\")
lines.extend([r"\end{longtable}", ""])

OUT.write_text("\n".join(lines), encoding="utf-8")
print(f"Wrote {OUT} ({len(rows)} rows from {SRC})")
