# 02 翻訳エンジンを選ぶ

PDFMathTranslate は「レイアウトを解析して、本文を翻訳エンジンに渡し、元の位置に戻す」道具です。**翻訳の品質と機密性は、どのエンジンを選ぶかで決まります**。ここが導入の分かれ道です。

## 選択肢の比較

| エンジン | 指定 | 文書が社外に出るか | 費用 | 品質 | 必要なもの |
|---|---|---|---|---|---|
| **自社サーバーのローカルLLM** | `-s ollama` | **出ない** | **0円** | 高い | GPU搭載サーバー1台 |
| 完全オフライン（Argos Translate） | `-s argos` | **出ない** | **0円** | 中程度 | なし（CPUのみ） |
| DeepL | `-s deepl` | 出る | 従量課金 | 高い | APIキー |
| OpenAI 等のLLM API | `-s openai` | 出る | 従量課金 | 高い | APIキー |
| Google 翻訳（既定） | `-s google` | 出る | 無料 | 中程度 | なし |

`-s` を省くと **Google 翻訳が既定**です。試すぶんには手軽ですが、社内文書をそのまま流さないでください。

## 判断の順番

1. **その文書は社外に出してよいか**。未公開の仕様書・図面・契約書・顧客資料なら、上2つのどちらかに限定されます。
2. **GPUのあるサーバーがあるか**。あれば `ollama`（品質・速度とも実用）。無ければ `argos`（品質は落ちるが完全オフライン）。
3. **社外に出してよい公開文書だけ**なら、DeepL や OpenAI が手軽です。ただしページ数×文字数で課金されます。

## ローカルLLM と オフライン翻訳の品質差（当社の実測）

同じ英文を訳した結果です。

原文: *The Transformer allows for significantly more parallelization and can reach a new state of the art in translation quality.*

| エンジン | 出力 | 所要 |
|---|---|---|
| ローカルLLM（gemma4 12B） | Transformerは、はるかに高い並列化を可能にし、翻訳品質において新たな最高水準に到達できます。 | 約4秒 |
| Argos Translate（オフライン） | トランスは、より多くの並列化を可能にし、翻訳品質の新しい状態に到達することができます。 | 4.33秒 |

Argos は「Transformer」を「トランス」と訳し、"state of the art" を直訳しています。**固有名詞と専門用語が崩れる**のがオフライン翻訳の弱点です。用語集（`05-operation-design.md`）で補うか、GPUを用意してローカルLLMにしてください。

### Argos Translate（完全オフライン）の導入

```bash
.venv/bin/pip install argostranslate
.venv/bin/python -c "
import argostranslate.package as p
p.update_package_index()
pkg=[x for x in p.get_available_packages() if x.from_code=='en' and x.to_code=='ja'][0]
p.install_from_path(pkg.download())
print('en->ja model installed')"
```

当社環境ではモデルの導入は4秒で終わりました。以後、ネットワークに一切出ずに翻訳できます。ライセンスは **MIT** なので、AGPL を避けたい構成でも使えます。

## クラウドAPIを使う場合の設定

環境変数で渡します。`~/.config/PDFMathTranslate/config.json` に書くこともできます。

```bash
# DeepL
export DEEPL_AUTH_KEY="..."
pdf2zh doc.pdf -li en -lo ja -s deepl -o out

# OpenAI互換（BASE_URL は必ず /v1 で終える。忘れると404になります）
export OPENAI_BASE_URL="https://api.openai.com/v1"
export OPENAI_API_KEY="..."
export OPENAI_MODEL="gpt-4o-mini"
pdf2zh doc.pdf -li en -lo ja -s openai -o out
```

**費用の見積もり**: 翻訳されるのは本文のテキストだけで、数式・図・参考文献の一部は対象外です。当社の実測では15ページの論文で約2万文字が翻訳対象でした。従量課金のAPIを使う場合は、この文字数で試算してください。ローカルLLMなら文字数に関係なく0円です。
