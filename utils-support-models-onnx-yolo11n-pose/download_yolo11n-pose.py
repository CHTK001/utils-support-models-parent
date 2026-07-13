#!/usr/bin/env python3
"""下载 YOLO11n 人体姿态估计 ONNX 模型文件到模块资源目录。"""
import sys, ssl, urllib.request
from pathlib import Path
ssl_ctx = ssl.create_default_context(); ssl_ctx.check_hostname = False; ssl_ctx.verified_mode = ssl.CERT_NONE

# Update this URL if needed
URL = "REPLACE_ME"
dest = Path(__file__).resolve().parent / "src" / "main" / "resources" / "MODEL_PATH"

def main():
    if dest.exists():
        print(f"[跳过] {dest}"); return
    dest.parent.mkdir(parents=True, exist_ok=True)
    try:
        req = urllib.request.Request(URL, headers={"User-Agent": "Mozilla/5.0"})
        resp = urllib.request.urlopen(req, context=ssl_ctx, timeout=300)
        with open(dest, "wb") as f: f.write(resp.read())
        print(f"[完成] {dest} ({len(resp.read())/1024/1024:.0f}MB)")
    except Exception as e:
        print(f"[失败] {e}"); sys.exit(1)
if __name__ == "__main__":
    main()
