# PDFMathTranslate 日本語導入・運用キット

英語のPDF（論文・技術文書・海外メーカーの仕様書）を、**レイアウト・数式・図表を保ったまま日本語にする**仕組みを自社サーバーに立てるためのキットです。土台はオープンソースの [PDFMathTranslate](https://github.com/Byaidu/PDFMathTranslate)（`pdf2zh`・AGPL-3.0・GitHubスター約36,700）。

**翻訳の中身を外部に送らない構成**（自社サーバーのローカルLLM、または完全オフライン）を選べます。未公開の仕様書・契約書・顧客資料を翻訳したい会社向けです。

## 当社の実測（2026年9月）

| 項目 | 実測値 |
|---|---|
| 対象 | 英語の学術論文 15ページ・2.2MB（数式・表・図つき） |
| 翻訳時間 | **179秒（約3分）／11秒・ページ** |
| エンジン | 自社サーバーのローカルLLM（GPU1枚） |
| 追加費用 | **0円** |
| 保持 | 数式・図表・箇条書き・節番号・式番号・引用番号 |

## 中身

```
docs/        手順書 8章（00 全体像 → 07 トラブルシューティング）
templates/   テンプレート5点 ＋ systemd unit ＋ nginx 設定
scripts/     導入・思考型モデル対策・一括翻訳・用語集適用・品質チェック
docker-compose.yml
```

## 最短の始め方

```bash
bash scripts/setup.sh .
export OLLAMA_HOST="http://<翻訳サーバー>:11434" OLLAMA_MODEL="gemma3:12b"
python3 scripts/patch_ollama_think.py .venv/lib/python3.10/site-packages/pdf2zh/translator.py
mkdir -p out
.venv/bin/pdf2zh sample.pdf -li en -lo ja -s ollama -p 1 -o out
python3 scripts/check_quality.py out/sample-mono.pdf --source sample.pdf
```

**先に `docs/01-install.md` を読んでください。** 素直に `pip install pdf2zh` すると、依存パッケージの破壊的更新（2026年7月）で起動しません。回避方法を書いています。

## このキットが解く問題

当社が実機で踏んで、解決したものです。

1. `pip install` しただけでは起動しない（依存の固定が必要）
2. 思考型モデルを使うと**5.8倍遅くなる**（81秒→14秒／ページ・当社実測）
3. 出力先ディレクトリを作らないと、翻訳を全部終えた後に落ちる
4. `-lo` を指定しないと中国語になる
5. `-p 3` は「1〜3ページ」ではなく「3ページ目だけ」
6. 社内に開くときの認証・アップロード上限・タイムアウト
7. 更新すると1と2の対策が両方消える

## ライセンス

- PDFMathTranslate 本体は **AGPL-3.0**。自社サーバーに置いて自社で使う分に公開義務はありません。**社外にサービスとして提供する場合は条件があります**（`docs/00-overview.md`）
- 本キット（手順書・テンプレート・スクリプト）は購入者の社内利用に限ります。再配布不可
- オフライン翻訳に使う Argos Translate は MIT

---
株式会社エクスブリッジ https://exbridge.jp/
