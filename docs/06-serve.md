# 06 社内に開く

## GUI を立てる

`pdf2zh -i` でブラウザから使える画面が開きます（既定 7860 番）。ファイルをドラッグして翻訳できるので、コマンドを打てない部署にも配れます。

```bash
.venv/bin/pdf2zh -i
```

## 常駐させる（systemd）

同梱の `templates/pdf2zh.service` を使います。要点は次の3つです。

- **社内ネットワークだけに開く**。`pdf2zh` の GUI に認証はありません。全社に開くならリバースプロキシで Basic 認証を付けてください
- 環境変数（`OLLAMA_HOST`・`OLLAMA_MODEL`・APIキー）は `EnvironmentFile` で外に出す。**ユニットファイルに直接書かない**
- 作業ディレクトリと出力先を固定し、ディスクの空きを監視する（対訳PDFは元の1.5〜2倍の大きさになります）

```bash
cp templates/pdf2zh.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now pdf2zh
```

## nginx で社内に公開する

`templates/nginx-pdf2zh.conf` を参照してください。大きなPDFを扱うので、次の2つを必ず変えます。

```nginx
client_max_body_size 100M;   # 既定の1MBだとPDFが上がりません
proxy_read_timeout 1800;     # 長い文書は数分かかります
```

## 更新するとき

```bash
.venv/bin/pip install -U pdf2zh
.venv/bin/pip install "tencentcloud-sdk-python-tmt==3.1.121"   # 固定を維持する
python3 scripts/patch_ollama_think.py .venv/lib/python3.10/site-packages/pdf2zh/translator.py
```

**更新すると、依存の固定と think=False の修正が両方とも消えます**。更新後は必ずこの2つを当て直し、1ページの翻訳で動作を確認してください。

## バックアップ

翻訳結果は再生成できるので、バックアップの対象は次の3つで足ります。

- 用語集・除外パターンの設定
- `~/.config/PDFMathTranslate/config.json`（翻訳エンジンの設定）
- 翻訳の記録（どの文書をいつ訳したか）

モデルのキャッシュ（`~/.cache/babeldoc/`・約1GB）は再取得できますが、閉じたネットワークではこれもバックアップに含めてください。
