#!/usr/bin/env python3
"""下载 人像分割 ONNX 模型文件到模块资源目录。"""
import sys, ssl, urllib.request
from pathlib import Path

ssl_ctx = ssl.create_default_context()
ssl_ctx.check_hostname = False
ssl_ctx.verified_mode = ssl.CERT_NONE

URL = "https://huggingface.co/Heliosoph/u2net-onnx/resolve/main/u2netp.onnx"
dest = Path(__file__).resolve().parent / "src" / "main" / "resources" / "vision/segmentation/u2net/u2netp.onnx"

def main():
    if dest.exists():
        print(f"[跳过] 已存在: {dest}")
        return
    dest.parent.mkdir(parents=True, exist_ok=True)
    print(f"[下载] {URL.split('/')[-1]} ...")
    try:
        req = urllib.request.Request(URL, headers={"User-Agent": "Mozilla/5.0"})
        resp = urllib.request.urlopen(req, context=ssl_ctx, timeout=300)
        content = resp.read()
        with open(dest, "wb") as f:
            f.write(content)
        print(f"[完成] {dest} ({len(content)/1024/1024:.0f}MB)")
    except Exception as e:
        print(f"[失败] {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
