#!/usr/bin/env python3
"""翻訳したPDFを機械で検査する。

  python3 scripts/check_quality.py <翻訳後PDF> [--source 原文PDF] [--json]

見るもの:
  - ページごとの日本語文字数（0のページは翻訳が抜けている可能性）
  - 原文とのページ数の一致
  - 数式・引用番号が残っているか
pdftotext(poppler-utils) が必要です。
"""
import argparse, json, re, shutil, subprocess, sys

JA = re.compile(r"[ぁ-んァ-ヶ一-龠]")
FORMULA = re.compile(r"[√∑∫±≤≥×÷αβγδθλμσω]|\b(softmax|max|min|log|exp)\b")
CITATION = re.compile(r"\[\d+\]")


def pages(path: str) -> int:
    out = subprocess.run(["pdfinfo", path], capture_output=True, text=True).stdout
    m = re.search(r"^Pages:\s+(\d+)", out, re.M)
    return int(m.group(1)) if m else 0


def text_of(path: str, page: int | None = None) -> str:
    cmd = ["pdftotext"]
    if page:
        cmd += ["-f", str(page), "-l", str(page)]
    cmd += [path, "-"]
    return subprocess.run(cmd, capture_output=True, text=True).stdout


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("translated")
    ap.add_argument("--source", default="")
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args()

    for tool in ("pdftotext", "pdfinfo"):
        if not shutil.which(tool):
            print(f"NG: {tool} がありません（apt install poppler-utils）"); return 2

    n = pages(a.translated)
    if n == 0:
        print("NG: ページ数を取得できません。PDFが壊れている可能性があります"); return 2

    per_page, empty = [], []
    for p in range(1, n + 1):
        t = text_of(a.translated, p)
        c = len(JA.findall(t))
        per_page.append(c)
        if c == 0:
            empty.append(p)

    whole = text_of(a.translated)
    res = {
        "file": a.translated,
        "pages": n,
        "japanese_chars": sum(per_page),
        "per_page": per_page,
        "empty_pages": empty,
        "formula_marks": len(FORMULA.findall(whole)),
        "citations": len(CITATION.findall(whole)),
    }
    if a.source:
        sp = pages(a.source)
        res["source_pages"] = sp
        res["pages_match"] = sp == n

    if a.json:
        print(json.dumps(res, ensure_ascii=False, indent=1))
    else:
        print(f"ファイル      : {res['file']}")
        print(f"ページ数      : {n}" + (f"（原文 {res['source_pages']} / "
              + ("一致" if res.get('pages_match') else "不一致") + "）" if a.source else ""))
        print(f"日本語文字数  : {res['japanese_chars']:,}")
        print(f"数式の記号    : {res['formula_marks']}  引用番号: {res['citations']}")
        print("ページ別      : " + " ".join(f"p{i+1}:{c}" for i, c in enumerate(per_page)))
        if empty:
            print(f"⚠ 日本語が0のページ: {empty}")
            print("  参考文献・図版だけのページなら正常です。本文のページなら翻訳が抜けています。")
        else:
            print("✓ すべてのページに日本語があります")

    # 本文ページの半分以上が空なら失敗扱い
    return 1 if len(empty) > n / 2 else 0


if __name__ == "__main__":
    sys.exit(main())
