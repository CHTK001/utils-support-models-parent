#!/usr/bin/env python3
"""下载 Piper TTS 中文语音合成 ONNX 模型文件。"""
import os, ssl, urllib.request
from pathlib import Path

ssl_ctx = ssl.create_default_context()
ssl_ctx.check_hostname = False
ssl_ctx.verified_mode = ssl.CERT_NONE

FILES = [
    ("https://huggingface.co/speaches-ai/piper-zh_CN-huayan-x_low/resolve/main/model.onnx",
     "audio/tts/piper/zh_CN-huayan/model.onnx"),
    ("https://huggingface.co/speaches-ai/piper-zh_CN-huayan-x_low/resolve/main/config.json",
     "audio/tts/piper/zh_CN-huayan/config.json"),
]

target = Path(__file__).resolve().parent / "src" / "main" / "resources"

for url, dest_rel in FILES:
    dest = target / dest_rel
    if dest.exists():
        print(f"[跳过] {dest_rel}")
        continue
    dest.parent.mkdir(parents=True, exist_ok=True)
    print(f"[下载] {url.split('/')[-1]} ...")
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        resp = urllib.request.urlopen(req, context=ssl_ctx, timeout=120)
        content = resp.read()
        with open(dest, "wb") as f:
            f.write(content)
        print(f"[完成] {len(content)/1024/1024:.0f}MB")
    except Exception as e:
        print(f"[失败] {e}")
        sys.exit(1)
print("完成")
