#!/usr/bin/env bash
# 用語集をプロンプトに差し込んで翻訳する（LLM系エンジン: ollama / openai 等でのみ有効）
#   bash scripts/translate_with_glossary.sh <PDF> <出力ディレクトリ> [用語集ファイル]
# 用語集ファイルは「原語<TAB>訳語」または「原語,訳語」の1行1組
set -euo pipefail
PDF="${1:?PDFを指定してください}"
OUT="${2:?出力ディレクトリを指定してください}"
GLOSSARY="${3:-templates/03-用語集.md}"
PDF2ZH="${PDF2ZH:-.venv/bin/pdf2zh}"
SERVICE="${SERVICE:-ollama}"

mkdir -p "$OUT"

# 用語集から「原語 -> 訳語」の行を作る
terms=$(grep -oE '^\| *[^|]+ *\| *[^|]+ *\|' "$GLOSSARY" 2>/dev/null \
  | sed 's/^| *//; s/ *|$//; s/ *| */ -> /' \
  | grep -vE '^(原語|例）|-+ )' | head -40 || true)

PROMPT_FILE="$(mktemp)"
trap 'rm -f "$PROMPT_FILE"' EXIT
cat > "$PROMPT_FILE" <<PROMPT
You are a professional translator. Translate the following text from \${lang_in} to \${lang_out}.
Keep all formula markers, numbers, and citation brackets exactly as they are.
Use these fixed translations for the listed terms:
${terms}
Output only the translation.

\${text}
PROMPT

echo "用語集: $(echo "$terms" | grep -c . ) 件を適用します"
"$PDF2ZH" "$PDF" -li en -lo ja -s "$SERVICE" --prompt "$PROMPT_FILE" -o "$OUT"
