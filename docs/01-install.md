# 01 立てる

## 先に読む：素直に入れると起動しません（2026年9月時点）

`pip install pdf2zh` だけで入れると、実行時にこのエラーで落ちます。

```
ImportError: cannot import name 'TextTranslateRequest'
  from 'tencentcloud.tmt.v20180321.models'
```

原因は、pdf2zh が依存している `tencentcloud-sdk-python-tmt` に**バージョン指定が無い**ことです。2026年7月7日に出た 3.1.129 でクラス名が変わり、pdf2zh 1.9.11 が参照しているクラスが消えました。新しく入れた人ほど踏みます。

**対処**: 依存を1つ古いバージョンに固定します。当社が実機で動作を確認したのは 3.1.121 です。

```bash
pip install pdf2zh
pip install "tencentcloud-sdk-python-tmt==3.1.121"
pdf2zh --version    # pdf2zh v1.9.11 と出れば成功
```

同梱の `scripts/setup.sh` はこの固定を含めて実行します。

## 手順（Linux・Python）

```bash
python3 -m venv .venv
.venv/bin/pip install --upgrade pip
.venv/bin/pip install pdf2zh "tencentcloud-sdk-python-tmt==3.1.121"
.venv/bin/pdf2zh --version
```

- Python は 3.10 以上。
- **導入後のサイズは約1.3GB**です（PyTorch・ONNX・レイアウト解析モデルを含むため）。ディスクの空きを先に確認してください。
- 初回の翻訳実行時に、レイアウト解析モデルと日本語フォント（Source Han Serif JP）が自動でダウンロードされ、`~/.cache/babeldoc/` に置かれます。**閉じたネットワークで使う場合は、外に出られる環境で一度実行してから `~/.cache/babeldoc/` ごと持ち込みます**。

## 手順（Docker）

公式イメージを使う場合は同梱の `docker-compose.yml` を参照してください。GUI が 7860 番で開きます。社内に開く場合は `06-serve.md` を先に読んでください。

## 動作確認

```bash
mkdir -p out
.venv/bin/pdf2zh sample.pdf -li en -lo ja -s google -p 1 -o out
```

`out/sample-mono.pdf`（日本語のみ）と `out/sample-dual.pdf`（対訳）ができれば成功です。

> **出力先ディレクトリは自動で作られません。** `-o out` を指定する場合、`out` が無いと翻訳処理を全部終えた後に `FileNotFoundError` で落ちます。長い文書だと数分が無駄になるので、`mkdir -p` を先に実行してください。同梱のスクリプトはこれを含めています。
