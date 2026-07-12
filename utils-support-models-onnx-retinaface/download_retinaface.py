#!/usr/bin/env python3
"""下载 RetinaFace R50 ONNX 模型文件到模块资源目录。"""

import os
import sys
import urllib.request
from pathlib import Path

# 从 HuggingFace 下载已导出的 ONNX 模型
FILES = [
    ("https://huggingface.co/nakamura196/retinaface-r50-onnx/resolve/main/retinaface_r50.onnx",
     "face/detection/retinaface/retinaface_r50.onnx"),
]

target = Path(__file__).resolve().parent / "src" / "main" / "resources"


def main() -> None:
    for url, dest_rel in FILES:
        dest = target / dest_rel
        if dest.exists():
            print(f"[跳过] 已存在: {dest}")
            continue
        dest.parent.mkdir(parents=True, exist_ok=True)
        print(f"[下载] {dest_rel} ...")
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            resp = urllib.request.urlopen(req, timeout=300)
            content = resp.read()
            with open(dest, "wb") as f:
                f.write(content)
            print(f"[完成] {dest} ({len(content)} bytes)")
        except Exception as e:
            print(f"[失败] {url}: {e}")
            sys.exit(1)
    print(f"\n所有模型文件已下载到: {target}")


if __name__ == "__main__":
    main()
