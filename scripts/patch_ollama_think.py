#!/usr/bin/env python3
"""pdf2zh の Ollama 翻訳に think=False を渡す（思考型モデル対策）。

gemma4 のような思考型モデルは、指定が無いと隠れた推論トークンを生成して
num_predict を食い潰し、遅くなる・応答が空になることがある。
pdf2zh 1.9.11 の OllamaTranslator は think を渡さないので、ここで足す。

  python3 scripts/patch_ollama_think.py .venv/lib/python3.10/site-packages/pdf2zh/translator.py
"""
import re, sys, shutil

path = sys.argv[1] if len(sys.argv) > 1 else "translator.py"
src = open(path, encoding="utf-8").read()
if "think=False" in src:
    print("already patched"); sys.exit(0)
old = """        response = self.client.chat(
            model=self.model,
            messages=self.prompt(text, self.prompt_template),
            options=self.options,
        )"""
new = """        response = self.client.chat(
            model=self.model,
            messages=self.prompt(text, self.prompt_template),
            options=self.options,
            think=False,  # 思考型モデル(gemma4等)の隠れ推論を止める
        )"""
if old not in src:
    print("NG: 対象コードが見つかりません（pdf2zhのバージョン差）"); sys.exit(1)
shutil.copy(path, path + ".bak")
open(path, "w", encoding="utf-8").write(src.replace(old, new))
print("patched:", path, "(backup: .bak)")
