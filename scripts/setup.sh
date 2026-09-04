#!/usr/bin/env bash
# PDF翻訳(pdf2zh)を入れる。依存の固定を含む。
#   bash scripts/setup.sh [インストール先ディレクトリ]
set -euo pipefail
DIR="${1:-$(pwd)}"
cd "$DIR"

echo "== Python venv =="
python3 -m venv .venv
.venv/bin/pip install --quiet --upgrade pip

echo "== pdf2zh =="
.venv/bin/pip install --quiet pdf2zh

# 【重要】依存の固定。tencentcloud-sdk-python-tmt 3.1.129(2026-07-07) で
# pdf2zh が参照するクラスが消え、ImportError で起動しなくなる。
echo "== 依存の固定 (tencentcloud-sdk-python-tmt) =="
.venv/bin/pip install --quiet "tencentcloud-sdk-python-tmt==3.1.121"

echo "== 動作確認 =="
.venv/bin/pdf2zh --version

cat <<'MSG'

導入できました。次にやること:

1. 翻訳エンジンを決める      → docs/02-translation-service.md
2. ローカルLLMを使うなら     → docs/03-local-llm.md
   （思考型モデルなら think=False の修正を必ず当てる）
   python3 scripts/patch_ollama_think.py .venv/lib/python3.10/site-packages/pdf2zh/translator.py
3. 1ページで試す
   mkdir -p out && .venv/bin/pdf2zh sample.pdf -li en -lo ja -p 1 -o out
MSG
