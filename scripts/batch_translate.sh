#!/usr/bin/env bash
# フォルダ内のPDFをまとめて日本語に翻訳する。
#   bash scripts/batch_translate.sh <入力ディレクトリ> <出力ディレクトリ>
# 環境変数: PDF2ZH(実行ファイル) SERVICE(既定 ollama) THREAD(既定 4)
#   OLLAMA_HOST / OLLAMA_MODEL は呼び出し側で export しておく
set -uo pipefail
IN="${1:?入力ディレクトリを指定してください}"
OUT="${2:?出力ディレクトリを指定してください}"
PDF2ZH="${PDF2ZH:-.venv/bin/pdf2zh}"
SERVICE="${SERVICE:-ollama}"
THREAD="${THREAD:-4}"
LOG="$OUT/batch.log"

# 出力先は先に作る。pdf2zh は作らないので、無いと翻訳を全部終えた後に落ちる
mkdir -p "$OUT"
echo "=== $(date '+%F %T') 開始 service=$SERVICE thread=$THREAD ===" | tee -a "$LOG"

ok=0; skip=0; ng=0
# 1本ずつ直列で処理する。並列にするとGPUを取り合って全体が遅くなる
for f in "$IN"/*.pdf; do
  [ -e "$f" ] || { echo "PDFがありません: $IN"; exit 1; }
  base="$(basename "$f" .pdf)"
  if [ -f "$OUT/${base}-mono.pdf" ]; then
    echo "skip  $base (訳済み)" | tee -a "$LOG"; skip=$((skip+1)); continue
  fi
  s=$(date +%s)
  if "$PDF2ZH" "$f" -li en -lo ja -s "$SERVICE" -t "$THREAD" -o "$OUT" >>"$LOG" 2>&1; then
    e=$(date +%s)
    pages=$(pdfinfo "$OUT/${base}-mono.pdf" 2>/dev/null | awk '/^Pages/{print $2}')
    echo "OK    $base  $((e-s))秒  ${pages:-?}ページ" | tee -a "$LOG"; ok=$((ok+1))
  else
    echo "NG    $base  (詳細は $LOG)" | tee -a "$LOG"; ng=$((ng+1))
  fi
done

echo "=== 完了 成功$ok 済$skip 失敗$ng ===" | tee -a "$LOG"
[ "$ng" -eq 0 ]
